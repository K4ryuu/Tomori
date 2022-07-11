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

ConVar 	gH_Cvar_Tomori_Profile_Enabled,						//Enable or disable Profile Module (0 - Disable, 1 - Enabled)
		gH_Cvar_Tomori_Profile_ApiKey,						//Api key to get Data from steam
		gH_Cvar_Tomori_Profile_MinHours,					//Minimum hour to play to join
		gH_Cvar_Tomori_Profile_MinLevel,					//Minimum steam level to join
		gH_Cvar_Tomori_Profile_IgnoreAdmins,				//Disable admin check on joining
		gH_Cvar_Tomori_Profile_IgnoreFlag,					//Admin flag to ignore
		gH_Cvar_Tomori_Profile_OnlyPrime,					//Minimum steam level to play in server
		gH_Cvar_Tomori_Profile_MinHours_NP,					//Minimum hour to play to join for non primes
		gH_Cvar_Tomori_Profile_MinLevel_NP;					//Minimum steam level to play to join for non primes

static char cAPIKey[64];
static Regex r_ApiKey;

bool 	gShadow_Tomori_UserAdmin[MAXPLAYERS+1] = false;

public void Profile_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Profile", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Profile_Enabled = AutoExecConfig_CreateConVar("tomori_profile_enabled", "1", "Enable or disable profile module in tomori:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Profile_ApiKey = AutoExecConfig_CreateConVar("tomori_profile_apikey", "", "Api key to get Data from steam", FCVAR_PROTECTED);
	
	gH_Cvar_Tomori_Profile_MinHours = AutoExecConfig_CreateConVar("tomori_profile_minhours", "100", "Minimum hour to play to join", 0, true, 0.0);
	gH_Cvar_Tomori_Profile_MinLevel = AutoExecConfig_CreateConVar("tomori_profile_minlevels", "1", "Minimum steam level to join", 0, true, 0.0);
	
	gH_Cvar_Tomori_Profile_IgnoreAdmins = AutoExecConfig_CreateConVar("tomori_profile_ignorevips", "1", "Disable vip check on joining", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Profile_OnlyPrime = AutoExecConfig_CreateConVar("tomori_profile_onlyprime", "2", "Enable or disable onlyprime (0 - Disable, 1 - Block Non-Prime, 2 - NonPrime with Custom Rules)", 0, true, 0.0, true, 2.0);
	gH_Cvar_Tomori_Profile_MinHours_NP = AutoExecConfig_CreateConVar("tomori_profile_minhours_nonprime", "200", "Minimum hour to play to join for non prime players", 0, true, 0.0);
	gH_Cvar_Tomori_Profile_MinLevel_NP = AutoExecConfig_CreateConVar("tomori_profile_minlevels_nonprime", "1", "Minimum steam level to join for non prime players", 0, true, 0.0);
	
	gH_Cvar_Tomori_Profile_IgnoreFlag = AutoExecConfig_CreateConVar("tomori_profile_ignoreflag", "a", "Flag to pass check on join (if ignorevips is 1)", 0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Profile_Enabled.SetInt(0, true, false);

	r_ApiKey = CompileRegex("^[0-9A-Z]*$");
}

public void Profile_CheckApi()
{
	if (gH_Cvar_Tomori_Profile_Enabled.BoolValue)
	{
		gH_Cvar_Tomori_Profile_ApiKey.GetString(cAPIKey, sizeof(cAPIKey));
		
		if (strlen(cAPIKey) > 0)
		{
			#if (MODULE_LOGGING == 1)
				if (!IsAPIKeyCorrect(cAPIKey, r_ApiKey))
					LogToFileEx(gShadow_Tomori_LogFile, "Steam-API Key is Invalid in tomori_profile_apikey | Use cfg/tomori/module_profile.cfg to enter a key.");
			#endif
		}
	}
}

public void Profile_OnConfigsExecuted()
{
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (EMP_IsValidClient(idx))
		{
			Profile_OnClientPostAdminCheck(idx);
		}
	}
}

public void Profile_OnClientPostAdminCheck(int client)
{
	if (gH_Cvar_Tomori_Profile_Enabled.BoolValue) 
	{
		Profile_CheckApi();
	
		if (!EMP_IsValidClient(client))
			return;
			
		char auth[40];
		GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
		
		char ignoreflag[32];
		gH_Cvar_Tomori_Profile_IgnoreFlag.GetString(ignoreflag, sizeof(ignoreflag));
		
		int ign_flag = EMP_Flag_StringToInt(ignoreflag);
		
		if (Client_HasAdminFlags(client, ign_flag))
			gShadow_Tomori_UserAdmin[client] = true;
		
		RequestHours(client, auth);
	}
}

void RequestHours(int client, char[] auth)
{
	Handle request = CreateRequest_RequestHours(client, auth);
	SteamWorks_SendHTTPRequest(request);
}

Handle CreateRequest_RequestHours(int client, char[] auth)
{
	char request_url[512];
	
	FormatEx(request_url, sizeof(request_url), "http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=%s&include_played_free_games=1&appids_filter[0]=%i&steamid=%s&format=json", cAPIKey, GetAppID(), auth);
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, request_url);
	
	SteamWorks_SetHTTPRequestContextValue(request, client);
	SteamWorks_SetHTTPCallbacks(request, RequestHours_OnHTTPResponse);
	return request;
}

public int RequestHours_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		#if (MODULE_LOGGING == 1)
			if (!IsAPIKeyCorrect(cAPIKey, r_ApiKey)) LogToFileEx(gShadow_Tomori_LogFile, "HTTP Request on HourCheck failed!");
		#endif
		delete request;
		return;
	}
	
	int bufferSize;	
	SteamWorks_GetHTTPResponseBodySize(request, bufferSize);
	
	char[] responseBody = new char[bufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, responseBody, bufferSize);
	delete request;
	
	int playedTime = GetPlayerHours(responseBody);
	int totalPlayedTime = playedTime / 60;
	
	if (k_EUserHasLicenseResultDoesNotHaveLicense == SteamWorks_HasLicenseForApp(client, 624820))
	{
		gShadow_Tomori_Client_Prime[client] = false;
	
		if (gH_Cvar_Tomori_Profile_OnlyPrime.IntValue == 1)
		{
			if (!gShadow_Tomori_UserAdmin[client] || !gH_Cvar_Tomori_Profile_IgnoreAdmins.BoolValue) KickClient(client, "%t", "Tomori Profile KickPrimeOnly");
			return;
		}
		else if (gH_Cvar_Tomori_Profile_OnlyPrime.IntValue == 2)
		{
			if (!totalPlayedTime && (gH_Cvar_Tomori_Profile_MinHours_NP.IntValue != 0))
			{
				KickClient(client, "%t", "Tomori Profile KickInvisible");
				return;
			}
			else if ((totalPlayedTime > 0) && (gH_Cvar_Tomori_Profile_MinHours_NP.IntValue != 0) && totalPlayedTime != 0)
			{
				if (totalPlayedTime < gH_Cvar_Tomori_Profile_MinHours_NP.IntValue)
				{
					if (!gShadow_Tomori_UserAdmin[client] || !gH_Cvar_Tomori_Profile_IgnoreAdmins.BoolValue) KickClient(client, "%t", "Tomori Profile KickNotEnough NonPrime", totalPlayedTime, gH_Cvar_Tomori_Profile_MinHours_NP.IntValue);
					return;
				}
				gShadow_Tomori_Client_Hour[client] = totalPlayedTime;
			}
			
			if (gH_Cvar_Tomori_Profile_MinLevel_NP.IntValue != 0)
			{
				char auth[40];
				GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));	
			
				RequestLevel(client, auth);
			}
		}
	}
	else
		gShadow_Tomori_Client_Prime[client] = true;

	if (!totalPlayedTime && (gH_Cvar_Tomori_Profile_MinHours.IntValue != 0))
	{
		KickClient(client, "%t", "Tomori Profile KickInvisible");
		return;
	}
	else if ((totalPlayedTime > 0) && (gH_Cvar_Tomori_Profile_MinHours.IntValue != 0) && totalPlayedTime != 0)
	{
		if ((!gShadow_Tomori_UserAdmin[client] || !gH_Cvar_Tomori_Profile_IgnoreAdmins.BoolValue) && (totalPlayedTime < gH_Cvar_Tomori_Profile_MinHours.IntValue))
		{
			KickClient(client, "%t", "Tomori Profile KickNotEnough", totalPlayedTime, gH_Cvar_Tomori_Profile_MinHours.IntValue);
			return;
		}
		gShadow_Tomori_Client_Hour[client] = totalPlayedTime;
	}
	
	if (gH_Cvar_Tomori_Profile_MinLevel.IntValue != 0)
	{
		char auth[40];
		GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));	
	
		RequestLevel(client, auth);
	}
}

void RequestLevel(int client, char[] auth)
{
	Handle request = CreateRequest_RequestLevel(client, auth);
	SteamWorks_SendHTTPRequest(request);
}

Handle CreateRequest_RequestLevel(int client, char[] auth)
{
	char request_url[512];
	FormatEx(request_url, sizeof(request_url), "https://api.steampowered.com/IPlayerService/GetSteamLevel/v1/?key=%s&format=json&input_json={\"steamid\":%s}", cAPIKey, auth);
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, request_url);
	
	SteamWorks_SetHTTPRequestContextValue(request, client);
	SteamWorks_SetHTTPCallbacks(request, RequestLevel_OnHTTPResponse);
	return request;
}

public int RequestLevel_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		#if (MODULE_LOGGING == 1)
			if (!IsAPIKeyCorrect(cAPIKey, r_ApiKey)) LogToFileEx(gShadow_Tomori_LogFile, "HTTP Request on HourCheck failed!");
		#endif
		delete request;
		return;
	}
	
	int bufferSize;

	SteamWorks_GetHTTPResponseBodySize(request, bufferSize);

	char[] responseBody = new char[bufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, responseBody, bufferSize);
	delete request;

	int UserLevel = GetPlayerLevel(responseBody);
	gShadow_Tomori_Client_Level[client] = UserLevel;
	
	if ((k_EUserHasLicenseResultDoesNotHaveLicense == SteamWorks_HasLicenseForApp(client, 624820)) && (UserLevel < gH_Cvar_Tomori_Profile_MinLevel_NP.IntValue))
	{
		if (!gShadow_Tomori_UserAdmin[client] || !gH_Cvar_Tomori_Profile_IgnoreAdmins.BoolValue) KickClient(client, "%t", "Tomori Profile KickLowLevel NonPrime", UserLevel, gH_Cvar_Tomori_Profile_MinLevel_NP.IntValue);
		return;
	}
	
	if (UserLevel < gH_Cvar_Tomori_Profile_MinLevel.IntValue)
	{
		if (!gShadow_Tomori_UserAdmin[client] || !gH_Cvar_Tomori_Profile_IgnoreAdmins.BoolValue) KickClient(client, "%t", "Tomori Profile KickLowLevel", UserLevel, gH_Cvar_Tomori_Profile_MinLevel.IntValue);
		return;
	}
}