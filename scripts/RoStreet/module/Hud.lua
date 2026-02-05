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
    return create("UIStroke", {Color = Theme.Stroke, Thickness = 1}, obj)
end

-- Функция проверки пересечения двух Rect
local function getOverlap(frame1, frame2)
    local p1, s1 = frame1.AbsolutePosition, frame1.AbsoluteSize
    local p2, s2 = frame2.AbsolutePosition, frame2.AbsoluteSize

    return (p1.X < p2.X + s2.X and p1.X + s1.X > p2.X and
            p1.Y < p2.Y + s2.Y and p1.Y + s1.Y > p2.Y)
end

-- Логика перетаскивания с коллизиями
local function applyCollisionDrag(frame)
    local dragging, dragStart, startPos
    local stroke = frame:FindFirstChildOfClass("UIStroke")

    table.insert(connections, frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, input.Position, frame.Position
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)

            -- Проверка на контакт
            local colliding = false
            for _, other in ipairs(elements) do
                if other:IsA("Frame") and other ~= frame and other.Visible and other.Name ~= "Ad" then
                    if getOverlap(frame, other) then
                        colliding = true
                        break
                    end
                end
            end
            if stroke then stroke.Color = colliding and Theme.Accent or Theme.Stroke end
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if stroke then stroke.Color = Theme.Stroke end

            -- Если после отпускания есть коллизия — отодвигаем
            for _, other in ipairs(elements) do
                if other:IsA("Frame") and other ~= frame and other.Visible and other.Name ~= "Ad" then
                    if getOverlap(frame, other) then
                        -- Сдвигаем текущий фрейм чуть ниже соседа плавно
                        local newY = other.Position.Y.Offset + other.Size.Y.Offset + 10
                        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                            Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, frame.Position.Y.Scale, newY)
                        }):Play()
                    end
                end
            end
        end
    end))
end

return {
    Name = "Hud",
    Desc = "Heaven HUD: Smart Collision Logic",
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
        screenGui = create("ScreenGui", { Name = "HeavenHud", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100 }, playerGui)

        -- 1. WATERMARK
        if ctx:GetSetting("Watermark") then
            local wm = create("Frame", {
                Name = "Watermark", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(280, 30),
                Position = UDim2.new(0.5, 0, 0, 8), BackgroundColor3 = Theme.Panel, Parent = screenGui
            })
            applyStyle(wm, 6)
            applyCollisionDrag(wm)

            local textLabel = create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                Text = "Heaven  •  00 FPS  •  00:00", TextColor3 = Theme.Text,
                Font = Enum.Font.GothamMedium, TextSize = 11, Parent = wm
            })

            local smoothedFps = 60
            table.insert(connections, RunService.RenderStepped:Connect(function(dt)
                smoothedFps = smoothedFps + ((1/dt) - smoothedFps) * 0.015
                textLabel.Text = string.format("Heaven  •  %d FPS  •  %s", math.round(smoothedFps), os.date("%H:%M"))
            end))
        end

        -- 2. STAFF LIST
        if ctx:GetSetting("StaffList") then
            local sl = create("Frame", {
                Name = "StaffList", Size = UDim2.fromOffset(170, 100), Position = UDim2.fromOffset(20, 85),
                BackgroundColor3 = Theme.Panel, Parent = screenGui
            })
            applyStyle(sl, 10)
            applyCollisionDrag(sl)
            create("TextLabel", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "Staff Online", TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 12, Parent = sl })
            local list = create("Frame", { Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 1, -28), BackgroundTransparency = 1, Parent = sl })
            create("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center }, list)
            create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "No staff found", TextColor3 = Theme.SubText, Font = Enum.Font.GothamMedium, TextSize = 11, Parent = list })
        end

        -- 3. NOTIFICATIONS
        if ctx:GetSetting("Notifications") then
            local notifyArea = create("Frame", {
                Name = "NotifyArea", Size = UDim2.new(0, 260, 0.4, 0),
                Position = UDim2.new(1, -280, 0.92, 0), AnchorPoint = Vector2.new(0, 1),
                BackgroundTransparency = 1, Parent = screenGui
            })
            create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, notifyArea)

            local function spawnNotify(title, msg)
                local n = create("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = Theme.Panel, ClipsDescendants = true, Parent = notifyArea })
                applyStyle(n, 10)
                create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 8)}, n)
                create("TextLabel", { Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Accent, Size = UDim2.new(1, 0, 0, 16), TextXAlignment = 0, BackgroundTransparency = 1, Parent = n })
                create("TextLabel", { Text = msg, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.SubText, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = 0, BackgroundTransparency = 1, Parent = n })

                n.Size = UDim2.new(1, 0, 0, 0)
                TweenService:Create(n, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 54)}):Play()
                task.delay(4, function()
                    if not n or not n.Parent then return end
                    local tw = TweenService:Create(n, TweenInfo.new(0.4), {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
                    tw:Play()
                    tw.Completed:Connect(function() n:Destroy() end)
                end)
            end

            spawnNotify("Heaven", "Collision System Active")
        end

        -- 4. FLOATING AD
        if ctx:GetSetting("DiscordAd") then
            local adLabel = create("TextLabel", { Size = UDim2.fromOffset(150, 24), BackgroundTransparency = 1, Text = "discord.gg/heaven", TextColor3 = Theme.Text, TextTransparency = 0.6, Font = Enum.Font.GothamBold, TextSize = 10, Position = UDim2.fromOffset(200, 200), Parent = screenGui })
            local vel = Vector2.new(75, 75)
            local currentX, currentY = 200, 200
            table.insert(connections, RunService.RenderStepped:Connect(function(dt)
                if not adLabel or not adLabel.Parent then return end
                local screen = screenGui.AbsoluteSize
                if screen.X <= 0 then return end
                currentX, currentY = currentX + (vel.X * dt), currentY + (vel.Y * dt)
                if currentX <= 0 then vel = Vector2.new(math.abs(vel.X), vel.Y) currentX = 0
                elseif currentX + adLabel.AbsoluteSize.X >= screen.X then vel = Vector2.new(-math.abs(vel.X), vel.Y) currentX = screen.X - adLabel.AbsoluteSize.X end
                if currentY <= 0 then vel = Vector2.new(vel.X, math.abs(vel.Y)) currentY = 0
                elseif currentY + adLabel.AbsoluteSize.Y >= screen.Y then vel = Vector2.new(vel.X, -math.abs(vel.Y)) currentY = screen.Y - adLabel.AbsoluteSize.Y end
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