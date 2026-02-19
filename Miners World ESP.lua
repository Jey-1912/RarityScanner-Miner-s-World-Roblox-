-- Rarity Scanner + ESP por bloco (OTIMIZADO, sem lag)
-- Adaptado para GUI Rayfield
-- LocalScript

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
    if #hex ~= 6 then return Color3.new(1,1,1) end
    local r = tonumber(hex:sub(1,2), 16) or 255
    local g = tonumber(hex:sub(3,4), 16) or 255
    local b = tonumber(hex:sub(5,6), 16) or 255
    return Color3.fromRGB(r,g,b)
end

local function isInsideBreaking(obj)
    return breakingFolder ~= nil and obj:IsDescendantOf(breakingFolder)
end

--------------------------------------------------
-- CONFIG
--------------------------------------------------
local MAX_BLOCKS = 200
local RESCAN_DEBOUNCE = 0.35
local YIELD_EVERY = 120

--------------------------------------------------
-- Raridades
--------------------------------------------------
local rarities = {
    Uncommon = {Color = hexToColor3("#00ff00")},
    Rare = {Color = hexToColor3("#1e90ff")},
    Epic = {Color = hexToColor3("#8a2be2")},
    Legendary = {Color = hexToColor3("#ffff00")},
    Mythic = {Color = hexToColor3("#ff0000")},
    Ethereal = {Color = hexToColor3("#ff1493")},
    Celestial = {Color = hexToColor3("#00ffff")},
    Zenith = {Color = hexToColor3("#800080")},
    Divine = {Color = hexToColor3("#000000")},
    Nil = {Color = hexToColor3("#635f62")}
}

-- Estados das raridades
local enabled = {}
for name in pairs(rarities) do
    enabled[name] = false
end

--------------------------------------------------
-- Utilidades de match
--------------------------------------------------
local function colorNear(a,b)
    return math.abs(a.R - b.R) < 0.18 and math.abs(a.G - b.G) < 0.18 and math.abs(a.B - b.B) < 0.18
end

local function getEmitterColors(emitter)
    if not emitter.Color then return nil end
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
-- ESP
--------------------------------------------------
local createdESP = {}

local function clearESP()
    for _,obj in ipairs(createdESP) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
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

--------------------------------------------------
-- TRACKING de ParticleEmitters
--------------------------------------------------
local trackedEmitters = {}

local function trackEmitter(emitter)
    if trackedEmitters[emitter] then return end
    if isInsideBreaking(emitter) then return end
    trackedEmitters[emitter] = true
end

local function untrackEmitter(emitter)
    trackedEmitters[emitter] = nil
end

-- Scan inicial
for _,obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("ParticleEmitter") then
        trackEmitter(obj)
    end
end

--------------------------------------------------
-- Scan coalescido
--------------------------------------------------
local scanPending = false
local scanning = false
local lastRequest = 0

local function doScan()
    if scanning then return end
    scanning = true
    scanPending = false
    clearESP()

    local counts = {}
    for name in pairs(rarities) do
        counts[name] = 0
    end

    local markedParts = {}
    local processed = 0
    local stepCount = 0

    for emitter in pairs(trackedEmitters) do
        if processed >= MAX_BLOCKS then break end

        if not emitter or not emitter.Parent then
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
                            processed += 1
                            createESP(part, found, rarities[found].Color)
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

    -- Atualizar contadores na GUI
    local countText = "📊 CONTAGEM DE MINÉRIOS\n"
    countText ..= "Limite: "..tostring(MAX_BLOCKS).."\n"
    countText ..= "────────────────\n"
    
    local sortedNames = {}
    for name in pairs(rarities) do
        table.insert(sortedNames, name)
    end
    table.sort(sortedNames)
    
    for _,name in ipairs(sortedNames) do
        if enabled[name] then
            countText ..= string.format("🟢 %s: %d\n", name, counts[name] or 0)
        else
            countText ..= string.format("⚪ %s: %d\n", name, counts[name] or 0)
        end
    end

    Rayfield:Notify({
        Title = "Scan Concluído",
        Content = countText,
        Duration = 5,
        Image = 4483362458,
    })

    scanning = false
end

local function requestScan()
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

--------------------------------------------------
-- CRIAÇÃO DA GUI RAYFIELD
--------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Rarity Scanner",
    LoadingTitle = "Carregando Scanner...",
    LoadingSubtitle = "by Sistema ESP",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RarityScanner",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Chave Necessária",
        Subtitle = "Digite a chave de acesso",
        Note = "Adquira a chave com o desenvolvedor",
        FileName = "Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {"12345"}
    }
})

--------------------------------------------------
-- ABA PRINCIPAL
--------------------------------------------------
local MainTab = Window:CreateTab("Principal", 4483362458)
local MainSection = MainTab:CreateSection("Controles do Scanner")

-- Status do scanner
local StatusLabel = MainTab:CreateLabel("Status: Aguardando scan...")

-- Botão de scan manual
MainTab:CreateButton({
    Name = "🔍 Escanear Agora",
    Callback = function()
        StatusLabel:Set("Status: Escaneando...")
        requestScan()
        task.wait(0.5)
        StatusLabel:Set("Status: Scan realizado!")
    end,
})

-- Slider para MAX_BLOCKS
MainTab:CreateSlider({
    Name = "Limite de Blocos",
    Range = {50, 1000},
    Increment = 10,
    Suffix = "blocos",
    CurrentValue = MAX_BLOCKS,
    Flag = "blockslider",
    Callback = function(Value)
        MAX_BLOCKS = Value
        StatusLabel:Set("Status: Limite alterado para "..Value)
        requestScan()
    end,
})

--------------------------------------------------
-- ABA RARIDADES
--------------------------------------------------
local RarityTab = Window:CreateTab("Raridades", 4483362458)
local RaritySection = RarityTab:CreateSection("Selecione as raridades")

-- Toggle para cada raridade
for name in pairs(rarities) do
    RarityTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Flag = "toggle_"..name,
        Callback = function(Value)
            enabled[name] = Value
            requestScan()
        end,
    })
end

--------------------------------------------------
-- ABA CONTADORES
--------------------------------------------------
local CountTab = Window:CreateTab("Contadores", 4483362458)
local CountSection = CountTab:CreateSection("Estatísticas")

-- Label para mostrar contagem
local CountDisplay = CountTab:CreateLabel("Aguardando scan...")

-- Botão atualizar contagem
CountTab:CreateButton({
    Name = "🔄 Atualizar Contagem",
    Callback = function()
        local counts = {}
        for name in pairs(rarities) do
            counts[name] = 0
        end

        for emitter in pairs(trackedEmitters) do
            if emitter and emitter.Parent and not isInsideBreaking(emitter) then
                local part = getRealPartFromEmitter(emitter)
                if part and part.Parent then
                    local colors = getEmitterColors(emitter)
                    if colors then
                        for rarityName, data in pairs(rarities) do
                            for _,c in ipairs(colors) do
                                if colorNear(c, data.Color) then
                                    counts[rarityName] += 1
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        local text = "📊 CONTAGEM ATUAL\n"
        text ..= "Limite: "..MAX_BLOCKS.."\n"
        text ..= "────────────────\n"
        
        local sortedNames = {}
        for name in pairs(rarities) do
            table.insert(sortedNames, name)
        end
        table.sort(sortedNames)
        
        for _,name in ipairs(sortedNames) do
            if enabled[name] then
                text ..= string.format("🟢 %s: %d\n", name, counts[name] or 0)
            else
                text ..= string.format("⚪ %s: %d\n", name, counts[name] or 0)
            end
        end

        CountDisplay:Set(text)
    end,
})

--------------------------------------------------
-- ABA AJUDA
--------------------------------------------------
local HelpTab = Window:CreateTab("Ajuda", 4483362458)
local HelpSection = HelpTab:CreateSection("Informações")

HelpTab:CreateParagraph({
    Title = "Como usar",
    Content = "1. Selecione as raridades desejadas\n2. Ajuste o limite de blocos\n3. O escaneamento é automático\n4. Blocos encontrados serão destacados"
})

HelpTab:CreateParagraph({
    Title = "Cores",
    Content = "Uncommon: Verde\nRare: Azul\nEpic: Roxo\nLegendary: Amarelo\nMythic: Vermelho\nEthereal: Rosa\nCelestial: Ciano\nZenith: Roxo escuro\nDivine: Preto\nNil: Cinza"
})

HelpTab:CreateButton({
    Name = "✅ Entendi",
    Callback = function()
        Rayfield:Notify({
            Title = "Pronto!",
            Content = "Bom uso do scanner!",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

--------------------------------------------------
-- EVENTOS AUTOMÁTICOS
--------------------------------------------------
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

-- Scan inicial
task.wait(1)
requestScan()

-- Atualizar status periodicamente
task.spawn(function()
    while true do
        task.wait(2)
        local count = 0
        for _ in pairs(trackedEmitters) do
            count += 1
        end
        StatusLabel:Set(string.format("Status: Ativo | Emitters: %d | Limite: %d", count, MAX_BLOCKS))
    end
end)

print("Rarity Scanner carregado com GUI Rayfield!")
