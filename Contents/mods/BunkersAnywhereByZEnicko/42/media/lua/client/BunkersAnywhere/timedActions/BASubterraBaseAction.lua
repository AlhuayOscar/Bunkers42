require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/WalkToTimedAction"
require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISEquipWeaponAction"

local BASubterraAPI = require("BunkersAnywhere/BASubterraAPI")

local CACHE_ARRAY_LIST = ArrayList.new()

local BASubterraBaseAction = ISBaseTimedAction:derive("BASubterraBaseAction")
BASubterraBaseAction.__index = BASubterraBaseAction

BASubterraBaseAction.SACKS_NEEDED = 0
BASubterraBaseAction.STONE_REWARD = 0

local function queueTransferIfNeeded(character, item)
    if not character or not item then
        return false
    end

    local inventory = character:getInventory()
    local container = item:getContainer()
    if container and container ~= inventory then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(character, item, container, inventory))
    end

    return true
end

function BASubterraBaseAction.queueSupplies(character, material, sacksNeeded)
    local inventory = character:getInventory()

    if material == "dirt" and sacksNeeded > 0 then
        local sacks = inventory:getSomeEvalRecurse(BASubterraAPI.canCarryDirt, sacksNeeded, CACHE_ARRAY_LIST)
        if not sacks or sacks:size() < sacksNeeded then
            CACHE_ARRAY_LIST:clear()
            return false
        end

        for i = 0, sacks:size() - 1 do
            queueTransferIfNeeded(character, sacks:get(i))
        end
        CACHE_ARRAY_LIST:clear()
    end

    local tool = inventory:getFirstEvalRecurse(material == "stone" and BASubterraAPI.canDigStone or BASubterraAPI.canDigDirt)
    if not tool then
        return false
    end

    queueTransferIfNeeded(character, tool)
    ISTimedActionQueue.add(ISEquipWeaponAction:new(character, tool, 50, true, false))
    return true
end

function BASubterraBaseAction:complete()
    if not self.character:isBuildCheat() then
        if self.material == "dirt" and self.SACKS_NEEDED > 0 then
            local inventory = self.character:getInventory()
            local sacks = inventory:getSomeEvalRecurse(BASubterraAPI.canCarryDirt, self.SACKS_NEEDED, CACHE_ARRAY_LIST)
            for i = 0, self.SACKS_NEEDED - 1 do
                inventory:Remove(sacks:get(i))
            end
            inventory:AddItems("Base.Dirtbag", self.SACKS_NEEDED)
            CACHE_ARRAY_LIST:clear()
        elseif self.material == "stone" and self.STONE_REWARD > 0 then
            self.character:getInventory():AddItems("Base.Stone2", self.STONE_REWARD)
        end
    end

    return true
end

function BASubterraBaseAction:perform()
    self:stopCommon()
    ISBaseTimedAction.perform(self)
end

function BASubterraBaseAction:stop()
    self:stopCommon()
    ISBaseTimedAction.stop(self)
end

function BASubterraBaseAction:stopCommon()
    if self.digTool then
        self.digTool:setJobDelta(0)
    end
    if self.handle then
        self.character:getEmitter():stopSound(self.handle)
    end
end

function BASubterraBaseAction:start()
    self.digTool = self.character:getPrimaryHandItem()
    self:setActionAnim(BuildingHelper.getShovelAnim(self.digTool))
    self.digTool:setJobType("Subterrain")
    self.handle = self.character:getEmitter():playSound("Shoveling")
end

function BASubterraBaseAction:update()
    if self.digTool then
        self.digTool:setJobDelta(self:getJobDelta())
    end
    self.character:setMetabolicTarget(Metabolics.HeavyWork)
    local emitter = self.character:getEmitter()
    if not emitter:isPlaying(self.handle) then
        self.handle = emitter:playSound("Shoveling")
    end
end

function BASubterraBaseAction:isValid()
    if self.material == "dirt" and self.SACKS_NEEDED > 0 then
        local sacks = self.character:getInventory():getSomeEvalRecurse(BASubterraAPI.canCarryDirt, self.SACKS_NEEDED, CACHE_ARRAY_LIST)
        if sacks:size() < self.SACKS_NEEDED then
            CACHE_ARRAY_LIST:clear()
            return false
        end
        CACHE_ARRAY_LIST:clear()
    end

    local primaryHandItem = self.character:getPrimaryHandItem()
    if not primaryHandItem
            or (self.material == "dirt" and not BASubterraAPI.canDigDirt(primaryHandItem))
            or (self.material == "stone" and not BASubterraAPI.canDigStone(primaryHandItem)) then
        return false
    end

    return true
end

function BASubterraBaseAction.canBePerformed(character, material)
    return BASubterraAPI.characterCanDig(character, material)
end

function BASubterraBaseAction.new(character, material)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, BASubterraBaseAction)
    o.material = material
    return o
end

return BASubterraBaseAction
