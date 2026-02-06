local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local bgGui = nil
local fgGui = nil

local elements = {}
local connections = {}
local activeNotifs = {}
local uiRefs = {}

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

local function applyScaleDrag(frame, targetGui)
    local dragging, dragStart, startPos = false, nil, nil
    table.insert(connections, frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, input.Position, frame.Position
        end
    end))
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local screen = targetGui.AbsoluteSize
            local deltaScaleX, deltaScaleY = delta.X / screen.X, delta.Y / screen.Y
            local newScaleX, newScaleY = startPos.X.Scale + deltaScaleX, startPos.Y.Scale + deltaScaleY
            local offsetFromAnchorX = (frame.Size.X.Offset / screen.X) * frame.AnchorPoint.X
            local offsetFromAnchorY = (frame.Size.Y.Offset / screen.Y) * frame.AnchorPoint.Y
            local limitMaxX = 1 - ((frame.Size.X.Offset / screen.X) * (1 - frame.AnchorPoint.X))
            local limitMaxY = 1 - ((frame.Size.Y.Offset / screen.Y) * (1 - frame.AnchorPoint.Y))
            frame.Position = UDim2.fromScale(math.clamp(newScaleX, offsetFromAnchorX, limitMaxX), math.clamp(newScaleY, offsetFromAnchorY, limitMaxY))
        end
    end))
    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
end

return {
    Name = "Hud",
    Desc = "Heaven HUD: Split Z-Index Logic",
    Class = "Visuals",
    Category = "Visuals",
    AlwaysEnabled = true,

    Settings = {
        { Type = "Boolean", Name = "Watermark", Default = true },
        { Type = "Boolean", Name = "StaffList", Default = true },
        { Type = "Boolean", Name = "Notifications", Default = true },
        { Type = "Slider",  Name = "MaxNotifications", Default = 5, Min = 1, Max = 12, Step = 1 },
        { Type = "Boolean", Name = "DiscordAd", Default = true },
    },

    OnEnable = function(ctx)
        local playerGui = player:WaitForChild("PlayerGui")

        bgGui = create("ScreenGui", { Name = "HeavenHud_BG", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = -1 }, playerGui)
        fgGui = create("ScreenGui", { Name = "HeavenHud_FG", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000 }, playerGui)

        activeNotifs = {}
        uiRefs = {}

        -- 1. Watermark
        local wm = create("Frame", {
            Name = "Watermark", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(280, 30),
            Position = UDim2.new(0.5, 0, 0, 8), BackgroundColor3 = Theme.Panel, Parent = bgGui,
            Visible = ctx:GetSetting("Watermark")
        })
        uiRefs.Watermark = wm
        applyStyle(wm, 6); applyScaleDrag(wm, bgGui)
        local wmLabel = create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Heaven  •  00 FPS  •  00:00", TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 11, Parent = wm })

        local smoothedFps = 60
        table.insert(connections, RunService.RenderStepped:Connect(function(dt)
            if dt > 0 then
                smoothedFps = smoothedFps + (math.clamp(1/dt, 0, 999) - smoothedFps) * 0.015
            end
            wmLabel.Text = string.format("Heaven  •  %d FPS  •  %s", math.floor(math.abs(smoothedFps)), os.date("%H:%M"))
        end))

        -- 2. Staff List
        local sl = create("Frame", {
            Name = "StaffList", Size = UDim2.fromOffset(170, 100), Position = UDim2.new(0, 20, 0, 85),
            BackgroundColor3 = Theme.Panel, Parent = bgGui,
            Visible = ctx:GetSetting("StaffList")
        })
        uiRefs.StaffList = sl
        applyStyle(sl, 10); applyScaleDrag(sl, bgGui)
        create("TextLabel", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "Staff Online", TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 12, Parent = sl })
        local listFrame = create("Frame", { Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 1, -28), BackgroundTransparency = 1, Parent = sl })
        create("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center }, listFrame)
        create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "No staff found", TextColor3 = Theme.SubText, Font = Enum.Font.GothamMedium, TextSize = 11, Parent = listFrame })

        -- 3. Notifications
        local notifyArea = create("Frame", {
            Name = "NotifyArea", Size = UDim2.new(0, 260, 0.4, 0), Position = UDim2.new(1, -280, 0.92, 0),
            AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, Parent = bgGui,
            Visible = ctx:GetSetting("Notifications")
        })
        uiRefs.Notifications = notifyArea
        create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, notifyArea)

        local function spawnNotify(title, msg)
            if not ctx:GetSetting("Notifications") then return end
            local max = ctx:GetSetting("MaxNotifications") or 5
            if #activeNotifs >= max then
                local oldest = table.remove(activeNotifs, 1)
                if oldest and oldest.Parent then oldest:Destroy() end
            end
            local n = create("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = Theme.Panel, ClipsDescendants = true, Parent = notifyArea })
            applyStyle(n, 10)
            create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 8)}, n)
            create("TextLabel", { Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Accent, Size = UDim2.new(1, 0, 0, 16), TextXAlignment = 0, BackgroundTransparency = 1, Parent = n })
            create("TextLabel", { Text = msg, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.SubText, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = 0, BackgroundTransparency = 1, Parent = n })
            table.insert(activeNotifs, n)
            n.Size = UDim2.new(1, 0, 0, 0)
            TweenService:Create(n, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 54)}):Play()
            task.delay(4, function()
                if not n or not n.Parent then return end
                local idx = table.find(activeNotifs, n); if idx then table.remove(activeNotifs, idx) end
                local tw = TweenService:Create(n, TweenInfo.new(0.4), {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
                tw:Play(); tw.Completed:Connect(function() n:Destroy() end)
            end)
        end
        ctx.Shared.Notify = spawnNotify

        -- 4. Discord Ad
        local adLabel = create("TextLabel", {
            Size = UDim2.fromOffset(150, 24), BackgroundTransparency = 1, Text = "discord.gg/heaven",
            TextColor3 = Theme.Text, TextTransparency = 0.4, Font = Enum.Font.GothamBold, TextSize = 11,
            Position = UDim2.fromOffset(200, 200), Parent = fgGui,
            Visible = ctx:GetSetting("DiscordAd"),
            ZIndex = 9999
        })
        uiRefs.DiscordAd = adLabel

        local vel = Vector2.new(85, 85)
        local curX, curY = 200, 200
        table.insert(connections, RunService.RenderStepped:Connect(function(dt)
            if not adLabel or not adLabel.Parent or not adLabel.Visible then return end
            local screen = fgGui.AbsoluteSize
            curX, curY = curX + (vel.X * dt), curY + (vel.Y * dt)
            if curX <= 0 or curX + adLabel.AbsoluteSize.X >= screen.X then vel = Vector2.new(-vel.X, vel.Y) curX = math.clamp(curX, 0, screen.X - adLabel.AbsoluteSize.X) end
            if curY <= 0 or curY + adLabel.AbsoluteSize.Y >= screen.Y then vel = Vector2.new(vel.X, -vel.Y) curY = math.clamp(curY, 0, screen.Y - adLabel.AbsoluteSize.Y) end
            adLabel.Position = UDim2.fromOffset(curX, curY)
        end))

        table.insert(connections, ctx.Changed:Connect(function(payload)
            if payload.moduleName == ctx.Name and payload.kind == "Setting" then
                local ref = uiRefs[payload.key]
                if ref then
                    ref.Visible = payload.value
                end
            end
        end))
    end,

    OnDisable = function(ctx)
        ctx.Shared.Notify = nil
        for _, conn in ipairs(connections) do if conn then conn:Disconnect() end end
        for _, el in ipairs(elements) do if el then el:Destroy() end end
        if bgGui then bgGui:Destroy() end
        if fgGui then fgGui:Destroy() end
        activeNotifs, uiRefs, connections, elements = {}, {}, {}, {}
    end,
}