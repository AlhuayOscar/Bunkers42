BunkersAnywhere = BunkersAnywhere or {}

BunkersAnywhere.ShippingMailbox = BunkersAnywhere.ShippingMailbox or {
    SpriteName = "trashcontainers_01_32",
    SpriteNameAlt = "trashcontainers_01_33",
    MaxCentralDistance = 20,
    Enabled = true,
}

local function bunkerText(key, fallback, ...)
    local text = getText(key, ...)
    if text and text ~= key then
        return text
    end
    if select("#", ...) > 0 then
        return string.format(fallback, ...)
    end
    return fallback
end

local function getNoDestinationsLabel()
    return bunkerText("ContextMenu_SendShippingMailboxNoDestinations", "Send shipping (no active destinations)")
end

local function requestShippingStoreSync()
    if ModData and ModData.request and BunkersAnywhere and BunkersAnywhere.InvisibleCentralGenerator and BunkersAnywhere.InvisibleCentralGenerator.DataKey then
        ModData.request(BunkersAnywhere.InvisibleCentralGenerator.DataKey)
    end
    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "RequestShippingDestinations", {})
    end
end

local function getShippingPlayerIdentity(playerObj)
    return {
        username = (playerObj and playerObj.getUsername and playerObj:getUsername()) or "",
        onlineID = (playerObj and playerObj.getOnlineID and playerObj:getOnlineID()) or -1,
    }
end

local function isMyShippingDestination(dest, playerObj)
    local identity = getShippingPlayerIdentity(playerObj)
    if identity.onlineID ~= -1 and tonumber(dest.ownerOnlineID or -1) == identity.onlineID then
        return true
    end
    return identity.username ~= "" and tostring(dest.ownerUsername or "") == identity.username
end

function BunkersAnywhere.isShippingMailboxTile(obj)
    if not BunkersAnywhere.ShippingMailbox.Enabled then return false end
    if not obj or not obj.getSprite then return false end
    local sprite = obj:getSprite()
    if not sprite or not sprite.getName then return false end
    local name = sprite:getName()
    return name == BunkersAnywhere.ShippingMailbox.SpriteName or name == BunkersAnywhere.ShippingMailbox.SpriteNameAlt
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

function BunkersAnywhere.getActiveShippingDestinations(currentMailObj)
    local destinations = {}
    local seen = {}
    local currentSq = currentMailObj and currentMailObj:getSquare() or nil
    local currentKey = currentSq and BunkersAnywhere.getInvisibleGeneratorNodeKey and BunkersAnywhere.getInvisibleGeneratorNodeKey(currentSq:getX(), currentSq:getY(), currentSq:getZ()) or nil
    requestShippingStoreSync()
    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local shippingDestinations = store and store.shippingDestinations or nil
    if shippingDestinations then
        for key, destination in pairs(shippingDestinations) do
            if destination and key ~= currentKey then
                table.insert(destinations, {
                    key = key,
                    x = destination.x,
                    y = destination.y,
                    z = destination.z,
                    active = destination.active == true,
                    ownerUsername = destination.ownerUsername or "",
                    ownerOnlineID = destination.ownerOnlineID or -1,
                })
                seen[key] = true
            end
        end
    end

    if #destinations == 0 and getCell then
        local cell = getCell()
        local player = getSpecificPlayer(0)
        local psq = player and player.getSquare and player:getSquare() or nil
        local pz = psq and psq:getZ() or nil
        if cell and psq and pz ~= nil then
            for x = psq:getX() - 40, psq:getX() + 40 do
                for y = psq:getY() - 40, psq:getY() + 40 do
                    local sq = cell:getGridSquare(x, y, pz)
                    if sq then
                        local objs = sq:getObjects()
                        if objs then
                            for i = 0, objs:size() - 1 do
                                local obj = objs:get(i)
                                if obj and obj ~= currentMailObj and BunkersAnywhere.isShippingMailboxTile(obj) then
                                    local md = obj.getModData and obj:getModData() or nil
                                    if md and md.baShippingMailboxActive == true then
                                        local key = BunkersAnywhere.getInvisibleGeneratorNodeKey and BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ()) or nil
                                        if key ~= currentKey and not seen[key] then
                                            table.insert(destinations, {
                                                key = key,
                                                x = sq:getX(),
                                                y = sq:getY(),
                                                z = sq:getZ(),
                                                active = true,
                                                ownerUsername = md.baShippingOwnerUsername or "",
                                                ownerOnlineID = md.baShippingOwnerOnlineID or -1,
                                            })
                                            seen[key] = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(destinations, function(a, b)
        if a.z ~= b.z then return a.z < b.z end
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)

    return destinations
end

function BunkersAnywhere.getShippingMailboxState(mailObj)
    local sq = mailObj and mailObj.getSquare and mailObj:getSquare() or nil
    if not sq then
        return { active = false, key = nil, centralKey = nil }
    end

    local key = BunkersAnywhere.getInvisibleGeneratorNodeKey and BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ()) or nil
    requestShippingStoreSync()
    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local mailbox = key and store and store.mailboxes and store.mailboxes[key] or nil
    if mailbox then
        return {
            active = mailbox.active == true,
            key = key,
            centralKey = mailbox.centralKey,
        }
    end

    local md = mailObj.getModData and mailObj:getModData() or nil
    return {
        active = md and md.baShippingMailboxActive == true or false,
        key = key,
        centralKey = md and md.baShippingCentralKey or nil,
    }
end

function BunkersAnywhere.activateShippingMailbox(mailObj, playerObj)
    local sq = mailObj and mailObj:getSquare()
    if not sq then return end
    requestShippingStoreSync()
    if sendClientCommand then
        local identity = getShippingPlayerIdentity(playerObj)
        sendClientCommand("BunkersAnywhere", "ActivateShippingMailbox", {
            x = sq:getX(),
            y = sq:getY(),
            z = sq:getZ(),
            username = identity.username,
            onlineID = identity.onlineID,
        })
    end
    playerObj:setHaloNote(bunkerText("IGUI_Bunker_MailActivated", "Activating shipping"), 0, 255, 100, 350)
end

function BunkersAnywhere.sendShippingMailbox(mailObj, playerObj, targetX, targetY, targetZ)
    local sq = mailObj and mailObj:getSquare()
    if not sq then return end
    requestShippingStoreSync()
    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "SendShippingMailboxToCentral", {
            x = sq:getX(), y = sq:getY(), z = sq:getZ(),
            tx = targetX, ty = targetY, tz = targetZ,
        })
    end
    playerObj:setHaloNote(bunkerText("IGUI_Bunker_MailSentTo", "Sent to %s, %s, %s", tostring(targetX), tostring(targetY), tostring(targetZ)), 80, 220, 255, 350)
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
            if not mailObj and BunkersAnywhere.isShippingMailboxTile(wo) then
                mailObj = wo
                break
            end
            scanSquareObjects(wo and wo.getSquare and wo:getSquare() or nil)
            if mailObj then break end
        end
    else
        for _, wo in ipairs(worldobjects) do
            if not mailObj and BunkersAnywhere.isShippingMailboxTile(wo) then
                mailObj = wo
                break
            end
            scanSquareObjects(wo and wo.getSquare and wo:getSquare() or nil)
            if mailObj then break end
        end
    end

    if not mailObj then return end

    local sq = mailObj.getSquare and mailObj:getSquare() or nil
    local sx = sq and sq:getX() or "?"
    local sy = sq and sq:getY() or "?"
    local sz = sq and sq:getZ() or "?"
    print("[BunkersAnywhere][ShippingClientDebug] context mailbox at " .. tostring(sx) .. "," .. tostring(sy) .. "," .. tostring(sz))

    local mailboxState = BunkersAnywhere.getShippingMailboxState(mailObj)
    if not mailboxState.active then
        print("[BunkersAnywhere][ShippingClientDebug] mailbox inactive")
        context:addOption(bunkerText("ContextMenu_ActivateShippingMailbox", "Activate shipping"), mailObj, BunkersAnywhere.onActivateShippingMailbox, playerObj)
        return
    end

    local destinations = BunkersAnywhere.getActiveShippingDestinations(mailObj)
    print("[BunkersAnywhere][ShippingClientDebug] mailbox active destinations=" .. tostring(#destinations))
    if #destinations > 0 then
        local sub = context:addOption(bunkerText("ContextMenu_SendShippingMailbox", "Send shipping"))
        local subCtx = ISContextMenu:getNew(context)
        context:addSubMenu(sub, subCtx)
        table.sort(destinations, function(a, b)
            local aMine = isMyShippingDestination(a, playerObj)
            local bMine = isMyShippingDestination(b, playerObj)
            if aMine ~= bMine then
                return aMine
            end
            if a.z ~= b.z then return a.z < b.z end
            if a.x ~= b.x then return a.x < b.x end
            return a.y < b.y
        end)
        for _, dest in ipairs(destinations) do
            local suffix = isMyShippingDestination(dest, playerObj) and " [Me]" or ""
            local label = bunkerText("ContextMenu_SendShippingMailboxTo", "Send to: %s, %s, %s%s", tostring(dest.x), tostring(dest.y), tostring(dest.z), suffix)
            subCtx:addOption(label, mailObj, BunkersAnywhere.onSendShippingMailbox, playerObj, dest.x, dest.y, dest.z)
        end
    else
        local sub = context:addOption(getNoDestinationsLabel())
        sub.notAvailable = true
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereShippingWorldContext)
Events.OnGameStart.Add(requestShippingStoreSync)
