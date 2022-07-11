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

ConVar 	gH_Cvar_Tomori_Purge_Enabled,				//Enable or disable Purge Module (0 - Disable, 1 - Enabled)
		gH_Cvar_Tomori_Purge_Days,					//Amount of days to purge after
		gH_Cvar_Tomori_Purge_Logging;				//Enable or disable Purge logging (0 - Disable, 1 - Enabled)

Database DB_Purge;
char 	gShadow_Tomori_Purge_LogFile[PLATFORM_MAX_PATH];

public void Purge_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Purge", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Purge_Enabled = AutoExecConfig_CreateConVar("tomori_purge_enabled", "0", "(CREATE BACKUP) Enable or disable Purge module in tomori (CREATE BACKUP)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Purge_Days = AutoExecConfig_CreateConVar("tomori_purge_days", "15", "Amount of days to purge after", 0, true, 0.0);
	gH_Cvar_Tomori_Purge_Logging = AutoExecConfig_CreateConVar("tomori_purge_logging", "1", "Enable or disable Purge logging", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Purge_Enabled.SetInt(0, true, false);

	char error[PLATFORM_MAX_PATH];
	DB_Purge = SQL_Connect("clientprefs", true, error, sizeof(error));
	
	if (!LibraryExists("clientprefs") || DB_Purge == INVALID_HANDLE)
	{
		gH_Cvar_Tomori_Purge_Enabled.SetInt(0, true, false);
		LogToFileEx(gShadow_Tomori_LogFile, "Purge disabled. Error: %s", error);
	}

	char Folder[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Folder, sizeof(Folder), "logs/Entity");
	EMP_DirExistsEx(Folder);
	EMP_SetLogFile(gShadow_Tomori_Purge_LogFile, "Tomori-Purge", "Entity");
}

public void Purge_OnMapStart()
{
	if (gH_Cvar_Tomori_Purge_Enabled.BoolValue)
	{
		char query[512];
		FormatEx(query, sizeof(query), "DELETE FROM sm_cookie_cache WHERE timestamp <= %i; VACUUM", GetTime() - (gH_Cvar_Tomori_Purge_Days.IntValue * 86400));
		SQL_TQuery(DB_Purge, CP_PurgeCallback, query);
	}
}

public void Purge_OnClientCookiesCached(int client)
{
	char client_steamid[MAX_NAME_LENGTH];

	if (GetClientAuthId(client, AuthId_Steam2, client_steamid, sizeof(client_steamid)) && gH_Cvar_Tomori_Purge_Enabled.BoolValue)
	{
		char query[512], safe_steamid[(MAX_NAME_LENGTH*2)+1];
		SQL_EscapeString(DB_Purge, client_steamid, safe_steamid, sizeof(safe_steamid));

		FormatEx(query, sizeof(query), "UPDATE sm_cookie_cache SET timestamp = %i WHERE player = '%s'", GetTime(), safe_steamid);
		SQL_TQuery(DB_Purge, CP_CheckErrors, query);
	}
}

public void CP_CheckErrors(Handle owner, Handle handle, char[] error, any data)
{
	if (error[0]) LogToFileEx(gShadow_Tomori_LogFile, "Purge error: %s", error);
}

public void CP_PurgeCallback(Handle owner, Handle handle, char[] error, any data)
{
	if (SQL_GetAffectedRows(owner) && gH_Cvar_Tomori_Purge_Enabled.BoolValue)
	{
		if (gH_Cvar_Tomori_Purge_Logging.BoolValue) LogToFileEx(gShadow_Tomori_Purge_LogFile, "Clientprefs Purged: Cookies of %i players was removed due of inactivity.", SQL_GetAffectedRows(owner));
	}
}