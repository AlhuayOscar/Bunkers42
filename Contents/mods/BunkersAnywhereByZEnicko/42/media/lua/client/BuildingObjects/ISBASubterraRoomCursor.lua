local ok = pcall(require, "BuildingObjects/ISBuildingObject")
local BASubterraAPI = require("BunkersAnywhere/BASubterraAPI")
local BASubterraRoomAction = require("BunkersAnywhere/timedActions/BASubterraRoomAction")

if not ok or not ISBuildingObject or not ISBuildingObject.derive then
    ISBASubterraRoomCursor = ISBASubterraRoomCursor or {}

    function ISBASubterraRoomCursor:new()
        return nil
    end
else
    ISBASubterraRoomCursor = ISBuildingObject:derive("ISBASubterraRoomCursor")

    function ISBASubterraRoomCursor:new(character)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o:init()
        o:setDragNilAfterPlace(true)
        o.character = character
        o.player = character and character:getPlayerNum() or 0
        o.noNeedHammer = true
        o.skipBuildAction = true
        o.renderFloorHelper = true
        return o
    end

    function ISBASubterraRoomCursor:isValid(square)
        if not square then
            return false
        end

        local material = BASubterraAPI.getMaterialAt(square)
        if not material then
            return false
        end

        return BASubterraRoomAction.canBePerformed(self.character, material, square)
    end

    function ISBASubterraRoomCursor:create(x, y, z)
        local square = getCell():getGridSquare(x, y, z)
        if not square or not self.character then
            self:removeDrag()
            return
        end

        local material = BASubterraAPI.getMaterialAt(square)
        if material then
            BASubterraRoomAction.queueNew(self.character, x, y, z, material)
        end
        self:removeDrag()
    end

    function ISBASubterraRoomCursor:removeDrag()
        getCell():setDrag(nil, self.player)
    end

    function ISBASubterraRoomCursor:render(x, y, z, square)
        local floorCursorSprite = ISBuildingObject:getFloorCursorSprite()
        local color = self:isValid(square) and getCore():getGoodHighlitedColor() or getCore():getBadHighlitedColor()
        floorCursorSprite:RenderGhostTileColor(x, y, z, color:getR(), color:getG(), color:getB(), 0.8)
    end
end
