local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local espFolder = Instance.new("Folder")
espFolder.Name = "Heaven_ESP_System"
espFolder.Parent = CoreGui

local espData = {}
local _connections = {}

-- Функция возврата стандартных ников в нормальное состояние
local function restoreNames()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                -- Устанавливаем в Viewer (стандарт), чтобы они появились снова
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
            end
        end
    end
end

local function clearPlrESP(plr)
    if espData[plr] then
        for _, obj in ipairs(espData[plr]) do
            if typeof(obj) == "Instance" then
                obj:Destroy()
            end
        end
        espData[plr] = nil
    end
end

local function createESP(plr)
    if not plr.Character then return end
    local char = plr.Character
    local root = char:WaitForChild("HumanoidRootPart", 3)
    if not root then return end
    local head = char:FindFirstChild("Head") or root

    local highlight = Instance.new("Highlight")
    highlight.Adornee = char
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = espFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = UDim2.fromOffset(200, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.AutomaticSize = Enum.AutomaticSize.XY
    label.BackgroundTransparency = 1
    label.BackgroundColor3 = Color3.new(0,0,0)
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.GothamBold
    label.BorderSizePixel = 0
    label.Parent = billboard

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = label

    espData[plr] = {highlight, billboard, char, label}
end

return {
    Name = "ESP",
    Desc = "Подсветка игроков (Исправлено пропадание)",
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
        -- 1. Сброс таблиц
        espData = {}
        _connections = {}

        -- 2. Сразу создаем для всех
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then createESP(plr) end
        end

        -- 3. Основной цикл
        table.insert(_connections, RunService.RenderStepped:Connect(function()
            local showBox = ctx:GetSetting("Show Box")
            local showName = ctx:GetSetting("Show Name")
            local showBg = ctx:GetSetting("Show Background")
            local hideNames = ctx:GetSetting("Hide Original Names")
            local nameMode = ctx:GetSetting("Name Mode")
            local textSize = ctx:GetSetting("Text Size")

            -- Управление оригинальными никами
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.DisplayDistanceType = hideNames and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer
                    end
                end
            end

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end
                local data = espData[plr]

                -- Пересоздание если персонаж обновился
                if not data or data[3] ~= plr.Character or not data[3].Parent then
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        clearPlrESP(plr)
                        createESP(plr)
                    end
                    continue
                end

                data[1].Enabled = showBox
                data[2].Enabled = showName
                data[4].TextSize = textSize
                data[4].BackgroundTransparency = showBg and 0.45 or 1

                -- Динамическое имя
                if nameMode == "Display" then data[4].Text = plr.DisplayName
                elseif nameMode == "Nickname" then data[4].Text = plr.Name
                else data[4].Text = plr.DisplayName .. " (@" .. plr.Name .. ")" end
            end
        end))

        table.insert(_connections, Players.PlayerRemoving:Connect(clearPlrESP))
    end,

    OnDisable = function(ctx)
        -- Отключаем события
        for _, conn in ipairs(_connections) do conn:Disconnect() end
        _connections = {}

        -- ВОЗВРАЩАЕМ ОРИГИНАЛЬНЫЕ НИКИ
        restoreNames()

        -- ПОЛНОЕ УДАЛЕНИЕ ОБЪЕКТОВ
        for plr, _ in pairs(espData) do clearPlrESP(plr) end
        espData = {}
        espFolder:ClearAllChildren()
    end,
}