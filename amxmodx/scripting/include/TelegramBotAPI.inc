#if defined _telegram_bot_api_included
	#endinput
#endif
#define _telegram_bot_api_included

#pragma reqlib telegram_bot_api
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib telegram_bot_api
#endif


/*
 * CallBack: public BotRegistred(const botID, const botName[]) { }
 */
native TG_RegisterBot(const token[], const callBack[]);
/*
 * CallBack: public BotSubscriptionAdded(const subscriptionID, const botID, const chatID, const chatTitle[], const chatType[]) { }
 */
native TG_BotAddSubscription(const botID, const chatID[], const callBack[]);
/*
 * @noreturn
 */
native TG_BotSendMessageALL(const botID, const message[]);
/*
 * @noreturn
 */
native TG_BotSendMessage(const botID, const chatUD[], const message[]);
/*
 * return bool;
 */
native bool: TG_BotAPI_Allowed();

forward TG_BotAPI_Initialized();
