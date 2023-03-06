Config = {}

Config.Standalone = true -- false enables qb-core useable item and shop
Config.UsingMap = true -- true if using optional gg-frisbeegolfstand map

--default aim values
Config.Pitch = 30.0
Config.Velocity = 30.0 -- note: 30.0 is maximum velocity allowed
Config.Roll = 0.0

Config.Gravity = 3.0 -- 3.0 recommended
Config.StopSlope = 22.0 -- ground slope angle to stop frisbee from sliding

Config.AimReset = false -- true will reset to default values every new throw
Config.UseIndicator = true
Config.IndicatorScale = 0.5 -- 0.1 to 1.0
Config.IndicatorPointerLength = 10.0 -- 1.0 to 10.0+ (note: scaled with above)

Config.Strict = true -- must thrown from tee / last landing spot of frisbee while playing frisbee golf
Config.StrictDist = 1.5 -- radius of zone
Config.StuckDist = 1.0 -- does not include z

Config.FrisbeeGolfTargets = { -- For z positions obtained from Player Position, subtract 1.2. Sounds at https://pastebin.com/eeFc5DiW
	[1] = {Prop ='prop_feeder1_cr', Sound = {'CLOSED', 'DOOR_GARAGE'}, Offset = vector3(0.0, 0.0, 1.0), Rotation = vector3(180.0, 0.0, 0.0), ZoneOffset = vector3(0.0, 0.0, 0.0), ZoneRadius = 1.0}, -- easiest (inverted)
	[2] = {Prop ='gg_fg_target', Sound = {'Cage_Rattle', 'DLC_HEIST_BIOLAB_MONKEYS_SOUNDS'}, Offset = vector3(0.0, 0.0, 0.0), Rotation = vector3(0.0, 0.0, 0.0), ZoneOffset = vector3(0.0, 0.0, 1.08), ZoneRadius = 0.34}, -- difficult
	[3] = {Prop ='prop_crate_10a', Sound = {'OPENED', 'DOOR_GARAGE'}, Offset = vector3(0.0, 0.0, 0.08), Rotation = vector3(0.0, 0.0, 0.0), ZoneOffset = vector3(0.0, 0.0, 0.25), ZoneRadius = 0.75}, -- easy
	[4] = {Prop ='prop_cs_bin_01_skinned', Sound = {'CLOSED', 'DOOR_GARAGE'}, Offset = vector3(0.0, 0.0, 0.2), Rotation = vector3(0.0, 0.0, 0.0), ZoneOffset = vector3(0.0, 0.0, 0.65), ZoneRadius = 0.4}, -- difficult
}

Config.FrisbeeGolfCourse = {
	[1] = {Tee = vector3(248.6463, 6761.6396, 14.5613), TeeBlip = 502, Hole = vector3(116.5900, 6801.8100, 18.5500), HoleHead = 0.0, HoleBlip = 502, HoleProp = 2, HoleSpawned = false, Distance = 0.0, Par = 0},
	[2] = {Tee = vector3(105.8246, 6824.5793, 16.7908), TeeBlip = 503, Hole = vector3(264.0200, 6810.0500, 14.6600), HoleHead = 0.0, HoleBlip = 503, HoleProp = 2, HoleSpawned = false, Distance = 0.0, Par = 0},
	[3] = {Tee = vector3(274.0600, 6837.3700, 16.6400), TeeBlip = 504, Hole = vector3(278.7400, 6948.2800, 9.9800), HoleHead = 0.0, HoleBlip = 504, HoleProp = 2, HoleSpawned = false, Distance = 0.0, Par = 0},
	[4] = {Tee = vector3(226.1300, 6934.6500, 14.5500), TeeBlip = 505, Hole = vector3(86.2400, 7076.7100, 0.7400), HoleHead = 0.0, HoleBlip = 505, HoleProp = 2, HoleSpawned = false, Distance = 0.0, Par = 0},
	[5] = {Tee = vector3(47.1900, 7092.9500, 1.9300), TeeBlip = 506, Hole = vector3(58.2600, 7003.0400, 12.4200), HoleHead = 0.0, HoleBlip = 506, HoleProp = 2, HoleSpawned = false, Distance = 0.0, Par = 0},
	[6] = {Tee = vector3(74.4510, 7021.7145, 12.4302), TeeBlip = 507, Hole = vector3(218.1500, 6901.3000, 11.9000), HoleHead = 0.0, HoleBlip = 507, HoleProp = 2, HoleSpawned = false, Distance = 0.0, Par = 0},
	[7] = {Tee = vector3(209.2832, 6845.1431, 20.2144), TeeBlip = 508, Hole = vector3(93.6500, 6966.5000, 10.0000), HoleHead = 0.0, HoleBlip = 508, HoleProp = 2, HoleSpawned = false, Distance = 0.0, Par = 0},
	[8] = {Tee = vector3(61.5141, 6934.0219, 12.0241), TeeBlip = 509, Hole = vector3(8.8326, 6826.3059, 14.6662), HoleHead = 0.0, HoleBlip = 509, HoleProp = 2, HoleSpawned = false, Distance = 0.0, Par = 0},
	[9] = {Tee = vector3(15.1900, 6769.7400, 21.8900), TeeBlip = 510, Hole = vector3(274.6600, 6756.9200, 14.7100), HoleHead = 0.0, HoleBlip = 510, HoleProp = 1, HoleSpawned = false, Distance = 0.0, Par = 0},
}

local SumX = 0.0
local SumY = 0.0
local SumZ = 0.0
for k, v in pairs(Config.FrisbeeGolfCourse) do
	v.Distance = #(v.Hole - v.Tee)
	local LongShots = v.Distance - 50
	if LongShots > 100 then
		v.Par = math.ceil(v.Distance / 100) + 2
	else
		v.Par = 3
	end
	SumX = SumX + v.Hole.x + v.Tee.x
	SumY = SumY + v.Hole.y + v.Tee.y
	SumZ = SumZ + v.Hole.z + v.Tee.z
end

Config.FrisbeeGolfCourseCenter = vector3(SumX / (2 * #Config.FrisbeeGolfCourse), SumY / (2 * #Config.FrisbeeGolfCourse), SumZ / (2 * #Config.FrisbeeGolfCourse))

Config.Practice = {
	[10] = {Hole = vector3(300.72, 6788.73, 14.40), HoleHead = 0.0, HoleProp = 1},
	[11] = {Hole = vector3(293.62, 6799.49, 14.52), HoleHead = 0.0, HoleProp = 2},
	[12] = {Hole = vector3(280.52, 6802.45, 14.50), HoleHead = 50.0, HoleProp = 3},
	[13] = {Hole = vector3(279.95, 6774.23, 14.50), HoleHead = 120.0, HoleProp = 4},
}

Config.DisplayFrisbees = {
	[1] = {Prop = "gg_prop_frisbee", Pos = vector3(277.1972, 6791.3815, 15.9248), Rot = vector3(0.0000, -20.0000, -90.0000)}, -- using rot 5
	[2] = {Prop = "gg_prop_frisbee_r", Pos = vector3(277.1972, 6790.7715, 15.5748), Rot = vector3(0.0000, -20.0000, -90.0000)},
	[3] = {Prop = "gg_prop_frisbee_g", Pos = vector3(277.1972, 6791.1915, 15.5748), Rot = vector3(0.0000, -20.0000, -90.0000)},
	[4] = {Prop = "gg_prop_frisbee_b", Pos = vector3(277.1972, 6790.9815, 15.9248), Rot = vector3(0.0000, -20.0000, -90.0000)},
	[5] = {Prop = "gg_prop_frisbee_y", Pos = vector3(277.1972, 6791.5715, 15.5748), Rot = vector3(0.0000, -20.0000, -90.0000)},
}

Config.FrisbeeDude = {
	["Location"] = vector4(279.3, 6790.43, 14.94, 270.37), -- or location below if not using provided map
	["Ped"] = 'cs_omega',
	["PedVariation"] = {
		[0] = {0, 0, 0},
		[1] = {0, 0, 0},
		[2] = {0, 0, 0},
		[3] = {0, 0, 0},
		[4] = {0, 0, 0},
		[5] = {0, 0, 0},
		[6] = {0, 0, 0},
		[7] = {0, 0, 0},
		[8] = {1, 0, 0},
		[9] = {0, 0, 0},
		[10] = {0, 0, 0},
		[11] = {0, 0, 0},
	},
	["PedProp"] = {
		[0] = {0, 0, true},
		[1] = {0, 0, true},
		[2] = {0, 0, true},
		[6] = {0, 0, true},
		[7] = {0, 0, true},
	},
	["Scenario"] = "WORLD_HUMAN_STAND_IMPATIENT"
}

if not Config.UsingMap then
	Config.FrisbeeDude.Location = vector4(281.93, 6789.18, 14.74, 270.37) -- use this location if not using provided map
end