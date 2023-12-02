local Debris = game:GetService("Debris")

local Module = {}

function Module.PlaySoundAtPosition( sound : Sound, position : Vector3, speedMultiplier : number? ) : Sound
	local attachment = Instance.new('Attachment')
	attachment.Name = 'SoundPoint'
	attachment.WorldCFrame = CFrame.new(position)
	attachment.Parent = workspace.Terrain

	sound = sound:Clone()
	if speedMultiplier then
		sound.PlaybackSpeed *= speedMultiplier
	end
	sound:Play()
	sound.Parent = attachment
	Debris:AddItem( attachment, sound.TimeLength )

	return sound
end

return Module
