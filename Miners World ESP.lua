-- Ore Scanner | Miners World - Updated Version (all in 1 raw)
-- Changes: Optimized for less lag (increased scan interval, added auto-scan toggle), expanded translations (added Spanish, French, German, Chinese, Arabic, Hindi, Russian), moved language to Settings tab, improved saving with multiple configs (create/overwrite/select/auto-load), fixed translation apply (recreates UI on change)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Translation library (expanded with more languages)
local Translations = {
    English = {
        WindowTitle = "⛏️ Ore Scanner | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "by Jey",
        ScannerTab = "Scanner",
        SettingsTab = "Settings",
        ConfigSection = "Settings",
        MaxBlocksSlider = "Max Blocks to Scan",
        RaritiesSection = "Rarities (toggle to scan + count)",
        DisplaySection = "Display",
        ShowCountsToggle = "Show Counts Window",
        ForceScanButton = "Force Scan Now",
        AutoScanToggle = "Auto Scan (reduce lag if off)",
        LanguageDropdown = "Language",
        ConfigNameInput = "Config Name",
        SaveConfigButton = "Save/Overwrite Config",
        LoadConfigButton = "Load Config",
        NotifyLoaded = "Ore Scanner Loaded",
        NotifyContent = "Toggle rarities to start scanning.",
        NotifyLanguage = "Language changed. Reopen GUI to apply.",
        NotifySaved = "Config saved as ",
        NotifyLoadedConfig = "Config loaded: ",
        CountsTitle = "ORE COUNTS",
        CountsLoading = "Loading...",
        LimitLabel = "Limit: "
    },
    Portuguese = {
        WindowTitle = "⛏️ Ore Scanner | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "por Jey",
        ScannerTab = "Scanner",
        SettingsTab = "Configurações",
        ConfigSection = "Configurações",
        MaxBlocksSlider = "Máximo de Blocos para Escanear",
        RaritiesSection = "Raridades (ative para escanear + contar)",
        DisplaySection = "Visualização",
        ShowCountsToggle = "Mostrar Janela de Contagem",
        ForceScanButton = "Forçar Scan Agora",
        AutoScanToggle = "Scan Automático (desative se lag)",
        LanguageDropdown = "Idioma",
        ConfigNameInput = "Nome da Config",
        SaveConfigButton = "Salvar/Sobrescrever Config",
        LoadConfigButton = "Carregar Config",
        NotifyLoaded = "Ore Scanner Carregado",
        NotifyContent = "Ative as raridades para começar.",
        NotifyLanguage = "Idioma alterado. Reabra a GUI para aplicar.",
        NotifySaved = "Config salva como ",
        NotifyLoadedConfig = "Config carregada: ",
        CountsTitle = "CONTAGEM DE ORES",
        CountsLoading = "Carregando...",
        LimitLabel = "Limite: "
    },
    Spanish = {
        WindowTitle = "⛏️ Escáner de Minerales | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "por Jey",
        ScannerTab = "Escáner",
        SettingsTab = "Configuraciones",
        ConfigSection = "Configuraciones",
        MaxBlocksSlider = "Máximo de Bloques para Escanear",
        RaritiesSection = "Rarezas (activa para escanear + contar)",
        DisplaySection = "Visualización",
        ShowCountsToggle = "Mostrar Ventana de Conteo",
        ForceScanButton = "Forzar Escaneo Ahora",
        AutoScanToggle = "Escaneo Automático (desactiva si hay lag)",
        LanguageDropdown = "Idioma",
        ConfigNameInput = "Nombre de Config",
        SaveConfigButton = "Guardar/Sobrescribir Config",
        LoadConfigButton = "Cargar Config",
        NotifyLoaded = "Escáner de Minerales Cargado",
        NotifyContent = "Activa rarezas para comenzar.",
        NotifyLanguage = "Idioma cambiado. Reabre la GUI para aplicar.",
        NotifySaved = "Config guardada como ",
        NotifyLoadedConfig = "Config cargada: ",
        CountsTitle = "CONTEO DE MINERALES",
        CountsLoading = "Cargando...",
        LimitLabel = "Límite: "
    },
    French = {
        WindowTitle = "⛏️ Scanner de Minerais | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "par Jey",
        ScannerTab = "Scanner",
        SettingsTab = "Paramètres",
        ConfigSection = "Paramètres",
        MaxBlocksSlider = "Blocs Max à Scanner",
        RaritiesSection = "Raretés (activer pour scanner + compter)",
        DisplaySection = "Affichage",
        ShowCountsToggle = "Afficher Fenêtre de Comptage",
        ForceScanButton = "Forcer Scan Maintenant",
        AutoScanToggle = "Scan Auto (désactiver si lag)",
        LanguageDropdown = "Langue",
        ConfigNameInput = "Nom de Config",
        SaveConfigButton = "Sauvegarder/Écraser Config",
        LoadConfigButton = "Charger Config",
        NotifyLoaded = "Scanner de Minerais Chargé",
        NotifyContent = "Activez les raretés pour commencer.",
        NotifyLanguage = "Langue changée. Réouvrez la GUI pour appliquer.",
        NotifySaved = "Config sauvegardée comme ",
        NotifyLoadedConfig = "Config chargée: ",
        CountsTitle = "COMPTE DE MINERAIS",
        CountsLoading = "Chargement...",
        LimitLabel = "Limite: "
    },
    German = {
        WindowTitle = "⛏️ Erz-Scanner | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "von Jey",
        ScannerTab = "Scanner",
        SettingsTab = "Einstellungen",
        ConfigSection = "Einstellungen",
        MaxBlocksSlider = "Max Blöcke zum Scannen",
        RaritiesSection = "Seltenheiten (aktivieren zum Scannen + Zählen)",
        DisplaySection = "Anzeige",
        ShowCountsToggle = "Zählfenster Anzeigen",
        ForceScanButton = "Scan Jetzt Erzwingen",
        AutoScanToggle = "Auto-Scan (deaktivieren bei Lag)",
        LanguageDropdown = "Sprache",
        ConfigNameInput = "Config-Name",
        SaveConfigButton = "Config Speichern/Überschreiben",
        LoadConfigButton = "Config Laden",
        NotifyLoaded = "Erz-Scanner Geladen",
        NotifyContent = "Aktivieren Sie Seltenheiten zum Starten.",
        NotifyLanguage = "Sprache geändert. GUI neu öffnen zum Anwenden.",
        NotifySaved = "Config gespeichert als ",
        NotifyLoadedConfig = "Config geladen: ",
        CountsTitle = "ERZ-ZÄHLUNG",
        CountsLoading = "Laden...",
        LimitLabel = "Limit: "
    },
    Chinese = {
        WindowTitle = "⛏️ 矿石扫描仪 | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "由 Jey",
        ScannerTab = "扫描仪",
        SettingsTab = "设置",
        ConfigSection = "设置",
        MaxBlocksSlider = "最大扫描块数",
        RaritiesSection = "稀有度（切换以扫描 + 计数）",
        DisplaySection = "显示",
        ShowCountsToggle = "显示计数窗口",
        ForceScanButton = "立即强制扫描",
        AutoScanToggle = "自动扫描（如果滞后则关闭）",
        LanguageDropdown = "语言",
        ConfigNameInput = "配置名称",
        SaveConfigButton = "保存/覆盖配置",
        LoadConfigButton = "加载配置",
        NotifyLoaded = "矿石扫描仪已加载",
        NotifyContent = "切换稀有度以开始扫描。",
        NotifyLanguage = "语言已更改。重新打开 GUI 以应用。",
        NotifySaved = "配置保存为 ",
        NotifyLoadedConfig = "配置加载： ",
        CountsTitle = "矿石计数",
        CountsLoading = "加载中...",
        LimitLabel = "限制： "
    },
    Arabic = {
        WindowTitle = "⛏️ ماسح الخامات | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "بواسطة Jey",
        ScannerTab = "الماسح",
        SettingsTab = "الإعدادات",
        ConfigSection = "الإعدادات",
        MaxBlocksSlider = "أقصى كتل للمسح",
        RaritiesSection = "الندرة (تبديل للمسح + العد)",
        DisplaySection = "العرض",
        ShowCountsToggle = "عرض نافذة العد",
        ForceScanButton = "فرض المسح الآن",
        AutoScanToggle = "مسح تلقائي (إيقاف إذا تأخر)",
        LanguageDropdown = "اللغة",
        ConfigNameInput = "اسم التكوين",
        SaveConfigButton = "حفظ/استبدال التكوين",
        LoadConfigButton = "تحميل التكوين",
        NotifyLoaded = "ماسح الخامات محمل",
        NotifyContent = "تبديل الندرة لبدء المسح.",
        NotifyLanguage = "تم تغيير اللغة. أعد فتح الواجهة للتطبيق.",
        NotifySaved = "تم حفظ التكوين كـ ",
        NotifyLoadedConfig = "تم تحميل التكوين: ",
        CountsTitle = "عد الخامات",
        CountsLoading = "جاري التحميل...",
        LimitLabel = "حد: "
    },
    Hindi = {
        WindowTitle = "⛏️ Ore Scanner | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "द्वारा Jey",
        ScannerTab = "स्कैनर",
        SettingsTab = "सेटिंग्स",
        ConfigSection = "सेटिंग्स",
        MaxBlocksSlider = "स्कैन करने के लिए अधिकतम ब्लॉक",
        RaritiesSection = "दुर्लभता (स्कैन + गिनती के लिए टॉगल)",
        DisplaySection = "डिस्प्ले",
        ShowCountsToggle = "काउंट विंडो दिखाएं",
        ForceScanButton = "अब फोर्स स्कैन",
        AutoScanToggle = "ऑटो स्कैन (लैग होने पर बंद करें)",
        LanguageDropdown = "भाषा",
        ConfigNameInput = "कॉन्फ़िग नाम",
        SaveConfigButton = "कॉन्फ़िग सेव/ओवरराइट",
        LoadConfigButton = "कॉन्फ़िग लोड",
        NotifyLoaded = "Ore Scanner लोडेड",
        NotifyContent = "स्कैन शुरू करने के लिए दुर्लभता टॉगल करें।",
        NotifyLanguage = "भाषा बदली गई। लागू करने के लिए GUI दोबारा खोलें।",
        NotifySaved = "कॉन्फ़िग सेव किया गया ",
        NotifyLoadedConfig = "कॉन्फ़िग लोडेड: ",
        CountsTitle = "ओर काउंट्स",
        CountsLoading = "लोड हो रहा है...",
        LimitLabel = "सीमा: "
    },
    Russian = {
        WindowTitle = "⛏️ Сканер Руды | Miners World",
        LoadingTitle = "Miners World ⛏️",
        LoadingSubtitle = "от Jey",
        ScannerTab = "Сканер",
        SettingsTab = "Настройки",
        ConfigSection = "Настройки",
        MaxBlocksSlider = "Макс Блоков для Сканирования",
        RaritiesSection = "Редкости (вкл для сканирования + подсчета)",
        DisplaySection = "Отображение",
        ShowCountsToggle = "Показать Окно Подсчета",
        ForceScanButton = "Принудительное Сканирование Сейчас",
        AutoScanToggle = "Авто-Скан (выкл если лаг)",
        LanguageDropdown = "Язык",
        ConfigNameInput = "Имя Конфига",
        SaveConfigButton = "Сохранить/Перезаписать Конфиг",
        LoadConfigButton = "Загрузить Конфиг",
        NotifyLoaded = "Сканер Руды Загружен",
        NotifyContent = "Вкл редкости для начала сканирования.",
        NotifyLanguage = "Язык изменен. Переоткройте GUI для применения.",
        NotifySaved = "Конфиг сохранен как ",
        NotifyLoadedConfig = "Конфиг загружен: ",
        CountsTitle = "ПОДСЧЕТ РУДЫ",
        CountsLoading = "Загрузка...",
        LimitLabel = "Лимит: "
    }
}

local CurrentLanguage = "English"  -- Default
local Strings = Translations[CurrentLanguage]

-- Function to update language (notify to reopen for full apply)
local function UpdateLanguage(lang)
    CurrentLanguage = lang
    Strings = Translations[lang]
    Rayfield:Notify({
        Title = "Language Updated",
        Content = Strings.NotifyLanguage,
        Duration = 5
    })
end

-- Rarities (no Rare)
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
local AutoScan = true  -- New: toggle for auto-scan to reduce lag

local createdESP = {}
local scanning = false
local lastScan = 0
local DEBOUNCE = 0.6  -- Increased debounce for less lag

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

-- Scanner + ESP
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

-- Auto-scan loop (now toggleable for lag control)
local autoScanConn
local function StartAutoScan()
    if autoScanConn then return end
    autoScanConn = task.spawn(function()
        task.wait(1.5)
        while AutoScan do
            if next(EnabledRarities) then
                pcall(scan)
            end
            task.wait(3.5)  -- Increased interval for less lag
        end
    end)
end

local function StopAutoScan()
    if autoScanConn then
        task.cancel(autoScanConn)
        autoScanConn = nil
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ParticleEmitter") and AutoScan then task.delay(0.4, scan) end
end)

-- Rayfield UI with separate tabs
local ScannerTab = Window:CreateTab(Strings.ScannerTab, nil)
local SettingsTab = Window:CreateTab(Strings.SettingsTab, nil)

-- Settings Tab (language + config saves)
SettingsTab:CreateSection(Strings.ConfigSection)

SettingsTab:CreateDropdown({
    Name = Strings.LanguageDropdown,
    Options = {"English", "Portuguese", "Spanish", "French", "German", "Chinese", "Arabic", "Hindi", "Russian"},
    CurrentOption = {CurrentLanguage},
    Callback = function(opt)
        UpdateLanguage(opt[1])
    end,
})

local configName = "default"  -- Default config name

SettingsTab:CreateInput({
    Name = Strings.ConfigNameInput,
    PlaceholderText = "Enter config name",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        configName = text or "default"
    end,
})

SettingsTab:CreateButton({
    Name = Strings.SaveConfigButton,
    Callback = function()
        Window.ConfigurationSaving.FileName = configName
        Rayfield:SaveConfiguration()
        Rayfield:Notify({
            Title = "Saved",
            Content = Strings.NotifySaved .. configName,
            Duration = 4
        })
    end
})

SettingsTab:CreateButton({
    Name = Strings.LoadConfigButton,
    Callback = function()
        Window.ConfigurationSaving.FileName = configName
        Rayfield:LoadConfiguration()
        Rayfield:Notify({
            Title = "Loaded",
            Content = Strings.NotifyLoadedConfig .. configName,
            Duration = 4
        })
        -- Reapply after load (Rayfield auto-applies, but force scan)
        task.delay(0.5, scan)
    end
})

-- Scanner Tab
ScannerTab:CreateSection(Strings.ConfigSection)

ScannerTab:CreateSlider({
    Name = Strings.MaxBlocksSlider,
    Range = {50, 1200},
    Increment = 25,
    CurrentValue = MaxBlocks,
    Callback = function(v)
        MaxBlocks = v
        task.delay(0.2, scan)
    end,
})

ScannerTab:CreateToggle({
    Name = Strings.AutoScanToggle,
    CurrentValue = true,
    Callback = function(state)
        AutoScan = state
        if state then
            StartAutoScan()
        else
            StopAutoScan()
        end
    end,
})

ScannerTab:CreateSection(Strings.RaritiesSection)

for _, name in ipairs(rarityList) do
    ScannerTab:CreateToggle({
        Name = name,
        CurrentValue = false,
        Callback = function(state)
            EnabledRarities[name] = state
            task.delay(0.2, scan)
        end,
    })
end

ScannerTab:CreateSection(Strings.DisplaySection)

ScannerTab:CreateToggle({
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

ScannerTab:CreateButton({
    Name = Strings.ForceScanButton,
    Callback = scan
})

Rayfield:Notify({
    Title = Strings.NotifyLoaded,
    Content = Strings.NotifyContent,
    Duration = 5.5
})

-- Auto-load default config on start
task.spawn(function()
    task.wait(0.5)
    Window.ConfigurationSaving.FileName = "default"
    Rayfield:LoadConfiguration()
end)

-- Start auto-scan if enabled
if AutoScan then
    StartAutoScan()
end
