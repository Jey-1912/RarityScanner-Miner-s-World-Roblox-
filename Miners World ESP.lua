-- Ore Scanner | Miners World - Final Optimized Version (English only, by Jey)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⛏️ Ore Scanner | Miners World",
    LoadingTitle = "Miners World ⛏️",
    LoadingSubtitle = "by Jey",
    ConfigurationSaving = { 
        Enabled = true, 
        FolderName = "OreScannerConfig", 
        FileName = "settings.json" 
    },
    KeySystem = false,
})

-- Services
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Rarities (no Rare)
local rarities = {
    Uncommon  = Color3.fromRGB(0, 255, 0),
    Epic      = Color3.fromRGB(138, 43, 226),
    Legendary = Color3.fromRGB(255, 255, 0),
    Mythic    = Color3.fromRGB(255, 0, 0),
    Ethereal  = Color3.fromRGB(255, 20, 147),
    Celestial = Color3.fromRGB(0, 255, 255),
    Zenith    = Color3.fromRGB(128, 0, 128),
    Divine    = Color3.fromRGB(0, 0, 0),
    Nil       = Color3.fromRGB(99, 95, 98),
}

local rarityList = {"Uncommon", "Epic", "Legendary", "Mythic", "Ethereal", "Celestial", "Zenith", "Divine", "Nil"}

-- Globals
local EnabledRarities = {}
local MaxBlocks = 200
local ShowCounts = false
local AutoScan = true

local createdESP = {}
local scanning = false
local lastScan = 0
local DEBOUNCE = 0.8  -- Increased to reduce lag

-- Counts Widget
local CountsWidget = nil

local function CreateCountsWidget()
    task.spawn(function()
        if CountsWidget then return end

        local gui = Instance.new("ScreenGui")
        gui.Name = "OreCountsWidget"
        gui.ResetOnSpawn = false
        gui.Parent = playerGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromScale(0.24, 0.36)
        frame.Position = UDim2.fromScale(0.38, 0.32)
        frame.BackgroundColor3 = Color3.fromRGB(18,18,22)
        frame.BackgroundTransparency = 0.15
        frame.Active = true
        frame.Draggable = true
        frame.Parent = gui

        local stroke = Instance.new("UIStroke", frame)
        stroke.Thickness = 1.5
        stroke.Color = Color3.fromRGB(60,60,70)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.fromScale(1,0.14)
        title.BackgroundTransparency = 1
        title.Text = "ORE COUNTS"
        title.Font = Enum.Font.GothamBlack
        title.TextScaled = true
        title.TextColor3 = Color3.fromRGB(240,240,255)

        local content = Instance.new("TextLabel", frame)
        content.Size = UDim2.fromScale(0.94,0.82)
        content.Position = UDim2.fromScale(0.03,0.16)
        content.BackgroundTransparency = 1
        content.TextColor3 = Color3.fromRGB(210,210,230)
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.TextWrapped = true
        content.TextSize = 14
        content.Font = Enum.Font.Gotham
        content.Text = "Loading..."

        local minBtn = Instance.new("TextButton", frame)
        minBtn.Size = UDim2.new(0,26,0,22)
        minBtn.Position = UDim2.new(1,-32,0,4)
        minBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
        minBtn.TextColor3 = Color3.new(1,1,1)
        minBtn.Font = Enum.Font.GothamBold
        minBtn.TextSize = 16
        minBtn.Text = "–"

        local minimized = false
        local origSize = frame.Size

        minBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            if minimized then
                frame.Size = UDim2.new(origSize.X.Scale, origSize.X.Offset, 0, 38)
                content.Visible = false
                minBtn.Text = "+"
            else
                frame.Size = origSize
                content.Visible = true
                minBtn.Text = "–"
            end
        end)

        CountsWidget = {Gui = gui, Frame = frame, Content = content}
    end)
end

local function DestroyCountsWidget()
    if CountsWidget then
        CountsWidget.Gui:Destroy()
        CountsWidget = nil
    end
end

local function UpdateCounts()
    if not ShowCounts or not CountsWidget then return end

    local counts = {}
    for _, name in ipairs(rarityList) do counts[name] = 0 end

    for _, hl in ipairs(workspace:GetDescendants()) do
        if hl:IsA("Highlight") and hl.Parent then
            local bb = hl.Parent:FindFirstChildWhichIsA("BillboardGui")
            if bb and bb:FindFirstChild("TextLabel") then
                local text = bb.TextLabel.Text
                if counts[text] then
                    counts[text] += 1
                end
            end
        end
    end

    local lines = {"Limit: " .. MaxBlocks, ""}
    for _, name in ipairs(rarityList) do
        lines[#lines+1] = name .. ": " .. counts[name]
    end

    CountsWidget.Content.Text = table.concat(lines, "\n")
end

-- Scanner + ESP logic
local function clearESP()
    for _, obj in ipairs(createdESP) do
        pcall(function() obj:Destroy() end)
    end
    table.clear(createdESP)
end

local function colorNear(a, b)
    return math.abs(a.R - b.R) < 0.18
       and math.abs(a.G - b.G) < 0.18
       and math.abs(a.B - b.B) < 0.18
end

local function getRealPart(emitter)
    local p = emitter.Parent
    if p:IsA("Attachment") then p = p.Parent end
    return p:IsA("BasePart") and p
end

local function scan()
    if scanning then return end
    if os.clock() - lastScan < DEBOUNCE then return end
    scanning = true
    lastScan = os.clock()

    clearESP()

    local processed = 0
    local seen = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if processed >= MaxBlocks then break end
        if not obj:IsA("ParticleEmitter") then continue end

        local part = getRealPart(obj)
        if not part or seen[part] then continue end

        local colors = {}
        if obj.Color then
            for _, kp in ipairs(obj.Color.Keypoints) do
                table.insert(colors, kp.Value)
            end
        end
        if #colors == 0 then continue end

        local found = nil
        for name, data in pairs(rarities) do
            if not EnabledRarities[name] then continue end
            for _, c in ipairs(colors) do
                if colorNear(c, data) then
                    found = name
                    break
                end
            end
            if found then break end
        end

        if found then
            seen[part] = true
            processed += 1

            local hl = Instance.new("Highlight")
            hl.Adornee = part
            hl.FillColor = rarities[found]
            hl.FillTransparency = 0.65
            hl.OutlineColor = Color3.new(1,1,1)
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.Occluded
            hl.Parent = part
            table.insert(createdESP, hl)

            local bb = Instance.new("BillboardGui")
            bb.Adornee = part
            bb.Size = UDim2.fromOffset(150, 36)
            bb.StudsOffset = Vector3.new(0, part.Size.Y + 0.8, 0)
            bb.AlwaysOnTop = true
            bb.Parent = part
            table.insert(createdESP, bb)

            local lbl = Instance.new("TextLabel", bb)
            lbl.Size = UDim2.fromScale(1,1)
            lbl.BackgroundTransparency = 1
            lbl.Text = found
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 18
            lbl.TextColor3 = rarities[found]
            lbl.TextStrokeTransparency = 0
            lbl.TextStrokeColor3 = Color3.new(0,0,0)
        end
    end

    scanning = false
    UpdateCounts()
end

-- Auto-scan
task.spawn(function()
    task.wait(1.5)
    while true do
        if AutoScan and next(EnabledRarities) then
            pcall(scan)
        end
        task.wait(4)  -- Higher interval to reduce lag
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ParticleEmitter") then task.delay(0.5, scan) end
end)

-- Rayfield UI
local Tab = Window:CreateTab("Scanner", nil)

Tab:CreateSection("Settings")

Tab:CreateSlider({
    Name = "Max Blocks to Scan",
    Range = {50, 1200},
    Increment = 25,
    CurrentValue = MaxBlocks,
    Callback = function(v)
        MaxBlocks = v
        task.delay(0.3, scan)
    end,
})

Tab:CreateToggle({
    Name = "Auto Scan",
    CurrentValue = true,
    Callback = function(v)
        AutoScan = v
    end,
})

Tab:CreateSection("Rarities (toggle to enable scan + count)")

task.spawn(function()
    for _, name in ipairs(rarityList) do
        task.wait(0.02)  -- Small delay to prevent freeze during toggle creation
        Tab:CreateToggle({
            Name = name,
            CurrentValue = false,
            Callback = function(v)
                EnabledRarities[name] = v
                task.delay(0.3, scan)
            end,
        })
    end
end)

Tab:CreateSection("Display")

Tab:CreateToggle({
    Name = "Show Counts Window",
    CurrentValue = false,
    Callback = function(v)
        ShowCounts = v
        if v then
            CreateCountsWidget()
            task.delay(0.6, UpdateCounts)
        else
            DestroyCountsWidget()
        end
    end,
})

Tab:CreateButton({
    Name = "Force Scan Now",
    Callback = scan
})

Rayfield:Notify({
    Title = "Ore Scanner Loaded",
    Content = "Toggle rarities to start scanning.",
    Duration = 5
})
