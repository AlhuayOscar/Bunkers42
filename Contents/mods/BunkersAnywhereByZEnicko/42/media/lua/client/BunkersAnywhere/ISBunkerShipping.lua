BunkersAnywhere = BunkersAnywhere or {}
require "ISUI/ISInventoryPaneContextMenu"

BunkersAnywhere.ShippingMailbox = BunkersAnywhere.ShippingMailbox or {
    SpriteName = "rooftop_furniture_3",
    MaxCentralDistance = 20,
    Enabled = false,
}

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

local function BunkersAnywhereShippingInventoryContext(player, context, items)
    if not BunkersAnywhere.ShippingMailbox.Enabled then return end
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local mailObj = BunkersAnywhere.findNearbyActiveMailbox(playerObj, 1)
    if mailObj then
        context:addOption(getText("ContextMenu_DepositToShippingMailbox"), items, BunkersAnywhere.onDepositSelectedItemsToMailbox, playerObj, mailObj)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(BunkersAnywhereShippingInventoryContext)

local function BunkersAnywhereShippingWorldContext(player, context, worldobjects, test)
    if not BunkersAnywhere.ShippingMailbox.Enabled then return end
    if not worldobjects then return end
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local mailObj = nil
    local function scanSquareObjects(sq)
        if not sq then return end
        local objects = sq:getObjects()
        if not objects then return end
        for i = 0, objects:size() - 1 do
            local obj = objects:get(i)
            if not mailObj and BunkersAnywhere.isShippingMailboxTile(obj) then
                mailObj = obj
                return
            end
        end
    end

    if worldobjects.size and worldobjects.get then
        for i = 0, worldobjects:size() - 1 do
            local wo = worldobjects:get(i)
            local sq = wo and wo.getSquare and wo:getSquare() or nil
            scanSquareObjects(sq)
            if mailObj then break end
        end
    else
        for _, wo in ipairs(worldobjects) do
            local sq = wo and wo.getSquare and wo:getSquare() or nil
            scanSquareObjects(sq)
            if mailObj then break end
        end
    end

    if not mailObj then
        scanSquareObjects(playerObj:getSquare())
    end
    if not mailObj then return end

    if mailObj.getModData then
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
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereShippingWorldContext)
