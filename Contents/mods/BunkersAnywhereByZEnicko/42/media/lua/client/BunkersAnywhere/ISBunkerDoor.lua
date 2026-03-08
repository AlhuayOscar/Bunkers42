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
    if not playerObj or type(newZ) ~= "number" or type(targetX) ~= "number" or type(targetY) ~= "number" then return end

    local tx = math.floor(targetX)
    local ty = math.floor(targetY)

    -- Centramos al jugador EXACTAMENTE en la escalera/tapa de destino.
    if type(playerObj.setX) == "function" then pcall(function() playerObj:setX(tx + 0.5) end) end
    if type(playerObj.setY) == "function" then pcall(function() playerObj:setY(ty + 0.5) end) end
    if type(playerObj.setZ) == "function" then pcall(function() playerObj:setZ(newZ) end) end

    -- Forzamos actualizacion de coordenadas "last" solo si la API existe.
    if type(playerObj.getX) == "function" and type(playerObj.setLx) == "function" then
        local okX, px = pcall(function() return playerObj:getX() end)
        if okX then pcall(function() playerObj:setLx(px) end) end
    end
    if type(playerObj.getY) == "function" and type(playerObj.setLy) == "function" then
        local okY, py = pcall(function() return playerObj:getY() end)
        if okY then pcall(function() playerObj:setLy(py) end) end
    end
    if type(playerObj.getZ) == "function" and type(playerObj.setLz) == "function" then
        local okZ, pz = pcall(function() return playerObj:getZ() end)
        if okZ then pcall(function() playerObj:setLz(pz) end) end
    end

    local targetSq = nil
    local cell = getCell and getCell() or nil
    if cell and type(cell.getGridSquare) == "function" then
        local okSq, sq = pcall(function() return cell:getGridSquare(tx, ty, newZ) end)
        if okSq then targetSq = sq end
    end

    if targetSq and type(playerObj.setCurrent) == "function" then
        pcall(function() playerObj:setCurrent(targetSq) end)
    end
end
function BunkersAnywhere.canTeleportTo(sqX, sqY, targetZ)
    if type(sqX) ~= "number" or type(sqY) ~= "number" or type(targetZ) ~= "number" then return false end
    if targetZ < -32 or targetZ > 7 then return false end

    local cell = getCell and getCell() or nil
    if not cell then return false end

    local okSquare, square = pcall(function()
        return cell:getGridSquare(math.floor(sqX), math.floor(sqY), targetZ)
    end)
    if not okSquare or not square then return false end

    if square:getFloor() == nil and square:getRoom() == nil then return false end

    -- Verificar si el tile destino esta libre de solidos (paredes, muebles, etc.)
    local objs = square:getObjects()
    if not objs then return true end

    local solidFlag = IsoFlagType and IsoFlagType.solid or nil
    local solidTransFlag = IsoFlagType and IsoFlagType.solidtrans or nil

    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o then
            local props = nil
            if type(o.getProperties) == "function" then
                local okProps, resultProps = pcall(function() return o:getProperties() end)
                if okProps then props = resultProps end
            end

            local isSolid = false
            if props and type(props.Is) == "function" then
                if solidFlag then
                    local okSolid, hasSolid = pcall(function() return props:Is(solidFlag) end)
                    if okSolid and hasSolid then isSolid = true end
                end
                if (not isSolid) and solidTransFlag then
                    local okSolidTrans, hasSolidTrans = pcall(function() return props:Is(solidTransFlag) end)
                    if okSolidTrans and hasSolidTrans then isSolid = true end
                end
            end

            if isSolid then
                -- Ignorar los objetos del mismo mod, para no bloquear.
                local isBunkerObject = false
                if type(o.getModData) == "function" then
                    local okModData, md = pcall(function() return o:getModData() end)
                    if okModData and md and md.bunkerType then
                        isBunkerObject = true
                    end
                end
                if not isBunkerObject then
                    return false
                end
            end
        end
    end

    return true
end

function BunkersAnywhere.findDestination(fromSq, newZ, destType)
    if not fromSq or type(newZ) ~= "number" then return nil, nil end

    local cell = getCell and getCell() or nil
    if not cell then return nil, nil end

    local baseX = fromSq:getX()
    local baseY = fromSq:getY()

    local function findOnSquare(sq)
        if not sq then return nil, nil end
        local objs = sq:getObjects()
        if not objs then return nil, nil end

        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            if o and type(o.getModData) == "function" then
                local okMd, md = pcall(function() return o:getModData() end)
                if okMd and md and md.bunkerType == destType then
                    return sq:getX() + 0.5, sq:getY() + 0.5
                end
            end
        end

        return nil, nil
    end

    local okSame, sameSq = pcall(function() return cell:getGridSquare(baseX, baseY, newZ) end)
    if okSame and sameSq then
        local dx, dy = findOnSquare(sameSq)
        if dx and dy then return dx, dy end
    end

    for radius = 1, 2 do
        for x = baseX - radius, baseX + radius do
            for y = baseY - radius, baseY + radius do
                local okSq, sq = pcall(function() return cell:getGridSquare(x, y, newZ) end)
                if okSq and sq then
                    local dx, dy = findOnSquare(sq)
                    if dx and dy then return dx, dy end
                end
            end
        end
    end

    if BunkersAnywhere.canTeleportTo(baseX, baseY, newZ) then
        return baseX + 0.5, baseY + 0.5
    end

    for radius = 1, 3 do
        for x = baseX - radius, baseX + radius do
            for y = baseY - radius, baseY + radius do
                if BunkersAnywhere.canTeleportTo(x, y, newZ) then
                    return x + 0.5, y + 0.5
                end
            end
        end
    end

    return nil, nil
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
    if not targetObj or not playerObj or type(newZ) ~= "number" then return end

    local targetSq = targetObj:getSquare()
    if not targetSq then return end

    local x, y, z = targetSq:getX(), targetSq:getY(), targetSq:getZ()

    local md = nil
    if type(targetObj.getModData) == "function" then
        local okMd, resultMd = pcall(function() return targetObj:getModData() end)
        if okMd then md = resultMd end
    end
    local bType = md and md.bunkerType or nil
    if not bType then return end

    local destType = (bType == "Entrada de Bunker") and "Escalera de Bunker" or "Entrada de Bunker"
    local destX, destY = BunkersAnywhere.findDestination(targetSq, newZ, destType)
    if not destX or not destY then
        playerObj:setHaloNote(getText("IGUI_Bunker_NoFloorTarget"), 255, 0, 0, 350)
        return
    end

    local pSq = playerObj:getCurrentSquare()
    local sameZ = math.abs(playerObj:getZ() - z) < 0.5
    local distX = math.abs(playerObj:getX() - (x + 0.5))
    local distY = math.abs(playerObj:getY() - (y + 0.5))
    local blocked = false

    if pSq and targetSq and pSq ~= targetSq then
        if type(pSq.isBlockedTo) == "function" then
            local okBlocked, isBlocked = pcall(function() return pSq:isBlockedTo(targetSq) end)
            if okBlocked and isBlocked then blocked = true end
        end
    end

    -- Si estamos en un tile adyacente o en el mismo, interceptamos para no caminar
    if distX < 1.5 and distY < 1.5 and sameZ then
        if blocked then
            -- Si esta bloqueado (ej: separado por pared o barandilla), simplemente salimos.
            -- Asi presionando 'E' el personaje no saltara ni correra hacia otra escalera.
            return
        end
        if type(playerObj.faceThisObject) == "function" then
            playerObj:faceThisObject(targetObj)
        end
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
    if not worldobjects then return end
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    local z = playerObj:getZ()

    local targetObj = nil
    local stairObj = nil
    local function scanSquare(sq)
        if not sq then return end
        local objects = sq:getObjects()
        if not objects then return end
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
    end

    if worldobjects.size and worldobjects.get then
        for i = 0, worldobjects:size() - 1 do
            local wo = worldobjects:get(i)
            local sq = wo and wo.getSquare and wo:getSquare() or nil
            scanSquare(sq)
            if targetObj and stairObj then break end
        end
    else
        for _, wo in ipairs(worldobjects) do
            local sq = wo and wo.getSquare and wo:getSquare() or nil
            scanSquare(sq)
            if targetObj and stairObj then break end
        end
    end

    if not targetObj or not stairObj then
        scanSquare(playerObj:getSquare())
    end

    -- Men� para objetos del MOD
    if targetObj then
        local sq = targetObj:getSquare()
        if not sq then return end
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

    -- Men� para el BUNKER KIT (sobre escaleras vanilla)
    if stairObj then
        local inv = playerObj:getInventory()
        if inv:containsWithModule("Base.BunkerKit") then
            context:addOption(getText("ContextMenu_InstallBunkerKit"), stairObj, BunkersAnywhere.onInstallBunkerKit, playerObj)
        end
    end
end
local function BunkersAnywhereWorldContextSafe(player, context, worldobjects, test)
    local ok, err = pcall(BunkersAnywhereWorldContext, player, context, worldobjects, test)
    if not ok then
        print("[BunkersAnywhere] DoorWorldContext error: " .. tostring(err))
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereWorldContextSafe)

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
                            local canUse = (sq == searchSq)
                            if (not canUse) and type(sq.isBlockedTo) == "function" then
                                local okBlocked, isBlocked = pcall(function() return sq:isBlockedTo(searchSq) end)
                                canUse = (okBlocked and not isBlocked) or (not okBlocked)
                            end
                            if canUse then
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
