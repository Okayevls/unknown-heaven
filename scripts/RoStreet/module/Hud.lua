local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Локальные переменные для работы внутри сессии модуля
local screenGui = nil
local connections = {}
local elements = {}

-- [ Внутренние утилиты для соблюдения Heaven Style ] --
local Theme = {
    Panel = Color3.fromRGB(255, 255, 255),
    Stroke = Color3.fromRGB(210, 225, 245),
    Accent = Color3.fromRGB(140, 200, 255),
    Text = Color3.fromRGB(20, 35, 55),
    SubText = Color3.fromRGB(95, 120, 155),
}

local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    table.insert(elements, obj)
    return obj
end

local function applyStyle(obj, radius)
    create("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, obj)
    create("UIStroke", {Color = Theme.Stroke, Thickness = 1}, obj)
end

local function applyDrag(frame)
    local dragging, dragStart, startPos
    table.insert(connections, frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end))
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
end

-- [ Сам Модуль ] --
return {
    Name = "Hud",
    Desc = "Отображает визуальный интерфейс (Watermark, StaffList, Ad)",
    Class = "Visuals",
    Category = "Visuals",

    Settings = {
        { Type = "Boolean", Name = "Watermark", Default = true },
        { Type = "Boolean", Name = "StaffList", Default = true },
        { Type = "Boolean", Name = "DiscordAd", Default = true },
    },

    OnEnable = function(ctx)
        local playerGui = player:WaitForChild("PlayerGui")
        screenGui = create("ScreenGui", { Name = "HeavenHud", ResetOnSpawn = false, IgnoreGuiInset = true }, playerGui)

        -- 1. Watermark
        if ctx:GetSetting("Watermark") then
            local wm = create("Frame", {
                Name = "Watermark",
                Size = UDim2.fromOffset(200, 32),
                Position = UDim2.fromOffset(20, 20),
                BackgroundColor3 = Theme.Panel,
                Parent = screenGui
            })
            applyStyle(wm, 8)
            applyDrag(wm)

            create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "  HEAVEN | " .. player.Name:lower(),
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = wm
            })
        end

        -- 2. Staff List
        if ctx:GetSetting("StaffList") then
            local sl = create("Frame", {
                Name = "StaffList",
                Size = UDim2.fromOffset(170, 100),
                Position = UDim2.fromOffset(20, 65),
                BackgroundColor3 = Theme.Panel,
                Parent = screenGui
            })
            applyStyle(sl, 10)
            applyDrag(sl)

            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Text = "Staff Online",
                TextColor3 = Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                Parent = sl
            })

            local list = create("Frame", {
                Position = UDim2.fromOffset(0, 28),
                Size = UDim2.new(1, 0, 1, -28),
                BackgroundTransparency = 1,
                Parent = sl
            })
            create("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center }, list)

            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = "No staff found",
                TextColor3 = Theme.SubText,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                Parent = list
            })
        end

        -- 3. Floating Discord Ad
        if ctx:GetSetting("DiscordAd") then
            local ad = create("Frame", {
                Size = UDim2.fromOffset(150, 24),
                BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 0.85,
                Parent = screenGui
            })
            applyStyle(ad, 6)

            create("TextLabel", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "discord.gg/heaven",
                TextColor3 = Theme.Text,
                TextTransparency = 0.5,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                Parent = ad
            })

            local vel = Vector2.new(65, 65)
            table.insert(connections, RunService.RenderStepped:Connect(function(dt)
                if not ad.Parent then return end
                local pos = ad.AbsolutePosition
                local size = ad.AbsoluteSize
                local screen = screenGui.AbsoluteSize

                if pos.X <= 0 or pos.X + size.X >= screen.X then vel = Vector2.new(-vel.X, vel.Y) end
                if pos.Y <= 0 or pos.Y + size.Y >= screen.Y then vel = Vector2.new(vel.X, -vel.Y) end

                ad.Position = UDim2.fromOffset(pos.X + vel.X * dt, pos.Y + vel.Y * dt)
            end))
        end
    end,

    OnDisable = function(ctx)
        -- Отключаем все RenderStepped и Dragging события
        for _, conn in ipairs(connections) do
            if conn then conn:Disconnect() end
        end
        connections = {}

        -- Удаляем все созданные UI элементы
        for _, el in ipairs(elements) do
            if el then el:Destroy() end
        end
        elements = {}

        screenGui = nil
    end,
}