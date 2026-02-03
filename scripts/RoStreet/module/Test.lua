local TextChatService = game:GetService("TextChatService")

return {
    Name = "ChatSpy",
    Desc = "Вы можете подглядывать за отключенным чатом",
    Class = "Player",
    Category = "Utility",

    Settings = {},

    OnEnable = function(ctx)
        TextChatService.ChatWindowConfiguration.Enabled = true
    end,

    OnDisable = function(ctx)
        TextChatService.ChatWindowConfiguration.Enabled = false
    end,
}