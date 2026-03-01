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
    -- En la Build 42, los sótanos pueden llegar hasta niveles negativos profundos (ej. -17 o -32)
    -- Extendemos los límites para permitir el teletransporte a sótanos profundos.
    if targetZ < -32 or targetZ > 7 then return false end
    
    local currentZ = playerObj:getZ()
    
    -- Para bajar (IR HACIA SÓTANOS):
    if targetZ < currentZ then
        -- Permitimos bajar siempre, ya que el motor de PZ manejará la creación del nivel
        -- o el personaje simplemente descenderá al nivel inferior del búnker.
        return true
    end

    -- Para subir (IR HACIA SUPERFICIE O TECHO):
    -- Verificamos que exista un suelo construido o natural arriba para no aparecer en el vacío.
    local x = math.floor(playerObj:getX())
    local y = math.floor(playerObj:getY())
    local square = getCell():getGridSquare(x, y, targetZ)
    
    return square ~= nil
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
