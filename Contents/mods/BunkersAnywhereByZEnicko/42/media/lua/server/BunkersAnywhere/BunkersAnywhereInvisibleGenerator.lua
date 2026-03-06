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

local function removeOwnedGenerator(square)
    if not square then return end
    local generator = square:getGenerator()
    if not generator or not generator.getModData then return end
    local gmd = generator:getModData()
    if gmd and gmd.baInvisibleGeneratorOwned then
        generator:setActivated(false)
        if generator.sync then generator:sync() end
        if square.transmitRemoveItemFromSquare then
            square:transmitRemoveItemFromSquare(generator)
        else
            generator:remove()
        end
    end
end

local function ensureInvisibleGenerator(square, wantOn)
    if not square then return end

    local generator = square:getGenerator()
    if generator and generator.getModData then
        local gmd = generator:getModData()
        if not gmd.baInvisibleGeneratorOwned then
            return
        end
    end

    if not generator then
        local item = instanceItem("Base.Generator")
        if not item then return end
        item:setCondition(100)
        item:getModData().fuel = 100
        generator = IsoGenerator.new(item, getCell(), square)
    end
    if not generator then return end

    local gmd = generator:getModData()
    gmd.baInvisibleGeneratorOwned = true
    generator:setCondition(100)
    generator:setFuel(100)
    generator:setConnected(true)
    generator:setActivated(wantOn == true)
    if wantOn then
        generator:setSurroundingElectricity()
    end

    pcall(function() generator:setAlpha(0.0) end)
    pcall(function() generator:setTargetAlpha(0, 0.0) end)
    pcall(function() generator:setTargetAlpha(1, 0.0) end)
    if generator.setSprite then
        generator:setSprite(nil)
    end
    if generator.sync then
        generator:sync()
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

local function updateCentralModData(square, on, localOn, providerText, providerCount)
    local hasCentral, centralObj = hasCentralOnSquare(square)
    if hasCentral and centralObj and centralObj.getModData then
        local md = centralObj:getModData()
        md.baInvisibleGeneratorConnected = true
        md.baInvisibleGeneratorOn = on == true
        md.baInvisibleGeneratorLocalOn = localOn == true
        md.baInvisibleGeneratorProviderText = providerText or ""
        md.baInvisibleGeneratorProviderCount = tonumber(providerCount) or 0
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

            while #stack > 0 do
                local key = table.remove(stack)
                local node = store.nodes[key]
                if not visited[key] and node and node.active then
                    visited[key] = true
                    table.insert(component, key)
                    table.insert(activeProviders, {
                        x = node.x,
                        y = node.y,
                        z = node.z,
                        key = key,
                    })

                    local links = node.links or {}
                    for linkedKey, enabled in pairs(links) do
                        local linkedNode = store.nodes[linkedKey]
                        if enabled and linkedNode and linkedNode.active and not visited[linkedKey] then
                            table.insert(stack, linkedKey)
                        end
                    end
                end
            end

            for _, key in ipairs(component) do
                effective[key] = true
                providers[key] = activeProviders
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
        local wantOn = effective[key] == true
        local providerText = ""
        local providerCount = 0
        local pList = providers[key]
        if pList then
            providerCount = #pList
            local parts = {}
            for _, p in ipairs(pList) do
                table.insert(parts, tostring(p.x) .. "," .. tostring(p.y) .. "," .. tostring(p.z))
            end
            providerText = table.concat(parts, " | ")
        end
        if square then
            updateCentralModData(square, wantOn, localOn, providerText, providerCount)
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

local function connectNodeAt(x, y, z)
    local square = getSquare(x, y, z)
    if not square then return false end
    if z ~= CFG.ZLevel then return false end
    local hasCentral = hasCentralOnSquare(square)
    if not hasCentral then return false end

    local store = getStore()
    local key = getNodeKey(x, y, z)
    local previous = store.nodes[key] or {}
    store.nodes[key] = {
        x = x,
        y = y,
        z = z,
        active = true,
        links = previous.links or {},
    }

    transmitStore()
    applyNetworkPower(store)
    return true
end

local function linkNodes(ax, ay, az, bx, by, bz)
    local store = getStore()
    local keyA = getNodeKey(ax, ay, az)
    local keyB = getNodeKey(bx, by, bz)
    local a = store.nodes[keyA]
    local b = store.nodes[keyB]

    -- Bypass: if a central tile exists but its node was not created yet,
    -- create/connect it on-demand before linking.
    if not a then
        connectNodeAt(ax, ay, az)
        store = getStore()
        a = store.nodes[keyA]
    end
    if not b then
        connectNodeAt(bx, by, bz)
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
    node.active = wantOn == true
    transmitStore()

    applyNetworkPower(store)
    return true
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

    if command == "ConnectInvisibleGeneratorCentral" then
        connectNodeAt(tonumber(args.x), tonumber(args.y), tonumber(args.z))
    elseif command == "ToggleInvisibleGeneratorCentral" then
        setNodeStateAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), args.on == true)
    elseif command == "LinkInvisibleGeneratorCentrals" then
        linkNodes(tonumber(args.ax), tonumber(args.ay), tonumber(args.az), tonumber(args.bx), tonumber(args.by), tonumber(args.bz))
    elseif command == "ActivateShippingMailbox" and CFG.EnableShipping then
        activateMailboxAt(tonumber(args.x), tonumber(args.y), tonumber(args.z))
    elseif command == "DepositShippingMailbox" and CFG.EnableShipping then
        depositMailboxAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), args.items or {})
    elseif command == "SendShippingMailboxToCentral" and CFG.EnableShipping then
        sendMailboxToCentral(tonumber(args.x), tonumber(args.y), tonumber(args.z), tonumber(args.tx), tonumber(args.ty), tonumber(args.tz))
    elseif command == "WithdrawShippingMailbox" and CFG.EnableShipping then
        withdrawMailboxAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), player)
    end
end

Events.OnClientCommand.Add(onClientCommand)
Events.EveryOneMinute.Add(cleanupAndMaintain)
