local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

return {
    Name = "Fly",
    Desc = "Позволяет свободно летать по карте",
    Class = "Movement",
    Category = "Movement",

    Settings = {
        { Type = "Slider", Name = "Fly Speed", Default = 1.5, Min = 0.1, Max = 10, Step = 0.05 },
    },

    _keys = {W = false, A = false, S = false, D = false, Space = false, LShift = false},
    _connection = nil,
    _inputBegan = nil,
    _inputEnded = nil,

    OnEnable = function(self, ctx)
        local player = Players.LocalPlayer

        self._keys = {W = false, A = false, S = false, D = false, Space = false, LShift = false}

        self._inputBegan = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            local kc = input.KeyCode
            if kc == Enum.KeyCode.W then self._keys.W = true
            elseif kc == Enum.KeyCode.A then self._keys.A = true
            elseif kc == Enum.KeyCode.S then self._keys.S = true
            elseif kc == Enum.KeyCode.D then self._keys.D = true
            elseif kc == Enum.KeyCode.Space then self._keys.Space = true
            elseif kc == Enum.KeyCode.LeftShift then self._keys.LShift = true
            end
        end)

        self._inputEnded = UserInputService.InputEnded:Connect(function(input)
            local kc = input.KeyCode
            if kc == Enum.KeyCode.W then self._keys.W = false
            elseif kc == Enum.KeyCode.A then self._keys.A = false
            elseif kc == Enum.KeyCode.S then self._keys.S = false
            elseif kc == Enum.KeyCode.D then self._keys.D = false
            elseif kc == Enum.KeyCode.Space then self._keys.Space = false
            elseif kc == Enum.KeyCode.LeftShift then self._keys.LShift = false
            end
        end)

        self._connection = RunService.RenderStepped:Connect(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")

            if hrp and hum then
                hum:ChangeState(Enum.HumanoidStateType.Physics)

                local cam = workspace.CurrentCamera
                local speed = ctx:GetSetting("Fly Speed")
                local dir = Vector3.zero

                if self._keys.W then dir += cam.CFrame.LookVector end
                if self._keys.S then dir -= cam.CFrame.LookVector end
                if self._keys.A then dir -= cam.CFrame.RightVector end
                if self._keys.D then dir += cam.CFrame.RightVector end
                if self._keys.Space then dir += Vector3.new(0, 1, 0) end
                if self._keys.LShift then dir -= Vector3.new(0, 1, 0) end

                if dir.Magnitude > 0 then
                    dir = dir.Unit
                    hrp.CFrame = CFrame.new(hrp.Position + dir * speed, hrp.Position + dir * speed + cam.CFrame.LookVector)
                end

                hrp.Velocity = Vector3.zero
            end
        end)
    end,

    OnDisable = function(self, ctx)
        if self._connection then self._connection:Disconnect() end
        if self._inputBegan then self._inputBegan:Disconnect() end
        if self._inputEnded then self._inputEnded:Disconnect() end

        local char = Players.LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end,
}