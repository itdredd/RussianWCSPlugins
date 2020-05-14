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
#include <cstrike>
#include <dbi>
#include <autoexecconfig>
#include <wcs>

// sm plugins refresh ruswcs_stats.smx

public Plugin myinfo = 
{
	name = "RUS Stats",
	author = "Dredd",
	description = "Additional functional for Russian servers.",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

Database g_hDatabase;
Handle hServer;

public void OnPluginStart()
{
    AutoExecConfig_SetFile("ru_stats");

    AutoExecConfig_CreateConVar("rustats_enable", "0", "Whether or not this plugin is enabled");
    AutoExecConfig_CreateConVar("rustats_servername", "none", "RUS Stats ServerName");

    AutoExecConfig_ExecuteFile();

    CheckOnEnable();

    Database.Connect(ConnectCallBack, "wcs_rus");
    RegConsoleCmd("ruswcs_stats_check", Command_Check);
}

public void WCS_OnClientLoaded(int client) {
    char szAuth[32], szQuery[256], tableName[16];
    int lvl = WCS_GetLvl(client);

    hServer = FindConVar("rustats_servername");
    GetConVarString(hServer, tableName, sizeof(tableName));
    GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));

    FormatEx(szQuery, sizeof(szQuery), "UPDATE `%s` SET `lvl` = '%i' WHERE `steamId` =  '%s';", tableName, lvl, szAuth);
    g_hDatabase.Query(SQL_Query_Callback, szQuery);

}

public void OnClientPostAdminCheck(int client) {

    if (!IsClientInGame(client) || IsFakeClient(client)) {
        return;
    }

    

    char szAuth[32], szQuery[256], tableName[16];
    
    hServer = FindConVar("rustats_servername");
    GetConVarString(hServer, tableName, sizeof(tableName));
    GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));

    FormatEx(szQuery, sizeof(szQuery), "INSERT INGNORE INTO `%s` (`steamId`) VALUES ('%s');", tableName, szAuth);
    //PrintToServer(szQuery);
    g_hDatabase.Query(SQL_Query_Callback, szQuery);
    
}



void CheckOnEnable() {
    Handle g_hBuffer = FindConVar("rustats_enable");
    if(GetConVarBool(g_hBuffer) == false ){
        PrintToServer("RUS Stats was unloaded.");
        ServerCommand("sm plugins unload ruswcs_stats.smx");
    } 
}

public Action Command_Check(int client, int args){

    char szAuth[32], szQuery[256], tableName[16];
    
    hServer = FindConVar("rustats_servername");
    GetConVarString(hServer, tableName, sizeof(tableName));
    GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));

    FormatEx(szQuery, sizeof(szQuery), "INSERT IGNORE INTO `%s` (`steamId`) VALUES ('%s');", tableName, szAuth);
    //PrintToServer(szQuery);
    g_hDatabase.Query(SQL_Query_Callback, szQuery);
    return Plugin_Continue;
}

/* SQL */


public void ConnectCallBack (Database hDB, const char[] szError, any data) // Пришел результат соединения
{
	if (hDB == null || szError[0]) {
		SetFailState("Database failure: %s", szError); // Отключаем плагин
		return;
	}
	g_hDatabase = hDB; // Присваиваем глобальной переменной соединения значение текущего соединения
	CreateTables(); // Функция пока не реализована, но по имени, думаю, ясно что она делает
}

public void CreateTables() {    
    hServer = FindConVar("rustats_servername");
    char tableName[16];
    GetConVarString(hServer, tableName, sizeof(tableName));


    char szQuery[256];
    FormatEx(szQuery, sizeof(szQuery), "CREATE TABLE IF NOT EXISTS `%s` (`steamId` VARCHAR(32) UNIQUE, `lvl` INTEGER NOT NULL);", tableName);
    g_hDatabase.Query(SQL_Query_Callback, szQuery);
    //PrintToChatAll("Done");
}

public void SQL_Query_Callback(Database hDatabase, DBResultSet results, const char[] sError, any data) {
	if(sError[0]) {
	LogError("SQL_Callback_Create: %s", sError); // Выводим в лог
	return; // Прекращаем выполнение ф-и
	}
}