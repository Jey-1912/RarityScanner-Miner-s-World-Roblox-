-- Ore Scanner | Miners World - Rayfield Version (English, by Jey, Save Tab Removed, Fixed Errors)
-- Atualizado com otimizações anti-lag: remoção de varredura pesada, debounce pending, remoção de eventos globais

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⛏️ Ore Scanner | Miners World",
    LoadingTitle = "Miners World ⛏️",
    LoadingSubtitle = "by Jey",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "OreScanner",
        FileName = "settings"
    },
    KeySystem = false,
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local breakingFolder = workspace:FindFirstChild("Breaking")

-- Pasta para scan (placeholder: workspace inteiro; troque pra pasta dos ores pra otimizar mais)
local scanFolder = workspace  -- Ex: workspace:FindFirstChild("MiningArea") ou workspace.Ores

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
    return math.abs(a.R - b.R) < 0.18
        and math.abs(a.G - b.G) < 0.18
        and math.abs(a.B - b.B) < 0.18
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

-- Minimize function
local function makeMinimizable(frame, titleLabel, contentObjects)
    local minimized = false
    local originalSize = frame.Size
    local btn = Instance.new("TextButton")
    btn.Name = "MinimizeButton"
    btn.Size = UDim2.new(0, 28, 0, 22)
    btn.Position = UDim2.new(1, -34, 0, 6)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Text = "–"
    btn.Parent = frame

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(80,80,80)
    btnStroke.Parent = btn

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
        btn.Visible = true
    end

    btn.MouseButton1Click:Connect(function()
        minimized = not minimized
        apply()
    end)
    apply()

    return function() return minimized end
end

-- Rarities
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

local MAX_BLOCKS    = 200
local SCAN_DEBOUNCE = 0.5  -- Aumentado pra dar mais folga
local createdESP    = {}

local function anyEnabled()
    for _, v in pairs(enabled) do
        if v then return true end
    end
    return false
end

local function zeroCounts()
    local counts = {}
    for name in pairs(rarities) do
        counts[name] = 0
    end
    return counts
end

local function clearESP()
    -- Só limpa o que está rastreado (sem varredura pesada no workspace)
    for _, obj in ipairs(createdESP) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    table.clear(createdESP)
end

local function createESP(part, rarityName, color)
    local highlight = Instance.new("Highlight")
    highlight.Name = "OreScannerHighlight"
    highlight.Adornee = part
    highlight.FillColor = color
    highlight.FillTransparency = 0.65
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = part
    table.insert(createdESP, highlight)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "OreScannerBillboard"
    billboard.Size = UDim2.fromOffset(150, 36)
    billboard.StudsOffset = Vector3.new(0, part.Size.Y + 0.6, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    table.insert(createdESP, billboard)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.Text = rarityName
    label.Font = Enum.Font.GothamBold
    label.TextScaled = false
    label.TextSize = 18
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0,0,0)
    label.Parent = billboard
end

-- SCAN principal (protegido e debounced)
local scanning = false
local lastScan = 0
local pendingScan = false  -- Novo: flag pra coalescing

local function scan()
    if scanning then return end
    if os.clock() - lastScan < SCAN_DEBOUNCE then return end

    scanning = true
    lastScan = os.clock()
    pendingScan = false  -- Reseta após rodar

    local success, err = pcall(function()
        clearESP()

        local counts = zeroCounts()
        local processed = 0
        local markedParts = {}

        for _, obj in ipairs(scanFolder:GetDescendants()) do  -- Usa scanFolder em vez de workspace
            if processed >= MAX_BLOCKS then break end
            if not obj:IsA("ParticleEmitter") then continue end
            if isInsideBreaking(obj) then continue end

            local part = getRealPartFromEmitter(obj)
            if not part then continue end
            if isInsideBreaking(part) then continue end
            if markedParts[part] then continue end

            local colors = getEmitterColors(obj)
            if not colors then continue end

            local foundRarity
            for rarityName, data in pairs(rarities) do
                if enabled[rarityName] then
                    for _, c in ipairs(colors) do
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
    end)

    scanning = false

    if not success then
        warn("[OreScanner] scan error: " .. tostring(err))
    end
end

-- Loop leve pra checar pending (roda a cada 0.1s, mas é super leve)
task.spawn(function()
    while true do
        task.wait(0.1)
        if pendingScan and not scanning then
            scan()
        end
    end
end)

-- Interface de contagem (sem mudanças)
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

    makeMinimizable(frame, title, {countText})

    CountsGui = {Gui = gui, Text = countText}
end

local function DestroyCountsGui()
    if CountsGui then
        CountsGui.Gui:Destroy()
        CountsGui = nil
    end
end

local function updateCountsGUI(counts)
    if not CountsGui then return end

    local lines = {}
    table.insert(lines, "Limit: " .. tostring(MAX_BLOCKS))
    table.insert(lines, "")

    local names = {}
    for name in pairs(rarities) do table.insert(names, name) end
    table.sort(names)

    for _, name in ipairs(names) do
        table.insert(lines, string.format("%s: %d", name, counts[name] or 0))
    end

    CountsGui.Text.Text = table.concat(lines, "\n")
end

-- Interface (Rayfield)
local ScannerTab = Window:CreateTab("Scanner", nil)

ScannerTab:CreateSection("Scanner Settings")

ScannerTab:CreateSlider({
    Name = "Max Blocks",
    Range = {1, 5000},
    Increment = 1,
    CurrentValue = MAX_BLOCKS,
    Flag = "MaxBlocksSlider",
    Callback = function(v)
        MAX_BLOCKS = v
        pendingScan = true  -- Marca pending em vez de chamar direto
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

            if not anyEnabled() then
                clearESP()
                if CountsGui then
                    updateCountsGUI(zeroCounts())
                end
                return
            end

            pendingScan = true  -- Marca pending
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
            pendingScan = true
        else
            DestroyCountsGui()
        end
    end,
})

-- Carrega configurações salvas
Rayfield:LoadConfiguration()

-- Auto scan em background (só roda se tiver algo ativado)
task.spawn(function()
    while true do
        task.wait(5)
        if anyEnabled() then
            pendingScan = true  -- Marca pending pro loop checar
        end
    end
end)

-- Eventos comentados (removidos pra anti-lag; descomente e troque workspace por scanFolder se quiser reativar restrito)
--[[
scanFolder.DescendantAdded:Connect(function(obj)
    if obj:IsA("ParticleEmitter") then pendingScan = true end
end)

scanFolder.DescendantRemoving:Connect(function(obj)
    if obj:IsA("ParticleEmitter") then pendingScan = true end
end)
--]]

-- Scan inicial
pendingScan = true
