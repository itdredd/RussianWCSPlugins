/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Basic Chat Plugin
 * Implements basic communication commands.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#pragma semicolon 1

#include <sourcemod>
#include <wcs>
#include <clientprefs>
#include <csgo_colors>
#include <cstrike>
#include <adminmenu>
#include <menus>
#include <dbi>

#pragma newdecls required

// sm plugins refresh ruswcs.smx

public Plugin myinfo = 
{
	name = "Russian addition",
	author = "Dredd",
	description = "Additional functional for Russian WCS.",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

#define MeOnly "STEAM_1:0:1240051"
Database g_hDatabase;

public void OnPluginStart()
{
	LoadTranslations("ruswcs.phrases");
	
	RegConsoleCmd("wcsbonus", Command_WcsBonus);
	RegConsoleCmd("wcsinfo", Command_WcsInfo);
	RegConsoleCmd("wcsgiveaway", Command_WcsGiveAway);
	RegAdminCmd("wcs_givevip", Command_WcsGiveVip, ADMFLAG_ROOT);
	RegAdminCmd("wcsbonuscheck", Command_CheckBonus, ADMFLAG_GENERIC, "Check for bonus.");
	RegConsoleCmd("steamgroup", Command_SteamGroup);	
	RegConsoleCmd("contact", Command_Contact);	
	RegConsoleCmd("ruswcs", Command_WcsMenu);
	Database.Connect(ConnectCallBack, "ruswcs"); // sp_lessons Имя секции в databases.cfg
}

public void OnClientPostAdminCheck(int client){
	if (IsClientInGame(client)) {
	char szQuery[256], szAuth[32];

	GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));

	FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `players` (`steamId`) VALUES ('%s');", szAuth);
	g_hDatabase.Query(SQL_PushSteamId_Callback, szQuery);
	}
}

//SQL

public Action PushDate(int client, int lvl, int type, int dbLvl) {
	switch (type){
		case 0:{
			if(lvl < 1000){
				CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsNoAccessBonus", 1000);
				return Plugin_Handled;
			}
			for (int i = 1000; i <= lvl; i+=1000){
				WCS_GiveLBlvl(client, 40);
				lvl = WCS_GetLvl(client);
				CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsGetBonus", i);
				//LogAction(client, -1, "Player %L received 40 lvls for to achieved %i lvls.", client, i);
				LogToFileEx("logs/ruswcs.log","Player %L received 40 lvls for to achieved %i lvls.", client, i);
			}
			char szQuery[256], szAuth[32];
			GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));
			FormatEx(szQuery, sizeof(szQuery), "UPDATE `players` SET `bonus` = '%i' WHERE `steamId` =  '%s';", lvl, szAuth);
			g_hDatabase.Query(SQL_Push_Callback, szQuery);
			
			return Plugin_Handled;
		}
		case 1:{
			int startLvl = RoundToCeil(float(dbLvl/1000));

			startLvl = (startLvl+1)*1000;

			if(startLvl > lvl){
				CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsNoAccessBonus", startLvl);
				return Plugin_Handled;
			}
			for (int i = startLvl; i <= lvl; i+=1000){
				WCS_GiveLBlvl(client, 40);
				lvl = WCS_GetLvl(client);
				CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsGetBonus", i);
				//LogAction(client, -1, "Player %L received 40 lvls for to achieved %i lvls.", client, i);
				LogToFileEx("logs/ruswcs.log","Player %L received 40 lvls for to achieved %i lvls.", client, i);
			}
			char szQuery[256], szAuth[32];
			GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));
			FormatEx(szQuery, sizeof(szQuery), "UPDATE `players` SET `bonus` = '%i' WHERE `steamId` =  '%s';", lvl, szAuth);
			g_hDatabase.Query(SQL_Push_Callback, szQuery);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public void SQL_PushSteamId_Callback(Database hDatabase, DBResultSet results, const char[] sError, any data) {
	if(sError[0]) {
	LogError("SQL_Callback_PushSteamId: %s", sError); // Выводим в лог
	return; // Прекращаем выполнение ф-и
	}
}

public void ConnectCallBack (Database hDB, const char[] szError, any data) // Пришел результат соединения
{
	if (hDB == null || szError[0]) {
		SetFailState("Database failure: %s", szError); // Отключаем плагин
		return;
	}
	g_hDatabase = hDB; // Присваиваем глобальной переменной соединения значение текущего соединения
	CreateTables(); // Функция пока не реализована, но по имени, думаю, ясно что она делает
}

public void SQL_Check_Callback(Database hDatabase, DBResultSet results, const char[] sError, any data) {
	DataPack dPack = view_as<DataPack>(data);
	dPack.Reset();
	int owner = dPack.ReadCell();
	int client = dPack.ReadCell();
	if(sError[0]) {
		LogError("SQL_Check_Callback: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	else if(results.IsFieldNull(0)) {
		//PrintToServer("Done");
		CGOPrintToChat(owner, "{GREEN}%N{DEFAULT} еще не получал бонус.", client);
	}
}

public void SQL_Push_Callback(Database hDatabase, DBResultSet results, const char[] sError, any data) {
	if(sError[0]) {
	LogError("SQL_Callback_Push: %s", sError); // Выводим в лог
	return; // Прекращаем выполнение ф-и
	}
}

public void SQL_Create_Callback(Database hDatabase, DBResultSet results, const char[] sError, any data) {
	if(sError[0]) {
	LogError("SQL_Callback_Create: %s", sError); // Выводим в лог
	return; // Прекращаем выполнение ф-и
	}
}

public void SQL_Bonus_Callback(Database hDatabase, DBResultSet results, const char[] sError, any data) {
	DataPack dPack = view_as<DataPack>(data);
	dPack.Reset();
	int lvl = dPack.ReadCell();
	int client = dPack.ReadCell();
	int dbLvl = results.FetchInt(0);

	if(sError[0]) {
		LogError("SQL_Callback_Bonus: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	else if(results.IsFieldNull(0)) {
		PushDate(lvl, client, 0, 0);
	}
	else if(!results.IsFieldNull(0)){
		PushDate(lvl, client, 1, dbLvl);
	}
	else{
		PrintToServer("%s", results);
	}
}

public void CreateTables() {
	char szQuery[256];
	FormatEx(szQuery, sizeof(szQuery), "CREATE TABLE IF NOT EXISTS `players` (`steamId` TEXT UNIQUE, `bonus` INTEGER);");
	g_hDatabase.Query(SQL_Create_Callback, szQuery);
}



//~SQL

public int RusWcsHandler(Menu menu, MenuAction action, int param1, int param2){
	switch(action)
    {
        case MenuAction_End:    // Меню завершилось
        {
            // Оно нам больше не нужно. Удалим его
            delete menu;
        }
        case MenuAction_Cancel:    // Меню было отменено
        {
            if(param2 == MenuCancel_ExitBack)    // Если игрок нажал кнопку "Назад"
            {
                // Отправим ему сообщение что нет возможности вернуться назад.
                // Бывает же что конопку "Назад" назад добавили там, где это не нужно
                PrintToChat(param1, "Извините, но назад вернуться нельзя!");
            }
        }
        case MenuAction_Select:    // Игрок выбрал пункт
        {
			if (param2 == 0)
				Command_WcsBonus(param1, 0);
			else if (param2 == 1)
				Command_WcsInfo(param1, 0);
			else if (param2 == 2)
				ClientCommand(param1, "wcs");
			else if (param2 == 3)
				CGOPrintToChat(param1, "%T", "VkGroupMenu", param1);
			else if (param2 == 4)
				Command_Contact(param1, 0);
			else if (param2 == 5)
				Command_SteamGroup(param1, 0);
			else if (param2 == 6)
				ClientCommand(param1, "sm_rules");
			else if (param2 == 7)
				Command_CheckBonus(param1, 0);
			else if(param2 == 8)
				Command_WcsGiveAway(param1, 0);
			else if(param2 == 9) {
				Command_WcsGiveVip(param1, 0);
			}
			else 
				CGOPrintToChat(param1, "{purple}[RUSSIAN WCS] {DEFAULT}%T", "WcsError", param1);
        }
	}
	return 0;
}

public Action Command_WcsMenu(int client, int args){
	char buffer[64];
	Menu hMenu = new Menu(RusWcsHandler);
	FormatEx(buffer, sizeof(buffer), "%T", "TitleMenu", client);
	hMenu.SetTitle(buffer);

	FormatEx(buffer, sizeof(buffer), "%T", "GetBonusMenu", client);
	hMenu.AddItem(buffer,buffer);

	FormatEx(buffer, sizeof(buffer), "%T", "WcsInfoMenu", client);
	hMenu.AddItem(buffer,buffer);

	FormatEx(buffer, sizeof(buffer), "%T", "WcsMenuR", client);
	hMenu.AddItem(buffer,buffer);

	FormatEx(buffer, sizeof(buffer), "%T", "VkGroupTitleMenu", client);
	hMenu.AddItem(buffer,buffer);

	FormatEx(buffer, sizeof(buffer), "%T", "ContactMenu", client);
	hMenu.AddItem(buffer,buffer);

	FormatEx(buffer, sizeof(buffer), "%T", "SteamGroupMenu", client);
	hMenu.AddItem(buffer,buffer);

	FormatEx(buffer, sizeof(buffer), "%T", "RulesMenu", client);
	hMenu.AddItem(buffer,buffer);

	if (client > 0 && (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ADMFLAG_GENERIC)) {
		FormatEx(buffer, sizeof(buffer), "%T", "CheckBonusMenu", client);
		hMenu.AddItem(buffer, buffer);
	}
	else {
		FormatEx(buffer, sizeof(buffer), "%T", "CheckBonusMenu", client);
		hMenu.AddItem(buffer, buffer, ITEMDRAW_DISABLED );
	}

	if (client > 0 && (GetUserFlagBits(client) & ADMFLAG_ROOT || strcmp(buffer, "STEAM_1:1:175284716") == 0)) {
		FormatEx(buffer, sizeof(buffer), "%T", "GiveAwayMenu", client);
		hMenu.AddItem(buffer, buffer);
	}
	else {
		FormatEx(buffer, sizeof(buffer), "%T", "GiveAwayMenu", client);
		hMenu.AddItem(buffer, buffer, ITEMDRAW_DISABLED );
	}

	if (client > 0 && GetUserFlagBits(client) & ADMFLAG_ROOT) {
		FormatEx(buffer, sizeof(buffer), "%T", "GiveAwayVipMenu", client);
		hMenu.AddItem(buffer, buffer);
	}
	else {
		FormatEx(buffer, sizeof(buffer), "%T", "GiveAwayVipMenu", client);
		hMenu.AddItem(buffer, buffer, ITEMDRAW_DISABLED );
	}

	hMenu.Display(client, 20);
}

stock int GetRandomClient(bool bot = false, bool alive = true) {
	int team = 0, count = 0;
	int [] players = new int [MaxClients];
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient) && bot == IsFakeClient(iClient) && alive == IsPlayerAlive(iClient) && !(team > 0 && team != GetClientTeam(iClient)))
			players[count++] = iClient;
	}
	return count > 0 ? players[GetRandomInt(0, count - 1)] : -1;
}

public Action Command_WcsGiveVip(int client, int args){

	char steamID[64];
	int [] vipPlayers = new int[MaxClients];
	int counter = 0;

	char group[] = "vip_group_1";

	for (int iClient = 1; iClient <= MaxClients; iClient++){
		if(counter == MaxClients) {
		CGOPrintToChatAll("{purple}[RUSSIAN WCS] {default}%T", "AllPlayersWithVip", client);
		return Plugin_Handled;
		}
		else if (!IsClientInGame(iClient) || IsFakeClient(iClient) || !WCS_IsPlayerLoaded(iClient)) {
			counter++;
			continue;
	 	}
		else if(WCS_GetVip(iClient)){
			vipPlayers[iClient] = iClient;
			//PrintToChat(owner, "vip=%i", iClient);
			counter++;
		} 
	}

	if(counter == MaxClients) {
		CGOPrintToChatAll("{purple}[RUSSIAN WCS] {default}%T", "AllPlayersWithVip", client);
		return Plugin_Handled;
	}

	int winner = GetRandomClient();

	for (int i = 1; i <= counter; i++) {
		if (winner == vipPlayers[i]){
			winner = GetRandomClient();
			i=1;
		}
		
	}

	if(!WCS_GetVip(winner)){
		char name[32];

		GetClientName(winner, name, sizeof(name));

		GetClientAuthId(winner, AuthId_Steam2, steamID, sizeof(steamID));
		//PrintToConsole(owner, "[DEBUG]\nsteamID = %s\nname = %s", steamID, name);
		WCS_GiveVIP(steamID, name, group,120);
		if (!WCS_GetVip(winner))
			return Plugin_Handled;
		CGOPrintToChatAll("{purple}[RUSSIAN WCS] {green}%N{default} выиграл VIP!", winner, client);
		PrintCenterText(winner, "Вы получили VIP на 2 часа от администрации.", winner);
		//LogAction(owner, client, "%L give random vip to %L", owner, client);
		LogToFileEx("logs/ruswcs.log","%L give random vip to %L", client, winner);

	}
	else {
		CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%T", "WcsError", client);
	}
	return Plugin_Handled;



	// char SteamID[65];
	// int[] clients = new int[MaxClients];
	// int vipPlayers;
	// char group[] = "vip_group_1";

	// for(int iClient = 1; iClient <= MaxClients; iClient++){
	// 	clients[iClient] = GetRandomClient();

	// 	for (int z = 1; z < iClient; z++){
	// 		if(clients[z] == clients[iClient]) {
	// 			clients[iClient] = GetRandomClient();
	// 			PrintToConsole(owner, "%i", vipPlayers);
	// 			z=1;
	// 		}
	// 		if(vipPlayers==MaxClients-1){
	// 			PrintToChat(owner, "Done");
	// 		}	
	// 	}
	// 	if (!IsClientInGame(clients[iClient]) || IsFakeClient(clients[iClient]) || !WCS_IsPlayerLoaded(clients[iClient])) {
	// 		continue;
	// 	}
	// 	else if(WCS_GetVip(clients[iClient])){
	// 		PrintToChat(owner, "vipplayer = %i", clients[iClient]);
	// 		vipPlayers++;
	// 		continue;
	// 	}
		
			
	// 	if(!WCS_GetVip(clients[iClient])){
	// 		char name[32];

	// 		GetClientName(clients[iClient], name, sizeof(name));

	// 		GetClientAuthId(clients[iClient], AuthId_Steam2, steamId, sizeof(steamId));
	// 		//PrintToConsole(owner, "[DEBUG]\nSteamId = %s\nname = %s", steamId, name);
	// 		WCS_GiveVIP(steamId, name, group,120);
	// 		if (!WCS_GetVip(clients[iClient]))
	// 			return Plugin_Handled;
	// 		CGOPrintToChatAll("{purple}[RUSSIAN WCS] {green}%N{default} выиграл VIP!", clients[iClient], owner);
	// 		PrintCenterText(clients[iClient], "Вы получили VIP на 2 часа от администрации.", clients[iClient]);
	// 		//LogAction(owner, client, "%L give random vip to %L", owner, client);
	// 		LogToFileEx("logs/ruswcs.log","%L give random vip to %L", owner, clients[iClient]);
	// 		break;


	// 	}

	// }

	// if(vipPlayers == MaxClients)
	// 		CGOPrintToChat(owner, "{purple}[RUSSIAN WCS] {default}%T", "AllPlayersWithVip", owner);

}

public void OnClientConnected(int client){ 

	SetGlobalTransTarget(client);
}

public Action Command_WcsGiveAway(int client, int args)
{
	char buffer[64];

	GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));

	if (GetUserFlagBits(client) & ADMFLAG_ROOT || strcmp(buffer, "STEAM_1:1:175284716") == 0 || client == 0){
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (!IsClientInGame(iClient) || IsFakeClient(iClient) || !WCS_IsPlayerLoaded(iClient)) {
				continue;
			}
			else if(client == iClient){
				CGOPrintToChat(iClient, "{purple}[RUSSIAN WCS] {default}Вы поблагодарили игроков.");
				continue;
			}
			
			WCS_GiveLBlvl(iClient, 5);
			
			CGOPrintToChat(iClient, "{purple}[RUSSIAN WCS] {default}%t", "WcsGiveAway", client);
			//LogAction(iClient, -1, "Player %L received 5 lvls from %L", iClient, client);
			LogToFileEx("logs/ruswcs.log","Player %L received 5 lvls from %L", iClient, client);
		}
	}
	else {
		PrintToConsole(client, "У Вас нет доступа для этой команды.");
	}
	return Plugin_Continue;
}

public Action Command_CheckBonus(int client, int args) {
	char szQuery[256], szAuth[32];
	DataPack hPack = new DataPack();
	hPack.WriteCell(client);


	for (int iClient = 1; iClient <= MaxClients; iClient++){
		if (!IsClientInGame(iClient) || IsFakeClient(iClient) || !WCS_IsPlayerLoaded(iClient)) {
				continue;
			}
		hPack.WriteCell(iClient);
		GetClientAuthId(iClient, AuthId_Steam2, szAuth, sizeof(szAuth));
		FormatEx(szQuery, sizeof(szQuery), "SELECT `bonus` FROM `players` WHERE `steamId` = '%s';", szAuth);
		g_hDatabase.Query(SQL_Check_Callback, szQuery, hPack);
	}

	return Plugin_Continue;
}

public Action Command_WcsBonus(int client, int args) {
	char szQuery[256], szAuth[32];
	int lvl;

	lvl = WCS_GetLvl(client);
	GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));

	FormatEx(szQuery, sizeof(szQuery), "SELECT `bonus` FROM `players` WHERE `steamId` = '%s';", szAuth);

	DataPack hPack = new DataPack();
	hPack.WriteCell(client);
	hPack.WriteCell(lvl);

	g_hDatabase.Query(SQL_Bonus_Callback, szQuery, hPack);
	


	return Plugin_Continue;
}

public Action Command_WcsInfo(int client, int args)
{
	PrintToChat(client, " \x02Russian WCS \x01— это сервер, который строится на расах («уникальный персонаж со своими способностями»). ");
	PrintToChat(client, "Каждая раса является уникальной, то есть имеет свои способности. ");
	PrintToChat(client, "Цель игры заключается в прокачке рас для достижения более сильных.");
	PrintToChat(client, "Команды сервера:");
	CGOPrintToChat(client, "«{GREEN}/lk{DEFAULT}» — личный кабинет (донат меню).");
	PrintToChat(client, "«\x04/wc\x01» — основная команда, которая открывает меню сервера.");
	PrintToChat(client, "«\x04/lb\x01» — банк уровней, которые можно купить, выиграть и т.д.");
	CGOPrintToChat(client, "«{GREEN}/ruswcs{DEFAULT}» — меню сервера.");
	PrintToChat(client, "«\x04/gb\x01» — банк золота.");
	PrintToChat(client, "«\x4/wcshop\x01» — магазин.");
	PrintToChat(client, "«\x04/wcsbonus\x01» — бонус за достижения определенного уровня.");
	CGOPrintToChat(client, "«{GREEN}/steamgroup{DEFAULT}» — ссылку на группу, при активации тега которой, Вы будете получать на 10% больше опыта.");
	CGOPrintToChat(client, "«{GREEN}/contact{DEFAULT}» — контакты администратора, у которого можно приобрести донат.");
	CGOPrintToChat(client, "«{GREEN}/vk *сообщение*{DEFAULT}» — отправляет сообщение в беседу сервера.");
	CGOPrintToChat(client, "«{GREEN}/viptest{DEFAULT}» — получение временной vip-группы для тестирования.");
	CGOPrintToChat(client, "«{GREEN}/cr{DEFAULT}» — команда для быстрой смены расы.");
	CGOPrintToChat(client, "«{GREEN}/ri{DEFAULT}» — команда для получения информации о расе.");
	CGOPrintToChat(client, "«{GREEN}/rr{DEFAULT}» — команда для выбора случайной расы.");
	PrintToChat(client, "Бинды:");
	PrintToChat(client, "«\x04bind v ultimate\x01» — бинд на способность.");
	PrintToChat(client, "«\x04bind x ability\x01» — бинд на вторую способность («тотем»).");
	return Plugin_Continue;
}

public Action Command_SteamGroup(int client, int args){
	CGOPrintToChat(client, "Steam группа Russian WCS — {LIME}https://steamcommunity.com/groups/ruswcs");

	return Plugin_Continue;
}

public Action Command_Contact(int client, int args){
	CGOPrintToChat(client, "{GREEN}Контакты:\nVK{DEFAULT} — https://vk.com/ruslanprusov\nTelegram{DEFAULT} — @DreddTG");

	return Plugin_Continue;
}




