BunkersAnywhere = BunkersAnywhere or {}
require "ISUI/ISInventoryPaneContextMenu"

BunkersAnywhere.InvisibleCentralGenerator = {
    DataKey = "BunkersAnywhereInvisibleCentralGenerators",
    SpriteName = "location_business_bank_01_67",
    SpriteNameAlt = "location_business_bank_01_66",
    ZLevel = -1,
}

BunkersAnywhere.ShippingMailbox = {
    SpriteName = "rooftop_furniture_3",
    MaxCentralDistance = 20,
    Enabled = false,
}

function BunkersAnywhere.isInvisibleCentralSpriteName(spriteName)
    if not spriteName then return false end
    if spriteName == BunkersAnywhere.InvisibleCentralGenerator.SpriteName then return true end
    if spriteName == BunkersAnywhere.InvisibleCentralGenerator.SpriteNameAlt then return true end
    return false
end

function BunkersAnywhere.isInvisibleCentralTile(obj)
    if not obj or not obj.getSprite then return false end
    local sprite = obj:getSprite()
    if not sprite or not sprite.getName then return false end
    return BunkersAnywhere.isInvisibleCentralSpriteName(sprite:getName())
end

function BunkersAnywhere.getInvisibleGeneratorStore()
    if isClient() and ModData and ModData.request then
        local shouldRequest = false
        if getTimestampMs then
            local now = getTimestampMs()
            local last = BunkersAnywhere._lastInvisibleGeneratorStoreRequestMs or 0
            if now - last > 5000 then
                BunkersAnywhere._lastInvisibleGeneratorStoreRequestMs = now
                shouldRequest = true
            end
        elseif not BunkersAnywhere._requestedInvisibleGeneratorStore then
            BunkersAnywhere._requestedInvisibleGeneratorStore = true
            shouldRequest = true
        end

        if shouldRequest then
            ModData.request(BunkersAnywhere.InvisibleCentralGenerator.DataKey)
        end
    end
    local data = ModData.getOrCreate(BunkersAnywhere.InvisibleCentralGenerator.DataKey)
    data.nodes = data.nodes or {}
    return data
end

function BunkersAnywhere.getInvisibleGeneratorNode(store, key)
    if not store or not store.nodes then return nil end
    return store.nodes[key]
end

function BunkersAnywhere.linkInvisibleGeneratorNodes(store, keyA, keyB)
    local a = BunkersAnywhere.getInvisibleGeneratorNode(store, keyA)
    local b = BunkersAnywhere.getInvisibleGeneratorNode(store, keyB)
    if not a or not b then return false end
    a.links = a.links or {}
    b.links = b.links or {}
    a.links[keyB] = true
    b.links[keyA] = true
    return true
end

function BunkersAnywhere.getInvisibleGeneratorNodeKey(x, y, z)
    return tostring(math.floor(x)) .. ":" .. tostring(math.floor(y)) .. ":" .. tostring(math.floor(z))
end

function BunkersAnywhere.isInvisibleGeneratorConnected(obj)
    if not obj or not obj.getModData then return false end
    local md = obj:getModData()
    return md and md.baInvisibleGeneratorConnected == true
end

function BunkersAnywhere.isOwnedInvisibleGenerator(obj)
    if not obj then return false end
    if not obj.getModData then return false end
    local md = obj:getModData()
    return md and md.baInvisibleGeneratorOwned == true
end

function BunkersAnywhere.forceHideGeneratorVisual(obj)
    if not obj then return false end
    -- MP clients may re-render replicated generators with default sprite.
    -- Force-hide repeatedly on client to keep it fully invisible.
    if obj.setAlpha then
        pcall(function() obj:setAlpha(0.0) end)
    end
    if obj.setSprite then
        pcall(function() obj:setSprite(nil) end)
    end
    return true
end

function BunkersAnywhere.hideOwnedInvisibleGenerator(obj)
    if not BunkersAnywhere.isOwnedInvisibleGenerator(obj) then return false end
    return BunkersAnywhere.forceHideGeneratorVisual(obj)
end

function BunkersAnywhere.hideGeneratorNearCentralNode(node)
    if not node then return false end
    local cell = getCell()
    if not cell then return false end
    local hiddenAny = false

    -- In MP the generator can be placed/rendered in an adjacent tile
    -- depending on engine placement constraints and replication.
    for dx = -1, 1 do
        for dy = -1, 1 do
            local sq = cell:getGridSquare(node.x + dx, node.y + dy, node.z)
            if sq then
                local g = sq:getGenerator()
                if g then
                    local hiddenOwned = BunkersAnywhere.hideOwnedInvisibleGenerator(g)
                    if hiddenOwned then
                        hiddenAny = true
                    else
                        local gmd = (g.getModData and g:getModData()) or nil
                        local hasOwnedFlag = gmd and (gmd.baInvisibleGeneratorOwned ~= nil)
                        local fuel = (g.getFuel and g:getFuel()) or 0
                        local cond = (g.getCondition and g:getCondition()) or 0
                        local closeToCentral = (math.abs(dx) + math.abs(dy)) <= 1

                        -- Fallback for MP desync cases where modData ownership
                        -- isn't replicated to this client but object is ours.
                        if (not hasOwnedFlag) and closeToCentral and fuel >= 99 and cond >= 99 then
                            if BunkersAnywhere.forceHideGeneratorVisual(g) then
                                hiddenAny = true
                            end
                        end
                    end
                end
            end
        end
    end

    return hiddenAny
end

function BunkersAnywhere.refreshOwnedInvisibleGenerators()
    local cell = getCell()
    if not cell then return end

    local basementZ = BunkersAnywhere.InvisibleCentralGenerator.ZLevel
    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    if not store or not store.nodes then return end

    for _, node in pairs(store.nodes) do
        if node and node.z == basementZ then
            BunkersAnywhere.hideGeneratorNearCentralNode(node)
        end
    end
end

function BunkersAnywhere.getWireDistanceCost(fromSq, toX, toY)
    local dx = fromSq:getX() - toX
    local dy = fromSq:getY() - toY
    return math.max(1, math.ceil(math.sqrt(dx * dx + dy * dy)))
end

function BunkersAnywhere.getNearbyContainers(playerObj)
    local res = {}
    if not ISInventoryPaneContextMenu or not ISInventoryPaneContextMenu.getContainers then
        return res
    end
    local playerInv = playerObj:getInventory()
    local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
    if containers and containers.size and containers.get then
        for i = 0, containers:size() - 1 do
            local c = containers:get(i)
            if c and c ~= playerInv then
                table.insert(res, c)
            end
        end
    elseif containers then
        local seen = {}
        local i = 1
        while containers[i] do
            local c = containers[i]
            if c and c ~= playerInv and not seen[c] then
                seen[c] = true
                table.insert(res, c)
            end
            i = i + 1
        end
        for _, c in pairs(containers) do
            if c and c ~= playerInv and not seen[c] then
                seen[c] = true
                table.insert(res, c)
            end
        end
    end
    return res
end

function BunkersAnywhere.countElectricWireAvailable(playerObj)
    local total = playerObj:getInventory():getItemCountRecurse("ElectricWire")
    local nearby = BunkersAnywhere.getNearbyContainers(playerObj)
    for _, c in ipairs(nearby) do
        local items = c:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and item:getType() == "ElectricWire" then
                total = total + 1
            end
        end
    end
    return total
end

function BunkersAnywhere.consumeElectricWire(playerObj, amount)
    local remaining = amount
    local inv = playerObj:getInventory()

    while remaining > 0 and inv:containsTypeRecurse("ElectricWire") do
        inv:RemoveOneOf("Base.ElectricWire")
        remaining = remaining - 1
    end

    if remaining <= 0 then return true end

    local nearby = BunkersAnywhere.getNearbyContainers(playerObj)
    for _, c in ipairs(nearby) do
        local items = c:getItems()
        for i = items:size() - 1, 0, -1 do
            local item = items:get(i)
            if item and item:getType() == "ElectricWire" then
                if c.DoRemoveItem then
                    c:DoRemoveItem(item)
                else
                    c:Remove(item)
                end
                remaining = remaining - 1
                if remaining <= 0 then
                    return true
                end
            end
        end
    end

    return remaining <= 0
end

function BunkersAnywhere.connectInvisibleGeneratorCentral(centralObj, playerObj)
    local sq = centralObj and centralObj:getSquare()
    if not sq then return end
    if sq:getZ() ~= BunkersAnywhere.InvisibleCentralGenerator.ZLevel then
        playerObj:setHaloNote(getText("IGUI_Bunker_CentralGeneratorOnlyBasement"), 255, 120, 0, 350)
        return
    end

    if BunkersAnywhere.isInvisibleGeneratorConnected(centralObj) then
        playerObj:setHaloNote(getText("IGUI_Bunker_CentralGeneratorAlreadyConnected"), 240, 240, 0, 300)
        return
    end

    local md = centralObj:getModData()
    md.baInvisibleGeneratorConnected = true
    md.baInvisibleGeneratorIsSource = true
    md.baInvisibleGeneratorOn = true
    if centralObj.transmitModData then
        centralObj:transmitModData()
    end

    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    store.nodes[key] = store.nodes[key] or { x = sq:getX(), y = sq:getY(), z = sq:getZ(), active = true, source = true, links = {} }
    store.nodes[key].active = true
    store.nodes[key].source = true
    if ModData.transmit then
        ModData.transmit(BunkersAnywhere.InvisibleCentralGenerator.DataKey)
    end

    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "ConnectInvisibleGeneratorCentral", {
            x = sq:getX(),
            y = sq:getY(),
            z = sq:getZ(),
        })
    end

    playerObj:setHaloNote(getText("IGUI_Bunker_CentralGeneratorConnected"), 0, 255, 100, 350)
end

function BunkersAnywhere.registerInvisibleGeneratorCentralCandidate(centralObj)
    local sq = centralObj and centralObj:getSquare()
    if not sq then return end
    if sq:getZ() ~= BunkersAnywhere.InvisibleCentralGenerator.ZLevel then return end
    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    if not (store.nodes and store.nodes[key]) then
        store.nodes[key] = { x = sq:getX(), y = sq:getY(), z = sq:getZ(), active = true, source = false, links = {} }
        if ModData.transmit then
            ModData.transmit(BunkersAnywhere.InvisibleCentralGenerator.DataKey)
        end
    end
    if not sendClientCommand then return end

    sendClientCommand("BunkersAnywhere", "RegisterInvisibleGeneratorCentral", {
        x = sq:getX(),
        y = sq:getY(),
        z = sq:getZ(),
    })
end

function BunkersAnywhere.connectInvisibleGeneratorToOtherCentral(centralObj, playerObj, targetX, targetY, targetZ)
    local sq = centralObj and centralObj:getSquare()
    if not sq then return end
    if targetZ ~= BunkersAnywhere.InvisibleCentralGenerator.ZLevel then return end

    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local keyA = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    local keyB = BunkersAnywhere.getInvisibleGeneratorNodeKey(targetX, targetY, targetZ)
    local nodeA = store.nodes and store.nodes[keyA] or nil
    if nodeA and nodeA.links and nodeA.links[keyB] == true then
        playerObj:setHaloNote(getText("IGUI_Bunker_CentralAlreadyLinked"), 240, 220, 80, 350)
        return
    end

    local need = BunkersAnywhere.getWireDistanceCost(sq, targetX, targetY)
    local available = BunkersAnywhere.countElectricWireAvailable(playerObj)
    if available < need then
        playerObj:setHaloNote(getText("IGUI_Bunker_CentralNeedWire", tostring(need), tostring(available)), 255, 80, 80, 400)
        return
    end

    if not BunkersAnywhere.consumeElectricWire(playerObj, need) then
        playerObj:setHaloNote(getText("IGUI_Bunker_CentralNeedWire", tostring(need), tostring(available)), 255, 80, 80, 400)
        return
    end

    BunkersAnywhere.linkInvisibleGeneratorNodes(store, keyA, keyB)
    if ModData.transmit then
        ModData.transmit(BunkersAnywhere.InvisibleCentralGenerator.DataKey)
    end
    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "LinkInvisibleGeneratorCentrals", {
            ax = sq:getX(), ay = sq:getY(), az = sq:getZ(),
            bx = targetX, by = targetY, bz = targetZ,
        })
    end

    playerObj:setHaloNote(getText("IGUI_Bunker_CentralLinkedTo", tostring(targetX), tostring(targetY), tostring(targetZ)), 0, 220, 255, 400)
end

function BunkersAnywhere.isShippingMailboxTile(obj)
    if not BunkersAnywhere.ShippingMailbox.Enabled then return false end
    if not obj or not obj.getSprite then return false end
    local sprite = obj:getSprite()
    if not sprite or not sprite.getName then return false end
    local name = sprite:getName()
    if name == BunkersAnywhere.ShippingMailbox.SpriteName then return true end
    return string.match(name or "", "^rooftop_furniture_.*_3$") ~= nil
end

function BunkersAnywhere.findNearestActiveCentralNodeKeyFromSquare(sq)
    if not sq then return nil end
    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local bestKey, bestDist = nil, 999999
    for key, node in pairs(store.nodes) do
        if node and node.active and node.z == sq:getZ() then
            local dx = node.x - sq:getX()
            local dy = node.y - sq:getY()
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist <= BunkersAnywhere.ShippingMailbox.MaxCentralDistance and dist < bestDist then
                bestKey = key
                bestDist = dist
            end
        end
    end
    return bestKey
end

function BunkersAnywhere.findNearbyActiveMailbox(playerObj, radius)
    local sq = playerObj and playerObj:getSquare()
    if not sq then return nil end
    local cell = getCell()
    local px, py, pz = sq:getX(), sq:getY(), sq:getZ()
    local r = radius or 1
    for x = px - r, px + r do
        for y = py - r, py + r do
            local s = cell:getGridSquare(x, y, pz)
            if s then
                local objs = s:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if BunkersAnywhere.isShippingMailboxTile(o) and o.getModData then
                        local md = o:getModData()
                        if md and md.baShippingMailboxActive then
                            return o
                        end
                    end
                end
            end
        end
    end
    return nil
end

function BunkersAnywhere.activateShippingMailbox(mailObj, playerObj)
    local sq = mailObj and mailObj:getSquare()
    if not sq then return end
    local centralKey = BunkersAnywhere.findNearestActiveCentralNodeKeyFromSquare(sq)
    if not centralKey then
        playerObj:setHaloNote(getText("IGUI_Bunker_MailNoCentralNearby"), 255, 80, 80, 400)
        return
    end
    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "ActivateShippingMailbox", { x = sq:getX(), y = sq:getY(), z = sq:getZ() })
    end
    playerObj:setHaloNote(getText("IGUI_Bunker_MailActivated"), 0, 255, 100, 350)
end

function BunkersAnywhere.sendShippingMailbox(mailObj, playerObj, targetX, targetY, targetZ)
    local sq = mailObj and mailObj:getSquare()
    if not sq then return end
    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "SendShippingMailboxToCentral", {
            x = sq:getX(), y = sq:getY(), z = sq:getZ(),
            tx = targetX, ty = targetY, tz = targetZ,
        })
    end
    playerObj:setHaloNote(getText("IGUI_Bunker_MailSentTo", tostring(targetX), tostring(targetY), tostring(targetZ)), 80, 220, 255, 350)
end

function BunkersAnywhere.withdrawShippingMailbox(mailObj, playerObj)
    local sq = mailObj and mailObj:getSquare()
    if not sq then return end
    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "WithdrawShippingMailbox", { x = sq:getX(), y = sq:getY(), z = sq:getZ() })
    end
end

function BunkersAnywhere.setInvisibleGeneratorCentralState(centralObj, playerObj, wantOn)
    local sq = centralObj and centralObj:getSquare()
    if not sq then return end
    if sq:getZ() ~= BunkersAnywhere.InvisibleCentralGenerator.ZLevel then return end

    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    local node = store.nodes and store.nodes[key] or nil
    local md = centralObj:getModData()
    local isConnected = (node ~= nil) or (md and md.baInvisibleGeneratorConnected == true)
    if not isConnected then
        playerObj:setHaloNote(getText("IGUI_Bunker_CentralNeedLinkFirst"), 255, 120, 0, 350)
        return
    end
    local current = (node and node.active == true) or (md and md.baInvisibleGeneratorLocalOn == true) or false
    if current == wantOn then
        local key = wantOn and "IGUI_Bunker_CentralGeneratorAlreadyOn" or "IGUI_Bunker_CentralGeneratorAlreadyOff"
        playerObj:setHaloNote(getText(key), 240, 240, 0, 300)
        return
    end

    md.baInvisibleGeneratorLocalOn = wantOn
    if centralObj.transmitModData then
        centralObj:transmitModData()
    end

    if store.nodes[key] then
        store.nodes[key].active = wantOn
        if ModData.transmit then
            ModData.transmit(BunkersAnywhere.InvisibleCentralGenerator.DataKey)
        end
    end

    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "ToggleInvisibleGeneratorCentral", {
            x = sq:getX(),
            y = sq:getY(),
            z = sq:getZ(),
            on = wantOn and true or false,
        })
    end

    local textKey = wantOn and "IGUI_Bunker_CentralGeneratorOn" or "IGUI_Bunker_CentralGeneratorOff"
    local r, g, b = wantOn and 0 or 255, wantOn and 255 or 180, wantOn and 100 or 120
    playerObj:setHaloNote(getText(textKey), r, g, b, 350)
end


function BunkersAnywhere.onConnectInvisibleGeneratorCentral(centralObj, playerObj)
    if luautils.walk(playerObj, centralObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, centralObj:getSquare(), 120, "Loot", "LightSwitch", BunkersAnywhere.connectInvisibleGeneratorCentral, centralObj, playerObj))
    end
end

function BunkersAnywhere.onTurnOnInvisibleGeneratorCentral(centralObj, playerObj)
    if luautils.walk(playerObj, centralObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, centralObj:getSquare(), 70, "Loot", "LightSwitch", BunkersAnywhere.setInvisibleGeneratorCentralState, centralObj, playerObj, true))
    end
end

function BunkersAnywhere.onTurnOffInvisibleGeneratorCentral(centralObj, playerObj)
    if luautils.walk(playerObj, centralObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, centralObj:getSquare(), 70, "Loot", "LightSwitch", BunkersAnywhere.setInvisibleGeneratorCentralState, centralObj, playerObj, false))
    end
end

function BunkersAnywhere.onConnectInvisibleGeneratorToOtherCentral(centralObj, playerObj, targetX, targetY, targetZ)
    if luautils.walk(playerObj, centralObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, centralObj:getSquare(), 180, "Loot", "LightSwitch", BunkersAnywhere.connectInvisibleGeneratorToOtherCentral, centralObj, playerObj, targetX, targetY, targetZ))
    end
end

function BunkersAnywhere.onActivateShippingMailbox(mailObj, playerObj)
    if luautils.walk(playerObj, mailObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, mailObj:getSquare(), 120, "Loot", "LightSwitch", BunkersAnywhere.activateShippingMailbox, mailObj, playerObj))
    end
end

function BunkersAnywhere.onSendShippingMailbox(mailObj, playerObj, targetX, targetY, targetZ)
    if luautils.walk(playerObj, mailObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, mailObj:getSquare(), 130, "Loot", "LightSwitch", BunkersAnywhere.sendShippingMailbox, mailObj, playerObj, targetX, targetY, targetZ))
    end
end

function BunkersAnywhere.onWithdrawShippingMailbox(mailObj, playerObj)
    if luautils.walk(playerObj, mailObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, mailObj:getSquare(), 80, "Loot", "LightSwitch", BunkersAnywhere.withdrawShippingMailbox, mailObj, playerObj))
    end
end

function BunkersAnywhere.depositSelectedItemsToMailbox(items, playerObj, mailObj)
    if not mailObj or not mailObj.getModData then return end
    local md = mailObj:getModData()
    if not (md and md.baShippingMailboxActive) then return end

    local payload = {}
    local payloadCount = 0
    local inv = playerObj:getInventory()

    for _, itemGroup in ipairs(items) do
        if instanceof(itemGroup, "InventoryItem") then
            local item = itemGroup
            payload[item:getFullType()] = (payload[item:getFullType()] or 0) + 1
            payloadCount = payloadCount + 1
        else
            for _, item in ipairs(itemGroup.items) do
                payload[item:getFullType()] = (payload[item:getFullType()] or 0) + 1
                payloadCount = payloadCount + 1
            end
        end
    end

    local capacity = tonumber(md.baShippingMailboxCapacity) or 100
    local current = tonumber(md.baShippingMailboxCount) or 0
    if current + payloadCount > capacity then
        playerObj:setHaloNote(getText("IGUI_Bunker_MailboxFull", tostring(capacity)), 255, 80, 80, 350)
        return
    end

    for _, itemGroup in ipairs(items) do
        if instanceof(itemGroup, "InventoryItem") then
            inv:Remove(itemGroup)
        else
            for _, item in ipairs(itemGroup.items) do
                inv:Remove(item)
            end
        end
    end

    local sq = mailObj:getSquare()
    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "DepositShippingMailbox", {
            x = sq:getX(), y = sq:getY(), z = sq:getZ(), items = payload
        })
    end
    playerObj:setHaloNote(getText("IGUI_Bunker_MailDeposited"), 0, 220, 255, 300)
end

function BunkersAnywhere.onDepositSelectedItemsToMailbox(items, playerObj, mailObj)
    ISTimedActionQueue.add(ISBunkerAction:new(playerObj, playerObj:getSquare(), 70, "Loot", nil, BunkersAnywhere.depositSelectedItemsToMailbox, items, playerObj, mailObj))
end

local function BunkersAnywhereCentralInventoryContext(player, context, items)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    local mailObj = BunkersAnywhere.findNearbyActiveMailbox(playerObj, 1)
    if mailObj then
        context:addOption(getText("ContextMenu_DepositToShippingMailbox"), items, BunkersAnywhere.onDepositSelectedItemsToMailbox, playerObj, mailObj)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(BunkersAnywhereCentralInventoryContext)

local function BunkersAnywhereCentralWorldContext(player, context, worldobjects, test)
    local playerObj = getSpecificPlayer(player)
    local sq = worldobjects[1]:getSquare()

    local centralObj = nil
    local mailObj = nil
    local objects = sq:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if not centralObj and BunkersAnywhere.isInvisibleCentralTile(obj) then
            centralObj = obj
        end
        if not mailObj and BunkersAnywhere.isShippingMailboxTile(obj) then
            mailObj = obj
        end
    end

    if centralObj then
        local md = centralObj:getModData()
        local sqCentral = centralObj:getSquare()
        local store = BunkersAnywhere.getInvisibleGeneratorStore()
        local currentKey = BunkersAnywhere.getInvisibleGeneratorNodeKey(sqCentral:getX(), sqCentral:getY(), sqCentral:getZ())
        local currentNode = store.nodes and store.nodes[currentKey] or nil

        if not currentNode then
            BunkersAnywhere.registerInvisibleGeneratorCentralCandidate(centralObj)
            currentNode = store.nodes and store.nodes[currentKey] or nil
        end

        local isKnown = currentNode ~= nil
        local isSource = (currentNode and currentNode.source ~= false) or (md and md.baInvisibleGeneratorIsSource == true)
        if not isSource then
            context:addOption(getText("ContextMenu_ConnectInvisibleGeneratorCentral"), centralObj, BunkersAnywhere.onConnectInvisibleGeneratorCentral, playerObj)
        end

        local connectSub = nil
        local connectSubCtx = nil
        for _, node in pairs(store.nodes) do
            if node and node.z == BunkersAnywhere.InvisibleCentralGenerator.ZLevel then
                if not (node.x == sqCentral:getX() and node.y == sqCentral:getY() and node.z == sqCentral:getZ()) then
                    local targetIsSource = (node.source ~= false)
                    local targetIsOn = (node.active == true)
                    if targetIsSource and targetIsOn then
                        local targetKey = BunkersAnywhere.getInvisibleGeneratorNodeKey(node.x, node.y, node.z)
                        local alreadyLinked = currentNode and currentNode.links and currentNode.links[targetKey] == true
                        if not alreadyLinked then
                            if not connectSub then
                                connectSub = context:addOption(getText("ContextMenu_ConnectToOtherCentral"))
                                connectSubCtx = ISContextMenu:getNew(context)
                                context:addSubMenu(connectSub, connectSubCtx)
                            end

                            local need = BunkersAnywhere.getWireDistanceCost(sqCentral, node.x, node.y)
                            local have = BunkersAnywhere.countElectricWireAvailable(playerObj)
                            local label = getText("ContextMenu_ConnectToOtherCentralCoord", tostring(node.x), tostring(node.y), tostring(node.z))
                            local opt = connectSubCtx:addOption(label, centralObj, BunkersAnywhere.onConnectInvisibleGeneratorToOtherCentral, playerObj, node.x, node.y, node.z)

                            opt.toolTip = ISToolTip:new()
                            opt.toolTip:initialise()
                            opt.toolTip:setVisible(false)
                            opt.toolTip.description = getText("IGUI_Bunker_CentralNeedWire", tostring(need), tostring(have))
                            if have < need then
                                opt.notAvailable = true
                            end
                        end
                    end
                end
            end
        end

        local localOn = md and md.baInvisibleGeneratorLocalOn == true
        local providers = md and md.baInvisibleGeneratorProviderText or nil
        local providerCount = tonumber(md and md.baInvisibleGeneratorProviderCount) or 0
        if providerCount > 0 and providers and providers ~= "" then
            local depLabel = getText("ContextMenu_CentralDependsOn", tostring(providers))
            local depOpt = context:addOption(depLabel)
            depOpt.notAvailable = true
        end

        if isKnown then
            local isOn = (currentNode and currentNode.active == true) or localOn
            if isOn then
                context:addOption(getText("ContextMenu_TurnOffInvisibleGeneratorCentral"), centralObj, BunkersAnywhere.onTurnOffInvisibleGeneratorCentral, playerObj)
            else
                context:addOption(getText("ContextMenu_TurnOnInvisibleGeneratorCentral"), centralObj, BunkersAnywhere.onTurnOnInvisibleGeneratorCentral, playerObj)
            end
        end
    end

    if mailObj and mailObj.getModData then
        local mdMail = mailObj:getModData()
        if not (mdMail and mdMail.baShippingMailboxActive) then
            local nearKey = BunkersAnywhere.findNearestActiveCentralNodeKeyFromSquare(mailObj:getSquare())
            local option = context:addOption(getText("ContextMenu_ActivateShippingMailbox"), mailObj, BunkersAnywhere.onActivateShippingMailbox, playerObj)
            if not nearKey then option.notAvailable = true end
        else
            context:addOption(getText("ContextMenu_WithdrawFromShippingMailbox"), mailObj, BunkersAnywhere.onWithdrawShippingMailbox, playerObj)

            local cKey = mdMail.baShippingCentralKey
            local store = BunkersAnywhere.getInvisibleGeneratorStore()
            local cNode = cKey and store.nodes[cKey] or nil
            if cNode and cNode.links then
                local sub = context:addOption(getText("ContextMenu_SendShippingMailbox"))
                local subCtx = ISContextMenu:getNew(context)
                context:addSubMenu(sub, subCtx)
                for linkedKey, enabled in pairs(cNode.links) do
                    if enabled and store.nodes[linkedKey] then
                        local ln = store.nodes[linkedKey]
                        local label = getText("ContextMenu_SendShippingMailboxTo", tostring(ln.x), tostring(ln.y), tostring(ln.z))
                        subCtx:addOption(label, mailObj, BunkersAnywhere.onSendShippingMailbox, playerObj, ln.x, ln.y, ln.z)
                    end
                end
            end
        end
    end

    local hasOwnedInvisibleGenerator = false
    for _, wo in ipairs(worldobjects) do
        if BunkersAnywhere.hideOwnedInvisibleGenerator(wo) then
            hasOwnedInvisibleGenerator = true
            break
        end
    end

    if hasOwnedInvisibleGenerator then
        context:removeOptionByName(getText("ContextMenu_Generator"))
        context:removeOptionByName(getText("ContextMenu_GeneratorInfo"))
        context:removeOptionByName(getText("ContextMenu_GeneratorPlug"))
        context:removeOptionByName(getText("ContextMenu_GeneratorUnplug"))
        context:removeOptionByName(getText("ContextMenu_GeneratorAddFuel"))
        context:removeOptionByName(getText("ContextMenu_GeneratorFix"))
        context:removeOptionByName(getText("ContextMenu_GeneratorTake"))
        context:removeOptionByName(getText("ContextMenu_Vehicle_PlugGenerator"))
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereCentralWorldContext)

local _baGeneratorHideTick = 0
local function BunkersAnywhereOnTickHideOwnedGenerators()
    _baGeneratorHideTick = _baGeneratorHideTick + 1
    if _baGeneratorHideTick < 3 then return end
    _baGeneratorHideTick = 0
    BunkersAnywhere.refreshOwnedInvisibleGenerators()
end

Events.OnTick.Add(BunkersAnywhereOnTickHideOwnedGenerators)
Events.OnGameStart.Add(BunkersAnywhere.refreshOwnedInvisibleGenerators)
