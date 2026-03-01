BunkersAnywhere = BunkersAnywhere or {}

-- Sprite que usaremos para la entrada (un registro/manhole de metal común en el vanilla)
BunkersAnywhere.BunkerSprite = "street_decoration_01_15"

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
    local cell = getCell()
    local square = cell:getGridSquare(x, y, targetZ)
    
    if square then
        if square:getFloor() ~= nil or square:getRoom() ~= nil then
            return true
        end
    end
    return false
end

-- Función para colocar la entrada en el mundo
function BunkersAnywhere.placeBunker(worldobjects, playerObj, item)
    local sq = playerObj:getSquare()
    if not sq then return end
    
    -- Usamos addTileObject que es la forma estándar y segura en PZ para añadir objetos por nombre de sprite
    local obj = sq:addTileObject(BunkersAnywhere.BunkerSprite)
    if not obj then return end
    
    obj:getModData().isBunker = true
    
    -- Transmitimos el cambio al servidor si es MP
    if isClient() then
        obj:transmitCompleteItemToServer()
    end
    
    -- Removemos el ítem del inventario
    playerObj:getInventory():Remove(item)
    playerObj:setHaloNote("Entrada de Bunker instalada", 255, 255, 0, 300)
end

-- Función para desinstalar la entrada
function BunkersAnywhere.removeBunker(obj, playerObj)
    local sq = obj:getSquare()
    if not sq then return end
    
    -- Usamos removeFromSquare que es más fiable
    obj:removeFromSquare()
    playerObj:getInventory():AddItem("Base.BunkerDoor")
    playerObj:setHaloNote("Entrada de Bunker recogida", 255, 255, 0, 300)
end

local function BunkersAnywhereInventoryContext(player, context, items)
    local bunkerDoorItem = nil
    for _, itemGroup in ipairs(items) do
        local testItem = itemGroup
        if not instanceof(itemGroup, "InventoryItem") then
            testItem = itemGroup.items[1]
        end
        if testItem:getType() == "BunkerDoor" then
            bunkerDoorItem = testItem
            break
        end
    end

    if bunkerDoorItem then
        local playerObj = getSpecificPlayer(player)
        local z = playerObj:getZ()
        
        -- Opción de colocar en el suelo
        context:addOption("Instalar Entrada de Bunker", nil, BunkersAnywhere.placeBunker, playerObj, bunkerDoorItem)

        -- Sótano (Abajo)
        local downOption = context:addOption("Bunker: Bajar al Sotano (Z-1)", playerObj, BunkersAnywhere.teleportToZ, z - 1)
        if not BunkersAnywhere.canTeleportTo(playerObj, z - 1) then
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip:setName("Error")
            tooltip.description = "No hay un lugar seguro/construido abajo."
            downOption.notAvailable = true
            downOption.toolTip = tooltip
        end
        
        -- Planta Baja (Arriba)
        local upOption = context:addOption("Bunker: Subir a Planta Baja (Z+1)", playerObj, BunkersAnywhere.teleportToZ, z + 1)
        if not BunkersAnywhere.canTeleportTo(playerObj, z + 1) then
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip:setName("Error")
            tooltip.description = "No hay un lugar seguro/construido arriba."
            upOption.notAvailable = true
            upOption.toolTip = tooltip
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(BunkersAnywhereInventoryContext)

local function BunkersAnywhereWorldContext(player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    local sq = worldobjects[1]:getSquare()
    local z = playerObj:getZ()
    
    -- Buscamos si el objeto clickeado es una entrada de búnker
    local bunkerObj = nil
    local objects = sq:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj:getModData().isBunker or obj:getSprite():getName() == BunkersAnywhere.BunkerSprite then
            bunkerObj = obj
            break
        end
    end

    if bunkerObj then
        local submenu = context:addOption("Entrada de Bunker")
        local submenuCtx = ISContextMenu:getNew(context)
        context:addSubMenu(submenu, submenuCtx)
        
        -- Bajar
        local downOption = submenuCtx:addOption("Bajar al Sotano (Z-1)", playerObj, BunkersAnywhere.teleportToZ, z - 1)
        if not BunkersAnywhere.canTeleportTo(playerObj, z - 1) then
            downOption.notAvailable = true
        end
        
        -- Subir
        local upOption = submenuCtx:addOption("Subir a Planta Baja (Z+1)", playerObj, BunkersAnywhere.teleportToZ, z + 1)
        if not BunkersAnywhere.canTeleportTo(playerObj, z + 1) then
            upOption.notAvailable = true
        end
        
        -- Desinstalar
        submenuCtx:addOption("Desinstalar Entrada", bunkerObj, BunkersAnywhere.removeBunker, playerObj)
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereWorldContext)
