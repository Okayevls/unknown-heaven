local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Локальные хранилища для очистки при OnDisable
local HudElements = {}
local HudConnections = {}

-- Вспомогательная функция для Dragging (перетаскивания)
local function enableDragging(frame)
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

    table.insert(HudConnections, conn1)
    table.insert(HudConnections, conn2)
    table.insert(HudConnections, conn3)
end

return {
    Name = "Hud",
    Desc = "Показывает важную информацию и уведомления",
    Class = "Visuals",
    Category = "Visuals",

    Settings = {
        { Type = "Boolean", Name = "Watermark", Default = true },
        { Type = "Boolean", Name = "StaffList", Default = true },
        { Type = "Boolean", Name = "Notifications", Default = true },
        { Type = "Boolean", Name = "DiscordAd", Default = true },
    },

    OnEnable = function(ctx)
        -- Очистка на всякий случай
        HudElements = {}
        HudConnections = {}

        -- Доступ к глобальным функциям дизайна из твоего UI
        -- Предполагаем, что Theme, mk, addCorner, addStroke доступны в окружении

        -- 1. WaterMark
        if ctx:GetSetting("Watermark") then
            local wm = mk("Frame", {
                Name = "Watermark",
                Parent = screenGui,
                Size = UDim2.fromOffset(200, 34),
                Position = UDim2.fromOffset(15, 15),
                BackgroundColor3 = Theme.Panel,
            })
            addCorner(wm, 10)
            addStroke(wm, 0.1)
            enableDragging(wm)

            mk("TextLabel", {
                Parent = wm,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "  HEAVEN  •  " .. player.Name .. "  •  beta",
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local accentLine = mk("Frame", {
                Parent = wm,
                Size = UDim2.new(0, 3, 0, 16),
                Position = UDim2.fromOffset(6, 9),
                BackgroundColor3 = Theme.Accent,
            })
            addCorner(accentLine, 2)

            table.insert(HudElements, wm)
        end

        -- 2. Staff List
        if ctx:GetSetting("StaffList") then
            local sl = mk("Frame", {
                Name = "StaffList",
                Parent = screenGui,
                Size = UDim2.fromOffset(180, 100),
                Position = UDim2.fromOffset(15, 60),
                BackgroundColor3 = Theme.Panel,
            })
            addCorner(sl, 12)
            addStroke(sl, 0.1)
            enableDragging(sl)

            mk("TextLabel", {
                Parent = sl,
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Text = "Staff Online",
                TextColor3 = Theme.Accent,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
            })

            local container = mk("Frame", {
                Parent = sl,
                Position = UDim2.fromOffset(0, 28),
                Size = UDim2.new(1, 0, 1, -28),
                BackgroundTransparency = 1,
            })
            addList(container, 4)
            addPadding(container, 8)

            -- Пример вывода
            mk("TextLabel", {
                Parent = container,
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = "No staff in server",
                TextColor3 = Theme.SubText,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
            })

            table.insert(HudElements, sl)
        end

        -- 3. Notifications
        if ctx:GetSetting("Notifications") then
            local notifyArea = mk("Frame", {
                Parent = screenGui,
                Size = UDim2.new(0, 260, 1, -40),
                Position = UDim2.new(1, -275, 0, 20),
                BackgroundTransparency = 1,
            })
            local layout = addList(notifyArea, 8)
            layout.VerticalAlignment = Enum.VerticalAlignment.Bottom

            table.insert(HudElements, notifyArea)

            -- Глобальная функция уведомлений (чтобы другие модули могли звать)
            _G.HeavenNotify = function(title, text, duration)
                if not notifyArea or not notifyArea.Parent then return end

                local n = mk("Frame", {
                    Parent = notifyArea,
                    Size = UDim2.new(1, 0, 0, 54),
                    BackgroundColor3 = Theme.Panel,
                    ClipsDescendants = true,
                })
                addCorner(n, 10)
                addStroke(n, 0.1)

                local c = mk("Frame", { Parent = n, Size = UDim2.fromScale(1,1), BackgroundTransparency = 1 })
                addPadding(c, 10)

                mk("TextLabel", { Parent = c, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Accent, Size = UDim2.new(1,0,0,16), TextXAlignment = 0, BackgroundTransparency = 1 })
                mk("TextLabel", { Parent = c, Text = text, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.SubText, Position = UDim2.fromOffset(0,18), Size = UDim2.new(1,0,0,16), TextXAlignment = 0, BackgroundTransparency = 1 })

                -- Анимация появления
                n.Size = UDim2.new(1, 0, 0, 0)
                tween(n, 0.3, {Size = UDim2.new(1, 0, 0, 54)})

                task.delay(duration or 4, function()
                    local t = tween(n, 0.4, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
                    t.Completed:Connect(function() n:Destroy() end)
                end)
            end
        end

        -- 4. Floating Discord Ad
        if ctx:GetSetting("DiscordAd") then
            local ad = mk("Frame", {
                Parent = screenGui,
                Size = UDim2.fromOffset(160, 26),
                BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 0.85,
            })
            addCorner(ad, 8)
            addStroke(ad, 0.6)

            mk("TextLabel", {
                Parent = ad,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "discord.gg/heaven",
                TextColor3 = Theme.Text,
                TextTransparency = 0.5,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
            })

            local vel = Vector2.new(80, 80)
            local adConn = RunService.RenderStepped:Connect(function(dt)
                local pos = ad.AbsolutePosition
                local size = ad.AbsoluteSize
                local screen = screenGui.AbsoluteSize

                if pos.X <= 0 or pos.X + size.X >= screen.X then vel = Vector2.new(-vel.X, vel.Y) end
                if pos.Y <= 0 or pos.Y + size.Y >= screen.Y then vel = Vector2.new(vel.X, -vel.Y) end

                ad.Position = UDim2.fromOffset(pos.X + vel.X * dt, pos.Y + vel.Y * dt)
            end)

            table.insert(HudConnections, adConn)
            table.insert(HudElements, ad)
        end
    end,

    OnDisable = function(ctx)
        -- Удаление всех UI элементов
        for _, el in pairs(HudElements) do
            if el then el:Destroy() end
        end
        -- Отключение соединений
        for _, conn in pairs(HudConnections) do
            if conn then conn:Disconnect() end
        end

        HudElements = {}
        HudConnections = {}
        _G.HeavenNotify = nil
    end,
}