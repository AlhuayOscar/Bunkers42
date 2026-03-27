local BASubterraData = {}

local metaGrid

local function getMetaSquare(square)
    if not metaGrid or not square then
        return nil
    end

    local zSlice = metaGrid[square:getZ()]
    if not zSlice then
        return nil
    end

    local zxSlice = zSlice[square:getX()]
    if not zxSlice then
        return nil
    end

    return zxSlice[square:getY()]
end

local function getOrCreateMetaSquare(square)
    local z = square:getZ()
    metaGrid[z] = metaGrid[z] or {}
    local zSlice = metaGrid[z]

    local x = square:getX()
    zSlice[x] = zSlice[x] or {}
    local zxSlice = zSlice[x]

    local y = square:getY()
    local metaSquare = zxSlice[y]
    if not metaSquare then
        metaSquare = {}
        zxSlice[y] = metaSquare
    end

    return metaSquare
end

function BASubterraData.onFloorRemoved(square)
    if not square or not metaGrid then
        return
    end

    local metaSquare = getOrCreateMetaSquare(square)
    metaSquare.isFloorRemoved = true
end

function BASubterraData.clearFloorRemoved(square)
    local metaSquare = getMetaSquare(square)
    if not metaSquare then
        return
    end

    metaSquare.isFloorRemoved = nil
end

function BASubterraData.isFloorRemoved(square)
    local metaSquare = getMetaSquare(square)
    return metaSquare and metaSquare.isFloorRemoved == true or false
end

Events.OnInitGlobalModData.Add(function()
    metaGrid = ModData.get("BASubterraData")
    if not metaGrid then
        metaGrid = ModData.create("BASubterraData")
        metaGrid.VERSION = 1
    end
end)

return BASubterraData
