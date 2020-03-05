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
	HookEvent("round_start", OnRoundStart);
	
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast){
	
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
				CGOPrintToChat(iClient, "{GREEN}[RUSSIAN WCS] {default}Вы поблагодарили игроков.");
				continue;
			}
			
			WCS_GiveLBlvl(iClient, 5);
			
			CGOPrintToChat(iClient, "{GREEN}[RUSSIAN WCS] {default}%t", "WcsGiveAway", client);

			LogToFile("logs/bonus.log","Игрок - %L получил 5 уровней от %L.", iClient, client);
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
			PrintToConsole(client, "%N еще не получал бонус.", iClient);
			--isEmpty;
		}
		
	}
	if(isEmpty == true){
		PrintToConsole(client, "[RUSSIAN WCS] Бонус игрокам недоступен либо они уже знают о нем.");
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
				
				CGOPrintToChat(client, "{GREEN}[RUSSIAN WCS] {DEFAULT}%t", "WcsGetBonus", i);
				LogToFile("logs/bonus.log","Игрок - %L получил 40 уровней за достижение %i уровня.", client, i);
			}
			else if (reply < i){
				CGOPrintToChat(client, "{GREEN}[RUSSIAN WCS] {DEFAULT}%t", "WcsNoAccessBonus", i);
				
				lvl = WCS_GetLvl(client);
				IntToString(lvl, buffer, sizeof(buffer));
				SetClientCookie(client, bCookie, buffer);
				break;
			}
			else {
				CGOPrintToChat(client, "{GREEN}[RUSSIAN WCS] {DEFAULT}%t", "WcsError");
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
				
				CGOPrintToChat(client, "{GREEN}[RUSSIAN WCS] {DEFAULT}%t", "WcsGetBonus", i);
				LogToFile("logs/bonus.log","Игрок - %L получил 40 уровней за достижение %i уровня.", client, i);
			}
			else if (reply < i){
				CGOPrintToChat(client, "{GREEN}[RUSSIAN WCS] {DEFAULT}%t", "WcsNoAccessBonus", i);
				
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
				CGOPrintToChat(client, "{GREEN}[RUSSIAN WCS] {DEFAULT}%t", "WcsError");
				break;
			}
		}
	}
	else {
		CGOPrintToChat(client, "{GREEN}[RUSSIAN WCS] {DEFAULT}%t", "WcsError");
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
		PrintToChat(client, "«\x04/gb\x01» — банк золота.");
		PrintToChat(client, "«\x4/wcshop\x01» — магазин.");
		PrintToChat(client, "«\x04/wcsbonus\x01» — бонус за достижения определенного уровня.");
		CGOPrintToChat(client, "«{GREEN}/steamgroup{DEFAULT}» — ссылку на группу, при активации тега которой, Вы будете получать на 10% больше опыта.");
		CGOPrintToChat(client, "«{GREEN}/contact{DEFAULT}» — контакты администратора, у которого можно приобрести донат.");
		CGOPrintToChat(client, "«{GREEN}/viptest{DEFAULT}» — получение временной vip-группы для тестирования.");
		CGOPrintToChat(client, "«{GREEN}/cr{DEFAULT}» — команда для быстрой смены расы.");
		CGOPrintToChat(client, "«{GREEN}/ri{DEFAULT}» — команда для получения информации о расе.");
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




