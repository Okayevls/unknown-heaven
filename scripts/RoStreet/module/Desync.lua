local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local desync_setback = Instance.new("Part")
desync_setback.Name = "dsHv4"
desync_setback.Size = Vector3.new(2, 2, 1)
desync_setback.CanCollide = false
desync_setback.Anchored = true
desync_setback.Transparency = 1

local desync = {
    teleportPosition = Vector3.new(0, 0, 0),
    old_position = nil
}

local function resetCamera()
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        workspace.CurrentCamera.CameraSubject = humanoid
    end
end

local function getGroundLevel()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return 0 end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char, desync_setback}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local currentOrigin = root.Position
    local result = workspace:Raycast(currentOrigin, Vector3.new(0, -10000, 0), rayParams)
    if result then
        local legOffset = (root.Size.Y / 2) + humanoid.HipHeight
        return result.Position.Y + legOffset
    end

    return root.Position.Y
end

local _connections = {}
local flickDuration = 0.05
local minWait, maxWait = 1, 3
local nextFlick = tick() + math.random(minWait, maxWait)
local isFlicking = false
local flickEnd = 0
local backGroundY = 0

return {
    Name = "Desync",
    Desc = "Манипуляция позицией для защиты от Silent Aim",
    Class = "Movement",
    Category = "Movement",

    Settings = {
        { Type = "ModeSetting", Name = "Mode", Default = "Step", Options = {"Step"} },
        { Type = "Slider", Name = "MaxY", Default = 1000000, Min = 35000, Max = 1000000, Step = 5000 },
        { Type = "Slider", Name = "MinY", Default = 30000, Min = 5000, Max = 30000, Step = 5000 },
        { Type = "Boolean", Name = "Calculate Ground", Default = false },
        { Type = "Slider", Name = "TickYBack", Default = 10, Min = 1, Max = 1000, Step = 2 },
    },

    OnEnable = function(ctx)
        desync_setback.Parent = workspace

        if ctx:GetSetting("Mode") == "Step" then
            table.insert(_connections, RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                local rootPart = char and char:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end

                local currentTime = tick()
                if not isFlicking and currentTime >= nextFlick then
                    isFlicking = true
                    flickEnd = currentTime + flickDuration
                end

                desync.old_position = rootPart.CFrame
                local randomY = math.random(ctx:GetSetting("MinY"), ctx:GetSetting("MaxY"))
                local randomOffset = Vector3.new(rootPart.Position.X, randomY, rootPart.Position.Z)

                if isFlicking then
                    local groundY = ctx:GetSetting("Calculate Ground") and getGroundLevel() or rootPart.Position.Y
                    desync.teleportPosition = Vector3.new(rootPart.Position.X, groundY, rootPart.Position.Z)
                    if currentTime >= flickEnd then
                        isFlicking = false
                        nextFlick = currentTime + math.random(minWait, maxWait)
                    end
                else
                    desync.teleportPosition = randomOffset
                end

                local isSpectating = ctx.SharedTrash and ctx.SharedTrash.IsSpectating

                if not isSpectating then
                    rootPart.CFrame = CFrame.new(desync.teleportPosition)
                    workspace.CurrentCamera.CameraSubject = desync_setback

                    RunService.RenderStepped:Wait()

                    desync_setback.CFrame = desync.old_position * CFrame.new(0, rootPart.Size.Y / 2 + 0.5, 0)
                    rootPart.CFrame = desync.old_position
                else
                    rootPart.CFrame = CFrame.new(desync.teleportPosition)

                    RunService.Heartbeat:Wait()

                    rootPart.CFrame = desync.old_position
                end

                if rootPart.Position.Y > ctx:GetSetting("MinY") - ctx:GetSetting("TickYBack") then
                    local ground = (backGroundY ~= 0) and backGroundY or getGroundLevel()
                    rootPart.CFrame = CFrame.new(rootPart.Position.X, ground, rootPart.Position.Z)
                    desync.teleportPosition = Vector3.new(rootPart.Position.X, ground, rootPart.Position.Z)
                else
                    backGroundY = getGroundLevel()
                end
            end))

            if ctx.SharedTrash and not ctx.SharedTrash.IsSpectating then
                workspace.CurrentCamera.CameraSubject = desync_setback
            end
        end
    end,

    OnDisable = function(ctx)
        for _, conn in ipairs(_connections) do
            if conn then conn:Disconnect() end
        end
        _connections = {}
        desync_setback.Parent = nil

        resetCamera()
        if ctx.SharedTrash then
            ctx.SharedTrash.IsSpectating = false
        end
    end,
}