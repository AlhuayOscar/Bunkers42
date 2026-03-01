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

-- Función auxiliar para detectar si un objeto es una escalera (por flags o nombre de sprite)
function BunkersAnywhere.isStair(obj)
    if not obj then return false end
    local props = obj:getProperties()
    if props:Is(IsoFlagType.StairsW) or props:Is(IsoFlagType.StairsN) then
        return true
    end
    local spriteName = obj:getSprite():getName()
    if spriteName then
        if string.find(spriteName, "stairs") or string.find(spriteName, "escalator") or
           string.find(spriteName, "carpentry_02_88") or 
           string.find(spriteName, "constructedobjects_01_88") or 
           string.find(spriteName, "crafted_02_106") then
            return true
        end
    end
    return false
end

-- FUNCIÓN: Usar el Bunker Kit en escaleras
function BunkersAnywhere.useBunkerKit(stairObj, playerObj)
    local sq = stairObj:getSquare()
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local cell = getCell()
    local topZ = z + 1
    local woodFloorSprite = "floors_interior_tiles_01_40"

    -- 1. Limpiar la estructura física de la escalera y rellenar los huecos
    for ix = -3, 3 do
        for iy = -3, 3 do
            local currentX = x + ix
            local currentY = y + iy
            
            -- NIVEL DE ABAJO (Z): Quitar escalera
            local s = cell:getGridSquare(currentX, currentY, z)
            if s then
                local objs = s:getObjects()
                for i = objs:size() - 1, 0, -1 do
                    local o = objs:get(i)
                    if BunkersAnywhere.isStair(o) then
                        s:RemoveTileObject(o)
                    end
                end
            end

            -- NIVEL DE ARRIBA (Z+1): Tapar agujeros (SUELO PERMANENTE)
            local tSq = cell:getGridSquare(currentX, currentY, topZ)
            if not tSq then
                tSq = IsoGridSquare.new(cell, nil, currentX, currentY, topZ)
                cell:ConnectNewSquare(tSq, false)
            end
            
            if tSq then
                -- Si no hay suelo, lo añadimos
                if not tSq:getFloor() then
                    -- Usamos el sprite de suelo de madera crafteable estándar: carpentry_02_57
                    local newFloor = tSq:addFloor("carpentry_02_57")
                    if isClient() and newFloor then
                        newFloor:transmitCompleteItemToServer()
                    end
                end
                
                -- RECALCULAR VISIBILIDAD Y LUCES (Defensivo para B42)
                if tSq.RecalcAllWithNeighbours then
                    tSq:RecalcAllWithNeighbours(true)
                elseif tSq.RecalcAllWithNeighbor then
                    tSq:RecalcAllWithNeighbor(true)
                else
                    tSq:RecalcProperties()
                end
                
                -- Marcar como cambiado para el motor/red y GUARDADO DE CHUNK (Evita que desaparezca al salir)
                if tSq.EnsureSurroundNotNull then tSq:EnsureSurroundNotNull() end
                if tSq.setSquareChanged then tSq:setSquareChanged() end
                if tSq.flagForHotSave then tSq:flagForHotSave() end
                if tSq.getChunk then
                    local chunk = tSq:getChunk()
                    if chunk and chunk.setHasDirtyObjects then chunk:setHasDirtyObjects(true) end
                end
                
                -- Asegurarnos de que el jugador "conozca" el cuadrado para que no sea negro
                if tSq.setIsExplored then tSq:setIsExplored(true) end
                
                -- Forzar transmisión en MP
                if isClient() then
                    tSq:transmitCompleteSquareToServer()
                end
            end
        end
    end

    -- 2. Colocar Escalera (Ladder) abajo
    local ladder = sq:addTileObject(BunkersAnywhere.Sprites.Ladder)
    ladder:getModData().bunkerType = "Escalera de Bunker"

    -- 3. Colocar Tapa de Bunker arriba (exactamente sobre la escalera)
    local topCenterSq = cell:getGridSquare(x, y, topZ)
    if not topCenterSq then
        topCenterSq = IsoGridSquare.new(cell, nil, x, y, topZ)
        cell:ConnectNewSquare(topCenterSq, false)
    end
    
    if topCenterSq then
        local ent = topCenterSq:addTileObject(BunkersAnywhere.getEntranceSprite(topCenterSq))
        ent:getModData().bunkerType = "Entrada de Bunker"
        if isClient() then ent:transmitCompleteItemToServer() end
        
        -- Sincronizar visualmente arriba (Defensivo)
        if topCenterSq.RecalcAllWithNeighbours then
            topCenterSq:RecalcAllWithNeighbours(true)
        elseif topCenterSq.RecalcAllWithNeighbor then
            topCenterSq:RecalcAllWithNeighbor(true)
        else
            topCenterSq:RecalcProperties()
        end
        
        -- Marcar como modificado para GUARDAR PARTIDA
        if topCenterSq.EnsureSurroundNotNull then topCenterSq:EnsureSurroundNotNull() end
        if topCenterSq.setSquareChanged then topCenterSq:setSquareChanged() end
        if topCenterSq.flagForHotSave then topCenterSq:flagForHotSave() end
        if topCenterSq.getChunk then
            local chunk = topCenterSq:getChunk()
            if chunk and chunk.setHasDirtyObjects then chunk:setHasDirtyObjects(true) end
        end
        
        if topCenterSq.setIsExplored then topCenterSq:setIsExplored(true) end
        
        if isClient() then topCenterSq:transmitCompleteSquareToServer() end
    end

    -- Consumir el Kit
    playerObj:getInventory():RemoveOneOf("Base.BunkerKit")
    playerObj:setHaloNote("Kit de Bunker: Estructura sellada con exito", 0, 255, 100, 400)
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
        elseif BunkersAnywhere.isStair(obj) then
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
