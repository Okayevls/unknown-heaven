local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RedeemRemote = nil
local isFunction = false
local connectionRenderStepped = nil
local running = false

local CODES = { "HAPPYNEWYEAR2026", "25MVISITS", "25KLIKES", "StarCity" }

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
        if running then return end
        running = true

        if connectionRenderStepped then
            connectionRenderStepped:Disconnect()
            connectionRenderStepped = nil
        end

        connectionRenderStepped = RunService.RenderStepped:Connect(function()
            if connectionRenderStepped then
                connectionRenderStepped:Disconnect()
                connectionRenderStepped = nil
            end

            task.spawn(function()
                if not findRemote() then
                    warn("Remote not found!")
                    running = false
                    ctx:SetEnabled(false)
                    return
                end

                for _, code in ipairs(CODES) do
                    if not running then break end

                    local ok = redeem(code)
                    if ok then
                        print("Redeemed:", code)
                    else
                        warn("Failed:", code)
                    end

                    task.wait(1)
                end

                running = false
                ctx:SetEnabled(false)
            end)
        end)
    end,

    OnDisable = function(ctx)
        running = false
        if connectionRenderStepped then
            connectionRenderStepped:Disconnect()
            connectionRenderStepped = nil
        end
    end,
}