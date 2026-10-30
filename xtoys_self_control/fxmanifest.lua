fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'xtoys_self_control'
author 'jonny5509'
description 'Client-only xToys self-control gameplay feedback'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'
