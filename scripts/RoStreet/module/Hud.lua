local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local screenGui = nil

local elements = {}
local connections = {}

local Theme = {
    Panel = Color3.fromRGB(255, 255, 255),
    Stroke = Color3.fromRGB(210, 225, 245),
    Accent = Color3.fromRGB(140, 200, 255),
    Text = Color3.fromRGB(20, 35, 55),
    SubText = Color3.fromRGB(95, 120, 155),
}

local TOP_OFFSET = 45

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

return {
    Name = "Hud",
    Desc = "Fixed Hud: Centered WM, Higher Notify, Optimized Ad",
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
        screenGui = create("ScreenGui", {
            Name = "HeavenHud",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 100
        }, playerGui)

        -- 1. WATERMARK (Центр сверху)
        if ctx:GetSetting("Watermark") then
            local wm = create("Frame", {
                Name = "Watermark",
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.fromOffset(220, 32),
                Position = UDim2.new(0.5, 0, 0, TOP_OFFSET),
                BackgroundColor3 = Theme.Panel,
                Parent = screenGui
            })
            applyStyle(wm, 8)
            applyDrag(wm)

            create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "HEAVEN | " .. player.Name:lower() .. " | beta",
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                Parent = wm
            })
        end

        -- 2. STAFF LIST
        if ctx:GetSetting("StaffList") then
            local sl = create("Frame", {
                Name = "StaffList",
                Size = UDim2.fromOffset(170, 100),
                Position = UDim2.fromOffset(20, TOP_OFFSET),
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

        -- 3. NOTIFICATIONS (Выше, чем было)
        if ctx:GetSetting("Notifications") then
            local notifyArea = create("Frame", {
                Name = "NotifyArea",
                Size = UDim2.new(0, 260, 0.7, 0),
                -- Сместили вверх, чтобы не липло к низу
                Position = UDim2.new(1, -280, 0.15, 0),
                BackgroundTransparency = 1,
                Parent = screenGui
            })
            create("UIListLayout", {
                VerticalAlignment = Enum.VerticalAlignment.Top, -- Теперь уведомления идут сверху вниз
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            }, notifyArea)

            local function spawnNotify(title, msg)
                local n = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 54),
                    BackgroundColor3 = Theme.Panel,
                    ClipsDescendants = true,
                    Parent = notifyArea
                })
                applyStyle(n, 10)

                create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 8)}, n)

                create("TextLabel", {
                    Text = title, Font = Enum.Font.GothamBold, TextSize = 13,
                    TextColor3 = Theme.Accent, Size = UDim2.new(1, 0, 0, 16),
                    TextXAlignment = 0, BackgroundTransparency = 1, Parent = n
                })
                create("TextLabel", {
                    Text = msg, Font = Enum.Font.GothamMedium, TextSize = 11,
                    TextColor3 = Theme.SubText, Position = UDim2.fromOffset(0, 18),
                    Size = UDim2.new(1, 0, 0, 16), TextXAlignment = 0,
                    BackgroundTransparency = 1, Parent = n
                })

                n.Size = UDim2.new(1, 0, 0, 0)
                TweenService:Create(n, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 54)}):Play()

                task.delay(4, function()
                    if not n or not n.Parent then return end
                    local tw = TweenService:Create(n, TweenInfo.new(0.4), {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
                    tw:Play()
                    tw.Completed:Connect(function() n:Destroy() end)
                end)
            end

            spawnNotify("Heaven Hud", "Successfully initialized visuals")
        end

        -- 4. FLOATING AD (Оптимизация лагов)
        if ctx:GetSetting("DiscordAd") then
            local ad = create("Frame", {
                Size = UDim2.fromOffset(150, 24),
                BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 0.85,
                Position = UDim2.fromOffset(100, 100),
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

            local vel = Vector2.new(70, 70)
            local currentX = 100
            local currentY = 100

            table.insert(connections, RunService.RenderStepped:Connect(function(dt)
                if not ad or not ad.Parent then return end

                local screen = screenGui.AbsoluteSize
                if screen.X == 0 then return end

                local size = ad.AbsoluteSize

                currentX = currentX + (vel.X * dt)
                currentY = currentY + (vel.Y * dt)

                if currentX <= 0 or currentX + size.X >= screen.X then
                    vel = Vector2.new(-vel.X, vel.Y)
                    currentX = math.clamp(currentX, 0, screen.X - size.X)
                end
                if currentY <= TOP_OFFSET or currentY + size.Y >= screen.Y then
                    vel = Vector2.new(vel.X, -vel.Y)
                    currentY = math.clamp(currentY, TOP_OFFSET, screen.Y - size.Y)
                end

                ad.Position = UDim2.fromOffset(currentX, currentY)
            end))
        end
    end,

    OnDisable = function(ctx)
        for _, conn in ipairs(connections) do if conn then conn:Disconnect() end end
        for _, el in ipairs(elements) do if el then el:Destroy() end end
        connections = {}
        elements = {}
        screenGui = nil
    end,
}