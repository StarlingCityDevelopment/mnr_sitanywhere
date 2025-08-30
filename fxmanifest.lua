fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mnr_sitanywhere'
description 'Optimized SitAnywhere script'
author 'IlMelons'
version '1.0.2'
repository 'https://github.com/Monarch-Development/mnr_sitanywhere'

ox_lib 'locale'

files {
    'config/*.lua',
    'locales/*.json',
}

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'bridge/client/**/*.lua',
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}