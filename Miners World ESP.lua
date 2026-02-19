-- Ore Scanner | Miners World - Rayfield Version (Corrigido: Counter GUI + Anti-Lag)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⛏️ Ore Scanner | Miners World",
    LoadingTitle = "Miners World ⛏️",
    LoadingSubtitle = "by Jey - Fixed Counter",
    ConfigurationSaving = { Enabled = true, FolderName = "OreScanner", FileName = "settings" },
    KeySystem = false,
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local breakingFolder = workspace:FindFirstChild("Breaking")

-- Pasta de scan (workspace inteiro por enquanto; se achar pasta de ores, troque)
local scanFolder = workspace

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
    return breakingFolder and obj:IsDescendantOf(breakingFolder)
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

-- Minimize (mantido igual)
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
            for _,obj in contentObjects do if obj and obj.Parent then obj.Visible = false end end
        else
            frame.Size = originalSize
            btn.Text = "–"
            for _,obj in contentObjects do if obj and obj.Parent then obj.Visible = true end end
        end
        titleLabel.Visible = true
        btn.Visible = true
    end

    btn.MouseButton1Click:Connect(function() minimized = not minimized apply() end)
    apply()
    return function() return minimized end
end

-- Rarities (incluindo Rare que tinha no original)
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
    Nil       = {Color = hexToColor3("#635f62")}
}

local enabled = {}
for name in pairs(rarities) do enabled[name] = false end

local MAX_BLOCKS = 200
local SCAN_DEBOUNCE = 0.8  -- Aumentado pra reduzir lag
local createdESP = {}

local function anyEnabled()
    for _,v in enabled do if v then return true end end
    return false
end

local function zeroCounts()
    local c = {}
    for n in pairs(rarities) do c[n] = 0 end
    return c
end

local function clearESP()
    for _,obj in createdESP do if obj and obj.Parent then obj:Destroy() end end
    table.clear(createdESP)
end

local function createESP(part, rarityName, color)
    local h = Instance.new("Highlight")
    h.Name = "OreScannerHighlight"
    h.Adornee = part
    h.FillColor = color
    h.FillTransparency = 0.65
    h.OutlineColor = Color3.new(1,1,1)
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.Occluded
    h.Parent = part
    table.insert(createdESP, h)

    local bb = Instance.new("BillboardGui")
    bb.Name = "OreScannerBillboard"
    bb.Size = UDim2.fromOffset(150,36)
    bb.StudsOffset = Vector3.new(0, part.Size.Y + 0.6, 0)
    bb.AlwaysOnTop = true
    bb.Parent = part
    table.insert(createdESP, bb)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1,1)
    lbl.BackgroundTransparency = 1
    lbl.Text = rarityName
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 18
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0,0,0)
    lbl.Parent = bb
end

local scanning = false
local lastScan = 0

local function scan()
    if scanning then return end
    if os.clock() - lastScan < SCAN_DEBOUNCE then return end
    scanning = true
    lastScan = os.clock()

    local ok, err = pcall(function()
        clearESP()
        local counts = zeroCounts()
        local processed = 0
        local marked = {}

        for _,obj in scanFolder:GetDescendants() do
            if processed >= MAX_BLOCKS then break end
            if not obj:IsA("ParticleEmitter") then continue end
            if isInsideBreaking(obj) then continue end

            local part = getRealPartFromEmitter(obj)
            if not part or isInsideBreaking(part) or marked[part] then continue end

            local colors = getEmitterColors(obj)
            if not colors then continue end

            local found
            for rName, data in rarities do
                if enabled[rName] then
                    for _,c in colors do
                        if colorNear(c, data.Color) then
                            found = rName
                            break
                        end
                    end
                end
                if found then break end
            end

            if found then
                marked[part] = true
                counts[found] += 1
                processed += 1
                createESP(part, found, rarities[found].Color)
            end
        end

        updateCountsGUI(counts)
        print("[OreScanner] Scan concluído - " .. processed .. " ores encontrados")
    end)

    scanning = false
    if not ok then
        warn("[OreScanner] Erro no scan: " .. tostring(err))
    end
end

-- GUI Counts (mais robusta)
local CountsGui = nil

local function CreateCountsGui()
    if CountsGui then CountsGui.Gui:Destroy() end  -- Limpa se existir duplicata

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
    text.Text = "Sem dados ainda."
    text.Parent = frame

    makeMinimizable(frame, title, {text})

    CountsGui = {Gui = gui, Text = text}
    updateCountsGUI(zeroCounts())  -- Inicializa zerado
end

local function DestroyCountsGui()
    if CountsGui then CountsGui.Gui:Destroy() CountsGui = nil end
end

local function updateCountsGUI(counts)
    if not CountsGui or not CountsGui.Text or not CountsGui.Text.Parent then 
        warn("[OreScanner] CountsGui não encontrada ou destruída!")
        return 
    end

    local lines = {"Limite: " .. MAX_BLOCKS, ""}
    local names = {}
    for n in pairs(rarities) do table.insert(names, n) end
    table.sort(names)
    for _,n in names do
        table.insert(lines, n .. ": " .. (counts[n] or 0))
    end
    CountsGui.Text.Text = table.concat(lines, "\n")
end

-- Tab
local Tab = Window:CreateTab("Scanner")

Tab:CreateSection("Configurações")
Tab:CreateSlider({
    Name = "Max Blocks",
    Range = {1,5000},
    Increment = 1,
    CurrentValue = MAX_BLOCKS,
    Callback = function(v)
        MAX_BLOCKS = v
        task.defer(scan)
    end
})

Tab:CreateSection("Raridades")
for _, name in {"Uncommon","Rare","Epic","Legendary","Mythic","Ethereal","Celestial","Zenith","Divine","Nil"} do
    Tab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Callback = function(v)
            enabled[name] = v
            if not anyEnabled() then
                clearESP()
                if CountsGui then updateCountsGUI(zeroCounts()) end
                return
            end
            task.defer(scan)
        end
    })
end

Tab:CreateSection("Contador")
Tab:CreateToggle({
    Name = "Mostrar Janela de Contagem",
    CurrentValue = false,
    Callback = function(v)
        if v then
            CreateCountsGui()
            task.defer(scan)  -- Força scan ao abrir
        else
            DestroyCountsGui()
        end
    end
})

-- Botão de teste pra confirmar GUI
Tab:CreateButton({
    Name = "Teste: Forçar Update Contador",
    Callback = function()
        CreateCountsGui()
        local test = zeroCounts()
        test.Uncommon = 99; test.Epic = 50; test.Legendary = 10
        updateCountsGUI(test)
        Rayfield:Notify({Title="Teste", Content="Contador forçado! Veja se mudou.", Duration=4})
    end
})

Rayfield:LoadConfiguration()

-- Loop auto-scan
task.spawn(function()
    while true do
        task.wait(5)
        if anyEnabled() then task.defer(scan) end
    end
end)

-- Inicial
task.defer(scan)
