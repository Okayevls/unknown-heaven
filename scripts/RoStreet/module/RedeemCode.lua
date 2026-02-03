local ReplicatedStorage = game:GetService("ReplicatedStorage")

return {
    Name = "RedeemCode",
    Desc = "Автоматически вводит все доступные коды игры",
    Class = "Utility",
    Category = "Utility",

    Settings = {},

    _codes = {
        "20MVISITS",
        "20KLIKES",
        "StarCity"
    },

    _findRemote = function(self)
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if obj.Name == "RedeemCode" and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                return obj
            end
        end
        return ReplicatedStorage:WaitForChild("RedeemCode", 5)
    end,

    OnEnable = function(self, ctx)
        local remote = self:_findRemote()

        if not remote then
            ctx.Logger:Error("RedeemCode: Remote 'RedeemCode' не найден!")
            ctx.moduleMgr:SetEnabled(self.Category, self.Name, false)
            return
        end

        task.spawn(function()
            local isFunction = remote:IsA("RemoteFunction")

            for _, code in ipairs(self._codes) do
                local currentState = ctx.moduleMgr:GetState(self.Category, self.Name)
                if not currentState or not currentState.Enabled then break end

                local success, result = pcall(function()
                    if isFunction then
                        return remote:InvokeServer(code)
                    else
                        remote:FireServer(code)
                    end
                end)

                if success then
                    ctx.Logger:Info("RedeemCode: Активирован код -> " .. code)
                else
                    ctx.Logger:Warn("RedeemCode: Ошибка кода " .. code .. ": " .. tostring(result))
                end

                task.wait(1)
            end

            ctx.moduleMgr:SetEnabled(self.Category, self.Name, false)
        end)
    end,

    OnDisable = function(self, ctx)

    end,
}