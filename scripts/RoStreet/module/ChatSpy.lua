local TextChatService = game:GetService("TextChatService")
local GetStartState = false

return {
    Name = "ChatSpy",
    Desc = "Вы можете подглядывать за отключенным чатом",
    Class = "Player",
    Category = "Utility",

    Settings = {},

    OnEnable = function(ctx)
        GetStartState = TextChatService.ChatWindowConfiguration.Enabled
        TextChatService.ChatWindowConfiguration.Enabled = true

        if ctx.Shared.Notify then
            ctx.Shared.Notify("Module System", ctx.Name.." was enabled!")
        end
    end,

    OnDisable = function(ctx)
        TextChatService.ChatWindowConfiguration.Enabled = GetStartState
        ctx.Shared.Notify("Module System", ctx.Name.." was disabled!")
    end,
}