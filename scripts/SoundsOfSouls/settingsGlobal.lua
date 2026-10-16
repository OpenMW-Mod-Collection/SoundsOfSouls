---@omw-context global
local I = require('openmw.interfaces')

I.Settings.registerGroup {
    key = 'SettingsSoundsOfSouls',
    page = 'SoundsOfSouls',
    l10n = "SoundsOfSouls",
    name = "settings_groupName",
    order = 1,
    permanentStorage = true,
    settings = {
        {
            key = 'cellCheckInterval',
            name = 'cellCheckInterval_name',
            description = 'cellCheckInterval_desc',
            renderer = 'number',
            default = 0.25,
        },
        {
            key = 'soundActivate',
            name = 'soundActivate_name',
            renderer = 'multiInput_V1',
            default = {
                chance = 75,
            },
            argument = {
                mode = "number",
                l10n = "SoundsOfSouls",
                keys = {
                    "chance",
                },
            },
        },
        {
            key = 'soundInventory',
            name = 'soundInventory_name',
            renderer = 'multiInput_V1',
            default = {
                chance = 50,
                timerMin = 30,
                timerMax = 90,
            },
            argument = {
                mode = "number",
                l10n = "SoundsOfSouls",
                keys = {
                    "chance",
                    "timerMin",
                    "timerMax",
                },
            },
        },
        {
            key = 'soundCell',
            name = 'soundCell_name',
            renderer = 'multiInput_V1',
            default = {
                chance = 20,
                timerMin = 1,
                timerMax = 60,
            },
            argument = {
                mode = "number",
                l10n = "SoundsOfSouls",
                keys = {
                    "chance",
                    "timerMin",
                    "timerMax",
                },
            },
        },
        {
            key = 'volume',
            name = 'volume_name',
            description = 'volume_desc',
            renderer = 'multiInput_V1',
            default = {
                scaler = 0.005,
                min = 0.2,
                max = 1,
            },
            argument = {
                mode = "number",
                l10n = "SoundsOfSouls",
                keys = {
                    "scaler",
                    "min",
                    "max",
                },
            },
        },
        {
            key = 'suffixes',
            name = 'suffixes_name',
            description = 'suffixes_desc',
            renderer = 'textSet_V1',
            default = {
                moan = true,
                roar = true,
                scream = true,
            },
            argument = {
                lower = true,
            },
        },
        {
            key = 'resolveInventories',
            name = 'resolveInventories_name',
            description = 'resolveInventories_desc',
            renderer = 'checkbox',
            default = false,
        },
    },
}
