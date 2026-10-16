---@omw-context global
-- Creature soul values and sounds.

local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local async = require("openmw.async")
local storage = require("openmw.storage")

local settingsCache = require("scripts.SoundsOfSouls.utils.settingsCache")

local settings = settingsCache.new(storage.globalSection("SettingsSoundsOfSouls"), async)

local sounds = {}

-- Soul value of a creature record.
function sounds.getSoulValue(soulId)
    local record = types.Creature.records[soulId]
    return record and record.soulValue or 0
end

-- Lazily-built set of all sound ids for existence checks.
local soundIds = nil
local function soundExists(id)
    if soundIds == nil then
        soundIds = {}
        for _, sound in ipairs(core.sound.records) do
            soundIds[sound.id] = true
        end
    end
    return soundIds[id] == true
end

-- creature record id -> list of sound ids (cached; they don't change).
local soundCache = {}

-- Returns the list of sound ids a creature can make (possibly empty).
function sounds.getForSoul(soulId)
    local cached = soundCache[soulId]
    if cached then
        return cached
    end

    local found = {}
    local id = soulId
    local record = types.Creature.records[id]
    local depth = 0
    while record and record.baseCreature and record.baseCreature ~= '' and depth < 10 do
        id = record.baseCreature
        record = types.Creature.records[id]
        depth = depth + 1
    end

    local names = {}
    if record and record.name and record.name ~= '' then
        names[#names + 1] = record.name:lower()
    end
    names[#names + 1] = (id:gsub('_', ' '))

    for suffix, _ in pairs(settings.suffixes) do
        for _, name in ipairs(names) do
            local candidate = name .. ' ' .. suffix
            if soundExists(candidate) then
                found[#found + 1] = candidate
                break
            end
        end
    end

    soundCache[soulId] = found
    return found
end

local function getVolume(soulId)
    return util.clamp(
        sounds.getSoulValue(soulId) * settings.volume.scaler,
        settings.volume.min,
        settings.volume.max
    )
end

-- Plays a random sound of the given creature at an object.
function sounds.play(soulId, atObject)
    local available = sounds.getForSoul(soulId)
    if #available == 0 then
        return
    end
    core.sound.playSound3d(available[math.random(#available)], atObject, {
        volume = getVolume(soulId),
    })
end

return sounds
