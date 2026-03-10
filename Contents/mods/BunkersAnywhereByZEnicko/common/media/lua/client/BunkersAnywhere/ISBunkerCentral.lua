BunkersAnywhere = BunkersAnywhere or {}
require "ISUI/ISInventoryPaneContextMenu"

BunkersAnywhere.InvisibleCentralGenerator = {
    DataKey = "BunkersAnywhereInvisibleCentralGenerators",
    SpriteName = "location_business_bank_01_67",
    SpriteNameAlt = "location_business_bank_01_66",
    PlacementSpriteName = "location_business_bank_01_67",
    PlacementSpriteNameAlt = "location_business_bank_01_66",
    ZLevel = -1,
    BaseRadius = 100,
    RadiusUpgradeBonus = 2000,
    RadiusUpgradeWireCost = 50,
    RadiusUpgradeBonuses = { 25, 50, 100, 200, 500, 1000, 2000 },
    RadiusUpgradeWireCosts = { 50, 50, 50, 50, 50, 50, 200 },
    RadiusUpgradeEnabled = false,
}

BunkersAnywhere.ShippingMailbox = {
    SpriteName = "rooftop_furniture_3",
    MaxCentralDistance = 20,
    Enabled = false,
}

BunkersAnywhere.CentralBattery = {
    MaxEnergy = 100,
    MaxUses = 3,
    MaxRuntimeMinutes = 10080,
    MinutesPerPercent = 4,
    Types = {
        "Base.CarBattery",
        "Base.CarBattery1",
        "Base.CarBattery2",
        "Base.CarBattery3",
    },
    ChargeByType = {
        ["Base.CarBattery"] = 15,
        ["Base.CarBattery1"] = 29,
        ["Base.CarBattery2"] = 29,
        ["Base.CarBattery3"] = 100,
    },
    RuntimeMinutesByType = {
        ["Base.CarBattery"] = 1440,
        ["Base.CarBattery1"] = 2880,
        ["Base.CarBattery2"] = 2880,
        ["Base.CarBattery3"] = 10080,
    },
}

BunkersAnywhere.CentralSkill = {
    MinElectricityToConnect = 3,
}

local BA_LOCAL_TEXT = {
    EN = {
        IGUI_Bunker_CentralGeneratorConnected = "Local central connected (hidden non-toxic generator)",
        IGUI_Bunker_CentralGeneratorAlreadyConnected = "Local central is already connected",
        IGUI_Bunker_CentralGeneratorOn = "Local central turned on",
        IGUI_Bunker_CentralGeneratorOff = "Local central turned off",
        IGUI_Bunker_CentralGeneratorAlreadyOn = "Local central is already on",
        IGUI_Bunker_CentralGeneratorAlreadyOff = "Local central is already off",
        IGUI_Bunker_CentralNeedLinkFirst = "First connect this central to another central",
        IGUI_Bunker_CentralNeedWire = "You need %1 electric wire (available: %2)",
        IGUI_Bunker_CentralLinkedTo = "Central linked to %1, %2, %3",
        IGUI_Bunker_CentralAlreadyLinked = "These centrals are already linked",
        IGUI_Bunker_NeedElectricityLevel = "You need Electricity %1 (you have %2)",
        IGUI_Bunker_CentralUpgradeDisabled = "Central upgrade is temporarily disabled",
        IGUI_Bunker_CentralUpgradeMax = "This central is already at maximum upgrade",
        IGUI_Bunker_CentralNeedWiresSimple = "You need %1 wires (you have %2)",
        IGUI_Bunker_CentralInvalidBattery = "Invalid battery for this central",
        IGUI_Bunker_CentralNoCompatibleBattery = "You do not have a compatible battery to insert",
        IGUI_Bunker_CentralAlreadyFull = "This central is already at 100%",
        IGUI_Bunker_CentralNoCompatibleBatteryHeadroom = "You do not have a compatible battery that fits without exceeding 100%",
        IGUI_Bunker_CentralNoEnergyInsertBattery = "This central has no energy (0%). Insert a battery.",
        IGUI_Bunker_CentralWouldExceed = "You cannot exceed 100%% (%1%% + %2%%)",
        IGUI_Bunker_BatteryStateGood = "Good",
        IGUI_Bunker_BatteryStateUsed = "Used",
        IGUI_Bunker_BatteryStateWorn = "Worn",
        IGUI_Bunker_CentralOnlyPrimaryUpgrade = "Only primary centrals can be upgraded",
        IGUI_Bunker_CentralUpgradeApplied = "Central upgraded: +%1 tiles of range",
        IGUI_Bunker_CentralOverlay = "Central: %1",
        ContextMenu_ConnectInvisibleGeneratorCentral = "Connect local electric central",
        ContextMenu_TurnOnInvisibleGeneratorCentral = "Turn on local electric central",
        ContextMenu_TurnOffInvisibleGeneratorCentral = "Turn off local electric central",
        ContextMenu_CentralEnergy = "Central energy: %1%%",
        ContextMenu_CentralTimeRemaining = "Time remaining: %1",
        ContextMenu_CentralRadius = "Central radius: %1 tiles",
        ContextMenu_CentralUpgradeDisabled = "Upgrade central (temporarily disabled)",
        ContextMenu_CentralAutoLoadBattery = "Load battery automatically",
        ContextMenu_CentralLoadWithBattery = "Load central with battery",
        ContextMenu_CentralInsertBattery = "Insert %1 (+%2) [%3]",
        ContextMenu_CentralWouldExceed = "Exceeds 100%% (%1%% + %2%%)",
        ContextMenu_CentralInvalidBattery = "Invalid battery",
        ContextMenu_CentralRemoveBattery = "Remove battery from central",
        ContextMenu_CentralTurnOffToRemoveBattery = "Turn off the central to remove batteries",
        ContextMenu_CentralRemoveBatteryEntry = "Remove %1 [%2]",
        ContextMenu_CentralRemoveBatteryScrap = "%1 -> Scrap",
        ContextMenu_CentralNeedElectricityLevel = "Requires Electricity %1 (current %2)",
        ContextMenu_ConnectToOtherCentral = "Connect to another central",
        ContextMenu_ConnectToOtherCentralCoord = "Connect to another central: %1, %2, %3",
        ContextMenu_CentralDependsOn = "This central depends on: %1",
        ContextMenu_InstallElectricCentral = "Install automatically facing north (up-right)",
        ContextMenu_AutoInstallElectricCentral = "Install automatically facing north (up-right)",
        ContextMenu_PlaceElectricCentral = "Place electric central",
        ContextMenu_CentralRotateNorth = "Place facing north",
        ContextMenu_CentralRotateWest = "Place facing west",
        IGUI_Bunker_CentralFaceNorthOrWest = "Face north or west to install the electric central",
        IGUI_Bunker_CentralNeedFacingWall = "You need a matching interior wall on the side you are facing",
        IGUI_Bunker_CentralInstallNeedWall = "You need an interior wall to place the electric central",
        IGUI_Bunker_CentralInstalled = "Electric central installed",
        IGUI_Bunker_CentralAlreadyPresent = "There is already an electric central here",
    },
    ES = {
        IGUI_Bunker_CentralGeneratorConnected = "Central local conectada (generador oculto sin toxicidad)",
        IGUI_Bunker_CentralGeneratorAlreadyConnected = "La central local ya esta conectada",
        IGUI_Bunker_CentralGeneratorOn = "Central local encendida",
        IGUI_Bunker_CentralGeneratorOff = "Central local apagada",
        IGUI_Bunker_CentralGeneratorAlreadyOn = "La central local ya esta encendida",
        IGUI_Bunker_CentralGeneratorAlreadyOff = "La central local ya esta apagada",
        IGUI_Bunker_CentralNeedLinkFirst = "Primero conecta esta central con otra central",
        IGUI_Bunker_CentralNeedWire = "Necesitas %1 cantidad de cable electrico (disponible: %2)",
        IGUI_Bunker_CentralLinkedTo = "Central enlazada a %1, %2, %3",
        IGUI_Bunker_CentralAlreadyLinked = "Estas centrales ya estan enlazadas",
        IGUI_Bunker_NeedElectricityLevel = "Necesitas Electricidad %1 (tienes %2)",
        IGUI_Bunker_CentralUpgradeDisabled = "La ampliacion de la central esta deshabilitada temporalmente",
        IGUI_Bunker_CentralUpgradeMax = "Esta central ya esta al maximo de ampliacion",
        IGUI_Bunker_CentralNeedWiresSimple = "Necesitas %1 cables (tienes %2)",
        IGUI_Bunker_CentralInvalidBattery = "Bateria no valida para esta central",
        IGUI_Bunker_CentralNoCompatibleBattery = "No tienes una bateria compatible para insertar",
        IGUI_Bunker_CentralAlreadyFull = "Esta central ya esta al 100%",
        IGUI_Bunker_CentralNoCompatibleBatteryHeadroom = "No tienes una bateria compatible para insertar sin superar 100%",
        IGUI_Bunker_CentralNoEnergyInsertBattery = "Esta central no tiene energia (0%). Inserta una bateria.",
        IGUI_Bunker_CentralWouldExceed = "No puedes superar 100%% (%1%% + %2%%)",
        IGUI_Bunker_BatteryStateGood = "Buen estado",
        IGUI_Bunker_BatteryStateUsed = "Usada",
        IGUI_Bunker_BatteryStateWorn = "Malgastada",
        IGUI_Bunker_CentralOnlyPrimaryUpgrade = "Solo las centrales principales pueden ampliarse",
        IGUI_Bunker_CentralUpgradeApplied = "Central ampliada: +%1 tiles de radio",
        IGUI_Bunker_CentralOverlay = "Central: %1",
        ContextMenu_ConnectInvisibleGeneratorCentral = "Conectar central electrica local",
        ContextMenu_TurnOnInvisibleGeneratorCentral = "Encender central electrica local",
        ContextMenu_TurnOffInvisibleGeneratorCentral = "Apagar central electrica local",
        ContextMenu_CentralEnergy = "Energia central: %1%%",
        ContextMenu_CentralTimeRemaining = "Tiempo restante: %1",
        ContextMenu_CentralRadius = "Radio central: %1 tiles",
        ContextMenu_CentralUpgradeDisabled = "Ampliar central (temporalmente deshabilitado)",
        ContextMenu_CentralAutoLoadBattery = "Cargar bateria automaticamente",
        ContextMenu_CentralLoadWithBattery = "Cargar central con bateria",
        ContextMenu_CentralInsertBattery = "Insertar %1 (+%2) [%3]",
        ContextMenu_CentralWouldExceed = "Supera 100%% (%1%% + %2%%)",
        ContextMenu_CentralInvalidBattery = "Bateria no valida",
        ContextMenu_CentralRemoveBattery = "Retirar bateria de central",
        ContextMenu_CentralTurnOffToRemoveBattery = "Apaga la central para retirar baterias",
        ContextMenu_CentralRemoveBatteryEntry = "Retirar %1 [%2]",
        ContextMenu_CentralRemoveBatteryScrap = "%1 -> Chatarra",
        ContextMenu_CentralNeedElectricityLevel = "Requiere Electricidad %1 (actual %2)",
        ContextMenu_ConnectToOtherCentral = "Conectar con otra central",
        ContextMenu_ConnectToOtherCentralCoord = "Conectar con otra central: %1, %2, %3",
        ContextMenu_CentralDependsOn = "Esta central depende de: %1",
        ContextMenu_InstallElectricCentral = "Instalar automaticamente hacia el norte (arriba a la derecha)",
        ContextMenu_AutoInstallElectricCentral = "Instalar automaticamente hacia el norte (arriba a la derecha)",
        ContextMenu_PlaceElectricCentral = "Colocar central electrica",
        ContextMenu_CentralRotateNorth = "Colocar hacia el norte",
        ContextMenu_CentralRotateWest = "Colocar hacia el oeste",
        IGUI_Bunker_CentralFaceNorthOrWest = "Mira hacia el norte o el oeste para instalar la central electrica",
        IGUI_Bunker_CentralNeedFacingWall = "Necesitas una pared interior del lado hacia el que estas mirando",
        IGUI_Bunker_CentralInstallNeedWall = "Necesitas una pared interior para colocar la central electrica",
        IGUI_Bunker_CentralInstalled = "Central electrica instalada",
        IGUI_Bunker_CentralAlreadyPresent = "Ya hay una central electrica aqui",
    },
}

local function baFormatText(template, ...)
    local result = tostring(template or "")
    local args = { ... }
    for i = 1, #args do
        result = string.gsub(result, "%%" .. tostring(i), tostring(args[i]))
    end
    return result
end

local function baGetLanguageCode()
    local candidates = {}
    if Translator and Translator.getLanguage then
        local ok, value = pcall(function() return Translator.getLanguage() end)
        if ok and value then table.insert(candidates, value) end
    end
    if getCore then
        local core = getCore()
        if core then
            if core.getOptionLanguageName then
                local ok, value = pcall(function() return core:getOptionLanguageName() end)
                if ok and value then table.insert(candidates, value) end
            end
            if core.getOptionLanguage then
                local ok, value = pcall(function() return core:getOptionLanguage() end)
                if ok and value then table.insert(candidates, value) end
            end
        end
    end

    local function parseLanguage(value)
        local raw = tostring(value or "")
        local lang = string.upper(raw)
        local compact = string.gsub(lang, "[^A-Z_%-]", "")

        if lang == "EN" or lang == "EN_US" or lang == "EN-US" or lang == "EN_GB" or lang == "EN-GB" then
            return "EN"
        end
        if lang == "ENGLISH" or string.find(lang, "ENGLISH", 1, true) == 1 then
            return "EN"
        end
        if string.find(compact, "EN_", 1, true) == 1 or string.find(compact, "EN%-", 1, true) == 1 then
            return "EN"
        end
        for i = 1, #candidates do
            if lang == "SPANISH" or lang == "ES" or lang == "ES_AR" or lang == "ES-AR" or lang == "ES_ES" or lang == "ES-ES" then
                return "ES"
            end
            if string.find(lang, "SPANISH", 1, true) == 1 then
                return "ES"
            end
            if string.find(compact, "ES_", 1, true) == 1 or string.find(compact, "ES%-", 1, true) == 1 then
                return "ES"
            end
        end
        return nil
    end

    for i = 1, #candidates do
        local parsed = parseLanguage(candidates[i])
        if parsed then
            return parsed
        end
    end
    return "EN"
end

local function baText(key, ...)
    local lang = baGetLanguageCode()
    local tableByLang = BA_LOCAL_TEXT[lang] or BA_LOCAL_TEXT.EN
    local template = tableByLang[key] or BA_LOCAL_TEXT.EN[key] or key
    return baFormatText(template, ...)
end
BunkersAnywhere.getCentralUIText = baText

function BunkersAnywhere.isInvisibleCentralSpriteName(spriteName)
    if not spriteName then return false end
local function baCanTransmitGlobalModData()
    return isServer and isServer() or false
end
    if spriteName == BunkersAnywhere.InvisibleCentralGenerator.SpriteName then return true end
    if spriteName == BunkersAnywhere.InvisibleCentralGenerator.SpriteNameAlt then return true end
    if string.match(spriteName, "^location_hospitality_sunstarmotel_01_4[89]$") then return true end
    if string.match(spriteName, "^location_hospitality_sunstarmotel_01_50$") then return true end
    if string.match(spriteName, "^location_business_bank_01_6%d$") then return true end
    if string.match(spriteName, "^location_business_bank_01_7%d$") then return true end
    return false
end

function BunkersAnywhere.isInvisibleCentralTile(obj)
    if not obj or not obj.getSprite then return false end
    local sprite = obj:getSprite()
    if not sprite or not sprite.getName then return false end
    return BunkersAnywhere.isInvisibleCentralSpriteName(sprite:getName())
end

local function isCentralSpriteFamilyName(spriteName)
    if not spriteName then return false end
    if string.match(spriteName, "^location_business_bank_01_") ~= nil then return true end
    if string.match(spriteName, "^location_hospitality_sunstarmotel_01_4[89]$") ~= nil then return true end
    if string.match(spriteName, "^location_hospitality_sunstarmotel_01_50$") ~= nil then return true end
    return false
end

local function setCentralSpriteMoveableProps(spriteName)
    if not spriteName or not getSprite then return end
    local sprite = getSprite(spriteName)
    if not sprite or not sprite.getProperties then return end

    local props = sprite:getProperties()
    if not props or not props.Set then return end

    props:Set("IsMoveAble", "true")
    props:Set("PickUpTool", "Crowbar")
    props:Set("PlaceTool", "Hammer")
    props:Set("PickUpLevel", "3")
    props:Set("PickUpWeight", "40")
    props:Set("MoveType", "WallObject")
    if spriteName == "location_business_bank_01_68" or spriteName == "location_business_bank_01_66" or spriteName == "location_hospitality_sunstarmotel_01_48" or spriteName == "location_hospitality_sunstarmotel_01_49" then
        props:Set("Facing", "W")
    else
        props:Set("Facing", "N")
    end
    props:Set("CustomName", "Electric Central")
    props:Set("GroupName", "Bunker")
end

function BunkersAnywhere.registerCentralMoveableSprites()
    local sprites = {
        "location_business_bank_01_64",
        "location_business_bank_01_65",
        "location_business_bank_01_66",
        "location_business_bank_01_67",
        "location_business_bank_01_68",
        "location_business_bank_01_69",
        "location_business_bank_01_70",
        "location_business_bank_01_71",
        "location_hospitality_sunstarmotel_01_48",
        "location_hospitality_sunstarmotel_01_49",
        "location_hospitality_sunstarmotel_01_50",
    }

    for i = 1, #sprites do
        setCentralSpriteMoveableProps(sprites[i])
    end
end

BunkersAnywhere.registerCentralMoveableSprites()
Events.OnGameStart.Add(BunkersAnywhere.registerCentralMoveableSprites)

local function getCentralPlacementSpriteForSquare(sq)
    if not sq then return nil end
    local objects = sq:getObjects()
    if not objects then return nil end

    local hasWallW = false
    local hasWallN = false
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        local props = obj and obj.getProperties and obj:getProperties() or nil
        if props and props.Is then
            if IsoFlagType and IsoFlagType.WallW then
                local ok, value = pcall(function() return props:Is(IsoFlagType.WallW) end)
                if ok and value then hasWallW = true end
            end
            if IsoFlagType and IsoFlagType.WallN then
                local ok, value = pcall(function() return props:Is(IsoFlagType.WallN) end)
                if ok and value then hasWallN = true end
            end
        end
    end

    if hasWallW then return BunkersAnywhere.InvisibleCentralGenerator.PlacementSpriteNameAlt or BunkersAnywhere.InvisibleCentralGenerator.SpriteNameAlt end
    if hasWallN then return BunkersAnywhere.InvisibleCentralGenerator.PlacementSpriteName or BunkersAnywhere.InvisibleCentralGenerator.SpriteName end
    return nil
end

local function getCentralSquareWallData(sq)
    if not sq then
        return false, false, false
    end

    local objects = sq:getObjects()
    if not objects then
        return false, false, false
    end

    local hasWallW = false
    local hasWallN = false
    local hasCentral = false
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if BunkersAnywhere.isInvisibleCentralTile(obj) then
            hasCentral = true
        end
        local props = obj and obj.getProperties and obj:getProperties() or nil
        if props and props.Is then
            if IsoFlagType and IsoFlagType.WallW then
                local ok, value = pcall(function() return props:Is(IsoFlagType.WallW) end)
                if ok and value then hasWallW = true end
            end
            if IsoFlagType and IsoFlagType.WallN then
                local ok, value = pcall(function() return props:Is(IsoFlagType.WallN) end)
                if ok and value then hasWallN = true end
            end
        end
    end

    return hasWallW, hasWallN, hasCentral
end

local function getCentralPlacementSpriteForPlayerFacing(playerObj, sq)
    if not playerObj or not sq then return nil, "invalid" end
    if sq:getRoom() == nil then return nil, "invalid" end

    local hasWallW, hasWallN, hasCentral = getCentralSquareWallData(sq)
    if hasCentral then
        return nil, "occupied"
    end

    local dir = playerObj.getDir and playerObj:getDir() or nil
    local dirName = dir and tostring(dir) or ""
    if dirName == "W" or dirName == "NW" or dirName == "SW" then
        if hasWallW then
            return BunkersAnywhere.InvisibleCentralGenerator.PlacementSpriteNameAlt or BunkersAnywhere.InvisibleCentralGenerator.SpriteNameAlt, nil
        end
        return nil, "wall"
    end
    if dirName == "N" or dirName == "NW" or dirName == "NE" then
        if hasWallN then
            return BunkersAnywhere.InvisibleCentralGenerator.PlacementSpriteName or BunkersAnywhere.InvisibleCentralGenerator.SpriteName, nil
        end
        return nil, "wall"
    end
    return nil, "facing"
end

local function getCentralPlacementSpriteAutomatic(sq)
    if not sq then return nil, "invalid" end
    if sq:getRoom() == nil then return nil, "invalid" end

    local hasWallW, hasWallN, hasCentral = getCentralSquareWallData(sq)
    if hasCentral then
        return nil, "occupied"
    end
    if hasWallW then
        return BunkersAnywhere.InvisibleCentralGenerator.PlacementSpriteNameAlt or BunkersAnywhere.InvisibleCentralGenerator.SpriteNameAlt, nil
    end
    if hasWallN then
        return BunkersAnywhere.InvisibleCentralGenerator.PlacementSpriteName or BunkersAnywhere.InvisibleCentralGenerator.SpriteName, nil
    end
    return nil, "wall"
end

function BunkersAnywhere.canPlaceElectricCentralOnSquare(sq)
    if not sq then return false, nil end
    if sq:getRoom() == nil then return false, nil end
    local spriteName = getCentralPlacementSpriteForSquare(sq)
    if not spriteName then return false, nil end

    local objects = sq:getObjects()
    if objects then
        for i = 0, objects:size() - 1 do
            local obj = objects:get(i)
            if BunkersAnywhere.isInvisibleCentralTile(obj) then
                return false, nil
            end
        end
    end

    return true, spriteName
end

function BunkersAnywhere.placeElectricCentralOnSquare(item, playerObj, sq)
    if not sq or not item then return end

    local canPlace, spriteName = BunkersAnywhere.canPlaceElectricCentralOnSquare(sq)
    local itemType = item.getType and item:getType() or nil
    if itemType == "ElectricCentralNorth" then
        spriteName = BunkersAnywhere.InvisibleCentralGenerator.PlacementSpriteName or spriteName
    elseif itemType == "ElectricCentral" then
        spriteName = BunkersAnywhere.InvisibleCentralGenerator.PlacementSpriteNameAlt or spriteName
    end
    if not canPlace or not spriteName then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralInstallNeedWall"), 255, 80, 80, 380)
        return
    end

    local obj = sq:addTileObject(spriteName)
    if not obj then return end

    local md = obj:getModData()
    md.baIsElectricCentral = true
    md.baInvisibleGeneratorConnected = false
    md.baInvisibleGeneratorIsSource = false
    md.baInvisibleGeneratorLocalOn = false
    md.baCentralEnergyPercent = 0

    if isClient() and obj.transmitCompleteItemToServer then
        obj:transmitCompleteItemToServer()
    end

    playerObj:getInventory():Remove(item)
    playerObj:setHaloNote(baText("IGUI_Bunker_CentralInstalled"), 0, 255, 100, 320)
end

function BunkersAnywhere.placeElectricCentral(item, playerObj)
    local sq = playerObj and playerObj.getSquare and playerObj:getSquare() or nil
    return BunkersAnywhere.placeElectricCentralOnSquare(item, playerObj, sq)
end

local function getCentralPlacementSpriteFromItem(item)
    local itemType = item and item.getType and item:getType() or nil
    if itemType == "ElectricCentral" then
        return BunkersAnywhere.InvisibleCentralGenerator.PlacementSpriteNameAlt
            or BunkersAnywhere.InvisibleCentralGenerator.SpriteNameAlt
    end
    return BunkersAnywhere.InvisibleCentralGenerator.PlacementSpriteName
        or BunkersAnywhere.InvisibleCentralGenerator.SpriteName
end

local function getCentralForwardSquare(playerObj)
    if not playerObj or not playerObj.getSquare then return nil end
    return playerObj:getSquare()
end

local function forcePlaceElectricCentral(item, playerObj)
    local sq = getCentralForwardSquare(playerObj)
    local spriteName = getCentralPlacementSpriteFromItem(item)
    if not sq or not item or not playerObj or not spriteName then return end

    local objects = sq:getObjects()
    if objects then
        for i = 0, objects:size() - 1 do
            local obj = objects:get(i)
            if BunkersAnywhere.isInvisibleCentralTile(obj) then
                playerObj:setHaloNote(baText("IGUI_Bunker_CentralAlreadyPresent"), 255, 120, 0, 320)
                return
            end
        end
    end

    local obj = sq:addTileObject(spriteName)
    if not obj then return end

    local md = obj:getModData()
    md.baIsElectricCentral = true
    md.baInvisibleGeneratorConnected = false
    md.baInvisibleGeneratorIsSource = false
    md.baInvisibleGeneratorLocalOn = false
    md.baCentralEnergyPercent = 0

    if isClient() and obj.transmitCompleteItemToServer then
        obj:transmitCompleteItemToServer()
    end

    playerObj:getInventory():Remove(item)
    playerObj:setHaloNote(baText("IGUI_Bunker_CentralInstalled"), 0, 255, 100, 320)
end

function BunkersAnywhere.swapCentralMoveableOrientation(item, playerObj, targetFullType)
    if not item or not playerObj or not targetFullType then return end
    local inv = playerObj:getInventory()
    if not inv then return end

    local currentFullType = item.getFullType and item:getFullType() or nil
    if currentFullType == targetFullType then return end

    inv:Remove(item)
    local newItem = inv:AddItem(targetFullType)
    if not newItem and currentFullType then
        inv:AddItem(currentFullType)
        return
    end
end

function BunkersAnywhere.onInstallElectricCentralHere(item, playerObj)
    local sq = playerObj and playerObj.getSquare and playerObj:getSquare() or nil
    if not sq or not item then return end
    ISTimedActionQueue.add(ISBunkerAction:new(playerObj, sq, 140, "Loot", "LightSwitch", forcePlaceElectricCentral, item, playerObj))
end

function BunkersAnywhere.installElectricCentralFacing(item, playerObj)
    return BunkersAnywhere.installElectricCentralAutomatic(item, playerObj)
end

function BunkersAnywhere.onInstallElectricCentralFacing(item, playerObj)
    local sq = playerObj and playerObj.getSquare and playerObj:getSquare() or nil
    if not sq or not item then return end
    ISTimedActionQueue.add(ISBunkerAction:new(playerObj, sq, 140, "Loot", "LightSwitch", BunkersAnywhere.installElectricCentralFacing, item, playerObj))
end

function BunkersAnywhere.installElectricCentralAutomatic(item, playerObj)
    return forcePlaceElectricCentral(item, playerObj)
end

function BunkersAnywhere.onInstallElectricCentralAutomatic(item, playerObj)
    local sq = playerObj and playerObj.getSquare and playerObj:getSquare() or nil
    if not sq or not item then return end
    ISTimedActionQueue.add(ISBunkerAction:new(playerObj, sq, 140, "Loot", "LightSwitch", BunkersAnywhere.installElectricCentralAutomatic, item, playerObj))
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

function BunkersAnywhere.getShortTypeFromFullType(fullType)
    if not fullType then return nil end
    local dot = string.find(fullType, "%.")
    if not dot then return fullType end
    return string.sub(fullType, dot + 1)
end

function BunkersAnywhere.getCentralBatteryCharge(fullType)
    if not fullType then return 0 end
    local charge = BunkersAnywhere.CentralBattery.ChargeByType[fullType]
    if charge then
        return math.floor(tonumber(charge) or 0)
    end
    local shortType = BunkersAnywhere.getShortTypeFromFullType(fullType)
    if not shortType then return 0 end
    for key, value in pairs(BunkersAnywhere.CentralBattery.ChargeByType) do
        if BunkersAnywhere.getShortTypeFromFullType(key) == shortType then
            return math.floor(tonumber(value) or 0)
        end
    end

    -- Fallback for modded batteries with same naming family.
    if shortType == "CarBattery" then return 15 end
    if shortType == "CarBattery1" then return 29 end
    if shortType == "CarBattery2" then return 29 end
    if shortType == "CarBattery3" then return 100 end
    return 0
end

function BunkersAnywhere.getCentralBatteryRuntimeMinutes(fullType)
    if not fullType then return 0 end
    local runtime = BunkersAnywhere.CentralBattery.RuntimeMinutesByType[fullType]
    if runtime then
        return math.max(0, math.floor(tonumber(runtime) or 0))
    end

    local shortType = BunkersAnywhere.getShortTypeFromFullType(fullType)
    if shortType then
        for key, value in pairs(BunkersAnywhere.CentralBattery.RuntimeMinutesByType) do
            if BunkersAnywhere.getShortTypeFromFullType(key) == shortType then
                return math.max(0, math.floor(tonumber(value) or 0))
            end
        end
    end

    return 0
end

function BunkersAnywhere.getCentralEnergyPercent(node, modData)
    local energy = 0
    if node and node.energy ~= nil then
        energy = tonumber(node.energy) or energy
    end
    if modData and modData.baCentralEnergyPercent ~= nil then
        energy = tonumber(modData.baCentralEnergyPercent) or energy
    end
    energy = math.floor(energy or 0)
    if energy < 0 then energy = 0 end
    if energy > BunkersAnywhere.CentralBattery.MaxEnergy then
        energy = BunkersAnywhere.CentralBattery.MaxEnergy
    end
    return energy
end

function BunkersAnywhere.getCentralRadiusBonus(node, modData)
    local bonus = 0
    if node and node.radiusBonus ~= nil then
        bonus = tonumber(node.radiusBonus) or bonus
    end
    if modData and modData.baCentralRadiusBonus ~= nil then
        bonus = tonumber(modData.baCentralRadiusBonus) or bonus
    end
    bonus = math.floor(bonus or 0)
    if bonus < 0 then bonus = 0 end
    local maxBonus = BunkersAnywhere.getMaxCentralRadiusUpgradeBonus()
    if bonus > maxBonus then
        bonus = maxBonus
    end
    return bonus
end

function BunkersAnywhere.getCentralRadiusUpgradeTiers()
    local cfg = BunkersAnywhere.InvisibleCentralGenerator or {}
    local bonuses = cfg.RadiusUpgradeBonuses or {}
    local costs = cfg.RadiusUpgradeWireCosts or {}
    local tiers = {}
    for i = 1, #bonuses do
        local bonus = math.floor(tonumber(bonuses[i]) or 0)
        if bonus > 0 then
            local cost = math.max(1, math.floor(tonumber(costs[i]) or cfg.RadiusUpgradeWireCost or 50))
            table.insert(tiers, { bonus = bonus, cost = cost })
        end
    end
    table.sort(tiers, function(a, b) return a.bonus < b.bonus end)
    return tiers
end

function BunkersAnywhere.getMaxCentralRadiusUpgradeBonus()
    local tiers = BunkersAnywhere.getCentralRadiusUpgradeTiers()
    if #tiers <= 0 then
        return math.max(0, math.floor(tonumber(BunkersAnywhere.InvisibleCentralGenerator.RadiusUpgradeBonus) or 0))
    end
    return tiers[#tiers].bonus
end

function BunkersAnywhere.getNextCentralRadiusUpgrade(currentBonus)
    local current = math.max(0, math.floor(tonumber(currentBonus) or 0))
    local tiers = BunkersAnywhere.getCentralRadiusUpgradeTiers()
    for i = 1, #tiers do
        if tiers[i].bonus > current then
            return tiers[i].bonus, tiers[i].cost
        end
    end
    return nil, nil
end

function BunkersAnywhere.getCentralRemainingMinutes(node, modData)
    local runtime = nil
    if node and node.runtimeMinutes ~= nil then
        runtime = tonumber(node.runtimeMinutes)
    end
    if runtime == nil and modData and modData.baCentralRuntimeMinutes ~= nil then
        runtime = tonumber(modData.baCentralRuntimeMinutes)
    end
    if runtime == nil then
        local maxRuntime = math.floor(tonumber(BunkersAnywhere.CentralBattery.MaxRuntimeMinutes) or 0)
        if maxRuntime > 0 then
            runtime = math.floor((BunkersAnywhere.getCentralEnergyPercent(node, modData) / BunkersAnywhere.CentralBattery.MaxEnergy) * maxRuntime)
        else
            runtime = BunkersAnywhere.getCentralEnergyPercent(node, modData) * (tonumber(BunkersAnywhere.CentralBattery.MinutesPerPercent) or 4)
        end
    end
    runtime = math.floor(runtime or 0)
    if runtime < 0 then runtime = 0 end
    return runtime
end

function BunkersAnywhere.getCentralRemainingMinutesDisplay(node, modData, nodeKey)
    return BunkersAnywhere.getCentralRemainingMinutes(node, modData)
end

function BunkersAnywhere.formatCentralRemainingMinutes(minutes)
    local m = math.floor(tonumber(minutes) or 0)
    if m < 0 then m = 0 end
    local h = math.floor(m / 60)
    local rem = m % 60
    if h > 0 then
        return tostring(h) .. "h " .. tostring(rem) .. "m"
    end
    return tostring(rem) .. "m"
end

function BunkersAnywhere.formatCentralRemainingTime(minutes)
    return BunkersAnywhere.formatCentralRemainingMinutes(minutes)
end

function BunkersAnywhere.countBatteryTypeAvailable(playerObj, fullType)
    local shortType = BunkersAnywhere.getShortTypeFromFullType(fullType)
    if not shortType then return 0 end
    local inv = playerObj:getInventory()
    if not inv then return 0 end
    local total = 0

    local function scan(container)
        if not container then return end
        local items = container:getItems()
        if not items or not items.size then return end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item then
                local t = item:getType()
                local ft = item:getFullType()
                if t == shortType or ft == fullType then
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
    return total
end

function BunkersAnywhere.getCentralBatteryDefsOrdered()
    return {
        { shortType = "CarBattery3", fullType = "Base.CarBattery3" },
        { shortType = "CarBattery2", fullType = "Base.CarBattery2" },
        { shortType = "CarBattery1", fullType = "Base.CarBattery1" },
        { shortType = "CarBattery",  fullType = "Base.CarBattery"  },
    }
end

function BunkersAnywhere.getCentralBatteryDefByRequest(requestedFullType)
    local requestedShort = BunkersAnywhere.getShortTypeFromFullType(requestedFullType)
    if not requestedShort then return nil end
    for _, def in ipairs(BunkersAnywhere.getCentralBatteryDefsOrdered()) do
        if requestedFullType == def.fullType or requestedShort == def.shortType then
            return def
        end
    end
    return nil
end

function BunkersAnywhere.getCentralBatteryUseLabel(uses)
    local n = math.floor(tonumber(uses) or 1)
    if n <= 1 then return baText("IGUI_Bunker_BatteryStateGood") end
    if n == 2 then return baText("IGUI_Bunker_BatteryStateUsed") end
    return baText("IGUI_Bunker_BatteryStateWorn")
end

function BunkersAnywhere.getInstalledCentralBatteriesForMenu(currentNode, modData)
    local fromNode = currentNode and currentNode.installedBatteries
    if fromNode and #fromNode > 0 then
        return fromNode
    end
    local fromMd = modData and modData.baCentralInstalledBatteries
    if fromMd and #fromMd > 0 then
        return fromMd
    end
    return nil
end

function BunkersAnywhere.applyCentralBatteryMetadata(item, uses)
    if not item then return end
    local n = math.floor(tonumber(uses) or 1)
    if n < 1 then n = 1 end
    if n > BunkersAnywhere.CentralBattery.MaxUses then
        n = BunkersAnywhere.CentralBattery.MaxUses
    end
    local md = item:getModData()
    md.baCentralBatteryUses = n
    local short = BunkersAnywhere.getShortTypeFromFullType(item:getFullType()) or item:getType() or "CarBattery"
    if item.setName then
        item:setName(tostring(short) .. " (" .. tostring(BunkersAnywhere.getCentralBatteryUseLabel(n)) .. ")")
    end
end

function BunkersAnywhere.onServerCentralBatteryPayout(args)
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end
    local inv = playerObj:getInventory()
    if not inv then return end

    local mode = tostring(args and args.mode or "")
    local fullType = tostring(args and args.fullType or "")
    local uses = math.floor(tonumber(args and args.uses or 1) or 1)

    if mode == "battery" then
        local t = (fullType ~= "" and fullType) or "Base.CarBattery"
        local item = inv:AddItem(t)
        if item then
            BunkersAnywhere.applyCentralBatteryMetadata(item, uses)
        end
    elseif mode == "scrap" then
        local t = (fullType ~= "" and fullType) or "Base.ElectronicsScrap"
        local item = inv:AddItem(t)
        if not item then
            item = inv:AddItem("Base.ScrapElectronics")
        end
        if not item then
            inv:AddItem("Base.ElectronicsScrap")
        end
    end
end

function BunkersAnywhere.getBatteryItemFromInventoryByDef(inv, def)
    if not inv or not def then return nil end
    return inv:getItemFromTypeRecurse(def.fullType) or inv:getItemFromTypeRecurse(def.shortType)
end

function BunkersAnywhere.consumeCentralBatteryFromPlayerInventory(playerObj, requestedFullType, maxCharge)
    if not playerObj then return nil, 0, 0 end
    local inv = playerObj:getInventory()
    if not inv then return nil, 0, 0 end

    local requestedIsAuto = (requestedFullType == nil or requestedFullType == "" or requestedFullType == "AUTO")
    local selected = nil
    local allowedMax = math.floor(tonumber(maxCharge) or BunkersAnywhere.CentralBattery.MaxEnergy)
    if allowedMax < 0 then allowedMax = 0 end

    if requestedIsAuto then
        for _, def in ipairs(BunkersAnywhere.getCentralBatteryDefsOrdered()) do
            local defCharge = BunkersAnywhere.getCentralBatteryCharge(def.fullType)
            if defCharge > 0 and defCharge <= allowedMax and BunkersAnywhere.countBatteryTypeAvailable(playerObj, def.fullType) > 0 then
                selected = def
                break
            end
        end
    else
        selected = BunkersAnywhere.getCentralBatteryDefByRequest(requestedFullType)
        if selected and BunkersAnywhere.countBatteryTypeAvailable(playerObj, selected.fullType) <= 0 then
            selected = nil
        end
    end

    if not selected then return nil, 0, 0 end
    local charge = BunkersAnywhere.getCentralBatteryCharge(selected.fullType)
    if charge <= 0 or charge > allowedMax then return nil, 0, 0 end

    local item = BunkersAnywhere.getBatteryItemFromInventoryByDef(inv, selected)
    if not item then return nil, 0, 0 end

    local itemFullType = item:getFullType() or selected.fullType
    local itemMd = item:getModData()
    local usesBefore = itemMd and math.floor(tonumber(itemMd.baCentralBatteryUses) or 0) or 0
    if usesBefore < 0 then usesBefore = 0 end
    local usesAfter = usesBefore + 1
    if usesAfter > BunkersAnywhere.CentralBattery.MaxUses then
        usesAfter = BunkersAnywhere.CentralBattery.MaxUses
    end

    local container = item:getContainer()
    if not container then return nil, 0, 0 end

    if container.DoRemoveItem then
        container:DoRemoveItem(item)
    else
        container:Remove(item)
    end

    return itemFullType, charge, usesAfter
end

function BunkersAnywhere.debugLogBatteryInventoryClient(playerObj, reason)
    if not playerObj then return end
    if getTimestampMs then
        local now = getTimestampMs()
        local last = BunkersAnywhere._lastClientInvDebugMs or 0
        if now - last < 1200 then
            return
        end
        BunkersAnywhere._lastClientInvDebugMs = now
    end
    local inv = playerObj:getInventory()
    if not inv then return end

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
    local username = (playerObj.getUsername and playerObj:getUsername()) or "unknown"
    print("[BunkersAnywhere][ClientInvDebug] reason=" .. tostring(reason or "context") .. " user=" .. tostring(username) .. " batteryItems=" .. tostring(total))

    local keys = {}
    for k, _ in pairs(summary) do
        table.insert(keys, k)
    end
    table.sort(keys)
    if #keys == 0 then
        print("[BunkersAnywhere][ClientInvDebug] no battery-like items found in player inventory")
    else
        for _, k in ipairs(keys) do
            local sep = string.find(k, "|", 1, true)
            local ft = sep and string.sub(k, 1, sep - 1) or k
            local t = sep and string.sub(k, sep + 1) or "?"
            print("[BunkersAnywhere][ClientInvDebug] item fullType=" .. tostring(ft) .. " type=" .. tostring(t) .. " count=" .. tostring(summary[k]))
        end
    end
end

function BunkersAnywhere.getPlayerElectricityLevel(playerObj)
    if not playerObj or not playerObj.getPerkLevel then return 0 end
    if not Perks or not Perks.Electricity then return 0 end
    local ok, level = pcall(function()
        return playerObj:getPerkLevel(Perks.Electricity)
    end)
    if not ok then return 0 end
    return math.floor(tonumber(level) or 0)
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

local function hasOwnedInvisibleGeneratorNearPlayer(playerObj, radius)
    local sq = playerObj and playerObj:getSquare()
    if not sq then return false end
    local cell = getCell()
    if not cell then return false end
    local r = radius or 1
    local px, py, pz = sq:getX(), sq:getY(), sq:getZ()
    for x = px - r, px + r do
        for y = py - r, py + r do
            local s = cell:getGridSquare(x, y, pz)
            if s then
                local g = s:getGenerator()
                if g and BunkersAnywhere.isOwnedInvisibleGenerator(g) then
                    return true
                end
            end
        end
    end
    return false
end

function BunkersAnywhere.refreshOwnedInvisibleGenerators()
    local cell = getCell()
    if not cell then return end

    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    if not store or not store.nodes then return end

    for _, node in pairs(store.nodes) do
        if node then
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

    if BunkersAnywhere.isInvisibleGeneratorConnected(centralObj) then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralGeneratorAlreadyConnected"), 240, 240, 0, 300)
        return
    end
    local elecLevel = BunkersAnywhere.getPlayerElectricityLevel(playerObj)
    local needLevel = BunkersAnywhere.CentralSkill.MinElectricityToConnect
    if elecLevel < needLevel then
        playerObj:setHaloNote(baText("IGUI_Bunker_NeedElectricityLevel", tostring(needLevel), tostring(elecLevel)), 255, 120, 0, 380)
        return
    end

    local md = centralObj:getModData()
    md.baInvisibleGeneratorConnected = true
    md.baInvisibleGeneratorIsSource = true
    md.baInvisibleGeneratorOn = false
    md.baInvisibleGeneratorLocalOn = false
    md.baCentralEnergyPercent = 0
    if centralObj.transmitModData then
        centralObj:transmitModData()
    end

    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    store.nodes[key] = store.nodes[key] or { x = sq:getX(), y = sq:getY(), z = sq:getZ(), active = false, source = true, links = {}, energy = 0, radiusBonus = 0, installedBatteries = {} }
    store.nodes[key].energy = BunkersAnywhere.getCentralEnergyPercent(store.nodes[key], nil)
    store.nodes[key].active = store.nodes[key].energy > 0
    store.nodes[key].source = true
    if baCanTransmitGlobalModData() and ModData.transmit then
        ModData.transmit(BunkersAnywhere.InvisibleCentralGenerator.DataKey)
    end

    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "ConnectInvisibleGeneratorCentral", {
            x = sq:getX(),
            y = sq:getY(),
            z = sq:getZ(),
        })
    end

    playerObj:setHaloNote(baText("IGUI_Bunker_CentralGeneratorConnected"), 0, 255, 100, 350)
end

function BunkersAnywhere.registerInvisibleGeneratorCentralCandidate(centralObj)
    local sq = centralObj and centralObj:getSquare()
    if not sq then return end
    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    if not (store.nodes and store.nodes[key]) then
        store.nodes[key] = { x = sq:getX(), y = sq:getY(), z = sq:getZ(), active = true, source = false, links = {}, energy = 0, radiusBonus = 0, installedBatteries = {} }
        if baCanTransmitGlobalModData() and ModData.transmit then
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

    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local elecLevel = BunkersAnywhere.getPlayerElectricityLevel(playerObj)
    local needLevel = BunkersAnywhere.CentralSkill.MinElectricityToConnect
    if elecLevel < needLevel then
        playerObj:setHaloNote(baText("IGUI_Bunker_NeedElectricityLevel", tostring(needLevel), tostring(elecLevel)), 255, 120, 0, 380)
        return
    end
    local keyA = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    local keyB = BunkersAnywhere.getInvisibleGeneratorNodeKey(targetX, targetY, targetZ)
    local nodeA = store.nodes and store.nodes[keyA] or nil
    if nodeA and nodeA.links and nodeA.links[keyB] == true then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralAlreadyLinked"), 240, 220, 80, 350)
        return
    end

    local need = BunkersAnywhere.getWireDistanceCost(sq, targetX, targetY)
    local available = BunkersAnywhere.countElectricWireAvailable(playerObj)
    if available < need then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralNeedWire", tostring(need), tostring(available)), 255, 80, 80, 400)
        return
    end

    if not BunkersAnywhere.consumeElectricWire(playerObj, need) then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralNeedWire", tostring(need), tostring(available)), 255, 80, 80, 400)
        return
    end

    BunkersAnywhere.linkInvisibleGeneratorNodes(store, keyA, keyB)
    if baCanTransmitGlobalModData() and ModData.transmit then
        ModData.transmit(BunkersAnywhere.InvisibleCentralGenerator.DataKey)
    end
    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "LinkInvisibleGeneratorCentrals", {
            ax = sq:getX(), ay = sq:getY(), az = sq:getZ(),
            bx = targetX, by = targetY, bz = targetZ,
        })
    end

    playerObj:setHaloNote(baText("IGUI_Bunker_CentralLinkedTo", tostring(targetX), tostring(targetY), tostring(targetZ)), 0, 220, 255, 400)
end

function BunkersAnywhere.upgradeCentralRadius(centralObj, playerObj)
    if BunkersAnywhere.InvisibleCentralGenerator.RadiusUpgradeEnabled ~= true then
        if playerObj and playerObj.setHaloNote then
            playerObj:setHaloNote(baText("IGUI_Bunker_CentralUpgradeDisabled"), 255, 180, 80, 450)
        end
        return
    end

    local sq = centralObj and centralObj:getSquare()
    if not sq then return end

    local md = centralObj:getModData()
    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    local node = store.nodes and store.nodes[key] or nil
    local isSource = (node and node.source ~= false) or (md and md.baInvisibleGeneratorIsSource == true)
    if not isSource then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralOnlyPrimaryUpgrade"), 255, 120, 0, 340)
        return
    end

    local currentBonus = BunkersAnywhere.getCentralRadiusBonus(node, md)
    local nextBonus, need = BunkersAnywhere.getNextCentralRadiusUpgrade(currentBonus)
    if not nextBonus then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralUpgradeMax"), 240, 220, 80, 340)
        return
    end

    local available = BunkersAnywhere.countElectricWireAvailable(playerObj)
    if available < need then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralNeedWiresSimple", tostring(need), tostring(available)), 255, 80, 80, 420)
        return
    end

    if not BunkersAnywhere.consumeElectricWire(playerObj, need) then
        playerObj:setHaloNote("No se pudieron consumir los cables necesarios", 255, 80, 80, 350)
        return
    end

    local newBonus = nextBonus
    if node then
        node.radiusBonus = newBonus
    end
    md.baCentralRadiusBonus = newBonus
    md.baCentralRadius = BunkersAnywhere.InvisibleCentralGenerator.BaseRadius + newBonus
    if centralObj.transmitModData then
        centralObj:transmitModData()
    end
    if baCanTransmitGlobalModData() and ModData.transmit then
        ModData.transmit(BunkersAnywhere.InvisibleCentralGenerator.DataKey)
    end

    if sendClientCommand then
        sendClientCommand("BunkersAnywhere", "UpgradeCentralRadius", {
            x = sq:getX(),
            y = sq:getY(),
            z = sq:getZ(),
            clientConsumed = true,
            wires = need,
            bonus = newBonus,
            onlineID = playerObj.getOnlineID and playerObj:getOnlineID() or -1,
            username = playerObj.getUsername and playerObj:getUsername() or "",
        })
    end

    playerObj:setHaloNote(baText("IGUI_Bunker_CentralUpgradeApplied", tostring(newBonus)), 0, 220, 255, 420)
end

function BunkersAnywhere.insertCentralBattery(centralObj, playerObj, fullType)
    local sq = centralObj and centralObj:getSquare()
    if not sq then return end
    if not sendClientCommand then return end
    local md = centralObj:getModData()
    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    local node = store.nodes and store.nodes[key] or nil
    local energy = BunkersAnywhere.getCentralEnergyPercent(node, md)
    local charge = BunkersAnywhere.getCentralBatteryCharge(fullType)
    if charge <= 0 then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralInvalidBattery"), 255, 120, 0, 300)
        return
    end
    if energy + charge > BunkersAnywhere.CentralBattery.MaxEnergy then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralWouldExceed", tostring(energy), tostring(charge)), 255, 120, 0, 380)
        return
    end
    local consumedFullType, consumedCharge, consumedUses = BunkersAnywhere.consumeCentralBatteryFromPlayerInventory(playerObj, fullType, BunkersAnywhere.CentralBattery.MaxEnergy - energy)
    if not consumedFullType or consumedCharge <= 0 then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralNoCompatibleBattery"), 255, 120, 0, 320)
        return
    end

    sendClientCommand("BunkersAnywhere", "InsertCentralBattery", {
        x = sq:getX(),
        y = sq:getY(),
        z = sq:getZ(),
        fullType = consumedFullType,
        charge = consumedCharge,
        batteryUses = consumedUses,
        clientConsumed = true,
        onlineID = playerObj.getOnlineID and playerObj:getOnlineID() or -1,
        username = playerObj.getUsername and playerObj:getUsername() or "",
    })
end

function BunkersAnywhere.insertAnyCentralBattery(centralObj, playerObj)
    local sq = centralObj and centralObj:getSquare()
    if not sq or not sendClientCommand then return end

    local md = centralObj:getModData()
    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    local node = store.nodes and store.nodes[key] or nil
    local energy = BunkersAnywhere.getCentralEnergyPercent(node, md)
    local headroom = BunkersAnywhere.CentralBattery.MaxEnergy - energy
    if headroom <= 0 then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralAlreadyFull"), 255, 180, 120, 280)
        return
    end

    local consumedFullType, consumedCharge, consumedUses = BunkersAnywhere.consumeCentralBatteryFromPlayerInventory(playerObj, "AUTO", headroom)
    if not consumedFullType or consumedCharge <= 0 then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralNoCompatibleBatteryHeadroom"), 255, 120, 0, 350)
        return
    end

    sendClientCommand("BunkersAnywhere", "InsertCentralBattery", {
        x = sq:getX(),
        y = sq:getY(),
        z = sq:getZ(),
        fullType = consumedFullType,
        charge = consumedCharge,
        batteryUses = consumedUses,
        clientConsumed = true,
        onlineID = playerObj.getOnlineID and playerObj:getOnlineID() or -1,
        username = playerObj.getUsername and playerObj:getUsername() or "",
    })
end

function BunkersAnywhere.removeCentralBattery(centralObj, playerObj, batteryIndex)
    local sq = centralObj and centralObj:getSquare()
    if not sq or not sendClientCommand then return end
    sendClientCommand("BunkersAnywhere", "RemoveCentralBattery", {
        x = sq:getX(),
        y = sq:getY(),
        z = sq:getZ(),
        batteryIndex = tonumber(batteryIndex) or -1,
        onlineID = playerObj.getOnlineID and playerObj:getOnlineID() or -1,
        username = playerObj.getUsername and playerObj:getUsername() or "",
    })
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

    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
    local node = store.nodes and store.nodes[key] or nil
    local md = centralObj:getModData()
    local isConnected = (node ~= nil) or (md and md.baInvisibleGeneratorConnected == true)
    if not isConnected then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralNeedLinkFirst"), 255, 120, 0, 350)
        return
    end
    local isSource = (node and node.source ~= false) or (md and md.baInvisibleGeneratorIsSource == true)
    local energy = BunkersAnywhere.getCentralEnergyPercent(node, md)
    if wantOn and isSource and energy <= 0 then
        playerObj:setHaloNote(baText("IGUI_Bunker_CentralNoEnergyInsertBattery"), 255, 120, 0, 350)
        return
    end
    local current = (node and node.active == true) or (md and md.baInvisibleGeneratorLocalOn == true) or false
    if current == wantOn then
        local key = wantOn and "IGUI_Bunker_CentralGeneratorAlreadyOn" or "IGUI_Bunker_CentralGeneratorAlreadyOff"
        playerObj:setHaloNote(baText(key), 240, 240, 0, 300)
        return
    end

    md.baInvisibleGeneratorLocalOn = wantOn
    if centralObj.transmitModData then
        centralObj:transmitModData()
    end

    if store.nodes[key] then
        store.nodes[key].active = wantOn
        if baCanTransmitGlobalModData() and ModData.transmit then
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
    playerObj:setHaloNote(baText(textKey), r, g, b, 350)
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

function BunkersAnywhere.onUpgradeCentralRadius(centralObj, playerObj)
    if BunkersAnywhere.InvisibleCentralGenerator.RadiusUpgradeEnabled ~= true then
        if playerObj and playerObj.setHaloNote then
            playerObj:setHaloNote(baText("IGUI_Bunker_CentralUpgradeDisabled"), 255, 180, 80, 450)
        end
        return
    end

    if luautils.walk(playerObj, centralObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, centralObj:getSquare(), 190, "Loot", "LightSwitch", BunkersAnywhere.upgradeCentralRadius, centralObj, playerObj))
    else
        BunkersAnywhere.upgradeCentralRadius(centralObj, playerObj)
    end
end

function BunkersAnywhere.onInsertCentralBattery(centralObj, playerObj, fullType)
    if luautils.walk(playerObj, centralObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, centralObj:getSquare(), 85, "Loot", "LightSwitch", BunkersAnywhere.insertCentralBattery, centralObj, playerObj, fullType))
    else
        -- Fallback for MP/pathing oddities near hidden generator tiles.
        BunkersAnywhere.insertCentralBattery(centralObj, playerObj, fullType)
    end
end

function BunkersAnywhere.onInsertAnyCentralBattery(centralObj, playerObj)
    if luautils.walk(playerObj, centralObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, centralObj:getSquare(), 85, "Loot", "LightSwitch", BunkersAnywhere.insertAnyCentralBattery, centralObj, playerObj))
    else
        BunkersAnywhere.insertAnyCentralBattery(centralObj, playerObj)
    end
end

function BunkersAnywhere.onRemoveCentralBattery(centralObj, playerObj, batteryIndex)
    if luautils.walk(playerObj, centralObj:getSquare()) then
        ISTimedActionQueue.add(ISBunkerAction:new(playerObj, centralObj:getSquare(), 80, "Loot", "LightSwitch", BunkersAnywhere.removeCentralBattery, centralObj, playerObj, batteryIndex))
    else
        BunkersAnywhere.removeCentralBattery(centralObj, playerObj, batteryIndex)
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
    local centralWestItem = nil
    local centralNorthItem = nil

    for _, itemGroup in ipairs(items) do
        local testItem = itemGroup
        if not instanceof(itemGroup, "InventoryItem") then
            testItem = itemGroup.items and itemGroup.items[1] or nil
        end
        local fullType = testItem and testItem.getFullType and testItem:getFullType() or nil
        if fullType == "Base.ElectricCentral" then
            centralWestItem = testItem
        elseif fullType == "Base.ElectricCentralNorth" then
            centralNorthItem = testItem
        end
    end

    if centralWestItem then
        context:addOption(baText("ContextMenu_AutoInstallElectricCentral"), centralWestItem, BunkersAnywhere.onInstallElectricCentralAutomatic, playerObj)
        context:addOption(baText("ContextMenu_CentralRotateNorth"), centralWestItem, BunkersAnywhere.swapCentralMoveableOrientation, playerObj, "Base.ElectricCentralNorth")
    elseif centralNorthItem then
        context:addOption(baText("ContextMenu_AutoInstallElectricCentral"), centralNorthItem, BunkersAnywhere.onInstallElectricCentralAutomatic, playerObj)
        context:addOption(baText("ContextMenu_CentralRotateWest"), centralNorthItem, BunkersAnywhere.swapCentralMoveableOrientation, playerObj, "Base.ElectricCentral")
    end

    if mailObj then
        context:addOption(getText("ContextMenu_DepositToShippingMailbox"), items, BunkersAnywhere.onDepositSelectedItemsToMailbox, playerObj, mailObj)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(BunkersAnywhereCentralInventoryContext)

local function BunkersAnywhereCentralWorldContext(player, context, worldobjects, test)
    if not worldobjects then return end
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local storeSnapshot = BunkersAnywhere.getInvisibleGeneratorStore()
    local function hasNodeOnSquare(sq)
        if not sq or not storeSnapshot or not storeSnapshot.nodes then return false end
        local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(sq:getX(), sq:getY(), sq:getZ())
        return storeSnapshot.nodes[key] ~= nil
    end

    local centralObj = nil
    local mailObj = nil
    local firstSq = nil
    local function scanSquareObjects(sq)
        if not sq then return end
        if not firstSq then firstSq = sq end
        local objects = sq:getObjects()
        if not objects then return end
        for i = 0, objects:size() - 1 do
            local obj = objects:get(i)
            if not centralObj then
                local isCentral = BunkersAnywhere.isInvisibleCentralTile(obj)
                if not isCentral and hasNodeOnSquare(sq) then
                    local md = obj and obj.getModData and obj:getModData() or nil
                    if md and (md.baInvisibleGeneratorConnected ~= nil or md.baInvisibleGeneratorIsSource ~= nil or md.baCentralEnergyPercent ~= nil) then
                        isCentral = true
                    end
                end
                if not isCentral and hasNodeOnSquare(sq) and obj and obj.getSprite then
                    local sprite = obj:getSprite()
                    local sname = sprite and sprite.getName and sprite:getName() or nil
                    if isCentralSpriteFamilyName(sname) then
                        isCentral = true
                    end
                end
                if isCentral then
                    centralObj = obj
                end
            end
            if not mailObj and BunkersAnywhere.isShippingMailboxTile(obj) then
                mailObj = obj
            end
        end
    end

    if worldobjects.size and worldobjects.get then
        for i = 0, worldobjects:size() - 1 do
            local wo = worldobjects:get(i)
            local sq = wo and wo.getSquare and wo:getSquare() or nil
            scanSquareObjects(sq)
            if centralObj and mailObj then break end
        end
    else
        for _, wo in ipairs(worldobjects) do
            local sq = wo and wo.getSquare and wo:getSquare() or nil
            scanSquareObjects(sq)
            if centralObj and mailObj then break end
        end
    end

    if not centralObj or not mailObj then
        scanSquareObjects(playerObj:getSquare())
    end

    if not centralObj then
        local pSq = playerObj:getSquare()
        if pSq then
            for dx = -1, 1 do
                for dy = -1, 1 do
                    local sq = getCell():getGridSquare(pSq:getX() + dx, pSq:getY() + dy, pSq:getZ())
                    scanSquareObjects(sq)
                    if centralObj then break end
                end
                if centralObj then break end
            end
        end
    end

    if not centralObj and getTimestampMs then
        local now = getTimestampMs()
        local last = BunkersAnywhere._lastCentralDetectDebugMs or 0
        if now - last >= 2000 then
            BunkersAnywhere._lastCentralDetectDebugMs = now
            local dsq = firstSq or playerObj:getSquare()
            if dsq then
                local key = BunkersAnywhere.getInvisibleGeneratorNodeKey(dsq:getX(), dsq:getY(), dsq:getZ())
                local hasNode = storeSnapshot and storeSnapshot.nodes and storeSnapshot.nodes[key] ~= nil
                print("[BunkersAnywhere][CentralDetect] no central detected at " .. tostring(dsq:getX()) .. "," .. tostring(dsq:getY()) .. "," .. tostring(dsq:getZ()) .. " node=" .. tostring(hasNode))
                local objs = dsq:getObjects()
                if objs then
                    for i = 0, math.min(objs:size() - 1, 10) do
                        local o = objs:get(i)
                        local sp = o and o.getSprite and o:getSprite() or nil
                        local sn = sp and sp.getName and sp:getName() or "nil"
                        print("[BunkersAnywhere][CentralDetect] obj#" .. tostring(i) .. " sprite=" .. tostring(sn))
                    end
                end
            end
        end
    end

    if centralObj then
        local hadClientDebug = false
        if getTimestampMs then
            local now = getTimestampMs()
            local last = BunkersAnywhere._lastServerInvDebugRequestMs or 0
            if now - last >= 1200 then
                hadClientDebug = true
                BunkersAnywhere._lastServerInvDebugRequestMs = now
            end
        else
            hadClientDebug = true
        end

        BunkersAnywhere.debugLogBatteryInventoryClient(playerObj, "OnFillWorldObjectContextMenu")
        if hadClientDebug and sendClientCommand then
            sendClientCommand("BunkersAnywhere", "DebugCentralBatteryInventory", {
                reason = "OnFillWorldObjectContextMenu",
                onlineID = playerObj.getOnlineID and playerObj:getOnlineID() or -1,
                username = playerObj.getUsername and playerObj:getUsername() or "",
            })
        end

        local md = centralObj:getModData()
        local sqCentral = centralObj:getSquare()
        local elecLevel = BunkersAnywhere.getPlayerElectricityLevel(playerObj)
        local needElec = BunkersAnywhere.CentralSkill.MinElectricityToConnect
        local store = BunkersAnywhere.getInvisibleGeneratorStore()
        local currentKey = BunkersAnywhere.getInvisibleGeneratorNodeKey(sqCentral:getX(), sqCentral:getY(), sqCentral:getZ())
        local currentNode = store.nodes and store.nodes[currentKey] or nil

        if not currentNode then
            BunkersAnywhere.registerInvisibleGeneratorCentralCandidate(centralObj)
            currentNode = store.nodes and store.nodes[currentKey] or nil
        end

        local isKnown = currentNode ~= nil
        local isSource = (currentNode and currentNode.source ~= false) or (md and md.baInvisibleGeneratorIsSource == true)
        local energyPercent = BunkersAnywhere.getCentralEnergyPercent(currentNode, md)
        if not isSource then
            local connectOpt = context:addOption(baText("ContextMenu_ConnectInvisibleGeneratorCentral"), centralObj, BunkersAnywhere.onConnectInvisibleGeneratorCentral, playerObj)
            if elecLevel < needElec then
                connectOpt.notAvailable = true
                connectOpt.toolTip = ISToolTip:new()
                connectOpt.toolTip:initialise()
                connectOpt.toolTip:setVisible(false)
                connectOpt.toolTip.description = baText("ContextMenu_CentralNeedElectricityLevel", tostring(needElec), tostring(elecLevel))
            end
        else
            local info = context:addOption(baText("ContextMenu_CentralEnergy", tostring(energyPercent)))
            info.notAvailable = true
            local remainingMinutes = BunkersAnywhere.getCentralRemainingMinutesDisplay(currentNode, md, currentKey)
            local timeInfo = context:addOption(baText("ContextMenu_CentralTimeRemaining", BunkersAnywhere.formatCentralRemainingTime(remainingMinutes)))
            timeInfo.notAvailable = true
            local radiusBonus = BunkersAnywhere.getCentralRadiusBonus(currentNode, md)
            local radiusValue = BunkersAnywhere.InvisibleCentralGenerator.BaseRadius + radiusBonus
            local radiusInfo = context:addOption(baText("ContextMenu_CentralRadius", tostring(radiusValue)))
            radiusInfo.notAvailable = true

            local upgradeDisabled = context:addOption(baText("ContextMenu_CentralUpgradeDisabled"))
            upgradeDisabled.notAvailable = true

            if energyPercent < BunkersAnywhere.CentralBattery.MaxEnergy then
                context:addOption(baText("ContextMenu_CentralAutoLoadBattery"), centralObj, BunkersAnywhere.onInsertAnyCentralBattery, playerObj)
            end

            local addSub = context:addOption(baText("ContextMenu_CentralLoadWithBattery"))
            local addSubCtx = ISContextMenu:getNew(context)
            context:addSubMenu(addSub, addSubCtx)
            local hasInsertOption = false

            for _, fullType in ipairs(BunkersAnywhere.CentralBattery.Types) do
                local charge = BunkersAnywhere.getCentralBatteryCharge(fullType)
                local runtimeMinutes = BunkersAnywhere.getCentralBatteryRuntimeMinutes(fullType)
                local shortType = BunkersAnywhere.getShortTypeFromFullType(fullType) or fullType
                local have = BunkersAnywhere.countBatteryTypeAvailable(playerObj, fullType)
                local after = energyPercent + charge
                local runtimeLabel = BunkersAnywhere.formatCentralRemainingTime(runtimeMinutes)
                local label = baText("ContextMenu_CentralInsertBattery", tostring(shortType), tostring(runtimeLabel), tostring(have))
                local opt = addSubCtx:addOption(label, centralObj, BunkersAnywhere.onInsertCentralBattery, playerObj, fullType)

                if charge <= 0 or after > BunkersAnywhere.CentralBattery.MaxEnergy then
                    opt.notAvailable = true
                    opt.toolTip = ISToolTip:new()
                    opt.toolTip:initialise()
                    opt.toolTip:setVisible(false)
                    if after > BunkersAnywhere.CentralBattery.MaxEnergy then
                        opt.toolTip.description = baText("ContextMenu_CentralWouldExceed", tostring(energyPercent), tostring(charge))
                    else
                        opt.toolTip.description = baText("ContextMenu_CentralInvalidBattery")
                    end
                else
                    hasInsertOption = true
                end
            end

            if not hasInsertOption then
                addSub.notAvailable = true
            end

        end

        local installed = BunkersAnywhere.getInstalledCentralBatteriesForMenu(currentNode, md)
        if installed and #installed > 0 then
            local removeSub = context:addOption(baText("ContextMenu_CentralRemoveBattery"))
            local removeSubCtx = ISContextMenu:getNew(context)
            context:addSubMenu(removeSub, removeSubCtx)

            local centralIsOn = (currentNode and currentNode.active == true) or (md and md.baInvisibleGeneratorLocalOn == true) or false
            if centralIsOn then
                removeSub.notAvailable = true
                removeSub.toolTip = ISToolTip:new()
                removeSub.toolTip:initialise()
                removeSub.toolTip:setVisible(false)
                removeSub.toolTip.description = baText("ContextMenu_CentralTurnOffToRemoveBattery")
            else
                for idx, entry in ipairs(installed) do
                    local uses = math.floor(tonumber(entry and entry.uses) or 1)
                    local full = (entry and entry.fullType) or "Base.CarBattery"
                    local short = BunkersAnywhere.getShortTypeFromFullType(full) or full
                    local state = BunkersAnywhere.getCentralBatteryUseLabel(uses)
                    local label = baText("ContextMenu_CentralRemoveBatteryEntry", tostring(short), tostring(state))
                    if uses >= BunkersAnywhere.CentralBattery.MaxUses then
                        label = baText("ContextMenu_CentralRemoveBatteryScrap", tostring(label))
                    end
                    removeSubCtx:addOption(label, centralObj, BunkersAnywhere.onRemoveCentralBattery, playerObj, idx)
                end
            end
        end

        local connectSub = nil
        local connectSubCtx = nil
        for _, node in pairs(store.nodes) do
            if node then
                if not (node.x == sqCentral:getX() and node.y == sqCentral:getY() and node.z == sqCentral:getZ()) then
                    local targetIsSource = (node.source ~= false)
                    local targetEnergy = BunkersAnywhere.getCentralEnergyPercent(node, nil)
                    local targetIsOn = (node.active == true) and (targetEnergy > 0)
                    if targetIsSource and targetIsOn then
                        local targetKey = BunkersAnywhere.getInvisibleGeneratorNodeKey(node.x, node.y, node.z)
                        local alreadyLinked = currentNode and currentNode.links and currentNode.links[targetKey] == true
                        if not alreadyLinked then
                            if not connectSub then
                                connectSub = context:addOption(baText("ContextMenu_ConnectToOtherCentral"))
                                connectSubCtx = ISContextMenu:getNew(context)
                                context:addSubMenu(connectSub, connectSubCtx)
                            end

                            local need = BunkersAnywhere.getWireDistanceCost(sqCentral, node.x, node.y)
                            local have = BunkersAnywhere.countElectricWireAvailable(playerObj)
                            local label = baText("ContextMenu_ConnectToOtherCentralCoord", tostring(node.x), tostring(node.y), tostring(node.z))
                            local opt = connectSubCtx:addOption(label, centralObj, BunkersAnywhere.onConnectInvisibleGeneratorToOtherCentral, playerObj, node.x, node.y, node.z)

                            opt.toolTip = ISToolTip:new()
                            opt.toolTip:initialise()
                            opt.toolTip:setVisible(false)
                            opt.toolTip.description = baText("IGUI_Bunker_CentralNeedWire", tostring(need), tostring(have))
                            if elecLevel < needElec then
                                opt.notAvailable = true
                                opt.toolTip.description = baText("ContextMenu_CentralNeedElectricityLevel", tostring(needElec), tostring(elecLevel))
                            elseif have < need then
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
            local depLabel = baText("ContextMenu_CentralDependsOn", tostring(providers))
            local depOpt = context:addOption(depLabel)
            depOpt.notAvailable = true
        end

        if isKnown then
            local isOn = (currentNode and currentNode.active == true) or localOn
            if isOn then
                context:addOption(baText("ContextMenu_TurnOffInvisibleGeneratorCentral"), centralObj, BunkersAnywhere.onTurnOffInvisibleGeneratorCentral, playerObj)
            else
                context:addOption(baText("ContextMenu_TurnOnInvisibleGeneratorCentral"), centralObj, BunkersAnywhere.onTurnOnInvisibleGeneratorCentral, playerObj)
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

    local hasOwnedInvisibleGenerator = centralObj ~= nil
    if worldobjects.size and worldobjects.get then
        for i = 0, worldobjects:size() - 1 do
            local wo = worldobjects:get(i)
            if BunkersAnywhere.hideOwnedInvisibleGenerator(wo) then
                hasOwnedInvisibleGenerator = true
                break
            end
        end
    else
        for _, wo in ipairs(worldobjects) do
            if BunkersAnywhere.hideOwnedInvisibleGenerator(wo) then
                hasOwnedInvisibleGenerator = true
                break
            end
        end
    end
    if not hasOwnedInvisibleGenerator then
        hasOwnedInvisibleGenerator = hasOwnedInvisibleGeneratorNearPlayer(playerObj, 1)
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

local function BunkersAnywhereCentralWorldContextSafe(player, context, worldobjects, test)
    local ok, err = pcall(BunkersAnywhereCentralWorldContext, player, context, worldobjects, test)
    if not ok then
        print("[BunkersAnywhere] CentralWorldContext error: " .. tostring(err))
    end
end

Events.OnFillWorldObjectContextMenu.Add(BunkersAnywhereCentralWorldContextSafe)

local function findCentralObjectOnSquare(square)
    if not square then return nil end
    local objects = square:getObjects()
    if not objects then return nil end
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if BunkersAnywhere.isInvisibleCentralTile(obj) then
            return obj
        end
        local md = obj and obj.getModData and obj:getModData() or nil
        if md and (md.baInvisibleGeneratorConnected ~= nil or md.baInvisibleGeneratorIsSource ~= nil or md.baCentralEnergyPercent ~= nil) then
            return obj
        end
        if obj and obj.getSprite then
            local sp = obj:getSprite()
            local sn = sp and sp.getName and sp:getName() or nil
            if sn and string.match(sn, "^location_business_bank_01_") then
                return obj
            end
        end
    end
    return nil
end

local function worldToScreen(playerIndex, x, y, z)
    if isoToScreenX and isoToScreenY then
        local okX, sx = pcall(function() return isoToScreenX(playerIndex, x, y, z) end)
        local okY, sy = pcall(function() return isoToScreenY(playerIndex, x, y, z) end)
        if okX and okY and sx and sy then
            return sx, sy
        end
    end
    if IsoUtils and IsoUtils.XToScreen and IsoUtils.YToScreen then
        local okX, sx = pcall(function() return IsoUtils.XToScreen(x, y, z, 0) end)
        local okY, sy = pcall(function() return IsoUtils.YToScreen(x, y, z, 0) end)
        if okX and okY and sx and sy then
            return sx, sy
        end
    end
    return nil, nil
end

local function canDrawCentralOverlayAtNode(node, playerX, playerY, playerZ, maxDistSq)
    if not node then return false end
    if node.z ~= playerZ then return false end
    local dx = node.x - playerX
    local dy = node.y - playerY
    local distSq = dx * dx + dy * dy
    return distSq <= maxDistSq
end

local function getCentralOverlayTextAndColor(node, md)
    local nodeKey = BunkersAnywhere.getInvisibleGeneratorNodeKey(node.x, node.y, node.z)
    local remaining = BunkersAnywhere.getCentralRemainingMinutesDisplay(node, md, nodeKey)
    local text = baText("IGUI_Bunker_CentralOverlay", BunkersAnywhere.formatCentralRemainingTime(remaining))
    local active = (node.active == true) and remaining > 0
    local r, g, b = 1.0, 0.85, 0.25
    if active then
        r, g, b = 0.25, 1.0, 0.35
    end
    return text, r, g, b
end

local function drawCentralOverlayAtNode(tm, core, node, md)
    local text, r, g, b = getCentralOverlayTextAndColor(node, md)
    local sx, sy = worldToScreen(0, node.x + 0.5, node.y + 0.5, node.z + 1.15)
    if not sx or not sy then return end
    if sx < -200 or sx > core:getScreenWidth() + 200 or sy < -200 or sy > core:getScreenHeight() + 200 then return end
    -- Slightly right and lower so it stays close to the central tile.
    tm:DrawStringCentre(UIFont.Small, sx + 18, sy - 10, text, r, g, b, 0.95)
end

local function BunkersAnywhereDrawCentralRuntimeOverlay()
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end
    local pSq = playerObj:getSquare()
    if not pSq then return end
    local cell = getCell()
    if not cell then return end
    local tm = getTextManager and getTextManager() or nil
    local core = getCore and getCore() or nil
    if not tm or not core then return end

    local store = BunkersAnywhere.getInvisibleGeneratorStore()
    if not store or not store.nodes then return end
    local px, py, pz = pSq:getX(), pSq:getY(), pSq:getZ()
    local maxDistSq = 20 * 20
    for _, node in pairs(store.nodes) do
        if node and node.source ~= false and canDrawCentralOverlayAtNode(node, px, py, pz, maxDistSq) then
            local sq = cell:getGridSquare(node.x, node.y, node.z)
            local centralObj = findCentralObjectOnSquare(sq)
            local md = centralObj and centralObj.getModData and centralObj:getModData() or nil
            drawCentralOverlayAtNode(tm, core, node, md)
        end
    end
end

local function BunkersAnywhereDrawCentralRuntimeOverlaySafe()
    local ok, err = pcall(BunkersAnywhereDrawCentralRuntimeOverlay)
    if not ok then
        local now = getTimestampMs and getTimestampMs() or 0
        local last = BunkersAnywhere._lastCentralOverlayErrorMs or 0
        if now == 0 or now - last > 3000 then
            BunkersAnywhere._lastCentralOverlayErrorMs = now
            print("[BunkersAnywhere] Central runtime overlay error: " .. tostring(err))
        end
    end
end

if Events.OnPostUIDraw then
    Events.OnPostUIDraw.Add(BunkersAnywhereDrawCentralRuntimeOverlaySafe)
end

local function BunkersAnywhereOnServerCommand(module, command, args)
    if module ~= "BunkersAnywhere" then return end
    if command == "CentralBatteryPayout" then
        BunkersAnywhere.onServerCentralBatteryPayout(args or {})
    end
end

Events.OnServerCommand.Add(BunkersAnywhereOnServerCommand)

local _baGeneratorHideTick = 0
local function BunkersAnywhereOnTickHideOwnedGenerators()
    _baGeneratorHideTick = _baGeneratorHideTick + 1
    if _baGeneratorHideTick < 3 then return end
    _baGeneratorHideTick = 0
    BunkersAnywhere.refreshOwnedInvisibleGenerators()
end

Events.OnTick.Add(BunkersAnywhereOnTickHideOwnedGenerators)
Events.OnGameStart.Add(BunkersAnywhere.refreshOwnedInvisibleGenerators)
