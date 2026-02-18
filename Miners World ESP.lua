-- RAYFIELD LOADER (LOADSTRING VERSION)

local Rayfield = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source"
))()

-- LOAD YOUR SCANNER FROM GITHUB
local Scanner = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Jey-1912/RarityScanner-Miner-s-World-Roblox-/refs/heads/main/BlockScanner.lua"
))()

-- OPTIONAL: LOAD COUNTER WIDGET
local CounterWidget = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Jey-1912/RarityScanner-Miner-s-World-Roblox-/refs/heads/main/TabFound.lua"
))()

local scanner = Scanner.new()
local widget = CounterWidget and CounterWidget.new()

local Window = Rayfield:CreateWindow({
    Name = "Block Scanner",
    LoadingTitle = "Block Scanner",
    LoadingSubtitle = "Control Panel",
    ConfigurationSaving = {
        Enabled = false,
    }
})

local Tab = Window:CreateTab("Scanner", 4483362458)

-- ENABLE SCANNER
Tab:CreateToggle({
    Name = "Scanner Enabled",
    CurrentValue = false,
    Callback = function(enabled)
        if enabled then
            scanner:Start()
        else
            scanner:Stop()
        end
    end
})

-- REMOVE RARE COMPLETELY
local RARITIES = {
    "Common",
    "Uncommon",
    "Epic",
    "Legendary",
    "Mythic",
}

Tab:CreateDropdown({
    Name = "Rarity",
    Options = RARITIES,
    CurrentOption = {"Common"},
    MultipleOptions = false,
    Callback = function(option)
        local selected = option[1]
        if selected then
            scanner:SetRarity(selected)
            scanner:ResetCount()
        end
    end
})

-- MAX BLOCKS SLIDER
Tab:CreateSlider({
    Name = "Max Blocks",
    Range = {1, 5000},
    Increment = 10,
    CurrentValue = 200,
    Suffix = "blocks",
    Callback = function(value)
        scanner:SetMaxBlocks(value)
    end
})

-- COUNTER GUI TOGGLE
Tab:CreateToggle({
    Name = "Show Counter Window",
    CurrentValue = false,
    Callback = function(show)
        if widget then
            if show then
                widget:Create()
                widget:SetCount(scanner.FoundCount or 0)
            else
                widget:Destroy()
            end
        end
    end
})

-- RESET COUNT
Tab:CreateButton({
    Name = "Reset Count",
    Callback = function()
        scanner:ResetCount()
        if widget then
            widget:SetCount(0)
        end
    end
})
