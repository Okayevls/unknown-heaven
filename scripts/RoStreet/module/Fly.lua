local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local character, hum, hrp
local keys = {W=false, A=false, S=false, D=false, Space=false, LeftControl=false}
local connectionRenderStepped = nil
local connectionUserInputService = nil
local connectionUserInputEnded = nil


return {
    Name = "Fly",
    Desc = "Позволяет свободно летать по карте",
    Class = "Movement",
    Category = "Movement",

    Settings = {
        { Type = "Slider", Name = "MultiplierXYZ", Default = 1.5, Min = 0.1, Max = 10, Step = 0.05 },
    },

    OnEnable = function(ctx)
        local multiplier = ctx:GetSetting("MultiplierXYZ")
        local character = player.Character or player.CharacterAdded:Wait()
        local hum = character:WaitForChild("Humanoid")
        local hrp = character:WaitForChild("HumanoidRootPart")

        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        connectionRenderStepped = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            local dir = Vector3.zero
            if keys.W then dir += cam.CFrame.LookVector end
            if keys.S then dir -= cam.CFrame.LookVector end
            if keys.A then dir -= cam.CFrame.RightVector end
            if keys.D then dir += cam.CFrame.RightVector end
            if keys.Space then dir += Vector3.new(0,1,0) end
            if keys.LeftControl then dir -= Vector3.new(0,1,0) end
            if dir.Magnitude > 0 then dir = dir.Unit end
            hrp.CFrame = CFrame.new(hrp.Position + dir * multiplier, hrp.Position + dir * multiplier + cam.CFrame.LookVector)
            hrp.Velocity = Vector3.zero
        end)

        connectionUserInputService = UserInputService.InputBegan:Connect(function(input, processed)
            local kc = input.KeyCode
            if kc == Enum.KeyCode.W then keys.W = true
            elseif kc == Enum.KeyCode.A then keys.A = true
            elseif kc == Enum.KeyCode.S then keys.S = true
            elseif kc == Enum.KeyCode.D then keys.D = true
            elseif kc == Enum.KeyCode.Space then keys.Space = true
            elseif kc == Enum.KeyCode.LeftControl then keys.LeftControl = true
            end
        end)

        connectionUserInputEnded = UserInputService.InputEnded:Connect(function(input)
            local kc = input.KeyCode
            if kc == Enum.KeyCode.W then keys.W = false end
            if kc == Enum.KeyCode.A then keys.A = false end
            if kc == Enum.KeyCode.S then keys.S = false end
            if kc == Enum.KeyCode.D then keys.D = false end
            if kc == Enum.KeyCode.Space then keys.Space = false end
            if kc == Enum.KeyCode.LeftControl then keys.LeftControl = false end
        end)
    end,

    OnDisable = function(ctx)
        local character = player.Character or player.CharacterAdded:Wait()
        local hum = character:WaitForChild("Humanoid")

        if connectionRenderStepped then connectionRenderStepped:Disconnect() connectionRenderStepped = nil end
        if connectionUserInputService then connectionUserInputService:Disconnect() connectionUserInputService = nil end
        if connectionUserInputEnded then connectionUserInputEnded:Disconnect() connectionUserInputEnded = nil end
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end,
}