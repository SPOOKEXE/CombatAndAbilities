
-- // Module // --
local Module = {}

-- default animations if none specified per-weapon
Module.Defaults = {
	Stunned = 'rbxassetid://-1',

	ToSheathe = 'rbxassetid://-1', -- unequip
	UnSheathe = 'rbxassetid://-1', -- equip

	Blocking = {
		NoShield = 'rbxassetid://-1',
		Shield = 'rbxassetid://-1',
	},

	BlockBreak = {
		NoShield = 'rbxassetid://-1',
		Shield = 'rbxassetid://-1',
	},
}

Module.AttackSets = {

	Default = { 'rbxassetid://-1' },

}

Module.AnimationSets = {

	Default = {
		Stunned = Module.Defaults.Stunned,
		Blocking = Module.Defaults.Blocking,
		BlockBroken = Module.Defaults.BlockBreak,

		Attacking = Module.AttackSets.Default, -- attack for both single and dual wield

		--[[Single = {
			Attacking = Module.AttackSets.Default,
		},

		Dual = {
			Attacking = Module.AttackSets.Default,
		},]]
	},

	-- // DUAL HANDED // --
	Daggers = {
		Stunned = Module.Defaults.Stunned,
		Blocking = Module.Defaults.Blocking,
		BlockBroken = Module.Defaults.BlockBreak,

		Single = {
			Attacking = Module.AttackSets.Default,
		},

		Dual = {
			Attacking = Module.AttackSets.Default,
		},
	},

	-- // SINGLE HANDED // --
	Shortsword = {
		Stunned = Module.Defaults.Stunned,
		Blocking = Module.Defaults.Blocking,
		BlockBroken = Module.Defaults.BlockBreak,

		Single = {
			Attacking = Module.AttackSets.Default,
		},
		Dual = false,
	},

	Longsword = {
		Stunned = Module.Defaults.Stunned,
		Blocking = Module.Defaults.Blocking,
		BlockBroken = Module.Defaults.BlockBreak,

		Single = {
			Attacking = Module.AttackSets.Default,
		},
		Dual = false,
	},

	Mace = {
		Stunned = Module.Defaults.Stunned,
		Blocking = Module.Defaults.Blocking,
		BlockBroken = Module.Defaults.BlockBreak,

		Single = {
			Attacking = Module.AttackSets.Default,
		},
		Dual = false,
	},

	Hammer = {
		Stunned = Module.Defaults.Stunned,
		Blocking = Module.Defaults.Blocking,
		BlockBroken = Module.Defaults.BlockBreak,

		Single = {
			Attacking = Module.AttackSets.Default,
		},
		Dual = false,
	},

	Waraxe = {
		Stunned = Module.Defaults.Stunned,
		Blocking = Module.Defaults.Blocking,
		BlockBroken = Module.Defaults.BlockBreak,

		Single = {
			Attacking = Module.AttackSets.Default,
		},
		Dual = false,
	},

}

--[[

	Dual Wield
	- Daggers

	One Handed (right)
	- Shortsword
	- Longsword
	- Mace
	- Hammer
	- Waraxe
]]

Module.Emotes = {
	Sleep = 'rbxassetid://-1',
}

function Module.ResolveWeaponAnimations( weaponType )
	local Animations = table.clone( Module.AnimationSets.Default )
	local AnimData = Module.AnimationSets[weaponType]
	if AnimData then
		for key, value in pairs( AnimData ) do
			if key == "Attacking" or key == "Single" or key == "Dual" then
				continue
			end
			Animations[key] = value
		end
		Animations.Single = AnimData.Single or AnimData.Attacking or Module.AnimationSets.Default.Attacking
		Animations.Dual = AnimData.Dual or AnimData.Attacking or Module.AnimationSets.Default.Attacking
	end
	return Animations
end

return Module
