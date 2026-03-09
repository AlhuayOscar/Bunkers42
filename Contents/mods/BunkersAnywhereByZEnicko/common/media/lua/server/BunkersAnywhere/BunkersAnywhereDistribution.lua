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
    local centralItem = "Base.ElectricCentral"
    local kitSpawnChance = 10
    local centralSpawnChance = 5

    for _, distName in ipairs(targetDistributions) do
        local distTable = ProceduralDistributions.list[distName]
        if distTable and distTable.items then
            table.insert(distTable.items, kitItem)
            table.insert(distTable.items, kitSpawnChance)
            table.insert(distTable.items, centralItem)
            table.insert(distTable.items, centralSpawnChance)
        end
    end
end

-- Inject on game boot once ProceduralDistributions are fully loaded
Events.OnPreDistributionMerge.Add(InjectBunkerKitSpawns)
