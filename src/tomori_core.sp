/*
 * SourceMod Entity Projects
 * by: Entity
 *
 * Copyright (C) 2020 Kőrösfalvi "Entity" Martin
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <autoexecconfig>
#include <multicolors>
#include <basecomm>
#include <emitsoundany>
#include <smlib>
#include <steamworks>
#include <profilestatus>
#include <stocksoup/version>
#include <geoip>
#include <clientprefs>
#include <emperor>
#include <unixtime_sourcemod>
#include <ptah>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <chat-processor>
#include <sourcebanspp>
#include <ccprocessor>
#include <sourcecomms>
#include <ctban>
#include <teambans>
#include <myjailbreak>
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

#define TOMORI_NAME			  "[CSGO] Tomori <3 - v3.0b"
#define TOMORI_VERSION		  "3.0b"

#define MODULE_NAME			  1
#define MODULE_AI				  1
#define MODULE_FILTERS		  1
#define MODULE_ENFORCER		  1
#define MODULE_PROFILE		  1
#define MODULE_BLOCKS		  1
#define MODULE_COUNTRY		  1
#define MODULE_PURGE			  1
#define MODULE_WATCHADMIN	  1
#define MODULE_GATHERING	  1
#define MODULE_ANTISLAM		  1
#define MODULE_TAGS			  1
#define MODULE_LOGGING		  1
#define MODULE_EXTRACOMMANDS 1
#define MODULE_AUTOJOIN		  1
#define MODULE_NODISARM		  1
#define MODULE_LOCKER		  1

ConVar gH_Cvar_Tomori_Enabled,
	gH_Cvar_Tomori_ChatPrefix;

char ServerIP[64],
	gShadow_Tomori_ChatPrefix[256],
	gShadow_Tomori_LogFile[PLATFORM_MAX_PATH],
	WordList[PLATFORM_MAX_PATH],
	WordCount[512][64],
	Replace_Special[128]											  = "§\'~\"+^!%/`=()¸.:;?,*<>_-@&#$[]{}|\\  ";

bool gShadow_CTBanFound											  = false,
	  gShadow_TeamBanFound										  = false,
	  gShadow_MYJBBanFound										  = false,
	  gShadow_Admin_HideMe[MAXPLAYERS + 1]					  = false,
	  gShadow_Tomori_ChangedTeamByTomori[MAXPLAYERS + 1] = false,
	  gShadow_Tomori_Client_Prime[MAXPLAYERS + 1]		  = true,
	  Filters_Loaded												  = false,
	  ReadCompleted												  = false;

int gShadow_Tomori_Client_Level[MAXPLAYERS + 1],
	gShadow_Tomori_Client_Hour[MAXPLAYERS + 1],
	WordLines,
	InitializeTime;

Regex R_Website,
	R_Ip,
	R_Dot;

#if (MODULE_NAME == 1)
	#include "modules/module_name.sp"
#endif

#if (MODULE_LOCKER == 1)
	#include "modules/module_locker.sp"
#endif

#if (MODULE_TAGS == 1)
	#include "modules/module_tags.sp"
#endif

#if (MODULE_AI == 1)
	#include "modules/module_ai.sp"
#endif

#if (MODULE_FILTERS == 1)
	#include "modules/module_filters.sp"
#endif

#if (MODULE_ENFORCER == 1)
	#include "modules/module_enforcer.sp"
#endif

#if (MODULE_PROFILE == 1)
	#include "modules/module_profile.sp"
#endif

#if (MODULE_BLOCKS == 1)
	#include "modules/module_blocks.sp"
#endif

#if (MODULE_COUNTRY == 1)
	#include "modules/module_country.sp"
#endif

#if (MODULE_PURGE == 1)
	#include "modules/module_purge.sp"
#endif

#if (MODULE_WATCHADMIN == 1)
	#include "modules/module_watchadmin.sp"
#endif

#if (MODULE_GATHERING == 1)
	#include "modules/module_gathering.sp"
#endif

#if (MODULE_ANTISLAM == 1)
	#include "modules/module_antislam.sp"
#endif

#if (MODULE_EXTRACOMMANDS == 1)
	#include "modules/module_extracmd.sp"
#endif

#if (MODULE_AUTOJOIN == 1)
	#include "modules/module_autojoin.sp"
#endif

#if (MODULE_NODISARM == 1)
	#include "modules/module_nodisarm.sp"
#endif

public Plugin myinfo =
{
	name			= TOMORI_NAME,
	author		= "Entity",
	description = "Tomori Management Bot from Entity - Made with <3",
	version		= TOMORI_VERSION
};

public void OnPluginStart()
{
	char Folder[256];
	BuildPath(Path_SM, Folder, sizeof(Folder), "logs/Entity");
	EMP_DirExistsEx(Folder);

	EMP_SetLogFile(gShadow_Tomori_LogFile, "Tomori-Logs", "Entity");

	LoadTranslations("ent_tomori.phrases");
	EMP_DirExistsEx("cfg/Tomori");

	gShadow_CTBanFound	= LibraryExists("ctban");
	gShadow_MYJBBanFound = LibraryExists("myjailbreak");
	gShadow_TeamBanFound = LibraryExists("teambans");

	AutoExecConfig_SetFile("Core", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Enabled	  = AutoExecConfig_CreateConVar("tomori_enabled", "1", "Enable or disable Tomori AI from Entity:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_ChatPrefix = AutoExecConfig_CreateConVar("sm_tomori_chat_banner", "{default}[{lightred}Tomori{default} {blue}", "Edit ChatTag for Tomori (Colors can be used).");

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	HookConVarChange(gH_Cvar_Tomori_ChatPrefix, OnCvarChange);

#if (MODULE_NAME == 1)
	Name_OnPluginStart();
#endif
#if (MODULE_BLOCKS == 1)
	Blocks_OnPluginStart();
#endif
#if (MODULE_FILTERS == 1)
	Filters_OnPluginStart();
#endif
#if (MODULE_EXTRACOMMANDS == 1)
	ExtraCMD_OnPluginStart();
#endif
#if (MODULE_PROFILE == 1)
	Profile_OnPluginStart();
#endif
#if (MODULE_GATHERING == 1)
	Gather_OnPluginStart();
#endif
#if (MODULE_PURGE == 1)
	Purge_OnPluginStart();
#endif
#if (MODULE_WATCHADMIN == 1)
	Watchadmin_OnPluginStart();
#endif
#if (MODULE_AI == 1)
	AI_OnPluginStart();
#endif
#if (MODULE_ENFORCER == 1)
	Enforcer_OnPluginStart();
#endif
#if (MODULE_TAGS == 1)
	Tags_OnPluginStart();
#endif
#if (MODULE_COUNTRY == 1)
	CountryFilter_OnPluginStart();
#endif
#if (MODULE_AUTOJOIN == 1)
	AutoJoin_OnPluginStart();
#endif
#if (MODULE_ANTISLAM == 1)
	Antislam_OnPluginStart();
#endif
#if (MODULE_LOCKER == 1)
	Locker_OnPluginStart();
#endif
#if (MODULE_NODISARM == 1)
	NoDisarm_OnPluginStart();
#endif

	HookEvent("round_start", Event_RoundStart);

	AddCommandListener(JoinTeamCmd, "jointeam");

	InitializeTime = GetTime();

	Handle request = CreateRequest_RequestIp();
	SteamWorks_SendHTTPRequest(request);
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "ctban") == 0)
	{
		gShadow_CTBanFound = true;
	}
	else if (strcmp(name, "myjailbreak") == 0)
	{
		gShadow_MYJBBanFound = true;
	}
	else if (strcmp(name, "teambans") == 0)
	{
		gShadow_TeamBanFound = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "ctban") == 0)
	{
		gShadow_CTBanFound = false;
	}
	else if (strcmp(name, "myjailbreak") == 0)
	{
		gShadow_MYJBBanFound = false;
	}
	else if (strcmp(name, "teambans") == 0)
	{
		gShadow_TeamBanFound = false;
	}
}

public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
#if (MODULE_AUTOJOIN == 1)
	AutoJoin_Event_RoundStart(event, name, dontBroadcast);
#endif
#if (MODULE_EXTRACOMMANDS == 1)
	ExtraCMD_Event_RoundStart(event, name, dontBroadcast);
#endif
}

public void OnCvarChange(ConVar cvar, char[] oldvalue, char[] newvalue)
{
	if (cvar == gH_Cvar_Tomori_ChatPrefix)
	{
		char buffer[128];
		GetConVarString(gH_Cvar_Tomori_ChatPrefix, buffer, sizeof(buffer));
		FormatEx(gShadow_Tomori_ChatPrefix, sizeof(gShadow_Tomori_ChatPrefix), "%s ", buffer);

		EMP_ProcessColors(gShadow_Tomori_ChatPrefix, sizeof(gShadow_Tomori_ChatPrefix));
	}
}

public Action JoinTeamCmd(int client, char[] command, int argc)
{
#if (MODULE_COUNTRY == 1)
	Country_JoinTeamCmd(client, command, argc);
#endif
#if (MODULE_AUTOJOIN == 1)
	AutoJoin_JoinTeamCmd(client, command, argc);
#endif
}

public void OnClientCookiesCached(int client)
{
#if (MODULE_PURGE == 1)
	Purge_OnClientCookiesCached(client);
#endif
}

public void OnClientPutInServer(int client)
{
#if (MODULE_NAME == 1)
	Name_OnClientPutInServer(client);
#endif
#if (MODULE_EXTRACOMMANDS == 1)
	ExtraCMD_OnClientPutInServer(client);
#endif
}

public void OnConfigsExecuted()
{
	char buffer[128];
	GetConVarString(gH_Cvar_Tomori_ChatPrefix, buffer, sizeof(buffer));
	FormatEx(gShadow_Tomori_ChatPrefix, sizeof(gShadow_Tomori_ChatPrefix), "%s ", buffer);

	EMP_ProcessColors(gShadow_Tomori_ChatPrefix, sizeof(gShadow_Tomori_ChatPrefix));

	Handle request = CreateRequest_RequestIp();
	SteamWorks_SendHTTPRequest(request);

#if (MODULE_PROFILE == 1)
	Profile_OnConfigsExecuted();
#endif
#if (MODULE_LOCKER == 1)
	Lock_OnConfigsExecuted();
#endif
}

public void OnClientPostAdminCheck(int client)
{
#if (MODULE_PROFILE == 1)
	Profile_OnClientPostAdminCheck(client);
#endif
#if (MODULE_TAGS == 1)
	Tags_OnClientPostAdminCheck(client);
#endif
}

public void OnClientDisconnect(int client)
{
#if (MODULE_TAGS == 1)
	Tags_OnClientDisconnect(client);
#endif
}

public void OnMapStart()
{
	Handle request = CreateRequest_RequestIp();
	SteamWorks_SendHTTPRequest(request);

#if (MODULE_NAME == 1)
	Name_OnMapStart();
#endif
#if (MODULE_BLOCKS == 1)
	Blocks_OnMapStart();
#endif
#if (MODULE_FILTERS == 1)
	Filters_OnMapStart();
#endif
#if (MODULE_EXTRACOMMANDS == 1)
	ExtraCMD_OnMapStart();
#endif
#if (MODULE_PURGE == 1)
	Purge_OnMapStart();
#endif
#if (MODULE_WATCHADMIN == 1)
	Watchadmin_OnMapStart();
#endif
#if (MODULE_AI == 1)
	AI_OnMapStart();
#endif
#if (MODULE_ENFORCER == 1)
	Enforcer_OnMapStart();
#endif
}

public Handle CreateRequest_RequestIp()
{
	char request_url[512];

	FormatEx(request_url, sizeof(request_url), "https://ip.seeip.org/jsonip?");
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, request_url);

	int	 client	= 0;
	SteamWorks_SetHTTPRequestContextValue(request, client);
	SteamWorks_SetHTTPCallbacks(request, RequestIp_OnHTTPResponse);
	return request;
}

public int RequestIp_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		delete request;
		return;
	}

	int bufferSize;

	SteamWorks_GetHTTPResponseBodySize(request, bufferSize);

	char[] responseBody = new char[bufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, responseBody, bufferSize);
	delete request;

	if (strlen(responseBody) > 0)
	{
		TrimString(responseBody);
		ReplaceString(responseBody, bufferSize, "{\"ip\":\"", "");
		ReplaceString(responseBody, bufferSize, "\"}", "");

		int Port = GetConVarInt(FindConVar("hostport"));
		FormatEx(ServerIP, sizeof(ServerIP), "%s:%d", responseBody, Port);
	}
}

public void OnMapEnd()
{
#if (MODULE_NAME == 1)
	Name_OnMapEnd();
#endif
}