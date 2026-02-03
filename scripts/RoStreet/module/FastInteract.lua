return {
    Name = "FastInteract",
    Desc = "Убирает задержку (HoldDuration) у всех ProximityPrompt",
    Class = "Player",
    Category = "Utility",

    Settings = {},

    _connections = {},
    _originalDurations = {},

    _makeInstant = function(self, prompt)
        if prompt:IsA("ProximityPrompt") then
            if not self._originalDurations[prompt] then
                self._originalDurations[prompt] = prompt.HoldDuration
            end
            prompt.HoldDuration = 0
        end
    end,

    OnEnable = function(self, ctx)
        for _, v in ipairs(workspace:GetDescendants()) do
            self:_makeInstant(v)
        end

        local conn = workspace.DescendantAdded:Connect(function(obj)
            self:_makeInstant(obj)
        end)

        table.insert(self._connections, conn)
    end,

    OnDisable = function(self, ctx)
        for _, conn in ipairs(self._connections) do
            if conn.Disconnect then
                conn:Disconnect()
            end
        end
        self._connections = {}

        for prompt, originalValue in pairs(self._originalDurations) do
            if prompt and prompt.Parent then
                prompt.HoldDuration = originalValue
            end
        end

        self._originalDurations = {}
    end,
}