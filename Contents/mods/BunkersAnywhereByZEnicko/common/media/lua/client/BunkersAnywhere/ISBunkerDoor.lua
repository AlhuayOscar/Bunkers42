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

-- Función para verificar si hay un piso válido en la coordenada Z destino
function BunkersAnywhere.canTeleportTo(playerObj, targetZ)
    -- Límites de la Build 42 (-32 a 7)
    if targetZ < -32 or targetZ > 7 then return false end
    
    local x = math.floor(playerObj:getX())
    local y = math.floor(playerObj:getY())
    
    -- Los niveles negativos (sótanos) a menudo no están cargados en el cliente.
    -- Intentamos obtener el square. Si es nil, intentamos forzar una verificación más profunda.
    local cell = getCell()
    local square = cell:getGridSquare(x, y, targetZ)
    
    -- Si el square existe, verificamos si tiene un piso (Floor) o si es parte de una habitación (Room)
    if square then
        -- En PZ, un square válido para pararse debe tener un Floor o ser una habitación cerrada
        if square:getFloor() ~= nil or square:getRoom() ~= nil then
            return true
        end
    end
    
    -- Si el square es nil, puede que no esté cargado. 
    -- Para la Build 42, si estamos intentando bajar a un búnker/sótano pre-existente,
    -- podríamos necesitar usar getWorld():getChunk() o similar para una comprobación técnica,
    -- pero getGridSquare es la forma estándar.
    
    return false
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
    
    local inventory = playerObj:getInventory()
    if inventory:contains("BunkerDoor") then
        local z = playerObj:getZ()
        local submenu = context:addOption("Usar Puerta de Bunker")
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
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereWorldContext)
