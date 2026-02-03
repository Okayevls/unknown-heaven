local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local espFolder = Instance.new("Folder")
espFolder.Name = "HeavenESP_Global"
espFolder.Parent = CoreGui

local espData = {}
local _connections = {}

-- Настройки визуализации
local ESP_SETTINGS = {
    Color = Color3.fromRGB(255, 255, 255),
    OutlineTransparency = 0,
    FillTransparency = 1,
}

local function updateOriginalNames(hide)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.DisplayDistanceType = hide and Enum.HumanoidDisplayDistanceType.None
                        or Enum.HumanoidDisplayDistanceType.Viewer
            end
        end
    end
end

local function clearPlrESP(plr)
    if espData[plr] then
        for _, obj in ipairs(espData[plr]) do
            if typeof(obj) == "Instance" then obj:Destroy() end
        end
        espData[plr] = nil
    end
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

-- Функция создания объектов
local function createESP(plr)
    local char = plr.Character
    if not char then return end

    -- Ждем корень, но не вечно
    local root = char:WaitForChild("HumanoidRootPart", 5)
    if not root then return end
    local head = char:FindFirstChild("Head") or root

    local highlight = Instance.new("Highlight")
    highlight.Name = plr.Name .. "_Highlight"
    highlight.Adornee = char
    highlight.FillTransparency = ESP_SETTINGS.FillTransparency
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
    label.BackgroundColor3 = Color3.new(0,0,0)
    label.TextColor3 = ESP_SETTINGS.Color
    label.Font = Enum.Font.Gotham
    label.Text = getPlrName(plr, "Display") -- Временное имя
    label.BorderSizePixel = 0
    label.Parent = billboard

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.PaddingTop = UDim.new(0, 2)
    padding.PaddingBottom = UDim.new(0, 2)
    padding.Parent = label

    espData[plr] = {highlight, billboard, char, label}
end

return {
    Name = "ESP",
    Desc = "Подсветка игроков без ограничения дистанции",
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
        -- Функция обработки игрока
        local function handlePlr(plr)
            if plr == LocalPlayer then return end

            -- Очищаем старое если было
            clearPlrESP(plr)

            -- Слушаем респавн
            local conn = plr.CharacterAdded:Connect(function(char)
                task.wait(0.5) -- Даем время персонажу прогрузиться в Workspace
                clearPlrESP(plr)
                createESP(plr)
            end)
            table.insert(_connections, conn)

            -- Если уже в игре
            if plr.Character then
                createESP(plr)
            end
        end

        -- Инициализация всех
        for _, plr in ipairs(Players:GetPlayers()) do
            handlePlr(plr)
        end

        -- Новые игроки
        table.insert(_connections, Players.PlayerAdded:Connect(handlePlr))

        -- Удаление при выходе
        table.insert(_connections, Players.PlayerRemoving:Connect(function(plr)
            clearPlrESP(plr)
        end))

        -- Основной цикл обновления (RenderStepped)
        table.insert(_connections, RunService.RenderStepped:Connect(function()
            local showBox = ctx:GetSetting("Show Box")
            local showName = ctx:GetSetting("Show Name")
            local showBg = ctx:GetSetting("Show Background")
            local hideNames = ctx:GetSetting("Hide Original Names")
            local nameMode = ctx:GetSetting("Name Mode")
            local textSize = ctx:GetSetting("Text Size")

            updateOriginalNames(hideNames)

            for plr, data in pairs(espData) do
                -- Если игрок вышел или персонаж удален из игры вообще
                if not plr or not plr.Parent then
                    clearPlrESP(plr)
                    continue
                end

                local highlight, billboard, char, label = data[1], data[2], data[3], data[4]

                -- ПРОВЕРКА НА РЕСПАВН (ФИКС ПРОПАДАНИЯ)
                if plr.Character and plr.Character ~= char then
                    clearPlrESP(plr)
                    createESP(plr)
                    continue
                end

                if char and char.Parent and char:FindFirstChild("HumanoidRootPart") then
                    -- Состояние Box
                    highlight.Enabled = showBox
                    highlight.OutlineTransparency = showBox and 0 or 1

                    -- Состояние Имени
                    billboard.Enabled = showName
                    label.Visible = showName
                    label.TextSize = textSize
                    label.Text = getPlrName(plr, nameMode)
                    label.BackgroundTransparency = showBg and 0.45 or 1
                else
                    highlight.Enabled = false
                    billboard.Enabled = false
                end
            end
        end))
    end,

    OnDisable = function(ctx)
        -- Отключаем все события (Events)
        for _, conn in ipairs(_connections) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
            end
        end
        _connections = {}

        -- Возвращаем стандартные ники
        updateOriginalNames(false)

        -- Чистим объекты из игры
        for plr, _ in pairs(espData) do
            clearPlrESP(plr)
        end
        espData = {}
    end,
}