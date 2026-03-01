BunkersAnywhere = BunkersAnywhere or {}

function BunkersAnywhere.teleportToZ(playerObj, newZ)
    if playerObj and newZ ~= nil then
        -- En Project Zomboid, para teletransportar de manera segura podemos actualizar las coordenadas Z
        local x = playerObj:getX()
        local y = playerObj:getY()
        playerObj:setZ(newZ)
        playerObj:setX(x)
        playerObj:setY(y)
    end
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
        -- Agregamos las opciones al inventario cuando clickeamos la puerta de bunker
        context:addOption("Bunker: Bajar al Sotano (Z-1)", playerObj, BunkersAnywhere.teleportToZ, z - 1)
        context:addOption("Bunker: Subir a Planta Baja (Z+1)", playerObj, BunkersAnywhere.teleportToZ, z + 1)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(BunkersAnywhereInventoryContext)

local function BunkersAnywhereWorldContext(player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    
    -- Permite usar la puerta de bunker directamente desde el mundo si la llevamos en el inventario
    local inventory = playerObj:getInventory()
    if inventory:contains("BunkerDoor") then
        local z = playerObj:getZ()
        local submenu = context:addOption("Usar Puerta de Bunker")
        local submenuCtx = ISContextMenu:getNew(context)
        context:addSubMenu(submenu, submenuCtx)
        submenuCtx:addOption("Bajar al Sotano (Z-1)", playerObj, BunkersAnywhere.teleportToZ, z - 1)
        submenuCtx:addOption("Subir a Planta Baja (Z+1)", playerObj, BunkersAnywhere.teleportToZ, z + 1)
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereWorldContext)
