local BASubterraBaseAction = require("BunkersAnywhere/timedActions/BASubterraBaseAction")
local BASubterraAPI = require("BunkersAnywhere/BASubterraAPI")
local BASubterraText = require("BunkersAnywhere/BASubterraText")

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

local function addAccessObject(square, spriteName, bunkerType, orientation)
    if not square then
        return nil
    end

    local objects = square:getObjects()
    if objects then
        for i = 0, objects:size() - 1 do
            local object = objects:get(i)
            local md = object and object.getModData and object:getModData() or nil
            if md and md.bunkerType == bunkerType and md.baSubterraAccess == true then
                return object
            end
        end
    end

    local object = square:addTileObject(spriteName)
    if not object then
        return nil
    end

    local md = object:getModData()
    md.bunkerType = bunkerType
    md.baSubterraAccess = true
    md.baSubterraOrientation = orientation

    if isClient() and object.transmitCompleteItemToServer then
        object:transmitCompleteItemToServer()
    end

    return object
end

local function placeAccessPair(topSquare, bottomSquare, orientation)
    local entranceSprite = (BunkersAnywhere and BunkersAnywhere.getEntranceSprite and BunkersAnywhere.getEntranceSprite(topSquare)) or BASubterraAPI.Sprites.Entrance
    local ladderSprite = (BunkersAnywhere and BunkersAnywhere.Sprites and BunkersAnywhere.Sprites.Ladder) or BASubterraAPI.Sprites.Ladder

    addAccessObject(topSquare, entranceSprite, "Entrada de Bunker", orientation)
    addAccessObject(bottomSquare, ladderSprite, "Escalera de Bunker", orientation)
end

local BASubterraAccessAction = BASubterraBaseAction:derive("BASubterraAccessAction")
BASubterraAccessAction.__index = BASubterraAccessAction

BASubterraAccessAction.SACKS_NEEDED = BASubterraAPI.DIRT_SACKS_ACCESS
BASubterraAccessAction.STONE_REWARD = 6

function BASubterraAccessAction:complete()
    local x, y, z = self.originSquare:getX(), self.originSquare:getY(), self.originSquare:getZ()
    local accessTopSquare
    local firstLowerSquare

    if self.orientation == "south" then
        accessTopSquare = BASubterraAPI.getOrCreateSquare(x, y + 1, z)
        BASubterraAPI.digFloor(accessTopSquare)

        for i = 1, 3 do
            BASubterraAPI.digSquare(x, y + i, z - 1)
        end
        BASubterraAPI.digSquare(x, y + 4, z - 1)
        firstLowerSquare = BASubterraAPI.getOrCreateSquare(x, y + 1, z - 1)
    else
        accessTopSquare = BASubterraAPI.getOrCreateSquare(x + 1, y, z)
        BASubterraAPI.digFloor(accessTopSquare)

        for i = 1, 3 do
            BASubterraAPI.digSquare(x + i, y, z - 1)
        end
        BASubterraAPI.digSquare(x + 4, y, z - 1)
        firstLowerSquare = BASubterraAPI.getOrCreateSquare(x + 1, y, z - 1)
    end

    placeAccessPair(accessTopSquare, firstLowerSquare, self.orientation)

    local inverseStrengthLevel = 10 - self.character:getPerkLevel(Perks.Strength)
    self.character:addArmMuscleStrain(3 + 4 * inverseStrengthLevel / 10)
    self.character:addBackMuscleStrain(2 + 2 * inverseStrengthLevel / 10)

    local stats = self.character:getStats()
    stats:setEndurance(stats:getEndurance() - (0.4 + inverseStrengthLevel / 80))
    syncPlayerStats(self.character, SyncPlayerStatsPacket.Stat_Endurance)

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

        if endSquare and (BASubterraAPI.isInPlayableArea(endSquare) and (not endSquare:hasFloor() or endSquare:Is("BlocksPlacement"))) then
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
