local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local character, hum, hrp
local keys = {W=false, A=false, S=false, D=false, Space=false, LeftControl=false}
local connectionRenderStepped = nil
local connectionUserInputService = nil
local connectionUserInputEnded = nil

local function resetKeys()
    for k in pairs(keys) do
        keys[k] = false
    end
end

return {
    Name = "Fly",
    Desc = "Позволяет свободно летать по карте",
    Class = "Movement",
    Category = "Movement",

    Settings = {
        { Type = "Slider", Name = "MultiplierXYZ", Default = 1.5, Min = 0.1, Max = 10, Step = 0.05 },
    },

    OnEnable = function(ctx)
        local character = player.Character
        if not character then return end

        local hum = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp or not hum then return end

        connectionRenderStepped = RunService.RenderStepped:Connect(function()
            if not hrp or not hrp.Parent then
                hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
            end

            local multiplier = ctx:GetSetting("MultiplierXYZ")
            local cam = workspace.CurrentCamera
            local dir = Vector3.zero

            if keys.W then dir += cam.CFrame.LookVector end
            if keys.S then dir -= cam.CFrame.LookVector end
            if keys.A then dir -= cam.CFrame.RightVector end
            if keys.D then dir += cam.CFrame.RightVector end
            if keys.Space then dir += Vector3.new(0, 1, 0) end
            if keys.LeftControl then dir -= Vector3.new(0, 1, 0) end

            if dir.Magnitude > 0 then
                dir = dir.Unit
            end

            hrp.CFrame = CFrame.new(hrp.Position + dir * multiplier, hrp.Position + dir * multiplier + cam.CFrame.LookVector)
            hrp.Velocity = Vector3.zero

            hum:ChangeState(Enum.HumanoidStateType.Physics)
        end)

        connectionInputBegan = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            local kc = input.KeyCode
            if keys[kc.Name] ~= nil then
                keys[kc.Name] = true
            end
        end)

        connectionInputEnded = UserInputService.InputEnded:Connect(function(input)
            local kc = input.KeyCode
            if keys[kc.Name] ~= nil then
                keys[kc.Name] = false
            end
        end)
    end,

    OnDisable = function(ctx)
        if connectionRenderStepped then connectionRenderStepped:Disconnect() connectionRenderStepped = nil end
        if connectionInputBegan then connectionInputBegan:Disconnect() connectionInputBegan = nil end
        if connectionInputEnded then connectionInputEnded:Disconnect() connectionInputEnded = nil end

        resetKeys()

        local character = player.Character
        if character then
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end,
}