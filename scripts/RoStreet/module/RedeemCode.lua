local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RedeemRemote = nil
local isFunction = false
local connectionRenderStepped = nil

local CODES = {
    "HAPPYNEWYEAR2026",
    "25MVISITS",
    "25KLIKES",
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

    OnEnable = function(ctx)
        connectionRenderStepped = RunService.RenderStepped:Connect(function()
            if not RedeemRemote then
                if not findRemote() then
                    warn("Remote not found!")
                    ctx:SetEnabled(false)
                    return
                end
            end

            for _, code in ipairs(CODES) do
                redeem(code)
                print(code)
                wait(1)
            end

            ctx:SetEnabled(false)
        end)
    end,

    OnDisable = function(ctx)

    end,
}