local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Папка для ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "HeavenESP_Global"
espFolder.Parent = CoreGui

local espData = {}         -- [player] = data
local _connections = {}    -- общие коннекты
local _charCons = {}       -- [player] = коннекты персонажа

local ESP_SETTINGS = {
    Color = Color3.fromRGB(255, 255, 255),
}

-- Восстановление исходного DisplayDistanceType
local originalNameType = {} -- [Humanoid] = Enum.HumanoidDisplayDistanceType

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

    -- НЕ трогаем data.Character!
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

-- =========================
-- АНИМАЦИИ ТЕКСТА
-- =========================

local function cancelTweens(data)
    if data._textTween then pcall(function() data._textTween:Cancel() end) end
    if data._sizeTween then pcall(function() data._sizeTween:Cancel() end) end
    data._textTween, data._sizeTween = nil, nil
end

local function setLabelInstant(label, text, color, bgOn, textSize)
    label.Text = text
    label.TextColor3 = color
    label.TextSize = textSize
    label.BackgroundTransparency = bgOn and 0.45 or 1
end

local function animateLabel(data, text, color, bgOn, textSize, holdSeconds, tokenKey)
    local label = data.Label
    if not (label and label.Parent) then return end

    -- токен, чтобы старые анимации не перебивали новые
    data._animToken = (data._animToken or 0) + 1
    local myToken = data._animToken
    if tokenKey then
        data[tokenKey] = myToken
    end

    cancelTweens(data)

    -- стартовые параметры (fade + pop)
    label.TextTransparency = 1
    label.TextStrokeTransparency = 1
    label.Size = UDim2.fromScale(1, 1) -- для совместимости
    setLabelInstant(label, text, color, bgOn, textSize)

    local startSize = label.TextSize
    label.TextSize = math.max(8, math.floor(startSize * 0.85))

    local tInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    data._textTween = TweenService:Create(label, tInfo, {
        TextTransparency = 0,
        TextStrokeTransparency = 0.3,
    })
    data._sizeTween = TweenService:Create(label, tInfo, {
        TextSize = startSize,
    })

    data._textTween:Play()
    data._sizeTween:Play()

    if holdSeconds and holdSeconds > 0 then
        task.delay(holdSeconds, function()
            -- если за время ожидания пришла новая анимация — выходим
            if not data or data._animToken ~= myToken then return end

            -- плавный fade-out (не всегда нужно, но красиво)
            cancelTweens(data)
            local outInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            data._textTween = TweenService:Create(label, outInfo, {
                TextTransparency = 1,
                TextStrokeTransparency = 1,
            })
            data._textTween:Play()
        end)
    end
end

-- =========================
-- СОЗДАНИЕ ESP
-- =========================

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
    label.Font = Enum.Font.GothamBold
    label.BorderSizePixel = 0
    label.TextStrokeTransparency = 0.3
    label.TextTransparency = 0
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

        -- состояние
        Status = "Name", -- "Name" | "Death" | "Respawned"
        _animToken = 0,
        _textTween = nil,
        _sizeTween = nil,
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

-- =========================
-- ХУКИ НА СМЕРТЬ/РЕСПАВН
-- =========================

local function hookDeath(plr, hum)
    local data = espData[plr]
    if not data or not hum then return end

    -- Если у нас уже есть коннект на смерть — не делаем второй
    if data._diedConn and typeof(data._diedConn) == "RBXScriptConnection" then
        data._diedConn:Disconnect()
    end

    data._diedConn = hum.Died:Connect(function()
        local d = espData[plr]
        if not d then return end
        d.Status = "Death"

        -- Показываем Death только если включен Show Name (иначе всё равно не видно)
        -- Но текст выставим — когда включат, будет актуально
        animateLabel(
                d,
                "Death",
                Color3.fromRGB(255, 80, 80),
                true,
                (d._lastTextSize or 14),
                0, -- не fade-out автоматически, пусть держится до респавна
                "_deathToken"
        )
    end)
end

local function hookPlayer(plr)
    if plr == LocalPlayer then return end

    disconnectCharCons(plr)
    _charCons[plr] = {}

    table.insert(_charCons[plr], plr.CharacterAdded:Connect(function(char)
        task.defer(function()
            ensureESP(plr)
            local data = espData[plr]
            if not data then return end

            data.Character = char
            data.Humanoid = char:FindFirstChildOfClass("Humanoid")

            if data.Humanoid then
                hookDeath(plr, data.Humanoid)
            end

            -- Анимация Respawned
            data.Status = "Respawned"
            animateLabel(
                    data,
                    "Respawned",
                    Color3.fromRGB(80, 255, 120),
                    true,
                    (data._lastTextSize or 14),
                    0,
                    "_respawnToken"
            )

            -- Через 1.1 сек плавно вернём ник
            task.delay(1.1, function()
                local d = espData[plr]
                if not d then return end
                -- если за это время снова умер/пошла другая анимация — не трогаем
                if d.Status ~= "Respawned" then return end
                d.Status = "Name"
                -- сам ник выставится в RenderStepped, но мы ещё сделаем плавный “переход”
                animateLabel(
                        d,
                        d._lastNameText or plr.DisplayName,
                        ESP_SETTINGS.Color,
                        false,
                        (d._lastTextSize or 14),
                        0,
                        "_nameToken"
                )
            end)
        end)
    end))

    table.insert(_charCons[plr], plr.CharacterRemoving:Connect(function()
        -- на удаление персонажа чистим только ESP (не персонаж)
        clearPlrESP(plr)
    end))

    if plr.Character then
        ensureESP(plr)
        local data = espData[plr]
        if data and data.Humanoid then
            hookDeath(plr, data.Humanoid)
        end
    end
end

-- =========================
-- МОДУЛЬ
-- =========================

return {
    Name = "ESP",
    Desc = "Подсветка игроков с плавными анимациями Death/Respawned",
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
        -- чистка на всякий
        for plr, _ in pairs(espData) do clearPlrESP(plr) end
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
                if not (char and char.Parent and char:FindFirstChild("HumanoidRootPart")) then
                    data.Highlight.Enabled = false
                    data.Billboard.Enabled = false
                    continue
                end

                data.Highlight.Enabled = showBox
                data.Highlight.OutlineTransparency = showBox and 0 or 1

                data.Billboard.Enabled = showName
                data.Label.Visible = showName

                -- сохраняем последние значения (для анимаций)
                data._lastTextSize = textSize
                data.Label.BackgroundTransparency = showBg and 0.45 or 1

                -- Если сейчас статус Death/Respawned — НЕ перетираем текст ником
                if data.Status == "Death" then
                    -- просто держим Death (и цвет), но подстрой размер/фон
                    data.Label.TextSize = textSize
                elseif data.Status == "Respawned" then
                    data.Label.TextSize = textSize
                else
                    -- обычный режим: ник
                    local nm = getPlrName(plr, nameMode)
                    data._lastNameText = nm
                    data.Label.TextColor3 = ESP_SETTINGS.Color
                    data.Label.Text = nm
                    data.Label.TextSize = textSize
                    data.Label.TextTransparency = 0
                    data.Label.TextStrokeTransparency = 0.3
                end
            end
        end))
    end,

    OnDisable = function(ctx)
        for _, conn in ipairs(_connections) do
            if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
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
