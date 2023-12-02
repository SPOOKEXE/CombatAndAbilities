
local Module = {}

Module.ATTACK_DURATION = 0.6 -- how many seconds to allow hits to register
Module.CUTOFF_TIME = 0.6 -- how many seconds max inbetween each press for combo (if over the time, starts cooldown period)
Module.MAX_DISTANCE_CUTOFF = 9
Module.Damage = 10

Module.BLOCK_MAX_HITS = 5
Module.BLOCK_COOLDOWN = 1.5

Module.DASH_COOLDOWN = 3
Module.DASH_DISTANCE = 25
Module.DASH_DURATION = 0.35

Module.StunDurations = {
	NPC = 0.8,
	Player = 0.4,

	LastComboHit = 0.8,
	BlockBreak = 1.4,
}

Module.Animations = {
	Attacks = {
		'rbxassetid://6147296899',
		'rbxassetid://6147300658',
		'rbxassetid://6147303386',
	},

	Block = 'rbxassetid://14666570960',
	--BlockBreak = 'rbxassetid://15525344586',
	Stunned = 'rbxassetid://14666489533',
	Dash = 'rbxassetid://11795131540',
}

return Module
