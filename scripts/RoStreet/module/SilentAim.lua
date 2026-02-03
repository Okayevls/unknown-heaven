local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
    Name = "SilentAim",
    Desc = "Автоматическая стрельба и помощь в наведении",
    Class = "Combat",
    Category = "Combat",

    Settings = {
        { Type = "Boolean", Name = "Auto Stomp", Default = false },
        { Type = "Boolean", Name = "Anti Buy", Default = false },
        { Type = "Boolean", Name = "Wallbang Beta", Default = false },
    },

    _selectedTarget = nil,
    _isShooting = false,
    _line = nil,
    _connections = {},
    _supportedWeapons = {
        ["AW1"] = true, ["Ak"] = true, ["Barrett"] = true, ["Deagle"] = true,
        ["Double Barrel"] = true, ["Draco"] = true, ["Glock"] = true,
        ["Heli"] = true, ["M249"] = true, ["M37"] = true, ["M4"] = true,
        ["Micro Uzi"] = true, ["Rpg"] = true, ["Silencer"] = true,
        ["Spas"] = true, ["Taser"] = true, ["Tec"] = true, ["Ump"] = true
    },

    _getWeapon = function(self)
        local char = Players.LocalPlayer.Character
        if not char then return nil end
        for name, _ in pairs(self._supportedWeapons) do
            local w = char:FindFirstChild(name)
            if w and w:FindFirstChild("Communication") then return w end
        end
        return nil
    end,

    _getClosest = function(self)
        local mouse = UserInputService:GetMouseLocation()
        local closest, dist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if d < dist then dist = d; closest = p end
                end
            end
        end
        return closest
    end,

    _updateLine = function(self, target)
        if not target or not target.Character then
            if self._line then self._line.Visible = false end
            return
        end

        if not self._line then
            self._line = Drawing.new("Line")
            self._line.Thickness = 2
            self._line.Transparency = 1
        end

        local lchar = Players.LocalPlayer.Character
        local tchar = target.Character
        if not lchar or not tchar or not tchar:FindFirstChild("Head") then
            self._line.Visible = false
            return
        end

        local from, fVis = workspace.CurrentCamera:WorldToViewportPoint(lchar.Head.Position)
        local to, tVis = workspace.CurrentCamera:WorldToViewportPoint(tchar.Head.Position)

        if fVis and tVis then
            self._line.From = Vector2.new(from.X, from.Y)
            self._line.To = Vector2.new(to.X, to.Y)
            self._line.Color = Color3.fromRGB(140, 200, 255)
            self._line.Visible = true
        else
            self._line.Visible = false
        end
    end,

    OnEnable = function(self, ctx)
        local lp = Players.LocalPlayer

        ContextActionService:BindAction("HeavenSilentShoot", function(_, state)
            if state == Enum.UserInputState.Begin and self:_getWeapon() then
                self._isShooting = true
                return Enum.ContextActionResult.Sink
            elseif state == Enum.UserInputState.End then
                self._isShooting = false
            end
            return Enum.ContextActionResult.Pass
        end, false, Enum.UserInputType.MouseButton1)

        table.insert(self._connections, RunService.RenderStepped:Connect(function()
            local target = self._selectedTarget or self:_getClosest()
            self:_updateLine(target)

            if target and self._isShooting then
                local weapon = self:_getWeapon()
                if weapon then
                    local tHead = target.Character:FindFirstChild("Head")
                    if tHead then
                        local wallbang = ctx:GetSetting("Wallbang Beta")
                        if wallbang then
                            local hrp = lp.Character.HumanoidRootPart
                            local oldCF = hrp.CFrame
                            hrp.CFrame = tHead.CFrame * CFrame.new(0, 0, 3)
                            weapon.Communication:FireServer({{tHead, tHead.Position, CFrame.new()}}, {tHead}, true)
                            RunService.RenderStepped:Wait()
                            hrp.CFrame = oldCF
                        else
                            weapon.Communication:FireServer({{tHead, tHead.Position, CFrame.new()}}, {tHead}, true)
                        end
                    end
                end
            end

            if ctx:GetSetting("Auto Stomp") and target and target.Character then
                local stompEv = ReplicatedStorage:WaitForChild("RemoteEvents", 1):WaitForChild("Stomp", 1)
                if stompEv then stompEv:InvokeServer(target.Character) end
            end

            ProximityPromptService.Enabled = not ctx:GetSetting("Anti Buy")
        end))
    end,

    OnDisable = function(self, ctx)
        ContextActionService:UnbindAction("HeavenSilentShoot")
        for _, c in ipairs(self._connections) do c:Disconnect() end
        self._connections = {}
        self._isShooting = false
        self._selectedTarget = nil

        if self._line then
            self._line.Visible = false
            self._line:Remove()
            self._line = nil
        end

        ProximityPromptService.Enabled = true
    end,
}