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

ConVar 	gH_Cvar_Tomori_Tags_Enabled,					//Enable or disable Tags Module (0 - Disable, 1 - Enabled)
		gH_Cvar_Tomori_Tags_ToggleFlag;

Handle 	gShadow_Tomori_Client_ForceClan[MAXPLAYERS+1] 		= INVALID_HANDLE,
		gCookie_Tomori_Client_Toggled						= INVALID_HANDLE;

char 	gH_Cvar_Tomori_Tags_Flag[PLATFORM_MAX_PATH],
		gH_Cvar_Tomori_Tags_SteamID[PLATFORM_MAX_PATH],
		gShadow_Tomori_Client_Tag[MAXPLAYERS+1][64],
		gShadow_Tomori_Client_CTag[MAXPLAYERS+1][64],
		gShadow_Tomori_Client_TColor[MAXPLAYERS+1][64],
		gShadow_Tomori_Client_NColor[MAXPLAYERS+1][64],
		gShadow_Tomori_Client_CColor[MAXPLAYERS+1][64],
		gShadow_Tomori_Symbols[16]							= "	";

bool 	gShadow_Tomori_Client_Custom[MAXPLAYERS+1] 			= false,
		gShadow_Tomori_Client_RainbowT[MAXPLAYERS+1] 		= false,
		gShadow_Tomori_Client_RainbowC[MAXPLAYERS+1] 		= false,
		gShadow_Tomori_Client_RainbowN[MAXPLAYERS+1] 		= false,
		gShadow_Tomori_Client_RandomT[MAXPLAYERS+1] 		= false,
		gShadow_Tomori_Client_RandomC[MAXPLAYERS+1] 		= false,
		gShadow_Tomori_Client_RandomN[MAXPLAYERS+1] 		= false,
		gShadow_Tomori_Client_ToggleTags[MAXPLAYERS+1] 		= true;

public void Tags_OnPluginStart()
{
	BuildPath(Path_SM, gH_Cvar_Tomori_Tags_Flag, sizeof(gH_Cvar_Tomori_Tags_Flag), "configs/Tomori/tags_flags.txt");
	BuildPath(Path_SM, gH_Cvar_Tomori_Tags_SteamID, sizeof(gH_Cvar_Tomori_Tags_SteamID), "configs/Tomori/tags_steamid.txt");

	AutoExecConfig_SetFile("Module_Tags", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Tags_Enabled = AutoExecConfig_CreateConVar("tomori_tags_enabled", "1", "Enable or disable Tags Module (0 - Disable, 1 - Enabled)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Tags_ToggleFlag = AutoExecConfig_CreateConVar("tomori_tags_enabled", "a", "The flag to use the command to toggle your chat tag benefits", 0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	gCookie_Tomori_Client_Toggled = RegClientCookie("Tomori_Tags_Toggled", "Tomori Tag Toggle", CookieAccess_Private);
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Tags_Enabled.SetInt(0, true, false);

	
	char toggle_flag[32];
	gH_Cvar_Tomori_Tags_ToggleFlag.GetString(toggle_flag, sizeof(toggle_flag));
		
	int tt_flag = EMP_Flag_StringToInt(toggle_flag);
	
	RegAdminCmd("sm_tag", Command_ToggleTag, tt_flag, "Toggle the chat and scoreboard tag what comes with your rank");
	
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (gH_Cvar_Tomori_Tags_Enabled.BoolValue)
		{
			if (EMP_IsValidClient(idx))
			{
				Tags_OnClientPostAdminCheck(idx);
			}
		}
	}
}

public Action Command_ToggleTag(int client, int args)
{
	if (gH_Cvar_Tomori_Tags_Enabled.BoolValue && EMP_IsValidClient(client))
	{
		if (!gShadow_Tomori_Client_ToggleTags[client])
		{
			if (gShadow_Tomori_Client_ForceClan[client] == INVALID_HANDLE)
				gShadow_Tomori_Client_ForceClan[client] = CreateTimer(1.0, Timer_ForceClanTag, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Tags Enabled");
				
			gShadow_Tomori_Client_ToggleTags[client] = true;
			SetClientCookie(client, gCookie_Tomori_Client_Toggled, "1");
		}
		else
		{
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Tags Disabled");
				
			gShadow_Tomori_Client_ToggleTags[client] = false;
			SetClientCookie(client, gCookie_Tomori_Client_Toggled, "0");
		}
	}
	return Plugin_Handled;
}

public void Tags_OnClientDisconnect(int client)
{
	if (gH_Cvar_Tomori_Tags_Enabled.BoolValue) ResetClientID(client);
}

public void Tags_OnClientPostAdminCheck(int client)
{
	if (gH_Cvar_Tomori_Tags_Enabled.BoolValue)
	{
		ResetClientID(client);
		
		if (EMP_IsValidClient(client))
		{
			CreateTimer(0.3, Timer_CheckCookie, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
			if (!IsClientInSteamList(client))
				GetUserTagByFlag(client);
		}
	}
}

public Action Timer_CheckCookie(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	if (!EMP_IsValidClient(client)) return Plugin_Stop;
	
	if (AreClientCookiesCached(client))
	{
		char temp[2];
		GetClientCookie(client, gCookie_Tomori_Client_Toggled, temp, sizeof(temp));
		gShadow_Tomori_Client_ToggleTags[client] = (strcmp(temp, "1") == 0) ? true : false;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

stock void ResetClientID(int id)
{
	gShadow_Tomori_Client_Tag[id] = NULL_STRING;
	gShadow_Tomori_Client_CTag[id] = NULL_STRING;
	gShadow_Tomori_Client_TColor[id] = NULL_STRING;
	gShadow_Tomori_Client_NColor[id] = NULL_STRING;
	gShadow_Tomori_Client_CColor[id] = NULL_STRING;
	
	gShadow_Tomori_Client_RainbowT[id] = false;
	gShadow_Tomori_Client_RainbowC[id] = false;
	gShadow_Tomori_Client_RainbowN[id] = false;
	
	gShadow_Tomori_Client_RandomT[id] = false;
	gShadow_Tomori_Client_RandomC[id] = false;
	gShadow_Tomori_Client_RandomN[id] = false;
	
	gShadow_Tomori_Client_ToggleTags[id] = true;
}

stock bool IsClientInSteamList(int client)
{
	char ID[32];
	GetClientAuthId(client, AuthId_SteamID64, ID, sizeof(ID));
	
	char CheckID[32]; bool Set = false;
	KeyValues kv = CreateKeyValues("tomori_tags_by_steamid");
	kv.ImportFromFile(gH_Cvar_Tomori_Tags_SteamID);
	
	if (!kv.GotoFirstSubKey())
		return false;
		
	do
	{
		kv.GetSectionName(CheckID, sizeof(CheckID));
	
		if (strcmp(ID, CheckID) == 0)
		{
			ResetClientID(client);
			
			kv.GetString("chat-tag", gShadow_Tomori_Client_Tag[client], sizeof(gShadow_Tomori_Client_Tag));
			kv.GetString("clan-tag", gShadow_Tomori_Client_CTag[client], sizeof(gShadow_Tomori_Client_CTag));
			kv.GetString("chat-color", gShadow_Tomori_Client_CColor[client], sizeof(gShadow_Tomori_Client_CColor));
			kv.GetString("name-color", gShadow_Tomori_Client_NColor[client], sizeof(gShadow_Tomori_Client_NColor));
			kv.GetString("tag-color", gShadow_Tomori_Client_TColor[client], sizeof(gShadow_Tomori_Client_TColor));
			
			Set = true;
			SetUserTags(client);
		}
	}
	while (kv.GotoNextKey() && !Set);
	delete kv;
	
	return Set;
}

stock void GetUserTagByFlag(int client)
{
	char s_flag[32], a_flag[32]; bool NotSet = true;
	KeyValues kv = CreateKeyValues("tomori_tags_by_flag");
	kv.ImportFromFile(gH_Cvar_Tomori_Tags_Flag);
	
	if (!kv.GotoFirstSubKey())
		return;
		
	int flag;
	
	do
	{
		kv.GetSectionName(s_flag, sizeof(s_flag));
		
		if ((StrContains("abcdefghijklmnopqrstz", s_flag, false) == -1) && (strcmp(s_flag, "default") != 0))
		{
			gH_Cvar_Tomori_Tags_Enabled.SetInt(0, true, false);
			LogToFileEx(gShadow_Tomori_LogFile, "Tags Disabled. The Flag config file contains incorrect flag (%s)", s_flag);
			return;
		}
		
		FormatEx(a_flag, sizeof(a_flag), s_flag);
		
		flag = EMP_Flag_StringToInt(s_flag);
		
		if(Client_HasAdminFlags(client, flag) || strcmp(a_flag, "default") == 0)
		{
			ResetClientID(client);
			
			kv.GetString("chat-tag", gShadow_Tomori_Client_Tag[client], sizeof(gShadow_Tomori_Client_Tag));
			kv.GetString("clan-tag", gShadow_Tomori_Client_CTag[client], sizeof(gShadow_Tomori_Client_CTag));
			kv.GetString("chat-color", gShadow_Tomori_Client_CColor[client], sizeof(gShadow_Tomori_Client_CColor));
			kv.GetString("name-color", gShadow_Tomori_Client_NColor[client], sizeof(gShadow_Tomori_Client_NColor));
			kv.GetString("tag-color", gShadow_Tomori_Client_TColor[client], sizeof(gShadow_Tomori_Client_TColor));
			
			if (strcmp(gShadow_Tomori_Client_CColor[client], "{red}") == 0)
				ReplaceString(gShadow_Tomori_Client_CColor[client], sizeof(gShadow_Tomori_Client_CColor), "{red}", "\x02");	
			if (strcmp(gShadow_Tomori_Client_NColor[client], "{red}") == 0)
				ReplaceString(gShadow_Tomori_Client_NColor[client], sizeof(gShadow_Tomori_Client_NColor), "{red}", "\x02");
			if (strcmp(gShadow_Tomori_Client_TColor[client], "{red}") == 0)
				ReplaceString(gShadow_Tomori_Client_TColor[client], sizeof(gShadow_Tomori_Client_TColor), "{red}", "\x02");
				
			if (strcmp(gShadow_Tomori_Client_CColor[client], "{blue}") == 0)
				ReplaceString(gShadow_Tomori_Client_CColor[client], sizeof(gShadow_Tomori_Client_CColor), "{blue}", "\x0C");	
			if (strcmp(gShadow_Tomori_Client_NColor[client], "{blue}") == 0)
				ReplaceString(gShadow_Tomori_Client_NColor[client], sizeof(gShadow_Tomori_Client_NColor), "{blue}", "\x0C");
			if (strcmp(gShadow_Tomori_Client_TColor[client], "{blue}") == 0)
				ReplaceString(gShadow_Tomori_Client_TColor[client], sizeof(gShadow_Tomori_Client_TColor), "{blue}", "\x0C");
			
			NotSet = false;
			SetUserTags(client);
		}
	}
	while (kv.GotoNextKey() && NotSet);
	delete kv;
}

public Action CP_OnChatMessage(int& client, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	if (gH_Cvar_Tomori_Tags_Enabled.BoolValue && gShadow_Tomori_Client_Custom[client])
	{
		char sname[MAX_NAME_LENGTH];
		GetClientName(client, sname, MAX_NAME_LENGTH);
		
		#if (MODULE_TAGS == 1)
			if (strlen(gShadow_Tomori_Client_CColor[client]) == 0)
			{
				for (int i = strlen(gShadow_Tomori_Symbols); i != 0; i--)
				{
					if (strlen(gShadow_Tomori_Symbols[i]) != 0)
						ReplaceString(message, 1024, gShadow_Tomori_Symbols[i], NULL_STRING);
				}
				
				return Plugin_Changed;
			}
		#endif
		
		if (gShadow_Tomori_Client_ToggleTags[client])
		{
			if (gShadow_Tomori_Client_RainbowN[client])
				FormatEx(name, MAX_NAME_LENGTH, "%s", SetRainbow(sname));
			else if (gShadow_Tomori_Client_RandomN[client])
				FormatEx(name, MAX_NAME_LENGTH, "%s", SetRandom(sname));
			else
				FormatEx(name, MAX_NAME_LENGTH, "%s%s", gShadow_Tomori_Client_NColor[client], sname);
				
			if (gShadow_Tomori_Client_RainbowC[client])
				Format(message, 1024, "%s", SetRainbow(message));
			else if (gShadow_Tomori_Client_RandomC[client])
				Format(message, 1024, "%s", SetRandom(message));
			else
				Format(message, 1024, "%s%s", gShadow_Tomori_Client_CColor[client], message);
				
			if (gShadow_Tomori_Client_RainbowT[client])
				Format(name, MAX_NAME_LENGTH, "%s %s", SetRainbow(gShadow_Tomori_Client_Tag[client]), name);
			else if (gShadow_Tomori_Client_RandomT[client])
				Format(name, MAX_NAME_LENGTH, "%s %s", SetRandom(gShadow_Tomori_Client_Tag[client]), name);
			else
				Format(name, MAX_NAME_LENGTH, "%s%s %s", gShadow_Tomori_Client_TColor[client], gShadow_Tomori_Client_Tag[client], name);
			
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock char[] SetRandom(char[] string)
{
	char sNewString[512];
	FormatEx(sNewString, 512, "%c%s{default}", EMP_GetRandomColor(), string);
	return sNewString;
}

stock char[] SetRainbow(char[] string)
{
	char sNewString[512];
	char sTemp[512];
	
	int len = strlen(string), bytes;
	for (int i = 0; i < len; i++)
	{
		if (IsCharSpace(string[i]))
		{
			Format(sTemp, sizeof(sTemp), "%s%c", sTemp, string[i]);
			continue;
		}
		
		bytes = GetCharBytes(string[i])+1;
		char[] c = new char[bytes];
		strcopy(c, bytes, string[i]);
		Format(sTemp, sizeof(sTemp), "%s%c%s", sTemp, EMP_GetRandomColor(), c);
		if (IsCharMB(string[i]))
		i += bytes-2;
	}		
	FormatEx(sNewString, 512, "%s{default}", sTemp);
	
	return sNewString;
}

stock void SetUserTags(int client)
{
	gShadow_Tomori_Client_Custom[client] = true;

	if (strcmp(gShadow_Tomori_Client_TColor[client], "{rainbow}") == 0)
		gShadow_Tomori_Client_RainbowT[client] = true;
	
	if (strcmp(gShadow_Tomori_Client_NColor[client], "{rainbow}") == 0)
		gShadow_Tomori_Client_RainbowN[client] = true;
	
	if (strcmp(gShadow_Tomori_Client_CColor[client], "{rainbow}") == 0)
		gShadow_Tomori_Client_RainbowC[client] = true;
		
	if (strcmp(gShadow_Tomori_Client_TColor[client], "{random}") == 0)
		gShadow_Tomori_Client_RandomT[client] = true;
	
	if (strcmp(gShadow_Tomori_Client_NColor[client], "{random}") == 0)
		gShadow_Tomori_Client_RandomN[client] = true;
	
	if (strcmp(gShadow_Tomori_Client_CColor[client], "{random}") == 0)
		gShadow_Tomori_Client_RandomC[client] = true;
	
	if (strlen(gShadow_Tomori_Client_CTag[client]) > 0)
	{
		SetClanTagFix(client);
		if (gShadow_Tomori_Client_ForceClan[client] == INVALID_HANDLE)
			gShadow_Tomori_Client_ForceClan[client] = CreateTimer(1.0, Timer_ForceClanTag, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_ForceClanTag(Handle timer, int client)
{
	if (EMP_IsValidClient(client))
		if (gShadow_Tomori_Client_ToggleTags[client])
			SetClanTagFix(client);
		else
		{
			CS_SetClientClanTag(client, NULL_STRING);
			gShadow_Tomori_Client_ForceClan[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
	else
	{
		gShadow_Tomori_Client_ForceClan[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

stock void SetClanTagFix(int client)
{
	CS_SetClientClanTag(client, gShadow_Tomori_Client_CTag[client]);
}