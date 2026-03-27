local BASubterraData = require("BunkersAnywhere/BASubterraData")

local BASubterraAPI = {}

BASubterraAPI.MIN_Z = -32
BASubterraAPI.STONE_LEVEL = -2
BASubterraAPI.DIRT_SACKS_ROOM = 3
BASubterraAPI.DIRT_SACKS_ACCESS = 6
BASubterraAPI.DEBUG_CLIMATE = true
BASubterraAPI.SANDBOX_NAMESPACE = "BunkersAnywhereByZEnicko"
BASubterraAPI.SANDBOX_OPTION = "BasementExpansionExperimental"

BASubterraAPI.Sprites = {
    WallWest = "walls_underground_dirt_1",
    WallNorth = "walls_underground_dirt_0",
    CornerNorthWest = "walls_underground_dirt_2",
    CornerSouthEast = "walls_underground_dirt_3",
    Floor = "blends_natural_01_64",
    StoneWallWest = "walls_logs_96",
    StoneWallNorth = "walls_logs_97",
    StoneCornerNorthWest = "walls_logs_98",
    StoneCornerSouthEast = "walls_logs_99",
    StoneFloor = "floors_exterior_street_01_0",
    Entrance = "street_decoration_01_15",
    Ladder = "location_sewer_01_32",
}

BASubterraAPI.DIRT = {
    wallNorth = BASubterraAPI.Sprites.WallNorth,
    wallWest = BASubterraAPI.Sprites.WallWest,
    wallCornerNorthwest = BASubterraAPI.Sprites.CornerNorthWest,
    wallCornerSoutheast = BASubterraAPI.Sprites.CornerSouthEast,
    floor = BASubterraAPI.Sprites.Floor,
}

BASubterraAPI.STONE = {
    wallNorth = BASubterraAPI.Sprites.StoneWallNorth,
    wallWest = BASubterraAPI.Sprites.StoneWallWest,
    wallCornerNorthwest = BASubterraAPI.Sprites.StoneCornerNorthWest,
    wallCornerSoutheast = BASubterraAPI.Sprites.StoneCornerSouthEast,
    floor = BASubterraAPI.Sprites.StoneFloor,
}

local CELL
Events.OnPostMapLoad.Add(function(cell)
    CELL = cell
end)

local function getCellRef()
    return CELL or getCell()
end

function BASubterraAPI.isEnabled()
    local sandbox = SandboxVars and SandboxVars[BASubterraAPI.SANDBOX_NAMESPACE] or nil
    if not sandbox then
        return false
    end

    return sandbox[BASubterraAPI.SANDBOX_OPTION] == true
end

local DIGGABLE_SPRITES = {}
for _, sprite in pairs(BASubterraAPI.DIRT) do
    DIGGABLE_SPRITES[sprite] = true
end
for _, sprite in pairs(BASubterraAPI.STONE) do
    DIGGABLE_SPRITES[sprite] = true
end

local invalidatedChunkLevels = {}

local function isEmptyTable(t)
    for _, _ in pairs(t) do
        return false
    end
    return true
end

Events.OnTick.Add(function()
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player then
            local z = math.floor(player:getZ())
            if invalidatedChunkLevels[z] then
                local zChunks = invalidatedChunkLevels[z]
                local chunk = player:getChunk()
                if chunk then
                    local x = chunk.wx
                    if zChunks[x] then
                        local y = chunk.wy
                        if zChunks[x][y] then
                            chunk:invalidateRenderChunkLevel(z, FBORenderChunk.DIRTY_OBJECT_ADD)
                            zChunks[x][y] = nil
                            if isEmptyTable(zChunks[x]) then
                                zChunks[x] = nil
                                if isEmptyTable(zChunks) then
                                    invalidatedChunkLevels[z] = nil
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

local function queueChunkRefresh(x, y, z)
    x = (x - x % 8) / 8
    y = (y - y % 8) / 8
    invalidatedChunkLevels[z] = invalidatedChunkLevels[z] or {}
    invalidatedChunkLevels[z][x] = invalidatedChunkLevels[z][x] or {}
    invalidatedChunkLevels[z][x][y] = true
end

local function objectHasProperty(object, flag)
    if not object then
        return false
    end

    if object.hasProperty then
        local ok, value = pcall(function() return object:hasProperty(flag) end)
        if ok and value then
            return true
        end
    end

    local props = object.getProperties and object:getProperties() or nil
    if props and props.Is then
        local ok, value = pcall(function() return props:Is(flag) end)
        if ok and value then
            return true
        end
    end

    return false
end

local function itemHasTag(item, tag)
    if not item or not item.hasTag then
        return false
    end

    local ok, value = pcall(function()
        return item:hasTag(tag)
    end)
    return ok and value or false
end

local function itemIsBroken(item)
    if not item or not item.isBroken then
        return false
    end

    local ok, value = pcall(function()
        return item:isBroken()
    end)
    return ok and value or false
end

function BASubterraAPI.canCarryDirt(item)
    if not itemHasTag(item, ItemTag.HOLD_DIRT) then
        return false
    end

    local inventory = item.getInventory and item:getInventory() or nil
    return inventory and inventory:isEmpty() or false
end

function BASubterraAPI.canDigDirt(item)
    return not itemIsBroken(item)
        and (itemHasTag(item, ItemTag.DIG_GRAVE) or itemHasTag(item, ItemTag.TAKE_DIRT))
end

function BASubterraAPI.canDigStone(item)
    return not itemIsBroken(item) and itemHasTag(item, ItemTag.PICK_AXE)
end

function BASubterraAPI.isDiggableSpriteName(spriteName)
    return spriteName and DIGGABLE_SPRITES[spriteName] == true or false
end

function BASubterraAPI.getOrCreateSquare(x, y, z)
    local square = getSquare(x, y, z)
    if square then
        return square
    end

    local cell = getCellRef()
    if not cell then
        return nil
    end

    if z < 0 and z % 2 ~= 0 then
        local chunk = cell:getChunkForGridSquare(x, y, z)
        if chunk then
            local minLevel = chunk:getMinLevel()
            if minLevel < z - 1 then
                chunk:setMinMaxLevel(z - 1, chunk:getMaxLevel())
            end
        end
    end

    return cell:createNewGridSquare(x, y, z, true)
end

function BASubterraAPI.getFirst(square, flag)
    if not square then
        return nil
    end

    local objects = square:getLuaTileObjectList()
    for i = 1, #objects do
        local object = objects[i]
        if objectHasProperty(object, flag) then
            return object
        end
    end
end

function BASubterraAPI.getWall(square, side)
    if not square then
        return nil
    end

    if side == "northwest" then
        return square:getWallNW()
    end

    if side == "southeast" then
        return square:getWallSE()
    end

    if side == "north" then
        return BASubterraAPI.getFirst(square, IsoFlagType.WallN) or BASubterraAPI.getFirst(square, IsoFlagType.WallNW)
    end

    if side == "west" then
        return BASubterraAPI.getFirst(square, IsoFlagType.WallW) or BASubterraAPI.getFirst(square, IsoFlagType.WallNW)
    end

    return nil
end

function BASubterraAPI.removeAll(square, flag)
    if not square then
        return
    end

    local objects = square:getLuaTileObjectList()
    for i = #objects, 1, -1 do
        local object = objects[i]
        if objectHasProperty(object, flag) then
            square:transmitRemoveItemFromSquare(object)
        end
    end
end

function BASubterraAPI.removeFloor(square, removeAttached)
    if not square then
        return
    end

    if removeAttached == nil then
        removeAttached = true
    end

    local floor = square:getFloor()
    if floor then
        square:transmitRemoveItemFromSquare(floor)
    end

    if removeAttached then
        BASubterraAPI.removeAll(square, IsoFlagType.attachedFloor)
    end
end

function BASubterraAPI.removeWall(square, side, removeAttached)
    if not square then
        return
    end

    if removeAttached == nil then
        removeAttached = true
    end

    local wall = square:getWall(side == "north")
    if not wall then
        return
    end

    local wantedWall = side == "north" and "CornerWestWall" or "CornerNorthWall"
    if wall:hasProperty(wantedWall) then
        local newWall = IsoObject.getNew(square, wall:getProperty(wantedWall), "", false)
        square:transmitAddObjectToSquare(newWall, -1)
    end

    square:transmitRemoveItemFromSquare(wall)

    if removeAttached then
        BASubterraAPI.removeAll(square, side == "north" and IsoFlagType.attachedN or IsoFlagType.attachedW)
    end
end

local function removeBlacklistedObjects(square)
    if not square then
        return
    end

    local objects = square:getLuaTileObjectList()
    for i = #objects, 1, -1 do
        local object = objects[i]
        local sprite = object and object.getSprite and object:getSprite() or nil
        local spriteName = sprite and sprite.getName and sprite:getName() or nil
        if spriteName == "underground_01_0" or spriteName == "underground_01_1" then
            square:transmitRemoveItemFromSquare(object)
            break
        end
    end
end

function BASubterraAPI.isOpenSquare(square)
    if not square then
        return false
    end
    return square:hasFloor() or BASubterraData.isFloorRemoved(square)
end

function BASubterraAPI.isSubterraSquare(square)
    if not square or square:getZ() >= 0 then
        return false
    end

    return BASubterraAPI.isOpenSquare(square)
end

function BASubterraAPI.isCoveredSquare(square)
    if not BASubterraAPI.isSubterraSquare(square) then
        return false
    end

    local x = square:getX()
    local y = square:getY()

    for z = square:getZ() + 1, 0 do
        local aboveSquare = getSquare(x, y, z)
        if not aboveSquare then
            return false
        end

        if BASubterraData.isFloorRemoved(aboveSquare) then
            return false
        end

        if not aboveSquare:hasFloor() then
            return false
        end
    end

    return true
end

function BASubterraAPI.getShelterState(square)
    if not BASubterraAPI.isSubterraSquare(square) then
        return "none"
    end

    if BASubterraAPI.isCoveredSquare(square) then
        return "covered"
    end

    return "open-shaft"
end

function BASubterraAPI.characterCanDig(character, material)
    if not character then
        return false, "Tooltip_BASubterraBlocked"
    end

    local stats = character:getStats()
    if not stats or not stats:isAboveMinimum(CharacterStat.ENDURANCE) then
        return false, "Tooltip_BASubterraTooExhausted"
    end

    local inventory = character:getInventory()
    if material == "stone" then
        if not inventory:containsEvalRecurse(BASubterraAPI.canDigStone) then
            return false, "Tooltip_BASubterraNeedPickaxe"
        end
    else
        if not inventory:containsEvalRecurse(BASubterraAPI.canDigDirt) then
            return false, "Tooltip_BASubterraNeedShovel"
        end
    end

    return true
end

function BASubterraAPI.getMaterialAtCoords(x, y, z)
    if z >= 0 then
        return nil
    end
    if z >= BASubterraAPI.STONE_LEVEL then
        return "dirt"
    end
    return "stone"
end

function BASubterraAPI.getMaterialAt(square)
    if not square then
        return nil
    end
    return BASubterraAPI.getMaterialAtCoords(square:getX(), square:getY(), square:getZ())
end

function BASubterraAPI.canDig(square)
    if not square then
        return false, "Tooltip_BASubterraBlocked"
    end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local aboveSquare = getSquare(x, y, z + 1)
    if aboveSquare and aboveSquare:isWaterSquare() then
        return false, "Tooltip_BASubterraWaterTile"
    end

    return true
end

function BASubterraAPI.isDiggableFloor(floor)
    if not floor or not floor.getSprite or not floor:getSprite() then
        return false
    end

    local spriteName = floor:getSprite():getName()
    if spriteName == BASubterraAPI.DIRT.floor
            or spriteName == BASubterraAPI.STONE.floor
            or luautils.stringStarts(spriteName, "floors_street_01")
            or luautils.stringStarts(spriteName, "floors_exterior_natural")
            or luautils.stringStarts(spriteName, "blends_natural_01") then
        return true
    end

    return false
end

function BASubterraAPI.canDigDownFrom(square)
    if not square then
        return false
    end

    local z = square:getZ()
    if z < 0 or z <= BASubterraAPI.MIN_Z then
        return false
    end

    local floor = square:getFloor()
    if not floor or not BASubterraAPI.isDiggableFloor(floor) then
        return false
    end

    local lowerSquare = getSquare(square:getX(), square:getY(), z - 1)
    if lowerSquare and lowerSquare:hasFloor() then
        return false
    end

    return true
end

function BASubterraAPI.isSquareClear(square, orientation, exclude)
    if not square then
        return false
    end

    if square.Is then
        local ok, blocked = pcall(function()
            return square:Is("BlocksPlacement")
        end)
        if ok and blocked then
            return false
        end
    end

    if orientation then
        local isSouth = orientation == "south"
        local objects = square:getLuaTileObjectList()
        for i = 1, #objects do
            local object = objects[i]
            local sprite = object and object.getSprite and object:getSprite() or nil
            local properties = sprite and sprite.getProperties and sprite:getProperties() or nil
            if (properties and properties.Is and properties:Is(isSouth and IsoFlagType.collideN or IsoFlagType.collideW))
                    or ((instanceof(object, "IsoThumpable") and object.getNorth and object:getNorth() == isSouth) and not object:isCorner() and not object:isFloor())
                    or (instanceof(object, "IsoWindow") and object.getNorth and object:getNorth() == isSouth)
                    or (instanceof(object, "IsoDoor") and object.getNorth and object:getNorth() == isSouth) then
                return false
            end
        end
    end

    local movingObjects = square:getLuaMovingObjectList()
    return #movingObjects == 0 or (#movingObjects == 1 and movingObjects[1] == exclude)
end

function BASubterraAPI.isInPlayableArea(square)
    if not square then
        return false
    end

    if square:hasFloor() then
        return true
    end

    local x, y = square:getX(), square:getY()
    for z = square:getZ() - 1, BASubterraAPI.MIN_Z, -1 do
        local lowerSquare = getSquare(x, y, z)
        if not lowerSquare then
            return false
        end
        if lowerSquare:hasFloor() then
            return true
        end
    end

    return false
end

local function touchSquare(square)
    if not square then
        return
    end

    if square.RecalcAllWithNeighbours then
        square:RecalcAllWithNeighbours(true)
    elseif square.RecalcProperties then
        square:RecalcProperties()
    end
    if square.setSquareChanged then
        square:setSquareChanged()
    end
    if square.flagForHotSave then
        square:flagForHotSave()
    end
end

function BASubterraAPI.findNearbyFloorSprite(cx, cy, cz)
    local offsets = {
        { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        { 1, 1 }, { -1, -1 }, { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 },
    }

    for _, off in ipairs(offsets) do
        local sx, sy = cx + off[1], cy + off[2]
        local sq = getSquare(sx, sy, cz)
        if sq then
            local floorObj = sq:getFloor()
            if floorObj and floorObj:getSprite() then
                return floorObj:getSprite():getName()
            end
        end
    end

    for _, off in ipairs(offsets) do
        local sx, sy = cx + off[1], cy + off[2]
        local sq = getSquare(sx, sy, cz - 1)
        if sq then
            local floorObj = sq:getFloor()
            if floorObj and floorObj:getSprite() then
                return floorObj:getSprite():getName()
            end
        end
    end

    return nil
end

function BASubterraAPI.restoreFloor(square, spriteName)
    if not square then
        return
    end

    local desired = spriteName or BASubterraAPI.Sprites.Floor
    local floor = square:getFloor()
    if floor and floor:getSprite() and floor:getSprite():getName() ~= desired then
        square:transmitRemoveItemFromSquare(floor)
        floor = nil
    end

    if not floor then
        local obj = IsoObject.getNew(square, desired, "", false)
        square:transmitAddObjectToSquare(obj, -1)
    end

    BASubterraData.clearFloorRemoved(square)
    touchSquare(square)
    queueChunkRefresh(square:getX(), square:getY(), square:getZ())
end

function BASubterraAPI.digFloor(square)
    if not square then
        return
    end

    BASubterraAPI.removeFloor(square)
    BASubterraAPI.removeAll(square, IsoFlagType.canBeRemoved)
    BASubterraData.onFloorRemoved(square)
    touchSquare(square)
    queueChunkRefresh(square:getX(), square:getY(), square:getZ())
end

local function addCornerIfNeeded(x, y, z, material)
    local square = BASubterraAPI.getOrCreateSquare(x, y, z)
    if square and not square:getWall() then
        local obj = IsoObject.getNew(square, material.wallCornerSoutheast, "", false)
        square:transmitAddObjectToSquare(obj, -1)
    end
end

local function removeCorner(square)
    if not square then
        return
    end

    local corner = square:getWallSE()
    if not corner or not corner:getSprite() then
        return
    end

    local spriteName = corner:getSprite():getName()
    if spriteName == BASubterraAPI.DIRT.wallCornerSoutheast
            or spriteName == BASubterraAPI.STONE.wallCornerSoutheast then
        square:transmitRemoveItemFromSquare(corner)
    end
end

local function digWall(square, side)
    local wall = BASubterraAPI.getWall(square, side)
    if wall and wall:getSprite() and DIGGABLE_SPRITES[wall:getSprite():getName()] then
        BASubterraAPI.removeWall(square, side)
    end
end

local function addWall(square, material, side)
    if not square or BASubterraAPI.getWall(square, side) then
        return
    end

    local spriteName
    local otherWall = BASubterraAPI.getWall(square, side == "north" and "west" or "north")
    if otherWall and otherWall:getSprite() then
        local otherName = otherWall:getSprite():getName()
        if otherName == (side == "north" and material.wallWest or material.wallNorth) then
            square:transmitRemoveItemFromSquare(otherWall)
            spriteName = material.wallCornerNorthwest
        end
    end

    if not spriteName then
        spriteName = side == "north" and material.wallNorth or material.wallWest
    end

    local obj = IsoObject.getNew(square, spriteName, "", false)
    square:transmitAddObjectToSquare(obj, -1)
    removeCorner(square)
end

function BASubterraAPI.digSquare(x, y, z)
    local square = BASubterraAPI.getOrCreateSquare(x, y, z)
    if not square then
        return nil
    end

    removeBlacklistedObjects(square)

    local floorMaterial = z <= BASubterraAPI.STONE_LEVEL and BASubterraAPI.STONE or BASubterraAPI.DIRT
    if not square:getFloor() then
        local obj = IsoObject.getNew(square, floorMaterial.floor, "", false)
        square:transmitAddObjectToSquare(obj, -1)
    end

    local wallMaterial = z < BASubterraAPI.STONE_LEVEL and BASubterraAPI.STONE or BASubterraAPI.DIRT
    local southOrEastWallAdded = false
    local southEastSquare = BASubterraAPI.getOrCreateSquare(x + 1, y + 1, z)

    local southSquare = BASubterraAPI.getOrCreateSquare(x, y + 1, z)
    if BASubterraAPI.isOpenSquare(southSquare) then
        digWall(southSquare, "north")
        removeCorner(southEastSquare)
    else
        addWall(southSquare, wallMaterial, "north")
        southOrEastWallAdded = true
    end
    removeBlacklistedObjects(southSquare)

    local eastSquare = BASubterraAPI.getOrCreateSquare(x + 1, y, z)
    if BASubterraAPI.isOpenSquare(eastSquare) then
        digWall(eastSquare, "west")
        removeCorner(southEastSquare)
    else
        addWall(eastSquare, wallMaterial, "west")
        southOrEastWallAdded = true
    end
    removeBlacklistedObjects(eastSquare)

    if southOrEastWallAdded then
        addCornerIfNeeded(x + 1, y + 1, z, wallMaterial)
    end

    local needsCornerAdded = true
    local northOrWestWallAdded = false

    local northSquare = BASubterraAPI.getOrCreateSquare(x, y - 1, z)
    if BASubterraAPI.isOpenSquare(northSquare) then
        digWall(square, "north")
        removeCorner(eastSquare)
        needsCornerAdded = needsCornerAdded and BASubterraAPI.getWall(square, "west") ~= nil
    else
        addWall(square, wallMaterial, "north")
        addCornerIfNeeded(x + 1, y, z, wallMaterial)
        northOrWestWallAdded = true
    end
    removeBlacklistedObjects(northSquare)

    local westSquare = BASubterraAPI.getOrCreateSquare(x - 1, y, z)
    if BASubterraAPI.isOpenSquare(westSquare) then
        digWall(square, "west")
        removeCorner(southSquare)
        needsCornerAdded = needsCornerAdded and BASubterraAPI.getWall(square, "north") ~= nil
    else
        addWall(square, wallMaterial, "west")
        addCornerIfNeeded(x, y + 1, z, wallMaterial)
        northOrWestWallAdded = true
    end
    removeBlacklistedObjects(westSquare)

    if needsCornerAdded then
        local obj = IsoObject.getNew(square, wallMaterial.wallCornerSoutheast, "", false)
        square:transmitAddObjectToSquare(obj, -1)
    end

    if northOrWestWallAdded then
        removeCorner(square)
    end

    buildUtil.setHaveConstruction(square, true)
    square:setSquareChanged()

    for xOffset = -1, 1, 2 do
        for yOffset = -1, 1, 2 do
            local cornerSquare = getSquare(x + xOffset, y + yOffset, z)
            if cornerSquare then
                removeBlacklistedObjects(square)
            end
        end
    end

    queueChunkRefresh(x, y, z)

    return square
end

return BASubterraAPI
