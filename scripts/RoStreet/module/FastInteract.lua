local  _connections = {}
local _originalDurations = {}

function _makeInstant(prompt)
   if prompt:IsA("ProximityPrompt") then
       if _originalDurations[prompt] == nil then
           _originalDurations[prompt] = prompt.HoldDuration
       end
       prompt.HoldDuration = 0
   end
end

return {
    Name = "FastInteract",
    Desc = "Убирает задержку (HoldDuration) у всех ProximityPrompt",
    Class = "Player",
    Category = "Utility",

    Settings = {},

    OnEnable = function(ctx)
        for _, v in ipairs(workspace:GetDescendants()) do
            _makeInstant(v)
        end

        local conn = workspace.DescendantAdded:Connect(function(obj)
            _makeInstant(obj)
        end)

        table.insert(_connections, conn)
    end,

    OnDisable = function(ctx)
        for _, conn in ipairs(_connections) do
            if conn.Disconnect then
                conn:Disconnect()
            end
        end
        _connections = {}

        for prompt, originalValue in pairs(_originalDurations) do
            if prompt and prompt.Parent then
                prompt.HoldDuration = originalValue
            end
        end
        _originalDurations = {}
    end,
}