local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local espFolder = Instance.new("Folder")
espFolder.Name = "E4PHREVN"
espFolder.Parent = CoreGui

local espData = {}
local _connections = {}
local _charCons = {}

local ESP_SETTINGS = {
    Color = Color3.fromRGB(255, 255, 255),
}

local originalNameType = {}

local function updateOriginalNames(hide)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if hide then
                    if originalNameType[hum] == nil then
                        originalNameType[hum] = hum.DisplayDistanceType
                    end
                    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                else
                    if originalNameType[hum] ~= nil then
                        hum.DisplayDistanceType = originalNameType[hum]
                        originalNameType[hum] = nil
                    end
                end
            end
        end
    end
end

local function disconnectCharCons(plr)
    local t = _charCons[plr]
    if not t then return end
    for _, c in ipairs(t) do
        if typeof(c) == "RBXScriptConnection" then
            c:Disconnect()
        end
    end
    _charCons[plr] = nil
end

local function clearPlrESP(plr)
    local data = espData[plr]
    if not data then return end

    if data.Highlight and data.Highlight.Parent then
        data.Highlight:Destroy()
    end
    if data.Billboard and data.Billboard.Parent then
        data.Billboard:Destroy()
    end

    espData[plr] = nil
end

local function getPlrName(plr, mode)
    if mode == "Display" then
        return plr.DisplayName
    elseif mode == "Nickname" then
        return plr.Name
    else
        return string.format("%s (@%s)", plr.DisplayName, plr.Name)
    end
end

local function createESP(plr)
    if plr == LocalPlayer then return end
    local char = plr.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local head = char:FindFirstChild("Head") or root
    local hum = char:FindFirstChildOfClass("Humanoid")

    local highlight = Instance.new("Highlight")
    highlight.Name = plr.Name .. "_Highlight"
    highlight.Adornee = char
    highlight.FillTransparency = 1
    highlight.OutlineColor = ESP_SETTINGS.Color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = espFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = plr.Name .. "_Billboard"
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(250, 70)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.fromScale(0.5, 0.5)
    label.AutomaticSize = Enum.AutomaticSize.XY
    label.BackgroundTransparency = 1
    label.BackgroundColor3 = Color3.new(0, 0, 0)
    label.TextColor3 = ESP_SETTINGS.Color
    label.Font = Enum.Font.Gotham
    label.BorderSizePixel = 0
    label.Parent = billboard

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.PaddingTop = UDim.new(0, 2)
    padding.PaddingBottom = UDim.new(0, 2)
    padding.Parent = label

    espData[plr] = {
        Highlight = highlight,
        Billboard = billboard,
        Label = label,
        Character = char,
        Humanoid = hum,
    }
end

local function ensureESP(plr)
    if plr == LocalPlayer then return end

    if not plr.Character or not plr.Character.Parent then
        clearPlrESP(plr)
        return
    end

    local data = espData[plr]
    if not data then
        createESP(plr)
        return
    end

    if data.Character ~= plr.Character then
        clearPlrESP(plr)
        createESP(plr)
        return
    end

    if (not data.Highlight or not data.Highlight.Parent) or (not data.Billboard or not data.Billboard.Parent) then
        clearPlrESP(plr)
        createESP(plr)
        return
    end
end

local function hookPlayer(plr)
    if plr == LocalPlayer then return end

    disconnectCharCons(plr)
    _charCons[plr] = {}

    table.insert(_charCons[plr], plr.CharacterAdded:Connect(function()
        task.defer(function()
            ensureESP(plr)
        end)
    end))

    table.insert(_charCons[plr], plr.CharacterRemoving:Connect(function()
        clearPlrESP(plr)
    end))

    if plr.Character then
        ensureESP(plr)
    end
end

return {
    Name = "ESP",
    Desc = "Подсветка других игроков",
    Class = "Visuals",
    Category = "Visuals",

    Settings = {
        { Type = "Boolean", Name = "Show Box", Default = false },
        { Type = "Boolean", Name = "Show Name", Default = false },
        { Type = "Boolean", Name = "Show Background", Default = false },
        { Type = "Boolean", Name = "Hide Original Names", Default = false },
        { Type = "ModeSetting", Name = "Name Mode", Default = "Display", Options = {"Display", "Nickname", "Both"} },
        { Type = "Slider", Name = "Text Size", Default = 14, Min = 8, Max = 32, Step = 1 },
    },

    OnEnable = function(ctx)
        for plr, _ in pairs(espData) do
            clearPlrESP(plr)
        end
        espData = {}

        for _, plr in ipairs(Players:GetPlayers()) do
            hookPlayer(plr)
        end

        table.insert(_connections, Players.PlayerAdded:Connect(function(plr)
            hookPlayer(plr)
        end))

        table.insert(_connections, Players.PlayerRemoving:Connect(function(plr)
            disconnectCharCons(plr)
            clearPlrESP(plr)
        end))

        table.insert(_connections, RunService.RenderStepped:Connect(function()
            local showBox = ctx:GetSetting("Show Box")
            local showName = ctx:GetSetting("Show Name")
            local showBg = ctx:GetSetting("Show Background")
            local hideNames = ctx:GetSetting("Hide Original Names")
            local nameMode = ctx:GetSetting("Name Mode")
            local textSize = ctx:GetSetting("Text Size")

            updateOriginalNames(hideNames)

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end

                ensureESP(plr)

                local data = espData[plr]
                if not data then continue end

                local char = data.Character
                if not (char and char.Parent) then
                    data.Highlight.Enabled = false
                    data.Billboard.Enabled = false
                    continue
                end

                if not char:FindFirstChild("HumanoidRootPart") then
                    data.Highlight.Enabled = false
                    data.Billboard.Enabled = false
                    continue
                end

                data.Highlight.Enabled = showBox
                data.Highlight.OutlineTransparency = showBox and 0 or 1

                data.Billboard.Enabled = showName
                data.Label.Visible = showName
                data.Label.TextSize = textSize
                data.Label.Text = getPlrName(plr, nameMode)
                data.Label.BackgroundTransparency = showBg and 0.45 or 1
            end
        end))
    end,

    OnDisable = function(ctx)
        for _, conn in ipairs(_connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        _connections = {}

        for plr, _ in pairs(_charCons) do
            disconnectCharCons(plr)
        end

        updateOriginalNames(false)
        for hum, oldType in pairs(originalNameType) do
            if hum and hum.Parent then
                hum.DisplayDistanceType = oldType
            end
            originalNameType[hum] = nil
        end

        for plr, _ in pairs(espData) do
            clearPlrESP(plr)
        end
        espData = {}
    end,
}
