---@omw-context global
-- Inventory access. An inventory object stays valid for as long as its owner
-- does, so it's fetched once and kept instead of being re-created per check.

local types = require('openmw.types')
local async = require("openmw.async")
local storage = require("openmw.storage")

local settingsCache = require("scripts.SoundsOfSouls.utils.settingsCache")

local settings = settingsCache.new(storage.globalSection("SettingsSoundsOfSouls"), async)

local inventories = {}

-- Fetches the inventory of a container or actor.
function inventories.get(object)
    if types.Container.objectIsInstance(object) then
        return types.Container.content(object)
    end
    return types.Actor.inventory(object)
end

-- Cached variant keyed by object id. Only for long-lived objects (players);
-- per-cell holders are cached in the cell scan data so they're dropped along
-- with the cell.
local cached = {}
function inventories.getCached(object)
    local inventory = cached[object.id]
    if not inventory then
        inventory = inventories.get(object)
        cached[object.id] = inventory
    end
    return inventory
end

-- Misc items in an inventory, or nil if its loot isn't resolved yet.
function inventories.getMiscItems(inventory)
    if not inventory:isResolved() then
        if not settings.resolveInventories then
            return nil
        end
        inventory:resolve()
    end
    return inventory:getAll(types.Miscellaneous)
end

return inventories
