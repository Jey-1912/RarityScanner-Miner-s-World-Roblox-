-- Ore Scanner | Miners World - Rayfield Version (OTIMIZADO SEM LAG)
-- Corrigido: Teleporte apenas no eixo Y | Scan otimizado | Taxa atualizável

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⛏️ Ore Scanner + Teleports | Miners World",
    LoadingTitle = "Miners World ⛏️",
    LoadingSubtitle = "by Jey - SEM LAG | Taxa ajustável",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "OreScanner",
        FileName = "settings"
    },
    KeySystem = false,
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local breakingFolder = workspace:FindFirstChild("Breaking")

-- Helpers
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

-- CONFIG
local MAX_BLOCKS = 200
local SCAN_INTERVAL = 3
local YIELD_EVERY = 120
local SCAN_ENABLED = false -- Só escaneia se tiver raridade ativa

-- Rarities
local rarities = {
    Uncommon = {Color = hexToColor3("#00ff00")},
    Epic = {Color = hexToColor3("#8a2be2")},
    Legendary = {Color = hexToColor3("#ffff00")},
    Mythic = {Color = hexToColor3("#ff0000")},
    Ethereal = {Color = hexToColor3("#ff1493")},
    Celestial = {Color = hexToColor3("#00ffff")},
    Zenith = {Color = hexToColor3("#800080")},
    Divine = {Color = hexToColor3("#000000")},
    Nil = {Color = hexToColor3("#635f62")}
}

local enabled = {}
for name in pairs(rarities) do
    enabled[name] = false
end

-- Match utilities (tolerância ajustada)
local function colorNear(a,b)
    return math.abs(a.R - b.R) < 0.25 and 
           math.abs(a.G - b.G) < 0.25 and 
           math.abs(a.B - b.B) < 0.25
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
    if not emitter then return nil end
    local p = emitter.Parent
    if p and p:IsA("Attachment") then
        p = p.Parent
    end
    if p and p:IsA("BasePart") and p ~= workspace then
        return p
    end
    return nil
end

-- Minimize function
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

-- Counts GUI
local CountsGui = nil

local function CreateCountsGui()
    if CountsGui then CountsGui.Gui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "OreCounts"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 100

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
    text.Text = "No data yet."
    text.Parent = frame

    makeMinimizable(frame, title, {text})

    CountsGui = {Gui = gui, Text = text}
end

local function DestroyCountsGui()
    if CountsGui then
        pcall(function() CountsGui.Gui:Destroy() end)
        CountsGui = nil
    end
end

local function updateCountsGUI(counts)
    if not CountsGui or not CountsGui.Text then return end
    local lines = {}
    table.insert(lines, "Limit: " .. tostring(MAX_BLOCKS))
    table.insert(lines, "")
    local names = {}
    for name in pairs(rarities) do table.insert(names, name) end
    table.sort(names)
    for _,name in ipairs(names) do
        table.insert(lines, string.format("%s: %d", name, counts[name] or 0))
    end
    CountsGui.Text.Text = table.concat(lines, "\n")
end

-- ESP Management (otimizado)
local espParts = {}
local espCleanupConnections = {}

local function cleanupESP(part)
    if espCleanupConnections[part] then
        espCleanupConnections[part]:Disconnect()
        espCleanupConnections[part] = nil
    end
end

local function clearESP()
    for part, esp in pairs(espParts) do
        pcall(function()
            if esp.highlight and esp.highlight.Parent then
                esp.highlight:Destroy()
            end
            if esp.billboard and esp.billboard.Parent then
                esp.billboard:Destroy()
            end
        end)
        cleanupESP(part)
    end
    table.clear(espParts)
end

local function removeESP(part)
    local esp = espParts[part]
    if esp then
        pcall(function()
            if esp.highlight and esp.highlight.Parent then
                esp.highlight:Destroy()
            end
            if esp.billboard and esp.billboard.Parent then
                esp.billboard:Destroy()
            end
        end)
        cleanupESP(part)
        espParts[part] = nil
    end
end

local function createESP(part, rarityName, color)
    if not part or not part.Parent then return end
    
    removeESP(part)
    
    -- Monitora quando a parte for destruída ou entrar no Breaking
    espCleanupConnections[part] = part.AncestryChanged:Connect(function()
        if not part.Parent or isInsideBreaking(part) then
            removeESP(part)
        end
    end)
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = part
    highlight.FillColor = color
    highlight.FillTransparency = 0.65
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = part

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(150, 36)
    billboard.StudsOffset = Vector3.new(0, part.Size.Y + 0.6, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

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
    
    espParts[part] = {
        highlight = highlight,
        billboard = billboard,
        rarity = rarityName
    }
end

-- ========== SISTEMA DE TELEPORTE CORRIGIDO ==========
-- Coordenadas corretas: X=0, Z=0, Y variável

local teleportLocations = {
    -- Positivos
    {Name = "🏠 Superfície", Y = 1},
    {Name = "⬆️ Altitude 1", Y = 501},
    {Name = "⬆️ Altitude 2", Y = 1001},
    {Name = "⬆️ Altitude 3", Y = 1501},
    {Name = "⬆️ Altitude 4", Y = 2001},
    {Name = "⬆️ Altitude 5", Y = 2501},
    {Name = "⬆️ Altitude 6", Y = 3001},
    
    -- Negativos
    {Name = "⬇️ Profundidade 1", Y = -499},
    {Name = "⬇️ Profundidade 2", Y = -999},
    {Name = "⬇️ Profundidade 3", Y = -1499},
    {Name = "⬇️ Profundidade 4", Y = -1999},
    {Name = "⬇️ Profundidade 5", Y = -2499},
    {Name = "⬇️ Profundidade 6", Y = -2999},
    {Name = "⬇️ Profundidade 7", Y = -3499},
    {Name = "⬇️ Profundidade 8", Y = -3999},
    {Name = "⬇️ Profundidade 9", Y = -4499},
    {Name = "⬇️ Profundidade 10", Y = -4999},
    {Name = "⬇️ Profundidade 11", Y = -5499},
    {Name = "⬇️ Profundidade 12", Y = -5999},
    {Name = "⬇️ Profundidade 13", Y = -6499},
    {Name = "⬇️ Profundidade 14", Y = -6999},
    {Name = "⬇️ Profundidade 15", Y = -7499},
    {Name = "⬇️ Profundidade 16", Y = -7999},
}

-- Função de teleporte OTIMIZADA (sem lag)
local function teleportToY(targetY)
    -- Garante que targetY é número
    targetY = tonumber(targetY)
    if not targetY then return end
    
    local character = player.Character
    if not character then
        -- Tenta aguardar o personagem
        character = player.CharacterAdded:Wait(2)
        if not character then
            Rayfield:Notify({
                Title = "Erro",
                Content = "Personagem não encontrado!",
                Duration = 3,
            })
            return
        end
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        Rayfield:Notify({
            Title = "Erro",
            Content = "HumanoidRootPart não encontrado!",
            Duration = 3,
        })
        return
    end
    
    -- CORREÇÃO: Garante que X e Z são 0
    local newPos = Vector3.new(0, targetY, 0)
    
    -- Teleporta suavemente
    humanoidRootPart.CFrame = CFrame.new(newPos)
    
    -- Notificação
    Rayfield:Notify({
        Title = "Teleportado!",
        Content = string.format("Y: %.0f", targetY),
        Duration = 2,
    })
end

-- Funções de navegação
local function teleportToSurface()
    teleportToY(1)
end

local function goUp()
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local currentY = hrp.Position.Y
    local targetY
    
    -- Encontra o próximo Y válido acima
    if currentY < 1 then
        targetY = 1
    elseif currentY >= 3001 then
        targetY = 3001
    else
        -- Para positivos: 1, 501, 1001...
        targetY = math.floor((currentY + 500) / 500) * 500 + 1
        if targetY > 3001 then targetY = 3001 end
    end
    
    teleportToY(targetY)
end

local function goDown()
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local currentY = hrp.Position.Y
    local targetY
    
    -- Encontra o próximo Y válido abaixo
    if currentY > -499 then
        targetY = -499
    elseif currentY <= -7999 then
        targetY = -7999
    else
        -- Para negativos: -499, -999, -1499...
        targetY = math.floor((currentY - 500) / 500) * 500 - 499
        if targetY < -7999 then targetY = -7999 end
    end
    
    teleportToY(targetY)
end

-- ========== SCAN FUNCTIONS OTIMIZADAS ==========
local scanning = false
local scanRequested = false
lastScanTime = 0

local function zeroCounts()
    local counts = {}
    for name in pairs(rarities) do counts[name] = 0 end
    return counts
end

local function shouldScan()
    if not SCAN_ENABLED then return false end
    for _, v in pairs(enabled) do
        if v then return true end
    end
    return false
end

local function performFullScan()
    if scanning or not shouldScan() then return end
    scanning = true
    
    -- Limita a frequência do scan
    if tick() - lastScanTime < 1 then
        scanning = false
        return
    end
    
    local success, err = pcall(function()
        -- Remove ESP de partes inválidas
        for part in pairs(espParts) do
            if not part or not part.Parent or isInsideBreaking(part) then
                removeESP(part)
            end
        end
        
        local counts = zeroCounts()
        local processed = 0
        local stepCount = 0
        
        -- Scan mais eficiente: procura apenas por Parts com ParticleEmitters
        for _, part in ipairs(workspace:GetDescendants()) do
            if processed >= MAX_BLOCKS then break end
            
            if part:IsA("BasePart") and part.Parent and not isInsideBreaking(part) then
                -- Verifica se a part tem ParticleEmitter
                local hasEmitter = false
                for _, child in ipairs(part:GetChildren()) do
                    if child:IsA("ParticleEmitter") and not isInsideBreaking(child) then
                        hasEmitter = true
                        break
                    end
                end
                
                if hasEmitter and not espParts[part] then
                    -- Procura o emitter para identificar a raridade
                    for _, child in ipairs(part:GetChildren()) do
                        if child:IsA("ParticleEmitter") then
                            local colors = getEmitterColors(child)
                            if colors and #colors > 0 then
                                local found = nil
                                
                                for rarityName, data in pairs(rarities) do
                                    if enabled[rarityName] then
                                        for _, color in ipairs(colors) do
                                            if colorNear(color, data.Color) then
                                                found = rarityName
                                                break
                                            end
                                        end
                                    end
                                    if found then break end
                                end
                                
                                if found then
                                    counts[found] = counts[found] + 1
                                    processed = processed + 1
                                    createESP(part, found, rarities[found].Color)
                                    break
                                end
                            end
                        end
                    end
                end
            end
            
            stepCount = stepCount + 1
            if stepCount >= YIELD_EVERY then
                stepCount = 0
                RunService.Heartbeat:Wait()
            end
        end
        
        if CountsGui then
            updateCountsGUI(counts)
        end
        
        lastScanTime = tick()
    end)
    
    scanning = false
    scanRequested = false
    
    if not success then
        warn("[OreScanner] Scan error: " .. tostring(err))
    end
end

local function scheduleScan()
    if not SCAN_ENABLED or not shouldScan() then return end
    if not scanRequested then
        scanRequested = true
        task.wait(0.5)
        if scanRequested and shouldScan() then
            performFullScan()
        end
    end
end

-- Loop periódico de scan (agora com pausa quando desativado)
coroutine.wrap(function()
    while true do
        task.wait(SCAN_INTERVAL)
        if shouldScan() then
            performFullScan()
        end
    end
end)()

-- Event Listeners (otimizados)
workspace.DescendantAdded:Connect(function(descendant)
    if SCAN_ENABLED and (descendant:IsA("ParticleEmitter") or descendant:IsA("BasePart")) then
        scheduleScan()
    end
end)

workspace.DescendantRemoving:Connect(function(descendant)
    if SCAN_ENABLED and (descendant:IsA("ParticleEmitter") or descendant:IsA("BasePart")) then
        scheduleScan()
    end
end)

-- Monitora pasta Breaking
if breakingFolder then
    breakingFolder.ChildAdded:Connect(function()
        if SCAN_ENABLED then scheduleScan() end
    end)
    breakingFolder.ChildRemoved:Connect(function()
        if SCAN_ENABLED then scheduleScan() end
    end)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Breaking" then
        breakingFolder = child
        breakingFolder.ChildAdded:Connect(function()
            if SCAN_ENABLED then scheduleScan() end
        end)
        breakingFolder.ChildRemoved:Connect(function()
            if SCAN_ENABLED then scheduleScan() end
        end)
    end
end)

-- ========== UI RAYFIELD ==========
local ScannerTab = Window:CreateTab("Scanner")
local TeleportTab = Window:CreateTab("Teleports")

-- ABA SCANNER
ScannerTab:CreateSection("⚙️ Configurações do Scanner")

ScannerTab:CreateToggle({
    Name = "🔴 Ativar Scanner",
    CurrentValue = false,
    Flag = "EnableScanner",
    Callback = function(v)
        SCAN_ENABLED = v
        if v and shouldScan() then
            performFullScan()
        elseif not v then
            clearESP()
            if CountsGui then
                updateCountsGUI(zeroCounts())
            end
        end
    end,
})

ScannerTab:CreateSlider({
    Name = "📊 Max Blocos",
    Range = {1, 5000},
    Increment = 1,
    CurrentValue = MAX_BLOCKS,
    Flag = "MaxBlocksSlider",
    Callback = function(v)
        MAX_BLOCKS = v
        if SCAN_ENABLED then scheduleScan() end
    end,
})

ScannerTab:CreateSlider({
    Name = "⏱️ Taxa de Atualização (segundos)",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = SCAN_INTERVAL,
    Flag = "ScanIntervalSlider",
    Callback = function(v)
        SCAN_INTERVAL = v
    end,
})

ScannerTab:CreateSection("💎 Raridades")

for _, name in ipairs({"Uncommon", "Epic", "Legendary", "Mythic", "Ethereal", "Celestial", "Zenith", "Divine", "Nil"}) do
    ScannerTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Flag = name .. "Toggle",
        Callback = function(v)
            enabled[name] = v
            if SCAN_ENABLED then
                if shouldScan() then
                    scheduleScan()
                else
                    clearESP()
                    if CountsGui then
                        updateCountsGUI(zeroCounts())
                    end
                end
            end
        end,
    })
end

ScannerTab:CreateToggle({
    Name = "📋 Mostrar Janela de Contagens",
    CurrentValue = false,
    Flag = "ShowCountsToggle",
    Callback = function(v)
        if v then
            CreateCountsGui()
            if SCAN_ENABLED then scheduleScan() end
        else
            DestroyCountsGui()
        end
    end,
})

ScannerTab:CreateButton({
    Name = "🔄 Forçar Scan Agora",
    Callback = function()
        if SCAN_ENABLED then
            clearESP()
            performFullScan()
            Rayfield:Notify({
                Title = "Scan Forçado",
                Content = "Scan completo realizado.",
                Duration = 2,
            })
        else
            Rayfield:Notify({
                Title = "Scanner Desativado",
                Content = "Ative o scanner primeiro!",
                Duration = 2,
            })
        end
    end,
})

-- ABA TELEPORTES
TeleportTab:CreateSection("📍 Navegação Rápida")

TeleportTab:CreateButton({
    Name = "🏠 Superfície (Y=1)",
    Callback = teleportToSurface,
})

TeleportTab:CreateButton({
    Name = "⬆️ Subir 500 blocos",
    Callback = goUp,
})

TeleportTab:CreateButton({
    Name = "⬇️ Descer 500 blocos",
    Callback = goDown,
})

TeleportTab:CreateSection("☀️ Acima da Superfície")

for i = 1, 7 do
    local loc = teleportLocations[i]
    TeleportTab:CreateButton({
        Name = loc.Name .. " (Y: " .. loc.Y .. ")",
        Callback = function()
            teleportToY(loc.Y)
        end,
    })
end

TeleportTab:CreateSection("🌑 Profundidades")

for i = 8, #teleportLocations do
    local loc = teleportLocations[i]
    TeleportTab:CreateButton({
        Name = loc.Name .. " (Y: " .. loc.Y .. ")",
        Callback = function()
            teleportToY(loc.Y)
        end,
    })
end

TeleportTab:CreateSection("⚙️ Teleporte Personalizado")

TeleportTab:CreateInput({
    Name = "Digite a coordenada Y",
    PlaceholderText = "Ex: 1501 ou -2499",
    RemoveTextAfterFocusLost = true,
    Callback = function(text)
        local y = tonumber(text)
        if y then
            teleportToY(y)
        else
            Rayfield:Notify({
                Title = "Erro",
                Content = "Valor inválido!",
                Duration = 2,
            })
        end
    end,
})

-- Load configuration
Rayfield:LoadConfiguration()

-- Scan inicial (apenas se ativado)
task.wait(2)
if SCAN_ENABLED and shouldScan() then
    performFullScan()
end
