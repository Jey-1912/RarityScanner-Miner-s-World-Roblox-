-- Ore Scanner | Miners World - Rayfield Version (TELEPORTES CORRIGIDOS)
-- Teleportes de 500 em 500 blocos: Positivos: 1, 501, 1001... | Negativos: -499, -999, -1499...

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⛏️ Ore Scanner + Teleports | Miners World",
    LoadingTitle = "Miners World ⛏️",
    LoadingSubtitle = "by Jey - Teleports 500 em 500",
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

-- Match utilities
local function colorNear(a,b)
    return math.abs(a.R - b.R) < 0.2 and math.abs(a.G - b.G) < 0.2 and math.abs(a.B - b.B) < 0.2
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
    if p and p:IsA("BasePart") then
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
        CountsGui.Gui:Destroy()
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

-- ESP Management
local espParts = {}

local function clearESP()
    for part, esp in pairs(espParts) do
        if esp.highlight and esp.highlight.Parent then
            esp.highlight:Destroy()
        end
        if esp.billboard and esp.billboard.Parent then
            esp.billboard:Destroy()
        end
    end
    table.clear(espParts)
end

local function removeESP(part)
    local esp = espParts[part]
    if esp then
        if esp.highlight and esp.highlight.Parent then
            esp.highlight:Destroy()
        end
        if esp.billboard and esp.billboard.Parent then
            esp.billboard:Destroy()
        end
        espParts[part] = nil
    end
end

local function createESP(part, rarityName, color)
    removeESP(part)
    
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
-- Gerando coordenadas Y no padrão do jogo:
-- Positivos: 1, 501, 1001, 1501, 2001, 2501, 3001
-- Negativos: -499, -999, -1499, -1999, -2499, -2999, -3499, -3999, -4499, -4999, -5499, -5999, -6499, -6999, -7499, -7999

local teleportLocations = {
    -- Positivos (acima da superfície)
    {Name = "🏠 Superfície", Y = 1, Description = "Nível do mar / Lobby"},
    {Name = "⬆️ Altitude 1", Y = 501, Description = "500 blocos acima"},
    {Name = "⬆️ Altitude 2", Y = 1001, Description = "1000 blocos acima"},
    {Name = "⬆️ Altitude 3", Y = 1501, Description = "1500 blocos acima"},
    {Name = "⬆️ Altitude 4", Y = 2001, Description = "2000 blocos acima"},
    {Name = "⬆️ Altitude 5", Y = 2501, Description = "2500 blocos acima"},
    {Name = "⬆️ Altitude 6", Y = 3001, Description = "3000 blocos acima"},
    
    -- Negativos (profundidades)
    {Name = "⬇️ Profundidade 1", Y = -499, Description = "500 blocos abaixo"},
    {Name = "⬇️ Profundidade 2", Y = -999, Description = "1000 blocos abaixo"},
    {Name = "⬇️ Profundidade 3", Y = -1499, Description = "1500 blocos abaixo"},
    {Name = "⬇️ Profundidade 4", Y = -1999, Description = "2000 blocos abaixo"},
    {Name = "⬇️ Profundidade 5", Y = -2499, Description = "2500 blocos abaixo"},
    {Name = "⬇️ Profundidade 6", Y = -2999, Description = "3000 blocos abaixo"},
    {Name = "⬇️ Profundidade 7", Y = -3499, Description = "3500 blocos abaixo"},
    {Name = "⬇️ Profundidade 8", Y = -3999, Description = "4000 blocos abaixo"},
    {Name = "⬇️ Profundidade 9", Y = -4499, Description = "4500 blocos abaixo"},
    {Name = "⬇️ Profundidade 10", Y = -4999, Description = "5000 blocos abaixo"},
    {Name = "⬇️ Profundidade 11", Y = -5499, Description = "5500 blocos abaixo"},
    {Name = "⬇️ Profundidade 12", Y = -5999, Description = "6000 blocos abaixo"},
    {Name = "⬇️ Profundidade 13", Y = -6499, Description = "6500 blocos abaixo"},
    {Name = "⬇️ Profundidade 14", Y = -6999, Description = "7000 blocos abaixo"},
    {Name = "⬇️ Profundidade 15", Y = -7499, Description = "7500 blocos abaixo"},
    {Name = "⬇️ Profundidade 16", Y = -7999, Description = "8000 blocos abaixo"},
}

-- Função para gerar todas as profundidades programaticamente (caso queira mais)
local function generateAllDepths()
    local depths = {}
    
    -- Positivos: de 1 até 3001, pulando 500
    for y = 1, 3001, 500 do
        table.insert(depths, {
            Name = (y == 1 and "🏠 Superfície" or string.format("⬆️ Altitude %d", (y-1)/500 + 1)),
            Y = y,
            Description = string.format("%d blocos %s", math.abs(y-1), y == 1 and "(nível do mar)" or "acima")
        })
    end
    
    -- Negativos: de -499 até -7999, pulando 500
    for y = -499, -7999, -500 do
        local level = math.abs(y + 1)/500 + 1
        table.insert(depths, {
            Name = string.format("⬇️ Profundidade %d", level),
            Y = y,
            Description = string.format("%d blocos abaixo", math.abs(y-1))
        })
    end
    
    return depths
end

-- Se quiser usar a versão gerada automaticamente:
-- local teleportLocations = generateAllDepths()

-- Função de teleporte
local function teleportToY(targetY)
    local character = player.Character
    if not character then
        Rayfield:Notify({
            Title = "Erro",
            Content = "Personagem não encontrado!",
            Duration = 3,
        })
        return
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
    
    -- Posição atual
    local currentPos = humanoidRootPart.Position
    local newPos = Vector3.new(0, targetY, 0) -- X e Z sempre 0
    
    -- Teleporta
    humanoidRootPart.CFrame = CFrame.new(newPos)
    
    -- Notificação
    Rayfield:Notify({
        Title = "Teleportado!",
        Content = string.format("Y: %.0f → %.0f", currentPos.Y, targetY),
        Duration = 3,
    })
end

-- Função para ir para a superfície (Y=1)
local function teleportToSurface()
    teleportToY(1)
end

-- Função para subir 500 blocos
local function goUp()
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local currentY = hrp.Position.Y
            local targetY
            
            -- Lógica para encontrar o próximo Y positivo
            if currentY >= 1 then
                -- Está em área positiva
                targetY = math.floor((currentY + 500) / 500) * 500 + 1
            else
                -- Está em área negativa, vai para o primeiro positivo
                targetY = 1
            end
            
            teleportToY(targetY)
        end
    end
end

-- Função para descer 500 blocos
local function goDown()
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local currentY = hrp.Position.Y
            local targetY
            
            if currentY > 1 then
                -- Está em área positiva, desce para o primeiro negativo
                targetY = -499
            elseif currentY <= -499 then
                -- Está em área negativa, desce mais
                targetY = math.floor((currentY - 500) / 500) * 500 - 499
            else
                targetY = -499
            end
            
            teleportToY(targetY)
        end
    end
end

-- Função para teleporte personalizado (agora valida se está no padrão)
local function customTeleport(yValue)
    yValue = tonumber(yValue)
    if yValue then
        -- Verifica se é um valor válido no padrão do jogo
        local isValid = false
        
        -- Verifica positivos (1, 501, 1001...)
        if yValue >= 1 and yValue <= 3001 and (yValue - 1) % 500 == 0 then
            isValid = true
        end
        
        -- Verifica negativos (-499, -999, -1499... até -7999)
        if yValue <= -499 and yValue >= -7999 and (yValue + 499) % -500 == 0 then
            isValid = true
        end
        
        if isValid or yValue == 0 then -- 0 não é usado, mas permitimos
            teleportToY(yValue)
        else
            Rayfield:Notify({
                Title = "Y Inválido",
                Content = "Use: 1, 501, 1001... ou -499, -999, -1499...",
                Duration = 5,
            })
        end
    else
        Rayfield:Notify({
            Title = "Erro",
            Content = "Valor inválido!",
            Duration = 3,
        })
    end
end

-- ========== SCAN FUNCTIONS ==========
local scanning = false
local scanRequested = false

local function zeroCounts()
    local counts = {}
    for name in pairs(rarities) do counts[name] = 0 end
    return counts
end

local function performFullScan()
    if scanning then return end
    scanning = true
    
    local success, err = pcall(function()
        for part in pairs(espParts) do
            if not part or not part.Parent or isInsideBreaking(part) then
                removeESP(part)
            end
        end
        
        local counts = zeroCounts()
        local processed = 0
        local stepCount = 0
        
        for _, emitter in ipairs(workspace:GetDescendants()) do
            if processed >= MAX_BLOCKS then break end
            
            if emitter:IsA("ParticleEmitter") and emitter.Parent then
                if not isInsideBreaking(emitter) then
                    local part = getRealPartFromEmitter(emitter)
                    
                    if part and part.Parent and not isInsideBreaking(part) then
                        local colors = getEmitterColors(emitter)
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
                            
                            if found and not espParts[part] then
                                counts[found] = counts[found] + 1
                                processed = processed + 1
                                createESP(part, found, rarities[found].Color)
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
        end
        
        if CountsGui then
            updateCountsGUI(counts)
        end
    end)
    
    scanning = false
    scanRequested = false
    
    if not success then
        warn("[OreScanner] Scan error: " .. tostring(err))
    end
end

local function scheduleScan()
    if not scanRequested then
        scanRequested = true
        task.wait(0.5)
        if scanRequested then
            performFullScan()
        end
    end
end

-- Loop periódico de scan
coroutine.wrap(function()
    while true do
        task.wait(SCAN_INTERVAL)
        local anyEnabled = false
        for _, v in pairs(enabled) do
            if v then 
                anyEnabled = true 
                break 
            end
        end
        if anyEnabled then
            performFullScan()
        end
    end
end)()

-- Event Listeners
workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ParticleEmitter") or descendant:IsA("BasePart") then
        scheduleScan()
    end
end)

workspace.DescendantRemoving:Connect(function(descendant)
    if descendant:IsA("ParticleEmitter") or descendant:IsA("BasePart") then
        scheduleScan()
    end
end)

if breakingFolder then
    breakingFolder.ChildAdded:Connect(scheduleScan)
    breakingFolder.ChildRemoved:Connect(scheduleScan)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Breaking" then
        breakingFolder = child
        breakingFolder.ChildAdded:Connect(scheduleScan)
        breakingFolder.ChildRemoved:Connect(scheduleScan)
    end
end)

-- ========== UI RAYFIELD ==========
local ScannerTab = Window:CreateTab("Scanner")
local TeleportTab = Window:CreateTab("Teleports")

-- ABA SCANNER
ScannerTab:CreateSection("Scanner Settings")

ScannerTab:CreateSlider({
    Name = "Max Blocks",
    Range = {1, 5000},
    Increment = 1,
    CurrentValue = MAX_BLOCKS,
    Flag = "MaxBlocksSlider",
    Callback = function(v)
        MAX_BLOCKS = v
        scheduleScan()
    end,
})

ScannerTab:CreateSlider({
    Name = "Scan Interval (seconds)",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = SCAN_INTERVAL,
    Flag = "ScanIntervalSlider",
    Callback = function(v)
        SCAN_INTERVAL = v
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
            local anyEnabled = false
            for _, enabledState in pairs(enabled) do
                if enabledState then 
                    anyEnabled = true 
                    break 
                end
            end
            
            if anyEnabled then
                scheduleScan()
            else
                clearESP()
                if CountsGui then
                    updateCountsGUI(zeroCounts())
                end
            end
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
            scheduleScan()
        else
            DestroyCountsGui()
        end
    end,
})

ScannerTab:CreateButton({
    Name = "Force Scan Now",
    Callback = function()
        clearESP()
        performFullScan()
        Rayfield:Notify({
            Title = "Scan Forçado",
            Content = "Scan completo realizado.",
            Duration = 2,
        })
    end,
})

-- ========== ABA DE TELEPORTES CORRIGIDA ==========
TeleportTab:CreateSection("📍 Controles Rápidos")

-- Botões de navegação rápida
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

TeleportTab:CreateSection("📊 Acima da Superfície (Positivos)")

-- Botões para altitudes positivas
local positiveLocations = {}
for _, loc in ipairs(teleportLocations) do
    if loc.Y > 0 then
        table.insert(positiveLocations, loc)
    end
end

for _, location in ipairs(positiveLocations) do
    TeleportTab:CreateButton({
        Name = location.Name .. " (Y: " .. location.Y .. ")",
        Callback = function()
            teleportToY(location.Y)
        end,
    })
end

TeleportTab:CreateSection("📊 Profundidades (Negativos)")

-- Botões para profundidades negativas
local negativeLocations = {}
for _, loc in ipairs(teleportLocations) do
    if loc.Y < 0 then
        table.insert(negativeLocations, loc)
    end
end

for _, location in ipairs(negativeLocations) do
    TeleportTab:CreateButton({
        Name = location.Name .. " (Y: " .. location.Y .. ")",
        Callback = function()
            teleportToY(location.Y)
        end,
    })
end

TeleportTab:CreateSection("⚙️ Teleporte Personalizado")

TeleportTab:CreateInput({
    Name = "Digite a coordenada Y",
    PlaceholderText = "Ex: 1501 ou -2499",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        customTeleport(text)
    end,
})

TeleportTab:CreateSection("ℹ️ Formato Válido")
TeleportTab:CreateLabel("Positivos: 1, 501, 1001, 1501... até 3001")
TeleportTab:CreateLabel("Negativos: -499, -999, -1499... até -7999")
TeleportTab:CreateLabel("Sempre pulando de 500 em 500")

-- Load configuration
Rayfield:LoadConfiguration()

-- Scan inicial
task.wait(1)
performFullScan()
