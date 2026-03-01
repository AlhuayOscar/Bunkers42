BunkersAnywhere = BunkersAnywhere or {}

-- Sprites que usaremos
BunkersAnywhere.BunkerSprite = "street_decoration_01_15" -- Tapa/Manhole para BAJAR
BunkersAnywhere.LadderSprite = "location_sewer_01_24"   -- Escalera de alcantarilla para SUBIR

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
function BunkersAnywhere.placeObject(worldobjects, playerObj, item, sprite, objName, zDir)
    local targetZ = playerObj:getZ() + zDir
    if not BunkersAnywhere.canTeleportTo(playerObj, targetZ) then
        playerObj:setHaloNote("No hay suelo en el destino (" .. (zDir > 0 and "arriba" or "abajo") .. ")", 255, 0, 0, 350)
        return
    end

    local sq = playerObj:getSquare()
    if not sq then return end
    
    local obj = sq:addTileObject(sprite)
    if not obj then return end
    
    obj:getModData().bunkerType = objName -- "BunkerEntrance" o "BunkerLadder"
    
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

    -- Solo permitir INSTALAR desde el inventario. Se removió el teleport directo para forzar el uso del tile.
    if bunkerDoorItem then
        local option = context:addOption("Instalar Entrada (Solo Bajar)", worldobjects, BunkersAnywhere.placeObject, playerObj, bunkerDoorItem, BunkersAnywhere.BunkerSprite, "Entrada de Bunker", -1)
        if not BunkersAnywhere.canTeleportTo(playerObj, playerObj:getZ() - 1) then
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip:setName("Error")
            tooltip.description = "Necesitas una habitacion o suelo debajo para instalar esto."
            option.notAvailable = true
            option.toolTip = tooltip
        end
    end

    if bunkerLadderItem then
        local option = context:addOption("Instalar Escalera (Solo Subir)", worldobjects, BunkersAnywhere.placeObject, playerObj, bunkerLadderItem, BunkersAnywhere.LadderSprite, "Escalera de Bunker", 1)
        if not BunkersAnywhere.canTeleportTo(playerObj, playerObj:getZ() + 1) then
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip:setName("Error")
            tooltip.description = "Necesitas una habitacion o suelo arriba para instalar esto."
            option.notAvailable = true
            option.toolTip = tooltip
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(BunkersAnywhereInventoryContext)

local function BunkersAnywhereWorldContext(player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    local sq = worldobjects[1]:getSquare()
    local z = playerObj:getZ()
    
    local targetObj = nil
    local objects = sq:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local bType = obj:getModData().bunkerType
        if bType then
            targetObj = obj
            break
        end
    end

    if targetObj then
        local bType = targetObj:getModData().bunkerType
        local optionName = (bType == "Entrada de Bunker") and "Entrada (Bajar)" or "Escalera (Subir)"
        local submenu = context:addOption(optionName)
        local submenuCtx = ISContextMenu:getNew(context)
        context:addSubMenu(submenu, submenuCtx)
        
        if bType == "Entrada de Bunker" then
            -- Solo BAJAR
            local downOption = submenuCtx:addOption("Bajar al Sotano (Z-1)", playerObj, BunkersAnywhere.teleportToZ, z - 1)
            if not BunkersAnywhere.canTeleportTo(playerObj, z - 1) then downOption.notAvailable = true end
            submenuCtx:addOption("Desinstalar Entrada", targetObj, BunkersAnywhere.removeObject, playerObj, "Base.BunkerDoor")
        else
            -- Solo SUBIR
            local upOption = submenuCtx:addOption("Subir a Planta Baja (Z+1)", playerObj, BunkersAnywhere.teleportToZ, z + 1)
            if not BunkersAnywhere.canTeleportTo(playerObj, z + 1) then upOption.notAvailable = true end
            submenuCtx:addOption("Desinstalar Escalera", targetObj, BunkersAnywhere.removeObject, playerObj, "Base.BunkerLadder")
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereWorldContext)
