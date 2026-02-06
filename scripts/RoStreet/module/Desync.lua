local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local desync_setback = Instance.new("Part")
desync_setback.Name = "dsHv4"
desync_setback.Parent = workspace
desync_setback.Size = Vector3.new(2, 2, 1)
desync_setback.CanCollide = false
desync_setback.Anchored = true
desync_setback.Transparency = 1

local desync = {
    teleportPosition = Vector3.new(0, 0, 0),
    old_position = nil
}

local function resetCamera()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
        end
    end
end

local function getGroundLevel()
    local char = game.Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return nil end

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = false
    rayParams.RespectCanCollide = true

    local currentOrigin = root.Position
    local traveled = 0
    local maxDistance = 1e5

    while traveled < maxDistance do
        local result = workspace:Raycast(currentOrigin, Vector3.new(0, -5000, 0), rayParams)

        if result then
            local legOffset = (root.Size.Y / 2) + humanoid.HipHeight
            return result.Position.y + legOffset
        end

        currentOrigin = currentOrigin - Vector3.new(0, 5000, 0)
        traveled = traveled + 5000
    end

    return root.Position.y
end

local _connections = {}

local flickDuration = 0.05
local minWait = 1
local maxWait = 3
local nextFlick = tick() + math.random(minWait, maxWait)
local isFlicking = false
local flickEnd = 0
local backGroundY = 0
return {
    Name = "Desync",
    Desc = "Дает огромнейшие преимущество над игроками",
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
        if ctx:GetSetting("Mode") == "Step" then
            table.insert(_connections, RunService.Heartbeat:Connect(function()
                if LocalPlayer.Character then
                    local currentTime = tick()
                    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not isFlicking and currentTime >= nextFlick then
                        isFlicking = true
                        flickEnd = currentTime + flickDuration
                    end
                    local forceGround = ctx.SharedTrash and ctx.SharedTrash.IsFiring
                    if rootPart then
                        desync.old_position = rootPart.CFrame

                        local randomOffset = Vector3.new(rootPart.Position.x, math.random(ctx:GetSetting("MinY"), ctx:GetSetting("MaxY")), rootPart.Position.z)
                        if isFlicking or forceGround then
                            local groundY = ctx:GetSetting("Calculate Ground") and getGroundLevel() or rootPart.Position.y
                            desync.teleportPosition = Vector3.new(rootPart.Position.x,  groundY, rootPart.Position.z)
                            if currentTime >= flickEnd then
                                isFlicking = false
                                nextFlick = currentTime + math.random(minWait, maxWait)
                            end
                        else
                            desync.teleportPosition = randomOffset
                        end

                        rootPart.CFrame = CFrame.new(desync.teleportPosition)
                        workspace.CurrentCamera.CameraSubject = desync_setback

                        RunService.RenderStepped:Wait()

                        desync_setback.CFrame = desync.old_position * CFrame.new(0, rootPart.Size.Y / 2 + 0.5, 0)

                        rootPart.CFrame = desync.old_position

                        if rootPart.Position.Y > ctx:GetSetting("MinY") - ctx:GetSetting("TickYBack") then
                            local ground = backGroundY
                            rootPart.CFrame = CFrame.new(rootPart.Position.X, ground, rootPart.Position.Z)
                            desync.teleportPosition = Vector3.new(rootPart.Position.X, ground, rootPart.Position.Z)
                        else
                            backGroundY = getGroundLevel()
                        end
                    end
                end
            end))
            workspace.CurrentCamera.CameraSubject = desync_setback
        end
    end,

    OnDisable = function(ctx)
        if ctx:GetSetting("Mode") == "Step" then
            for _, conn in ipairs(_connections) do
                conn:Disconnect()
            end
            _connections = {}
            resetCamera()
        end
    end,
}