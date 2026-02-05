local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local screenGui = nil

-- Хранилище для очистки
local elements = {}
local connections = {}

-- Цвета твоего дизайна (Heaven White Style)
local Theme = {
    Panel = Color3.fromRGB(255, 255, 255),
    Stroke = Color3.fromRGB(210, 225, 245),
    Text = Color3.fromRGB(20, 35, 55),
    SubText = Color3.fromRGB(95, 120, 155),
    Accent = Color3.fromRGB(140, 200, 255),
}

-- Внутренние утилиты для создания дизайна
local function create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function addCorner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end

local function addStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function applyDrag(frame)
    local dragging, dragInput, dragStart, startPos
    local conn1 = frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    local conn2 = frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    local conn3 = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    table.insert(connections, conn1)
    table.insert(connections, conn2)
    table.insert(connections, conn3)
end

return {
    Name = "Hud",
    Desc = "Отображение Watermark, StaffList и уведомлений",
    Class = "Visuals",
    Category = "Visuals",

    Settings = {
        { Type = "Boolean", Name = "Watermark", Default = true },
        { Type = "Boolean", Name = "StaffList", Default = true },
        { Type = "Boolean", Name = "Notifications", Default = true },
        { Type = "Boolean", Name = "DiscordAd", Default = true },
    },

    OnEnable = function(ctx)
        local playerGui = player:WaitForChild("PlayerGui")
        screenGui = create("ScreenGui", {Name = "HeavenHud", ResetOnSpawn = false, IgnoreGuiInset = true}, playerGui)
        table.insert(elements, screenGui)

        -- 1. WATERMARK
        if ctx:GetSetting("Watermark") then
            local wm = create("Frame", {
                Name = "Watermark",
                Size = UDim2.fromOffset(200, 34),
                Position = UDim2.fromOffset(20, 20),
                BackgroundColor3 = Theme.Panel,
                Parent = screenGui
            })
            addCorner(wm, 10)
            addStroke(wm)
            applyDrag(wm)

            create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "  HEAVEN  •  " .. player.Name .. "  •  beta",
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = wm
            })

            local line = create("Frame", {
                Size = UDim2.new(0, 3, 0, 16),
                Position = UDim2.fromOffset(8, 9),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Parent = wm
            })
            addCorner(line, 2)
        end

        -- 2. STAFF LIST
        if ctx:GetSetting("StaffList") then
            local sl = create("Frame", {
                Name = "StaffList",
                Size = UDim2.fromOffset(180, 110),
                Position = UDim2.fromOffset(20, 70),
                BackgroundColor3 = Theme.Panel,
                Parent = screenGui
            })
            addCorner(sl, 12)
            addStroke(sl)
            applyDrag(sl)

            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = "Staff Online",
                TextColor3 = Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                Parent = sl
            })

            local listFrame = create("Frame", {
                Position = UDim2.fromOffset(0, 30),
                Size = UDim2.new(1, 0, 1, -30),
                BackgroundTransparency = 1,
                Parent = sl
            })
            create("UIListLayout", {Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center}, listFrame)
            create("UIPadding", {PaddingTop = UDim.new(0, 5)}, listFrame)

            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = "No staff found",
                TextColor3 = Theme.SubText,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                Parent = listFrame
            })
        end

        -- 3. NOTIFICATIONS SYSTEM
        if ctx:GetSetting("Notifications") then
            local notifyArea = create("Frame", {
                Name = "NotifyArea",
                Size = UDim2.new(0, 260, 1, -40),
                Position = UDim2.new(1, -280, 0, 20),
                BackgroundTransparency = 1,
                Parent = screenGui
            })
            create("UIListLayout", {VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8)}, notifyArea)

            -- Внутренняя функция для создания уведомления
            local function spawnNotify(title, msg)
                local n = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 54),
                    BackgroundColor3 = Theme.Panel,
                    ClipsDescendants = true,
                    Parent = notifyArea
                })
                addCorner(n, 10)
                addStroke(n)

                local pad = create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 8)}, n)

                create("TextLabel", {
                    Text = title,
                    Font = Enum.Font.GothamBold,
                    TextSize = 13,
                    TextColor3 = Theme.Accent,
                    Size = UDim2.new(1, 0, 0, 16),
                    TextXAlignment = 0,
                    BackgroundTransparency = 1,
                    Parent = n
                })
                create("TextLabel", {
                    Text = msg,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 11,
                    TextColor3 = Theme.SubText,
                    Position = UDim2.fromOffset(0, 18),
                    Size = UDim2.new(1, 0, 0, 16),
                    TextXAlignment = 0,
                    BackgroundTransparency = 1,
                    Parent = n
                })

                n.Size = UDim2.new(1, 0, 0, 0)
                TweenService:Create(n, TweenInfo.new(0.35), {Size = UDim2.new(1, 0, 0, 54)}):Play()

                task.delay(4, function()
                    local tw = TweenService:Create(n, TweenInfo.new(0.4), {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
                    tw:Play()
                    tw.Completed:Connect(function() n:Destroy() end)
                end)
            end

            spawnNotify("Heaven Hud", "Successfully initialized visuals")
        end

        -- 4. FLOATING AD
        if ctx:GetSetting("DiscordAd") then
            local ad = create("Frame", {
                Size = UDim2.fromOffset(150, 26),
                BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 0.85,
                Parent = screenGui
            })
            addCorner(ad, 8)
            addStroke(ad, Theme.Stroke, 1, 0.5)

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

            local vel = Vector2.new(70, 70)
            local adConn = RunService.RenderStepped:Connect(function(dt)
                if not ad.Parent then return end
                local pos = ad.AbsolutePosition
                local size = ad.AbsoluteSize
                local screen = screenGui.AbsoluteSize

                if pos.X <= 0 or pos.X + size.X >= screen.X then vel = Vector2.new(-vel.X, vel.Y) end
                if pos.Y <= 0 or pos.Y + size.Y >= screen.Y then vel = Vector2.new(vel.X, -vel.Y) end

                ad.Position = UDim2.fromOffset(pos.X + vel.X * dt, pos.Y + vel.Y * dt)
            end)
            table.insert(connections, adConn)
        end
    end,

    OnDisable = function(ctx)
        for _, conn in ipairs(connections) do
            if conn then conn:Disconnect() end
        end
        for _, el in ipairs(elements) do
            if el then el:Destroy() end
        end
        connections = {}
        elements = {}
    end,
}