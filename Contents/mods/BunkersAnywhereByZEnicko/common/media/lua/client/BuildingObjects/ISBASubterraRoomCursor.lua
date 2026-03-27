local BABaseSquareCursor = require("BunkersAnywhere/BABaseSquareCursor")
local BASubterraAPI = require("BunkersAnywhere/BASubterraAPI")
local BASubterraRoomAction = require("BunkersAnywhere/timedActions/BASubterraRoomAction")

local ISBASubterraRoomCursor = {}
setmetatable(ISBASubterraRoomCursor, BABaseSquareCursor)
ISBASubterraRoomCursor.__index = ISBASubterraRoomCursor

function ISBASubterraRoomCursor:select(square)
    local material = BASubterraAPI.getMaterialAt(square)
    if material then
        BASubterraRoomAction.queueNew(self.player, square:getX(), square:getY(), square:getZ(), material)
    end

    BABaseSquareCursor.select(self, square, false)
end

function ISBASubterraRoomCursor:isValidInternal(square)
    if not square then
        return false
    end

    local material = BASubterraAPI.getMaterialAt(square)
    if not material then
        return false
    end

    return BASubterraRoomAction.canBePerformed(self.player, material, square)
end

function ISBASubterraRoomCursor:getAPrompt()
    local square = getSquare(self.xJoypad, self.yJoypad, self.zJoypad)
    return self:isValid(square) and "Excavar sala" or nil
end

function ISBASubterraRoomCursor.new(player)
    local o = BABaseSquareCursor.new(player)
    setmetatable(o, ISBASubterraRoomCursor)
    return o
end

return ISBASubterraRoomCursor
