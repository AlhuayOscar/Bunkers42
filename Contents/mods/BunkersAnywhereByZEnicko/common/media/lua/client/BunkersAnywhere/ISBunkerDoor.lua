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

-- FUNCIÓN NUEVA: Convertir escaleras vanilla
function BunkersAnywhere.convertStairs(stairObj, playerObj)
    local sq = stairObj:getSquare()
    local z = sq:getZ()
    local x, y = sq:getX(), sq:getY()
    
    -- Buscamos el punto más alto de la escalera (donde el jugador "termina")
    -- En PZ las escaleras suelen ocupar 3 tiles. Buscamos el tile que tiene acceso al piso de arriba.
    local topSq = nil
    if stairObj:getProperties():Is(IsoFlagType.StairsW) or stairObj:getProperties():Is(IsoFlagType.StairsN) then
        -- Intentamos detectar el cuadrado superior
        topSq = getCell():getGridSquare(x, y, z + 1)
        if not topSq then
            -- A veces el objeto clickeado es la base, buscamos el tope
            -- (Lógica simplificada: usamos el cuadrado actual para la entrada y el de abajo para la escalera)
            topSq = sq
        end
    end

    if not topSq then topSq = sq end
    local bottomSq = getCell():getGridSquare(topSq:getX(), topSq:getY(), topSq:getZ() - 1)

    -- Consumimos los materiales
    local inv = playerObj:getInventory()
    local door = inv:FindAndReturn("Base.BunkerDoor")
    local ladder = inv:FindAndReturn("Base.BunkerLadder")

    if door and ladder then
        -- 1. Eliminar la escalera (esto es complejo porque son varios objetos, eliminamos el clickeado y vecinos)
        sq:RemoveTileObject(stairObj)
        -- 2. Colocar Entrance arriba
        local ent = topSq:addTileObject(BunkersAnywhere.getEntranceSprite(topSq))
        ent:getModData().bunkerType = "Entrada de Bunker"
        -- 3. Colocar Ladder abajo
        if bottomSq then
            local lad = bottomSq:addTileObject(BunkersAnywhere.Sprites.Ladder)
            lad:getModData().bunkerType = "Escalera de Bunker"
        end
        
        inv:Remove(door)
        inv:Remove(ladder)
        playerObj:setHaloNote("Escaleras convertidas a Bunker", 0, 255, 255, 400)
    end
end

local function BunkersAnywhereInventoryContext(player, context, items)
    local bunkerDoorItem = nil
    local bunkerLadderItem = nil

    for _, itemGroup in ipairs(items) do
        local testItem = itemGroup
        if not instanceof(itemGroup, "InventoryItem") then
            testItem = itemGroup.items[1]
        end
        if testItem:getType() == "BunkerDoor" then
            bunkerDoorItem = testItem
        elseif testItem:getType() == "BunkerLadder" then
            bunkerLadderItem = testItem
        end
    end

    local playerObj = getSpecificPlayer(player)

    if bunkerDoorItem then
        local option = context:addOption("Instalar Entrada (Solo Bajar)", worldobjects, BunkersAnywhere.placeObject, playerObj, bunkerDoorItem, "Entrada de Bunker", -1)
        if not BunkersAnywhere.canTeleportTo(playerObj, playerObj:getZ() - 1) then
            option.notAvailable = true
        end
    end

    if bunkerLadderItem then
        local option = context:addOption("Instalar Escalera (Solo Subir)", worldobjects, BunkersAnywhere.placeObject, playerObj, bunkerLadderItem, "Escalera de Bunker", 1)
        if not BunkersAnywhere.canTeleportTo(playerObj, playerObj:getZ() + 1) then
            option.notAvailable = true
        end
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

    -- Menú para convertir escaleras VANILLA
    if stairObj then
        local inv = playerObj:getInventory()
        if inv:contains("BunkerDoor") and inv:contains("BunkerLadder") then
            context:addOption("Sustituir por Bunker (Consumir items)", stairObj, BunkersAnywhere.convertStairs, playerObj)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereWorldContext)
