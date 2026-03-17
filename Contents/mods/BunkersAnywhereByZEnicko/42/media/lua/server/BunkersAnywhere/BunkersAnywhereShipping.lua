BunkersAnywhere = BunkersAnywhere or {}

BunkersAnywhereShipping = BunkersAnywhereShipping or {}

local Shipping = BunkersAnywhereShipping
local H = nil
local LOADED_MISSING_CHECKS_TO_REMOVE = 3

function Shipping.init(helpers)
    H = helpers
end

function Shipping.syncMailboxes(effective)
    if not H.isEnabled() then return false end

    local store = H.getStore()
    store.shippingDestinations = store.shippingDestinations or {}
    local changed = false

    for key, mailbox in pairs(store.mailboxes) do
        local square = mailbox and getSquare(mailbox.x, mailbox.y, mailbox.z) or nil
        local centralExists = mailbox.centralKey and store.nodes[mailbox.centralKey] and effective[mailbox.centralKey]
        local previousActive = mailbox.active == true
        mailbox.active = centralExists and true or false
        store.shippingDestinations[key] = {
            x = mailbox.x,
            y = mailbox.y,
            z = mailbox.z,
            active = mailbox.active == true,
            centralKey = mailbox.centralKey,
            ownerUsername = mailbox.ownerUsername or "",
            ownerOnlineID = mailbox.ownerOnlineID or -1,
        }
        if previousActive ~= (mailbox.active == true) then
            changed = true
        end

        if square then
            local hasMailbox, mailboxObj = H.hasMailboxOnSquare(square)
            if not hasMailbox then
                mailbox.missingLoadedChecks = math.floor(tonumber(mailbox.missingLoadedChecks) or 0) + 1
                if mailbox.missingLoadedChecks >= LOADED_MISSING_CHECKS_TO_REMOVE then
                    print("[BunkersAnywhere][ShippingDebug] syncMailboxes removing mailbox " .. tostring(key) .. " after loaded missing checks=" .. tostring(mailbox.missingLoadedChecks))
                    store.mailboxes[key] = nil
                    store.shippingDestinations[key] = nil
                    if store.shippingPendingGround then
                        store.shippingPendingGround[key] = nil
                    end
                    changed = true
                end
            elseif mailboxObj and mailboxObj.getModData then
                if (tonumber(mailbox.missingLoadedChecks) or 0) ~= 0 then
                    mailbox.missingLoadedChecks = 0
                end
                local md = mailboxObj:getModData()
                md.baShippingMailboxActive = mailbox.active
                md.baShippingCentralKey = mailbox.centralKey
                md.baShippingMailboxCapacity = mailbox.capacity or H.getMailboxCapacity()
                md.baShippingMailboxCount = H.getItemsMapCount(mailbox.items)
                md.baShippingOwnerUsername = mailbox.ownerUsername or ""
                md.baShippingOwnerOnlineID = mailbox.ownerOnlineID or -1
                if mailboxObj.transmitModData then
                    mailboxObj:transmitModData()
                end
                if H.flushPendingGroundPayloadForMailbox and H.flushPendingGroundPayloadForMailbox(store, key, square) then
                    changed = true
                end
            end
        end
    end

    for key, destination in pairs(store.shippingDestinations) do
        if not store.mailboxes[key] then
            store.shippingDestinations[key] = nil
            if store.shippingPendingGround then
                store.shippingPendingGround[key] = nil
            end
            changed = true
        elseif destination then
            destination.active = store.mailboxes[key].active == true
        end
    end

    if changed and H.pushShippingDestinations then
        H.pushShippingDestinations()
    end

    return changed
end

function Shipping.handleClientCommand(command, actor, args)
    if not H.isEnabled() then return false end

    if command == "ActivateShippingMailbox" then
        H.activateMailboxAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), actor, args)
        return true
    elseif command == "RequestShippingDestinations" then
        H.pushShippingDestinations(actor)
        return true
    elseif command == "DepositShippingMailbox" then
        H.depositMailboxAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), args.items or {})
        return true
    elseif command == "SendShippingMailboxToCentral" then
        H.sendMailboxToCentral(tonumber(args.x), tonumber(args.y), tonumber(args.z), tonumber(args.tx), tonumber(args.ty), tonumber(args.tz))
        return true
    elseif command == "WithdrawShippingMailbox" then
        H.withdrawMailboxAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), actor)
        return true
    end

    return false
end
