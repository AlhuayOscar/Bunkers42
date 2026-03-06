BunkersAnywhere = BunkersAnywhere or {}

local CFG = {
    DataKey = "BunkersAnywhereInvisibleCentralGenerators",
    SpriteName = "location_business_bank_01_67",
    ZLevel = -1,
    GeneratorRadius = 20,
    GeneratorVertical = 3,
}

local function getStore()
    local data = ModData.getOrCreate(CFG.DataKey)
    data.nodes = data.nodes or {}
    return data
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
            if spriteName == CFG.SpriteName then
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
            return -- respetar generadores normales del jugador
        end
    end

    if not generator then
        local item = instanceItem("Base.Generator")
        if not item then return end
        item:setCondition(100)
        item:getModData().fuel = 100
        generator = IsoGenerator.new(item, getCell(), square)
        if generator and generator.transmitCompleteItemToClients then
            generator:transmitCompleteItemToClients()
        end
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

local function connectNodeAt(x, y, z)
    local square = getSquare(x, y, z)
    if not square then return false end
    if z ~= CFG.ZLevel then return false end
    local hasCentral, centralObj = hasCentralOnSquare(square)
    if not hasCentral then return false end

    local store = getStore()
    local key = getNodeKey(x, y, z)
    store.nodes[key] = { x = x, y = y, z = z, active = true }
    if ModData.transmit then
        ModData.transmit(CFG.DataKey)
    end

    if centralObj and centralObj.getModData then
        centralObj:getModData().baInvisibleGeneratorConnected = true
        centralObj:getModData().baInvisibleGeneratorOn = true
        if centralObj.transmitModData then
            centralObj:transmitModData()
        end
    end

    ensureInvisibleGenerator(square, true)
    forceNoToxic(square)
    clampGeneratorPowerToBasement({ x = x, y = y, z = z })
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
    if ModData.transmit then
        ModData.transmit(CFG.DataKey)
    end

    local hasCentral, centralObj = hasCentralOnSquare(square)
    if hasCentral and centralObj and centralObj.getModData then
        centralObj:getModData().baInvisibleGeneratorOn = node.active
        if centralObj.transmitModData then
            centralObj:transmitModData()
        end
    end

    ensureInvisibleGenerator(square, node.active)
    forceNoToxic(square)
    clampGeneratorPowerToBasement(node)
    return true
end

local function cleanupAndMaintain()
    local store = getStore()
    local changed = false

    for key, node in pairs(store.nodes) do
        local square = node and getSquare(node.x, node.y, node.z) or nil
        local hasCentral = square and hasCentralOnSquare(square) or false

        if not hasCentral or not (node and node.active) then
            if not hasCentral then
                removeOwnedGenerator(square)
                store.nodes[key] = nil
                changed = true
            else
                ensureInvisibleGenerator(square, false)
                forceNoToxic(square)
                clampGeneratorPowerToBasement(node)
            end
        else
            ensureInvisibleGenerator(square, true)
            forceNoToxic(square)
            clampGeneratorPowerToBasement(node)
        end
    end

    if changed and ModData.transmit then
        ModData.transmit(CFG.DataKey)
    end
end

local function onClientCommand(module, command, player, args)
    if module ~= "BunkersAnywhere" then return end
    if not args then return end

    if command == "ConnectInvisibleGeneratorCentral" then
        connectNodeAt(tonumber(args.x), tonumber(args.y), tonumber(args.z))
    elseif command == "ToggleInvisibleGeneratorCentral" then
        setNodeStateAt(tonumber(args.x), tonumber(args.y), tonumber(args.z), args.on == true)
    end
end

Events.OnClientCommand.Add(onClientCommand)
Events.EveryOneMinute.Add(cleanupAndMaintain)
