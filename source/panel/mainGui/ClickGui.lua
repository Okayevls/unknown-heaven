local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")


if playerGui:FindFirstChild("HeavenGui") then
    playerGui.HeavenGui:Destroy()
end

local currentSettings = nil

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeavenGui"
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Theme = {
    Bg = Color3.fromRGB(245, 250, 255),
    Panel = Color3.fromRGB(255, 255, 255),
    Panel2 = Color3.fromRGB(248, 252, 255),
    Stroke = Color3.fromRGB(210, 225, 245),

    Text = Color3.fromRGB(20, 35, 55),
    SubText = Color3.fromRGB(95, 120, 155),

    Accent = Color3.fromRGB(140, 200, 255),
    Accent2 = Color3.fromRGB(110, 170, 255),

    Round = 14,
    RoundSmall = 10,
}

local function tween(obj, t, props, style, dir)
    local info = TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function mk(inst, props, parent)
    local o = Instance.new(inst)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end

local function addCorner(gui, radius)
    mk("UICorner", {CornerRadius = UDim.new(0, radius or Theme.Round)}, gui)
end

local function addStroke(gui, transparency)
    mk("UIStroke", {Color = Theme.Stroke, Thickness = 1, Transparency = transparency or 0}, gui)
end

local function addPadding(gui, p)
    mk("UIPadding", {
        PaddingLeft = UDim.new(0, p or 10),
        PaddingRight = UDim.new(0, p or 10),
        PaddingTop = UDim.new(0, p or 10),
        PaddingBottom = UDim.new(0, p or 10),
    }, gui)
end

local function addList(gui, padding, dir)
    return mk("UIListLayout", {
        FillDirection = dir or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 8),
    }, gui)
end

local function clamp01(x) return math.clamp(x, 0, 1) end

local ThemeRegistry = {}

local function trackTheme(obj, prop, kind)
    table.insert(ThemeRegistry, {obj=obj, prop=prop, kind=kind})
end

local function applyTheme()
    for _, item in ipairs(ThemeRegistry) do
        if item.obj and item.obj.Parent then
            if item.kind == "Accent" then
                item.obj[item.prop] = Theme.Accent
            elseif item.kind == "Accent2" then
                item.obj[item.prop] = Theme.Accent2
            end
        end
    end
end


local MODULES = {
    Combat = {
        {Name="Aim Assist", Desc="Мягкая помощь при наведении (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="Strength", Default=35, Min=0, Max=100, Step=1},
             {Type="ModeSetting", Name="Mode", Default="Legit", Options={"Legit","Soft","Aggressive"}},
             {Type="MultiBoolean", Name="Targets", Default={Players=true,NPC=false,Team=false,Players1=true,NPC1=false,Team1=false,Players2=true,NPC2=false,Team2=false}},
         }},
        {Name="Clicker", Desc="Авто-клик по нажатию (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="CPS", Default=10, Min=1, Max=25, Step=1},
             {Type="Boolean", Name="HoldOnly", Default=true},
             {Type="String", Name="Note", Default="Аккуратно с режимом."},
         }},
        {Name="Reach", Desc="Изменение дальности взаимодействия (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="Distance", Default=6, Min=3, Max=18, Step=0.5},
             {Type="ModeSetting", Name="Profile", Default="Smooth", Options={"Smooth","Strict"}},
             {Type="Boolean", Name="Visualize", Default=true},
         }},
        {Name="Criticals", Desc="Критические удары (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="ModeSetting", Name="Type", Default="MiniJump", Options={"MiniJump","Timing","None"}},
             {Type="Slider", Name="Chance", Default=60, Min=0, Max=100, Step=5},
             {Type="Boolean", Name="OnlyInAir", Default=false},
         }},
    },
    Movement = {
        {Name="Speed", Desc="Скорость передвижения (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="WalkSpeed", Default=18, Min=8, Max=40, Step=1},
             {Type="ModeSetting", Name="Method", Default="Safe", Options={"Safe","Boost","Custom"}},
             {Type="Boolean", Name="AutoReset", Default=true},
         }},
        {Name="Fly", Desc="Свободный полёт (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="FlySpeed", Default=40, Min=10, Max=120, Step=5},
             {Type="Boolean", Name="NoClip", Default=false},
             {Type="ModeSetting", Name="Control", Default="WASD", Options={"WASD","Camera","Hybrid"}},
         }},
        {Name="BHop", Desc="Авто-прыжки в движении (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="Gain", Default=10, Min=0, Max=35, Step=1},
             {Type="Boolean", Name="OnlyForward", Default=true},
             {Type="ModeSetting", Name="Style", Default="Soft", Options={"Soft","Hard"}},
         }},
        {Name="Step", Desc="Шаг через препятствия (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="Height", Default=2, Min=1, Max=8, Step=0.5},
             {Type="Boolean", Name="Smart", Default=true},
             {Type="String", Name="Hint", Default="Зависит от коллизий."},
         }},
    },
    Visuals = {
        {Name="ESP", Desc="Подсветка сущностей (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="MultiBoolean", Name="Show", Default={Boxes=true,Names=true,Distance=false,Health=true}},
             {Type="Slider", Name="MaxDistance", Default=250, Min=50, Max=1000, Step=25},
             {Type="ModeSetting", Name="Theme", Default="Heaven", Options={"Heaven","Neutral","Contrast"}},
         }},
        {Name="Chams", Desc="Материал/цвет модели (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="ModeSetting", Name="Material", Default="ForceField", Options={"ForceField","Neon","SmoothPlastic"}},
             {Type="Slider", Name="Opacity", Default=60, Min=5, Max=100, Step=5},
             {Type="Boolean", Name="TeamCheck", Default=true},
         }},
        {Name="Fullbright", Desc="Яркость/освещение (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="Brightness", Default=2, Min=0, Max=5, Step=0.1},
             {Type="Boolean", Name="NoFog", Default=true},
             {Type="ModeSetting", Name="Preset", Default="Soft", Options={"Soft","Clear","Studio"}},
         }},
        {Name="FOV", Desc="Изменение поля зрения (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="Value", Default=80, Min=50, Max=120, Step=1},
             {Type="Boolean", Name="Animate", Default=true},
             {Type="String", Name="Info", Default="Камера зависит от игры."},
         }},
    },
    Player = {
        {Name="NoFall", Desc="Снижение урона от падения (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="ModeSetting", Name="Method", Default="Soft", Options={"Soft","Strict"}},
             {Type="Boolean", Name="OnlyHigh", Default=true},
             {Type="Slider", Name="Threshold", Default=25, Min=5, Max=80, Step=5},
         }},
        {Name="AutoHeal", Desc="Авто-использование хилок (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="AtHP%", Default=45, Min=1, Max=99, Step=1},
             {Type="ModeSetting", Name="Priority", Default="Safe", Options={"Safe","Fast"}},
             {Type="Boolean", Name="Sound", Default=true},
         }},
        {Name="AntiAFK", Desc="Защита от AFK-кика (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Slider", Name="Interval", Default=60, Min=15, Max=240, Step=5},
             {Type="ModeSetting", Name="Action", Default="Input", Options={"Input","Camera","Both"}},
             {Type="String", Name="Note", Default="Не злоупотребляй."},
         }},
        {Name="AutoRespawn", Desc="Авто-возрождение/перезагрузка (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Boolean", Name="Fast", Default=false},
             {Type="ModeSetting", Name="When", Default="OnDeath", Options={"OnDeath","LowHP"}},
             {Type="Slider", Name="Delay", Default=1, Min=0, Max=10, Step=0.5},
         }},
    },
    Utility = {
        {Name="Chat Spy", Desc="Лог чата в окне (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="Boolean", Name="Team", Default=true},
             {Type="Slider", Name="Lines", Default=8, Min=3, Max=20, Step=1},
             {Type="String", Name="Filter", Default=""},
         }},
        {Name="AutoBuy", Desc="Авто-покупки (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="ModeSetting", Name="Item", Default="Potion", Options={"Potion","Ammo","Armor"}},
             {Type="Slider", Name="Count", Default=1, Min=1, Max=10, Step=1},
             {Type="Boolean", Name="Confirm", Default=true},
         }},
        {Name="Teleports", Desc="Список точек телепорта (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="ModeSetting", Name="Point", Default="Spawn", Options={"Spawn","Shop","Arena","Hill"}},
             {Type="Boolean", Name="SafeCheck", Default=true},
             {Type="String", Name="CustomName", Default="MyPoint"},
         }},
        {Name="FPS Boost", Desc="Упрощение графики (каркас).",
         Settings={
             {Type="Boolean", Name="Enabled", Default=false},
             {Type="MultiBoolean", Name="Disable", Default={Particles=true,Shadows=true,Decals=false,Water=false}},
             {Type="Slider", Name="Quality", Default=2, Min=0, Max=10, Step=1},
             {Type="ModeSetting", Name="Preset", Default="Balanced", Options={"Max","Balanced","Minimal"}},
         }},
    },
}

local TAB_ORDER = {"Combat","Movement","Visuals","Player","Utility","Theme"}

local State = {
    Modules = {},
    Theme = {Accent = Theme.Accent},
    LastUpdate = "19.01.2026",
    User = {
        Email = "example@gmail.com",
        SubDate = "10.12.2029",
        Role = "Beta",
    }
}

for tabName, list in pairs(MODULES) do
    State.Modules[tabName] = State.Modules[tabName] or {}
    for _, m in ipairs(list) do
        local settings = {}
        for _, s in ipairs(m.Settings) do
            if s.Type == "MultiBoolean" then
                local copy = {}
                for k,v in pairs(s.Default or {}) do copy[k]=v end
                settings[s.Name] = copy
            else
                settings[s.Name] = s.Default
            end
        end
        State.Modules[tabName][m.Name] = {
            Enabled = false,
            Bind = nil,
            Settings = settings,
            Desc = m.Desc,
            Definition = m,
        }
    end
end

local dim = mk("Frame", {
    Name="Dim",
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.55,
    Size=UDim2.fromScale(1,1),
    Visible=true,
}, screenGui)
dim.ZIndex = 1

local main = mk("Frame", {
    Name="Main",
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.fromScale(0.5,0.5),
    Size=UDim2.fromOffset(860, 560),
    BackgroundColor3=Theme.Bg,
}, screenGui)
addCorner(main, Theme.Round)
addStroke(main, 0)
main.ZIndex = 2

local top = mk("Frame", {
    Name="Top",
    BackgroundColor3=Theme.Panel,
    Size=UDim2.new(1,0,0,96),
}, main)
addCorner(top, Theme.Round)
addStroke(top, 0)

mk("Frame", {BackgroundColor3=Theme.Panel, BorderSizePixel=0, Size=UDim2.new(1,0,0,Theme.Round), Position=UDim2.new(0,0,1,-Theme.Round)}, top)

mk("TextLabel", {
    Name="Title",
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(18, 14),
    Size=UDim2.fromOffset(260, 28),
    Text="Heaven",
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBold,
    TextSize=22,
    TextColor3=Theme.Text
}, top)

mk("TextLabel", {
    Name="Sub",
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(18, 46),
    Size=UDim2.fromOffset(420, 22),
    Text=("Last update: %s"):format(State.LastUpdate),
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamMedium,
    TextSize=14,
    TextColor3=Theme.SubText
}, top)

local userCard = mk("Frame", {
    Name="UserCard",
    AnchorPoint=Vector2.new(1,0.5),
    Position=UDim2.new(1,-16,0.5,0),
    Size=UDim2.fromOffset(360, 68),
    BackgroundColor3=Theme.Panel2,
}, top)
addCorner(userCard, Theme.RoundSmall)
addStroke(userCard, 0)

local avatar = mk("ImageLabel", {
    Name="Avatar",
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(10,10),
    Size=UDim2.fromOffset(48,48),
    Image="",
}, userCard)
addCorner(avatar, 14)

task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if ok then avatar.Image = img end
end)

mk("TextLabel", {
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(68, 10),
    Size=UDim2.fromOffset(280, 18),
    Text=("Name: %s"):format(localPlayer.Name),
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBold,
    TextSize=14,
    TextColor3=Theme.Text
}, userCard)

mk("TextLabel", {
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(68, 30),
    Size=UDim2.fromOffset(280, 16),
    Text=("Gmail: %s"):format(State.User.Email),
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamMedium,
    TextSize=12,
    TextColor3=Theme.SubText
}, userCard)

mk("TextLabel", {
    BackgroundTransparency=1,
    Position=UDim2.fromOffset(68, 46),
    Size=UDim2.fromOffset(280, 16),
    Text=("Sub: %s  •  Role: %s"):format(State.User.SubDate, State.User.Role),
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamMedium,
    TextSize=12,
    TextColor3=Theme.SubText
}, userCard)

local body = mk("Frame", {
    Name="Body",
    BackgroundTransparency=1,
    Position=UDim2.new(0,0,0,108),
    Size=UDim2.new(1,0,1,-120),
}, main)

local tabsBar = mk("Frame", {
    Name="Tabs",
    BackgroundColor3=Theme.Panel,
    Size=UDim2.new(0,190,1,0),
}, body)
addCorner(tabsBar, Theme.Round)
addStroke(tabsBar, 0)
addPadding(tabsBar, 12)
addList(tabsBar, 8)

local content = mk("Frame", {
    Name="Content",
    BackgroundColor3=Theme.Panel,
    Position=UDim2.new(0, 200, 0, 0),
    Size=UDim2.new(1, -200, 1, 0),
}, body)
addCorner(content, Theme.Round)
addStroke(content, 0)
addPadding(content, 12)

local settingsCloseOverlay = mk("TextButton", {
    Name="SettingsCloseOverlay",
    BackgroundTransparency=1,
    Text="",
    AutoButtonColor=false,
    Visible=false,
    Active=false,
    Size=UDim2.fromScale(1,1),
}, content)

local settingsPane = mk("Frame", {
    Name="SettingsPane",
    BackgroundColor3=Theme.Panel2,
    AnchorPoint=Vector2.new(1,0),
    Position=UDim2.new(1,0,0,0),

    Size=UDim2.new(0, 300, 1, 0),
    Visible=false,
}, content)
addCorner(settingsPane, Theme.RoundSmall)
addStroke(settingsPane, 0)
addPadding(settingsPane, 10)

local settingsTopRow = mk("Frame", {
    BackgroundTransparency=1,
    Size=UDim2.new(1,0,0,20),
}, settingsPane)


local settingsTitle = mk("TextLabel", {
    BackgroundTransparency=1,
    Size=UDim2.new(1,-40,1,0),
    Text="Settings",
    TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBold,
    TextSize=14,
    TextColor3=Theme.Text,
}, settingsTopRow)

local settingsCloseBtn = mk("TextButton", {
    BackgroundColor3=Theme.Panel,
    Size=UDim2.fromOffset(28,18),
    AnchorPoint=Vector2.new(1,0),
    Position=UDim2.new(1,0,0,0),
    Text="X",
    Font=Enum.Font.GothamBold,
    TextSize=12,
    TextColor3=Theme.SubText,
    AutoButtonColor=false,
}, settingsTopRow)
addCorner(settingsCloseBtn, 8)
addStroke(settingsCloseBtn, 0.2)

local settingsContainer = mk("ScrollingFrame", {
    Name="SettingsContainer",
    BackgroundTransparency=1,

    Position = UDim2.new(0,0,0,27),
    Size = UDim2.new(1,0,1,-27),

    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0,0,0,0),

    ClipsDescendants = true,
}, settingsPane)

addList(settingsContainer, 8)
addPadding(settingsContainer, 2)

local modulesArea = mk("ScrollingFrame", {
    Name="ModulesArea",
    BackgroundTransparency=1,
    Size=UDim2.new(1, -312, 1, 0),

    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0,0,0,0),

    ClipsDescendants = true,
}, content)

addList(modulesArea, 10)
addPadding(modulesArea, 2)

local MODULES_AREA_NORMAL_SIZE = UDim2.new(1, -312, 1, 0)
local MODULES_AREA_FULL_SIZE   = UDim2.new(1, 0, 1, 0)

local function closeSettings()
    settingsPane.Visible = false
    settingsCloseOverlay.Visible = false
    currentSettings = nil
end

settingsCloseBtn.MouseButton1Click:Connect(closeSettings)

local function createMiniToggle(parent)
    local root = mk("Frame", {BackgroundColor3=Theme.Panel, Size=UDim2.fromOffset(38, 20)}, parent)
    addCorner(root, 10)
    addStroke(root, 0.2)

    local knob = mk("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromOffset(2,2),
    }, root)
    addCorner(knob, 8)
    trackTheme(knob, "BackgroundColor3", "Accent")

    local line = mk("Frame", {
        BackgroundColor3 = Theme.Accent2,
        Size = UDim2.fromOffset(10, 2),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.fromScale(0.5,0.5),
        BackgroundTransparency = 0.55,
    }, knob)
    addCorner(line, 1)
    trackTheme(line, "BackgroundColor3", "Accent2")

    local hit = mk("TextButton", {BackgroundTransparency=1, Text="", Size=UDim2.fromScale(1,1), AutoButtonColor=false}, root)

    local set = {Value=false}
    function set:Set(v)
        self.Value = (v and true) or false
        if self.Value then
            tween(root, 0.2, {BackgroundColor3=Theme.Accent, BackgroundTransparency=0.2})
            tween(knob, 0.2, {Position=UDim2.fromOffset(20,2), BackgroundColor3=Color3.fromRGB(255,255,255)})
            tween(line, 0.2, {BackgroundTransparency=0.75})
        else
            tween(root, 0.2, {BackgroundColor3=Theme.Panel, BackgroundTransparency=0})
            tween(knob, 0.2, {Position=UDim2.fromOffset(2,2), BackgroundColor3=Theme.Accent})
            tween(line, 0.2, {BackgroundTransparency=0.55})
        end
    end

    hit.MouseButton1Click:Connect(function()
        set:Set(not set.Value)
        if set.OnChanged then
            set.OnChanged(set.Value)
        end
    end)

    return set, root
end

local function tinyButton(parent, text)
    local b = mk("TextButton", {
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.fromOffset(54, 22),
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        AutoButtonColor = false,
    }, parent)
    addCorner(b, 8)
    addStroke(b, 0.2)

    b.MouseEnter:Connect(function() tween(b, 0.12, {BackgroundColor3 = Theme.Panel2}) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, {BackgroundColor3 = Theme.Panel}) end)
    return b
end

local function bindToText(bind)
    if not bind then return "None" end
    if bind.kind == "KeyCode" then return bind.code.Name end
    if bind.kind == "UserInputType" then
        local n = bind.code.Name
        return n:gsub("MouseButton", "M")
    end
    return "None"
end

local activeBindTarget = nil

local function setBind(tab, moduleName, bind)
    State.Modules[tab][moduleName].Bind = bind
end

local function isDeleteBindInput(input)
    return input.KeyCode == Enum.KeyCode.Delete
end

local function inputToBind(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.Unknown then return nil end
        if input.KeyCode == Enum.KeyCode.Delete then return nil end
        return {kind="KeyCode", code=input.KeyCode}
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.MouseButton3 then
        return {kind="UserInputType", code=input.UserInputType}
    end
    return nil
end

local function bindsEqual(a,b)
    if a==nil and b==nil then return true end
    if not a or not b then return false end
    return a.kind==b.kind and a.code==b.code
end

local function clearSettingsUI()
    for _, c in ipairs(settingsContainer:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local function settingRowBase(name, hint)
    local row = mk("Frame", {BackgroundColor3=Theme.Panel, Size=UDim2.new(1,0,0,50)}, settingsContainer)
    addCorner(row, Theme.RoundSmall)
    addStroke(row, 0.2)
    addPadding(row, 10)

    mk("TextLabel", {
        BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,16),
        Text=name,
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamBold,
        TextSize=13,
        TextColor3=Theme.Text
    }, row)

    mk("TextLabel", {
        BackgroundTransparency=1,
        Position=UDim2.new(0,0,0,18),
        Size=UDim2.new(1,0,0,14),
        Text=hint or "",
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamMedium,
        TextSize=11,
        TextColor3=Theme.SubText
    }, row)

    return row
end

local function addBooleanSetting(tab, moduleName, sDef)
    local row = settingRowBase(sDef.Name, "Boolean")
    local holder = mk("Frame", {
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,0,0.5,0),
        Size=UDim2.fromOffset(40, 20),
    }, row)

    local tgl = createMiniToggle(holder)
    tgl:Set(State.Modules[tab][moduleName].Settings[sDef.Name])
    tgl.OnChanged = function(v) State.Modules[tab][moduleName].Settings[sDef.Name] = v end
end

local function addSliderSetting(tab, moduleName, sDef)
    local row = settingRowBase(sDef.Name, ("Slider • %s–%s"):format(sDef.Min, sDef.Max))
    row.Size = UDim2.new(1,0,0,65)

    local bar = mk("Frame", {BackgroundColor3=Theme.Panel2, Position=UDim2.new(0,0,0,37), Size=UDim2.new(1,0,0,10)}, row)
    addCorner(bar, 8)
    addStroke(bar, 0.35)

    local fill = mk("Frame", {BackgroundColor3=Theme.Accent, Size=UDim2.new(0,0,1,0)}, bar)
    addCorner(fill, 8)
    trackTheme(fill, "BackgroundColor3", "Accent")

    local knob = mk("Frame", {
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0,0,0.5,0),
    }, bar)
    addCorner(knob, 7)
    addStroke(knob, 0.2)

    local valLabel = mk("TextLabel", {
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(1,0),
        Position=UDim2.new(1,0,0,0),
        Size=UDim2.fromOffset(80, 16),
        TextXAlignment=Enum.TextXAlignment.Right,
        Font=Enum.Font.GothamBold,
        TextSize=12,
        TextColor3=Theme.Text
    }, row)

    local function setValue(v)
        local step = sDef.Step or 1
        v = math.clamp(v, sDef.Min, sDef.Max)
        v = math.floor((v - sDef.Min)/step + 0.5)*step + sDef.Min
        State.Modules[tab][moduleName].Settings[sDef.Name] = v
        valLabel.Text = tostring(v)
        local alpha = (v - sDef.Min) / (sDef.Max - sDef.Min)
        fill.Size = UDim2.new(alpha,0,1,0)
        knob.Position = UDim2.new(alpha,0,0.5,0)
    end
    setValue(State.Modules[tab][moduleName].Settings[sDef.Name])

    local dragging = false
    local function updateFromX(x)
        local abs = bar.AbsolutePosition.X
        local w = bar.AbsoluteSize.X
        local a = clamp01((x - abs) / w)
        setValue(sDef.Min + a*(sDef.Max - sDef.Min))
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(i.Position.X)
            tween(knob, 0.12, {Size = UDim2.fromOffset(16,16)})
        end
    end)
    bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            tween(knob, 0.12, {Size = UDim2.fromOffset(14,14)})
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(i.Position.X)
        end
    end)
end

local function addMultiBooleanSetting(tab, moduleName, sDef)
    local row = settingRowBase(sDef.Name, "MultiBoolean")
    local wrapTop = 41

    local wrap = mk("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,wrapTop),
        Size = UDim2.new(1,0,0,10),
        ClipsDescendants = true,
    }, row)

    local cols = 4
    local padX, padY = 6, 6

    local grid = mk("UIGridLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        CellPadding = UDim2.fromOffset(padX, padY),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = cols,
        StartCorner = Enum.StartCorner.TopLeft,
    }, wrap)

    local values = State.Modules[tab][moduleName].Settings[sDef.Name]

    local function makeChip(label)
        local chip = mk("TextButton", {
            BackgroundColor3 = Theme.Panel,
            Text = label,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Theme.Text,
            AutoButtonColor = false,
        }, wrap)
        addCorner(chip, 8)
        addStroke(chip, 0.25)

        local function render()
            if values[label] then
                tween(chip, 0.14, {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(255,255,255)})
            else
                tween(chip, 0.14, {BackgroundColor3 = Theme.Panel, TextColor3 = Theme.Text})
            end
        end

        chip.MouseEnter:Connect(function()
            if not values[label] then tween(chip, 0.10, {BackgroundColor3 = Theme.Panel2}) end
        end)
        chip.MouseLeave:Connect(render)

        chip.MouseButton1Click:Connect(function()
            values[label] = not values[label]
            render()
        end)

        render()
    end

    local keys = {}
    for k in pairs(sDef.Default) do table.insert(keys, k) end
    table.sort(keys)
    for _, key in ipairs(keys) do makeChip(key) end

    local function updateCellSize()
        local w = wrap.AbsoluteSize.X
        if w <= 0 then return end

        local offsetRight = 0

        local available = w - offsetRight - (padX * (cols - 1))
        local cellW = math.floor(available / cols)

        cellW = math.clamp(cellW, 48, 80)
        grid.CellSize = UDim2.fromOffset(cellW, 20)
    end

    local function resizeHeights()
        local h = grid.AbsoluteContentSize.Y
        wrap.Size = UDim2.new(1,0,0,h)
        row.Size = UDim2.new(1,0,0, wrapTop + h + 17)
    end

    wrap:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        updateCellSize()
        resizeHeights()
    end)
    grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeHeights)

    task.defer(function()
        updateCellSize()
        resizeHeights()
    end)
end


local function addStringSetting(tab, moduleName, sDef)
    local row = settingRowBase(sDef.Name, "String")
    row.Size = UDim2.new(1,0,0,58)

    local box = mk("TextBox", {
        BackgroundColor3=Theme.Panel2,
        Position=UDim2.new(0,0,0,32),
        Size=UDim2.new(1,0,0,20),
        Text=tostring(State.Modules[tab][moduleName].Settings[sDef.Name] or ""),
        ClearTextOnFocus=false,
        Font=Enum.Font.GothamMedium,
        TextSize=12,
        TextColor3=Theme.Text,
        PlaceholderText="Введите текст...",
    }, row)
    addCorner(box, 8)
    addStroke(box, 0.35)

    box.FocusLost:Connect(function()
        State.Modules[tab][moduleName].Settings[sDef.Name] = box.Text
    end)
end

local function addModeSetting(tab, moduleName, sDef)
    local row = settingRowBase(sDef.Name, "ModeSetting")

    local holder = mk("Frame", {
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,0,0.5,0),
        Size=UDim2.fromOffset(160, 22),
    }, row)

    local left = tinyButton(holder, "<"); left.Size = UDim2.fromOffset(28,22)
    local mid = mk("TextLabel", {
        BackgroundColor3=Theme.Panel2,
        Position=UDim2.fromOffset(34,0),
        Size=UDim2.fromOffset(92,22),
        Text="",
        Font=Enum.Font.GothamBold,
        TextSize=12,
        TextColor3=Theme.Text
    }, holder)
    addCorner(mid, 8); addStroke(mid, 0.35)

    local right = tinyButton(holder, ">"); right.Size = UDim2.fromOffset(28,22); right.Position = UDim2.fromOffset(132,0)

    local options = sDef.Options or {}
    local current = State.Modules[tab][moduleName].Settings[sDef.Name]
    local idx = table.find(options, current) or 1

    local function refresh()
        State.Modules[tab][moduleName].Settings[sDef.Name] = options[idx]
        mid.Text = tostring(options[idx])
    end
    refresh()

    left.MouseButton1Click:Connect(function()
        idx -= 1
        if idx < 1 then idx = #options end
        tween(mid, 0.10, {BackgroundTransparency=0.15})
        refresh()
        tween(mid, 0.10, {BackgroundTransparency=0})
    end)

    right.MouseButton1Click:Connect(function()
        idx += 1
        if idx > #options then idx = 1 end
        tween(mid, 0.10, {BackgroundTransparency=0.15})
        refresh()
        tween(mid, 0.10, {BackgroundTransparency=0})
    end)
end

local function renderSettings(tab, moduleName)
    clearSettingsUI()
    settingsPane.Visible = true
    settingsCloseOverlay.Visible = true

    currentSettings = {tab = tab, module = moduleName}

    settingsTitle.Text = ("Settings • %s"):format(moduleName)
    --settingsSub.Text = State.Modules[tab][moduleName].Desc

    for _, sDef in ipairs(State.Modules[tab][moduleName].Definition.Settings) do
        if sDef.Type == "Boolean" then addBooleanSetting(tab, moduleName, sDef)
        elseif sDef.Type == "Slider" then addSliderSetting(tab, moduleName, sDef)
        elseif sDef.Type == "MultiBoolean" then addMultiBooleanSetting(tab, moduleName, sDef)
        elseif sDef.Type == "String" then addStringSetting(tab, moduleName, sDef)
        elseif sDef.Type == "ModeSetting" then addModeSetting(tab, moduleName, sDef)
        end
    end
end

local function moduleCard(tabName, mName, desc)
    local card = mk("Frame", {BackgroundColor3=Theme.Panel2, Size=UDim2.new(1,0,0,72)}, modulesArea)
    addCorner(card, Theme.RoundSmall)
    addStroke(card, 0.2)
    addPadding(card, 10)

    mk("TextLabel", {
        BackgroundTransparency=1,
        Size=UDim2.new(1,-140,0,18),
        Text=mName,
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamBold,
        TextSize=14,
        TextColor3=Theme.Text
    }, card)

    mk("TextLabel", {
        BackgroundTransparency=1,
        Position=UDim2.new(0,0,0,20),
        Size=UDim2.new(1,-140,0,34),
        Text=desc,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top,
        TextWrapped=true,
        Font=Enum.Font.GothamMedium,
        TextSize=12,
        TextColor3=Theme.SubText
    }, card)

    local toggleHolder = mk("Frame", {
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,0,0.5,-10),
        Size=UDim2.fromOffset(40, 20),
    }, card)
    local tgl = createMiniToggle(toggleHolder)

    local bindBtn = tinyButton(card, "Bind")
    bindBtn.AnchorPoint = Vector2.new(1,0)
    bindBtn.Position = UDim2.new(1,0,0,44)
    bindBtn.Size = UDim2.fromOffset(54, 22)

    local bindLabel = mk("TextLabel", {
        BackgroundTransparency=1,
        AnchorPoint=Vector2.new(1,0),
        Position=UDim2.new(1,-60,0,46),
        Size=UDim2.fromOffset(90, 18),
        TextXAlignment=Enum.TextXAlignment.Right,
        Font=Enum.Font.GothamBold,
        TextSize=12,
        TextColor3=Theme.SubText,
        Text="None"
    }, card)

    local function refreshBind()
        bindLabel.Text = bindToText(State.Modules[tabName][mName].Bind)
    end
    refreshBind()

    tgl:Set(State.Modules[tabName][mName].Enabled)
    tgl.OnChanged = function(v)
        State.Modules[tabName][mName].Enabled = v
    end
    State.Modules[tabName][mName]._uiToggle = tgl

    card.MouseEnter:Connect(function() tween(card, 0.12, {BackgroundColor3 = Theme.Panel}) end)
    card.MouseLeave:Connect(function() tween(card, 0.12, {BackgroundColor3 = Theme.Panel2}) end)

    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            if settingsPane.Visible and currentSettings
                    and currentSettings.tab == tabName
                    and currentSettings.module == mName then
                closeSettings()
            else
                renderSettings(tabName, mName)
            end
        end
    end)

    bindBtn.MouseButton1Click:Connect(function()
        if activeBindTarget and activeBindTarget.tab == tabName and activeBindTarget.moduleName == mName then
            activeBindTarget = nil
            setBind(tabName, mName, nil)
            refreshBind()
            tween(bindBtn, 0.12, {BackgroundColor3 = Theme.Panel, TextColor3 = Theme.Text})
            return
        end

        activeBindTarget = {tab=tabName, moduleName=mName, button=bindBtn, label=bindLabel}
        tween(bindBtn, 0.12, {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(255,255,255)})
        bindLabel.Text = "Press..."
    end)

    return refreshBind
end

local tabButtons = {}
local activeTab = nil

local function clearModulesUI()
    for _, c in ipairs(modulesArea:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local function themePresetTile(parent, name, col, onPick)
    local wrap = mk("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(92, 98),
    }, parent)

    local tile = mk("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.fromScale(1, 0),
        SizeConstraint = Enum.SizeConstraint.RelativeXX,
        Text = "",
    }, wrap)

    tile.Size = UDim2.new(1, 0, 0, 72)

    addCorner(tile, 14)
    addStroke(tile, 0.18)

    local swatch = mk("Frame", {
        BackgroundColor3 = col,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 1, -16),
    }, tile)
    addCorner(swatch, 12)

    mk("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.86),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, swatch)

    local badge = mk("Frame", {
        BackgroundColor3 = Theme.Panel,
        AnchorPoint = Vector2.new(1,0),
        Position = UDim2.new(1,-6,0,6),
        Size = UDim2.fromOffset(22,22),
    }, tile)
    addCorner(badge, 11)
    addStroke(badge, 0.25)

    local check = mk("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,1),
        Text = "✓",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Theme.Text,
        TextTransparency = 1,
    }, badge)

    local lbl = mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,74),
        Size = UDim2.new(1,0,0,18),
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Center,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, wrap)

    local function setHover(on)
        if on then
            tween(tile, 0.12, {BackgroundColor3 = Theme.Panel2})
            tween(badge, 0.12, {BackgroundColor3 = Theme.Panel2})
        else
            tween(tile, 0.12, {BackgroundColor3 = Theme.Panel})
            tween(badge, 0.12, {BackgroundColor3 = Theme.Panel})
        end
    end

    tile.MouseEnter:Connect(function() setHover(true) end)
    tile.MouseLeave:Connect(function() setHover(false) end)

    tile.MouseButton1Down:Connect(function()
        tween(tile, 0.08, {Size = UDim2.new(1, 0, 0, 70)})
    end)
    tile.MouseButton1Up:Connect(function()
        tween(tile, 0.08, {Size = UDim2.new(1, 0, 0, 72)})
    end)

    tile.MouseButton1Click:Connect(onPick)

    return wrap, check
end

local function makeMiniSlider(parent, title, startValue01, onChanged)
    local row = mk("Frame", {
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(1,0,0,52),
    }, parent)
    addCorner(row, Theme.RoundSmall)
    addStroke(row, 0.2)
    addPadding(row, 10)

    mk("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,16),
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Theme.Text,
    }, row)

    local valueLabel = mk("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1,0),
        Position = UDim2.new(1,0,0,0),
        Size = UDim2.fromOffset(70,16),
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.SubText,
    }, row)

    local bar = mk("Frame", {
        BackgroundColor3 = Theme.Panel2,
        Position = UDim2.new(0,0,0,30),
        Size = UDim2.new(1,0,0,10),
    }, row)
    addCorner(bar, 8)
    addStroke(bar, 0.35)

    local fill = mk("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0,0,1,0),
    }, bar)
    addCorner(fill, 8)
    trackTheme(fill, "BackgroundColor3", "Accent")

    local knob = mk("Frame", {
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.fromOffset(14, 14),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0,0,0.5,0),
    }, bar)
    addCorner(knob, 7)
    addStroke(knob, 0.2)

    local dragging = false
    local value01 = clamp01(startValue01 or 0)

    local function set01(a)
        value01 = clamp01(a)
        fill.Size = UDim2.new(value01,0,1,0)
        knob.Position = UDim2.new(value01,0,0.5,0)
        valueLabel.Text = tostring(math.floor(value01 * 255 + 0.5))
        if onChanged then onChanged(value01) end
    end

    local function updateFromX(x)
        local abs = bar.AbsolutePosition.X
        local w = bar.AbsoluteSize.X
        if w <= 0 then return end
        set01((x - abs) / w)
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(i.Position.X)
            tween(knob, 0.12, {Size = UDim2.fromOffset(16,16)})
        end
    end)
    bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            tween(knob, 0.12, {Size = UDim2.fromOffset(14,14)})
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(i.Position.X)
        end
    end)

    set01(value01)

    return {
        Set01 = set01,
        Get01 = function() return value01 end,
    }
end

local function renderThemeTab()
    clearModulesUI()
    closeSettings()
    activeBindTarget = nil

    local function applyAccent(col)
        Theme.Accent = col
        Theme.Accent2 = col:Lerp(Color3.new(1,1,1), 0.22)
        State.Theme.Accent = col

        applyTheme()

        for t, btn in pairs(tabButtons) do
            if t == activeTab then
                btn.BackgroundColor3 = Theme.Accent
                btn.TextColor3 = Color3.fromRGB(255,255,255)
            end
        end
    end

    local header = mk("Frame", {
        BackgroundColor3 = Theme.Panel2,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1,0,1,0),
        ClipsDescendants = false,
    }, modulesArea)
    addCorner(header, Theme.RoundSmall)
    addStroke(header, 0.2)
    addPadding(header, 10)

    local headerList = mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,8),
    }, header)

    mk("TextLabel", {
        BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,20),
        Text="Theme",
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamBold,
        TextSize=16,
        TextColor3=Theme.Text
    }, header)

    mk("TextLabel", {
        BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,16),
        Text="Accent применяется сразу. Палитра скроллится колёсиком.",
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamMedium,
        TextSize=12,
        TextColor3=Theme.SubText
    }, header)

    local actions = mk("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,28),
    }, header)

    local resetBtn = tinyButton(actions, "Reset")
    resetBtn.Size = UDim2.fromOffset(70, 24)

    local customJumpBtn = tinyButton(actions, "Custom")
    customJumpBtn.Size = UDim2.fromOffset(78, 24)
    customJumpBtn.Position = UDim2.fromOffset(78, 0)

    local tip = mk("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 166, 0, 2),
        Size = UDim2.new(1, -166, 1, 0),
        Text = "Скролль ниже для RGB (Custom).",
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Theme.SubText,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, actions)

    local presets = mk("ScrollingFrame", {
        Name = "Presets",
        BackgroundTransparency = 1,

        Size = UDim2.new(1,0,0,220),

        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        ScrollBarImageTransparency = 0.35,

        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0,0,0,0),
        ClipsDescendants = true,
    }, header)

    local grid = mk("UIGridLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        CellPadding = UDim2.fromOffset(10, 10),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 4,
        StartCorner = Enum.StartCorner.TopLeft,
    }, presets)

    local presetList = {
        {"Heaven", Color3.fromRGB(140,200,255)},
        {"Ocean",  Color3.fromRGB(90,160,255)},
        {"Mint",   Color3.fromRGB(120,230,190)},
        {"Rose",   Color3.fromRGB(255,140,175)},
        {"Lime",   Color3.fromRGB(170,255,140)},
        {"Sunset", Color3.fromRGB(255,170,110)},
        {"Violet", Color3.fromRGB(180,140,255)},
        {"Amber",  Color3.fromRGB(255,210,90)},
        {"Teal",   Color3.fromRGB(90,220,255)},
        {"Coral",  Color3.fromRGB(255,120,120)},
        {"Mono",   Color3.fromRGB(190,205,225)},
        {"Deep",   Color3.fromRGB(110,170,255)},
        {"Ice",    Color3.fromRGB(180,240,255)},
        {"Grape",  Color3.fromRGB(150,90,255)},
        {"Peach",  Color3.fromRGB(255,190,150)},
        {"Steel",  Color3.fromRGB(140,160,190)},
    }

    local tiles = {}
    local function clearChecks()
        for _, it in ipairs(tiles) do it.check.TextTransparency = 1 end
    end
    local function setCheckByIndex(idx)
        for i, it in ipairs(tiles) do
            it.check.TextTransparency = (i == idx) and 0 or 1
        end
    end

    local function updateGridCell()
        local cols = 4
        local pad = 10
        local w = presets.AbsoluteSize.X
        if w <= 0 then return end

        local cellW = math.floor((w - (pad * (cols - 1))) / cols)
        cellW = math.clamp(cellW, 78, 120)
        grid.CellSize = UDim2.fromOffset(cellW, 98)
    end
    presets:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateGridCell)
    task.defer(updateGridCell)

    for i, p in ipairs(presetList) do
        local name, col = p[1], p[2]
        local _, check = themePresetTile(presets, name, col, function()
            applyAccent(col)
            setCheckByIndex(i)
        end)
        table.insert(tiles, {check = check, col = col})
    end

    do
        local picked = nil
        for i, it in ipairs(tiles) do
            if Theme.Accent == it.col then picked = i break end
        end
        if picked then setCheckByIndex(picked) else clearChecks() end
    end

    resetBtn.MouseButton1Click:Connect(function()
        local col = Color3.fromRGB(140,200,255)
        applyAccent(col)
        local picked = nil
        for i, it in ipairs(tiles) do
            if it.col == col then picked = i break end
        end
        if picked then setCheckByIndex(picked) else clearChecks() end
    end)

    local customCard = mk("Frame", {
        BackgroundColor3 = Theme.Panel2,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1,0,0,0),
        ClipsDescendants = false,
    }, modulesArea)
    addCorner(customCard, Theme.RoundSmall)
    addStroke(customCard, 0.2)
    addPadding(customCard, 10)

    local ccList = mk("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,8),
    }, customCard)

    mk("TextLabel", {
        BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,20),
        Text="Custom Accent (RGB)",
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamBold,
        TextSize=16,
        TextColor3=Theme.Text
    }, customCard)

    mk("TextLabel", {
        BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,16),
        Text="Настрой Accent и нажми Apply (галочки пресетов снимутся).",
        TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamMedium,
        TextSize=12,
        TextColor3=Theme.SubText
    }, customCard)

    local previewRow = mk("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,48),
    }, customCard)

    local preview = mk("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.fromOffset(64, 48),
    }, previewRow)
    addCorner(preview, 12)
    addStroke(preview, 0.25)

    local applyBtn = mk("TextButton", {
        BackgroundColor3 = Theme.Panel,
        AutoButtonColor = false,
        Position = UDim2.new(0, 74, 0, 12),
        Size = UDim2.fromOffset(90, 24),
        Text = "Apply",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
    }, previewRow)
    addCorner(applyBtn, 10)
    addStroke(applyBtn, 0.2)

    applyBtn.MouseEnter:Connect(function() tween(applyBtn, 0.12, {BackgroundColor3 = Theme.Panel2}) end)
    applyBtn.MouseLeave:Connect(function() tween(applyBtn, 0.12, {BackgroundColor3 = Theme.Panel}) end)

    local r01, g01, b01 = Theme.Accent.R, Theme.Accent.G, Theme.Accent.B
    local function updatePreview()
        preview.BackgroundColor3 = Color3.new(r01, g01, b01)
    end
    updatePreview()

    makeMiniSlider(customCard, "Red",   r01, function(v) r01 = v; updatePreview() end)
    makeMiniSlider(customCard, "Green", g01, function(v) g01 = v; updatePreview() end)
    makeMiniSlider(customCard, "Blue",  b01, function(v) b01 = v; updatePreview() end)

    applyBtn.MouseButton1Click:Connect(function()
        applyAccent(Color3.new(r01, g01, b01))
        clearChecks()
    end)

    customJumpBtn.MouseButton1Click:Connect(function()
        local y = customCard.AbsolutePosition.Y - modulesArea.AbsolutePosition.Y + modulesArea.CanvasPosition.Y
        modulesArea.CanvasPosition = Vector2.new(modulesArea.CanvasPosition.X, math.max(0, y))
    end)
end


local function renderTab(tabName)
    activeTab = tabName
    closeSettings()
    activeBindTarget = nil

    for t, btn in pairs(tabButtons) do
        if t == tabName then
            tween(btn, 0.12, {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(255,255,255)})
        else
            tween(btn, 0.12, {BackgroundColor3 = Theme.Panel2, TextColor3 = Theme.Text})
        end
    end

    if tabName == "Theme" then
        modulesArea.Size = MODULES_AREA_FULL_SIZE
        renderThemeTab()
        return
    else
        modulesArea.Size = MODULES_AREA_NORMAL_SIZE
    end

    clearModulesUI()
    for _, m in ipairs(MODULES[tabName]) do
        moduleCard(tabName, m.Name, m.Desc)
    end
end

for _, tabName in ipairs(TAB_ORDER) do
    local b = mk("TextButton", {
        BackgroundColor3 = Theme.Panel2,
        Size = UDim2.new(1,0,0,42),
        Text = tabName,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        AutoButtonColor = false,
    }, tabsBar)
    addCorner(b, Theme.RoundSmall)
    addStroke(b, 0.2)

    b.MouseEnter:Connect(function()
        if activeTab ~= tabName then tween(b, 0.10, {BackgroundColor3 = Theme.Panel}) end
    end)
    b.MouseLeave:Connect(function()
        if activeTab ~= tabName then tween(b, 0.10, {BackgroundColor3 = Theme.Panel2}) end
    end)

    b.MouseButton1Click:Connect(function() renderTab(tabName) end)
    tabButtons[tabName] = b
end

renderTab("Combat")

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if isDeleteBindInput(input) then
        if activeBindTarget then
            setBind(activeBindTarget.tab, activeBindTarget.moduleName, nil)
            activeBindTarget.label.Text = "None"
            tween(activeBindTarget.button, 0.10, {BackgroundColor3 = Theme.Panel, TextColor3 = Theme.Text})
            activeBindTarget = nil
        end
        return
    end

    if activeBindTarget then
        local bind = inputToBind(input)
        if bind then
            setBind(activeBindTarget.tab, activeBindTarget.moduleName, bind)
            activeBindTarget.label.Text = bindToText(bind)
            tween(activeBindTarget.button, 0.10, {BackgroundColor3 = Theme.Panel, TextColor3 = Theme.Text})
            activeBindTarget = nil
        end
        return
    end

    for tabName, mods in pairs(State.Modules) do
        for moduleName, info in pairs(mods) do
            local b = info.Bind
            if b then
                if b.kind == "KeyCode" and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == b.code then
                    info.Enabled = not info.Enabled
                    if info._uiToggle then
                        info._uiToggle:Set(info.Enabled)
                    end
                elseif b.kind == "UserInputType" and input.UserInputType == b.code then
                    info.Enabled = not info.Enabled
                    if info._uiToggle then
                        info._uiToggle:Set(info.Enabled)
                    end
                end
            end
        end
    end
end)

do
    local dragging = false
    local dragStart, startPos
    top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
            tween(main, 0.10, {Size = UDim2.fromOffset(870, 568)})
        end
    end)
    top.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            tween(main, 0.10, {Size = UDim2.fromOffset(860, 560)})
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local uiVisible = true
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        uiVisible = not uiVisible
        dim.Visible = uiVisible
        main.Visible = uiVisible
    end
end)

applyTheme()
