local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer

local randomTarget = nil
local selectedTarget = nil
local line = nil
local isShooting = false
local lastCFrame = nil

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
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(char.Head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude
                    if dist < closestDist then
                        closestDist = dist; closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function stomp(targetPlayer)
    if targetPlayer and targetPlayer.Character then
        game:GetService("ReplicatedStorage").RemoteEvents.Stomp:InvokeServer(targetPlayer.Character)
    end
end

local function updateLine()
    if not selectedTarget or not selectedTarget.Character or not selectedTarget.Character:FindFirstChild("Head") then
        if line then line.Visible = false end
        return
    end
    if not line then
        line = Drawing.new("Line")
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 2
    end
    local fromScreen, fromVisible = workspace.CurrentCamera:WorldToViewportPoint(LocalPlayer.Character.Head.Position)
    local toScreen, toVisible = workspace.CurrentCamera:WorldToViewportPoint(selectedTarget.Character.Head.Position)
    if fromVisible and toVisible then
        line.From = Vector2.new(fromScreen.X, fromScreen.Y)
        line.To = Vector2.new(toScreen.X, toScreen.Y)
        line.Visible = true
    else
        line.Visible = false
    end
end

return {
    Name = "SilentAim",
    Desc = "Автоматическая стрельба и помощь в наведении",
    Class = "Combat",
    Category = "Combat",

    Settings = {
        { Type = "Boolean", Name = "AntiBuy", Default = false },
        { Type = "Boolean", Name = "Wallbang Beta", Default = false },
        { Type = "BindSetting", Name = "Select Target Key", Default = { kind = "KeyCode", code = Enum.KeyCode.T } },
        { Type = "BindSetting", Name = "Stomp Key", Default = { kind = "KeyCode", code = Enum.KeyCode.V } },
    },

    OnEnable = function(self, ctx)
        self.Connections = {}

        table.insert(self.Connections, RunService.RenderStepped:Connect(function()
            ProximityPromptService.Enabled = not ctx:GetSetting("AntiBuy")

            if selectedTarget then
                updateLine()
                randomTarget = nil
            else
                if line then line.Visible = false end
                randomTarget = findNearestToMouse()
            end

            local target = selectedTarget or randomTarget
            if target and isShooting then
                local gun = getEquippedWeapon()
                if gun then
                    if ctx:GetSetting("Wallbang Beta") then
                        lastCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                        local targetPos = target.Character.Head.Position
                        local teleportPos = targetPos + (target.Character.HumanoidRootPart.CFrame.LookVector * -3.6) + Vector3.new(0, 4, 0)
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(teleportPos, targetPos)
                        gun.Communication:FireServer({{target.Character.Head, targetPos, CFrame.new()}}, {target.Character.Head}, true)
                        task.defer(function() RunService.RenderStepped:Wait() LocalPlayer.Character.HumanoidRootPart.CFrame = lastCFrame end)
                    else
                        gun.Communication:FireServer({{target.Character.Head, target.Character.Head.Position, CFrame.new()}}, {target.Character.Head}, true)
                    end
                end
            end
        end))

        table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end

            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isShooting = true
            end

            local targetBind = ctx:GetSetting("Select Target Key")
            if targetBind and input.KeyCode == targetBind.code then
                if selectedTarget then selectedTarget = nil else selectedTarget = findNearestToMouse() end
            end

            local stompBind = ctx:GetSetting("Stomp Key")
            if stompBind and input.KeyCode == stompBind.code then
                local target = selectedTarget or randomTarget
                if target then
                    stomp(target)
                end
            end
        end))

        table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isShooting = false
            end
        end))

        ContextActionService:BindAction("BlockShoot", function(_, state)
            if state == Enum.UserInputState.Begin and (selectedTarget or randomTarget) then
                return Enum.ContextActionResult.Sink
            end
            return Enum.ContextActionResult.Pass
        end, false, Enum.UserInputType.MouseButton1)
    end,

    OnDisable = function(self, ctx)
        isShooting = false
        selectedTarget = nil
        randomTarget = nil
        if line then line:Remove() line = nil end
        ProximityPromptService.Enabled = true
        if self.Connections then
            for _, c in ipairs(self.Connections) do c:Disconnect() end
            self.Connections = nil
        end
        ContextActionService:UnbindAction("BlockShoot")
    end,
}