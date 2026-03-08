BunkersAnywhere = BunkersAnywhere or {}

local CFG = {
    DataKey = "BunkersAnywhereInvisibleCentralGenerators",
    SpriteName = "location_business_bank_01_67",
    SpriteNameAlt = "location_business_bank_01_66",
    ZLevel = -1,
    GeneratorRadius = 20,
    GeneratorVertical = 3,
    EnableShipping = false,
    MailboxSpriteName = "rooftop_furniture_3",
    MaxMailboxCentralDistance = 20,
    MailboxCapacity = 100,
    CentralEnergyMax = 100,
    CentralDrainPerMinute = 1,
    BatteryChargeByType = {
        ["Base.CarBattery"] = 40,
        ["Base.CarBattery1"] = 40,
        ["Base.CarBattery2"] = 60,
        ["Base.CarBattery3"] = 80,
    },
    MinElectricityToConnect = 3,
}

local function isCentralSpriteName(spriteName)
    if not spriteName then return false end
    if spriteName == CFG.SpriteName then return true end
    if spriteName == CFG.SpriteNameAlt then return true end
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
    if shortType == "CarBattery" then return 40 end
    if shortType == "CarBattery1" then return 40 end
    if shortType == "CarBattery2" then return 60 end
    if shortType == "CarBattery3" then return 80 end
    return 0
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

local function getNodeEnergyPercent(node)
    return clampEnergyPercent(node and node.energy or 0)
end

local function sourceNodeHasUsableEnergy(node)
    return node and node.source ~= false and node.active == true and getNodeEnergyPercent(node) > 0
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
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if obj and obj.getSprite then
            local sprite = obj:getSprite()
            local spriteName = sprite and sprite.getName and sprite:getName() or nil
            if isCentralSpriteName(spriteName) then
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
        generator:setActivated(false)
        if generator.sync then generator:sync() end
        if targetSquare and targetSquare.transmitRemoveItemFromSquare then
            targetSquare:transmitRemoveItemFromSquare(generator)
        else
            generator:remove()
        end
    end
end

local function isGeneratorActivated(generator)
    if not generator then return false end
    local ok, value = pcall(function()
        if generator.isActivated then
            return generator:isActivated()
        end
        if generator.getActivated then
            return generator:getActivated()
        end
        return false
    end)
    if not ok then return false end
    return value == true
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

    if created then
        generator:setCondition(100)
        generator:setFuel(100)
        generator:setConnected(true)
        changed = true
    end

    local shouldBeOn = wantOn == true
    local lastAppliedOn = (gmd.baInvisibleGeneratorLastAppliedOn == true)
    if gmd.baInvisibleGeneratorLastAppliedOn == nil then
        lastAppliedOn = isGeneratorActivated(generator)
    end

    if created or lastAppliedOn ~= shouldBeOn then
        generator:setActivated(shouldBeOn)
        if shouldBeOn then
            generator:setSurroundingElectricity()
        end
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
            generator:sync()
        end
    end
end

local function setSquarePower(square, on)
    if not square then return end
    if square.setHaveElectricity then
        square:setHaveElectricity(on == true)
    end
    if square.setHasGridPower then
        square:setHasGridPower(on == true)
    end
    if square.RecalcProperties then
        square:RecalcProperties()
    end
end

local function clampGeneratorPowerToBasement(node)
    local cell = getCell()
    local r = CFG.GeneratorRadius
    for ix = node.x - r, node.x + r do
        for iy = node.y - r, node.y + r do
            for iz = node.z - CFG.GeneratorVertical, node.z + CFG.GeneratorVertical do
                if iz ~= CFG.ZLevel then
                    local sq = cell:getGridSquare(ix, iy, iz)
                    if sq then
                        setSquarePower(sq, false)
                    end
                end
            end
        end
    end
end

local function forceNoToxic(square)
    if not square then return end
    local building = square:getBuilding()
    if building and building.setToxic then
        building:setToxic(false)
    end
end

local function updateCentralModData(square, on, localOn, providerText, providerCount, isSource, energyPercent)
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

local function applyNetworkPower(store)
    local effective, providers = getNetworkState(store)
    for key, node in pairs(store.nodes) do
        local square = getSquare(node.x, node.y, node.z)
        local localOn = node.active == true
        local energyPercent = getNodeEnergyPercent(node)
        local wantOn = effective[key] == true
        local isSource = node.source ~= false
        local providerText = ""
        local providerCount = 0
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
        if square then
            updateCentralModData(square, wantOn, localOn, providerText, providerCount, isSource, energyPercent)
            ensureInvisibleGenerator(square, wantOn)
            forceNoToxic(square)
            clampGeneratorPowerToBasement(node)
        end
    end
    return effective, providers
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
    if z ~= CFG.ZLevel then return false end
    local hasCentral = hasCentralOnSquare(square)
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
    }
    if asSource == true then
        node.source = true
    elseif not existed and node.source == nil then
        node.source = false
    end
    node.energy = clampEnergyPercent(node.energy)
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
        store.nodes[key].active = true
        if getNodeEnergyPercent(store.nodes[key]) <= 0 then
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
    if wantOn == true and node.source ~= false and getNodeEnergyPercent(node) <= 0 then
        return false
    end
    node.active = wantOn == true
    transmitStore()

    applyNetworkPower(store)
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

    local okRemove, resolvedFullType, charge = false, nil, 0
    local clientConsumed = args and args.clientConsumed == true
    local clientCharge = args and math.floor(tonumber(args.charge) or 0) or 0

    if clientConsumed and clientCharge > 0 then
        okRemove = true
        resolvedFullType = tostring(fullType or "")
        charge = clientCharge
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
    print("[BunkersAnywhere] InsertCentralBattery applied: " .. tostring(resolvedFullType) .. " +" .. tostring(charge) .. "% (" .. tostring(current) .. "% -> " .. tostring(node.energy) .. "%)")
    transmitStore()
    applyNetworkPower(store)
    return true
end

local function consumeCentralEnergyPerMinute(store)
    local changed = false
    local drain = math.max(0, math.floor(tonumber(CFG.CentralDrainPerMinute) or 0))
    if drain <= 0 then return false end

    for _, node in pairs(store.nodes) do
        if node and node.source ~= false and node.active == true then
            local oldEnergy = getNodeEnergyPercent(node)
            if oldEnergy > 0 then
                local newEnergy = oldEnergy - drain
                if newEnergy < 0 then newEnergy = 0 end
                node.energy = newEnergy
                if newEnergy <= 0 then
                    node.active = false
                end
                if newEnergy ~= oldEnergy then
                    changed = true
                end
            else
                node.active = false
                changed = true
            end
        end
    end

    return changed
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

    for key, node in pairs(store.nodes) do
        local square = node and getSquare(node.x, node.y, node.z) or nil
        local hasCentral = square and hasCentralOnSquare(square) or false
        if not hasCentral then
            removeOwnedGenerator(square)
            store.nodes[key] = nil
            changed = true
        end
    end

    for _, node in pairs(store.nodes) do
        node.links = node.links or {}
        for linkedKey, enabled in pairs(node.links) do
            if enabled and not store.nodes[linkedKey] then
                node.links[linkedKey] = nil
                changed = true
            end
        end
    end

    if consumeCentralEnergyPerMinute(store) then
        changed = true
    end

    local effective, _ = applyNetworkPower(store)

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
                mailbox.active = centralExists and true or false

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
    elseif command == "DebugCentralBatteryInventory" then
        debugDumpPlayerBatteryInventory(actor, tostring(args.reason or "OnClientCommand"))
    elseif command == "LinkInvisibleGeneratorCentrals" then
        linkNodes(tonumber(args.ax), tonumber(args.ay), tonumber(args.az), tonumber(args.bx), tonumber(args.by), tonumber(args.bz), actor)
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
