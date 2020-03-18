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

Handle bCookie;

public void OnPluginStart()
{
	LoadTranslations("ruswcs.phrases");
	
	RegConsoleCmd("wcsbonus", Command_WcsBonus);
	RegConsoleCmd("wcsinfo", Command_WcsInfo);
	RegConsoleCmd("wcsgiveaway", Command_WcsGiveAway);
	RegAdminCmd("wcsbonuscheck", Command_CheckBonus, ADMFLAG_GENERIC, "Check for bonus.");
	RegConsoleCmd("steamgroup", Command_SteamGroup);	
	RegConsoleCmd("contact", Command_Contact);	
	RegConsoleCmd("ruswcs", Command_WcsMenu);
}

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
				GiveRandomVip(param1);
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

int GetRandomClient(bool bot = false, bool alive = true) {
	int team = 0, count = 0;
	int [] players = new int [MaxClients];
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient) && bot == IsFakeClient(iClient) && alive == IsPlayerAlive(iClient) && !(team > 0 && team != GetClientTeam(iClient)))
			players[count++] = iClient;
	}
	return count > 0 ? players[GetRandomInt(0, count - 1)] : -1;
}

public Action GiveRandomVip(int owner){
	char steamId[65];
	char group[] = "vip_group_1";
	int client = GetRandomClient();
	PrintToConsole(owner, "[DEBUG]\nclient = %i", client);
	int i = 0;
	while (WCS_GetVip(client)) {
		i++;
		client = GetRandomClient();
		if (i==MaxClients) {
			CGOPrintToChat(owner, "{purple}[RUSSIAN WCS] {default}%T", "AllPlayersWithVip", owner);
			break;
		}
			
	}
		
	char name[32];

	GetClientName(client, name, sizeof(name));

	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	//PrintToConsole(owner, "[DEBUG]\nSteamId = %s\nname = %s", steamId, name);
	WCS_GiveVIP(steamId, name, group,120);
	if (!WCS_GetVip(client))
		return Plugin_Handled;
	CGOPrintToChatAll("{purple}[RUSSIAN WCS] {green}%N{default} выиграл VIP!", client, owner);
	CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {default} Вы получили VIP на 2 часа от администрации.", client);
	//LogAction(owner, client, "%L give random vip to %L", owner, client);
	LogToFileEx("logs/ruswcs.log","%L give random vip to %L", owner, client);

	return Plugin_Continue;
}

public void OnClientConnected(int client){ 
	bCookie = RegClientCookie("bonus", "cookie for bonus", CookieAccess_Private);
	
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
	char buffer[64];
	bool isEmpty = true;
	int response;

	for (int iClient = 1; iClient <= MaxClients; iClient++) {

		if ((WCS_IsPlayerLoaded(iClient) && WCS_GetLvl(iClient) <= 1000) || !IsClientInGame(iClient) || IsFakeClient(iClient) || !WCS_IsPlayerLoaded(iClient)) {
				continue;
			}

		GetClientCookie(iClient, bCookie, buffer, sizeof(buffer));
		response = StringToInt(buffer);

		if(response == 0) {
			CGOPrintToChat(client, "{GREEN}%N{DEFAULT} еще не получал бонус.", iClient);
			--isEmpty;
		}
		
	}
	if(isEmpty == true){
		CGOPrintToChat(client, "{PURPLE}[RUSSIAN WCS]{DEFAULT} Бонус игрокам недоступен либо они уже знают о нем.");
	}

	return Plugin_Continue;
}

public Action Command_WcsBonus(int client, int args) {
	
	// char buffer[32];
	// GetClientAuthId(client, AuthId_Steam2, buffer, 32);
	// if (strcmp(buffer, MeOnly) != 0) {
		// return Plugin_Handled;
	// }
	
	
	
	char buffer[64];
	float lvlF;
	int lvl;
	int reply;
	

	
	GetClientCookie(client, bCookie, buffer, sizeof(buffer));
	reply = StringToInt(buffer);
	PrintToConsole(client, "[DEBUG]");
	PrintToConsole(client, "reply = %i", reply);
	if (reply != 0) {
		lvlF = float(reply);
		lvlF /=1000;
		reply = RoundToCeil(lvlF);
		PrintToConsole(client, "RoundNextLvl = %i", reply);
		for (int i = reply*1000; i < 50000; i+=1000) {
			
			reply = WCS_GetLvl(client);
			if(reply >= i) {
				WCS_GiveLBlvl(client, 40);
				
				lvl = WCS_GetLvl(client);
				
				IntToString(lvl, buffer, sizeof(buffer));
				SetClientCookie(client, bCookie, buffer);
				
				CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsGetBonus", i);
				//LogAction(client, -1, "Player %L received 40 lvls for to achieved %i lvls.", client, i);
				LogToFileEx("logs/ruswcs.log","Player %L received 40 lvls for to achieved %i lvls.", client, i);
			}
			else if (reply < i){
				CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsNoAccessBonus", i);
				
				lvl = WCS_GetLvl(client);
				IntToString(lvl, buffer, sizeof(buffer));
				SetClientCookie(client, bCookie, buffer);
				break;
			}
			else {
				CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsError");
				break;
			}
		}
	}
	else if(reply == 0) {
		lvl = WCS_GetLvl(client);
		IntToString(lvl, buffer, sizeof(buffer));
		SetClientCookie(client, bCookie, buffer);
		
		for (int i = 1000; i < 50000; i+=1000) {

			GetClientCookie(client, bCookie, buffer, sizeof(buffer));
			reply = StringToInt(buffer);
			if(reply >= i) {
				WCS_GiveLBlvl(client, 40);
				
				lvl = WCS_GetLvl(client);
				IntToString(lvl, buffer, sizeof(buffer));
				SetClientCookie(client, bCookie, buffer);
				
				CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsGetBonus", i);
				//LogAction(client, -1, "Player %L received 40 lvls for to achieved %i lvls.", client, i);
				LogToFileEx("logs/ruswcs.log","Player %L received 40 lvls for to achieved %i lvls.", client, i);
			}
			else if (reply < i){
				CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsNoAccessBonus", i);
				
				lvl = WCS_GetLvl(client);
				IntToString(lvl, buffer, sizeof(buffer));
				SetClientCookie(client, bCookie, buffer);
				PrintToConsole(client, "reply = 0");
				PrintToConsole(client, "reply < i");
				PrintToConsole(client, "reply = %i", reply);
				PrintToConsole(client, "i = %i", i);
				break;
			}
			else {
				CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsError");
				break;
			}
		}
	}
	else {
		CGOPrintToChat(client, "{purple}[RUSSIAN WCS] {DEFAULT}%t", "WcsError");
	}
	
	return Plugin_Continue;
}

public Action Command_WcsInfo(int client, int args)
{
	WcsInfo(client);
	return Plugin_Continue;	
}



public Action WcsInfo(int client){
		PrintToChat(client, " \x02Russian WCS \x01— это сервер, который строится на расах («уникальный персонаж со своими способностями»). ");
		PrintToChat(client, "Каждая раса является уникальной, то есть имеет свои способности. ");
		PrintToChat(client, "Цель игры заключается в прокачке рас для достижения более сильных.");
		PrintToChat(client, "Команды сервера:");
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




