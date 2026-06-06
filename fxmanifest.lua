fx_version 'cerulean'
game 'gta5'

author 'Noted Development'
description 'noted_removeclothes — Undress and loot clothing from vulnerable players'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    -- QBX (Config.Framework = 'qbx'): keep this line.
    -- QBCore (Config.Framework = 'qb'): remove/comment this line.
    '@qbx_core/modules/playerdata.lua',

    'client/framework.lua',
    'client/client.lua',
}

server_scripts {
    'server/server.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
}

-- ─── dependencies ─────────────────────────────────────────────────────────────
-- Keep only the entries that match your config:
--
--  Framework      → 'qbx_core'    (Config.Framework = 'qbx')
--                   'qb-core'     (Config.Framework = 'qb')
--
--  Inventory      → 'ox_inventory' (Config.InventoryResource = 'ox_inventory')
--                   'qb-inventory' (Config.InventoryResource = 'qb-inventory')
--
--  Target         → 'ox_target'   (Config.TargetResource = 'ox_target', UseTarget = true)
--                   'qb-target'   (Config.TargetResource = 'qb-target', UseTarget = true)
--                   omit entirely  (Config.UseTarget = false)
dependencies {
    'ox_lib',
    'qbx_core',      -- swap to 'qb-core' for QBCore
    'ox_inventory',  -- swap to 'qb-inventory' for qb-inventory
    'ox_target',     -- swap to 'qb-target' or remove if UseTarget = false
}
