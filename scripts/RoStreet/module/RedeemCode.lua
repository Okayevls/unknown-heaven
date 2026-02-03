local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RedeemRemote = nil
local isFunction = false

local CODES = {
    "20MVISITS",
    "20KLIKES",
    "StarCity"
}

local redeemed = {}
for _, code in ipairs(CODES) do
    redeemed[code] = false
end

local function findRemote()
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == "RedeemCode" and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            RedeemRemote = obj
            isFunction = obj:IsA("RemoteFunction")
            return true
        end
    end
    RedeemRemote = ReplicatedStorage:WaitForChild("RedeemCode", 10)
    if RedeemRemote then
        isFunction = RedeemRemote:IsA("RemoteFunction")
        return true
    end
    return false
end

local function redeem(code)
    if redeemed[code] then return end
    if not RedeemRemote then return end

    local success, result = pcall(function()
        if isFunction then
            return RedeemRemote:InvokeServer(code)
        else
            RedeemRemote:FireServer(code)
        end
    end)

    if success then
        redeemed[code] = true
    end
end

return {
    Name = "RedeemCode",
    Desc = "Автоматически вводит все доступные коды игры",
    Class = "Utility",
    Category = "Utility",

    Settings = {},

    OnEnable = function(self, ctx)
        task.spawn(function()
            if not RedeemRemote then
                if not findRemote() then
                    self.Enabled = false

                    if self._Switch then
                        self._Switch.Value = false
                    end
                    return
                end
            end

            for _, code in ipairs(CODES) do
                redeem(code)
                print(code)
                task.wait(1)
            end

            getgenv().ctx.moduleMgr:SetEnabled(self.Category, self.Name, false)
        end)
    end,

    OnDisable = function(self, ctx)

    end,
}