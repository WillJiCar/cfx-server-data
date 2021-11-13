resource_type 'gametype' { name = 'Racing' }
game 'common'
fx_version 'adamant'

-- Manifest
resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'Racing gamemode by mraes'
client_script 'client/zzdebug.lua'
client_script 'client/xml.lua'
client_script 'client/map_loader.lua'
client_script 'client/gfx.lua'

client_script 'client/racing_client.lua'

-- POST race results page
ui_page 'client/html/scoreboard.html'

client_script 'client/scoreboard.lua'

files {
    'client/html/scoreboard.html',
    'client/html/style.css',
    'client/html/reset.css',
    'client/html/listener.js',
}

--server_script 'server/lib/NewtonSoft.Json.net.dll'
server_script 'server/Newtonsoft.Json.net.dll'
server_script 'server/RaceServer.net.dll'

dependencies { 'mapmanager' }