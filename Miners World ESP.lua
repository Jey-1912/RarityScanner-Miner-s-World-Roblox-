-- Ore Counter (Rayfield) | SEM ESP | SEM RARE
-- Detecta raridades por ParticleEmitter.Color (keypoints)
-- Mostra apenas texto + janela de contagem arrastável e minimizável

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local breakingFolder = workspace:FindFirstChild("Breaking")

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function hexToColor3(hex)
	hex = hex:gsub("#","")
	if #hex == 3 then
		hex = hex:sub(1,1)..hex:sub(1,1)..hex:sub(2,2)..hex:sub(2,2)..hex:sub(3,3)..hex:sub(3,3)
	end
	if #hex ~= 6 then
		return Color3.new(1,1,1)
	end
	local r = tonumber(hex:sub(1,2), 16) or 255
	local g = tonumber(hex:sub(3,4), 16) or 255
	local b = tonumber(hex:sub(5,6), 16) or 255
	return Color3.fromRGB(r,g,b)
end

local function isInsideBreaking(obj)
	return breakingFolder ~= nil and obj:IsDescendantOf(breakingFolder)
end

local function colorNear(a,b)
	return math.abs(a.R - b.R) < 0.18
	   and math.abs(a.G - b.G) < 0.18
	   and math.abs(a.B - b.B) < 0.18
end

local function getEmitterColors(emitter)
	if not emitter or not emitter.Color then return nil end
	local colors = {}
	for _,kp in ipairs(emitter.Color.Keypoints) do
		table.insert(colors, kp.Value)
	end
	return colors
end

local function getRealPartFromEmitter(emitter)
	local p = emitter.Parent
	if p and p:IsA("Attachment") then
		p = p.Parent
	end
	if p and p:IsA("BasePart") then
		return p
	end
	return nil
end

--------------------------------------------------
-- Config
--------------------------------------------------
local MAX_BLOCKS = 200
local RESCAN_DEBOUNCE = 0.35
local YIELD_EVERY = 120

-- ✅ SEM "Rare"
local rarities = {
	Uncommon  = {Color = hexToColor3("#00ff00")},
	Epic      = {Color = hexToColor3("#8a2be2")},
	Legendary = {Color = hexToColor3("#ffff00")},
	Mythic    = {Color = hexToColor3("#ff0000")},
	Ethereal  = {Color = hexToColor3("#ff1493")},
	Celestial = {Color = hexToColor3("#00ffff")},
	Zenith    = {Color = hexToColor3("#800080")},
	Divine    = {Color = hexToColor3("#000000")},
	Nil       = {Color = hexToColor3("#635f62")},
}

local enabled = {}
for name in pairs(rarities) do
	enabled[name] = false
end

--------------------------------------------------
-- Rayfield Window
--------------------------------------------------
local Window = Rayfield:CreateWindow({
	Name = "⛏️ Ore Counter | Miners World",
	LoadingTitle = "Miners World ⛏️",
	LoadingSubtitle = "Counts only (no ESP)",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "OreCounter",
		FileName = "settings"
	},
	KeySystem = false,
})

local ScannerTab = Window:CreateTab("Scanner")
local CountsTab  = Window:CreateTab("Counts")

ScannerTab:CreateSection("Scanner Settings")

ScannerTab:CreateSlider({
	Name = "Max Blocks (limit)",
	Range = {1, 5000},
	Increment = 1,
	CurrentValue = MAX_BLOCKS,
	Flag = "MaxBlocksSlider",
	Callback = function(v)
		MAX_BLOCKS = v
		requestScan()
	end,
})

ScannerTab:CreateParagraph({
	Title = "Info",
	Content = "Marque as raridades para contar. Isso NÃO cria ESP, só texto/contagem."
})

ScannerTab:CreateSection("Rarities (sem Rare)")
local rarityOrder = {"Uncommon","Epic","Legendary","Mythic","Ethereal","Celestial","Zenith","Divine","Nil"}
for _, name in ipairs(rarityOrder) do
	ScannerTab:CreateToggle({
		Name = name,
		CurrentValue = false,
		Flag = name .. "Toggle",
		Callback = function(v)
			enabled[name] = v
			requestScan()
		end,
	})
end

--------------------------------------------------
-- Counts GUI (arrastável + minimizável)
--------------------------------------------------
local CountsGui = nil

local function makeMinimizable(frame, titleLabel, contentObjects)
	local minimized = false
	local originalSize = frame.Size
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 28, 0, 22)
	btn.Position = UDim2.new(1, -34, 0, 6)
	btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
	btn.BorderSizePixel = 0
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.Text = "–"
	btn.Parent = frame

	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(80,80,80)
	st.Parent = btn

	local function apply()
		if minimized then
			frame.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 48)
			btn.Text = "+"
			for _,obj in ipairs(contentObjects) do
				if obj and obj.Parent then obj.Visible = false end
			end
		else
			frame.Size = originalSize
			btn.Text = "–"
			for _,obj in ipairs(contentObjects) do
				if obj and obj.Parent then obj.Visible = true end
			end
		end
		if titleLabel then titleLabel.Visible = true end
	end

	btn.MouseButton1Click:Connect(function()
		minimized = not minimized
		apply()
	end)

	apply()
end

local function CreateCountsGui()
	if CountsGui then CountsGui.Gui:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "OreCountsRayfield"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(0.26, 0.32)
	frame.Position = UDim2.fromScale(0.43, 0.28)
	frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(55,55,55)
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1,0.18)
	title.BackgroundTransparency = 1
	title.Text = "COUNTS"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255,255,255)
	title.Parent = frame

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(0.92,0.78)
	text.Position = UDim2.fromScale(0.04,0.20)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1,1,1)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.TextSize = 14
	text.Font = Enum.Font.Gotham
	text.Text = "Sem dados."
	text.Parent = frame

	makeMinimizable(frame, title, {text})

	CountsGui = {Gui = gui, Text = text}
end

local function DestroyCountsGui()
	if CountsGui then
		CountsGui.Gui:Destroy()
		CountsGui = nil
	end
end

local function updateCountsGUI(counts, totalFound, emittersCount)
	if not CountsGui or not CountsGui.Text then return end

	local lines = {}
	table.insert(lines, "MAX_BLOCKS: " .. tostring(MAX_BLOCKS))
	table.insert(lines, "Emitters rastreados: " .. tostring(emittersCount))
	table.insert(lines, "Ores identificados: " .. tostring(totalFound))
	table.insert(lines, "")

	for _,name in ipairs(rarityOrder) do
		table.insert(lines, string.format("%s: %d", name, counts[name] or 0))
	end

	CountsGui.Text.Text = table.concat(lines, "\n")
end

CountsTab:CreateSection("Counts Window")

CountsTab:CreateToggle({
	Name = "Show Counts Window",
	CurrentValue = true,
	Flag = "ShowCounts",
	Callback = function(v)
		if v then
			CreateCountsGui()
			requestScan()
		else
			DestroyCountsGui()
		end
	end,
})

CountsTab:CreateButton({
	Name = "Force Scan Now",
	Callback = function()
		requestScan()
		Rayfield:Notify({Title="Scan", Content="Scan solicitado.", Duration=2})
	end
})

-- cria por padrão
CreateCountsGui()

--------------------------------------------------
-- Tracking de ParticleEmitters (cache)
--------------------------------------------------
local trackedEmitters = {} -- [emitter] = true

local function trackEmitter(emitter)
	if trackedEmitters[emitter] then return end
	if isInsideBreaking(emitter) then return end
	trackedEmitters[emitter] = true
end

local function untrackEmitter(emitter)
	trackedEmitters[emitter] = nil
end

for _,obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("ParticleEmitter") then
		trackEmitter(obj)
	end
end

--------------------------------------------------
-- Scan coalescido (somente contagem / texto)
--------------------------------------------------
local scanPending = false
local scanning = false
local lastRequest = 0

function doScan()
	if scanning then return end
	scanning = true
	scanPending = false

	local counts = {}
	for name in pairs(rarities) do counts[name] = 0 end

	local markedParts = {}
	local processed = 0
	local stepCount = 0
	local totalFound = 0

	for emitter in pairs(trackedEmitters) do
		if processed >= MAX_BLOCKS then break end

		if (not emitter) or (not emitter.Parent) then
			trackedEmitters[emitter] = nil
		else
			if not isInsideBreaking(emitter) then
				local part = getRealPartFromEmitter(emitter)
				if part and part.Parent and (not isInsideBreaking(part)) and (not markedParts[part]) then
					local colors = getEmitterColors(emitter)
					if colors then
						local found = nil
						for rarityName, data in pairs(rarities) do
							if enabled[rarityName] then
								for _,c in ipairs(colors) do
									if colorNear(c, data.Color) then
										found = rarityName
										break
									end
								end
							end
							if found then break end
						end

						if found then
							markedParts[part] = true
							counts[found] += 1
							totalFound += 1
							processed += 1
						end
					end
				end
			end
		end

		stepCount += 1
		if stepCount >= YIELD_EVERY then
			stepCount = 0
			RunService.Heartbeat:Wait()
		end
	end

	-- contador de emitters
	local emittersCount = 0
	for _ in pairs(trackedEmitters) do emittersCount += 1 end

	updateCountsGUI(counts, totalFound, emittersCount)

	scanning = false
end

function requestScan()
	lastRequest = os.clock()
	if scanPending then return end
	scanPending = true

	task.delay(RESCAN_DEBOUNCE, function()
		if os.clock() - lastRequest >= RESCAN_DEBOUNCE - 0.01 then
			doScan()
		else
			scanPending = false
			requestScan()
		end
	end)
end

-- eventos
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("ParticleEmitter") then
		trackEmitter(obj)
		requestScan()
	end
end)

workspace.DescendantRemoving:Connect(function(obj)
	if obj:IsA("ParticleEmitter") then
		untrackEmitter(obj)
		requestScan()
	end
end)

-- scan inicial (vai mostrar 0 até marcar toggles)
Rayfield:LoadConfiguration()
requestScan()
