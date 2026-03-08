BunkersAnywhere = BunkersAnywhere or {}
require "ISUI/ISInventoryPaneContextMenu"

-- Sprites dinÃ¡micos
BunkersAnywhere.Sprites = {
    InsideEntrance = "street_decoration_01_15", -- Escotilla/Manhole
    OutsideEntrance = "street_decoration_01_15", -- Escotilla/Manhole
    Ladder = "location_sewer_01_32" -- Escalera de alcantarilla (B42 style)
}

-- FunciÃ³n para elegir el sprite segÃºn el entorno
function BunkersAnywhere.getEntranceSprite(sq)
    if sq:isOutside() then
        return BunkersAnywhere.Sprites.OutsideEntrance
    else
        return BunkersAnywhere.Sprites.InsideEntrance
    end
end

-- Central system moved to ISBunkerCentral.lua

function BunkersAnywhere.teleportToZ(playerObj, newZ, targetX, targetY)
    if playerObj and newZ ~= nil and targetX ~= nil and targetY ~= nil then
        local cell = getCell()
        local targetSq = cell:getGridSquare(math.floor(targetX), math.floor(targetY), newZ)
        
        -- Centramos al jugador EXACTAMENTE en la escalera/tapa de destino
        playerObj:setX(math.floor(targetX) + 0.5)
        playerObj:setY(math.floor(targetY) + 0.5)
        playerObj:setZ(newZ)
        
        -- Forzamos la actualizaciÃ³n de coordenadas "last" para evitar interpolaciones raras en MP
        playerObj:setLx(playerObj:getX())
        playerObj:setLy(playerObj:getY())
        playerObj:setLz(playerObj:getZ())
        
        if targetSq then
            playerObj:setCurrent(targetSq)
        end
    end
end

function BunkersAnywhere.canTeleportTo(sqX, sqY, targetZ)
    if targetZ < -32 or targetZ > 7 then return false end
    
    local square = getCell():getGridSquare(sqX, sqY, targetZ)
    
    if square then
        if square:getFloor() ~= nil or square:getRoom() ~= nil then
            -- Verificar si el tile destino esta libre de solidos (paredes, mueles, etc.)
            local objs = square:getObjects()
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                if o:getProperties() and (o:getProperties():Is(IsoFlagType.solid) or o:getProperties():Is(IsoFlagType.solidtrans)) then
                    -- Ignorar los objetos del mismo mod u otras puertas, para no bloquear
                    if not (o.getModData and o:getModData() and o:getModData().bunkerType) then
                        return false
                    end
                end
            end
            return true
        end
    end
    return false
end

-- FunciÃ³n para colocar objetos en el mundo
function BunkersAnywhere.placeObject(worldobjects, playerObj, item, objName, zDir)
    local sq = playerObj:getSquare()
    if not sq then return end
    
    local targetZ = playerObj:getZ() + zDir
    if not BunkersAnywhere.canTeleportTo(sq:getX(), sq:getY(), targetZ) then
        playerObj:setHaloNote(getText("IGUI_Bunker_NoFloorTarget"), 255, 0, 0, 350)
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
    
    local itemName = (objName == "Entrada de Bunker") and getText("ItemName_Base.BunkerDoor") or getText("ItemName_Base.BunkerLadder")
    playerObj:setHaloNote(itemName .. getText("IGUI_Bunker_Installed"), 0, 255, 0, 300)
end

-- FunciÃ³n para desinstalar
function BunkersAnywhere.removeObject(obj, playerObj, itemFullType)
    local sq = obj:getSquare()
    if not sq then return end
    
    obj:removeFromSquare()
    
    -- Si al quitar el objeto no queda suelo, ponemos tablones (evita caer al vacÃ­o)
    BunkersAnywhere.ensureFloor(sq)

    playerObj:getInventory():AddItem(itemFullType)
    playerObj:setHaloNote(getText("IGUI_Bunker_ItemPickedUp"), 200, 200, 200, 300)
end

-- FunciÃ³n para detectar si un objeto es una escalera (por flags o nombre de sprite)
function BunkersAnywhere.isStair(obj)
    if not obj then return false end
    
    -- 0. Check if it's a native Stair Object (New in B42/MP)
    local okIso, isNativeStair = pcall(function() return instanceof(obj, "IsoStairsObject") end)
    if okIso and isNativeStair then return true end

    -- 1. Check by Sprite Name (Safest and most direct)
    if type(obj.getSprite) == "function" then
        local sprite = obj:getSprite()
        if sprite and type(sprite.getName) == "function" then
            local spriteName = sprite:getName()
            if spriteName then
                spriteName = string.lower(spriteName)
                if string.find(spriteName, "stairs") or string.find(spriteName, "escalator") or
                   string.find(spriteName, "carpentry_02_88") or 
                   string.find(spriteName, "carpentry_02_89") or 
                   string.find(spriteName, "carpentry_02_90") or 
                   string.find(spriteName, "constructedobjects_01_88") or 
                   string.find(spriteName, "constructedobjects_01_89") or 
                   string.find(spriteName, "constructedobjects_01_90") or
                   string.find(spriteName, "fixtures_stairs") or
                   string.find(spriteName, "crafted_02_106") or
                   string.find(spriteName, "crafted_02_107") or
                   string.find(spriteName, "crafted_02_108") or
                   string.find(spriteName, "location_shop_mall_01_6") or -- Mall escalators
                   string.find(spriteName, "location_shop_mall_01_7") or
                   string.find(spriteName, "location_shop_mall_01_8") then
                    return true
                end
            end
        end
    end

    -- 2. Check by Flags (Protected)
    if type(obj.getProperties) == "function" then
        local props = obj:getProperties()
        if props and type(props.Is) == "function" then
            local ok, hasStair = pcall(function()
                return props:Is(IsoFlagType.StairsW) or props:Is(IsoFlagType.StairsN)
            end)
            if ok and hasStair then return true end
        end
    end
    
    return false
end


-- FunciÃ³n para detectar barandillas/pasamanos
function BunkersAnywhere.isRailing(obj)
    if not obj then return false end
    if type(obj.getSprite) == "function" then
        local sprite = obj:getSprite()
        if sprite and type(sprite.getName) == "function" then
            local spriteName = sprite:getName()
            if spriteName then
                spriteName = string.lower(spriteName)
                -- Patrones para barandillas
                if string.find(spriteName, "railing") or string.find(spriteName, "fence_rs") or
                   string.find(spriteName, "fixtures_railings") or
                   -- Agregamos rangos especÃ­ficos solicitados
                   string.find(spriteName, "fixtures_railings_01_59") or
                   string.find(spriteName, "fixtures_railings_01_60") or
                   string.find(spriteName, "fixtures_railings_01_61") then
                    return true
                end
            end
        end
    end
    return false
end

-- FUNCIÃ“N: Asegurar que una casilla tenga suelo (y guardarla permanentemente)
function BunkersAnywhere.ensureFloor(sq, floorSprite)
    if not sq then return end
    
    local spriteToUse = floorSprite or "carpentry_02_57"
    
    -- 1. Si no hay suelo, lo aÃ±adimos
    if not sq:getFloor() then
        local newFloor = sq:addFloor(spriteToUse)
        if isClient() and newFloor then
            -- Safe call for deprecated or changing sync functions
            if newFloor.transmitCompleteItemToServer then
                newFloor:transmitCompleteItemToServer()
            end
        end
    end
    
    -- 2. RECALCULAR VISIBILIDAD
    if sq.RecalcAllWithNeighbours then
        sq:RecalcAllWithNeighbours(true)
    elseif sq.RecalcProperties then
        sq:RecalcProperties()
    end
    
    -- 3. Marcar para HotSave
    if sq.setSquareChanged then sq:setSquareChanged() end
    if sq.flagForHotSave then sq:flagForHotSave() end
    
    -- 4. TransmisiÃ³n segura en Multijugador
    if isClient() then
        if sq.transmitCompleteSquareToServer then
            sq:transmitCompleteSquareToServer()
        end
    end
end

-- FUNCIÃ“N: Usar el Bunker Kit en escaleras
function BunkersAnywhere.useBunkerKit(stairObj, playerObj)
    local sq = stairObj:getSquare()
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local cell = getCell()
    local topZ = z + 1
    local woodFloorSprite = "carpentry_02_57"

    -- 1. Buscar TODAS las partes de la escalera y barandillas y removerlas correctamente (9x9 para escaleras largas)
    local itemsToRemove = {}
    for ix = -4, 4 do
        for iy = -4, 4 do
            local currentX = x + ix
            local currentY = y + iy
            local s = cell:getGridSquare(currentX, currentY, z)
            if s then
                local objs = s:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if BunkersAnywhere.isStair(o) or BunkersAnywhere.isRailing(o) then
                        table.insert(itemsToRemove, {sq = s, obj = o, xx = currentX, yy = currentY})
                    end
                end
            end
        end
    end

    -- Remover los objetos y tapar los agujeros en Z+1 donde estaban (Evitando duplicados)
    local patchedSquares = {}
    for _, item in ipairs(itemsToRemove) do
        local s = item.sq
        local o = item.obj
        
        if isClient() and s.transmitRemoveItemFromSquare then
            s:transmitRemoveItemFromSquare(o)
        end
        s:RemoveTileObject(o)
        
        local key = tostring(item.xx) .. "," .. tostring(item.yy)
        if not patchedSquares[key] then
            -- Tapamos su posible agujero (Z+1)
            local tSq = cell:getGridSquare(item.xx, item.yy, topZ)
            if not tSq then
                tSq = IsoGridSquare.new(cell, nil, item.xx, item.yy, topZ)
                cell:ConnectNewSquare(tSq, false)
            end
            if tSq then
                BunkersAnywhere.ensureFloor(tSq, woodFloorSprite)
            end
            patchedSquares[key] = true
        end
    end

    -- 2. Asegurar suelo y tapar huecos en una zona mas amplia (5x5)
    for ix = -2, 2 do
        for iy = -2, 2 do
            local currentX = x + ix
            local currentY = y + iy
            
            -- NIVEL DE ABAJO (Z): Asegurar suelo
            local s = cell:getGridSquare(currentX, currentY, z)
            if not s then
                s = IsoGridSquare.new(cell, nil, currentX, currentY, z)
                cell:ConnectNewSquare(s, false)
            end
            
            if s then
                BunkersAnywhere.ensureFloor(s, woodFloorSprite)
            end

            -- NIVEL DE ARRIBA (Z+1): Tapar agujeros (SUELO PERMANENTE)
            local tSq = cell:getGridSquare(currentX, currentY, topZ)
            if not tSq then
                tSq = IsoGridSquare.new(cell, nil, currentX, currentY, topZ)
                cell:ConnectNewSquare(tSq, false)
            end
            
            if tSq then
                -- Si no hay suelo, lo aÃ±adimos y sincronizamos
                BunkersAnywhere.ensureFloor(tSq, woodFloorSprite)
            end
        end
    end

    -- 2. Colocar Escalera (Ladder) abajo
    local ladder = sq:addTileObject(BunkersAnywhere.Sprites.Ladder)
    if ladder then
        ladder:getModData().bunkerType = "Escalera de Bunker"
        if isClient() and ladder.transmitCompleteItemToServer then 
            ladder:transmitCompleteItemToServer() 
        end
    end

    -- 3. Colocar Tapa de Bunker arriba (exactamente sobre la escalera)
    local topCenterSq = cell:getGridSquare(x, y, topZ)
    if not topCenterSq then
        topCenterSq = IsoGridSquare.new(cell, nil, x, y, topZ)
        cell:ConnectNewSquare(topCenterSq, false)
    end
    
    if topCenterSq then
        local ent = topCenterSq:addTileObject(BunkersAnywhere.getEntranceSprite(topCenterSq))
        if ent then
            ent:getModData().bunkerType = "Entrada de Bunker"
            if isClient() and ent.transmitCompleteItemToServer then 
                ent:transmitCompleteItemToServer() 
            end
        end
        
        -- Sincronizar visualmente arriba (Defensivo)
        if topCenterSq.RecalcAllWithNeighbours then
            topCenterSq:RecalcAllWithNeighbours(true)
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
        
        if isClient() and topCenterSq.transmitCompleteSquareToServer then 
            topCenterSq:transmitCompleteSquareToServer() 
        end
    end

    -- Consumir el Kit
    playerObj:getInventory():RemoveOneOf("Base.BunkerKit")
    playerObj:setHaloNote(getText("IGUI_Bunker_StructureSealed"), 0, 255, 100, 400)
end

-- FUNCIÃ“N: Desempaquetar el Kit
function BunkersAnywhere.unpackBunkerKit(kitItem, playerObj)
    local inv = playerObj:getInventory()
    inv:Remove(kitItem)
    inv:AddItem("Base.BunkerDoor")
    inv:AddItem("Base.BunkerLadder")
    inv:AddItem("Base.Hammer")
    playerObj:setHaloNote(getText("IGUI_Bunker_KitUnpacked"), 0, 255, 0, 300)
end

-- ==========================================================
-- Timed Action: AcciÃ³n GenÃ©rica del Bunker (Instalar/Subir/Bajar)
-- ==========================================================
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"

ISBunkerAction = ISBaseTimedAction:derive("ISBunkerAction");

function ISBunkerAction:isValid()
    return true; 
end

function ISBunkerAction:update()
    self.character:faceLocation(self.targetSq:getX(), self.targetSq:getY())
    self.character:setMetabolicTarget(Metabolics.HeavyWork);
end

function ISBunkerAction:start()
    self:setActionAnim(self.anim)
    self.character:SetVariable("LootPosition", "Low")
    if self.sound then
        self.character:getEmitter():playSound(self.sound)
    end
end

function ISBunkerAction:stop()
    ISBaseTimedAction.stop(self);
end

function ISBunkerAction:perform()
    if self.callback then
        self.callback(self.arg1, self.arg2, self.arg3, self.arg4, self.arg5)
    end
    ISBaseTimedAction.perform(self);
end

function ISBunkerAction:new(character, targetSq, time, anim, sound, callback, arg1, arg2, arg3, arg4, arg5)
    local o = ISBaseTimedAction.new(self, character)
    o.targetSq = targetSq
    o.anim = anim or "Loot"
    o.sound = sound
    o.callback = callback
    o.arg1 = arg1
    o.arg2 = arg2
    o.arg3 = arg3
    o.arg4 = arg4
    o.arg5 = arg5
    o.maxTime = time
    if character:isTimedActionInstant() then 
        o.maxTime = 1; 
    end
    return o
end

-- ==========================================================
-- Wrappers para forzar TimedActions en los MenÃºs
-- ==========================================================

function BunkersAnywhere.onInstallBunkerKit(stairObj, playerObj)
    if luautils.walk(playerObj, stairObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, stairObj:getSquare(), 250, "Loot", "Carpentry", BunkersAnywhere.useBunkerKit, stairObj, playerObj))
    end
end

function BunkersAnywhere.onTeleport(targetObj, playerObj, newZ)
    local targetSq = targetObj:getSquare()
    local x, y, z = targetSq:getX(), targetSq:getY(), targetSq:getZ()
    local bType = targetObj:getModData().bunkerType
    
    local destType = (bType == "Entrada de Bunker") and "Escalera de Bunker" or "Entrada de Bunker"
    local destX, destY = BunkersAnywhere.findDestination(targetSq, newZ, destType)
    
    local pSq = playerObj:getCurrentSquare()
    local sameZ = math.abs(playerObj:getZ() - z) < 0.5
    local distX = math.abs(playerObj:getX() - (x + 0.5))
    local distY = math.abs(playerObj:getY() - (y + 0.5))
    local blocked = false
    
    if pSq and targetSq and pSq ~= targetSq then
        blocked = pSq:isBlockedTo(targetSq)
    end
    
    -- Si estamos en un tile adyacente o en el mismo, interceptamos para no caminar
    if distX < 1.5 and distY < 1.5 and sameZ then
        if blocked then
            -- Si esta bloqueado (ej: separado por pared o barandilla), simplemente salimos.
            -- Asi presionando 'E' el personaje no saltarÃ¡ ni correrÃ¡ hacia otra escalera.
            return
        end
        playerObj:faceThisObject(targetObj)
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, targetSq, 25, "Loot", nil, BunkersAnywhere.teleportToZ, playerObj, newZ, destX, destY))
    else
        -- Desde lejos (click derecho), usamos walk normal
        if luautils.walk(playerObj, targetSq) then
            ISTimedActionQueue.add(ISBunkerAction:new(playerObj, targetSq, 25, "Loot", nil, BunkersAnywhere.teleportToZ, playerObj, newZ, destX, destY))
        end
    end
end

function BunkersAnywhere.onRemove(targetObj, playerObj, itemFullType)
    if luautils.walk(playerObj, targetObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, targetObj:getSquare(), 150, "Loot", "Carpentry", BunkersAnywhere.removeObject, targetObj, playerObj, itemFullType))
    end
end

function BunkersAnywhere.onPlaceObject(worldobjects, playerObj, item, objName, zOffset)
    local sq = playerObj:getSquare()
    if sq and luautils.walk(playerObj, sq) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, sq, 150, "Loot", "Carpentry", BunkersAnywhere.placeObject, worldobjects, playerObj, item, objName, zOffset))
    end
end

function BunkersAnywhere.onUnpackBunkerKit(kitItem, playerObj)
    ISTimedActionQueue.add(ISBunkerAction:new(playerObj, playerObj:getSquare(), 100, "Loot", "HammerClick", BunkersAnywhere.unpackBunkerKit, kitItem, playerObj))
end

-- ==========================================================
-- Context Menus
-- ==========================================================

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
    local worldobjects = { playerObj:getCurrentSquare() } -- Fallback

    if bunkerDoorItem then
        local option = context:addOption(getText("ContextMenu_InstallEntrance"), worldobjects, BunkersAnywhere.onPlaceObject, playerObj, bunkerDoorItem, "Entrada de Bunker", -1)
        if not BunkersAnywhere.canTeleportTo(playerObj:getX(), playerObj:getY(), playerObj:getZ() - 1) then option.notAvailable = true end
    end

    if bunkerLadderItem then
        local option = context:addOption(getText("ContextMenu_InstallLadder"), worldobjects, BunkersAnywhere.onPlaceObject, playerObj, bunkerLadderItem, "Escalera de Bunker", 1)
        if not BunkersAnywhere.canTeleportTo(playerObj:getX(), playerObj:getY(), playerObj:getZ() + 1) then option.notAvailable = true end
    end

    if bunkerKitItem then
        context:addOption(getText("ContextMenu_UnpackBunkerKit"), bunkerKitItem, BunkersAnywhere.onUnpackBunkerKit, playerObj)
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
        if obj and obj.getModData then
            local modData = obj:getModData()
            if modData and modData.bunkerType then
                targetObj = obj
            elseif BunkersAnywhere.isStair(obj) then
                stairObj = obj
            end
        end
    end

    -- MenÃº para objetos del MOD
    if targetObj then
        local bType = targetObj:getModData().bunkerType
        local optionName = (bType == "Entrada de Bunker") and getText("ContextMenu_EntranceDown") or getText("ContextMenu_LadderUp")
        local submenu = context:addOption(optionName)
        local submenuCtx = ISContextMenu:getNew(context)
        context:addSubMenu(submenu, submenuCtx)
        
        if bType == "Entrada de Bunker" then
            local downOption = submenuCtx:addOption(getText("ContextMenu_GoDownBasement"), targetObj, BunkersAnywhere.onTeleport, playerObj, z - 1)
            if not BunkersAnywhere.canTeleportTo(sq:getX(), sq:getY(), z - 1) then downOption.notAvailable = true end
            submenuCtx:addOption(getText("ContextMenu_UninstallEntrance"), targetObj, BunkersAnywhere.onRemove, playerObj, "Base.BunkerDoor")
        else
            local upOption = submenuCtx:addOption(getText("ContextMenu_GoUpFloor"), targetObj, BunkersAnywhere.onTeleport, playerObj, z + 1)
            if not BunkersAnywhere.canTeleportTo(sq:getX(), sq:getY(), z + 1) then upOption.notAvailable = true end
            submenuCtx:addOption(getText("ContextMenu_UninstallLadder"), targetObj, BunkersAnywhere.onRemove, playerObj, "Base.BunkerLadder")
        end
    end

    -- MenÃº para el BUNKER KIT (sobre escaleras vanilla)
    if stairObj then
        local inv = playerObj:getInventory()
        if inv:containsWithModule("Base.BunkerKit") then
            context:addOption(getText("ContextMenu_InstallBunkerKit"), stairObj, BunkersAnywhere.onInstallBunkerKit, playerObj)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereWorldContext)

local function BunkersAnywhereOnKeyPressed(key)
    if key ~= getCore():getKey("Interact") then return end

    local playerObj = getSpecificPlayer(0)
    if not playerObj or playerObj:isDead() then return end

    -- No interactuar si ya esta haciendo otra accion (TimedAction)
    if not playerObj:getCharacterActions():isEmpty() then return end

    local sq = playerObj:getCurrentSquare()
    if not sq then return end
    
    local targetObj = nil
    
    -- Busca el tile del jugador y los adyacentes (hasta 1 tile de distancia)
    local pX, pY, pZ = playerObj:getX(), playerObj:getY(), playerObj:getZ()
    local cell = getCell()
    
    for x = math.floor(pX) - 1, math.floor(pX) + 1 do
        for y = math.floor(pY) - 1, math.floor(pY) + 1 do
            local searchSq = cell:getGridSquare(x, y, pZ)
            if searchSq then
                local objects = searchSq:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if obj.getModData and type(obj.getModData) == "function" then
                        local md = obj:getModData()
                        if md and md.bunkerType then
                            -- Confirmar que esten en la misma casilla o no esten separados por paredes fisicas
                            if sq == searchSq or not sq:isBlockedTo(searchSq) then
                                targetObj = obj
                                break
                            end
                        end
                    end
                end
            end
            if targetObj then break end
        end
        if targetObj then break end
    end

    if targetObj then
        local bType = targetObj:getModData().bunkerType
        local objSq = targetObj:getSquare()
        local objX, objY, objZ = objSq:getX(), objSq:getY(), objSq:getZ()
        
        if bType == "Entrada de Bunker" then
            if BunkersAnywhere.canTeleportTo(objX, objY, objZ - 1) then
                BunkersAnywhere.onTeleport(targetObj, playerObj, objZ - 1)
            else
                playerObj:setHaloNote(getText("IGUI_Bunker_NoFloorTarget"), 255, 0, 0, 350)
            end
        elseif bType == "Escalera de Bunker" then
            if BunkersAnywhere.canTeleportTo(objX, objY, objZ + 1) then
                BunkersAnywhere.onTeleport(targetObj, playerObj, objZ + 1)
            else
                playerObj:setHaloNote(getText("IGUI_Bunker_NoFloorTarget"), 255, 0, 0, 350)
            end
        end
    end
end

Events.OnKeyPressed.Add(BunkersAnywhereOnKeyPressed)
