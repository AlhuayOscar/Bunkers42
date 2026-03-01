require "TimedActions/ISTimedAction"

ISInstallBunkerKitAction = ISTimedAction:derive("ISInstallBunkerKitAction");

function ISInstallBunkerKitAction:isValid()
    return self.character:getInventory():contains("BunkerKit");
end

function ISInstallBunkerKitAction:update()
    self.character:faceLocation(self.stairObj:getSquare():getX(), self.stairObj:getSquare():getY())
    self.character:setMetabolicTarget(Metabolics.HeavyWork);
end

function ISInstallBunkerKitAction:start()
    self:setActionAnim("BuildLow")
    self.character:getEmitter():playSound("Carpentry")
end

function ISInstallBunkerKitAction:stop()
    ISBaseTimedAction.stop(self);
end

function ISInstallBunkerKitAction:perform()
    -- Ejecutamos la lógica que estaba en el Context Menu
    BunkersAnywhere.useBunkerKit(self.stairObj, self.character)

    -- Se elimina la acción de la cola
    ISBaseTimedAction.perform(self);
end

function ISInstallBunkerKitAction:new(character, stairObj)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.stairObj = stairObj
    o.maxTime = 250 -- duration in ticks
    if character:isTimedActionInstant() then 
        o.maxTime = 1; 
    end
    return o
end
