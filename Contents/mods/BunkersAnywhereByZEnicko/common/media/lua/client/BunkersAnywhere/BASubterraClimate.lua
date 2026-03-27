local BASubterraAPI = require("BunkersAnywhere/BASubterraAPI")

local playerStates = {}
local tickCounter = 0

local function roundValue(value)
    if value == nil then
        return "nil"
    end
    return tostring(math.floor(value * 10 + 0.5) / 10)
end

local function getSquareKey(square)
    if not square then
        return "nil"
    end

    return tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
end

local function safeCall(target, method, ...)
    if not target or not target[method] then
        return nil
    end

    local ok, value = pcall(target[method], target, ...)
    if ok then
        return value
    end

    return nil
end

local function dryWornItems(player)
    local wornItems = player and player.getWornItems and player:getWornItems() or nil
    if not wornItems then
        return
    end

    for i = 0, wornItems:size() - 1 do
        local wornItem = wornItems:get(i)
        local item = wornItem and wornItem.getItem and wornItem:getItem() or nil
        if item and item.getWetness and item.setWetness then
            local wetness = item:getWetness()
            if wetness and wetness > 0 then
                item:setWetness(math.max(0, wetness - 0.75))
            end
        end
    end
end

local function dryBody(player)
    local body = player and player.getBodyDamage and player:getBodyDamage() or nil
    if not body then
        return
    end

    local bodyParts = body.getBodyParts and body:getBodyParts() or nil
    if bodyParts then
        for i = 0, bodyParts:size() - 1 do
            local part = bodyParts:get(i)
            if part and part.getWetness and part.setWetness then
                local wetness = part:getWetness()
                if wetness and wetness > 0 then
                    part:setWetness(math.max(0, wetness - 0.75))
                end
            end
        end
    end

    local stats = player:getStats()
    if stats and stats.get and stats.set then
        local wetness = stats:get(CharacterStat.WETNESS)
        if wetness and wetness > 0 then
            stats:set(CharacterStat.WETNESS, math.max(0, wetness - 1.0))
            if isClient() and sendPlayerStat then
                pcall(sendPlayerStat, player, CharacterStat.WETNESS)
            end
        end
    end
end

local function stabilizeTemperature(player)
    local currentTemperature = safeCall(player, "getTemperature")
    if currentTemperature == nil then
        return
    end

    local targetTemperature = 36.8
    if currentTemperature < targetTemperature and player.setTemperature then
        local warmed = math.min(targetTemperature, currentTemperature + 0.03)
        pcall(player.setTemperature, player, warmed)
    end
end

local function logTileState(player, square, shelterState)
    local body = player and player.getBodyDamage and player:getBodyDamage() or nil
    local thermoregulator = body and body.getThermoregulator and body:getThermoregulator() or nil
    local outside = square and square.isOutside and square:isOutside() or false
    local room = square and square.getRoom and square:getRoom() or nil
    local airTemp = thermoregulator and thermoregulator.getTemperatureAirAndWind and thermoregulator:getTemperatureAirAndWind() or nil
    local playerTemp = safeCall(player, "getTemperature")
    local raining = RainManager and RainManager.isRaining and RainManager.isRaining() or false

    print(string.format(
        "[BASubterra][Climate] tile=%s shelter=%s outside=%s room=%s rain=%s air=%s playerTemp=%s",
        getSquareKey(square),
        tostring(shelterState),
        tostring(outside),
        tostring(room ~= nil),
        tostring(raining),
        roundValue(airTemp),
        roundValue(playerTemp)
    ))

    if player and player.setHaloNote then
        local text = string.format("Subterra %s | rain=%s | air=%s", shelterState, tostring(raining), roundValue(airTemp))
        player:setHaloNote(text, 80, 220, 255, 180)
    end
end

local function updatePlayerClimate(player)
    if not player or player:isDead() then
        return
    end

    local square = player:getCurrentSquare()
    local playerNum = player:getPlayerNum()
    local state = playerStates[playerNum] or {}
    playerStates[playerNum] = state

    local shelterState = BASubterraAPI.getShelterState(square)
    local squareKey = getSquareKey(square)

    if BASubterraAPI.DEBUG_CLIMATE and (state.lastSquareKey ~= squareKey or state.lastShelterState ~= shelterState) then
        if shelterState ~= "none" then
            logTileState(player, square, shelterState)
        end
        state.lastSquareKey = squareKey
        state.lastShelterState = shelterState
    end

    if shelterState ~= "covered" then
        return
    end

    if state.nextClimateTick and tickCounter < state.nextClimateTick then
        return
    end

    state.nextClimateTick = tickCounter + 30

    dryBody(player)
    dryWornItems(player)
    stabilizeTemperature(player)
end

Events.OnTick.Add(function()
    tickCounter = tickCounter + 1

    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player then
            updatePlayerClimate(player)
        end
    end
end)
