# [Telegram BOT API](https://core.telegram.org/api) wrapper library for [AMXModX](github.com/alliedmodders/amxmodx) plugins.

Requirments:
- [GoldSrc RestInPawn module](https://github.com/In-line/grip)

Include file API: [TelegramBotAPI.inc](https://github.com/wopox1337/AMXX_TelegramBotAPI/blob/master/amxmodx/scripting/include/TelegramBotAPI.inc)

* Create telegram bot: [LINK](https://core.telegram.org/bots#6-botfather)
* Get bot_token: [LINK](https://www.google.com/search?q=how+to+get+bot+token+telegram&oq=How+to+get+bot+token)
* Get chat_id: [LINK](https://www.google.com/search?q=how+to+get+telegram+%22chat_id)

Usage example:
```C
#include <amxmodx>
#include <TelegramBotAPI>

new const BOT_TOKEN[] = " ENTER YOU KEY HERE ";

// Chats ID configuration.
new const CHATS[][] = {
    "207444577"
    ,"-1001431316463"
};

new g_botID;

public plugin_init() {
    register_plugin("[Example plugin] Send server startup to TG", "1.0.0", "Sergey Shorokhov");
}

public TG_BotAPI_Initialized() {
    TG_RegisterBot(BOT_TOKEN, "BotRegistred");
}

public BotRegistred(const botID, const botName[]) {
    g_botID = botID;
    for(new i; i < sizeof CHATS; i++) {
        TG_BotAddSubscription(botID, CHATS[i], "BotSubscriptionAdded");
    }
}

public BotSubscriptionAdded(const subscriptionID, const botID, const chatID[], const chatTitle[], const chatType[]) {
    
}

public OnConfigsExecuted() {
    if(!TG_BotAPI_Allowed())
        return;

    TG_BotSendMessageALL(g_botID, "[Server startup] - TG_BotSendMessageALL");
    //TG_BotSendMessage(g_botID, "-1001431316463", "[Server startup] - TG_BotSendMessage");
}
```
