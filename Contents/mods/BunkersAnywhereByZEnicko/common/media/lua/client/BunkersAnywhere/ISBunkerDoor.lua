BunkersAnywhere = BunkersAnywhere or {}

-- Sprites dinámicos
BunkersAnywhere.Sprites = {
    InsideEntrance = "street_decoration_01_15", -- Escotilla/Manhole
    OutsideEntrance = "street_decoration_01_15", -- Escotilla/Manhole
    Ladder = "location_sewer_01_32" -- Escalera de alcantarilla (B42 style)
}

-- Función para elegir el sprite según el entorno
function BunkersAnywhere.getEntranceSprite(sq)
    if sq:isOutside() then
        return BunkersAnywhere.Sprites.OutsideEntrance
    else
        return BunkersAnywhere.Sprites.InsideEntrance
    end
end

function BunkersAnywhere.teleportToZ(playerObj, newZ)
    if playerObj and newZ ~= nil then
        local x = playerObj:getX()
        local y = playerObj:getY()
        playerObj:setZ(newZ)
        playerObj:setX(x)
        playerObj:setY(y)
    end
end

function BunkersAnywhere.canTeleportTo(playerObj, targetZ)
    if targetZ < -32 or targetZ > 7 then return false end
    
    local x = math.floor(playerObj:getX())
    local y = math.floor(playerObj:getY())
    local square = getCell():getGridSquare(x, y, targetZ)
    
    if square then
        if square:getFloor() ~= nil or square:getRoom() ~= nil then
            return true
        end
    end
    return false
end

-- Función para colocar objetos en el mundo
function BunkersAnywhere.placeObject(worldobjects, playerObj, item, objName, zDir)
    local sq = playerObj:getSquare()
    if not sq then return end
    
    local targetZ = playerObj:getZ() + zDir
    if not BunkersAnywhere.canTeleportTo(playerObj, targetZ) then
        playerObj:setHaloNote("No hay suelo en el destino", 255, 0, 0, 350)
        return
    end

    local sprite = (objName == "Entrada de Bunker") and BunkersAnywhere.getEntranceSprite(sq) or BunkersAnywhere.Sprites.Ladder
    local obj = sq:addTileObject(sprite)
    if not obj then return end
    
    obj:getModData().bunkerType = objName
    
    if isClient() then
        obj:transmitCompleteItemToServer()
    end
    
    playerObj:getInventory():Remove(item)
    playerObj:setHaloNote(objName .. " instalada", 0, 255, 0, 300)
end

-- Función para desinstalar
function BunkersAnywhere.removeObject(obj, playerObj, itemFullType)
    local sq = obj:getSquare()
    if not sq then return end
    
    obj:removeFromSquare()
    playerObj:getInventory():AddItem(itemFullType)
    playerObj:setHaloNote("Objeto recogido", 200, 200, 200, 300)
end

-- FUNCIÓN: Usar el Bunker Kit en escaleras
function BunkersAnywhere.useBunkerKit(stairObj, playerObj)
    local sq = stairObj:getSquare()
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local cell = getCell()

    -- 1. Identificar todos los tiles de la escalera (habitualmente 3 tiles seguidos)
    -- Buscamos en un pequeño radio para limpiar la estructura completa
    for ix = -2, 2 do
        for iy = -2, 2 do
            local s = cell:getGridSquare(x + ix, y + iy, z)
            if s then
                local objs = s:getObjects()
                for i = objs:size() - 1, 0, -1 do
                    local o = objs:get(i)
                    if o:getProperties():Is(IsoFlagType.StairsW) or o:getProperties():Is(IsoFlagType.StairsN) then
                        s:RemoveTileObject(o)
                    end
                end
            end
        end
    end

    -- 2. Colocar Escalera (Ladder) abajo
    local ladder = sq:addTileObject(BunkersAnywhere.Sprites.Ladder)
    ladder:getModData().bunkerType = "Escalera de Bunker"

    -- 3. Gestionar el nivel superior (Z+1)
    local topZ = z + 1
    local woodFloorSprite = "floors_interior_tiles_01_40" -- Suelo de madera estándar

    -- Llenar hueco 3x3 arriba
    for dx = -1, 1 do
        for dy = -1, 1 do
            local tSq = cell:getGridSquare(x + dx, y + dy, topZ)
            if tSq then
                if not tSq:getFloor() then
                    tSq:addTileObject(woodFloorSprite)
                end
            end
        end
    end

    -- 4. Colocar Tapa de Bunker arriba (exactamente sobre la escalera)
    local topCenterSq = cell:getGridSquare(x, y, topZ)
    if topCenterSq then
        local ent = topCenterSq:addTileObject(BunkersAnywhere.getEntranceSprite(topCenterSq))
        ent:getModData().bunkerType = "Entrada de Bunker"
    end

    -- Consumir el Kit
    playerObj:getInventory():RemoveOneOf("Base.BunkerKit")
    playerObj:setHaloNote("Kit de Bunker instalado: Escaleras sustituidas", 0, 255, 0, 400)
end

local function BunkersAnywhereInventoryContext(player, context, items)
    local bunkerDoorItem = nil
    local bunkerLadderItem = nil
    local bunkerKitItem = nil

    for _, itemGroup in ipairs(items) do
        local testItem = itemGroup
        if not instanceof(itemGroup, "InventoryItem") then
            testItem = itemGroup.items[1]
        end
        local type = testItem:getType()
        if type == "BunkerDoor" then bunkerDoorItem = testItem
        elseif type == "BunkerLadder" then bunkerLadderItem = testItem
        elseif type == "BunkerKit" then bunkerKitItem = testItem end
    end

    local playerObj = getSpecificPlayer(player)

    if bunkerDoorItem then
        local option = context:addOption("Instalar Entrada (Solo Bajar)", worldobjects, BunkersAnywhere.placeObject, playerObj, bunkerDoorItem, "Entrada de Bunker", -1)
        if not BunkersAnywhere.canTeleportTo(playerObj, playerObj:getZ() - 1) then option.notAvailable = true end
    end

    if bunkerLadderItem then
        local option = context:addOption("Instalar Escalera (Solo Subir)", worldobjects, BunkersAnywhere.placeObject, playerObj, bunkerLadderItem, "Escalera de Bunker", 1)
        if not BunkersAnywhere.canTeleportTo(playerObj, playerObj:getZ() + 1) then option.notAvailable = true end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(BunkersAnywhereInventoryContext)

local function BunkersAnywhereWorldContext(player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    local sq = worldobjects[1]:getSquare()
    local z = playerObj:getZ()
    
    local targetObj = nil
    local stairObj = nil
    local objects = sq:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj:getModData().bunkerType then
            targetObj = obj
        elseif obj:getProperties():Is(IsoFlagType.StairsW) or obj:getProperties():Is(IsoFlagType.StairsN) then
            stairObj = obj
        end
    end

    -- Menú para objetos del MOD
    if targetObj then
        local bType = targetObj:getModData().bunkerType
        local optionName = (bType == "Entrada de Bunker") and "Entrada (Bajar)" or "Escalera (Subir)"
        local submenu = context:addOption(optionName)
        local submenuCtx = ISContextMenu:getNew(context)
        context:addSubMenu(submenu, submenuCtx)
        
        if bType == "Entrada de Bunker" then
            local downOption = submenuCtx:addOption("Bajar al Sotano (Z-1)", playerObj, BunkersAnywhere.teleportToZ, z - 1)
            if not BunkersAnywhere.canTeleportTo(playerObj, z - 1) then downOption.notAvailable = true end
            submenuCtx:addOption("Desinstalar Entrada", targetObj, BunkersAnywhere.removeObject, playerObj, "Base.BunkerDoor")
        else
            local upOption = submenuCtx:addOption("Subir a Planta Baja (Z+1)", playerObj, BunkersAnywhere.teleportToZ, z + 1)
            if not BunkersAnywhere.canTeleportTo(playerObj, z + 1) then upOption.notAvailable = true end
            submenuCtx:addOption("Desinstalar Escalera", targetObj, BunkersAnywhere.removeObject, playerObj, "Base.BunkerLadder")
        end
    end

    -- Menú para el BUNKER KIT (sobre escaleras vanilla)
    if stairObj then
        local inv = playerObj:getInventory()
        if inv:contains("BunkerKit") then
            context:addOption("Instalar Kit de Bunker (Sustituir Escaleras)", stairObj, BunkersAnywhere.useBunkerKit, playerObj)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereWorldContext)
