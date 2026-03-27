local BASubterraData = require("BunkersAnywhere/BASubterraData")

local BASubterraAPI = {}

BASubterraAPI.MIN_Z = -32
BASubterraAPI.STONE_LEVEL = -2
BASubterraAPI.DIRT_SACKS_ROOM = 3
BASubterraAPI.DIRT_SACKS_ACCESS = 6

BASubterraAPI.Sprites = {
    WallWest = "walls_interior_01_16",
    WallNorth = "walls_interior_01_17",
    CornerNorthWest = "walls_interior_01_18",
    Floor = "floors_street_01_16",
    Entrance = "street_decoration_01_15",
    Ladder = "location_sewer_01_32",
}

local CELL
Events.OnPostMapLoad.Add(function(cell)
    CELL = cell
end)

local function getCellRef()
    return CELL or getCell()
end

local DIGGABLE_SPRITES = {
    [BASubterraAPI.Sprites.WallWest] = true,
    [BASubterraAPI.Sprites.WallNorth] = true,
    [BASubterraAPI.Sprites.CornerNorthWest] = true,
    [BASubterraAPI.Sprites.Floor] = true,
}

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

function BASubterraAPI.canCarryDirt(item)
    return item and item.hasTag and item:hasTag("HoldDirt") or false
end

function BASubterraAPI.canDigDirt(item)
    return item and item.hasTag and item:hasTag("DigGrave") and not item:isBroken() or false
end

function BASubterraAPI.canDigStone(item)
    return item and item.hasTag and item:hasTag("PickAxe") and not item:isBroken() or false
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

function BASubterraAPI.characterCanDig(character, material)
    if not character then
        return false, "Tooltip_BASubterraBlocked"
    end

    if character:getMoodles():getMoodleLevel(MoodleType.Endurance) > 1 then
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

function BASubterraAPI.canDigDownFrom(square)
    if not square then
        return false
    end

    local z = square:getZ()
    if z < 0 or z <= BASubterraAPI.MIN_Z then
        return false
    end

    if not square:hasFloor() then
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

    if square:Is("BlocksPlacement") then
        return false
    end

    if orientation then
        local isSouth = orientation == "south"
        local objects = square:getLuaTileObjectList()
        for i = 1, #objects do
            local object = objects[i]
            local sprite = object:getSprite()
            if (sprite and sprite:getProperties():Is(isSouth and IsoFlagType.collideN or IsoFlagType.collideW))
                    or ((instanceof(object, "IsoThumpable") and object:getNorth() == isSouth) and not object:isCorner() and not object:isFloor())
                    or (instanceof(object, "IsoWindow") and object:getNorth() == isSouth)
                    or (instanceof(object, "IsoDoor") and object:getNorth() == isSouth) then
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

local function addWall(square, side)
    if not square or BASubterraAPI.getWall(square, side) then
        return
    end

    local otherSide = side == "north" and "west" or "north"
    local otherWall = BASubterraAPI.getWall(square, otherSide)
    local spriteName
    if otherWall and otherWall:getSprite() then
        local otherName = otherWall:getSprite():getName()
        if (side == "north" and otherName == BASubterraAPI.Sprites.WallWest)
                or (side == "west" and otherName == BASubterraAPI.Sprites.WallNorth) then
            square:transmitRemoveItemFromSquare(otherWall)
            spriteName = BASubterraAPI.Sprites.CornerNorthWest
        end
    end

    if not spriteName then
        spriteName = side == "north" and BASubterraAPI.Sprites.WallNorth or BASubterraAPI.Sprites.WallWest
    end

    local obj = IsoObject.getNew(square, spriteName, "", false)
    square:transmitAddObjectToSquare(obj, -1)
end

function BASubterraAPI.digSquare(x, y, z)
    local square = BASubterraAPI.getOrCreateSquare(x, y, z)
    if not square then
        return nil
    end

    removeBlacklistedObjects(square)

    if not square:getFloor() then
        local obj = IsoObject.getNew(square, BASubterraAPI.Sprites.Floor, "", false)
        square:transmitAddObjectToSquare(obj, -1)
    end

    local southSquare = BASubterraAPI.getOrCreateSquare(x, y + 1, z)
    if BASubterraAPI.isOpenSquare(southSquare) then
        BASubterraAPI.removeWall(southSquare, "north")
    else
        addWall(southSquare, "north")
    end
    removeBlacklistedObjects(southSquare)

    local eastSquare = BASubterraAPI.getOrCreateSquare(x + 1, y, z)
    if BASubterraAPI.isOpenSquare(eastSquare) then
        BASubterraAPI.removeWall(eastSquare, "west")
    else
        addWall(eastSquare, "west")
    end
    removeBlacklistedObjects(eastSquare)

    local northSquare = BASubterraAPI.getOrCreateSquare(x, y - 1, z)
    if BASubterraAPI.isOpenSquare(northSquare) then
        BASubterraAPI.removeWall(square, "north")
    else
        addWall(square, "north")
    end
    removeBlacklistedObjects(northSquare)

    local westSquare = BASubterraAPI.getOrCreateSquare(x - 1, y, z)
    if BASubterraAPI.isOpenSquare(westSquare) then
        BASubterraAPI.removeWall(square, "west")
    else
        addWall(square, "west")
    end
    removeBlacklistedObjects(westSquare)

    buildUtil.setHaveConstruction(square, true)

    touchSquare(square)
    touchSquare(southSquare)
    touchSquare(eastSquare)
    touchSquare(northSquare)
    touchSquare(westSquare)

    queueChunkRefresh(x, y, z)
    queueChunkRefresh(x, y + 1, z)
    queueChunkRefresh(x + 1, y, z)
    queueChunkRefresh(x, y - 1, z)
    queueChunkRefresh(x - 1, y, z)

    return square
end

return BASubterraAPI
