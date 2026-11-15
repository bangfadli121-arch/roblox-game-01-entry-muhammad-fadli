local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local WIDTH, HEIGHT = 640, 480
local COLORS = {
	background = Color3.fromRGB(12, 16, 25), panel = Color3.fromRGB(21, 28, 41),
	white = Color3.fromRGB(244, 247, 255), muted = Color3.fromRGB(166, 180, 199),
	orange = Color3.fromRGB(255, 111, 33), gold = Color3.fromRGB(255, 207, 61),
	red = Color3.fromRGB(243, 63, 60),
}

local gui = Instance.new("ScreenGui")
gui.Name = "EmberDash"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeFrame(parent, name, size, position, color, radius)
	local frame = Instance.new("Frame")
	frame.Name, frame.Size, frame.Position = name, size, position
	frame.BackgroundColor3, frame.BorderSizePixel = color, 0
	frame.Parent = parent
	if radius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, radius)
		corner.Parent = frame
	end
	return frame
end

local function makeLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name, label.Text = name, text
	label.Size, label.Position = size, position
	label.BackgroundTransparency, label.BorderSizePixel = 1, 0
	label.Font, label.TextSize, label.TextColor3 = Enum.Font.GothamBold, textSize, color
	label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Center, Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local arena = makeFrame(gui, "Arena", UDim2.fromOffset(WIDTH, HEIGHT), UDim2.fromScale(0.5, 0.5), COLORS.background, 14)
arena.AnchorPoint = Vector2.new(0.5, 0.5)
local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = WIDTH / HEIGHT
aspect.Parent = arena
local border = Instance.new("UIStroke")
border.Color, border.Thickness, border.Transparency = COLORS.orange, 2, 0.35
border.Parent = arena

local gameLayer = makeFrame(arena, "GameLayer", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), COLORS.background)
gameLayer.BackgroundTransparency = 1
local hud = makeFrame(arena, "HUD", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), COLORS.background)
hud.BackgroundTransparency = 1

local scoreLabel = makeLabel(hud, "Score", "SCORE  0", UDim2.fromOffset(260, 40), UDim2.new(0.5, -130, 0, 10), 27, COLORS.white)
local timerLabel = makeLabel(hud, "Timer", "00:00", UDim2.fromOffset(150, 25), UDim2.new(0.5, -75, 0, 49), 17, COLORS.muted)
local livesLabel = makeLabel(hud, "Lives", "♥  ♥  ♥", UDim2.fromOffset(145, 38), UDim2.new(1, -158, 0, 16), 23, COLORS.red)
livesLabel.TextXAlignment = Enum.TextXAlignment.Right

local overlay = makeFrame(arena, "Overlay", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), COLORS.background)
overlay.BackgroundTransparency = 0.12
local title = makeLabel(overlay, "Title", "EMBER DASH", UDim2.new(1, -40, 0, 74), UDim2.new(0, 20, 0, 115), 46, COLORS.orange)
local subtitle = makeLabel(overlay, "Subtitle", "DODGE THE LAVA  •  GRAB THE GOLD", UDim2.new(1, -40, 0, 30), UDim2.new(0, 20, 0, 182), 17, COLORS.white)
local bestLabel = makeLabel(overlay, "Best", "SESSION BEST  0", UDim2.new(1, -40, 0, 30), UDim2.new(0, 20, 0, 223), 17, COLORS.gold)
local actionButton = Instance.new("TextButton")
actionButton.Name, actionButton.Text = "ActionButton", "START"
actionButton.Size, actionButton.Position = UDim2.fromOffset(220, 60), UDim2.new(0.5, -110, 0, 278)
actionButton.BackgroundColor3, actionButton.TextColor3 = COLORS.orange, COLORS.white
actionButton.Font, actionButton.TextSize = Enum.Font.GothamBlack, 24
actionButton.AutoButtonColor, actionButton.Parent = true, overlay
local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 12)
buttonCorner.Parent = actionButton
local hint = makeLabel(overlay, "Hint", "MOVE WITH WASD OR ARROW KEYS", UDim2.new(1, -40, 0, 25), UDim2.new(0, 20, 0, 355), 14, COLORS.muted)
local countdown = makeLabel(arena, "Countdown", "", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), 76, COLORS.white)
countdown.Visible = false
countdown.BackgroundTransparency = 1

local state = "menu"
local bestScore, score, lives, elapsed = 0, 0, 3, 0
local playerX, playerY = WIDTH / 2, HEIGHT - 100
local invulnerableUntil, nextCoinAt, nextHazardAt = 0, 1.2, 1.5
local hazards, coins = {}, {}
local orb
local random = Random.new()

local function setState(nextState)
	state = nextState
	overlay.Visible = nextState == "menu" or nextState == "over"
	hud.Visible = nextState == "playing" or nextState == "countdown"
	gameLayer.Visible = nextState == "playing" or nextState == "countdown"
	countdown.Visible = nextState == "countdown"
end

local function clearObjects()
	for _, item in hazards do item.view:Destroy() end
	for _, item in coins do item.view:Destroy() end
	table.clear(hazards)
	table.clear(coins)
end

local function makeOrb()
	orb = makeFrame(gameLayer, "Ember", UDim2.fromOffset(28, 28), UDim2.fromOffset(playerX - 14, playerY - 14), COLORS.orange, 14)
	local glow = Instance.new("UIStroke")
	glow.Color, glow.Thickness, glow.Transparency = COLORS.gold, 3, 0.1
	glow.Parent = orb
end

local function placeObject(item)
	item.view.Position = UDim2.fromOffset(item.x - item.size / 2, item.y - item.size / 2)
end

local function spawnCoin()
	local size = 22
	local view = makeFrame(gameLayer, "GoldCoin", UDim2.fromOffset(size, size), UDim2.fromOffset(0, 0), COLORS.gold, 11)
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = Color3.fromRGB(255, 240, 160), 2
	stroke.Parent = view
	table.insert(coins, { view = view, x = random:NextInteger(40, WIDTH - 40), y = random:NextInteger(100, HEIGHT - 45), size = size })
end

local function spawnHazard(difficulty)
	local size = random:NextInteger(24, 38)
	local view = makeFrame(gameLayer, "Lava", UDim2.fromOffset(size, size), UDim2.fromOffset(0, 0), COLORS.red, 7)
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = Color3.fromRGB(255, 143, 84), 2
	stroke.Parent = view
	local speed = 122 + difficulty * 22 + random:NextInteger(0, 48)
	table.insert(hazards, { view = view, x = random:NextInteger(28, WIDTH - 28), y = -size, size = size, speed = speed, drift = random:NextNumber(-65, 65) })
end

local function showMenu()
	title.Text, subtitle.Text, bestLabel.Text = "EMBER DASH", "DODGE THE LAVA  •  GRAB THE GOLD", "SESSION BEST  " .. bestScore
	actionButton.Text, hint.Text = "START", "MOVE WITH WASD OR ARROW KEYS"
	setState("menu")
end

local function finishRun()
	local finalScore = math.floor(score)
	bestScore = math.max(bestScore, finalScore)
	title.Text, subtitle.Text = "GAME OVER", "FINAL SCORE  " .. finalScore .. "   •   BEST  " .. bestScore
	bestLabel.Text = "PRESS R OR CLICK TO RESTART"
	actionButton.Text, hint.Text = "PLAY AGAIN", "DODGE LAVA  •  COLLECT COINS"
	setState("over")
	local remote = ReplicatedStorage:FindFirstChild("SubmitScore")
	if remote and remote:IsA("RemoteEvent") then remote:FireServer(finalScore) end
end

local function startRun()
	clearObjects()
	score, lives, elapsed = 0, 3, 0
	playerX, playerY = WIDTH / 2, HEIGHT - 100
	invulnerableUntil, nextCoinAt, nextHazardAt = 0, 1.2, 1.5
	makeOrb()
	setState("countdown")
	local token = os.clock()
	task.spawn(function()
		for n = 3, 1, -1 do
			if state ~= "countdown" or os.clock() - token > 5 then return end
			countdown.Text = tostring(n)
			task.wait(1)
		end
		if state == "countdown" then countdown.Text = "DASH!"; task.wait(0.35) end
		if state == "countdown" then setState("playing") end
	end)
end

actionButton.Activated:Connect(startRun)
UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.R and state == "over" then startRun() end
end)

local function moving(keyA, keyB)
	return UserInputService:IsKeyDown(keyA) or UserInputService:IsKeyDown(keyB)
end

local function updatePlayer(dt, now)
	local dx = (moving(Enum.KeyCode.D, Enum.KeyCode.Right) and 1 or 0) - (moving(Enum.KeyCode.A, Enum.KeyCode.Left) and 1 or 0)
	local dy = (moving(Enum.KeyCode.S, Enum.KeyCode.Down) and 1 or 0) - (moving(Enum.KeyCode.W, Enum.KeyCode.Up) and 1 or 0)
	if dx ~= 0 or dy ~= 0 then
		local length = math.sqrt(dx * dx + dy * dy)
		playerX += dx / length * 270 * dt
		playerY += dy / length * 270 * dt
	end
	playerX, playerY = math.clamp(playerX, 18, WIDTH - 18), math.clamp(playerY, 76, HEIGHT - 18)
	orb.Position = UDim2.fromOffset(playerX - 14, playerY - 14)
	orb.Visible = now >= invulnerableUntil or math.floor(now * 12) % 2 == 0
end

local function overlaps(item, radius)
	local dx, dy = item.x - playerX, item.y - playerY
	local reach = radius + item.size / 2
	return dx * dx + dy * dy <= reach * reach
end

local function updateCoins(dt)
	for i = #coins, 1, -1 do
		local item = coins[i]
		if overlaps(item, 15) then
			score += 100
			item.view:Destroy()
			table.remove(coins, i)
		elseif item.y < -30 then
			item.view:Destroy()
			table.remove(coins, i)
		end
	end
end

local function updateHazards(dt, now)
	for i = #hazards, 1, -1 do
		local item = hazards[i]
		item.x += item.drift * dt
		if item.x < 18 or item.x > WIDTH - 18 then item.drift = -item.drift end
		item.y += item.speed * dt
		placeObject(item)
		if overlaps(item, 12) and now >= invulnerableUntil then
			lives -= 1
			invulnerableUntil = now + 1.5
			if lives <= 0 then
				finishRun()
				return false
			end
		elseif item.y > HEIGHT + item.size then
			item.view:Destroy()
			table.remove(hazards, i)
		end
	end
	return true
end

local function updateHud()
	scoreLabel.Text = "SCORE  " .. math.floor(score)
	timerLabel.Text = string.format("%02d:%02d", math.floor(elapsed / 60), math.floor(elapsed % 60))
	livesLabel.Text = string.rep("♥  ", lives)
end

RunService.RenderStepped:Connect(function(dt)
	if state == "countdown" then return end
	if state ~= "playing" then return end
	local now = os.clock()
	elapsed += dt
	local difficulty = math.floor(elapsed / 15)
	score += 10 * dt
	if elapsed >= nextCoinAt then
		spawnCoin()
		nextCoinAt = elapsed + math.max(0.8, 1.4 - difficulty * 0.045)
	end
	if elapsed >= nextHazardAt then
		spawnHazard(difficulty)
		nextHazardAt = elapsed + math.max(0.38, 1.55 - difficulty * 0.085)
	end
	updatePlayer(dt, now)
	updateCoins(dt)
	if not updateHazards(dt, now) then return end
	updateHud()
end)

local remote = ReplicatedStorage:WaitForChild("SubmitScore", 10)
if remote and remote:IsA("RemoteEvent") then
	remote.OnClientEvent:Connect(function(serverBest)
		if typeof(serverBest) == "number" then
			bestScore = math.max(bestScore, serverBest)
			if state == "menu" then bestLabel.Text = "SESSION BEST  " .. bestScore end
		end
	end)
end
showMenu()
