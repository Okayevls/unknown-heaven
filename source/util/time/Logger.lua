if getgenv().LoggerInstance then
   return getgenv().LoggerInstance
end

local Logger = {}
Logger.__index = Logger

function Logger.new(prefix: string)
   if getgenv().DefaultLogger then
   return getgenv().DefaultLogger
end

local self = setmetatable({}, Logger)
self.prefix = prefix or "[System]"

getgenv().DefaultLogger = self
   return self
end

function Logger:Info(msg: string)
   print(string.format("%s (INFO): %s", self.prefix, msg))
end

function Logger:Warn(msg: string)
   warn(string.format("%s (WARN): %s", self.prefix, msg))
end

function Logger:Error(msg: string)
   warn(string.format("%s (CRITICAL): %s", self.prefix, msg))
end

function Logger:LogLoading(index: number, path: string)
   local fileName = path:match("([^/]+)$") or path
   self:Info(string.format("  [%d] -> Loading: %s", index, fileName))
end

getgenv().LoggerInstance = Logger
return Logger