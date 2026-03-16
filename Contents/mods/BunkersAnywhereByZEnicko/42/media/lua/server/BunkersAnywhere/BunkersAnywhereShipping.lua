BunkersAnywhere = BunkersAnywhere or {}

BunkersAnywhereShipping = BunkersAnywhereShipping or {}

local Shipping = BunkersAnywhereShipping
local H = nil

function Shipping.init(helpers)
    H = helpers
end

function Shipping.syncMailboxes(effective)
    if not H.isEnabled() then return false end

    local store = H.getStore()
    local changed = false

    for key, mailbox in pairs(store.mailboxes) do
        local square = mailbox and getSquare(mailbox.x, mailbox.y, mailbox.z) or nil
        local hasMailbox, mailboxObj = square and H.hasMailboxOnSquare(square) or false, nil
        if square then
            hasMailbox, mailboxObj = H.hasMailboxOnSquare(square)
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
                md.baShippingMailboxCapacity = mailbox.capacity or H.getMailboxCapacity()
                md.baShippingMailboxCount = H.getItemsMapCount(mailbox.items)
                if mailboxObj.transmitModData then
                    mailboxObj:transmitModData()
                end
            end
        end
    end

    return changed
end

function Shipping.handleClientCommand(command, actor, args)
    if not H.isEnabled() then return false end

    if command == "ActivateShippingMailbox" then
        H.activateMailboxAt(tonumber(args.x), tonumber(args.y), tonumber(args.z))
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
