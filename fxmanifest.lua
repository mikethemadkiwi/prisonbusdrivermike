fx_version "cerulean"
games {"gta5"}
dependencies {
    'yarn',
    'PolyZone'
}
client_scripts {
  '@PolyZone/client.lua',
  '@PolyZone/BoxZone.lua',
  '@PolyZone/EntityZone.lua',
  '@PolyZone/CircleZone.lua',
  '@PolyZone/ComboZone.lua'
}
client_script 'client.lua'
server_script 'server.lua'