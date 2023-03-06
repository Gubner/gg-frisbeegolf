fx_version 'cerulean'
game 'gta5'

author 'Gubner'
description 'Frisbee Golf'
version '1.0'

ui_page 'client/html/index.html'

client_scripts {
	'@PolyZone/client.lua',
	'@PolyZone/CircleZone.lua',
	'client/client.lua',
}

server_scripts {
	'server/server.lua',
}

shared_scripts {
	'config.lua',
}

files {
	'client/html/index.html',
	'client/html/script.js',
	'client/html/style.css',
	'client/html/reset.css',
	'server/scores.json'
}
