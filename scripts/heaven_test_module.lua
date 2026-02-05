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

-- Упрощенный Drag без коллизий и застреваний
local function applySimpleDrag(frame)
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
end

return {
    Name = "Hud",
    Desc = "Heaven HUD: Ad Bounce Fix & Real Time",
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

        -- 1. WATERMARK (С часами)
        if ctx:GetSetting("Watermark") then
            local wm = create("Frame", {
                Name = "Watermark",
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.fromOffset(280, 30),
                Position = UDim2.new(0.5, 0, 0, 10),
                BackgroundColor3 = Theme.Panel,
                Parent = screenGui
            })
            applyStyle(wm, 6)
            applySimpleDrag(wm)

            local textLabel = create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "HEAVEN | " .. player.Name:lower() .. " | 00:00:00",
                TextColor3 = Theme.Text,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                Parent = wm
            })

            -- Обновление времени
            table.insert(connections, RunService.Heartbeat:Connect(function()
                local timeStr = os.date("%H:%M:%S")
                textLabel.Text = "HEAVEN  •  " .. player.Name:lower() .. "  •  " .. timeStr
            end))
        end

        -- 2. STAFF LIST
        if ctx:GetSetting("StaffList") then
            local sl = create("Frame", {
                Name = "StaffList",
                Size = UDim2.fromOffset(170, 100),
                Position = UDim2.fromOffset(20, 60),
                BackgroundColor3 = Theme.Panel,
                Parent = screenGui
            })
            applyStyle(sl, 10)
            applySimpleDrag(sl)

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

        -- 3. NOTIFICATIONS (Внизу)
        if ctx:GetSetting("Notifications") then
            local notifyArea = create("Frame", {
                Name = "NotifyArea",
                Size = UDim2.new(0, 260, 0.5, 0),
                Position = UDim2.new(1, -280, 0.85, 0),
                AnchorPoint = Vector2.new(0, 1),
                BackgroundTransparency = 1,
                Parent = screenGui
            })
            create("UIListLayout", {
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
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

            spawnNotify("Heaven", "Ad and Time Fixed!")
        end

        -- 4. FLOATING AD (Исправленный Bounce)
        if ctx:GetSetting("DiscordAd") then
            local adLabel = create("TextLabel", {
                Size = UDim2.fromOffset(150, 24),
                BackgroundTransparency = 1,
                Text = "discord.gg/heaven",
                TextColor3 = Theme.Text,
                TextTransparency = 0.6,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                Position = UDim2.fromOffset(200, 200),
                Parent = screenGui
            })

            local vel = Vector2.new(80, 80)
            local currentX, currentY = 200, 200

            table.insert(connections, RunService.RenderStepped:Connect(function(dt)
                if not adLabel or not adLabel.Parent then return end
                local screen = screenGui.AbsoluteSize
                if screen.X <= 0 then return end

                local size = adLabel.AbsoluteSize

                currentX = currentX + (vel.X * dt)
                currentY = currentY + (vel.Y * dt)

                -- Логика отскока (Bounce)
                if currentX <= 0 then
                    vel = Vector2.new(math.abs(vel.X), vel.Y)
                    currentX = 0
                elseif currentX + size.X >= screen.X then
                    vel = Vector2.new(-math.abs(vel.X), vel.Y)
                    currentX = screen.X - size.X
                end

                if currentY <= 0 then
                    vel = Vector2.new(vel.X, math.abs(vel.Y))
                    currentY = 0
                elseif currentY + size.Y >= screen.Y then
                    vel = Vector2.new(vel.X, -math.abs(vel.Y))
                    currentY = screen.Y - size.Y
                end

                adLabel.Position = UDim2.fromOffset(currentX, currentY)
            end))
        end
    end,

    OnDisable = function(ctx)
        for _, conn in ipairs(connections) do if conn then conn:Disconnect() end end
        for _, el in ipairs(elements) do if el then el:Destroy() end end
        connections, elements, screenGui = {}, {}, nil
    end,
}