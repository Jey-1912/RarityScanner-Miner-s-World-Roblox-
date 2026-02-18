-- Ore Scanner | Miners World - Updated Version (all in 1 raw)
-- Changes: Removed Rare, fully in English, translation library via dropdown, config saving enabled

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⛏️ Ore Scanner | Miners World",
    LoadingTitle = "Miners World ⛏️",
    LoadingSubtitle = "by Jean",
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

-- Translation library (string tables for English and Portuguese)
local Translations = {
    English = {
        WindowTitle = "⛏️ Ore Scanner | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "by Jean",
        TabName = "Scanner",
        ConfigSection = "Settings",
        MaxBlocksSlider = "Max Blocks to Scan",
        RaritiesSection = "Rarities (toggle to scan + count)",
        DisplaySection = "Display",
        ShowCountsToggle = "Show Counts Window",
        ForceScanButton = "Force Scan Now",
        NotifyLoaded = "Ore Scanner Loaded",
        NotifyContent = "Toggle rarities to start scanning.",
        CountsTitle = "ORE COUNTS",
        CountsLoading = "Loading...",
        LimitLabel = "Limit: "
    },
    Portuguese = {
        WindowTitle = "⛏️ Ore Scanner | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "por Jean",
        TabName = "Scanner",
        ConfigSection = "Configurações",
        MaxBlocksSlider = "Máximo de Blocos para Escanear",
        RaritiesSection = "Raridades (ative para escanear + contar)",
        DisplaySection = "Visualização",
        ShowCountsToggle = "Mostrar Janela de Contagem",
        ForceScanButton = "Forçar Scan Agora",
        NotifyLoaded = "Ore Scanner Carregado",
        NotifyContent = "Ative as raridades para começar.",
        CountsTitle = "CONTAGEM DE ORES",
        CountsLoading = "Carregando...",
        LimitLabel = "Limite: "
    }
}

local CurrentLanguage = "English"  -- Default
local Strings = Translations[CurrentLanguage]  -- Current strings

-- Function to update UI with new language
local function UpdateLanguage(lang)
    CurrentLanguage = lang
    Strings = Translations[lang]
    -- Rayfield doesn't support dynamic renaming of existing elements, so reload the window or notify user to reopen
    Rayfield:Notify({
        Title = "Language Changed",
        Content = "Reopen the GUI to apply changes fully.",
        Duration = 5
    })
    -- Note: For full dynamic update, you'd need to recreate tabs/elements, but Rayfield limits this. User can reopen.
end

-- Rarities (removed Rare)
local function hexToColor3(hex)
    hex = hex:gsub("#","")
    local r = tonumber(hex:sub(1,2),16) or 255
    local g = tonumber(hex:sub(3,4),16) or 255
    local b = tonumber(hex:sub(5,6),16) or 255
    return Color3.fromRGB(r,g,b)
end

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

local rarityList = {"Uncommon","Epic","Legendary","Mythic","Ethereal","Celestial","Zenith","Divine","Nil"}

-- Globals
local EnabledRarities = {}
local MaxBlocks = 200
local ShowCounts = false

local createdESP = {}
local scanning = false
local lastScan = 0
local DEBOUNCE = 0.45

-- Counts Widget
local CountsWidget = nil

local function CreateCountsWidget()
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
    title.Text = Strings.CountsTitle
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
    content.Text = Strings.CountsLoading

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

    local lines = {Strings.LimitLabel .. MaxBlocks, ""}
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
                if colorNear(c, data.Color) then
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
            hl.FillColor = rarities[found].Color
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
            lbl.TextColor3 = rarities[found].Color
            lbl.TextStrokeTransparency = 0
            lbl.TextStrokeColor3 = Color3.new(0,0,0)
        end
    end

    scanning = false
    UpdateCounts()
end

-- Auto-scan loop
task.spawn(function()
    task.wait(1.5)
    while true do
        if next(EnabledRarities) then
            pcall(scan)
        end
        task.wait(2.5)
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ParticleEmitter") then task.delay(0.4, scan) end
end)

-- Rayfield UI
local Tab = Window:CreateTab(Strings.TabName, nil)

Tab:CreateSection(Strings.ConfigSection)

Tab:CreateDropdown({
    Name = "Language",
    Options = {"English", "Portuguese"},
    CurrentOption = {"English"},
    Callback = function(opt)
        UpdateLanguage(opt[1])
    end,
})

Tab:CreateSlider({
    Name = Strings.MaxBlocksSlider,
    Range = {50, 1200},
    Increment = 25,
    CurrentValue = MaxBlocks,
    Callback = function(v)
        MaxBlocks = v
        task.delay(0.2, scan)
    end,
})

Tab:CreateSection(Strings.RaritiesSection)

for _, name in ipairs(rarityList) do
    Tab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Callback = function(state)
            EnabledRarities[name] = state
            task.delay(0.2, scan)
        end,
    })
end

Tab:CreateSection(Strings.DisplaySection)

Tab:CreateToggle({
    Name = Strings.ShowCountsToggle,
    CurrentValue = false,
    Callback = function(state)
        ShowCounts = state
        if state then
            CreateCountsWidget()
            task.delay(0.6, UpdateCounts)
        else
            DestroyCountsWidget()
        end
    end,
})

Tab:CreateButton({
    Name = Strings.ForceScanButton,
    Callback = scan
})

Rayfield:Notify({
    Title = Strings.NotifyLoaded,
    Content = Strings.NotifyContent,
    Duration = 5.5
})
