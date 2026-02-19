-- Ore Scanner | Miners World - Rayfield Version (SCAN CORRIGIDO)
-- Correções: Atualiza ESP quando minério muda, remove ESP não visto, busca partes mais robusta

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "⛏️ Ore Scanner | Miners World",
    LoadingTitle = "Miners World ⛏️",
    LoadingSubtitle = "by Jey - Scan Corrigido",
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
local SCAN_INTERVAL = 3 -- Segundos entre scans completos
local YIELD_EVERY = 120

-- Rarities (NO RARE, NO EMERALD)
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
    -- Pega as cores dos keypoints
    for _,kp in ipairs(emitter.Color.Keypoints) do
        table.insert(colors, kp.Value)
    end
    return colors
end

-- CORREÇÃO: Função mais robusta para encontrar a parte real do emitter
local function getRealPartFromEmitter(emitter)
    if not emitter then return nil end
    
    local current = emitter
    local maxIterations = 10 -- Evita loops infinitos
    local iter = 0
    
    while current and current.Parent and iter < maxIterations do
        current = current.Parent
        iter = iter + 1
        
        if current:IsA("BasePart") then
            return current
        elseif current:IsA("Attachment") then
            -- Continua subindo
        elseif current:IsA("Model") then
            -- Se for Model, pode ter uma PrimaryPart
            if current.PrimaryPart then
                return current.PrimaryPart
            end
        end
    end
    
    -- Se não achou, tenta encontrar qualquer BasePart nos descendentes
    if emitter:IsA("ParticleEmitter") then
        local parent = emitter.Parent
        if parent then
            if parent:IsA("Attachment") and parent.Parent then
                parent = parent.Parent
            end
            -- Procura por BasePart nos filhos
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("BasePart") then
                    return child
                end
            end
        end
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
local espParts = {} -- Mapeia parte -> informações do ESP

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
    -- Remove ESP antigo se existir
    removeESP(part)
    
    -- Cria novo ESP
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
    
    -- Armazena referências
    espParts[part] = {
        highlight = highlight,
        billboard = billboard,
        rarity = rarityName
    }
end

-- Scan Functions
local scanning = false
local lastScanTime = 0
local scanRequested = false

local function zeroCounts()
    local counts = {}
    for name in pairs(rarities) do counts[name] = 0 end
    return counts
end

-- CORREÇÃO: Função principal de scan com as melhorias
local function performFullScan()
    if scanning then return end
    scanning = true
    
    local success, err = pcall(function()
        -- Remove ESP de partes que não existem mais ou estão no Breaking
        for part in pairs(espParts) do
            if (not part) or (not part.Parent) or isInsideBreaking(part) then
                removeESP(part)
            end
        end
        
        local counts = zeroCounts()
        local processed = 0
        local stepCount = 0
        local seen = {} -- Parts detectadas neste scan
        
        -- Procura por ParticleEmitters no workspace INTEIRO
        for _, emitter in ipairs(workspace:GetDescendants()) do
            if processed >= MAX_BLOCKS then break end
            
            -- Verifica se é um ParticleEmitter válido
            if emitter:IsA("ParticleEmitter") and emitter.Parent then
                -- Ignora se estiver na pasta Breaking
                if not isInsideBreaking(emitter) then
                    local part = getRealPartFromEmitter(emitter)
                    
                    -- Verifica se a parte é válida e não está no Breaking
                    if part and part.Parent and not isInsideBreaking(part) then
                        -- Pega as cores do emitter
                        local colors = getEmitterColors(emitter)
                        if colors and #colors > 0 then
                            local found = nil
                            
                            -- Verifica cada raridade habilitada
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
                            
                            -- Se encontrou uma raridade
                            if found then
                                seen[part] = found
                                
                                -- CORREÇÃO: Atualiza se não tem ESP ou se a raridade mudou
                                if (not espParts[part]) or (espParts[part].rarity ~= found) then
                                    createESP(part, found, rarities[found].Color)
                                end
                                
                                -- Incrementa contador
                                counts[found] = counts[found] + 1
                                processed = processed + 1
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
        
        -- CORREÇÃO: Remove ESP que não foi visto neste scan (sumiu ou mudou)
        for part in pairs(espParts) do
            if not seen[part] then
                removeESP(part)
            end
        end
        
        -- Atualiza GUI de contagens
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

-- Função para agendar scan (com debounce)
local function scheduleScan()
    if not scanRequested then
        scanRequested = true
        task.wait(0.5) -- Pequeno delay para coalescer eventos
        if scanRequested then -- Verifica se ainda é necessário
            performFullScan()
        end
    end
end

-- Loop periódico de scan
coroutine.wrap(function()
    while true do
        task.wait(SCAN_INTERVAL)
        -- Só faz scan se houver raridades habilitadas
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

-- Monitora pasta Breaking
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

-- Monitora mudanças de propriedade nos emitters (cores podem mudar?)
game:GetService("CollectionService"):GetInstanceAddedSignal("ParticleEmitter"):Connect(scheduleScan)

-- Force Restart
local function forceRestart()
    clearESP()
    performFullScan()
end

-- UI Rayfield
local ScannerTab = Window:CreateTab("Scanner")

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
            -- Verifica se alguma raridade está habilitada
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
        forceRestart()
        Rayfield:Notify({
            Title = "Scan Forçado",
            Content = "Scan completo realizado.",
            Duration = 2,
        })
    end,
})

--------------------------------------------------
-- TELEPORT TAB (TESTE LOCAL)
-- X=0, Z=0, Y = lobby selecionado
--------------------------------------------------

local TeleportTab = Window:CreateTab("Teleport")

TeleportTab:CreateSection("Lobby Teleport (Teste)")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Gera Ys: 1, 501..3001 (passo 500), -499..-7999 (passo -500)
local function buildLobbyYs()
    local ys = {1}

    for y = 501, 3001, 500 do
        table.insert(ys, y)
    end

    for y = -499, -7999, -500 do
        table.insert(ys, y)
    end

    return ys
end

local LobbyYs = buildLobbyYs()
local selectedIndex = 1

local function getSelectedY()
    return LobbyYs[selectedIndex] or 1
end

-- Validação do Y conforme sua regra
local function isValidLobbyY(y)
    y = math.floor(y)
    if y == 1 then return true end

    if y >= 501 and y <= 3001 then
        return ((y - 1) % 500) == 0
    end

    if y <= -499 and y >= -7999 then
        return ((y - 1) % 500) == 0
    end

    return false
end

local function teleportToY(y)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Teleporte local (teste)
    hrp.CFrame = CFrame.new(0, y + 5, 0)
end

-- Dropdown options como texto
local dropdownOptions = {}
for _, y in ipairs(LobbyYs) do
    table.insert(dropdownOptions, tostring(y))
end

TeleportTab:CreateDropdown({
    Name = "Escolher Lobby (Y)",
    Options = dropdownOptions,
    CurrentOption = { tostring(getSelectedY()) },
    Flag = "LobbyDropdown",
    Callback = function(option)
        local v = option
        if typeof(option) == "table" then v = option[1] end
        local y = tonumber(v)

        if y then
            -- acha índice correspondente
            for i, yy in ipairs(LobbyYs) do
                if yy == y then
                    selectedIndex = i
                    break
                end
            end
        end
    end
})

TeleportTab:CreateButton({
    Name = "Prev Lobby",
    Callback = function()
        selectedIndex -= 1
        if selectedIndex < 1 then selectedIndex = #LobbyYs end
        Rayfield:Notify({
            Title = "Lobby",
            Content = ("Selecionado Y=%d"):format(getSelectedY()),
            Duration = 1.5,
        })
    end
})

TeleportTab:CreateButton({
    Name = "Next Lobby",
    Callback = function()
        selectedIndex += 1
        if selectedIndex > #LobbyYs then selectedIndex = 1 end
        Rayfield:Notify({
            Title = "Lobby",
            Content = ("Selecionado Y=%d"):format(getSelectedY()),
            Duration = 1.5,
        })
    end
})

TeleportTab:CreateInput({
    Name = "Y manual (opcional)",
    PlaceholderText = "Ex: 1, 501, 1001, -499, -999...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local y = tonumber(text)
        if not y then
            Rayfield:Notify({
                Title = "Teleport",
                Content = "Digite um número válido.",
                Duration = 2,
            })
            return
        end

        y = math.floor(y)
        if not isValidLobbyY(y) then
            Rayfield:Notify({
                Title = "Teleport",
                Content = "Y inválido. Regra: 1, (1+500n) até 3001 e até -7999.",
                Duration = 3,
            })
            return
        end

        -- seta selectedIndex para esse Y
        for i, yy in ipairs(LobbyYs) do
            if yy == y then
                selectedIndex = i
                break
            end
        end

        Rayfield:Notify({
            Title = "Lobby",
            Content = ("Selecionado Y=%d"):format(y),
            Duration = 1.5,
        })
    end
})

TeleportTab:CreateButton({
    Name = "Teleportar para Lobby selecionado",
    Callback = function()
        local y = getSelectedY()
        teleportToY(y)
        Rayfield:Notify({
            Title = "Teleport",
            Content = ("Teleportado para (0, %d, 0)"):format(y),
            Duration = 2,
        })
    end
})



-- Load configuration
Rayfield:LoadConfiguration()

-- Scan inicial
task.wait(1)
performFullScan()
