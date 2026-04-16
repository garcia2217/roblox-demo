local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Config = require(ReplicatedStorage.Shared.Config)
local OreTypes = require(ReplicatedStorage.Shared.OreTypes)

-- Background music (parented to SoundService = non-positional, heard everywhere)
local bgm = Instance.new("Sound")
bgm.SoundId = Config.SOUNDS.BackgroundMusic
bgm.Volume = Config.BGM_VOLUME
bgm.Looped = true
bgm.Parent = SoundService
bgm:Play()

local CoinSoundEvent = ReplicatedStorage.Events:WaitForChild("CoinSoundEvent")
local FloatingCoinsEvent = ReplicatedStorage.Events:WaitForChild("FloatingCoinsEvent")

-- Coin sound plays only for the local player
local coinSound = Instance.new("Sound")
coinSound.SoundId = Config.SOUNDS.CoinPickup
coinSound.Volume = 0.8
coinSound.Parent = workspace

CoinSoundEvent.OnClientEvent:Connect(function()
	coinSound:Play()
end)

-- Floating "+N coins" label rising from the ore's break position
FloatingCoinsEvent.OnClientEvent:Connect(function(position, amount, oreType)
	local oreColor = OreTypes[oreType] and OreTypes[oreType].color.Color or Color3.new(1, 1, 1)

	-- Invisible anchor part so BillboardGui has a world position to attach to
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CastShadow = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Position = position
	anchor.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 120, 0, 40)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+" .. amount
	label.TextColor3 = oreColor
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.5
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	-- Float upward
	TweenService:Create(anchor, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = position + Vector3.new(0, 6, 0),
	}):Play()

	-- Fade out text, then destroy anchor
	local fade = TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	fade:Play()
	fade.Completed:Connect(function()
		anchor:Destroy()
	end)
end)
