local ok = pcall(require, "BuildingObjects/ISBuildingObject")
local BASubterraAPI = require("BunkersAnywhere/BASubterraAPI")
local BASubterraAccessAction = require("BunkersAnywhere/timedActions/BASubterraAccessAction")

if not ok or not ISBuildingObject or not ISBuildingObject.derive then
    ISBASubterraAccessCursor = ISBASubterraAccessCursor or {}

    function ISBASubterraAccessCursor:new()
        return nil
    end
else
    ISBASubterraAccessCursor = ISBuildingObject:derive("ISBASubterraAccessCursor")

    function ISBASubterraAccessCursor:new(character)
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
        o.orientation = "south"
        return o
    end

    function ISBASubterraAccessCursor:isValid(square)
        if not square then
            return false
        end

        local material = BASubterraAPI.getMaterialAtCoords(square:getX(), square:getY(), square:getZ() - 1) or "dirt"
        return BASubterraAccessAction.canBePerformed(self.character, material, square, self.orientation)
    end

    function ISBASubterraAccessCursor:create(x, y, z)
        local square = getCell():getGridSquare(x, y, z)
        if not square or not self.character then
            self:removeDrag()
            return
        end

        BASubterraAccessAction.queueNew(self.character, square, self.orientation)
        self:removeDrag()
    end

    function ISBASubterraAccessCursor:removeDrag()
        getCell():setDrag(nil, self.player)
    end

    function ISBASubterraAccessCursor:rotateKey(key)
        if getCore():isKey("Rotate building", key) then
            self.orientation = self.orientation == "south" and "east" or "south"
        end
    end

    function ISBASubterraAccessCursor:render(x, y, z, square)
        local floorCursorSprite = ISBuildingObject:getFloorCursorSprite()
        local color = self:isValid(square) and getCore():getGoodHighlitedColor() or getCore():getBadHighlitedColor()
        local r = color:getR()
        local g = color:getG()
        local b = color:getB()

        floorCursorSprite:RenderGhostTileColor(x, y, z, r, g, b, 0.8)
        if self.orientation == "south" then
            for i = 1, 4 do
                floorCursorSprite:RenderGhostTileColor(x, y + i, z, r, g, b, 0.8)
            end
        else
            for i = 1, 4 do
                floorCursorSprite:RenderGhostTileColor(x + i, y, z, r, g, b, 0.8)
            end
        end
    end
end
