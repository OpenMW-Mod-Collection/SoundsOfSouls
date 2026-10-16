---@omw-context global
-- Per-cell scan cache. Each occupied cell is scanned once when a player
-- enters it; afterwards only the short list of relevant gems/holders found by
-- that scan is walked.

local types = require('openmw.types')
local world = require('openmw.world')

local inventories = require('scripts.SoundsOfSouls.logic.inventories')
local soulGems = require('scripts.SoundsOfSouls.logic.soulgems')

local cells = {}

-- cell id -> {
--   gems = playable soul gems lying in the world,
--   gemIds = set of object ids in gems (dedupes drops),
--   holders = list of { object, inventory } for containers/actors holding at
--             least one playable gem,
-- }
-- Only cells currently occupied by a player are kept. The table itself is
-- never reassigned, so other modules may hold a reference to it.
cells.scanned = {}

local HOLDER_TYPES = { types.Container, types.NPC, types.Creature }

local occupied = {} -- reused: set of cell ids players are in

local function scanCell(cell)
    local data = { gems = {}, gemIds = {}, holders = {} }

    for _, obj in ipairs(cell:getAll(types.Miscellaneous)) do
        if obj.enabled and soulGems.makeEntry(obj, obj) then
            data.gems[#data.gems + 1] = obj
            data.gemIds[obj.id] = true
        end
    end

    for _, holderType in ipairs(HOLDER_TYPES) do
        for _, holder in ipairs(cell:getAll(holderType)) do
            if holder.enabled and not types.Player.objectIsInstance(holder) then
                local inventory = inventories.get(holder)
                local items = inventories.getMiscItems(inventory)
                if items and #soulGems.getEntries(items, holder) > 0 then
                    data.holders[#data.holders + 1] = { object = holder, inventory = inventory }
                end
            end
        end
    end

    return data
end

-- Scans cells that just became occupied; forgets cells nobody is in.
function cells.update()
    for id in pairs(occupied) do
        occupied[id] = nil
    end
    for _, player in ipairs(world.players) do
        local cell = player.cell
        if cell then
            occupied[cell.id] = true
            if cells.scanned[cell.id] == nil then
                cells.scanned[cell.id] = scanCell(cell)
            end
        end
    end
    for id in pairs(cells.scanned) do
        if not occupied[id] then
            cells.scanned[id] = nil
        end
    end
end

-- Builds the entry list from a cell's cached scan. Stale things (picked up
-- gems, emptied containers, deleted objects) are re-checked here and pruned
-- from the cache, so nothing needs a rescan.
function cells.getEntries(data)
    local soulList = {}

    local keptGems = {}
    local keptIds = {}
    for _, gem in ipairs(data.gems) do
        if gem:isValid() and gem.enabled and gem.parentContainer == nil and gem.cell ~= nil then
            keptGems[#keptGems + 1] = gem
            keptIds[gem.id] = true
            soulList[#soulList + 1] = soulGems.makeEntry(gem, gem)
        end
    end
    data.gems = keptGems
    data.gemIds = keptIds

    local keptHolders = {}
    for _, holder in ipairs(data.holders) do
        local object = holder.object
        if object:isValid() and object.enabled then
            local items = inventories.getMiscItems(holder.inventory)
            local entries = items and soulGems.getEntries(items, object) or {}
            if #entries > 0 then
                keptHolders[#keptHolders + 1] = holder
                for _, entry in ipairs(entries) do
                    soulList[#soulList + 1] = entry
                end
            end
        end
    end
    data.holders = keptHolders

    return soulList
end

-- Gems dropped/placed after the scan: add them to the cache directly.
-- Used for both onDropped and onPlaced.
function cells.trackDrop(object, actor)
    if not types.Miscellaneous.objectIsInstance(object) then
        return
    end
    local data = actor and actor.cell and cells.scanned[actor.cell.id]
    if not data then
        return -- not in a scanned cell
    end
    if data.gemIds[object.id] then
        return -- already tracked (drop + place can both fire)
    end
    if soulGems.makeEntry(object, object) then
        data.gems[#data.gems + 1] = object
        data.gemIds[object.id] = true
    end
end

return cells
