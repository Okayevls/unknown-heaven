local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local bgGui, fgGui = nil, nil

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
    return create("UIStroke", {Color = Theme.Stroke, Thickness = 1}, obj)
end

local function applyScaleDrag(frame, targetGui)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    table.insert(connections, frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true

            dragStart = input.Position
            startPos = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local screen = targetGui.AbsoluteSize

            local newX = startPos.X + delta.X
            local newY = startPos.Y + delta.Y

            newX = newX + (frame.Size.X.Offset * frame.AnchorPoint.X)
            newY = newY + (frame.Size.Y.Offset * frame.AnchorPoint.Y)

            frame.Position = UDim2.fromScale(
                    math.clamp(newX / screen.X, 0, 1),
                    math.clamp(newY / screen.Y, 0, 1)
            )
        end
    end))
end

local HudMethods = {}

function HudMethods:renderWatermark(ctx)
    local wm = create("Frame", {
        Name = "Watermark", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(280, 30),
        Position = UDim2.new(0.5, 0, 0, 8), BackgroundColor3 = Theme.Panel, Parent = bgGui,
        Visible = ctx:GetSetting("Watermark")
    })
    uiRefs.Watermark = wm
    applyStyle(wm, 6); applyScaleDrag(wm, bgGui)

    local wmLabel = create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "Heaven  •  00 FPS  •  00:00", TextColor3 = Theme.Text,
        Font = Enum.Font.GothamMedium, TextSize = 11, Parent = wm
    })

    local smoothedFps = 60
    table.insert(connections, RunService.RenderStepped:Connect(function(dt)
        if dt > 0 then
            smoothedFps = smoothedFps + (math.clamp(1/dt, 0, 999) - smoothedFps) * 0.015
        end
        wmLabel.Text = string.format("Heaven  •  %d FPS  •  %s", math.floor(math.abs(smoothedFps)), os.date("%H:%M"))
    end))
end

function HudMethods:renderStaffList(ctx)
    local ManualStaffList = {
        ["polska_sigma21379"] = true,
        ["Builderman"] = true,
        ["ROBLOX"] = true,
    }

    local sl = create("Frame", {
        Name = "StaffList", Size = UDim2.fromOffset(170, 40), Position = UDim2.new(0, 20, 0, 250),
        BackgroundColor3 = Theme.Panel, Parent = bgGui,
        Visible = ctx:GetSetting("StaffList"),
        ClipsDescendants = true
    })
    uiRefs.StaffList = sl
    applyStyle(sl, 10); applyScaleDrag(sl, bgGui)

    local title = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "Staff Online",
        TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 12, Parent = sl
    })

    local listFrame = create("Frame", {
        Name = "ListFrame",
        Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 1, -28),
        BackgroundTransparency = 1, Parent = sl
    })

    create("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10)
    }, listFrame)

    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 4),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.Name
    }, listFrame)

    local function adjustHeight()
        local contentHeight = layout.AbsoluteContentSize.Y
        local finalHeight = 28 + (contentHeight > 0 and contentHeight + 10 or 25)

        TweenService:Create(sl, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Size = UDim2.fromOffset(170, finalHeight)
        }):Play()
    end

    table.insert(connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(adjustHeight))

    local function isStaff(p)
        if ManualStaffList[p.Name] then return true end
        local data = p:FindFirstChild("PlayerData")
        local isMod = data and data:FindFirstChild("IsModerator")
        return isMod and isMod.Value == true
    end

    local function updateList()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("Frame") or (child:IsA("TextLabel") and child.Name == "NoStaffLabel") then
                child:Destroy()
            end
        end

        local foundCount = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if isStaff(p) then
                foundCount = foundCount + 1
                local row = create("Frame", {
                    Name = p.Name,
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Parent = listFrame
                })

                create("TextLabel", {
                    Size = UDim2.new(1, -15, 1, 0),
                    BackgroundTransparency = 1,
                    Text = p.DisplayName or p.Name,
                    TextColor3 = Theme.Text,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = row
                })

                local dot = create("Frame", {
                    Name = "Status",
                    Size = UDim2.fromOffset(6, 6),
                    Position = UDim2.new(1, -6, 0.5, -3),
                    BackgroundColor3 = Color3.fromRGB(0, 255, 120),
                    Parent = row
                })
                create("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
            end
        end

        if foundCount == 0 then
            create("TextLabel", {
                Name = "NoStaffLabel",
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = "No staff found",
                TextColor3 = Theme.SubText,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                Parent = listFrame
            })
        end
    end

    table.insert(connections, Players.PlayerAdded:Connect(function(p)
        p:WaitForChild("PlayerData", 10)
        updateList()
    end))

    table.insert(connections, Players.PlayerRemoving:Connect(function(p)
        local row = listFrame:FindFirstChild(p.Name)
        if row then
            local dot = row:FindFirstChild("Status")
            if dot then dot.BackgroundColor3 = Color3.fromRGB(255, 60, 60) end
            task.wait(0.5)
        end
        updateList()
    end))

    task.spawn(updateList)
end

function HudMethods:renderNotifications(ctx)
    local notifyArea = create("Frame", {
        Name = "NotifyArea", Size = UDim2.new(0, 260, 0.4, 0), Position = UDim2.new(1, -280, 0.92, 0),
        AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, Parent = bgGui,
        Visible = ctx:GetSetting("Notifications")
    })
    uiRefs.Notifications = notifyArea
    create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, notifyArea)

    ctx.Shared.Notify = function(title, msg)
        if not ctx:GetSetting("Notifications") then return end
        local max = ctx:GetSetting("MaxNotifications") or 5
        if #activeNotifs >= max then
            local oldest = table.remove(activeNotifs, 1)
            if oldest and oldest.Parent then oldest:Destroy() end
        end

        local n = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Panel,
            BackgroundTransparency = 1, ClipsDescendants = true, Parent = notifyArea
        })
        local stroke = applyStyle(n, 10)
        stroke.Transparency = 1
        create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 8)}, n)

        local t1 = create("TextLabel", { Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.Accent, Size = UDim2.new(1, 0, 0, 16), TextXAlignment = 0, BackgroundTransparency = 1, TextTransparency = 1, Parent = n })
        local t2 = create("TextLabel", { Text = msg, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.SubText, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = 0, BackgroundTransparency = 1, TextTransparency = 1, Parent = n })

        table.insert(activeNotifs, n)

        TweenService:Create(n, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 0}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Transparency = 0}):Play()
        TweenService:Create(t1, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {TextTransparency = 0}):Play()
        TweenService:Create(t2, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {TextTransparency = 0}):Play()

        task.delay(4, function()
            if not n or not n.Parent then return end
            local idx = table.find(activeNotifs, n); if idx then table.remove(activeNotifs, idx) end
            TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Transparency = 1}):Play()
            TweenService:Create(t1, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {TextTransparency = 1}):Play()
            local lastTw = TweenService:Create(t2, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {TextTransparency = 1})
            lastTw:Play(); lastTw.Completed:Connect(function() n:Destroy() end)
        end)
    end
end

function HudMethods:renderDiscordAd(ctx)
    local adLabel = create("TextLabel", {
        Size = UDim2.fromOffset(150, 24), BackgroundTransparency = 1, Text = "discord.gg/R7ABPb2f",
        TextColor3 = Theme.Text, TextTransparency = 0.4, Font = Enum.Font.GothamBold, TextSize = 11,
        Position = UDim2.fromOffset(200, 200), Parent = fgGui,
        Visible = ctx:GetSetting("DiscordAd"), ZIndex = 9999
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
end

return {
    Name = "Hud",
    Desc = "Показывает всякую информацию на экране",
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

        bgGui = create("ScreenGui", { Name = "HeavenHud_BG", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2147483645 }, playerGui)
        fgGui = create("ScreenGui", { Name = "HeavenHud_FG", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2147483647 }, playerGui)

        activeNotifs = {}
        uiRefs = {}

        HudMethods:renderWatermark(ctx)
        HudMethods:renderStaffList(ctx)
        HudMethods:renderNotifications(ctx)
        HudMethods:renderDiscordAd(ctx)

        table.insert(connections, ctx.Changed:Connect(function(payload)
            if payload.moduleName == ctx.Name and payload.kind == "Setting" then
                local ref = uiRefs[payload.key]
                if ref then ref.Visible = payload.value end
            end
        end))

        if ctx.Shared.Notify then ctx.Shared.Notify("Heaven", "Structured HUD Loaded") end
    end,

    OnDisable = function(ctx)
        ctx.Shared.Notify = nil
        for _, conn in pairs(connections) do if conn then conn:Disconnect() end end
        for _, el in pairs(elements) do if el then el:Destroy() end end
        if bgGui then bgGui:Destroy() end
        if fgGui then fgGui:Destroy() end
        activeNotifs, uiRefs, connections, elements = {}, {}, {}, {}
    end,
}