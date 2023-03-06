# gg-frisbeegolf: Frisbee Golf by Gubner
A FiveM resource to add Frisbee Golf to your server. Use as Standalone or QB-Core.
Includes custom props: Frisbees with physics, Tee Pads, and Frisbee Golf Baskets.
Ability to customize locations of tees and holes, and even use alternative props for the hole targets.

## Installation:
>Install [gg-frisbeegolf](https://github.com/Gubner) in your resources folder and ensure in your server.cfg file

>Install [gg-frisbeeprops](https://github.com/Gubner) in your resources folder and ensure in your server.cfg file

## Optional:
>Install [gg-frisbeegolfstand](https://github.com/Gubner) in your resources folder and ensure in your server.cfg file. If you decide not to use this ymap, update gg-frisbeegolf\config.lua Config.UsingMap.

## Dependencies:
[PolyZone](https://github.com/mkafrin/PolyZone)

## Setting up for QB-Core:

**1. Add items to qb-core\shared\items.lua:**
```lua
	['frisbee'] 				 	 = {['name'] = 'frisbee', 						['label'] = 'Frisbee', 							['weight'] = 100, 		['type'] = 'item', 		['image'] = 'frisbee.png', 					['unique'] = true, 		['useable'] = true, 	['shouldClose'] = false, 	['combinable'] = nil, 	['description'] = 'A flying disc'},
	['frisbee_r'] 				 	 = {['name'] = 'frisbee_r', 					['label'] = 'Red Frisbee', 						['weight'] = 100, 		['type'] = 'item', 		['image'] = 'frisbee_r.png', 				['unique'] = true, 		['useable'] = true, 	['shouldClose'] = false, 	['combinable'] = nil, 	['description'] = 'A flying disc'},
	['frisbee_g'] 				 	 = {['name'] = 'frisbee_g', 					['label'] = 'Green Frisbee', 					['weight'] = 100, 		['type'] = 'item', 		['image'] = 'frisbee_g.png', 				['unique'] = true, 		['useable'] = true, 	['shouldClose'] = false, 	['combinable'] = nil, 	['description'] = 'A flying disc'},
	['frisbee_b'] 				 	 = {['name'] = 'frisbee_b', 					['label'] = 'Blue Frisbee', 					['weight'] = 100, 		['type'] = 'item', 		['image'] = 'frisbee_b.png', 				['unique'] = true, 		['useable'] = true, 	['shouldClose'] = false, 	['combinable'] = nil, 	['description'] = 'A flying disc'},
	['frisbee_y'] 				 	 = {['name'] = 'frisbee_y', 					['label'] = 'Yellow Frisbee', 					['weight'] = 100, 		['type'] = 'item', 		['image'] = 'frisbee_y.png', 				['unique'] = true, 		['useable'] = true, 	['shouldClose'] = false, 	['combinable'] = nil, 	['description'] = 'A flying disc'},
```

**2. Add items to qb-shops\config.lua Config.Products:**
```lua
	["frisbee"] = {
		[1] = {
			name = "frisbee",
			price = 500,
			amount = 10,
			info = {},
			type = "item",
			slot = 1,
		},
		[2] = {
			name = "frisbee_r",
			price = 500,
			amount = 10,
			info = {},
			type = "item",
			slot = 2,
		},
		[3] = {
			name = "frisbee_g",
			price = 500,
			amount = 10,
			info = {},
			type = "item",
			slot = 3,
		},
		[4] = {
			name = "frisbee_b",
			price = 500,
			amount = 10,
			info = {},
			type = "item",
			slot = 4,
		},
		[5] = {
			name = "frisbee_y",
			price = 500,
			amount = 10,
			info = {},
			type = "item",
			slot = 5,
		},
	},
```

**3. Add shop to qb-shops\config.lua Config.Locations (if you are not using the provided map, switch coords commenting):**
```lua
	["frisbeeshop"] = {
		["label"] = "Frisbee Shop",
		["coords"] = vector4(279.3, 6790.43, 15.94, 270.37), -- using ymap
		--["coords"] = vector4(281.93, 6789.18, 15.7, 270.37), -- not using ymap
		["ped"] = 'cs_omega',
		["scenario"] = "WORLD_HUMAN_STAND_IMPATIENT",
		["radius"] = 1.5,
		["targetIcon"] = "fa-solid fa-cart-shopping",
		["targetLabel"] = "What frisbees do you have?",
		["products"] = Config.Products["frisbee"],
		["showblip"] = true,
		["blipsprite"] = 540,
		["blipscale"] = 0.6,
		["blipcolor"] = 0
	},
```

**4. Add provided images to qb-inventory\html\images**

**5. Update gg-frisbeegolf\config.lua**
```lua
Config.Standalone = false
```

## Commands
In Standalone, you may retrieve your frisbee from your inventory using:
>/frisbee

If your frisbee is stuck in a place you cannot get to (up a tree, on a roof, under the map), get as close as possible and use:
>/frisbeestuck

If a client does not want to play and is concerned about the resource running, the main thread loop can be deactivated with:
>/nofg
