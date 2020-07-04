#include <amxmodx>
#include <TelegramBotAPI>

#pragma semicolon 1
#pragma ctrlchar '\'

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