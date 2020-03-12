#include <sourcemod>

#include <sdktools>
#include <sdktools_sound>

#undef REQUIRE_PLUGIN
#include <basecomm>

#define MAX_FILE_LEN 80

#undef REQUIRE_EXTENSIONS
#tryinclude <ripext>

#define RIP_ON()		(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "HTTPClient.HTTPClient")			== FeatureStatus_Available)

#pragma semicolon 1
#pragma newdecls required

HTTPClient g_hHTTPClient;

int iChats, iIncludeServerName, iBaseComms, iMessagesPerRound, iLogging, iVK[MAXPLAYERS + 1], iSteamSay, iAdminCensored, iSteamType;
char sToken[128], sServerName[256], sSection[100],sValueID[100], sText[MAXPLAYERS+1][300], sName[MAXPLAYERS+1][30], sSteamID[MAXPLAYERS + 1][64], sIP[MAXPLAYERS + 1][64], sSoundMessage[128], sSoundSend[128], sSoundError[128];
Menu menu_chats;

public Plugin myinfo =
{
	name = "VKChat (mod chat2vk)",
	description = "Send messages to VK conversation",
	author = "xtance & DeathScore13",
	version = "4.0 (GLOBAL)",
	url = "https://t.me/xtance & https://vk.com/deathscore13"
};

public void OnPluginStart()
{
	if (RIP_ON()) g_hHTTPClient = new HTTPClient("https://api.vk.com");
	
	LoadTranslations("vkchat.phrases");

	RegConsoleCmd("sm_vk", VKsay, "Посылает сообщение в VK");
	RegServerCmd("sm_send", VKsend, "Посылает сообщение из VK на сервер - не трогать");
	RegServerCmd("sm_web_getplayers", Action_Web_GetPlayers, "Получает массив с игроками - не трогать");
	
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/vkchat.ini");
	KeyValues kv = new KeyValues("VKChat");
	
	if (!FileExists(sPath, false))
	{
		if (kv.JumpToKey("VK_Settings", true))
		{
			kv.SetNum("BaseComms", 1);
			kv.SetString("VKToken", "ключ");
			kv.SetNum("MessagesPerRound", 5);
			kv.SetNum("IncludeServerName", 1);
			kv.SetNum("Logging", 1);
			kv.SetString("SoundMessage", "vkchat/message.mp3");
			kv.SetString("SoundSend", "vkchat/send.mp3");
			kv.SetString("SoundError", "vkchat/error.mp3");
			kv.SetNum("SteamSay", 1);
			kv.SetNum("AdminCensored", 1);
			kv.SetNum("SteamType", 0);
			kv.Rewind();
		}
		if (kv.JumpToKey("VK_Commands", true))
		{
			kv.SetString("Отправить в беседу", "2000000001");
			kv.SetString("Отправить Администраторам", "2000000002");
			kv.SetString("Отправить Гл. Админам", "2000000003");
			kv.Rewind();
		}
		kv.ExportToFile(sPath);
	}
	
	if (kv.ImportFromFile(sPath))
	{
		if (kv.JumpToKey("VK_Settings", false))
		{
			iBaseComms = kv.GetNum("BaseComms");
			kv.GetString("VKToken", sToken, sizeof(sToken));
			kv.GetString("SoundMessage", sSoundMessage, sizeof(sSoundMessage));
			kv.GetString("SoundSend", sSoundSend, sizeof(sSoundSend));
			kv.GetString("SoundError", sSoundError, sizeof(sSoundError));
			iMessagesPerRound = kv.GetNum("MessagesPerRound");
			iIncludeServerName = kv.GetNum("IncludeServerName");
			iLogging = kv.GetNum("Logging");
			iSteamSay = kv.GetNum("SteamSay");
			iAdminCensored = kv.GetNum("AdminCensored");
			iSteamType = kv.GetNum("SteamType");
			kv.Rewind();
		}
		if (kv.JumpToKey("VK_Commands", false))
		{
			kv.GotoFirstSubKey(false);
			menu_chats = new Menu(hmenu);
			menu_chats.SetTitle("Выберите получателя:");
			do {
				kv.GetSectionName(sSection, sizeof(sSection));
				kv.GetString(NULL_STRING, sValueID, sizeof(sValueID));
				menu_chats.AddItem(sValueID, sSection);
				if (iLogging) PrintToServer("[VKChat] ChatID: %s, Text: %s", sValueID, sSection);
				iChats++;
			} while (kv.GotoNextKey(false));
		}
	} else SetFailState("[VKChat] KeyValues Error!");
	delete kv;

	for (int i = 1; i<=MaxClients; i++) OnClientPostAdminCheck(i);
}

public void OnConfigsExecuted()
{
	if (iIncludeServerName)
	{
		Handle hHostName;
		if(hHostName == INVALID_HANDLE)
		{
			if( (hHostName = FindConVar("hostname")) == INVALID_HANDLE)
			{
				PrintToServer("[VKChat] Плагин сломался.");
				return;
			}
		}
		GetConVarString(hHostName, sServerName, sizeof(sServerName));
		ReplaceString(sServerName, sizeof(sServerName), " ", "%20", false);
	}

	if (sSoundMessage[0] != 0)
	{
		char buffer[MAX_FILE_LEN];
		PrecacheSound(sSoundMessage, true);
		Format(buffer, sizeof(buffer), "sound/%s", sSoundMessage);
		AddFileToDownloadsTable(buffer);
	}

	if (sSoundSend[0] != 0)
	{
		char buffer2[MAX_FILE_LEN];
		PrecacheSound(sSoundSend, true);
		Format(buffer2, sizeof(buffer2), "sound/%s", sSoundSend);
		AddFileToDownloadsTable(buffer2);
	}

	if (sSoundError[0] != 0)
	{
		char buffer3[MAX_FILE_LEN];
		PrecacheSound(sSoundError, true);
		Format(buffer3, sizeof(buffer3), "sound/%s", sSoundError);
		AddFileToDownloadsTable(buffer3);
	}
}

public void OnClientPostAdminCheck(int iClient)
{
	if (IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		if (iAdminCensored)
		{
			AdminId iAdmin = GetUserAdmin(iClient);
			if (iAdmin != INVALID_ADMIN_ID)
			{
				sSteamID[iClient] = "СКРЫТО";
				sIP[iClient] = "СКРЫТО";
			}
			else
			{
				if (iSteamType == 0)
				{
					GetClientAuthId(iClient, AuthId_Steam2, sSteamID[iClient], 64, true);
				}
				else if (iSteamType == 1)
				{
					GetClientAuthId(iClient, AuthId_Steam3, sSteamID[iClient], 64, true);
					ReplaceString(sSteamID[iClient], 64, "[", "", false);
					ReplaceString(sSteamID[iClient], 64, "]", "", false);
				}
				else {
					GetClientAuthId(iClient, AuthId_SteamID64, sSteamID[iClient], sizeof(sSteamID), true);
					Format(sSteamID[iClient], sizeof(sSteamID), "steamcommunity.com/profiles/%s", sSteamID[iClient]);
				}
				GetClientIP(iClient, sIP[iClient], 64, true);
			}
		}
		else
		{
			GetClientAuthId(iClient, AuthId_Steam2, sSteamID[iClient], 64, true);
			GetClientIP(iClient, sIP[iClient], 64, true);
		}
		GetClientName(iClient, sName[iClient], sizeof(sName[]));
		ReplaceString(sName[iClient], sizeof(sName[]), "\\", "", false);
		ReplaceString(sName[iClient], sizeof(sName[]), "\"", "", false);
	}
}

public Action Action_Web_GetPlayers(int iArgs)
{
	PrintToServer("[");
	for (int i = 1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			PrintToServer("{\"name\": \"%s\", \"steamid\": \"%s\", \"ip\": \"%s\", \"team\": \"%i\", \"time\": \"%f\", \"gag\": \"%b\", \"mute\": \"%b\", \"k\": %i, \"d\": %i},",sName[i],sSteamID[i],sIP[i],GetClientTeam(i),GetClientTime(i),BaseComm_IsClientGagged(i),BaseComm_IsClientMuted(i),GetClientFrags(i),GetClientDeaths(i));
		}
	}
	PrintToServer("]ArrayEnd");
	
	/*for (int i = 1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			Format(sJson, sizeof(sJson), "{\"name\": \"%s\", \"steamid\": \"%s\", \"k\": %i, \"d\": %i},%s",sName[i],sSteamID[i],GetClientFrags(i),GetClientDeaths(i),sJson);
		}
	}
	Format(sJson, sizeof(sJson), "[%s]", sJson);
	ReplaceString(sJson, sizeof(sJson), ",]", "]", false); // :D
	ReplyToCommand(0, sJson);*/
	return Plugin_Handled;
}

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErr_max)
{
	MarkNativeAsOptional("HTTPClient.HTTPClient");
	MarkNativeAsOptional("HTTPClient.SetHeader");
	MarkNativeAsOptional("HTTPClient.Get");
	MarkNativeAsOptional("HTTPResponse.Status.get");
	return APLRes_Success;
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) iVK[i] = 0;
}

public Action VKsend(int iArgs)
{
	if (iArgs < 1)
	{
		PrintToServer("[VKChat] Что-то пошло не так!");
		return Plugin_Handled;
	}
	else
	{
		char sVK[512], sBuffer[3][512];
		GetCmdArgString(sVK, sizeof(sVK));
		ReplaceString(sVK, sizeof(sVK), "\"", "", false);
		ExplodeString(sVK, "&", sBuffer, sizeof(sBuffer), sizeof(sBuffer[]));
		
		if (strlen(sBuffer[2]) < 1) return Plugin_Handled;

		PrintToChatAll("%t %t", "Prefix", "SendVK", sBuffer[0], sBuffer[1]);
		PrintToChatAll("%t %t", "Prefix", "MessageVK", sBuffer[2]);
		if (sSoundMessage[0] != 0)
		{
			EmitSoundToAll(sSoundMessage);
		}

		if (iLogging > 0) LogMessage("%s пишет %s: %s", sBuffer[0],sBuffer[1],sBuffer[2]);
		return Plugin_Handled;
	}
}

public Action VKsay(int iClient, int iArgs)
{
	if (iClient == 0) PrintToServer("[VKChat] Эта команда для клиента!");
	else if (iArgs < 1) PrintToChat(iClient, "%t %t", "Prefix", "UseCommand");
	else if (iVK[iClient] < iMessagesPerRound)
	{
		//Проверка BaseComms
		if (iBaseComms && BaseComm_IsClientGagged(iClient))
		{
			PrintToChat(iClient, "%t %t", "Prefix", "Mute");
			return Plugin_Handled;
		}
		
		char sSteam[64];
		GetCmdArgString(sText[iClient], sizeof(sText[]));
		if (iSteamType == 0)
		{
			GetClientAuthId(iClient, AuthId_Steam2, sSteam, 64, true);
		}
		else if (iSteamType == 1)
		{
			GetClientAuthId(iClient, AuthId_Steam3, sSteam, 64, true);
			ReplaceString(sSteam, 64, "[", "", false);
			ReplaceString(sSteam, 64, "]", "", false);
		}
		else
		{
			GetClientAuthId(iClient, AuthId_SteamID64, sSteam, sizeof(sSteam), true);
			Format(sSteam, sizeof(sSteam), "steamcommunity.com/profiles/%s", sSteam);
		}
		
		//Фикс всякой фигни
		ReplaceString(sText[iClient], 300, "⠀", " ", false);
		for (int i = StrContains(sText[iClient], "  ", false); i >= 0; i = StrContains(sText[iClient], "  ", false))
		{
			ReplaceString(sText[iClient], 300, "  ", " ", false);
		}
		ReplaceString(sText[iClient], 300, "  ", " ", false);
		
		if (strlen(sText[iClient]) <= 122 && !StrEqual(sText[iClient], " ", false))
		{
			if (iSteamSay)
			{
				if (iAdminCensored)
				{
					AdminId iAdmin = GetUserAdmin(iClient);
					if (iAdmin != INVALID_ADMIN_ID)
					{
						if (iIncludeServerName) Format(sText[iClient], sizeof(sText[]), "%N <СКРЫТО>:NWLN NWLN%s NWLN NWLNСервер: %s",iClient,sText[iClient],sServerName);
						else Format(sText[iClient], sizeof(sText[]), "%N <СКРЫТО>:NWLN NWLN%s",iClient,sText[iClient]);
					}
					else
					{
						if (iIncludeServerName) Format(sText[iClient], sizeof(sText[]), "%N <%s>:NWLN NWLN%s NWLN NWLNСервер: %s",iClient,sSteam,sText[iClient],sServerName);
						else Format(sText[iClient], sizeof(sText[]), "%N <%s>:NWLN NWLN%s",iClient,sSteam,sText[iClient]);
					}
				}
				else
				{
					if (iIncludeServerName) Format(sText[iClient], sizeof(sText[]), "%N <%s>:NWLN NWLN%s NWLN NWLNСервер: %s",iClient,sSteam,sText[iClient],sServerName);
					else Format(sText[iClient], sizeof(sText[]), "%N <%s>:NWLN NWLN%s",iClient,sSteam,sText[iClient]);
				}
			}
			else
			{
				if (iIncludeServerName) Format(sText[iClient], sizeof(sText[]), "%N:NWLN NWLN%s NWLN NWLNСервер: %s",iClient,sText[iClient],sServerName);
				else Format(sText[iClient], sizeof(sText[]), "%N:NWLN NWLN%s",iClient,sText[iClient]);
			}
			
			if (iChats < 1)
			{
				PrintToChat(iClient, "%t %t", "Prefix", "Error");
			}
			else if (iChats == 1)
			{
				SendMessage(StringToInt(sValueID), sText[iClient], iClient);
				iVK[iClient]++;
				if (iLogging) LogAction(iClient, -1, "\"%L\" отправил: %s", iClient, sText[iClient]);
			}
			else menu_chats.Display(iClient, 0);
		}
		else
		{
			PrintToChat(iClient, "%t %t", "Prefix", "ErrorSize");
		}
	}
	else {
		PrintToChat(iClient, "%t %t", "Prefix", "AllowCounts", iMessagesPerRound);
		if (sSoundError[0] != 0)
		{
			EmitSoundToClient(iClient, sSoundError);
		}
	}
	return Plugin_Handled;
}

public int hmenu(Menu m, MenuAction action, int iClient, int iParam2)
{
	switch (action)
	{
		case MenuAction_Select:{
			char sID[50];
			m.GetItem(iParam2, sID, sizeof(sID));
			SendMessage(StringToInt(sID), sText[iClient], iClient);
			iVK[iClient]++;
			if (iLogging) LogAction(iClient, -1, "\"%L\" отправил: %s", iClient, sText[iClient]);
		}
	}
	return 0;
}

void SendMessage(int iID, const char[] sMessage, int iClient)
{
	char sURL[2000];
	if(iID >= 2000000000)
	{
		iID -= 2000000000;
		FormatEx(sURL, sizeof(sURL), "https://api.vk.com/method/messages.send?v=5.101&random_id=%i&access_token=%s&chat_id=%i&message=%s",
			GetRandomInt(0, 100500),
			sToken,
			iID,
			sMessage, iClient
		);
	}
	else{
		FormatEx(sURL, sizeof(sURL), "https://api.vk.com/method/messages.send?v=5.101&random_id=%i&access_token=%s&user_id=%i&message=%s",
			GetRandomInt(0, 100500),
			sToken,
			iID,
			sMessage, iClient
		);
	}
	
	//Костыли
	ReplaceString(sURL, sizeof(sURL), " ", "%20", false);
	ReplaceString(sURL, sizeof(sURL), "⠀", "%20", false);
	ReplaceString(sURL, sizeof(sURL), "NWLN", "%0A", false);
	ReplaceString(sURL, sizeof(sURL), "#", "%23", false);
	
	if (RIP_ON())
	{
		RIP_SendMessage(sURL, iClient);
		return;
	}
	LogError("Ошибка отправки сообщения! Установите RIP, если его ещё нет: https://forums.alliedmods.net/showthread.php?t=298024");
	PrintToChat(iClient, "%t %t", "Prefix", "MessageSendError");
	if (sSoundError[0] != 0)
	{
		EmitSoundToClient(iClient, sSoundError);
	}
}

void RIP_SendMessage(const char[] sURL, int iClient)
{
	g_hHTTPClient.SetHeader("User-Agent", "Test");
	g_hHTTPClient.Get(sURL[19], OnRequestCompleteRIP);
	PrintToChat(iClient, "%t %t", "Prefix", "MessageSend");
	if (sSoundSend[0] != 0)
	{
		EmitSoundToClient(iClient, sSoundSend);
	}
}

public void OnRequestCompleteRIP(HTTPResponse hResponse, any iData)
{
	if (hResponse.Status != HTTPStatus_OK && iLogging) LogMessage("Отклик VK: %d", hResponse.Status);
}