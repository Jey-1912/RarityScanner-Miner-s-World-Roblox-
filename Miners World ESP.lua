-- Ore Scanner | Miners World - Rayfield Version (English, by Jey, Back to Original Scan)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⛏️ Ore Scanner | Miners World",
    LoadingTitle = "Miners World ⛏️",
    LoadingSubtitle = "by Jey",
    ConfigurationSaving = { Enabled = true, FolderName = "OreScanner", FileName = "settings" },
    KeySystem = false,
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local breakingFolder = workspace:FindFirstChild("Breaking")

-- Helpers
local function hexToColor3(hex)
    hex = hex:gsub("#","")
    if #hex == 3 then hex = hex:sub(1,1)..hex:sub(1,1)..hex:sub(2,2)..hex:sub(2,2)..hex:sub(3,3)..hex:sub(3,3) end
    if #hex ~= 6 then return Color3.new(1,1,1) end
    local r = tonumber(hex:sub(1,2), 16) or 255
    local g = tonumber(hex:sub(3,4), 16) or 255
    local b = tonumber(hex:sub(5,6), 16) or 255
    return Color3.fromRGB(r,g,b)
end

local function isInsideBreaking(obj)
    return breakingFolder ~= nil and obj:IsDescendantOf(breakingFolder)
end

local function colorNear(a, b)
    return math.abs(a.R - b.R) < 0.18 and math.abs(a.G - b.G) < 0.18 and math.abs(a.B - b.B) < 0.18
end

local function getEmitterColors(emitter)
    if not emitter.Color then return nil end
    local colors = {}
    for _, kp in ipairs(emitter.Color.Keypoints) do
        table.insert(colors, kp.Value)
    end
    return colors
end

local function getRealPartFromEmitter(emitter)
    local p = emitter.Parent
    if p and p:IsA("Attachment") then p = p.Parent end
    if p and p:IsA("BasePart") then return p end
    return nil
end

-- Rarities (no Rare, no Emerald)
local rarities = {
    Uncommon  = {Color = hexToColor3("#00ff00")},
    Epic      = {Color = hexToColor3("#8a2be2")},
    Legendary = {Color = hexToColor3("#ffff00")},
    Mythic    = {Color = hexToColor3("#ff0000")},
    Ethereal  = {Color = hexToColor3("#ff1493")},
    Celestial = {Color = hexToColor3("#00ffff")},
    Zenith    = {Color = hexToColor3("#800080")},
    Divine    = {Color = hexToColor3("#000000")},
    Nil       = {Color = hexToColor3("#635f62")}
}

local enabled = {}
for name in pairs(rarities) do enabled[name] = false end

local MAX_BLOCKS = 200
local SCAN_DEBOUNCE = 0.35

local createdESP = {}

local function clearESP()
    for _, obj in ipairs(createdESP) do pcall(function() obj:Destroy() end) end
    table.clear(createdESP)
end

local function createESP(part, rarityName, color)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = part
    highlight.FillColor = color
    highlight.FillTransparency = 0.65
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = part
    table.insert(createdESP, highlight)

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(150, 36)
    billboard.StudsOffset = Vector3.new(0, part.Size.Y + 0.6, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    table.insert(createdESP, billboard)

    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.Text = rarityName
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0,0,0)
end

-- SCAN (volta ao original)
local scanning = false
local lastScan = 0

local function scan()
    if scanning then return end
    if os.clock() - lastScan < SCAN_DEBOUNCE then return end

    scanning = true
    lastScan = os.clock()

    clearESP()

    local counts = {}
    for name in pairs(rarities) do counts[name] = 0 end

    local processed = 0
    local markedParts = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if processed >= MAX_BLOCKS then break end
        if not obj:IsA("ParticleEmitter") then continue end
        if isInsideBreaking(obj) then continue end
        local part = getRealPartFromEmitter(obj)
        if not part then continue end
        if isInsideBreaking(part) then continue end
        if markedParts[part] then continue end
        local colors = getEmitterColors(obj)
        if not colors then continue end
        local foundRarity = nil
        for rarityName, data in pairs(rarities) do
            if enabled[rarityName] then
                for _,c in ipairs(colors) do
                    if colorNear(c, data.Color) then
                        foundRarity = rarityName
                        break
                    end
                end
            end
            if foundRarity then break end
        end
        if foundRarity then
            markedParts[part] = true
            counts[foundRarity] += 1
            processed += 1
            createESP(part, foundRarity, rarities[foundRarity].Color)
        end
    end

    updateCountsGUI(counts)
    scanning = false
end

-- Counts GUI with minimize and close
local CountsGui = nil
local function CreateCountsGui()
    if CountsGui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "OreCounts"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(0.26, 0.32)
    frame.Position = UDim2.fromScale(0.43, 0.28)
    frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
    frame.BackgroundTransparency = 0.1
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

    local countText = Instance.new("TextLabel")
    countText.Size = UDim2.fromScale(0.92,0.78)
    countText.Position = UDim2.fromScale(0.04,0.20)
    countText.BackgroundTransparency = 1
    countText.TextColor3 = Color3.new(1,1,1)
    countText.TextXAlignment = Enum.TextXAlignment.Left
    countText.TextYAlignment = Enum.TextYAlignment.Top
    countText.TextWrapped = true
    countText.TextSize = 14
    countText.Font = Enum.Font.Gotham
    countText.Text = "No data yet."
    countText.Parent = frame

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0,26,0,22)
    minBtn.Position = UDim2.new(1,-58,0,4)
    minBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
    minBtn.TextColor3 = Color3.new(1,1,1)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    minBtn.Text = "–"
    minBtn.Parent = frame

    local minimized = false
    local origSize = frame.Size

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            frame.Size = UDim2.new(origSize.X.Scale, origSize.X.Offset, 0, 38)
            countText.Visible = false
            minBtn.Text = "+"
        else
            frame.Size = origSize
            countText.Visible = true
            minBtn.Text = "–"
        end
    end)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,26,0,22)
    closeBtn.Position = UDim2.new(1,-28,0,4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Text = "X"
    closeBtn.Parent = frame

    closeBtn.MouseButton1Click:Connect(function()
        DestroyCountsGui()
    end)

    CountsGui = {Gui = gui, Text = countText}
end

local function DestroyCountsGui()
    if CountsGui then
        CountsGui.Gui:Destroy()
        CountsGui = nil
    end
end

local function updateCountsGUI(counts)
    if not CountsGui or not CountsGui.Text then return end
    local lines = {"Limit: " .. tostring(MAX_BLOCKS), ""}
    local names = {}
    for n in pairs(rarities) do table.insert(names, n) end
    table.sort(names)
    for _, name in ipairs(names) do
        lines[#lines+1] = name .. ": " .. (counts[name] or 0)
    end
    CountsGui.Text.Text = table.concat(lines, "\n")
end

-- Tabs
local ScannerTab = Window:CreateTab("Scanner", nil)
local SaveTab = Window:CreateTab("Save Menu", nil)

ScannerTab:CreateSection("Scanner Settings")

ScannerTab:CreateSlider({
    Name = "Max Blocks",
    Range = {1, 5000},
    Increment = 1,
    CurrentValue = MAX_BLOCKS,
    Flag = "MaxBlocksSlider",
    Callback = function(v)
        MAX_BLOCKS = v
        task.defer(scan)
    end,
})

ScannerTab:CreateSection("Rarities")

for _, name in ipairs({"Uncommon", "Epic", "Legendary", "Mythic", "Ethereal", "Celestial", "Zenith", "Divine", "Nil"}) do
    ScannerTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Flag = name .. "Toggle",
        Callback = function(v)
            enabled[name] = v
            task.defer(scan)
        end,
    })
end

ScannerTab:CreateToggle({
    Name = "Show Counts Window",
    CurrentValue = false,
    Flag = "ShowCountsToggle",
    Callback = function(v)
        if v then
            CreateCountsGui()
            task.defer(scan)
        else
            DestroyCountsGui()
        end
    end,
})

-- Save Tab
SaveTab:CreateSection("Save/Load Configuration")

local configNameInput = SaveTab:CreateInput({
    Name = "Config File Name",
    PlaceholderText = "Enter file name (default: settings)",
    RemoveTextAfterFocusLost = false,
    Callback = function(text) end,
})

SaveTab:CreateButton({
    Name = "Save/Overwrite Config",
    Callback = function()
        local newName = configNameInput.CurrentValue or "settings"
        Window.ConfigurationSaving.FileName = newName
        Rayfield:SaveConfiguration()
        Rayfield:Notify({Title = "Config Saved", Content = "Saved as " .. newName, Duration = 3})
    end,
})

SaveTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        local newName = configNameInput.CurrentValue or "settings"
        Window.ConfigurationSaving.FileName = newName
        Rayfield:LoadConfiguration()
        Rayfield:Notify({Title = "Config Loaded", Content = "Loaded from " .. newName, Duration = 3})
        task.defer(scan)
    end,
})

Rayfield:LoadConfiguration()

-- Auto scan setup
task.defer(scan)

task.spawn(function()
    while true do
        task.wait(5)
        if next(enabled) then pcall(scan) end
    end
end)
