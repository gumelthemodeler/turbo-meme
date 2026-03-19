-- @ScriptType: LocalScript
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local TRACK_IDS = {
	134094755226119,
	1846749782,
	1846749640,
	1846749192,
	1846748840,
	1837230263,
	1846751619,
	101659615219397,
	1846748706,
	1846749472,
	1847245367
}

local bgmPlayer = Instance.new("Sound")
bgmPlayer.Name = "BizarreBGM"
bgmPlayer.Volume = 0.4
bgmPlayer.Parent = SoundService

local lastTrackIndex = 0

task.spawn(function()
	task.wait(2)

	while true do
		local nextTrackIndex = math.random(1, #TRACK_IDS)
		if #TRACK_IDS > 1 then
			while nextTrackIndex == lastTrackIndex do
				nextTrackIndex = math.random(1, #TRACK_IDS)
			end
		end
		lastTrackIndex = nextTrackIndex

		local trackId = TRACK_IDS[nextTrackIndex]
		bgmPlayer.SoundId = "rbxassetid://" .. tostring(trackId)

		pcall(function()
			ContentProvider:PreloadAsync({bgmPlayer})
		end)

		bgmPlayer:Play()

		if bgmPlayer.TimeLength > 0 then
			bgmPlayer.Ended:Wait()
		else
			task.wait(5)
		end

		task.wait(math.random(1, 3))
	end
end)