local BABaseSquareCursor = require("BunkersAnywhere/BABaseSquareCursor")
local BASubterraAPI = require("BunkersAnywhere/BASubterraAPI")
local BASubterraAccessAction = require("BunkersAnywhere/timedActions/BASubterraAccessAction")
local CORE = getCore()

local ISBASubterraAccessCursor = {}
setmetatable(ISBASubterraAccessCursor, BABaseSquareCursor)
ISBASubterraAccessCursor.__index = ISBASubterraAccessCursor

function ISBASubterraAccessCursor:select(square)
    BASubterraAccessAction.queueNew(self.player, square, self.orientation)
    BABaseSquareCursor.select(self, square)
end

function ISBASubterraAccessCursor:isValidInternal(square)
    if not square then
        return false
    end

    local material = BASubterraAPI.getMaterialAtCoords(square:getX(), square:getY(), square:getZ() - 1)
    if not material then
        return false
    end

    return BASubterraAccessAction.canBePerformed(self.player, material, square, self.orientation)
end

function ISBASubterraAccessCursor:render(x, y, z, square)
    local highlight = CORE:getGoodHighlitedColor()
    if not self:isValid(square) then
        highlight = CORE:getBadHighlitedColor()
    end

    local floorCursorSprite = ISBuildingObject:getFloorCursorSprite()
    floorCursorSprite:RenderGhostTileColor(x, y, z, highlight:getR(), highlight:getG(), highlight:getB(), 0.8)

    if self.orientation == "south" then
        for i = 1, 3 do
            floorCursorSprite:RenderGhostTileColor(x, y + i, z, highlight:getR(), highlight:getG(), highlight:getB(), 0.8)
        end
        floorCursorSprite:RenderGhostTileColor(x, y + 4, z, highlight:getR(), highlight:getG(), highlight:getB(), 0.8)
    else
        for i = 1, 3 do
            floorCursorSprite:RenderGhostTileColor(x + i, y, z, highlight:getR(), highlight:getG(), highlight:getB(), 0.8)
        end
        floorCursorSprite:RenderGhostTileColor(x + 4, y, z, highlight:getR(), highlight:getG(), highlight:getB(), 0.8)
    end
end

function ISBASubterraAccessCursor:rotate()
    self.orientation = self.orientation == "south" and "east" or "south"
end

function ISBASubterraAccessCursor:keyPressed(key)
    if CORE:isKey("Rotate building", key) then
        self:rotate()
    end
end

function ISBASubterraAccessCursor:onJoypadPressLB(joypadData)
    self:rotate()
end

function ISBASubterraAccessCursor:onJoypadPressRB(joypadData)
    self:rotate()
end

function ISBASubterraAccessCursor:getAPrompt()
    local square = getSquare(self.xJoypad, self.yJoypad, self.zJoypad)
    return self:isValid(square) and "Excavar acceso" or nil
end

function ISBASubterraAccessCursor:getLBPrompt()
    return getText("IGUI_Controller_RotateLeft")
end

function ISBASubterraAccessCursor:getRBPrompt()
    return getText("IGUI_Controller_RotateRight")
end

function ISBASubterraAccessCursor.new(player)
    local o = BABaseSquareCursor.new(player)
    setmetatable(o, ISBASubterraAccessCursor)
    o.orientation = "south"
    return o
end

return ISBASubterraAccessCursor
