---@omw-context global
-- Sounds of Souls: filled soul gems occasionally moan/roar/scream with their
-- creature's voice:
--   * when a player activates (picks up) one,
--   * at random while one is in a player's inventory,
--   * at random while one is in a player's current cell: lying on the ground,
--     inside a container, or in an NPC's/creature's inventory (including
--     corpses).

local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')
local async = require("openmw.async")
local storage = require("openmw.storage")

local sounds = require('scripts.SoundsOfSouls.logic.sounds')
local soulGems = require('scripts.SoundsOfSouls.logic.soulgems')
local inventories = require('scripts.SoundsOfSouls.logic.inventories')
local cells = require('scripts.SoundsOfSouls.logic.cells')
local settingsCache = require("scripts.SoundsOfSouls.utils.settingsCache")

local settings = settingsCache.new(storage.globalSection("SettingsSoundsOfSouls"), async)

----------------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------------

local function rollChance(chance)
    return math.random(1, 100) <= chance
end

local function randomDelay(min, max)
    return min + math.random() * (max - min)
end

local function playRandomInventorySoul(player)
    local gems = inventories.getCached(player):getAll(types.Miscellaneous)
    local choice = soulGems.choose(soulGems.getEntries(gems, player))
    if choice == nil or not rollChance(settings.soundInventory.chance) then
        return
    end
    -- Gems in an inventory have no world position: play at the player.
    sounds.play(choice.soul, player)
end

local function playRandomCellSoul(data)
    local choice = soulGems.choose(cells.getEntries(data))
    if choice == nil or not rollChance(settings.soundCell.chance) then
        return
    end
    sounds.play(choice.soul, choice.object)
end

----------------------------------------------------------------------------
-- Handlers
----------------------------------------------------------------------------

local inventoryTimer = 0
local cellTimer = 0
local cellChangeTimer = 0

-- Force a chance when a player picks up a soul gem.
local function onSoulGemActivated(object, actor)
    if not types.Player.objectIsInstance(actor) then
        return -- not false: never block activation
    end
    local soul = soulGems.getSoul(object)
    if soul and rollChance(settings.soundActivate.chance) then
        -- Played at the player, so it isn't positional.
        sounds.play(soul, actor)
    end
end

local function onUpdate(dt)
    cellChangeTimer = cellChangeTimer - dt
    if cellChangeTimer <= 0 then
        cellChangeTimer = settings.cellCheckInterval
        cells.update()
    end

    inventoryTimer = inventoryTimer - dt
    if inventoryTimer <= 0 then
        inventoryTimer = randomDelay(settings.soundInventory.timerMin, settings.soundInventory.timerMax)
        for _, player in ipairs(world.players) do
            playRandomInventorySoul(player)
        end
    end

    cellTimer = cellTimer - dt
    if cellTimer <= 0 then
        cellTimer = randomDelay(settings.soundCell.timerMin, settings.soundCell.timerMax)
        for _, data in pairs(cells.scanned) do
            playRandomCellSoul(data)
        end
    end
end

----------------------------------------------------------------------------
-- Entry points
----------------------------------------------------------------------------

I.Activation.addHandlerForType(types.Miscellaneous, onSoulGemActivated)

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onDropped = cells.trackDrop,
        onPlaced = cells.trackDrop,
    },
    eventHandlers = {
        IE_Teleport = function(data)
            cells.trackDrop(data.obj, data.player)
        end
    }
}
