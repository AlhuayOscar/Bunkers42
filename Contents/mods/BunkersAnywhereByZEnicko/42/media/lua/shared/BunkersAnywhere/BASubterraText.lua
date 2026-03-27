local BASubterraText = {}

local TEXT = {
    EN = {
        ContextMenu_BASubterra = "Subterrain Works",
        ContextMenu_BASubterraRoom = "Excavate Room",
        ContextMenu_BASubterraAccess = "Excavate Access",
        Tooltip_BASubterraNeedShovel = "You need a shovel to excavate soil",
        Tooltip_BASubterraNeedPickaxe = "You need a pickaxe to excavate stone",
        Tooltip_BASubterraNeedSacks = "You need %1 dirt bags (available: %2)",
        Tooltip_BASubterraTooExhausted = "You are too exhausted to excavate",
        Tooltip_BASubterraNoPath = "You need an adjacent excavated room to keep digging",
        Tooltip_BASubterraBlocked = "The selected tiles are blocked",
        Tooltip_BASubterraWaterTile = "You cannot excavate under water",
        Tooltip_BASubterraNeedGround = "You need a solid floor to start the access",
        Tooltip_BASubterraDepthLimit = "Only ground-to-basement access is supported",
        Tooltip_BASubterraAlreadyOpen = "That tile is already excavated",
        Tooltip_BASubterraNeedUnderground = "Room excavation must start underground",
        IGUI_BASubterraAccessBuilt = "Subterrain access created",
        IGUI_BASubterraRoomBuilt = "Underground room excavated",
    },
    ES = {
        ContextMenu_BASubterra = "Obras subterra",
        ContextMenu_BASubterraRoom = "Excavar sala",
        ContextMenu_BASubterraAccess = "Excavar acceso",
        Tooltip_BASubterraNeedShovel = "Necesitas una pala para excavar tierra",
        Tooltip_BASubterraNeedPickaxe = "Necesitas un pico para excavar piedra",
        Tooltip_BASubterraNeedSacks = "Necesitas %1 bolsas de tierra (disponibles: %2)",
        Tooltip_BASubterraTooExhausted = "Estas demasiado exhausto para excavar",
        Tooltip_BASubterraNoPath = "Necesitas una sala excavada adyacente para seguir cavando",
        Tooltip_BASubterraBlocked = "Los tiles seleccionados estan bloqueados",
        Tooltip_BASubterraWaterTile = "No puedes excavar debajo del agua",
        Tooltip_BASubterraNeedGround = "Necesitas un piso solido para iniciar el acceso",
        Tooltip_BASubterraDepthLimit = "Solo se admite acceso de planta baja a sotano",
        Tooltip_BASubterraAlreadyOpen = "Ese tile ya esta excavado",
        Tooltip_BASubterraNeedUnderground = "La excavacion de salas debe empezar bajo tierra",
        IGUI_BASubterraAccessBuilt = "Acceso subterraneo creado",
        IGUI_BASubterraRoomBuilt = "Sala subterranea excavada",
    },
}

local function formatText(template, ...)
    local result = tostring(template or "")
    local args = { ... }
    for i = 1, #args do
        result = string.gsub(result, "%%" .. tostring(i), tostring(args[i]))
    end
    return result
end

local function getLanguageCode()
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

    for i = 1, #candidates do
        local raw = string.upper(tostring(candidates[i] or ""))
        if raw == "ES" or raw == "ES_AR" or raw == "ES-AR" or raw == "ES_ES" or raw == "ES-ES" then
            return "ES"
        end
        if raw == "SPANISH" or string.find(raw, "SPANISH", 1, true) == 1 then
            return "ES"
        end
        if raw == "EN" or raw == "EN_US" or raw == "EN-US" or raw == "EN_GB" or raw == "EN-GB" then
            return "EN"
        end
        if raw == "ENGLISH" or string.find(raw, "ENGLISH", 1, true) == 1 then
            return "EN"
        end
    end

    return "EN"
end

function BASubterraText.get(key, ...)
    local translated = getText and getText(key, ...) or key
    if translated and translated ~= key then
        return translated
    end

    local lang = getLanguageCode()
    local tableByLang = TEXT[lang] or TEXT.EN
    local template = tableByLang[key] or TEXT.EN[key] or key
    return formatText(template, ...)
end

return BASubterraText
