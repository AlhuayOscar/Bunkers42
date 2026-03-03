require "Items/ProceduralDistributions"

local function InjectBunkerKitSpawns()
    if not ProceduralDistributions or not ProceduralDistributions.list then return end

    local targetDistributions = {
        "ToolStoreTools",
        "ToolStoreMisc",
        "HardwareTools",
        "MechanicTools",
        "CarSupplyTools",
        "ArmySurplusTools",
        "GigamartHardware"
    }

    local kitItem = "Base.BunkerKit"
    local spawnChance = 5 -- 5% chance

    for _, distName in ipairs(targetDistributions) do
        local distTable = ProceduralDistributions.list[distName]
        if distTable and distTable.items then
            table.insert(distTable.items, kitItem)
            table.insert(distTable.items, spawnChance)
        end
    end
end

-- Inject on game boot once ProceduralDistributions are fully loaded
Events.OnPreDistributionMerge.Add(InjectBunkerKitSpawns)
