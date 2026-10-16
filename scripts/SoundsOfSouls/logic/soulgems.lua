---@omw-context global
-- Soul gem detection and weighted selection.

local types = require('openmw.types')

local sounds = require('scripts.SoundsOfSouls.logic.sounds')

local soulGems = {}

-- Returns the soul (creature record id) in a misc item, or nil if not a
-- filled soul gem.
function soulGems.getSoul(item)
    if not types.Miscellaneous.objectIsInstance(item) then
        return nil
    end
    local soul = types.Item.itemData(item).soul
    if not soul or soul == '' then
        return nil
    end
    return soul
end

-- Returns { object, soul, value } for a filled soul gem that has at least one
-- sound we can play, or nil. `soundObject` is where the sound will play.
function soulGems.makeEntry(item, soundObject)
    local soul = soulGems.getSoul(item)
    if soul == nil or #sounds.getForSoul(soul) == 0 then
        return nil
    end
    return {
        object = soundObject,
        soul = soul,
        value = math.max(sounds.getSoulValue(soul) * item.count, 1)
    }
end

-- Entries for every playable soul gem in `items`. Sounds play at
-- `soundObject`, or at the item itself when that's nil.
function soulGems.getEntries(items, soundObject)
    local list = {}
    for _, item in ipairs(items) do
        local entry = soulGems.makeEntry(item, soundObject or item)
        if entry then
            list[#list + 1] = entry
        end
    end
    return list
end

-- Picks an entry weighted by soul value.
function soulGems.choose(list)
    local total = 0
    for _, entry in ipairs(list) do
        total = total + entry.value
    end
    if total <= 0 then
        return nil
    end

    local roll = math.random() * total
    for _, entry in ipairs(list) do
        roll = roll - entry.value
        if roll <= 0 then
            return entry
        end
    end
    return list[#list]
end

return soulGems
