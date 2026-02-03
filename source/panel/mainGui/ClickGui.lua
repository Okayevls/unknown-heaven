local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local ctx = getgenv().ctx
local moduleMgr = ctx and ctx.moduleMgr

assert(moduleMgr, "Heaven UI: ctx.moduleMgr not found. Make sure loader creates ModuleManager and puts it in getgenv().ctx")


if playerGui:FindFirstChild("HeavenGui") then
    playerGui.HeavenGui:Destroy()
end

local currentSettings = nil
local SettingsConnections = {}
local ThemeConnections = {}
local function trackThemeConn(c)
    table.insert(ThemeConnections, c)
    return c
end

local function disconnectThemeConns()
    for i = #ThemeConnections, 1, -1 do
        local c = ThemeConnections[i]
        ThemeConnections[i] = nil
        if c and c.Disconnect then c:Disconnect() end
    end
end

local function trackConn(c)
    table.insert(SettingsConnections, c)
    return c
end
local function disconnectSettingsConns()
    for i = #SettingsConnections, 1, -1 do
        local c = SettingsConnections[i]
        SettingsConnections[i] = nil
        if c and c.Disconnect then c:Disconnect() end
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
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

local function compactThemeRegistry()
    for i = #ThemeRegistry, 1, -1 do
        local it = ThemeRegistry[i]
        if not it or not it.obj or not it.obj.Parent then
            table.remove(ThemeRegistry, i)
        end
    end
end

local function trackTheme(obj, prop, kind)
    table.insert(ThemeRegistry, {obj=obj, prop=prop, kind=kind})
end

local function applyTheme()
    compactThemeRegistry()
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

local TAB_ORDER = moduleMgr:GetCategories()
table.sort(TAB_ORDER)
if not table.find(TAB_ORDER, "Theme") then
    table.insert(TAB_ORDER, "Theme")
end

local State = {
    Theme = {Accent = Theme.Accent},
    LastUpdate = "19.01.2026",
    User = {
        Email = "example@gmail.com",
        SubDate = "10.12.2029",
        Role = "Beta",
    }
}

local dim = mk("Frame", {
    Name="Dim",
    BackgroundColor3=Color3.fromRGB(0,0,0),
    BackgroundTransparency=0.55,
    Size=UDim2.fromScale(1,1),
    Visible=true,
}, screenGui)
dim.ZIndex = 1
dim.Active = true
dim.Selectable = true

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
    Active = true,
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

    Active = true, -- ДОБАВИТЬ ЭТО
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


local function clearSettingsUI()
    disconnectSettingsConns()
    for _, c in ipairs(settingsContainer:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local function closeSettings()
    settingsPane.Visible = false
    settingsCloseOverlay.Visible = false
    settingsCloseOverlay.Active = false
    currentSettings = nil
    clearSettingsUI()
end

settingsCloseBtn.MouseButton1Click:Connect(closeSettings)

settingsPane.ZIndex = content.ZIndex + 10
settingsCloseOverlay.ZIndex = settingsPane.ZIndex - 1

settingsCloseOverlay.MouseButton1Down:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    local panePos = settingsPane.AbsolutePosition
    local paneSize = settingsPane.AbsoluteSize

    local isInside = mousePos.X >= panePos.X and mousePos.X <= (panePos.X + paneSize.X) and
            mousePos.Y >= (panePos.Y + 36) and mousePos.Y <= (panePos.Y + paneSize.Y + 36)

    if isInside then
        return
    end

    closeSettings()
end)

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

local UIRefreshBind = {}
local activeBindTarget = nil
local BindMap = {} -- key -> {tab=, module=}
local function bindKey(b)
    if not b then return nil end
    return ("%s:%s"):format(b.kind, b.code.Name)
end

local function rebuildBindMap()
    BindMap = {}
    for _, tabName in ipairs(moduleMgr:GetCategories()) do
        local defs = moduleMgr:GetModuleDefs(tabName)
        for _, def in ipairs(defs) do
            local st = moduleMgr:GetState(tabName, def.Name)
            if st and st.Bind then
                local k = bindKey(st.Bind)
                if k then BindMap[k] = {tab=tabName, module=def.Name} end
            end
        end
    end
end

rebuildBindMap()

local function setBind(tab, moduleName, bind)
    moduleMgr:SetBind(tab, moduleName, bind)
    rebuildBindMap()
    local rf = UIRefreshBind[tab] and UIRefreshBind[tab][moduleName]
    if rf then rf() end
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

    local tgl, _tglRoot = createMiniToggle(holder)
    local v = moduleMgr:GetSetting(tab, moduleName, sDef.Name)
    tgl:Set(v == true)
    tgl.OnChanged = function(v)
        moduleMgr:SetSetting(tab, moduleName, sDef.Name, v)
    end
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
        moduleMgr:SetSetting(tab, moduleName, sDef.Name, v)
        valLabel.Text = tostring(v)
        local denom = (sDef.Max - sDef.Min)
        local alpha = (denom == 0) and 0 or ((v - sDef.Min) / denom)

        fill.Size = UDim2.new(alpha,0,1,0)
        knob.Position = UDim2.new(alpha,0,0.5,0)
    end

    local function setUI(v)
        local step = sDef.Step or 1
        v = math.clamp(tonumber(v) or sDef.Min, sDef.Min, sDef.Max)
        v = math.floor((v - sDef.Min)/step + 0.5)*step + sDef.Min

        valLabel.Text = tostring(v)
        local denom = (sDef.Max - sDef.Min)
        local alpha = (denom == 0) and 0 or ((v - sDef.Min) / denom)

        fill.Size = UDim2.new(alpha,0,1,0)
        knob.Position = UDim2.new(alpha,0,0.5,0)
    end

    local initial = moduleMgr:GetSetting(tab, moduleName, sDef.Name)
    setUI(initial)

    --setValue(moduleMgr:GetSetting(tab, moduleName, sDef.Name))

    local dragging = false
    local function updateFromX(x)
        local abs = bar.AbsolutePosition.X
        local w = bar.AbsoluteSize.X
        if w <= 0 then return end
        local a = clamp01((x - abs) / w)
        setValue(sDef.Min + a*(sDef.Max - sDef.Min))
    end

    trackConn(bar.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(i.Position.X)
            tween(knob, 0.12, {Size = UDim2.fromOffset(16,16)})
        end
    end))
    trackConn(bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            tween(knob, 0.12, {Size = UDim2.fromOffset(14,14)})
        end
    end))

    trackConn(UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(i.Position.X)
        end
    end))
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

    local values = moduleMgr:GetSetting(tab, moduleName, sDef.Name)
    if type(values) ~= "table" then values = {} end

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
            moduleMgr:SetSetting(tab, moduleName, sDef.Name, values)
            render()
        end)

        render()
    end

    local keys = {}
    local defaults = sDef.Default or {}
    for k in pairs(defaults) do table.insert(keys, k) end
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
        Text=tostring(moduleMgr:GetSetting(tab, moduleName, sDef.Name) or ""),
        ClearTextOnFocus=false,
        Font=Enum.Font.GothamMedium,
        TextSize=12,
        TextColor3=Theme.Text,
        PlaceholderText="Введите текст...",
    }, row)
    addCorner(box, 8)
    addStroke(box, 0.35)

    box.FocusLost:Connect(function()
        moduleMgr:SetSetting(tab, moduleName, sDef.Name, box.Text)
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
    if #options == 0 then return end
    local current = moduleMgr:GetSetting(tab, moduleName, sDef.Name)
    local idx = table.find(options, current) or 1

    local function refreshUI()
        mid.Text = tostring(options[idx])
    end

    local function commit()
        moduleMgr:SetSetting(tab, moduleName, sDef.Name, options[idx])
    end

    refreshUI()
    commit()

    left.MouseButton1Click:Connect(function()
        idx -= 1
        if idx < 1 then idx = #options end
        tween(mid, 0.10, {BackgroundTransparency=0.15})
        refreshUI()
        commit()
        tween(mid, 0.10, {BackgroundTransparency=0})
    end)

    right.MouseButton1Click:Connect(function()
        idx += 1
        if idx > #options then idx = 1 end
        tween(mid, 0.10, {BackgroundTransparency=0.15})
        refreshUI()
        commit()
        tween(mid, 0.10, {BackgroundTransparency=0})
    end)
end

local function renderSettings(tab, moduleName)
    clearSettingsUI()
    settingsPane.Visible = true
    settingsCloseOverlay.Visible = true
    settingsCloseOverlay.Active = true

    currentSettings = {tab = tab, module = moduleName}

    settingsTitle.Text = ("Settings • %s"):format(moduleName)
    --settingsSub.Text = State.Modules[tab][moduleName].Desc

    local st = moduleMgr:GetState(tab, moduleName)
    if not st then return end

    for _, sDef in ipairs(st.Definition.Settings) do
        if sDef.Type == "Boolean" then addBooleanSetting(tab, moduleName, sDef)
        elseif sDef.Type == "Slider" then addSliderSetting(tab, moduleName, sDef)
        elseif sDef.Type == "MultiBoolean" then addMultiBooleanSetting(tab, moduleName, sDef)
        elseif sDef.Type == "String" then addStringSetting(tab, moduleName, sDef)
        elseif sDef.Type == "ModeSetting" then addModeSetting(tab, moduleName, sDef)
        end
    end
end

local UIToggles = {}

local function moduleCard(tabName, mName, desc)
    local st = moduleMgr:GetState(tabName, mName)
    if not st then return function() end end

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
    local tgl, _tglRoot = createMiniToggle(toggleHolder)

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
        local st2 = moduleMgr:GetState(tabName, mName)
        bindLabel.Text = bindToText(st2 and st2.Bind)
    end

    refreshBind()

    tgl:Set(st.Enabled)
    tgl.OnChanged = function(v)
        moduleMgr:SetEnabled(tabName, mName, v)
    end

    UIToggles[tabName] = UIToggles[tabName] or {}
    UIToggles[tabName][mName] = tgl

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

    bindBtn.MouseButton1Down:Connect(function()
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

    UIRefreshBind[tabName] = UIRefreshBind[tabName] or {}
    UIRefreshBind[tabName][mName] = refreshBind
    return refreshBind
end

local tabButtons = {}
local activeTab = nil

local function clearModulesUI()
    disconnectThemeConns()

    for _, c in ipairs(modulesArea:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    for k in pairs(UIRefreshBind) do UIRefreshBind[k] = nil end
    compactThemeRegistry()
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

    trackThemeConn(tile.MouseEnter:Connect(function() setHover(true) end))
    trackThemeConn(tile.MouseLeave:Connect(function() setHover(false) end))

    trackThemeConn(tile.MouseButton1Down:Connect(function()
        tween(tile, 0.08, {Size = UDim2.new(1, 0, 0, 70)})
    end))
    trackThemeConn(tile.MouseButton1Up:Connect(function()
        tween(tile, 0.08, {Size = UDim2.new(1, 0, 0, 72)})
    end))

    trackThemeConn(tile.MouseButton1Click:Connect(onPick))

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

    trackThemeConn(bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(i.Position.X)
            tween(knob, 0.12, {Size = UDim2.fromOffset(16,16)})
        end
    end))
    trackThemeConn(bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            tween(knob, 0.12, {Size = UDim2.fromOffset(14,14)})
        end
    end))

    trackThemeConn(UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(i.Position.X)
        end
    end))

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
    trackThemeConn(presets:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateGridCell))
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

    trackThemeConn(resetBtn.MouseButton1Click:Connect(function()
        local col = Color3.fromRGB(140,200,255)
        applyAccent(col)
        local picked = nil
        for i, it in ipairs(tiles) do
            if it.col == col then picked = i break end
        end
        if picked then setCheckByIndex(picked) else clearChecks() end
    end))

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

    trackThemeConn(applyBtn.MouseEnter:Connect(function() tween(applyBtn, 0.12, {BackgroundColor3 = Theme.Panel2}) end))
    trackThemeConn(applyBtn.MouseLeave:Connect(function() tween(applyBtn, 0.12, {BackgroundColor3 = Theme.Panel}) end))

    local r01, g01, b01 = Theme.Accent.R, Theme.Accent.G, Theme.Accent.B
    local function updatePreview()
        preview.BackgroundColor3 = Color3.new(r01, g01, b01)
    end
    updatePreview()

    makeMiniSlider(customCard, "Red",   r01, function(v) r01 = v; updatePreview() end)
    makeMiniSlider(customCard, "Green", g01, function(v) g01 = v; updatePreview() end)
    makeMiniSlider(customCard, "Blue",  b01, function(v) b01 = v; updatePreview() end)

    trackThemeConn(applyBtn.MouseButton1Click:Connect(function()
        applyAccent(Color3.new(r01, g01, b01))
        clearChecks()
    end))

    trackThemeConn(customJumpBtn.MouseButton1Click:Connect(function()
        local y = customCard.AbsolutePosition.Y - modulesArea.AbsolutePosition.Y + modulesArea.CanvasPosition.Y
        modulesArea.CanvasPosition = Vector2.new(modulesArea.CanvasPosition.X, math.max(0, y))
    end))
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
    UIToggles[tabName] = {} -- сбрасываем карту тумблеров под вкладку

    local defs = moduleMgr:GetModuleDefs(tabName)
    for _, def in ipairs(defs) do
        moduleCard(tabName, def.Name, def.Desc or "")
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

local first = TAB_ORDER[1] or "Theme"
renderTab(first)

moduleMgr.Changed:Connect(function(payload)
    if payload.kind == "Enabled" then
        local tgl = UIToggles[payload.category] and UIToggles[payload.category][payload.moduleName]
        if tgl then
            tgl:Set(payload.value == true)
        end
        return
    end

    if payload.kind == "Bind" then
        rebuildBindMap()
        local rf = UIRefreshBind[payload.category] and UIRefreshBind[payload.category][payload.moduleName]
        if rf then rf() end
        return
    end
end)

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

    local hitBind = inputToBind(input)
    local k = bindKey(hitBind)
    local info = k and BindMap[k]
    if info then
        moduleMgr:Toggle(info.tab, info.module)
        local st2 = moduleMgr:GetState(info.tab, info.module)
        local tgl = UIToggles[info.tab] and UIToggles[info.tab][info.module]
        if tgl and st2 then
            tgl:Set(st2.Enabled)
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

local function toggleUI(state)
    uiVisible = state
    dim.Visible = uiVisible
    main.Visible = uiVisible

    UserInputService.MouseIconEnabled = uiVisible
    UserInputService.MouseBehavior = uiVisible and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        toggleUI(not uiVisible)
    end
end)

toggleUI(true)
applyTheme()
