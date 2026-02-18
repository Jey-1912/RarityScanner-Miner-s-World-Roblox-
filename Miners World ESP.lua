-- Ore Scanner | Miners World - Versão Completa 2025 (tudo em 1 raw)
-- Coloque esse script inteiro no seu raw

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⛏️ Ore Scanner | Miners World",
    LoadingTitle = "Miners World ⛏️",
    LoadingSubtitle = "by Jean",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- Serviços
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Raridades
local function hexToColor3(hex)
    hex = hex:gsub("#","")
    local r = tonumber(hex:sub(1,2),16) or 255
    local g = tonumber(hex:sub(3,4),16) or 255
    local b = tonumber(hex:sub(5,6),16) or 255
    return Color3.fromRGB(r or 255, g or 255, b or 255)
end

local rarities = {
    Uncommon  = {Color = hexToColor3("#00ff00")},
    Rare      = {Color = hexToColor3("#1e90ff")},
    Epic      = {Color = hexToColor3("#8a2be2")},
    Legendary = {Color = hexToColor3("#ffff00")},
    Mythic    = {Color = hexToColor3("#ff0000")},
    Ethereal  = {Color = hexToColor3("#ff1493")},
    Celestial = {Color = hexToColor3("#00ffff")},
    Zenith    = {Color = hexToColor3("#800080")},
    Divine    = {Color = hexToColor3("#000000")},
    Nil       = {Color = hexToColor3("#635f62")},
}

local rarityList = {"Uncommon","Rare","Epic","Legendary","Mythic","Ethereal","Celestial","Zenith","Divine","Nil"}

-- Variáveis globais
local EnabledRarities = {}
local MaxBlocks = 200
local ShowCounts = false

local createdESP = {}
local scanning = false
local lastScan = 0
local DEBOUNCE = 0.45

-- Widget de contagem (janela separada)
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
    content.Text = "Carregando..."

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

    local lines = {"Limite: " .. MaxBlocks, ""}
    for _, name in ipairs(rarityList) do
        lines[#lines+1] = name .. ": " .. counts[name]
    end

    CountsWidget.Content.Text = table.concat(lines, "\n")
end

-- Lógica do Scanner + ESP
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

-- Auto-scan
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

-- Interface Rayfield
local Tab = Window:CreateTab("Scanner", nil)

Tab:CreateSection("Configurações")

Tab:CreateSlider({
    Name = "Máximo de blocos",
    Range = {50, 1200},
    Increment = 25,
    CurrentValue = MaxBlocks,
    Callback = function(v)
        MaxBlocks = v
        task.delay(0.2, scan)
    end,
})

Tab:CreateSection("Raridades (ative para escanear + contar)")

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

Tab:CreateSection("Visualização")

Tab:CreateToggle({
    Name = "Mostrar janela de contagem",
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
    Name = "Forçar Scan Agora",
    Callback = scan
})

Rayfield:Notify({
    Title = "Ore Scanner Carregado",
    Content = "Ative as raridades desejadas para começar.",
    Duration = 5.5
})
