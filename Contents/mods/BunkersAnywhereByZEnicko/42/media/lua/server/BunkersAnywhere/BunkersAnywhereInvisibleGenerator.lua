BunkersAnywhere = BunkersAnywhere or {}

local CFG = {
    DataKey = "BunkersAnywhereInvisibleCentralGenerators",
    SpriteName = "location_business_bank_01_67",
    SpriteNameAlt = "location_business_bank_01_66",
    ZLevel = -1,
    GeneratorRadius = 100,
    VanillaGeneratorRadius = 20,
    DebugRadiusLogs = true,
    GeneratorRadiusUpgradeBonus = 2000,
    GeneratorRadiusUpgradeWireCost = 50,
    GeneratorRadiusUpgradeBonuses = { 25, 50, 100, 200, 500, 1000, 2000 },
    GeneratorRadiusUpgradeWireCosts = { 50, 50, 50, 50, 50, 50, 200 },
    EnableCentralRadiusUpgrade = false,
    GeneratorVertical = 3,
    LoadedPowerTickInterval = 10,
    LoadedPowerScanRange = 55,
    EnableShipping = false,
    MailboxSpriteName = "rooftop_furniture_3",
    MaxMailboxCentralDistance = 20,
    MailboxCapacity = 100,
    CentralEnergyMax = 100,
    CentralMinutesPerPercent = 4,
    BatteryMaxUses = 3,
    BatteryScrapRewardType = "Base.ElectronicsScrap",
    BatteryChargeByType = {
        ["Base.CarBattery"] = 10,
        ["Base.CarBattery1"] = 10,
        ["Base.CarBattery2"] = 15,
        ["Base.CarBattery3"] = 20,
    },
    MinElectricityToConnect = 3,
}

local function isCentralSpriteName(spriteName)
    if not spriteName then return false end
    if spriteName == CFG.SpriteName then return true end
    if spriteName == CFG.SpriteNameAlt then return true end
    if string.match(spriteName, "^location_hospitality_sunstarmotel_01_4[89]$") then return true end
    if string.match(spriteName, "^location_hospitality_sunstarmotel_01_50$") then return true end
    if string.match(spriteName, "^location_business_bank_01_") then return true end
    if string.match(spriteName, "^location_business_bank_01_6%d$") then return true end
    if string.match(spriteName, "^location_business_bank_01_7%d$") then return true end
    return false
end

local function isMailboxSpriteName(spriteName)
    if not spriteName then return false end
    if spriteName == CFG.MailboxSpriteName then return true end
    return string.match(spriteName, "^rooftop_furniture_.*_3$") ~= nil
end

local function getStore()
    local data = ModData.getOrCreate(CFG.DataKey)
    data.nodes = data.nodes or {}
    data.mailboxes = data.mailboxes or {}
    data.inboxes = data.inboxes or {}
    return data
end

local function transmitStore()
    if ModData.transmit then
        ModData.transmit(CFG.DataKey)
    end
end

local function getNodeKey(x, y, z)
    return tostring(math.floor(x)) .. ":" .. tostring(math.floor(y)) .. ":" .. tostring(math.floor(z))
end

local function getShortTypeFromFullType(fullType)
    if not fullType then return nil end
    local dot = string.find(fullType, "%.")
    if not dot then return fullType end
    return string.sub(fullType, dot + 1)
end

local function getBatteryChargePercent(fullType)
    if not fullType then return 0 end
    local charge = CFG.BatteryChargeByType[fullType]
    if charge then
        return math.floor(tonumber(charge) or 0)
    end

    local shortType = getShortTypeFromFullType(fullType)
    if not shortType then return 0 end
    for key, value in pairs(CFG.BatteryChargeByType) do
        if getShortTypeFromFullType(key) == shortType then
            return math.floor(tonumber(value) or 0)
        end
    end

    -- Fallback for battery naming variants.
    if shortType == "CarBattery" then return 10 end
    if shortType == "CarBattery1" then return 10 end
    if shortType == "CarBattery2" then return 15 end
    if shortType == "CarBattery3" then return 20 end
    return 0
end

local function clampBatteryUses(value)
    local n = math.floor(tonumber(value) or 1)
    if n < 1 then n = 1 end
    if n > CFG.BatteryMaxUses then n = CFG.BatteryMaxUses end
    return n
end

local function getBatteryStateLabelByUses(uses)
    local n = clampBatteryUses(uses)
    if n <= 1 then return "Buen estado" end
    if n == 2 then return "Usada" end
    return "Malgastada"
end

local function applyBatteryMetadata(item, uses)
    if not item then return end
    local n = clampBatteryUses(uses)
    local md = item:getModData()
    md.baCentralBatteryUses = n
    local short = getShortTypeFromFullType(item:getFullType()) or item:getType() or "CarBattery"
    if item.setName then
        item:setName(tostring(short) .. " (" .. tostring(getBatteryStateLabelByUses(n)) .. ")")
    end
end

local function getBatteryDefsOrdered()
    return {
        { shortType = "CarBattery3", fullType = "Base.CarBattery3" },
        { shortType = "CarBattery2", fullType = "Base.CarBattery2" },
        { shortType = "CarBattery1", fullType = "Base.CarBattery1" },
        { shortType = "CarBattery",  fullType = "Base.CarBattery"  },
    }
end

local function getBatteryDefByRequest(requestedFullType)
    local requestedShort = getShortTypeFromFullType(requestedFullType)
    if not requestedShort then return nil end
    for _, def in ipairs(getBatteryDefsOrdered()) do
        if requestedFullType == def.fullType or requestedShort == def.shortType then
            return def
        end
    end
    return nil
end

local function getBatteryCountInInventory(inv, def)
    if not inv or not def then return 0 end
    local cFull = tonumber(inv:getItemCountRecurse(def.fullType)) or 0
    local cShort = tonumber(inv:getItemCountRecurse(def.shortType)) or 0
    local count = math.max(cFull, cShort)
    if count > 0 then return count end

    if inv:containsTypeRecurse(def.fullType) or inv:containsTypeRecurse(def.shortType) then
        return 1
    end
    local item = inv:getItemFromTypeRecurse(def.fullType) or inv:getItemFromTypeRecurse(def.shortType)
    if item then return 1 end
    return 0
end

local function getBatteryInventorySnapshot(player)
    local counts = { CarBattery = 0, CarBattery1 = 0, CarBattery2 = 0, CarBattery3 = 0 }
    if not player then return counts end
    local inv = player:getInventory()
    if not inv then return counts end

    for _, def in ipairs(getBatteryDefsOrdered()) do
        counts[def.shortType] = getBatteryCountInInventory(inv, def)
    end
    return counts
end

local function resolveCommandPlayer(player, args)
    local resolved = player
    if args and args.onlineID and getPlayerByOnlineID then
        local id = tonumber(args.onlineID)
        if id and id >= 0 then
            local p = getPlayerByOnlineID(id)
            if p then
                resolved = p
            end
        end
    end
    return resolved
end

local function debugDumpPlayerBatteryInventory(player, reason)
    local username = (player and player.getUsername and player:getUsername()) or "unknown"
    local inv = player and player:getInventory() or nil
    if not inv then
        print("[BunkersAnywhere][ServerInvDebug] reason=" .. tostring(reason or "context") .. " user=" .. tostring(username) .. " inventory=nil")
        return
    end
    local topItems = inv:getItems()
    local topCount = topItems and topItems.size and topItems:size() or -1

    local snapshot = getBatteryInventorySnapshot(player)
    print("[BunkersAnywhere][ServerInvDebug] reason=" .. tostring(reason or "context") .. " user=" .. tostring(username)
        .. " topItems=" .. tostring(topCount)
        .. " counts: CarBattery=" .. tostring(snapshot.CarBattery or 0)
        .. " CarBattery1=" .. tostring(snapshot.CarBattery1 or 0)
        .. " CarBattery2=" .. tostring(snapshot.CarBattery2 or 0)
        .. " CarBattery3=" .. tostring(snapshot.CarBattery3 or 0))

    local summary = {}
    local total = 0
    local function scan(container)
        if not container then return end
        local items = container:getItems()
        if not items or not items.size then return end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item then
                local t = item:getType() or "?"
                local ft = item:getFullType() or "?"
                local lt = string.lower(t)
                local lft = string.lower(ft)
                if string.find(lt, "battery", 1, true) or string.find(lft, "battery", 1, true) then
                    local key = ft .. "|" .. t
                    summary[key] = (summary[key] or 0) + 1
                    total = total + 1
                end
                local child = item.getInventory and item:getInventory() or nil
                if child then
                    scan(child)
                end
            end
        end
    end
    scan(inv)

    print("[BunkersAnywhere][ServerInvDebug] batteryItems=" .. tostring(total))
    local keys = {}
    for k, _ in pairs(summary) do
        table.insert(keys, k)
    end
    table.sort(keys)
    if #keys == 0 then
        print("[BunkersAnywhere][ServerInvDebug] no battery-like items found")
    else
        for _, k in ipairs(keys) do
            local sep = string.find(k, "|", 1, true)
            local ft = sep and string.sub(k, 1, sep - 1) or k
            local t = sep and string.sub(k, sep + 1) or "?"
            print("[BunkersAnywhere][ServerInvDebug] item fullType=" .. tostring(ft) .. " type=" .. tostring(t) .. " count=" .. tostring(summary[k]))
        end
    end
end

local function findCompatibleBatteryDefInInventory(player, requestedFullType)
    if not player then return nil, 0 end
    local inv = player:getInventory()
    if not inv then return nil, 0 end

    local requestedIsAuto = (requestedFullType == nil or requestedFullType == "" or requestedFullType == "AUTO")
    if not requestedIsAuto then
        local def = getBatteryDefByRequest(requestedFullType)
        if not def then return nil, 0 end
        local count = getBatteryCountInInventory(inv, def)
        if count <= 0 then return nil, 0 end
        return def, getBatteryChargePercent(def.fullType)
    end

    for _, def in ipairs(getBatteryDefsOrdered()) do
        local count = getBatteryCountInInventory(inv, def)
        if count > 0 then
            return def, getBatteryChargePercent(def.fullType)
        end
    end
    return nil, 0
end

local function clampEnergyPercent(value)
    local n = math.floor(tonumber(value) or 0)
    if n < 0 then return 0 end
    if n > CFG.CentralEnergyMax then return CFG.CentralEnergyMax end
    return n
end

local function getMinutesPerPercent()
    local n = math.floor(tonumber(CFG.CentralMinutesPerPercent) or 0)
    if n < 1 then n = 1 end
    return n
end

local function clampRuntimeMinutes(value)
    local n = math.floor(tonumber(value) or 0)
    if n < 0 then n = 0 end
    local maxRuntime = CFG.CentralEnergyMax * getMinutesPerPercent()
    if n > maxRuntime then
        n = maxRuntime
    end
    return n
end

local function getRuntimeMinutesFromEnergyPercent(energyPercent)
    return clampRuntimeMinutes(clampEnergyPercent(energyPercent) * getMinutesPerPercent())
end

local function clampRadiusBonus(value)
    local n = math.floor(tonumber(value) or 0)
    if n < 0 then n = 0 end
    local maxBonus = math.floor(tonumber(CFG.GeneratorRadiusUpgradeBonus) or 0)
    local tiers = CFG.GeneratorRadiusUpgradeBonuses
    if tiers and #tiers > 0 then
        local tierMax = 0
        for i = 1, #tiers do
            local b = math.floor(tonumber(tiers[i]) or 0)
            if b > tierMax then tierMax = b end
        end
        if tierMax > 0 then
            maxBonus = tierMax
        end
    end
    if n > maxBonus then n = maxBonus end
    return n
end

local function getRadiusUpgradeTiers()
    local bonuses = CFG.GeneratorRadiusUpgradeBonuses or {}
    local costs = CFG.GeneratorRadiusUpgradeWireCosts or {}
    local tiers = {}
    for i = 1, #bonuses do
        local bonus = math.floor(tonumber(bonuses[i]) or 0)
        if bonus > 0 then
            local cost = math.max(1, math.floor(tonumber(costs[i]) or CFG.GeneratorRadiusUpgradeWireCost or 50))
            table.insert(tiers, { bonus = bonus, cost = cost })
        end
    end
    table.sort(tiers, function(a, b) return a.bonus < b.bonus end)
    return tiers
end

local function getNextRadiusUpgrade(currentBonus)
    local current = math.max(0, math.floor(tonumber(currentBonus) or 0))
    local tiers = getRadiusUpgradeTiers()
    for i = 1, #tiers do
        if tiers[i].bonus > current then
            return tiers[i].bonus, tiers[i].cost
        end
    end
    return nil, nil
end

local function getNodePowerRadius(node)
    local base = math.max(1, math.floor(tonumber(CFG.GeneratorRadius) or 1))
    local bonus = clampRadiusBonus(node and node.radiusBonus)
    return base + bonus
end

local function getNodeEnergyPercent(node)
    return clampEnergyPercent(node and node.energy or 0)
end

local function nodeCanSelfPower(node)
    if not node or node.source == false or node.active ~= true then return false end
    if getNodeEnergyPercent(node) <= 0 then return false end
    if clampRuntimeMinutes(node.runtimeMinutes) <= 0 then return false end
    return true
end

local function sourceNodeHasUsableEnergy(node)
    if not node or node.source == false or node.active ~= true then return false end
    local energy = getNodeEnergyPercent(node)
    if energy <= 0 then return false end
    local runtime = clampRuntimeMinutes(node.runtimeMinutes)
    if runtime <= 0 then
        runtime = getRuntimeMinutesFromEnergyPercent(energy)
        node.runtimeMinutes = runtime
    end
    return runtime > 0
end

local function getPlayerElectricityLevel(player)
    if not player or not player.getPerkLevel then return 0 end
    if not Perks or not Perks.Electricity then return 0 end
    local ok, level = pcall(function()
        return player:getPerkLevel(Perks.Electricity)
    end)
    if not ok then return 0 end
    return math.floor(tonumber(level) or 0)
end

local function playerMeetsElectricityRequirement(player)
    return getPlayerElectricityLevel(player) >= CFG.MinElectricityToConnect
end

local function hasCentralOnSquare(square)
    if not square then return false end
    local objects = square:getObjects()
    if not objects then return false, nil end
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj then
            local sprite = obj.getSprite and obj:getSprite() or nil
            local spriteName = sprite and sprite.getName and sprite:getName() or nil
            if isCentralSpriteName(spriteName) then
                return true, obj
            end
            local md = obj.getModData and obj:getModData() or nil
            if md and (md.baInvisibleGeneratorConnected ~= nil or md.baInvisibleGeneratorIsSource ~= nil or md.baCentralEnergyPercent ~= nil) then
                return true, obj
            end
        end
    end
    return false, nil
end

local function hasMailboxOnSquare(square)
    if not square then return false end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and obj.getSprite then
            local sprite = obj:getSprite()
            local spriteName = sprite and sprite.getName and sprite:getName() or nil
            if isMailboxSpriteName(spriteName) then
                return true, obj
            end
        end
    end
    return false, nil
end

local function findOwnedGeneratorNearSquare(square)
    if not square then return nil, nil end
    local cell = getCell()
    if not cell then return nil, nil end

    local sx, sy, sz = square:getX(), square:getY(), square:getZ()
    for dx = -1, 1 do
        for dy = -1, 1 do
            local sq = nil
            if dx == 0 and dy == 0 then
                sq = square
            else
                sq = cell:getGridSquare(sx + dx, sy + dy, sz)
            end
            if sq then
                local g = sq:getGenerator()
                if g and g.getModData then
                    local md = g:getModData()
                    if md and md.baInvisibleGeneratorOwned then
                        return g, sq
                    end
                end
            end
        end
    end

    return nil, nil
end

local function getGeneratorActivatedState(generator)
    if not generator then return nil end
    if generator.isActivated then
        local ok, value = pcall(function() return generator:isActivated() end)
        if ok then return value == true end
    end
    if generator.getActivated then
        local ok, value = pcall(function() return generator:getActivated() end)
        if ok then return value == true end
    end
    return nil
end

local function setGeneratorActivatedState(generator, on)
    if not generator then return nil end
    local desired = on == true

    if generator.setConnected then
        pcall(function() generator:setConnected(true) end)
    end
    if generator.setActivated then
        pcall(function() generator:setActivated(desired) end)
    end
    if generator.setSurroundingElectricity then
        pcall(function() generator:setSurroundingElectricity() end)
    end
    if IsoGenerator and IsoGenerator.updateSurroundingNow then
        pcall(function() IsoGenerator.updateSurroundingNow() end)
    end
    if generator.sync then
        pcall(function() generator:sync() end)
    end

    return getGeneratorActivatedState(generator)
end

local function removeOwnedGenerator(square)
    if not square then return end
    local generator = square:getGenerator()
    local targetSquare = square
    if not generator or not generator.getModData then
        generator, targetSquare = findOwnedGeneratorNearSquare(square)
    end
    if not generator or not generator.getModData then return end
    local gmd = generator:getModData()
    if gmd and gmd.baInvisibleGeneratorOwned then
        setGeneratorActivatedState(generator, false)
        if targetSquare and targetSquare.transmitRemoveItemFromSquare then
            targetSquare:transmitRemoveItemFromSquare(generator)
        else
            generator:remove()
        end
    end
end

local function normalizeBool(value)
    if value == true then return true end
    if value == 1 or value == "1" then return true end
    if value == "true" then return true end
    return false
end

local function ensureInvisibleGenerator(square, wantOn)
    if not square then return end

    local generator = square:getGenerator()
    local created = false
    if generator and generator.getModData then
        local gmd = generator:getModData()
        if not gmd.baInvisibleGeneratorOwned then
            generator = nil
        end
    end

    if not generator then
        generator = findOwnedGeneratorNearSquare(square)
    end

    if not generator then
        local item = instanceItem("Base.Generator")
        if not item then return end
        item:setCondition(100)
        item:getModData().fuel = 100
        generator = IsoGenerator.new(item, getCell(), square)
        created = generator ~= nil
    end
    if not generator then return end

    local gmd = generator:getModData()
    local changed = false

    if gmd.baInvisibleGeneratorOwned ~= true then
        gmd.baInvisibleGeneratorOwned = true
        changed = true
    end

    local shouldBeOn = wantOn == true
    local currentlyOn = getGeneratorActivatedState(generator)
    local storedOn = normalizeBool(gmd.baInvisibleGeneratorLastAppliedOn)
    local effectiveCurrent = currentlyOn
    if effectiveCurrent == nil then
        effectiveCurrent = storedOn
    end

    if created then
        if generator.setCondition then
            pcall(function() generator:setCondition(100) end)
        end
        if generator.setFuel then
            pcall(function() generator:setFuel(100) end)
        end
        if generator.setConnected then
            pcall(function() generator:setConnected(true) end)
        end
        changed = true
    end

    if effectiveCurrent ~= shouldBeOn then
        setGeneratorActivatedState(generator, shouldBeOn)
        changed = true
    end

    if storedOn ~= shouldBeOn then
        gmd.baInvisibleGeneratorLastAppliedOn = shouldBeOn
        changed = true
    end

    if generator.setAlpha then
        pcall(function() generator:setAlpha(0.0) end)
    end
    if generator.setSprite then
        pcall(function() generator:setSprite(nil) end)
    end

    if changed then
        if generator.transmitModData then
            pcall(function() generator:transmitModData() end)
        end
        if generator.sync then
            pcall(function() generator:sync() end)
        end
    end
end
local function setSquarePower(square, on)
    if not square then return false end
    local changed = false
    if square.setHaveElectricity then
        square:setHaveElectricity(on == true)
        changed = true
    end
    if square.setHasGridPower then
        square:setHasGridPower(on == true)
        changed = true
    end
    if square.RecalcProperties then
        square:RecalcProperties()
    end
    return changed
end

local function isSquareCoveredByActiveNodes(x, y, z, activeNodes)
    if not activeNodes then return false end
    local vertical = math.max(0, math.floor(tonumber(CFG.GeneratorVertical) or 0))
    for i = 1, #activeNodes do
        local n = activeNodes[i]
        if math.abs((n.z or 0) - z) <= vertical then
            local dx = x - n.x
            local dy = y - n.y
            if (dx * dx + dy * dy) <= n.r2 then
                return true
            end
        end
    end
    return false
end

local function clampGeneratorPowerToBasement(node, activeNodes)
    if not node then return false end
    local cell = getCell()
    if not cell then return false end
    local r = getNodePowerRadius(node)
    local changedAny = false
    for ix = node.x - r, node.x + r do
        for iy = node.y - r, node.y + r do
            for iz = node.z - CFG.GeneratorVertical, node.z + CFG.GeneratorVertical do
                if iz ~= node.z then
                    local sq = cell:getGridSquare(ix, iy, iz)
                    if sq then
                        local keepOn = isSquareCoveredByActiveNodes(ix, iy, iz, activeNodes)
                        if not keepOn then
                            if setSquarePower(sq, false) then
                                changedAny = true
                            end
                        end
                    end
                end
            end
        end
    end
    return changedAny
end

-- Vanilla generator only powers its own base radius (~20 tiles). Apply
-- manual grid power from vanilla radius up to configured target radius.
local function applyExtendedBasementPowerForNode(node, on)
    if not node then return false end
    local cell = getCell()
    if not cell then return false end

    local baseR = math.max(0, math.floor(tonumber(CFG.VanillaGeneratorRadius) or 20))
    local targetR = getNodePowerRadius(node)
    if targetR <= baseR then return false end

    local baseR2 = baseR * baseR
    local targetR2 = targetR * targetR
    local changedAny = false
    local desired = on == true

    local vertical = math.max(0, math.floor(tonumber(CFG.GeneratorVertical) or 0))
    for ix = node.x - targetR, node.x + targetR do
        local dx = ix - node.x
        for iy = node.y - targetR, node.y + targetR do
            local dy = iy - node.y
            local d2 = dx * dx + dy * dy
            if d2 <= targetR2 then
                for iz = node.z - vertical, node.z + vertical do
                    -- On node.z, preserve vanilla inner radius and only apply the extra ring.
                    -- On other z levels, apply full target radius manually.
                    local shouldApply = (iz ~= node.z) or (d2 > baseR2)
                    if shouldApply then
                        local sq = cell:getGridSquare(ix, iy, iz)
                        if sq then
                            if setSquarePower(sq, desired) then
                                changedAny = true
                            end
                        end
                    end
                end
            end
        end
    end
    return changedAny
end

local function forceNoToxic(square)
    if not square then return end
    local building = square:getBuilding()
    if not building or not building.setToxic then return end

    local toxic = nil
    if building.isToxic then
        local ok, value = pcall(function() return building:isToxic() end)
        if ok then toxic = value == true end
    elseif building.getToxic then
        local ok, value = pcall(function() return building:getToxic() end)
        if ok then toxic = value == true end
    end

    if toxic == true then
        building:setToxic(false)
    end
end

local function copyInstalledBatteriesList(installed)
    local result = {}
    if not installed then return result end
    for i = 1, #installed do
        local entry = installed[i]
        if entry then
            table.insert(result, {
                fullType = tostring(entry.fullType or "Base.CarBattery"),
                uses = clampBatteryUses(entry.uses),
            })
        end
    end
    return result
end

local function updateCentralModData(square, on, localOn, providerText, providerCount, isSource, energyPercent, installedBatteries, runtimeMinutes, radiusBonus)
    local hasCentral, centralObj = hasCentralOnSquare(square)
    if hasCentral and centralObj and centralObj.getModData then
        local md = centralObj:getModData()
        md.baInvisibleGeneratorConnected = isSource == true
        md.baInvisibleGeneratorIsSource = isSource == true
        md.baInvisibleGeneratorOn = on == true
        md.baInvisibleGeneratorLocalOn = localOn == true
        md.baInvisibleGeneratorProviderText = providerText or ""
        md.baInvisibleGeneratorProviderCount = tonumber(providerCount) or 0
        md.baCentralEnergyPercent = clampEnergyPercent(energyPercent)
        md.baCentralRuntimeMinutes = clampRuntimeMinutes(runtimeMinutes)
        md.baCentralRadiusBonus = clampRadiusBonus(radiusBonus)
        md.baCentralRadius = getNodePowerRadius({ radiusBonus = radiusBonus })
        local copied = copyInstalledBatteriesList(installedBatteries)
        md.baCentralInstalledBatteries = copied
        md.baCentralInstalledBatteryCount = #copied
        if centralObj.transmitModData then
            centralObj:transmitModData()
        end
    end
end

local function getNetworkState(store)
    local effective = {}
    local providers = {}
    local visited = {}

    for rootKey, rootNode in pairs(store.nodes) do
        if rootNode and rootNode.active and not visited[rootKey] then
            local stack = { rootKey }
            local component = {}
            local activeProviders = {}
            local hasSourceProvider = false

            while #stack > 0 do
                local key = table.remove(stack)
                local node = store.nodes[key]
                if not visited[key] and node and node.active then
                    visited[key] = true
                    table.insert(component, key)
                    if sourceNodeHasUsableEnergy(node) then
                        hasSourceProvider = true
                        table.insert(activeProviders, {
                            x = node.x,
                            y = node.y,
                            z = node.z,
                            key = key,
                        })
                    end

                    local links = node.links or {}
                    for linkedKey, enabled in pairs(links) do
                        local linkedNode = store.nodes[linkedKey]
                        if enabled and linkedNode and linkedNode.active and not visited[linkedKey] then
                            table.insert(stack, linkedKey)
                        end
                    end
                end
            end

            if hasSourceProvider then
                for _, key in ipairs(component) do
                    effective[key] = true
                    providers[key] = activeProviders
                end
            else
                for _, key in ipairs(component) do
                    effective[key] = false
                    providers[key] = {}
                end
            end
        end
    end

    return effective, providers
end

local function collectWantedPowerNodes(store, effective)
    local activeNodes = {}
    if not store or not store.nodes then return activeNodes end

    for key, node in pairs(store.nodes) do
        if node then
            local wantOn = effective and effective[key] == true
            if node.source ~= false and nodeCanSelfPower(node) then
                wantOn = true
            end
            if wantOn then
                local r = getNodePowerRadius(node)
                if r > 0 then
                    table.insert(activeNodes, {
                        x = node.x,
                        y = node.y,
                        z = node.z,
                        r2 = r * r,
                    })
                end
            end
        end
    end

    return activeNodes
end

local _baLastRadiusDebugSignatureByKey = {}
local function logCentralRadiusIfChanged(key, node, wantOn, providerCount)
    if CFG.DebugRadiusLogs ~= true then return end
    if not key or not node then return end

    local baseR = math.max(1, math.floor(tonumber(CFG.GeneratorRadius) or 1))
    local vanillaR = math.max(0, math.floor(tonumber(CFG.VanillaGeneratorRadius) or 20))
    local bonusR = clampRadiusBonus(node.radiusBonus)
    local targetR = baseR + bonusR
    local energy = getNodeEnergyPercent(node)
    local runtime = clampRuntimeMinutes(node.runtimeMinutes)
    local localOn = node.active == true
    local isSource = node.source ~= false
    local providers = math.floor(tonumber(providerCount) or 0)

    local signature = table.concat({
        tostring(targetR),
        tostring(wantOn == true),
        tostring(localOn),
        tostring(energy),
        tostring(runtime),
        tostring(providers),
    }, "|")

    if _baLastRadiusDebugSignatureByKey[key] == signature then return end
    _baLastRadiusDebugSignatureByKey[key] = signature

    print(
        "[BunkersAnywhere][RadiusDebug] key=" .. tostring(key) ..
        " pos=" .. tostring(node.x) .. "," .. tostring(node.y) .. "," .. tostring(node.z) ..
        " source=" .. tostring(isSource) ..
        " localOn=" .. tostring(localOn) ..
        " netOn=" .. tostring(wantOn == true) ..
        " vanilla=" .. tostring(vanillaR) ..
        " base=" .. tostring(baseR) ..
        " bonus=" .. tostring(bonusR) ..
        " target=" .. tostring(targetR) ..
        " providers=" .. tostring(providers) ..
        " energy=" .. tostring(energy) ..
        " runtime=" .. tostring(runtime)
    )
end

local function applyNetworkPower(store)
    local effective, providers = getNetworkState(store)
    local activeNodes = collectWantedPowerNodes(store, effective)

    if CFG.DebugRadiusLogs == true then
        for loggedKey, _ in pairs(_baLastRadiusDebugSignatureByKey) do
            if not (store.nodes and store.nodes[loggedKey]) then
                _baLastRadiusDebugSignatureByKey[loggedKey] = nil
            end
        end
    end

    for key, node in pairs(store.nodes) do
        local square = getSquare(node.x, node.y, node.z)
        local localOn = node.active == true
        local energyPercent = getNodeEnergyPercent(node)
        local wantOn = effective[key] == true
        local isSource = node.source ~= false
        if isSource and nodeCanSelfPower(node) then
            wantOn = true
        end
        local providerText, providerCount = "", 0
        local pList = providers[key]
        if pList then
            local parts = {}
            for _, p in ipairs(pList) do
                -- Do not count self as a dependency.
                if p.key ~= key then
                    table.insert(parts, tostring(p.x) .. "," .. tostring(p.y) .. "," .. tostring(p.z))
                end
            end
            providerCount = #parts
            providerText = table.concat(parts, " | ")
        end

        logCentralRadiusIfChanged(key, node, wantOn, providerCount)

        if square then
            updateCentralModData(square, wantOn, localOn, providerText, providerCount, isSource, energyPercent, node.installedBatteries, node.runtimeMinutes, node.radiusBonus)
            ensureInvisibleGenerator(square, wantOn)
            applyExtendedBasementPowerForNode(node, wantOn)
            if wantOn then
                forceNoToxic(square)
            end
            clampGeneratorPowerToBasement(node, activeNodes)
        end
    end
    return effective, providers
end

local function syncCentralModDataFromState(store, effective, providers)
    for key, node in pairs(store.nodes) do
        local square = getSquare(node.x, node.y, node.z)
        if square then
            local localOn = node.active == true
            local energyPercent = getNodeEnergyPercent(node)
            local wantOn = effective[key] == true
            local isSource = node.source ~= false
            local providerText, providerCount = "", 0
            local pList = providers and providers[key] or nil
            if pList then
                local parts = {}
                for _, p in ipairs(pList) do
                    if p.key ~= key then
                        table.insert(parts, tostring(p.x) .. "," .. tostring(p.y) .. "," .. tostring(p.z))
                    end
                end
                providerCount = #parts
                providerText = table.concat(parts, " | ")
            end
            updateCentralModData(square, wantOn, localOn, providerText, providerCount, isSource, energyPercent, node.installedBatteries, node.runtimeMinutes, node.radiusBonus)
        end
    end
end

local function syncOwnedGeneratorActivationFromState(store, effective)
    for key, node in pairs(store.nodes) do
        local square = getSquare(node.x, node.y, node.z)
        if square then
            local wantOn = effective and effective[key] == true
            if node and node.source ~= false and nodeCanSelfPower(node) then
                wantOn = true
            end
            ensureInvisibleGenerator(square, wantOn)
        end
    end
end

local function collectActivePowerNodes(store, effective)
    local nodes = {}
    if not store or not store.nodes then return nodes end
    for key, node in pairs(store.nodes) do
        if node and effective and effective[key] == true then
            local r = getNodePowerRadius(node)
            if r > 0 then
                table.insert(nodes, {
                    x = node.x,
                    y = node.y,
                    z = node.z,
                    r2 = r * r,
                })
            end
        end
    end
    return nodes
end

local function isSquarePoweredByActiveNode(x, y, z, activeNodes)
    local vertical = math.max(0, math.floor(tonumber(CFG.GeneratorVertical) or 0))
    for i = 1, #activeNodes do
        local n = activeNodes[i]
        if math.abs((n.z or 0) - z) <= vertical then
            local dx = x - n.x
            local dy = y - n.y
            if (dx * dx + dy * dy) <= n.r2 then
                return true
            end
        end
    end
    return false
end

local function forEachOnlinePlayerSafe(fn)
    if not fn then return end
    if getOnlinePlayers then
        local players = getOnlinePlayers()
        if players and players.size and players.get then
            for i = 0, players:size() - 1 do
                local p = players:get(i)
                if p then fn(p) end
            end
            return
        end
    end
    if getNumActivePlayers and getSpecificPlayer then
        local num = tonumber(getNumActivePlayers()) or 0
        for i = 0, num - 1 do
            local p = getSpecificPlayer(i)
            if p then fn(p) end
        end
    end
end

-- Keep loaded chunks around players synchronized with central power
-- radius (including upgraded tiers), even when central chunks are unloaded.
local _baLoadedBasementPowerTick = 0
local function maintainLoadedBasementPowerAroundPlayers()
    _baLoadedBasementPowerTick = _baLoadedBasementPowerTick + 1
    local tickInterval = math.max(1, math.floor(tonumber(CFG.LoadedPowerTickInterval) or 1))
    if _baLoadedBasementPowerTick < tickInterval then return end
    _baLoadedBasementPowerTick = 0

    local store = getStore()
    if not store or not store.nodes then return end
    local cell = getCell()
    if not cell then return end

    local effective = getNetworkState(store)
    local activeNodes = collectActivePowerNodes(store, effective)
    local range = math.max(10, math.floor(tonumber(CFG.LoadedPowerScanRange) or 55))

    forEachOnlinePlayerSafe(function(player)
        local sq = player and player.getSquare and player:getSquare() or nil
        if not sq then return end
        local px, py, pz = sq:getX(), sq:getY(), sq:getZ()
        local nodesNearPlayerZ = {}
        local vertical = math.max(0, math.floor(tonumber(CFG.GeneratorVertical) or 0))
        for i = 1, #activeNodes do
            local n = activeNodes[i]
            if n and math.abs((n.z or 0) - pz) <= vertical then
                table.insert(nodesNearPlayerZ, n)
            end
        end
        if #nodesNearPlayerZ <= 0 then return end

        -- Skip full-area scans if no active central on this z can affect the
        -- player's nearby loaded range.
        local canAffectPlayerArea = false
        for i = 1, #nodesNearPlayerZ do
            local n = nodesNearPlayerZ[i]
            local dx = px - n.x
            local dy = py - n.y
            local maxReach = range + math.floor(math.sqrt(n.r2))
            if (dx * dx + dy * dy) <= (maxReach * maxReach) then
                canAffectPlayerArea = true
                break
            end
        end
        if not canAffectPlayerArea then return end

        for x = px - range, px + range do
            for y = py - range, py + range do
                local gs = cell:getGridSquare(x, y, pz)
                if gs then
                    local shouldOn = isSquarePoweredByActiveNode(x, y, pz, nodesNearPlayerZ)
                    setSquarePower(gs, shouldOn)
                    if shouldOn then
                        forceNoToxic(gs)
                    end
                end
            end
        end
    end)
end

local _baPowerMaintainTick = 0
local function maintainPowerSafety()
    _baPowerMaintainTick = _baPowerMaintainTick + 1
    if _baPowerMaintainTick < 30 then return end
    _baPowerMaintainTick = 0

    local store = getStore()
    if not store or not store.nodes then return end
    local effective = getNetworkState(store)
    local activeNodes = collectWantedPowerNodes(store, effective)
    for key, node in pairs(store.nodes) do
        local square = getSquare(node.x, node.y, node.z)
        if square then
            local wantOn = effective[key] == true
            if node and node.source ~= false and nodeCanSelfPower(node) then
                wantOn = true
            end
            ensureInvisibleGenerator(square, wantOn)
            if wantOn then
                forceNoToxic(square)
            end
            clampGeneratorPowerToBasement(node, activeNodes)
        end
    end
end

local function findNearestActiveCentralNodeKeyFromSquare(square)
    if not square then return nil end
    local store = getStore()
    local effective = getNetworkState(store)
    local bestKey = nil
    local bestDist = 999999
    local sx = square:getX()
    local sy = square:getY()
    local sz = square:getZ()

    for key, node in pairs(store.nodes) do
        if node and effective[key] and node.z == sz then
            local dx = node.x - sx
            local dy = node.y - sy
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist <= CFG.MaxMailboxCentralDistance and dist < bestDist then
                bestDist = dist
                bestKey = key
            end
        end
    end

    return bestKey
end

local function mergeItemsMap(dest, src)
    if not dest or not src then return end
    for fullType, count in pairs(src) do
        local n = math.floor(tonumber(count) or 0)
        if n > 0 then
            dest[fullType] = (dest[fullType] or 0) + n
        end
    end
end

local function getItemsMapCount(src)
    local total = 0
    if not src then return 0 end
    for _, count in pairs(src) do
        local n = math.floor(tonumber(count) or 0)
        if n > 0 then
            total = total + n
        end
    end
    return total
end

local function clearItemsMap(map)
    if not map then return end
    for k, _ in pairs(map) do
        map[k] = nil
    end
end

local function ensureNodeAt(x, y, z, asSource)
    local square = getSquare(x, y, z)
    if not square then return false end
    local hasCentral, centralObj = hasCentralOnSquare(square)
    if not hasCentral then return false end

    local store = getStore()
    local key = getNodeKey(x, y, z)
    local existed = store.nodes[key] ~= nil
    local previous = store.nodes[key] or {}
    local node = {
        x = x,
        y = y,
        z = z,
        active = (previous.active == nil) and true or (previous.active == true),
        links = previous.links or {},
        source = previous.source,
        energy = previous.energy,
        radiusBonus = previous.radiusBonus,
        runtimeMinutes = previous.runtimeMinutes,
        runtimeDrainRemainder = tonumber(previous.runtimeDrainRemainder) or 0,
        missingCentralMinutes = math.floor(tonumber(previous.missingCentralMinutes) or 0),
        installedBatteries = previous.installedBatteries or {},
    }

    if not existed and centralObj and centralObj.getModData then
        local md = centralObj:getModData()
        if node.source == nil and md and md.baInvisibleGeneratorIsSource ~= nil then
            node.source = md.baInvisibleGeneratorIsSource == true
        end
        if md and md.baCentralEnergyPercent ~= nil then
            node.energy = clampEnergyPercent(md.baCentralEnergyPercent)
        end
        if md and md.baCentralRuntimeMinutes ~= nil then
            node.runtimeMinutes = clampRuntimeMinutes(md.baCentralRuntimeMinutes)
        end
        if md and md.baCentralRadiusBonus ~= nil then
            node.radiusBonus = clampRadiusBonus(md.baCentralRadiusBonus)
        end
        if (#node.installedBatteries <= 0) and md and md.baCentralInstalledBatteries and type(md.baCentralInstalledBatteries) == "table" then
            for i = 1, #md.baCentralInstalledBatteries do
                local entry = md.baCentralInstalledBatteries[i]
                if entry then
                    table.insert(node.installedBatteries, {
                        fullType = tostring(entry.fullType or "Base.CarBattery"),
                        uses = clampBatteryUses(entry.uses),
                    })
                end
            end
        end
    end
    if asSource == true then
        node.source = true
    elseif not existed and node.source == nil then
        node.source = false
    elseif node.source == nil then
        -- Backward compatibility: old saves may have nil source.
        -- Runtime logic already treats nil as source (source ~= false).
        node.source = true
    end
    node.radiusBonus = clampRadiusBonus(node.radiusBonus)
    node.energy = clampEnergyPercent(node.energy)
    node.runtimeMinutes = clampRuntimeMinutes(node.runtimeMinutes)
    if node.runtimeDrainRemainder < 0 then node.runtimeDrainRemainder = 0 end
    if node.missingCentralMinutes < 0 then node.missingCentralMinutes = 0 end
    if node.source ~= false and node.energy > 0 and node.runtimeMinutes <= 0 then
        node.runtimeMinutes = getRuntimeMinutesFromEnergyPercent(node.energy)
    end
    if node.source ~= false and (node.energy <= 0 or node.runtimeMinutes <= 0) then
        node.active = false
    end
    store.nodes[key] = node
    return true
end

local function connectNodeAt(x, y, z, player)
    if not playerMeetsElectricityRequirement(player) then return false end
    if not ensureNodeAt(x, y, z, true) then return false end

    local store = getStore()
    local key = getNodeKey(x, y, z)
    if store.nodes[key] then
        store.nodes[key].source = true
        store.nodes[key].energy = clampEnergyPercent(store.nodes[key].energy)
        store.nodes[key].runtimeMinutes = clampRuntimeMinutes(store.nodes[key].runtimeMinutes)
        if getNodeEnergyPercent(store.nodes[key]) > 0 and store.nodes[key].runtimeMinutes <= 0 then
            store.nodes[key].runtimeMinutes = getRuntimeMinutesFromEnergyPercent(store.nodes[key].energy)
        end
        store.nodes[key].active = true
        if getNodeEnergyPercent(store.nodes[key]) <= 0 or store.nodes[key].runtimeMinutes <= 0 then
            store.nodes[key].active = false
        end
    end

    transmitStore()
    applyNetworkPower(store)
    return true
end

local function registerNodeAt(x, y, z)
    if not ensureNodeAt(x, y, z, false) then return false end
    local store = getStore()
    transmitStore()
    applyNetworkPower(store)
    return true
end

local function linkNodes(ax, ay, az, bx, by, bz, player)
    if not playerMeetsElectricityRequirement(player) then return false end
    local store = getStore()
    local keyA = getNodeKey(ax, ay, az)
    local keyB = getNodeKey(bx, by, bz)
    local a = store.nodes[keyA]
    local b = store.nodes[keyB]

    -- Bypass: if central tiles exist but nodes were not registered yet,
    -- register as non-source nodes before linking.
    if not a then
        ensureNodeAt(ax, ay, az, false)
        store = getStore()
        a = store.nodes[keyA]
    end
    if not b then
        ensureNodeAt(bx, by, bz, false)
        store = getStore()
        b = store.nodes[keyB]
    end
    if not a or not b then return false end

    a.links = a.links or {}
    b.links = b.links or {}
    if a.links[keyB] == true and b.links[keyA] == true then
        return true
    end
    a.links[keyB] = true
    b.links[keyA] = true
    transmitStore()
    applyNetworkPower(store)
    return true
end

local function setNodeStateAt(x, y, z, wantOn)
    local square = getSquare(x, y, z)
    if not square then return false end
    local key = getNodeKey(x, y, z)
    local store = getStore()
    local node = store.nodes[key]
    if not node then return false end
    if wantOn == true and node.source ~= false and (getNodeEnergyPercent(node) <= 0 or clampRuntimeMinutes(node.runtimeMinutes) <= 0) then
        return false
    end
    node.active = wantOn == true
    transmitStore()

    applyNetworkPower(store)
    return true
end

local function countElectricWireInInventory(player)
    if not player then return 0 end
    local inv = player:getInventory()
    if not inv then return 0 end
    local c1 = tonumber(inv:getItemCountRecurse("ElectricWire")) or 0
    local c2 = tonumber(inv:getItemCountRecurse("Base.ElectricWire")) or 0
    return math.max(c1, c2)
end

local function consumeElectricWireFromPlayer(player, amount)
    local need = math.max(0, math.floor(tonumber(amount) or 0))
    if need <= 0 then return true end
    if not player then return false end
    local inv = player:getInventory()
    if not inv then return false end

    local before = countElectricWireInInventory(player)
    if before < need then return false end

    local remaining = need
    while remaining > 0 do
        local prev = countElectricWireInInventory(player)
        if prev <= 0 then break end
        inv:RemoveOneOf("Base.ElectricWire")
        local after = countElectricWireInInventory(player)
        if after < prev then
            remaining = remaining - 1
        else
            inv:RemoveOneOf("ElectricWire")
            after = countElectricWireInInventory(player)
            if after < prev then
                remaining = remaining - 1
            else
                break
            end
        end
    end

    return remaining <= 0
end

local function upgradeCentralRadiusAt(x, y, z, player, args)
    if CFG.EnableCentralRadiusUpgrade ~= true then
        if CFG.DebugRadiusLogs == true then
            print("[BunkersAnywhere][RadiusDebug] UpgradeCentralRadius ignored: temporarily disabled")
        end
        return false
    end

    local store = getStore()
    local key = getNodeKey(x, y, z)
    local node = store.nodes[key]
    if not node then
        ensureNodeAt(x, y, z, true)
        node = store.nodes[key]
    end
    if not node then
        if CFG.DebugRadiusLogs == true then
            print("[BunkersAnywhere][RadiusDebug] UpgradeCentralRadius rejected: node missing at " .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))
        end
        return false
    end
    if node.source == false then
        if CFG.DebugRadiusLogs == true then
            print("[BunkersAnywhere][RadiusDebug] UpgradeCentralRadius rejected: non-source key=" .. tostring(key))
        end
        return false
    end

    local current = clampRadiusBonus(node.radiusBonus)
    local nextBonus, wireCost = getNextRadiusUpgrade(current)
    if not nextBonus then
        if CFG.DebugRadiusLogs == true then
            print("[BunkersAnywhere][RadiusDebug] UpgradeCentralRadius rejected: max tier key=" .. tostring(key) .. " currentBonus=" .. tostring(current))
        end
        return false
    end

    local paid = false
    if args and args.clientConsumed == true and (tonumber(args.wires) or 0) >= wireCost then
        paid = true
    else
        paid = consumeElectricWireFromPlayer(player, wireCost)
    end
    if not paid then
        if CFG.DebugRadiusLogs == true then
            print("[BunkersAnywhere][RadiusDebug] UpgradeCentralRadius rejected: wire payment failed key=" .. tostring(key) .. " need=" .. tostring(wireCost))
        end
        return false
    end

    node.radiusBonus = nextBonus
    transmitStore()
    applyNetworkPower(store)
    if CFG.DebugRadiusLogs == true then
        print("[BunkersAnywhere][RadiusDebug] UpgradeCentralRadius applied: key=" .. tostring(key) .. " " .. tostring(current) .. " -> " .. tostring(nextBonus))
    end
    return true
end

local function consumeBatteryItemFromPlayer(player, fullType)
    if not player then return false, nil, 0 end
    local inv = player:getInventory()
    if not inv then return false, nil, 0 end

    local def, charge = findCompatibleBatteryDefInInventory(player, fullType)
    if not def or charge <= 0 then
        return false, nil, 0
    end

    local before = getBatteryCountInInventory(inv, def)
    if before <= 0 then
        return false, nil, 0
    end

    inv:RemoveOneOf(def.fullType)
    local after = getBatteryCountInInventory(inv, def)
    if after < before then
        return true, def.fullType, charge
    end

    inv:RemoveOneOf(def.shortType)
    after = getBatteryCountInInventory(inv, def)
    if after < before then
        return true, def.fullType, charge
    end

    local item = inv:getItemFromTypeRecurse(def.fullType) or inv:getItemFromTypeRecurse(def.shortType)
    if item then
        local container = item:getContainer()
        if container then
            if container.DoRemoveItem then
                container:DoRemoveItem(item)
            else
                container:Remove(item)
            end
            return true, (item:getFullType() or def.fullType), charge
        end
    end

    return false, nil, 0
end

local function insertCentralBatteryAt(x, y, z, player, fullType, args)
    local store = getStore()
    local key = getNodeKey(x, y, z)
    local node = store.nodes[key]
    if not node or node.source ~= true then
        ensureNodeAt(x, y, z, true)
        node = store.nodes[key]
    end
    if not node then return false end
    node.source = true
    node.installedBatteries = node.installedBatteries or {}

    local okRemove, resolvedFullType, charge = false, nil, 0
    local clientConsumed = args and args.clientConsumed == true
    local clientCharge = args and math.floor(tonumber(args.charge) or 0) or 0
    local batteryUses = 1

    if clientConsumed and clientCharge > 0 then
        okRemove = true
        resolvedFullType = tostring(fullType or "")
        charge = clientCharge
        batteryUses = clampBatteryUses(args and args.batteryUses or 1)
    else
        okRemove, resolvedFullType, charge = consumeBatteryItemFromPlayer(player, fullType)
        if not okRemove then
            local counts = getBatteryInventorySnapshot(player)
            local uname = (player and player.getUsername and player:getUsername()) or "unknown"
            print("[BunkersAnywhere] InsertCentralBattery rejected: no compatible battery in inventory (" .. tostring(fullType) .. ") user=" .. tostring(uname) .. " counts: CarBattery=" .. tostring(counts.CarBattery or 0) .. " CarBattery1=" .. tostring(counts.CarBattery1 or 0) .. " CarBattery2=" .. tostring(counts.CarBattery2 or 0) .. " CarBattery3=" .. tostring(counts.CarBattery3 or 0))
            return false
        end
    end
    if charge <= 0 then
        print("[BunkersAnywhere] InsertCentralBattery rejected: charge could not be resolved for " .. tostring(resolvedFullType))
        return false
    end

    local current = getNodeEnergyPercent(node)
    local target = current + charge
    if target > CFG.CentralEnergyMax then
        if clientConsumed then
            target = CFG.CentralEnergyMax
        else
            -- rollback battery removal if charge would exceed max
            if player and resolvedFullType and resolvedFullType ~= "" then
                local inv = player:getInventory()
                if inv and inv.AddItem then
                    inv:AddItem(resolvedFullType)
                end
            end
            print("[BunkersAnywhere] InsertCentralBattery rejected: would exceed 100% at " .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))
            return false
        end
    end

    node.energy = clampEnergyPercent(target)
    local addedRuntime = getRuntimeMinutesFromEnergyPercent(charge)
    node.runtimeMinutes = clampRuntimeMinutes((node.runtimeMinutes or 0) + addedRuntime)
    local autoReactivated = false
    if node.source ~= false and node.energy > 0 and node.runtimeMinutes > 0 and node.active ~= true then
        node.active = true
        autoReactivated = true
    end
    table.insert(node.installedBatteries, {
        fullType = resolvedFullType,
        uses = batteryUses,
    })
    print("[BunkersAnywhere] InsertCentralBattery applied: " .. tostring(resolvedFullType) .. " +" .. tostring(charge) .. "% (" .. tostring(current) .. "% -> " .. tostring(node.energy) .. "%) runtime=" .. tostring(node.runtimeMinutes) .. " autoReactivated=" .. tostring(autoReactivated))
    transmitStore()
    applyNetworkPower(store)

    -- Fallback: if this is a source central with energy, force world power ON now.
    -- This avoids desync cases where network-state says ON but tiles stay OFF.
    if node.source ~= false and node.active == true and getNodeEnergyPercent(node) > 0 then
        local square = getSquare(node.x, node.y, node.z)
        if square then
            local effectiveNow = getNetworkState(store)
            local activeNodes = collectWantedPowerNodes(store, effectiveNow)
            ensureInvisibleGenerator(square, true)
            forceNoToxic(square)
            clampGeneratorPowerToBasement(node, activeNodes)
            local g = square:getGenerator() or findOwnedGeneratorNearSquare(square)
            local gOn = getGeneratorActivatedState(g)
            print("[BunkersAnywhere] InsertCentralBattery power-apply: key=" .. tostring(key) .. " generatorOn=" .. tostring(gOn) .. " energy=" .. tostring(getNodeEnergyPercent(node)))
        end
    end
    return true
end

local function giveBatteryScrapReward(player)
    if not player then return false end
    local inv = player:getInventory()
    if not inv then return false end

    local scrap = inv:AddItem(CFG.BatteryScrapRewardType)
    if scrap then return true end

    scrap = inv:AddItem("Base.ScrapElectronics")
    if scrap then return true end

    scrap = inv:AddItem("Base.ElectronicsScrap")
    return scrap ~= nil
end

local function sendCentralBatteryPayoutToClient(player, mode, fullType, uses)
    if not player or not sendServerCommand then return false end
    local ok = pcall(function()
        sendServerCommand(player, "BunkersAnywhere", "CentralBatteryPayout", {
            mode = tostring(mode or ""),
            fullType = tostring(fullType or ""),
            uses = clampBatteryUses(uses),
        })
    end)
    return ok == true
end

local function sendCentralBatteryPayoutToTargets(primaryPlayer, fallbackPlayer, mode, fullType, uses)
    local sentAny = false
    if sendCentralBatteryPayoutToClient(primaryPlayer, mode, fullType, uses) then
        sentAny = true
    end
    if fallbackPlayer and fallbackPlayer ~= primaryPlayer then
        if sendCentralBatteryPayoutToClient(fallbackPlayer, mode, fullType, uses) then
            sentAny = true
        end
    end
    return sentAny
end

local function removeCentralBatteryAt(x, y, z, player, batteryIndex, fallbackPlayer)
    local store = getStore()
    local key = getNodeKey(x, y, z)
    local node = store.nodes[key]
    if not node then return false end
    if node.active == true then
        print("[BunkersAnywhere] RemoveCentralBattery rejected: central is ON at " .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z))
        return false
    end

    node.installedBatteries = node.installedBatteries or {}
    if #node.installedBatteries <= 0 then return false end

    local idx = math.floor(tonumber(batteryIndex) or -1)
    if idx < 1 or idx > #node.installedBatteries then
        idx = #node.installedBatteries
    end

    local entry = table.remove(node.installedBatteries, idx)
    if not entry then return false end

    local fullType = tostring(entry.fullType or "Base.CarBattery")
    local uses = clampBatteryUses(entry.uses)
    local username = (player and player.getUsername and player:getUsername()) or "unknown"

    if uses >= CFG.BatteryMaxUses then
        local sent = sendCentralBatteryPayoutToTargets(player, fallbackPlayer, "scrap", CFG.BatteryScrapRewardType, uses)
        local gaveScrap = false
        if not sent then
            gaveScrap = giveBatteryScrapReward(player)
        end
        print("[BunkersAnywhere] RemoveCentralBattery scrapped: " .. tostring(fullType) .. " uses=" .. tostring(uses) .. " user=" .. tostring(username) .. " sent=" .. tostring(sent) .. " fallbackScrap=" .. tostring(gaveScrap))
    else
        local sent = sendCentralBatteryPayoutToTargets(player, fallbackPlayer, "battery", fullType, uses)
        local fallbackAdded = false
        if not sent then
            local inv = player and player:getInventory() or nil
            local item = inv and inv:AddItem(fullType) or nil
            if item then
                applyBatteryMetadata(item, uses)
                fallbackAdded = true
            end
        end
        print("[BunkersAnywhere] RemoveCentralBattery returned: " .. tostring(fullType) .. " uses=" .. tostring(uses) .. " user=" .. tostring(username) .. " sent=" .. tostring(sent) .. " fallbackAdded=" .. tostring(fallbackAdded))
    end

    transmitStore()
    applyNetworkPower(store)
    return true
end

local function computeSourceRuntimeLoadPerMinute(store, effective, providers)
    local sourceLoads = {}
    for key, node in pairs(store.nodes) do
        if node and node.source ~= false then
            sourceLoads[key] = 0
        end
    end

    for key, isOn in pairs(effective or {}) do
        if isOn == true then
            local currentNode = store.nodes[key]
            local nodeWeight = 0
            if currentNode and currentNode.source ~= false then
                -- Base drain of the provider network.
                nodeWeight = 1.0
            else
                -- Secondary centrals increase drain, but softer than 1:1.
                nodeWeight = 0.25
            end
            if nodeWeight <= 0 then
                nodeWeight = 0.25
            end

            local pList = providers and providers[key] or nil
            local validProviderKeys = {}
            local seen = {}
            if pList then
                for _, p in ipairs(pList) do
                    local pKey = p and p.key or nil
                    local src = pKey and store.nodes[pKey] or nil
                    if pKey and not seen[pKey] and src and src.source ~= false and src.active == true and getNodeEnergyPercent(src) > 0 and clampRuntimeMinutes(src.runtimeMinutes) > 0 then
                        seen[pKey] = true
                        table.insert(validProviderKeys, pKey)
                    end
                end
            end

            local providerCount = #validProviderKeys
            if providerCount > 0 then
                local share = nodeWeight / providerCount
                for _, pKey in ipairs(validProviderKeys) do
                    sourceLoads[pKey] = (sourceLoads[pKey] or 0) + share
                end
            end
        end
    end

    return sourceLoads
end

local function consumeCentralRuntimePerMinute(store)
    local runtimeChanged = false
    local powerStateChanged = false
    local effective, providers = getNetworkState(store)
    local sourceLoads = computeSourceRuntimeLoadPerMinute(store, effective, providers)
    local maxRuntimeAtFull = getRuntimeMinutesFromEnergyPercent(CFG.CentralEnergyMax)

    for key, load in pairs(sourceLoads) do
        local node = store.nodes[key]
        if node and node.source ~= false and node.active == true then
            local energy = getNodeEnergyPercent(node)
            if energy <= 0 then
                if node.active == true then
                    node.active = false
                    powerStateChanged = true
                end
            else
                local runtime = clampRuntimeMinutes(node.runtimeMinutes)
                if runtime <= 0 then
                    node.runtimeMinutes = 0
                    node.energy = 0
                    if node.active == true then
                        node.active = false
                        powerStateChanged = true
                    end
                    runtimeChanged = true
                else
                    local remainder = tonumber(node.runtimeDrainRemainder) or 0
                    if remainder < 0 then remainder = 0 end
                    local requestedLoad = tonumber(load) or 0
                    if requestedLoad < 0 then requestedLoad = 0 end
                    local total = remainder + requestedLoad
                    local drain = math.floor(total)
                    node.runtimeDrainRemainder = total - drain
                    if drain > runtime then drain = runtime end

                    if drain > 0 then
                        runtime = runtime - drain
                        if runtime < 0 then runtime = 0 end
                        node.runtimeMinutes = runtime
                        runtimeChanged = true
                    end

                    if maxRuntimeAtFull > 0 then
                        local newEnergy = clampEnergyPercent(math.ceil((runtime / maxRuntimeAtFull) * CFG.CentralEnergyMax))
                        if runtime <= 0 then newEnergy = 0 end
                        if newEnergy ~= energy then
                            node.energy = newEnergy
                            energy = newEnergy
                            runtimeChanged = true
                        end
                    end

                    if runtime <= 0 then
                        node.energy = 0
                        if node.active == true then
                            node.active = false
                            powerStateChanged = true
                        end
                    end
                end
            end
        end
    end

    return runtimeChanged, powerStateChanged
end

local function activateMailboxAt(x, y, z)
    if not CFG.EnableShipping then return false end
    local square = getSquare(x, y, z)
    if not square then return false end
    local hasMailbox, mailboxObj = hasMailboxOnSquare(square)
    if not hasMailbox then return false end

    local centralKey = findNearestActiveCentralNodeKeyFromSquare(square)
    if not centralKey then return false end

    local store = getStore()
    local key = getNodeKey(x, y, z)
    local previous = store.mailboxes[key] or {}
    store.mailboxes[key] = {
        x = x,
        y = y,
        z = z,
        active = true,
        centralKey = centralKey,
        capacity = CFG.MailboxCapacity,
        items = previous.items or {},
    }
    if mailboxObj and mailboxObj.getModData then
        local md = mailboxObj:getModData()
        md.baShippingMailboxActive = true
        md.baShippingCentralKey = centralKey
        md.baShippingMailboxCapacity = CFG.MailboxCapacity
        md.baShippingMailboxCount = getItemsMapCount(store.mailboxes[key].items)
        if mailboxObj.transmitModData then
            mailboxObj:transmitModData()
        end
    end

    transmitStore()
    return true
end

local function depositMailboxAt(x, y, z, payload)
    if not CFG.EnableShipping then return false end
    local key = getNodeKey(x, y, z)
    local store = getStore()
    local mailbox = store.mailboxes[key]
    if not mailbox or not mailbox.active then return false end

    mailbox.capacity = mailbox.capacity or CFG.MailboxCapacity
    mailbox.items = mailbox.items or {}
    local currentCount = getItemsMapCount(mailbox.items)
    local incoming = getItemsMapCount(payload)
    if incoming <= 0 then return false end
    if currentCount + incoming > mailbox.capacity then
        return false
    end
    mergeItemsMap(mailbox.items, payload)

    local square = getSquare(x, y, z)
    local hasMailbox, mailboxObj = hasMailboxOnSquare(square)
    if hasMailbox and mailboxObj and mailboxObj.getModData then
        local md = mailboxObj:getModData()
        md.baShippingMailboxCapacity = mailbox.capacity
        md.baShippingMailboxCount = getItemsMapCount(mailbox.items)
        if mailboxObj.transmitModData then
            mailboxObj:transmitModData()
        end
    end

    transmitStore()
    return true
end

local function sendMailboxToCentral(x, y, z, tx, ty, tz)
    if not CFG.EnableShipping then return false end
    local store = getStore()
    local effective = getNetworkState(store)
    local mailKey = getNodeKey(x, y, z)
    local mailbox = store.mailboxes[mailKey]
    if not mailbox or not mailbox.active then return false end
    local sourceCentralKey = mailbox.centralKey
    local sourceCentral = sourceCentralKey and store.nodes[sourceCentralKey] or nil
    if not sourceCentral or not effective[sourceCentralKey] then return false end

    local targetCentralKey = getNodeKey(tx, ty, tz)
    local targetCentral = store.nodes[targetCentralKey]
    if not targetCentral or not effective[targetCentralKey] then return false end

    if not (sourceCentral.links and sourceCentral.links[targetCentralKey]) then
        return false
    end

    mailbox.items = mailbox.items or {}
    local hasAny = false
    for _, count in pairs(mailbox.items) do
        if (tonumber(count) or 0) > 0 then
            hasAny = true
            break
        end
    end
    if not hasAny then return false end

    store.inboxes[targetCentralKey] = store.inboxes[targetCentralKey] or {}
    mergeItemsMap(store.inboxes[targetCentralKey], mailbox.items)
    clearItemsMap(mailbox.items)

    local square = getSquare(x, y, z)
    local hasMailbox, mailboxObj = hasMailboxOnSquare(square)
    if hasMailbox and mailboxObj and mailboxObj.getModData then
        local md = mailboxObj:getModData()
        md.baShippingMailboxCount = 0
        if mailboxObj.transmitModData then
            mailboxObj:transmitModData()
        end
    end

    transmitStore()
    return true
end

local function giveItemToPlayer(player, fullType)
    if not player or not fullType then return false end
    local inv = player:getInventory()
    if not inv then return false end
    local item = inv:AddItem(fullType)
    return item ~= nil
end

local function withdrawMailboxAt(x, y, z, player)
    if not CFG.EnableShipping then return false end
    local store = getStore()
    local mailKey = getNodeKey(x, y, z)
    local mailbox = store.mailboxes[mailKey]
    if not mailbox or not mailbox.active then return false end

    local granted = false

    mailbox.items = mailbox.items or {}
    for fullType, count in pairs(mailbox.items) do
        local n = math.floor(tonumber(count) or 0)
        while n > 0 do
            if not giveItemToPlayer(player, fullType) then
                break
            end
            n = n - 1
            granted = true
        end
    end
    clearItemsMap(mailbox.items)

    local cKey = mailbox.centralKey
    if cKey then
        local inbox = store.inboxes[cKey]
        if inbox then
            for fullType, count in pairs(inbox) do
                local n = math.floor(tonumber(count) or 0)
                while n > 0 do
                    if not giveItemToPlayer(player, fullType) then
                        break
                    end
                    n = n - 1
                    granted = true
                end
            end
            clearItemsMap(inbox)
        end
    end

    local square = getSquare(x, y, z)
    local hasMailbox, mailboxObj = hasMailboxOnSquare(square)
    if hasMailbox and mailboxObj and mailboxObj.getModData then
        local md = mailboxObj:getModData()
        md.baShippingMailboxCount = getItemsMapCount(mailbox.items)
        if mailboxObj.transmitModData then
            mailboxObj:transmitModData()
        end
    end

    transmitStore()
    return granted
end

local function cleanupAndMaintain()
    local store = getStore()
    local changed = false
    local topologyChanged = false

    for key, node in pairs(store.nodes) do
        local square = node and getSquare(node.x, node.y, node.z) or nil
        local hasCentral = square and hasCentralOnSquare(square) or false
        -- In MP, detection can be transiently false due chunk/object streaming.
        -- Require several consecutive "missing" checks before deleting.
        if square then
            if not hasCentral then
                node.missingCentralMinutes = math.floor(tonumber(node.missingCentralMinutes) or 0) + 1
                if node.missingCentralMinutes >= 3 then
                    removeOwnedGenerator(square)
                    store.nodes[key] = nil
                    changed = true
                    topologyChanged = true
                end
            else
                if (tonumber(node.missingCentralMinutes) or 0) ~= 0 then
                    node.missingCentralMinutes = 0
                end
                if node and node.source ~= false then
                    local oldRuntime = clampRuntimeMinutes(node.runtimeMinutes)
                    local newRuntime = oldRuntime
                    if getNodeEnergyPercent(node) > 0 and newRuntime <= 0 then
                        newRuntime = getRuntimeMinutesFromEnergyPercent(node.energy)
                    end
                    if newRuntime ~= oldRuntime then
                        node.runtimeMinutes = newRuntime
                        changed = true
                    end
                end
            end
        end
    end

    for _, node in pairs(store.nodes) do
        node.links = node.links or {}
        for linkedKey, enabled in pairs(node.links) do
            if enabled and not store.nodes[linkedKey] then
                node.links[linkedKey] = nil
                changed = true
                topologyChanged = true
            end
        end
    end

    local runtimeChanged, powerStateChanged = consumeCentralRuntimePerMinute(store)
    if runtimeChanged then
        changed = true
    end

    local effective, providers
    if topologyChanged or powerStateChanged then
        effective, providers = applyNetworkPower(store)
    else
        effective, providers = getNetworkState(store)
        if runtimeChanged then
            -- Runtime drain alone does not require re-scanning the full power
            -- radius every minute. That work is expensive in SP and can stall
            -- the game for large central ranges. Keep UI/modData synchronized
            -- here; actual power-area refresh still happens when state/topology
            -- changes and around loaded players via OnTick maintenance.
            syncCentralModDataFromState(store, effective, providers)
        end
    end

    if CFG.EnableShipping then
        for key, mailbox in pairs(store.mailboxes) do
            local square = mailbox and getSquare(mailbox.x, mailbox.y, mailbox.z) or nil
            local hasMailbox, mailboxObj = square and hasMailboxOnSquare(square) or false, nil
            if square then
                hasMailbox, mailboxObj = hasMailboxOnSquare(square)
            end

            if not hasMailbox then
                store.mailboxes[key] = nil
                changed = true
            else
                local centralExists = mailbox.centralKey and store.nodes[mailbox.centralKey] and effective[mailbox.centralKey]
                local previousActive = mailbox.active == true
                mailbox.active = centralExists and true or false
                if previousActive ~= (mailbox.active == true) then
                    changed = true
                end

                if mailboxObj and mailboxObj.getModData then
                    local md = mailboxObj:getModData()
                    md.baShippingMailboxActive = mailbox.active
                    md.baShippingCentralKey = mailbox.centralKey
                    md.baShippingMailboxCapacity = mailbox.capacity or CFG.MailboxCapacity
                    md.baShippingMailboxCount = getItemsMapCount(mailbox.items)
                    if mailboxObj.transmitModData then
                        mailboxObj:transmitModData()
                    end
                end
            end
        end
    end

    if changed then
        transmitStore()
    end
end

local function onClientCommand(module, command, player, args)
    if module ~= "BunkersAnywhere" then return end
    if not args then return end
    local actor = resolveCommandPlayer(player, args)

    if command == "ConnectInvisibleGeneratorCentral" then
        connectNodeAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), actor)
    elseif command == "RegisterInvisibleGeneratorCentral" then
        registerNodeAt(tonumber(args.x), tonumber(args.y), tonumber(args.z))
    elseif command == "ToggleInvisibleGeneratorCentral" then
        setNodeStateAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), args.on == true)
    elseif command == "InsertCentralBattery" then
        insertCentralBatteryAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), actor, tostring(args.fullType or ""), args)
    elseif command == "RemoveCentralBattery" then
        removeCentralBatteryAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), actor, tonumber(args.batteryIndex), player)
    elseif command == "DebugCentralBatteryInventory" then
        debugDumpPlayerBatteryInventory(actor, tostring(args.reason or "OnClientCommand"))
    elseif command == "LinkInvisibleGeneratorCentrals" then
        linkNodes(tonumber(args.ax), tonumber(args.ay), tonumber(args.az), tonumber(args.bx), tonumber(args.by), tonumber(args.bz), actor)
    elseif command == "UpgradeCentralRadius" then
        if CFG.EnableCentralRadiusUpgrade == true then
            upgradeCentralRadiusAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), actor, args)
        end
    elseif command == "ActivateShippingMailbox" and CFG.EnableShipping then
        activateMailboxAt(tonumber(args.x), tonumber(args.y), tonumber(args.z))
    elseif command == "DepositShippingMailbox" and CFG.EnableShipping then
        depositMailboxAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), args.items or {})
    elseif command == "SendShippingMailboxToCentral" and CFG.EnableShipping then
        sendMailboxToCentral(tonumber(args.x), tonumber(args.y), tonumber(args.z), tonumber(args.tx), tonumber(args.ty), tonumber(args.tz))
    elseif command == "WithdrawShippingMailbox" and CFG.EnableShipping then
        withdrawMailboxAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), actor)
    end
end

Events.OnClientCommand.Add(onClientCommand)
Events.EveryOneMinute.Add(cleanupAndMaintain)
-- Disabled to avoid rapid ON/OFF oscillation in MP.
-- Events.OnTick.Add(maintainPowerSafety)
Events.OnTick.Add(maintainLoadedBasementPowerAroundPlayers)
