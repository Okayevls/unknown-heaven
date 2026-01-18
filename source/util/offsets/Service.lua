local Service = {}
Service.__index = Service

local _cache = {}

local function get(name: string)
   local svc = _cache[name]
   if svc then return svc end

   svc = game:GetService(name)
   _cache[name] = svc
   return svc w
end

setmetatable(Service, {
  __index = function(_, key)
      return get(key)
  end,
})

Service.Players = get("Players")
Service.RunService = get("RunService")
Service.ReplicatedStorage = get("ReplicatedStorage")
Service.ServerStorage = get("ServerStorage")
Service.ServerScriptService = get("ServerScriptService")
Service.StarterGui = get("StarterGui")
Service.StarterPlayer = get("StarterPlayer")
Service.StarterPack = get("StarterPack")
Service.TweenService = get("TweenService")
Service.UserInputService = get("UserInputService")
Service.ContextActionService = get("ContextActionService")
Service.HttpService = get("HttpService")
Service.TextService = get("TextService")
Service.SoundService = get("SoundService")
Service.Lighting = get("Lighting")
Service.Workspace = get("Workspace")
Service.CollectionService = get("CollectionService")
Service.TeleportService = get("TeleportService")
Service.MarketplaceService = get("MarketplaceService")
Service.GuiService = get("GuiService")
Service.PathfindingService = get("PathfindingService")
Service.Debris = get("Debris")
Service.InsertService = get("InsertService")
Service.GroupService = get("GroupService")
Service.LocalizationService = get("LocalizationService")
Service.Stats = get("Stats")

function Service:Get(name: string)
   return get(name)
end

function Service:Dump()
   local out = {}
   for k, v in pairs(_cache) do
      out[#out + 1] = { Name = k, Service = v }
   end
   table.sort(out, function(a, b) return a.Name < b.Name end)
   return out
end

return Service
