local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local bestByUserId = {}
local submitScore = Instance.new("RemoteEvent")
submitScore.Name = "SubmitScore"
submitScore.Parent = ReplicatedStorage

local function safePlayer(player)
	return typeof(player) == "Instance" and player:IsA("Player") and player.Parent == Players
end

local function bestFor(player)
	return bestByUserId[player.UserId] or 0
end

local function sendBest(player)
	local ok, err = pcall(function()
		submitScore:FireClient(player, bestFor(player))
	end)
	if not ok then
		warn("EMBER DASH could not send best score: " .. tostring(err))
	end
end

local function acceptScore(player, score)
	if not safePlayer(player) or typeof(score) ~= "number" then
		return
	end
	if score ~= score or score < 0 or score > 100000000 or score % 1 ~= 0 then
		return
	end
	if score > bestFor(player) then
		bestByUserId[player.UserId] = score
	end
	sendBest(player)
end

local okConnect, connectErr = pcall(function()
	submitScore.OnServerEvent:Connect(acceptScore)
end)
if not okConnect then
	warn("EMBER DASH could not connect score handler: " .. tostring(connectErr))
end

local okJoin, joinErr = pcall(function()
	Players.PlayerAdded:Connect(sendBest)
	for _, player in Players:GetPlayers() do
		task.defer(sendBest, player)
	end
end)
if not okJoin then
	warn("EMBER DASH could not initialize player replies: " .. tostring(joinErr))
end
