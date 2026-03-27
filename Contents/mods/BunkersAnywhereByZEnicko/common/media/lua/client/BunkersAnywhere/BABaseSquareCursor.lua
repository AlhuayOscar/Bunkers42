local CORE = getCore()
local CELL

Events.OnPostMapLoad.Add(function(cell)
    CELL = cell
end)

local BABaseSquareCursor = {}
BABaseSquareCursor.__index = BABaseSquareCursor

function BABaseSquareCursor:select(square, hide)
    hide = hide == nil and true or hide
    self._selectedThisTick = true
    if hide then
        CELL:setDrag(nil, self.player:getPlayerNum())
    end
end

function BABaseSquareCursor:isValid(square)
    if self._isValidCache == nil or square ~= self._isValidCacheSquare then
        self._isValidCacheSquare = square
        self._isValidCache = self:isValidInternal(square)
    end
    return self._isValidCache
end

function BABaseSquareCursor:isValidInternal(square)
    return true
end

function BABaseSquareCursor:render(x, y, z, square)
    local highlight = CORE:getGoodHighlitedColor()
    if not self:isValid(square) then
        highlight = CORE:getBadHighlitedColor()
    end

    ISBuildingObject:getFloorCursorSprite():RenderGhostTileColor(
        x, y, z, highlight:getR(), highlight:getG(), highlight:getB(), 0.8)
end

function BABaseSquareCursor:rotateKey(key)
    self:keyPressed(key)
end

function BABaseSquareCursor:keyPressed(key)
end

function BABaseSquareCursor:onJoypadPressButton(joypadIndex, joypadData, button)
    if button == Joypad.AButton then
        self:onJoypadPressA(joypadData)
    elseif button == Joypad.BButton then
        self:onJoypadPressB(joypadData)
    elseif button == Joypad.YButton then
        self:onJoypadPressY(joypadData)
    elseif button == Joypad.LBumper then
        self:onJoypadPressLB(joypadData)
    elseif button == Joypad.RBumper then
        self:onJoypadPressRB(joypadData)
    end
end

function BABaseSquareCursor:onJoypadDirDown(joypadData)
    self.yJoypad = self.yJoypad + 1
end

function BABaseSquareCursor:onJoypadDirUp(joypadData)
    self.yJoypad = self.yJoypad - 1
end

function BABaseSquareCursor:onJoypadDirRight(joypadData)
    self.xJoypad = self.xJoypad + 1
end

function BABaseSquareCursor:onJoypadDirLeft(joypadData)
    self.xJoypad = self.xJoypad - 1
end

function BABaseSquareCursor:onJoypadPressA(joypadData)
    local square = getSquare(self.xJoypad, self.yJoypad, self.zJoypad)
    if self:isValid(square) then
        self:select(square)
    end
end

function BABaseSquareCursor:onJoypadPressB(joypadData)
    CELL:setDrag(nil, joypadData.player)
end

function BABaseSquareCursor:onJoypadPressY(joypadData)
    local playerSquare = self.player:getSquare()
    self.xJoypad = playerSquare:getX()
    self.yJoypad = playerSquare:getY()
end

function BABaseSquareCursor:onJoypadPressLB(joypadData)
end

function BABaseSquareCursor:onJoypadPressRB(joypadData)
end

function BABaseSquareCursor:getAPrompt()
    return getText("IGUI_Keyboard_Accept")
end

function BABaseSquareCursor:getBPrompt()
    return getText("UI_Cancel")
end

function BABaseSquareCursor:getYPrompt()
    return getText("IGUI_SetCursorToPlayerLocation")
end

function BABaseSquareCursor:getLBPrompt()
    return nil
end

function BABaseSquareCursor:getRBPrompt()
    return nil
end

function BABaseSquareCursor.new(player)
    local o = {
        player = player,
        _isBACursor = true,
        _selectedThisTick = false,
        xJoypad = -1,
        yJoypad = -1,
        zJoypad = -1,
    }
    setmetatable(o, BABaseSquareCursor)
    return o
end

local function isMouseOverUI()
    local uis = UIManager.getUI()
    for i = 1, uis:size() do
        local ui = uis:get(i - 1)
        if ui:isMouseOver() then
            return true
        end
    end
    return false
end

Events.OnInitGlobalModData.Add(function()
    Events.OnDoTileBuilding2.Remove(DoTileBuilding)

    local old_DoTileBuilding = DoTileBuilding
    function DoTileBuilding(draggingItem, isRender, x, y, z, square)
        if draggingItem._isBACursor then
            if isRender then
                draggingItem:render(x, y, z, square)
            end
            if not draggingItem._selectedThisTick
                    and (draggingItem.player:getPlayerNum() ~= 0
                    or (GameKeyboard.isKeyPressed("Attack/Click") and not isMouseOverUI()))
                    and draggingItem:isValid(square) then
                draggingItem:select(square)
            end
        else
            return old_DoTileBuilding(draggingItem, isRender, x, y, z, square)
        end
    end

    Events.OnDoTileBuilding2.Add(DoTileBuilding)
end)

local currentCursors = table.newarray()

Events.SetDragItem.Add(function(drag, playerNum)
    local previousDrag = CELL and CELL:getDrag(playerNum) or nil
    if previousDrag and previousDrag._isBACursor then
        for i = 1, #currentCursors do
            if currentCursors[i] == previousDrag then
                table.remove(currentCursors, i)
                break
            end
        end
    end

    if drag and drag._isBACursor then
        for i = 1, #currentCursors do
            if currentCursors[i] == drag then
                return
            end
        end
        table.insert(currentCursors, drag)
    end
end)

Events.OnTick.Add(function()
    for i = 1, #currentCursors do
        currentCursors[i]._isValidCache = nil
        currentCursors[i]._selectedThisTick = false
    end
end)

return BABaseSquareCursor
