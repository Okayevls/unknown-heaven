local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local randomTarget = nil
local selectedTarget = nil
local line = nil
local isShooting = false
local isSpectating = false

local SupportedWeapons = {
    ["AW1"] = true, ["Ak"] = true, ["Barrett"] = true, ["Deagle"] = true, ["Double Barrel"] = true, ["Draco"] = true,
    ["Glock"] = true, ["Heli"] = true, ["M249"] = true, ["M37"] = true, ["M4"] = true, ["Micro Uzi"] = true,
    ["Rpg"] = true, ["Silencer"] = true, ["Spas"] = true, ["Taser"] = true, ["Tec"] = true, ["Ump"] = true
}

local function getEquippedWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    for name, _ in pairs(SupportedWeapons) do
        if char:FindFirstChild(name) and char[name]:FindFirstChild("Communication") then
            return char[name]
        end
    end
    return nil
end

local function findNearestToMouse()
    local mouseLocation = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local closestDist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local headPos = char.Head.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function toggleSpectate(target)
    if isSpectating then
        Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        isSpectating = false
    elseif target and target.Character and target.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = target.Character.Humanoid
        isSpectating = true
    end
end

local function create3DTracer(fromAttachment, targetPosition)
    local startPart = Instance.new("Part")
    startPart.Size = Vector3.new(0.1, 0.1, 0.1)
    startPart.Anchored = true
    startPart.CanCollide = false
    startPart.Transparency = 1
    startPart.Position = fromAttachment.WorldPosition
    startPart.Parent = workspace

    local attachStart = Instance.new("Attachment")
    attachStart.Parent = startPart

    local endPart = Instance.new("Part")
    endPart.Size = Vector3.new(0.1, 0.1, 0.1)
    endPart.Anchored = true
    endPart.CanCollide = false
    endPart.Transparency = 1
    endPart.Position = targetPosition
    endPart.Parent = workspace

    local attachEnd = Instance.new("Attachment")
    attachEnd.Parent = endPart

    local beam = Instance.new("Beam")
    beam.Attachment0 = attachStart
    beam.Attachment1 = attachEnd
    beam.FaceCamera = true
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 190, 255), Color3.fromRGB(180, 140, 255))
    beam.Width0, beam.Width1 = 0.2, 0.2
    beam.LightEmission = 0.9
    beam.Transparency = NumberSequence.new(0, 0.8)
    beam.Parent = workspace

    task.spawn(function()
        local steps = 40
        for i = 1, steps do
            local factor = 1 - (i / steps)
            beam.Width0, beam.Width1 = 0.2 * factor, 0.2 * factor
            task.wait(0.025)
        end
        beam:Destroy() startPart:Destroy() endPart:Destroy()
    end)
end

local function updateLine()
    if not selectedTarget or not selectedTarget.Character or not selectedTarget.Character:FindFirstChild("Head") then
        if line then line.Visible = false end
        return
    end
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("Head") then
        if line then line.Visible = false end
        return
    end

    if not line then
        line = Drawing.new("Line")
        line.Visible = true
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 2
    end

    local fromScreen, fromVisible = Camera:WorldToViewportPoint(localChar.Head.Position)
    local toScreen, toVisible = Camera:WorldToViewportPoint(selectedTarget.Character.Head.Position)

    if fromVisible and toVisible then
        line.From, line.To = Vector2.new(fromScreen.X, fromScreen.Y), Vector2.new(toScreen.X, toScreen.Y)
        line.Visible = true
    else
        line.Visible = false
    end
end

local lastAmmoPerAmmoObject = {}

local function shoot(targetPlayer, ctx)
    local gun = getEquippedWeapon()
    if not gun then return end
    local ammo = gun:FindFirstChild("Ammo")
    if not ammo then return end
    if lastAmmoPerAmmoObject[ammo] == nil then lastAmmoPerAmmoObject[ammo] = ammo.Value end

    local char = targetPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not head or not root then return end

    local predicted = head.Position
    if ctx:GetSetting("Resolver") then
        local v = root.Velocity
        predicted = head.Position + (Vector3.new(v.X, 0, v.Z).Unit * (v.Magnitude * 0.12))
    end

    local muzzle = gun:FindFirstChild("Muzzle") or (gun:FindFirstChild("Main") and gun.Main:FindFirstChild("Front"))
    gun.Communication:FireServer({ { head, predicted, CFrame.new() } }, { head }, true)

    if ammo.Value == lastAmmoPerAmmoObject[ammo] then return end
    lastAmmoPerAmmoObject[ammo] = ammo.Value

    if muzzle then
        local attach = muzzle:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", muzzle)
        create3DTracer(attach, predicted)
    end
end

local function stomp(targetPlayer)
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("Stomp"):InvokeServer(targetPlayer.Character)
end

local function blockShoot(_, state)
    if state == Enum.UserInputState.Begin and getEquippedWeapon() and (randomTarget or selectedTarget) then
        isShooting = true
        return Enum.ContextActionResult.Sink
    end
    return Enum.ContextActionResult.Pass
end

local function getKeyCode(bind)
    return (bind and bind.kind == "KeyCode") and bind.code or nil
end

local _connections = {}

return {
    Name = "SilentAim",
    Desc = "Автоматическая стрельба и спектэйт",
    Class = "Combat",
    Category = "Combat",

    Settings = {
        { Type = "Boolean", Name = "Anti Interaction", Default = false },
        { Type = "BindSetting", Name = "Select Target", Default = { kind = "KeyCode", code = Enum.KeyCode.H } },
        { Type = "BindSetting", Name = "Spectate Target", Default = { kind = "KeyCode", code = Enum.KeyCode.V } },
        { Type = "BindSetting", Name = "Auto Stomp", Default = { kind = "KeyCode", code = Enum.KeyCode.N } },
        { Type = "Boolean", Name = "Reset Target On Death", Default = false },
        { Type = "Boolean", Name = "Resolver", Default = false },
    },

    OnEnable = function(ctx)
        ContextActionService:BindAction("BlockShoot", blockShoot, false, Enum.UserInputType.MouseButton1)

        _connections.InputBegan = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end

            local selectBind = getKeyCode(ctx:GetSetting("Select Target"))
            local stompBind = getKeyCode(ctx:GetSetting("Auto Stomp"))
            local spectateBind = getKeyCode(ctx:GetSetting("Spectate Target"))

            local currentTarget = selectedTarget or randomTarget

            if selectBind and input.KeyCode == selectBind then
                if selectedTarget then
                    selectedTarget = nil
                    if isSpectating then toggleSpectate() end
                    if line then line.Visible = false end
                else
                    selectedTarget = findNearestToMouse()
                end
            end

            if stompBind and input.KeyCode == stompBind and currentTarget then
                stomp(currentTarget)
            end

            if spectateBind and input.KeyCode == spectateBind then
                toggleSpectate(currentTarget)
            end
        end)

        _connections.InputEnded = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then isShooting = false end
        end)

        _connections.RenderStepped = RunService.RenderStepped:Connect(function()
            if selectedTarget then
                updateLine()
                randomTarget = nil
            else
                randomTarget = findNearestToMouse()
            end

            local target = selectedTarget or randomTarget
            if isShooting and target then
                shoot(target, ctx)
            end

            if isSpectating and (not target or not target.Character or not target.Character:FindFirstChild("Humanoid")) then
                toggleSpectate()
            end

            ProximityPromptService.Enabled = not ctx:GetSetting("Anti Interaction")
        end)

        _connections.CharAdded = LocalPlayer.CharacterAdded:Connect(function()
            if ctx:GetSetting("Reset Target On Death") then
                selectedTarget = nil
                if isSpectating then toggleSpectate() end
            end
        end)

        _connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
            if player == selectedTarget then
                selectedTarget = nil
                if isSpectating then toggleSpectate() end
            end
        end)
    end,

    OnDisable = function(ctx)
        ContextActionService:UnbindAction("BlockShoot")
        for _, conn in pairs(_connections) do conn:Disconnect() end
        _connections = {}

        if isSpectating then toggleSpectate() end
        if line then line:Remove() line = nil end
        isShooting = false
        selectedTarget = nil
        ProximityPromptService.Enabled = true
    end,
}