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
    '@qbx_core/modules/playerdata.lua',
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

dependencies {
    'ox_lib',
    'qbx_core',
    'ox_inventory',
    'ox_target',
}
