local BASubterraBaseAction = require("BunkersAnywhere/timedActions/BASubterraBaseAction")
local BASubterraAPI = require("BunkersAnywhere/BASubterraAPI")
local BASubterraText = require("BunkersAnywhere/BASubterraText")

local function isStandableSquare(square)
    if not square or not square:hasFloor() or square:HasStairs() then
        return false
    end
    return true
end

local function getDiggableWallBetween(square, neighbour, side)
    if not square or not neighbour then
        return nil
    end

    local wall
    if side == "north" then
        wall = BASubterraAPI.getWall(square, "north")
    elseif side == "west" then
        wall = BASubterraAPI.getWall(square, "west")
    elseif side == "south" then
        wall = BASubterraAPI.getWall(neighbour, "north")
    elseif side == "east" then
        wall = BASubterraAPI.getWall(neighbour, "west")
    end

    if wall and wall:getSprite() then
        local spriteName = wall:getSprite():getName()
        if BASubterraAPI.isDiggableSpriteName(spriteName) then
            return wall
        end
    end

    return nil
end

local function getClosestAdjacentSquare(x, y, z, character)
    local candidates = {}
    local square = getSquare(x, y, z)
    if not square then
        return nil
    end

    local north = square:getAdjacentSquare(IsoDirections.N)
    if north and isStandableSquare(north) and getDiggableWallBetween(square, north, "north") then
        table.insert(candidates, north)
    end

    local west = square:getAdjacentSquare(IsoDirections.W)
    if west and isStandableSquare(west) and getDiggableWallBetween(square, west, "west") then
        table.insert(candidates, west)
    end

    local south = square:getAdjacentSquare(IsoDirections.S)
    if south and isStandableSquare(south) and getDiggableWallBetween(square, south, "south") then
        table.insert(candidates, south)
    end

    local east = square:getAdjacentSquare(IsoDirections.E)
    if east and isStandableSquare(east) and getDiggableWallBetween(square, east, "east") then
        table.insert(candidates, east)
    end

    if #candidates <= 1 then
        return candidates[1]
    end

    local closest
    local closestDist = 1000000
    for i = 1, #candidates do
        local candidate = candidates[i]
        local dist = candidate:DistToProper(character)
        if dist < closestDist then
            closestDist = dist
            closest = candidate
        end
    end

    return closest
end

local function getValidAdjacentSquare(square)
    if not square then
        return nil
    end

    local north = square:getAdjacentSquare(IsoDirections.N)
    if north and isStandableSquare(north) and getDiggableWallBetween(square, north, "north") then
        return north
    end

    local west = square:getAdjacentSquare(IsoDirections.W)
    if west and isStandableSquare(west) and getDiggableWallBetween(square, west, "west") then
        return west
    end

    local south = square:getAdjacentSquare(IsoDirections.S)
    if south and isStandableSquare(south) and getDiggableWallBetween(square, south, "south") then
        return south
    end

    local east = square:getAdjacentSquare(IsoDirections.E)
    if east and isStandableSquare(east) and getDiggableWallBetween(square, east, "east") then
        return east
    end

    return nil
end

local BASubterraRoomAction = BASubterraBaseAction:derive("BASubterraRoomAction")
BASubterraRoomAction.__index = BASubterraRoomAction

BASubterraRoomAction.SACKS_NEEDED = BASubterraAPI.DIRT_SACKS_ROOM
BASubterraRoomAction.STONE_REWARD = 3

function BASubterraRoomAction:complete()
    BASubterraAPI.digSquare(self.x, self.y, self.z)

    local inverseStrengthLevel = 10 - self.character:getPerkLevel(Perks.Strength)
    self.character:addArmMuscleStrain(2 + 3 * inverseStrengthLevel / 10)

    local stats = self.character:getStats()
    stats:setEndurance(stats:getEndurance() - (0.2 + inverseStrengthLevel / 80))
    syncPlayerStats(self.character, SyncPlayerStatsPacket.Stat_Endurance)

    self.character:setHaloNote(BASubterraText.get("IGUI_BASubterraRoomBuilt"), 0, 255, 100, 250)
    return BASubterraBaseAction.complete(self)
end

function BASubterraRoomAction:waitToStart()
    self.character:faceLocation(self.x, self.y)
    return self.character:shouldBeTurning()
end

function BASubterraRoomAction.canBePerformed(character, material, square)
    if square then
        if square:getZ() >= 0 then
            return false, "Tooltip_BASubterraNeedUnderground"
        end

        local canDig, reason = BASubterraAPI.canDig(square)
        if not canDig then
            return false, reason
        end

        if BASubterraAPI.isOpenSquare(square) then
            return false, "Tooltip_BASubterraAlreadyOpen"
        end

        if not getValidAdjacentSquare(square) then
            return false, "Tooltip_BASubterraNoPath"
        end
    end

    if material == "dirt" then
        local inventory = character:getInventory()
        local available = inventory:getCountEvalRecurse(BASubterraAPI.canCarryDirt)
        if available < BASubterraRoomAction.SACKS_NEEDED then
            return false, "Tooltip_BASubterraNeedSacks", BASubterraRoomAction.SACKS_NEEDED, available
        end
    end

    return BASubterraBaseAction.canBePerformed(character, material)
end

function BASubterraRoomAction.queueNew(character, x, y, z, material)
    local adjacentSquare = getClosestAdjacentSquare(x, y, z, character)
    if not adjacentSquare then
        return false
    end

    ISTimedActionQueue.add(ISWalkToTimedAction:new(character, adjacentSquare))

    if not BASubterraBaseAction.queueSupplies(character, material, material == "dirt" and BASubterraRoomAction.SACKS_NEEDED or 0) then
        return false
    end

    ISTimedActionQueue.add(BASubterraRoomAction.new(character, x, y, z, material))
    return true
end

function BASubterraRoomAction.new(character, x, y, z, material)
    local o = BASubterraBaseAction.new(character, material)
    setmetatable(o, BASubterraRoomAction)
    o.x = x
    o.y = y
    o.z = z
    o.maxTime = character:isTimedActionInstant() and 1 or 500
    return o
end

return BASubterraRoomAction
