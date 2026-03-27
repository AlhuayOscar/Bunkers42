local BASubterraBaseAction = require("BunkersAnywhere/timedActions/BASubterraBaseAction")
local BASubterraAPI = require("BunkersAnywhere/BASubterraAPI")
local BASubterraText = require("BunkersAnywhere/BASubterraText")

local function drainEndurance(character, amount)
    local stats = character and character:getStats() or nil
    if not stats then
        return
    end

    local current = stats.get and stats:get(CharacterStat.ENDURANCE) or nil
    if current == nil and stats.getEndurance then
        current = stats:getEndurance()
    end
    if current == nil then
        return
    end

    local nextValue = math.max(0, current - amount)
    if stats.set then
        stats:set(CharacterStat.ENDURANCE, nextValue)
    elseif stats.setEndurance then
        stats:setEndurance(nextValue)
    end

    local enduranceStat = SyncPlayerStatsPacket and SyncPlayerStatsPacket.Stat_Endurance or nil
    if syncPlayerStats and enduranceStat ~= nil then
        pcall(syncPlayerStats, character, enduranceStat)
    end
end

local function hasBunkerMarker(square)
    if not square then
        return false
    end

    local objects = square:getObjects()
    if not objects then
        return false
    end

    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local md = object and object.getModData and object:getModData() or nil
        if md and (md.bunkerType or md.baSubterraAccess) then
            return true
        end
    end

    return false
end

local BASubterraAccessAction = BASubterraBaseAction:derive("BASubterraAccessAction")
BASubterraAccessAction.__index = BASubterraAccessAction

BASubterraAccessAction.SACKS_NEEDED = BASubterraAPI.DIRT_SACKS_ACCESS
BASubterraAccessAction.STONE_REWARD = 6

function BASubterraAccessAction:complete()
    local x, y, z = self.originSquare:getX(), self.originSquare:getY(), self.originSquare:getZ()

    if self.orientation == "south" then
        for i = 1, 3 do
            BASubterraAPI.digFloor(getSquare(x, y + i, z))
            BASubterraAPI.digSquare(x, y + i, z - 1)
            local belowSquare = BASubterraAPI.getOrCreateSquare(x, y + i, z - 1)
            if belowSquare then
                local obj = IsoObject.getNew(belowSquare, "fixtures_excavation_01_" .. tostring(6 - i), "", false)
                belowSquare:transmitAddObjectToSquare(obj, -1)
            end
        end
        local endSquare = BASubterraAPI.getOrCreateSquare(x, y + 4, z - 1)
        if endSquare and not endSquare:hasFloor() then
            BASubterraAPI.digSquare(x, y + 4, z - 1)
        end
    else
        for i = 1, 3 do
            BASubterraAPI.digFloor(getSquare(x + i, y, z))
            BASubterraAPI.digSquare(x + i, y, z - 1)
            local belowSquare = BASubterraAPI.getOrCreateSquare(x + i, y, z - 1)
            if belowSquare then
                local obj = IsoObject.getNew(belowSquare, "fixtures_excavation_01_" .. tostring(3 - i), "", false)
                belowSquare:transmitAddObjectToSquare(obj, -1)
            end
        end
        local endSquare = BASubterraAPI.getOrCreateSquare(x + 4, y, z - 1)
        if endSquare and not endSquare:hasFloor() then
            BASubterraAPI.digSquare(x + 4, y, z - 1)
        end
    end

    local inverseStrengthLevel = 10 - self.character:getPerkLevel(Perks.Strength)
    self.character:addArmMuscleStrain(3 + 4 * inverseStrengthLevel / 10)
    self.character:addBackMuscleStrain(2 + 2 * inverseStrengthLevel / 10)

    drainEndurance(self.character, 0.4 + inverseStrengthLevel / 80)

    self.character:setHaloNote(BASubterraText.get("IGUI_BASubterraAccessBuilt"), 0, 255, 100, 300)
    return BASubterraBaseAction.complete(self)
end

function BASubterraAccessAction:waitToStart()
    self.character:faceDirection(self.orientation == "south" and IsoDirections.S or IsoDirections.E)
    return self.character:shouldBeTurning()
end

function BASubterraAccessAction.canBePerformed(character, material, square, orientation)
    if square then
        local z = square:getZ()
        if z ~= 0 then
            return false, "Tooltip_BASubterraDepthLimit"
        end

        if not square:hasFloor() or not BASubterraAPI.isSquareClear(square, nil, character) then
            return false, "Tooltip_BASubterraNeedGround"
        end

        local x, y = square:getX(), square:getY()
        local endSquare
        if orientation == "south" then
            for i = 1, 3 do
                local targetSquare = getSquare(x, y + i, z)
                if not BASubterraAPI.canDigDownFrom(targetSquare)
                        or not BASubterraAPI.isSquareClear(targetSquare, orientation, character)
                        or hasBunkerMarker(targetSquare) then
                    return false, "Tooltip_BASubterraBlocked"
                end
            end
            endSquare = getSquare(x, y + 4, z - 1)
        else
            for i = 1, 3 do
                local targetSquare = getSquare(x + i, y, z)
                if not BASubterraAPI.canDigDownFrom(targetSquare)
                        or not BASubterraAPI.isSquareClear(targetSquare, orientation, character)
                        or hasBunkerMarker(targetSquare) then
                    return false, "Tooltip_BASubterraBlocked"
                end
            end
            endSquare = getSquare(x + 4, y, z - 1)
        end

        local blocked = false
        if endSquare and endSquare.Is then
            local ok, value = pcall(function()
                return endSquare:Is("BlocksPlacement")
            end)
            blocked = ok and value or false
        end
        if endSquare and (BASubterraAPI.isInPlayableArea(endSquare) and (not endSquare:hasFloor() or blocked)) then
            return false, "Tooltip_BASubterraBlocked"
        end
    end

    if material == "dirt" then
        local inventory = character:getInventory()
        local available = inventory:getCountEvalRecurse(BASubterraAPI.canCarryDirt)
        if available < BASubterraAccessAction.SACKS_NEEDED then
            return false, "Tooltip_BASubterraNeedSacks", BASubterraAccessAction.SACKS_NEEDED, available
        end
    end

    return BASubterraBaseAction.canBePerformed(character, material)
end

function BASubterraAccessAction.queueNew(character, square, orientation)
    ISTimedActionQueue.add(ISWalkToTimedAction:new(character, square))

    local material = BASubterraAPI.getMaterialAtCoords(square:getX(), square:getY(), square:getZ() - 1) or "dirt"
    if not BASubterraBaseAction.queueSupplies(character, material, material == "dirt" and BASubterraAccessAction.SACKS_NEEDED or 0) then
        return false
    end

    ISTimedActionQueue.add(BASubterraAccessAction.new(character, square, orientation, material))
    return true
end

function BASubterraAccessAction.new(character, square, orientation, material)
    local o = BASubterraBaseAction.new(character, material)
    setmetatable(o, BASubterraAccessAction)
    o.maxTime = character:isTimedActionInstant() and 1 or 1000
    o.originSquare = square
    o.orientation = orientation
    return o
end

return BASubterraAccessAction
