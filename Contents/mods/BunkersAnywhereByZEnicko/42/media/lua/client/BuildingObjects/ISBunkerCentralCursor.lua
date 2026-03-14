local ok = pcall(require, "BuildingObjects/ISBuildingObject")

if not ok or not ISBuildingObject or not ISBuildingObject.derive then
    ISBunkerCentralCursor = ISBunkerCentralCursor or {}

    function ISBunkerCentralCursor:new()
        return nil
    end
else
    ISBunkerCentralCursor = ISBuildingObject:derive("ISBunkerCentralCursor")

    function ISBunkerCentralCursor:new(character, item)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o:init()
        o:setDragNilAfterPlace(true)
        o.character = character
        o.player = character and character:getPlayerNum() or 0
        o.item = item
        o.noNeedHammer = true
        o.skipBuildAction = true
        o.renderFloorHelper = true
        return o
    end

    function ISBunkerCentralCursor:getPlacementSpriteName(square)
        if BunkersAnywhere and BunkersAnywhere.canPlaceElectricCentralOnSquare then
            local canPlace, spriteName = BunkersAnywhere.canPlaceElectricCentralOnSquare(square)
            if canPlace then
                return spriteName
            end
        end
        return nil
    end

    function ISBunkerCentralCursor:isValid(square)
        return self:getPlacementSpriteName(square) ~= nil
    end

    function ISBunkerCentralCursor:create(x, y, z, north, sprite)
        local square = getCell():getGridSquare(x, y, z)
        if not square or not self.item or not self.character then
            self:removeDrag()
            return
        end

        if BunkersAnywhere and BunkersAnywhere.placeElectricCentralOnSquare then
            BunkersAnywhere.placeElectricCentralOnSquare(self.item, self.character, square)
        end
        self:removeDrag()
    end

    function ISBunkerCentralCursor:removeDrag()
        getCell():setDrag(nil, self.player)
    end

    function ISBunkerCentralCursor:render(x, y, z, square)
        local spriteName = self:getPlacementSpriteName(square)
        if not spriteName then
            if not ISBunkerCentralCursor.floorSprite then
                ISBunkerCentralCursor.floorSprite = IsoSprite.new()
                ISBunkerCentralCursor.floorSprite:LoadFramesNoDirPageSimple("media/ui/FloorTileCursor.png")
            end
            local hc = getCore():getBadHighlitedColor()
            ISBunkerCentralCursor.floorSprite:RenderGhostTileColor(x, y, z, hc:getR(), hc:getG(), hc:getB(), 0.8)
            return
        end

        local spriteRef = getSprite and getSprite(spriteName) or nil
        if spriteRef and spriteRef.RenderGhostTileColor then
            local hc = getCore():getGoodHighlitedColor()
            spriteRef:RenderGhostTileColor(x, y, z, hc:getR(), hc:getG(), hc:getB(), 0.8)
        end
    end
end
