#include <amxmodx>
#include <grip>

#include <TelegramBotAPI>

#pragma semicolon 1
#pragma ctrlchar '\'
#pragma dynamic 524288


#define print(%1) server_print(%1)

new const URL_API[] = "https://api.telegram.org/";
new GripRequestOptions: g_pReqOptions;


new g_fwResult;
new g_fwAPI_Initialized;


enum APIState_s {
    m_Init = 123,
    m_RegisterBot,
    m_BotSubscriptions,
    m_SendMessage,
    m_Ready
}

enum RequestData_s {
    APIState_s: rd_state,
    rd_callBack[32],
    rd_token[64]
}

new bool: g_bInitialized;

enum BotData_s {
    bot_Name[64],
    bot_Token[64],
    Array:bot_Subscriptions
}
new Array:g_aBotsArray;

public plugin_precache() {
    register_plugin("Telegram Bot API", "1.0.0", "SergeyShorokhov");

    // Requests prepare
    g_pReqOptions = grip_create_default_options(.timeout = 30.0);
    grip_options_add_header(g_pReqOptions, "Content-Type", "application/json");

    // Test connect, initialize API
    new DataPack: reqData = CreateDataPack();
    WritePackCell(reqData, m_Init);
    ResetPack(reqData);

    new GripBody:body = grip_body_from_string("");
    grip_request(URL_API, body, GripRequestTypeGet, "HandleRequest", g_pReqOptions, reqData);
    grip_destroy_body(body);
}

    // *** Natives *** //
public plugin_natives() {
    register_library("telegram_bot_api");

    register_native("TG_RegisterBot", "native_RegisterBot");
    register_native("TG_BotAddSubscription", "native_BotAddSubscription");
    register_native("TG_BotSendMessageALL", "native_BotSendMessageALL");
    register_native("TG_BotSendMessage", "native_BotSendMessage");
    register_native("TG_BotAPI_Allowed", "native_BotAPI_Allowed");
}

public native_RegisterBot(pluginID, argc) {
    enum { arg_token = 1, arg_callBack };

    if(argc != 2) {
        log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 2, passed %d", argc);
        return 0;
    }

    if(!g_bInitialized) {
        log_error(AMX_ERR_NATIVE, "API not initialized!");
        return 0;
    }

    new botToken[64];
    get_string(arg_token, botToken, charsmax(botToken));

    new callBack[32];
    get_string(arg_callBack, callBack, charsmax(callBack));
    new funcID = get_func_id(callBack, pluginID);
    if(funcID == -1) {
        log_error(AMX_ERR_NATIVE, "Function `%s` not found!", callBack);
        return 0;
    }

    // Send req
    new DataPack: reqData = CreateDataPack();
    WritePackCell(reqData, m_RegisterBot);
    WritePackString(reqData, botToken);
    WritePackCell(reqData, funcID);
    WritePackCell(reqData, pluginID);
    ResetPack(reqData);

    new url[256];
    formatex(url, charsmax(url), "%sbot%s/getMe", URL_API, botToken);

    new GripBody:body = grip_body_from_string("");
    grip_request(url, body, GripRequestTypeGet, "HandleRequest", g_pReqOptions, reqData);
    grip_destroy_body(body);

    return 1;
}

public native_BotAddSubscription(pluginID, argc) {
    enum { arg_botID = 1, arg_chatID, arg_callBack };

    if(argc != 3) {
        log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 2, passed %d", argc);
        return -1;
    }

    if(!g_bInitialized) {
        log_error(AMX_ERR_NATIVE, "API not initialized!");
        return -1;
    }

    new registredBotsCount = ArraySize(g_aBotsArray);
    if(registredBotsCount < 1) {
        log_error(AMX_ERR_NATIVE, "Haven't registred bots.");
        return -1;
    }

    new botIndexEntry = get_param(arg_botID) - 1;
    if(botIndexEntry > registredBotsCount) {
        log_error(AMX_ERR_NATIVE, "TG Bot out of range (index:%i, max:%i)", botIndexEntry, registredBotsCount);
        return -1;
    }

    new chatID[64];
    get_string(arg_chatID, chatID, charsmax(chatID));

    new callBack[32];
    get_string(arg_callBack, callBack, charsmax(callBack));
    new funcID = get_func_id(callBack, pluginID);
    if(funcID == -1) {
        log_error(AMX_ERR_NATIVE, "Function `%s` not found!", callBack);
        return -1;
    }

    new DataPack: reqData = CreateDataPack();
    WritePackCell(reqData, m_BotSubscriptions);

    WritePackCell(reqData, botIndexEntry);
    WritePackString(reqData, chatID);
    WritePackCell(reqData, funcID);
    WritePackCell(reqData, pluginID);
    ResetPack(reqData);

    new botData[BotData_s];
    ArrayGetArray(g_aBotsArray, botIndexEntry, botData);
    new botToken[64];
    copy(botToken, charsmax(botToken), botData[bot_Token]);

    new url[256];
    formatex(url, charsmax(url), "%sbot%s/getChat", URL_API, botToken);

    new GripJSONValue: bodyJSON = grip_json_init_object();
    grip_json_object_set_string(bodyJSON, "chat_id", chatID);

    new GripBody:body = grip_body_from_json(bodyJSON);
    grip_request(url, body, GripRequestTypePost, "HandleRequest", g_pReqOptions, reqData);
    grip_destroy_body(body);

    return 1;
}

public native_BotSendMessageALL(pluginID, argc) {
    enum { arg_botID = 1, arg_message };

    if(argc != 2) {
        log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 2, passed %d", argc);
        return 0;
    }

    if(!g_bInitialized) {
        log_error(AMX_ERR_NATIVE, "API not initialized!");
        return 0;
    }

    new registredBotsCount = ArraySize(g_aBotsArray);
    if(registredBotsCount < 1) {
        log_error(AMX_ERR_NATIVE, "Haven't registred bots.");
        return 0;
    }

    new message[2048];
    get_string(arg_message, message, charsmax(message));
    if(!strlen(message)) {
        log_error(AMX_ERR_NATIVE, "Can't send empty message (message:'%s')", message);
        return 0;
    }

    new botIndexEntry = get_param(arg_botID);
    if(botIndexEntry > registredBotsCount) {
        log_error(AMX_ERR_NATIVE, "TG Bot out of range (index:%i, max:%i)", botIndexEntry, registredBotsCount);
        return 0;
    }

    new botData[BotData_s];
    ArrayGetArray(g_aBotsArray, botIndexEntry, botData);

    new subscriptionsCount = ArraySize(botData[bot_Subscriptions]);
    if(!subscriptionsCount) {
        log_error(AMX_ERR_NATIVE, "TG Bot haven't any subscriptions.");
        return 0;
    }
    
    new url[256];
    formatex(url, charsmax(url), "%sbot%s/sendMessage", URL_API, botData[bot_Token]);

    new GripBody:body;
    new GripJSONValue: bodyJSON = grip_json_init_object();
    grip_json_object_set_string(bodyJSON, "text", message);

    for(new i; i < subscriptionsCount; i++) {
        new DataPack: reqData = CreateDataPack();
        WritePackCell(reqData, m_SendMessage);
        ResetPack(reqData);

        new chat_id[64];
        ArrayGetString(botData[bot_Subscriptions], i, chat_id, charsmax(chat_id));
        grip_json_object_set_string(bodyJSON, "chat_id", chat_id);
        
        body = grip_body_from_json(bodyJSON);
        grip_request(url, body, GripRequestTypePost, "HandleRequest", g_pReqOptions, reqData);
    }
    grip_destroy_body(body);

    return 1;
}

public native_BotSendMessage(pluginID, argc) {
    enum { arg_botID = 1, arg_chatID, arg_message };

    if(argc != 3) {
        log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 3, passed %d", argc);
        return 0;
    }

    if(!g_bInitialized) {
        log_error(AMX_ERR_NATIVE, "API not initialized!");
        return 0;
    }

    new registredBotsCount = ArraySize(g_aBotsArray);
    if(registredBotsCount < 1) {
        log_error(AMX_ERR_NATIVE, "Haven't registred bots.");
        return 0;
    }

    new message[2048];
    get_string(arg_message, message, charsmax(message));
    if(!strlen(message)) {
        log_error(AMX_ERR_NATIVE, "Can't send empty message (message:'%s')", message);
        return 0;
    }

    new botIndexEntry = get_param(arg_botID);
    if(botIndexEntry > registredBotsCount) {
        log_error(AMX_ERR_NATIVE, "TG Bot out of range (index:%i, max:%i)", botIndexEntry, registredBotsCount);
        return 0;
    }

    new botData[BotData_s];
    ArrayGetArray(g_aBotsArray, botIndexEntry, botData);
    
    new url[256];
    formatex(url, charsmax(url), "%sbot%s/sendMessage", URL_API, botData[bot_Token]);

    new GripBody:body;
    new GripJSONValue: bodyJSON = grip_json_init_object();
    grip_json_object_set_string(bodyJSON, "text", message);

    new DataPack: reqData = CreateDataPack();
    WritePackCell(reqData, m_SendMessage);
    ResetPack(reqData);

    new chat_id[64];
    get_string(arg_chatID, chat_id, charsmax(chat_id));
    grip_json_object_set_string(bodyJSON, "chat_id", chat_id);
    
    body = grip_body_from_json(bodyJSON);
    grip_request(url, body, GripRequestTypePost, "HandleRequest", g_pReqOptions, reqData);
    
    grip_destroy_body(body);

    return 1;
}

public native_BotAPI_Allowed(pluginID, argc) {
    return g_bInitialized;
}
///////////////////////////

public HandleRequest(DataPack: reqData) {
    new GripResponseState: response_state = grip_get_response_state();
    switch(response_state) {
        case GripResponseStateError, GripResponseStateTimeout, GripResponseStateCancelled: {
            print(" > HandleRequest() -> wrong response_state! (response_state:%i)", response_state);
            return;
        }
    }

    new response[2024];
    grip_get_response_body_string(response, charsmax(response));

    new GripHTTPStatus:status = grip_get_response_status_code();
    if(status != GripHTTPStatusOk) {
        print(" > HandleRequest() -> wrong status! (status:%i). [response:'%s']", status, response);
    }

    new APIState_s: reqState = ReadPackCell(reqData);

    switch(reqState) {
        case m_Init: {
            Initialize();
        }
        
        case m_RegisterBot: {
            new error[512];
            new GripJSONValue: responseBody = grip_json_parse_response_body(error, charsmax(error));
            if(responseBody == Invalid_GripJSONValue) {
                print("> HandleRequest() -> m_RegisterBot: Response parse error. ['%s']", error);
                // TODO: Need to prevent
            }
            
            new bool: is_bot = grip_json_object_get_bool(responseBody, "ok") && grip_json_object_get_bool(responseBody, "result.is_bot", .dot_not = true);        
            if(is_bot) {
                new botName[64];
                grip_json_object_get_string(responseBody, "result.first_name", botName, sizeof(botName), .dot_not = true);

                new botToken[64];
                ReadPackString(reqData, botToken, charsmax(botToken));

                new funcID = ReadPackCell(reqData);
                new pluginID = ReadPackCell(reqData);

                RegisterBot(botName, botToken, funcID, pluginID);
            }
            
        }
        case m_BotSubscriptions: {
            new error[512];
            new GripJSONValue: responseBody = grip_json_parse_response_body(error, charsmax(error));
            if(responseBody == Invalid_GripJSONValue) {
                print("> HandleRequest() -> m_BotSubscriptions: Response parse error. ['%s']", error);
                // TODO: Need to prevent
            }

            new bool: chat_found = grip_json_object_get_bool(responseBody, "ok");
            if(chat_found) {
                new botID = ReadPackCell(reqData);
                new chatID[64];
                ReadPackString(reqData, chatID, charsmax(chatID));
                new funcID = ReadPackCell(reqData);
                new pluginID = ReadPackCell(reqData);

                new chatTitle[64];
                //grip_json_object_get_string(responseBody, "result.title", chatTitle, charsmax(chatTitle), .dot_not = true);

                new chatType[32];
                grip_json_object_get_string(responseBody, "result.type", chatType, charsmax(chatType), .dot_not = true);
                BotAddSubscription(botID, chatID, chatTitle, chatType, funcID, pluginID);
            }
        }
        case m_SendMessage: {
            new error[512];
            new GripJSONValue: responseBody = grip_json_parse_response_body(error, charsmax(error));
            if(responseBody == Invalid_GripJSONValue) {
                print("> HandleRequest() -> m_BotSubscriptions: Response parse error. ['%s']", error);
                // TODO: Need to prevent
            }
        }
    }

    //print(" > HandleRequest() -> response:'%s'", response);
    DestroyDataPack(reqData); 
}

Initialize() {
    g_aBotsArray = ArrayCreate(_:BotData_s);

    g_bInitialized = true;

    g_fwAPI_Initialized = CreateMultiForward("TG_BotAPI_Initialized", ET_IGNORE);
    ExecuteForward(g_fwAPI_Initialized, g_fwResult);
}

RegisterBot(const botName[], const botToken[], const funcID, const pluginID) {
    new botData[BotData_s];
    copy(botData[bot_Name], charsmax(botData[bot_Name]), botName);
    copy(botData[bot_Token], charsmax(botData[bot_Token]), botToken);
    botData[bot_Subscriptions] = ArrayCreate(64);
    
    ArrayPushArray(g_aBotsArray, botData);

    new botIndexEntry = ArraySize(g_aBotsArray);

    // public BotRegistred(const botID, const botName[]) { }
    if(callfunc_begin_i(funcID, pluginID) == 1) {
        callfunc_push_int(botIndexEntry);
        callfunc_push_str(botName, .copyback = false);
        callfunc_end();
    }
}

BotAddSubscription(const botID, const chatID[], const chatTitle[], const chatType[], const funcID, const pluginID) {
    new botData[BotData_s];
    ArrayGetArray(g_aBotsArray, botID, botData);

    ArrayPushString(botData[bot_Subscriptions], chatID);
    new subscriptionIndexEntry = ArraySize(botData[bot_Subscriptions]);

    ArrayPushArray(g_aBotsArray, botData);

    // public BotSubscriptionAdded(const subscriptionID, const botID, const chatID[], const chatTitle[], const chatType[]) { }
    if(callfunc_begin_i(funcID, pluginID) == 1) {
        callfunc_push_int(subscriptionIndexEntry - 1);
        callfunc_push_int(botID);
        callfunc_push_str(chatID, .copyback = false);        
        callfunc_push_str(chatTitle, .copyback = false);
        callfunc_push_str(chatType, .copyback = false);
        callfunc_end();
    }
}
