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
    
    -- Si al quitar el objeto no queda suelo, ponemos tablones (evita caer al vacío)
    BunkersAnywhere.ensureFloor(sq)

    playerObj:getInventory():AddItem(itemFullType)
    playerObj:setHaloNote("Objeto recogido", 200, 200, 200, 300)
end

-- Función para detectar si un objeto es una escalera (por flags o nombre de sprite)
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

-- FUNCIÓN: Asegurar que una casilla tenga suelo (y guardarla permanentemente)
function BunkersAnywhere.ensureFloor(sq)
    if not sq then return end
    
    -- 1. Si no hay suelo, lo añadimos (carpentry_02_57 es el tablón de madera estándar)
    if not sq:getFloor() then
        local newFloor = sq:addFloor("carpentry_02_57")
        if isClient() and newFloor then
            newFloor:transmitCompleteItemToServer()
        end
    end
    
    -- 2. RECALCULAR VISIBILIDAD Y LUCES (Defensivo para B42)
    if sq.RecalcAllWithNeighbours then
        sq:RecalcAllWithNeighbours(true)
    elseif sq.RecalcAllWithNeighbor then
        sq:RecalcAllWithNeighbor(true)
    else
        sq:RecalcProperties()
    end
    
    -- 3. Marcar como modificado para el motor y GUARDADO permanente (HotSave)
    if sq.EnsureSurroundNotNull then sq:EnsureSurroundNotNull() end
    if sq.setSquareChanged then sq:setSquareChanged() end
    if sq.flagForHotSave then sq:flagForHotSave() end
    if sq.getChunk then
        local chunk = sq:getChunk()
        if chunk and chunk.setHasDirtyObjects then chunk:setHasDirtyObjects(true) end
    end
    
    -- 4. Asegurarnos de que el jugador "conozca" el cuadrado para que no sea negro
    if sq.setIsExplored then sq:setIsExplored(true) end
    
    -- 5. Forzar transmisión en Multijugador
    if isClient() then
        sq:transmitCompleteSquareToServer()
    end
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
            
            -- NIVEL DE ABAJO (Z): Quitar escalera y asegurar suelo
            local s = cell:getGridSquare(currentX, currentY, z)
            if not s then
                s = IsoGridSquare.new(cell, nil, currentX, currentY, z)
                cell:ConnectNewSquare(s, false)
            end
            
            if s then
                local objs = s:getObjects()
                for i = objs:size() - 1, 0, -1 do
                    local o = objs:get(i)
                    if BunkersAnywhere.isStair(o) then
                        s:RemoveTileObject(o)
                    end
                end
                -- Aseguramos suelo abajo también
                BunkersAnywhere.ensureFloor(s)
            end

            -- NIVEL DE ARRIBA (Z+1): Tapar agujeros (SUELO PERMANENTE)
            local tSq = cell:getGridSquare(currentX, currentY, topZ)
            if not tSq then
                tSq = IsoGridSquare.new(cell, nil, currentX, currentY, topZ)
                cell:ConnectNewSquare(tSq, false)
            end
            
            if tSq then
                -- Si no hay suelo, lo añadimos y sincronizamos (Usando la nueva función)
                BunkersAnywhere.ensureFloor(tSq)
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

-- FUNCIÓN: Desempaquetar el Kit
function BunkersAnywhere.unpackBunkerKit(kitItem, playerObj)
    local inv = playerObj:getInventory()
    inv:Remove(kitItem)
    inv:AddItem("Base.BunkerDoor")
    inv:AddItem("Base.BunkerLadder")
    inv:AddItem("Base.Hammer")
    playerObj:setHaloNote("Kit desempaquetado", 0, 255, 0, 300)
end

-- ==========================================================
-- Timed Action: Acción Genérica del Bunker (Instalar/Subir/Bajar)
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
-- Wrappers para forzar TimedActions en los Menús
-- ==========================================================

function BunkersAnywhere.onInstallBunkerKit(stairObj, playerObj)
    if luautils.walk(playerObj, stairObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, stairObj:getSquare(), 250, "Loot", "Carpentry", BunkersAnywhere.useBunkerKit, stairObj, playerObj))
    end
end

function BunkersAnywhere.onTeleport(targetObj, playerObj, newZ)
    if luautils.walk(playerObj, targetObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, targetObj:getSquare(), 25, "Loot", nil, BunkersAnywhere.teleportToZ, playerObj, newZ))
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
        local option = context:addOption("Instalar Entrada (Solo Bajar)", worldobjects, BunkersAnywhere.onPlaceObject, playerObj, bunkerDoorItem, "Entrada de Bunker", -1)
        if not BunkersAnywhere.canTeleportTo(playerObj, playerObj:getZ() - 1) then option.notAvailable = true end
    end

    if bunkerLadderItem then
        local option = context:addOption("Instalar Escalera (Solo Subir)", worldobjects, BunkersAnywhere.onPlaceObject, playerObj, bunkerLadderItem, "Escalera de Bunker", 1)
        if not BunkersAnywhere.canTeleportTo(playerObj, playerObj:getZ() + 1) then option.notAvailable = true end
    end

    if bunkerKitItem then
        context:addOption("Desempaquetar Kit de Bunker", bunkerKitItem, BunkersAnywhere.onUnpackBunkerKit, playerObj)
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
            local downOption = submenuCtx:addOption("Bajar al Sotano (Z-1)", targetObj, BunkersAnywhere.onTeleport, playerObj, z - 1)
            if not BunkersAnywhere.canTeleportTo(playerObj, z - 1) then downOption.notAvailable = true end
            submenuCtx:addOption("Desinstalar Entrada", targetObj, BunkersAnywhere.onRemove, playerObj, "Base.BunkerDoor")
        else
            local upOption = submenuCtx:addOption("Subir a Planta Baja (Z+1)", targetObj, BunkersAnywhere.onTeleport, playerObj, z + 1)
            if not BunkersAnywhere.canTeleportTo(playerObj, z + 1) then upOption.notAvailable = true end
            submenuCtx:addOption("Desinstalar Escalera", targetObj, BunkersAnywhere.onRemove, playerObj, "Base.BunkerLadder")
        end
    end

    -- Menú para el BUNKER KIT (sobre escaleras vanilla)
    if stairObj then
        local inv = playerObj:getInventory()
        if inv:contains("BunkerKit") then
            context:addOption("Instalar Kit de Bunker (Sustituir Escaleras)", stairObj, BunkersAnywhere.onInstallBunkerKit, playerObj)
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
                    if obj:getModData().bunkerType then
                        -- Encontramos un objeto de bunker, lo guardamos si esta suficientemente cerca
                        targetObj = obj
                        break
                    end
                end
            end
            if targetObj then break end
        end
        if targetObj then break end
    end

    if targetObj then
        local bType = targetObj:getModData().bunkerType
        if bType == "Entrada de Bunker" then
            if BunkersAnywhere.canTeleportTo(playerObj, pZ - 1) then
                BunkersAnywhere.onTeleport(targetObj, playerObj, pZ - 1)
            end
        elseif bType == "Escalera de Bunker" then
            if BunkersAnywhere.canTeleportTo(playerObj, pZ + 1) then
                BunkersAnywhere.onTeleport(targetObj, playerObj, pZ + 1)
            end
        end
    end
end

Events.OnKeyPressed.Add(BunkersAnywhereOnKeyPressed)
