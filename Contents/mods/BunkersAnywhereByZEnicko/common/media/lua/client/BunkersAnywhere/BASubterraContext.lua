require "BunkersAnywhere/ISBunkerDoor"

local BASubterraAPI = require("BunkersAnywhere/BASubterraAPI")
local BASubterraData = require("BunkersAnywhere/BASubterraData")
local BASubterraText = require("BunkersAnywhere/BASubterraText")
local ISBASubterraRoomCursor = require("BuildingObjects/ISBASubterraRoomCursor")
local ISBASubterraAccessCursor = require("BuildingObjects/ISBASubterraAccessCursor")

local badColour = getCore():getBadHighlitedColor()
badColour = table.newarray(badColour:getR(), badColour:getG(), badColour:getB())
local badColourString = string.format(" <RGB:%f,%f,%f> ", badColour[1], badColour[2], badColour[3])

local function addTooltip(option, description)
    option.notAvailable = true
    option.toolTip = ISToolTip:new()
    option.toolTip:initialise()
    option.toolTip:setVisible(false)
    option.toolTip.description = badColourString .. tostring(description)
end

local function addGenericDigTooltip(option, reason, arg1, arg2)
    local text = BASubterraText.get(reason, arg1, arg2)
    addTooltip(option, text)
end

local function onDigRoom(player)
    getCell():setDrag(ISBASubterraRoomCursor:new(player), player:getPlayerNum())
end

local function onDigAccess(player)
    getCell():setDrag(ISBASubterraAccessCursor:new(player), player:getPlayerNum())
end

local function getGenericRoomState(player)
    local square = player and player:getSquare() or nil
    if not square or square:getZ() >= 0 then
        return false, "Tooltip_BASubterraNeedUnderground"
    end

    local material = BASubterraAPI.getMaterialAt(square) or "dirt"
    local canDig, reason = BASubterraAPI.characterCanDig(player, material)
    if not canDig then
        return false, reason
    end

    if material == "dirt" then
        local available = player:getInventory():getCountEvalRecurse(BASubterraAPI.canCarryDirt)
        if available < BASubterraAPI.DIRT_SACKS_ROOM then
            return false, "Tooltip_BASubterraNeedSacks", BASubterraAPI.DIRT_SACKS_ROOM, available
        end
    end

    return true
end

local function getGenericAccessState(player)
    local square = player and player:getSquare() or nil
    if not square or square:getZ() ~= 0 then
        return false, "Tooltip_BASubterraDepthLimit"
    end

    local canDig, reason = BASubterraAPI.characterCanDig(player, "dirt")
    if not canDig then
        return false, reason
    end

    local available = player:getInventory():getCountEvalRecurse(BASubterraAPI.canCarryDirt)
    if available < BASubterraAPI.DIRT_SACKS_ACCESS then
        return false, "Tooltip_BASubterraNeedSacks", BASubterraAPI.DIRT_SACKS_ACCESS, available
    end

    return true
end

local function onFillWorldObjectContextMenu(playerNum, context)
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() then
        return
    end

    local square = player:getSquare()
    if not square or square:getZ() > 0 then
        return
    end

    local inventory = player:getInventory()
    if not (inventory:containsEvalRecurse(BASubterraAPI.canDigDirt) or inventory:containsEvalRecurse(BASubterraAPI.canDigStone)) then
        return
    end

    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(context:addOption(BASubterraText.get("ContextMenu_BASubterra")), submenu)

    if square:getZ() == 0 then
        local accessOption = submenu:addOption(BASubterraText.get("ContextMenu_BASubterraAccess"), player, onDigAccess)
        local canAccess, reason, arg1, arg2 = getGenericAccessState(player)
        if not canAccess then
            addGenericDigTooltip(accessOption, reason, arg1, arg2)
        end
    else
        local roomOption = submenu:addOption(BASubterraText.get("ContextMenu_BASubterraRoom"), player, onDigRoom)
        local canRoom, reason, arg1, arg2 = getGenericRoomState(player)
        if not canRoom then
            addGenericDigTooltip(roomOption, reason, arg1, arg2)
        end
    end
end

local function wrapBunkerRemoval()
    BunkersAnywhere = BunkersAnywhere or {}
    if BunkersAnywhere._baSubterraRemoveWrapped then
        return
    end

    local originalRemoveObject = BunkersAnywhere.removeObject
    if type(originalRemoveObject) ~= "function" then
        return
    end

    BunkersAnywhere.removeObject = function(obj, playerObj, itemFullType)
        local square = obj and obj.getSquare and obj:getSquare() or nil
        local md = obj and obj.getModData and obj:getModData() or nil
        local shouldRestoreTopFloor = square and md and md.baSubterraAccess == true and md.bunkerType == "Entrada de Bunker"

        originalRemoveObject(obj, playerObj, itemFullType)

        if shouldRestoreTopFloor and square then
            BASubterraData.clearFloorRemoved(square)
            local spriteName = BASubterraAPI.findNearbyFloorSprite(square:getX(), square:getY(), square:getZ())
            BASubterraAPI.restoreFloor(square, spriteName)
        end
    end

    BunkersAnywhere._baSubterraRemoveWrapped = true
end

wrapBunkerRemoval()
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
