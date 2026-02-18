-- Ore Scanner | Miners World - Load Rápido (2026 Otimizado)

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source', true))()
end)

if not success then
    warn("Falha ao carregar Rayfield - tente outro executor ou mirror")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Ore Scanner | Miners World",
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "by Jean",
    ConfigurationSaving = {Enabled = true, FolderName = "OreScanner", FileName = "config"},
    KeySystem = false,
})

-- Rarities simples (sem Rare)
local rarities = {
    Uncommon  = Color3.fromRGB(0,255,0),
    Epic      = Color3.fromRGB(138,43,226),
    Legendary = Color3.fromRGB(255,255,0),
    Mythic    = Color3.fromRGB(255,0,0),
    Ethereal  = Color3.fromRGB(255,20,147),
    Celestial = Color3.fromRGB(0,255,255),
    Zenith    = Color3.fromRGB(128,0,128),
    Divine    = Color3.fromRGB(0,0,0),
    Nil       = Color3.fromRGB(99,95,98),
}

local rarityList = {"Uncommon","Epic","Legendary","Mythic","Ethereal","Celestial","Zenith","Divine","Nil"}

local EnabledRarities = {}
local MaxBlocks = 200
local ShowCounts = false
local AutoScan = true

local createdESP = {}
local scanning = false
local DEBOUNCE = 1.0  -- Maior = menos lag

-- Counts Widget (criado só quando necessário)
local CountsWidget = nil

local function CreateCountsWidget()
    task.spawn(function()
        if CountsWidget then return end
        local gui = Instance.new("ScreenGui")
        gui.Name = "OreCounts"
        gui.ResetOnSpawn = false
        gui.Parent = playerGui

        local frame = Instance.new("Frame", gui)
        frame.Size = UDim2.fromScale(0.22, 0.32)
        frame.Position = UDim2.fromScale(0.4, 0.35)
        frame.BackgroundColor3 = Color3.fromRGB(20,20,25)
        frame.Active = true
        frame.Draggable = true

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.fromScale(1,0.15)
        title.Text = "ORE COUNTS"
        title.BackgroundTransparency = 1
        title.TextColor3 = Color3.new(1,1,1)
        title.Font = Enum.Font.GothamBold
        title.TextScaled = true

        local content = Instance.new("TextLabel", frame)
        content.Size = UDim2.fromScale(1,0.85)
        content.Position = UDim2.fromScale(0,0.15)
        content.BackgroundTransparency = 1
        content.TextColor3 = Color3.new(0.9,0.9,1)
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.TextWrapped = true
        content.Text = "Loading..."

        CountsWidget = {Content = content}
    end)
end

-- Scan simplificado (adicione task.wait(0.01) no loop se ainda lagar)
local function scan()
    -- sua lógica de scan aqui (clearESP + loop GetDescendants)
    -- ...
    task.wait(0.1)  -- respiro
end

-- Auto-scan
task.spawn(function()
    while true do
        if AutoScan and next(EnabledRarities) then
            pcall(scan)
        end
        task.wait(4.5)  -- Intervalo alto para performance
    end
end)

-- UI lazy: crie em task.spawn com waits
task.spawn(function()
    task.wait(0.2)  -- Deixa Rayfield carregar primeiro

    local Tab = Window:CreateTab("Scanner")

    Tab:CreateSlider({
        Name = "Max Blocks",
        Range = {50, 800},
        Increment = 50,
        CurrentValue = MaxBlocks,
        Callback = function(v) MaxBlocks = v end,
    })

    Tab:CreateToggle({
        Name = "Auto Scan",
        CurrentValue = true,
        Callback = function(v) AutoScan = v end,
    })

    Tab:CreateToggle({
        Name = "Show Counts",
        CurrentValue = false,
        Callback = function(v)
            ShowCounts = v
            if v then CreateCountsWidget() end
        end,
    })

    for _, name in ipairs(rarityList) do
        task.wait(0.01)  -- respiro na criação de toggles
        Tab:CreateToggle({
            Name = name,
            Callback = function(v) EnabledRarities[name] = v end,
        })
    end

    Tab:CreateButton({Name = "Scan Now", Callback = scan})
end)

print("Ore Scanner carregado - tempo total deve ser bem menor agora")
