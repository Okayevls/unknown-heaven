local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

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

-- Стабильный Drag без прыжков
local function applyScaleDrag(frame, targetGui)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    table.insert(connections, frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.AbsolutePosition
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local screen = targetGui.AbsoluteSize
            local inset = GuiService:GetGuiInset()

            local newX = startPos.X + delta.X
            local newY = startPos.Y + delta.Y

            if targetGui.IgnoreGuiInset then
                newY = newY + inset.Y
                newX = newX + inset.X
            end

            newX = newX + (frame.AbsoluteSize.X * frame.AnchorPoint.X)
            newY = newY + (frame.AbsoluteSize.Y * frame.AnchorPoint.Y)

            frame.Position = UDim2.fromScale(
                    math.clamp(newX / screen.X, 0, 1),
                    math.clamp(newY / screen.Y, 0, 1)
            )
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
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
    local ManualStaffList = { ["Builderman"] = true, ["ROBLOX"] = true }

    local sl = create("Frame", {
        Name = "StaffList", Size = UDim2.fromOffset(170, 40), Position = UDim2.new(0, 20, 0, 250),
        BackgroundColor3 = Theme.Panel, Parent = bgGui, Visible = ctx:GetSetting("StaffList"), ClipsDescendants = true
    })
    uiRefs.StaffList = sl
    applyStyle(sl, 10); applyScaleDrag(sl, bgGui)

    local title = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "Staff Online",
        TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 12, Parent = sl
    })

    local listFrame = create("Frame", {
        Name = "ListFrame", Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 1, -28),
        BackgroundTransparency = 1, Parent = sl
    })
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, listFrame)
    local layout = create("UIListLayout", { Padding = UDim.new(0, 4), HorizontalAlignment = 1, SortOrder = 2 }, listFrame)

    local function adjustHeight()
        local contentHeight = layout.AbsoluteContentSize.Y
        local finalHeight = 28 + (contentHeight > 0 and contentHeight + 10 or 25)
        TweenService:Create(sl, TweenInfo.new(0.3, 6), {Size = UDim2.fromOffset(170, finalHeight)}):Play()
    end
    table.insert(connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(adjustHeight))

    local function isStaff(p)
        if ManualStaffList[p.Name] then return true end
        local data = p:FindFirstChild("PlayerData")
        return data and data:FindFirstChild("IsModerator") and data.IsModerator.Value == true
    end

    local function updateList()
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("Frame") or (child:IsA("TextLabel") and child.Name == "NoStaffLabel") then child:Destroy() end
        end
        local found = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if isStaff(p) then
                found = found + 1
                local row = create("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = listFrame })
                create("TextLabel", { Size = UDim2.new(1, -15, 1, 0), BackgroundTransparency = 1, Text = p.DisplayName or p.Name, TextColor3 = Theme.Text, Font = 17, TextSize = 11, TextXAlignment = 0, TextTruncate = 1, Parent = row })
                local dot = create("Frame", { Name = "Status", Size = UDim2.fromOffset(6, 6), Position = UDim2.new(1, -6, 0.5, -3), BackgroundColor3 = Color3.fromRGB(0, 255, 120), Parent = row })
                create("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
            end
        end
        if found == 0 then
            create("TextLabel", { Name = "NoStaffLabel", Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "No staff found", TextColor3 = Theme.SubText, Font = 17, TextSize = 11, Parent = listFrame })
        end
    end

    table.insert(connections, Players.PlayerAdded:Connect(function(p) p:WaitForChild("PlayerData", 10); updateList() end))
    table.insert(connections, Players.PlayerRemoving:Connect(function(p)
        local row = listFrame:FindFirstChild(p.Name)
        if row and row:FindFirstChild("Status") then row.Status.BackgroundColor3 = Color3.fromRGB(255, 60, 60) task.wait(0.5) end
        updateList()
    end))
    task.spawn(updateList)
end

function HudMethods:renderTargetHud(ctx)
    local th = create("Frame", {
        Name = "TargetHud", Size = UDim2.fromOffset(240, 105),
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.85, 0),
        BackgroundColor3 = Theme.Panel, Parent = bgGui, Visible = false, BackgroundTransparency = 1, ClipsDescendants = true
    })
    uiRefs.TargetHud = th
    local stroke = applyStyle(th, 10); stroke.Transparency = 1
    applyScaleDrag(th, bgGui)

    local nameLabel = create("TextLabel", { Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 18), BackgroundTransparency = 1, Text = "Target", TextColor3 = Theme.Text, Font = 18, TextSize = 14, TextXAlignment = 0, Parent = th, TextTransparency = 1 })

    local function createBar(pos, color, text)
        local b = create("Frame", { Position = pos, Size = UDim2.new(1, -24, 0, 12), BackgroundColor3 = Color3.fromRGB(40, 40, 40), Parent = th, BackgroundTransparency = 1 })
        applyStyle(b, 4).Transparency = 1
        local f = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = color, Parent = b, BackgroundTransparency = 1 })
        create("UICorner", {CornerRadius = UDim.new(0, 4)}, f)
        local t = create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.new(1,1,1), Font = 18, TextSize = 10, Parent = b, TextTransparency = 1 })
        return b, f, t
    end

    local hpB, hpF, hpT = createBar(UDim2.fromOffset(12, 32), Color3.fromRGB(255, 80, 80), "100 HP")
    local apB, apF, apT = createBar(UDim2.fromOffset(12, 48), Color3.fromRGB(80, 200, 255), "0 AP")
    local ragLabel = create("TextLabel", { Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 0, 16), BackgroundTransparency = 1, Text = "", TextColor3 = Color3.fromRGB(255, 150, 50), Font = 18, TextSize = 11, TextXAlignment = 0, Parent = th, TextTransparency = 1 })
    local distLabel = create("TextLabel", { Position = UDim2.fromOffset(12, 82), Size = UDim2.new(1, -24, 0, 16), BackgroundTransparency = 1, Text = "Distance: 0m", TextColor3 = Theme.SubText, Font = 17, TextSize = 11, TextXAlignment = 0, Parent = th, TextTransparency = 1 })

    local isVisible, ragTime, lastRag = false, 0, false
    local function animate(tr)
        if tr == 0 then th.Visible = true end
        local ti = TweenInfo.new(0.3, 6)
        TweenService:Create(th, ti, {BackgroundTransparency = tr}):Play()
        TweenService:Create(stroke, ti, {Transparency = tr}):Play()
        TweenService:Create(nameLabel, ti, {TextTransparency = tr}):Play()
        TweenService:Create(hpB, ti, {BackgroundTransparency = tr}):Play()
        TweenService:Create(hpF, ti, {BackgroundTransparency = tr}):Play()
        TweenService:Create(hpT, ti, {TextTransparency = tr}):Play()
        TweenService:Create(apB, ti, {BackgroundTransparency = tr}):Play()
        TweenService:Create(apF, ti, {BackgroundTransparency = tr}):Play()
        TweenService:Create(apT, ti, {TextTransparency = tr}):Play()
        TweenService:Create(ragLabel, ti, {TextTransparency = tr}):Play()
        local last = TweenService:Create(distLabel, ti, {TextTransparency = tr}); last:Play()
        if tr == 1 then last.Completed:Connect(function() if not isVisible then th.Visible = false end end) end
    end

    table.insert(connections, RunService.Heartbeat:Connect(function(dt)
        local target = ctx.SharedTrash and (ctx.SharedTrash.SelectedTarget or ctx.SharedTrash.RandomTarget)
        if target and target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
            if not isVisible then isVisible = true animate(0) end
            local char = target.Character
            local hum = char.Humanoid
            nameLabel.Text = target.DisplayName or target.Name

            local isRag = char:GetAttribute("Ragdoll")
            if isRag then
                ragLabel.Visible = true
                local currentHp = hum.Health

                if currentHp < 30 then
                    -- РАСЧЕТ: Сколько HP осталось до 30
                    local hpNeeded = 30 - currentHp

                    -- СКОРОСТЬ: Укажи здесь, сколько HP в секунду регенится в твоей игре
                    -- Если 2 HP в сек:
                    local regenRate = 2
                    local secondsLeft = hpNeeded / regenRate

                    ragLabel.Text = string.format("WAKING UP IN: %.1fs", secondsLeft)
                    ragLabel.TextColor3 = Color3.fromRGB(255, 150, 50) -- Оранжевый
                else
                    -- Если уже больше 30 HP, значит он встанет в любой момент (серверный тик)
                    ragLabel.Text = "WAKING UP NOW..."
                    ragLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Зеленый
                end
            else
                ragLabel.Visible = false
            end

            local av = 0
            local vals = char:FindFirstChild("Values")
            if vals and vals:FindFirstChild("Armor") then av = vals.Armor.Value end

            hpF.Size = UDim2.fromScale(math.clamp(hum.Health/hum.MaxHealth, 0, 1), 1)
            apF.Size = UDim2.fromScale(math.clamp(av/100, 0, 1), 1)
            hpT.Text = string.format("%d / %d HP", math.floor(hum.Health), math.floor(hum.MaxHealth))
            apT.Text = math.floor(av) .. " AP"

            local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local tRoot = char:FindFirstChild("HumanoidRootPart")
            distLabel.Text = "Distance: " .. ((myRoot and tRoot) and math.floor((myRoot.Position - tRoot.Position).Magnitude) or 0) .. "m"
        else if isVisible then isVisible = false animate(1) end end
    end))
end

function HudMethods:renderNotifications(ctx)
    local notifyArea = create("Frame", { Name = "NotifyArea", Size = UDim2.new(0, 260, 0.4, 0), Position = UDim2.new(1, -280, 0.92, 0), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, Parent = bgGui, Visible = ctx:GetSetting("Notifications") })
    create("UIListLayout", { VerticalAlignment = 1, Padding = UDim.new(0, 8), SortOrder = 2 }, notifyArea)

    ctx.Shared.Notify = function(title, msg)
        if not ctx:GetSetting("Notifications") then return end
        if #activeNotifs >= (ctx:GetSetting("MaxNotifications") or 5) then
            local oldest = table.remove(activeNotifs, 1)
            if oldest then oldest:Destroy() end
        end

        local n = create("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 1, ClipsDescendants = true, Parent = notifyArea })
        local s = applyStyle(n, 10); s.Transparency = 1
        create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 8)}, n)

        local t1 = create("TextLabel", { Text = title, Font = 18, TextSize = 13, TextColor3 = Theme.Accent, Size = UDim2.new(1, 0, 0, 16), TextXAlignment = 0, BackgroundTransparency = 1, TextTransparency = 1, Parent = n })
        local t2 = create("TextLabel", { Text = msg, Font = 17, TextSize = 11, TextColor3 = Theme.SubText, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 16), TextXAlignment = 0, BackgroundTransparency = 1, TextTransparency = 1, Parent = n })
        table.insert(activeNotifs, n)

        local ti = TweenInfo.new(0.4, 6)
        TweenService:Create(n, ti, {Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 0}):Play()
        TweenService:Create(s, ti, {Transparency = 0}):Play()
        TweenService:Create(t1, ti, {TextTransparency = 0}):Play()
        TweenService:Create(t2, ti, {TextTransparency = 0}):Play()

        task.delay(4, function()
            if not n.Parent then return end
            local idx = table.find(activeNotifs, n) if idx then table.remove(activeNotifs, idx) end
            local out = TweenInfo.new(0.3, 6)
            TweenService:Create(n, out, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}):Play()
            TweenService:Create(s, out, {Transparency = 1}):Play()
            local last = TweenService:Create(t2, out, {TextTransparency = 1}); last:Play()
            last.Completed:Connect(function() n:Destroy() end)
        end)
    end
end

function HudMethods:renderDiscordAd(ctx)
    local ad = create("TextLabel", { Size = UDim2.fromOffset(150, 24), BackgroundTransparency = 1, Text = "discord.gg/R7ABPb2f", TextColor3 = Theme.Text, TextTransparency = 0.4, Font = 18, TextSize = 11, Position = UDim2.fromOffset(200, 200), Parent = fgGui, Visible = ctx:GetSetting("DiscordAd"), ZIndex = 9999 })
    local vel = Vector2.new(85, 85) local curX, curY = 200, 200
    table.insert(connections, RunService.RenderStepped:Connect(function(dt)
        if not ad.Visible then return end
        local screen = fgGui.AbsoluteSize
        curX, curY = curX + (vel.X * dt), curY + (vel.Y * dt)
        if curX <= 0 or curX + ad.AbsoluteSize.X >= screen.X then vel = Vector2.new(-vel.X, vel.Y) end
        if curY <= 0 or curY + ad.AbsoluteSize.Y >= screen.Y then vel = Vector2.new(vel.X, -vel.Y) end
        ad.Position = UDim2.fromOffset(math.clamp(curX, 0, screen.X), math.clamp(curY, 0, screen.Y))
    end))
end

return {
    Name = "Hud",
    Desc = "Heaven Visual Interface",
    Class = "Visuals", Category = "Visuals", AlwaysEnabled = true,
    Settings = {
        { Type = "Boolean", Name = "Watermark", Default = true },
        { Type = "Boolean", Name = "StaffList", Default = true },
        { Type = "Boolean", Name = "TargetHud", Default = true },
        { Type = "Boolean", Name = "Notifications", Default = true },
        { Type = "Slider",  Name = "MaxNotifications", Default = 5, Min = 1, Max = 12, Step = 1 },
        { Type = "Boolean", Name = "DiscordAd", Default = true },
    },
    OnEnable = function(ctx)
        local pg = player:WaitForChild("PlayerGui")
        bgGui = create("ScreenGui", { Name = "Heaven_BG", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10 }, pg)
        fgGui = create("ScreenGui", { Name = "Heaven_FG", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 11 }, pg)

        HudMethods:renderWatermark(ctx)
        HudMethods:renderStaffList(ctx)
        HudMethods:renderNotifications(ctx)
        HudMethods:renderTargetHud(ctx)
        HudMethods:renderDiscordAd(ctx)

        table.insert(connections, ctx.Changed:Connect(function(p)
            if p.kind == "Setting" and uiRefs[p.key] then uiRefs[p.key].Visible = p.value end
        end))
    end,
    OnDisable = function()
        for _, c in pairs(connections) do c:Disconnect() end
        for _, e in pairs(elements) do e:Destroy() end
        if bgGui then bgGui:Destroy() end if fgGui then fgGui:Destroy() end
        connections, elements, activeNotifs, uiRefs = {}, {}, {}, {}
    end
}