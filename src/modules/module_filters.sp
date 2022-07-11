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

ConVar 	gH_Cvar_Tomori_Filter_Enabled,						//Enable or disable Filter Module
		gH_Cvar_Tomori_Filter_FilterChat,					//Enable or disable badword check in names
		gH_Cvar_Tomori_Filter_WarnTimes,					//How many times warn user before punish
		gH_Cvar_Tomori_Filter_Punishment,					//Punishment mode (0 - Warn, 1 - Block Msg, 2 - Gag, 3 - Kick, 4 - Ban)
		gH_Cvar_Tomori_Filter_GagTime,						//Gag Time
		gH_Cvar_Tomori_Filter_GagTime_N,					//Gag after warn time
		gH_Cvar_Tomori_Filter_BanTime,						//Ban time
		gH_Cvar_Tomori_Filter_BlockWebsiteAdvert,			//Block website adverts in chat
		gH_Cvar_Tomori_Filter_BlockIPAdvert,				//Block ip adverts in chat
		gH_Cvar_Tomori_Filter_URL_Whitelist,				//URLs to exclude from filtering
		gH_Cvar_Tomori_Filter_IP_Whitelist;					//IPs to exclude from filtering

int 	WarnedTimes[MAXPLAYERS+1] = 0;

public void Filters_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Filters", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Filter_Enabled = AutoExecConfig_CreateConVar("tomori_filter_enabled", "1", "Enable or disable name module in tomori:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Filter_FilterChat = AutoExecConfig_CreateConVar("tomori_filter_filterchat", "1", "Filter chat messaages for bad words?", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Filter_WarnTimes = AutoExecConfig_CreateConVar("tomori_filter_warntime", "5", "How many times tomori warn player before punish", 0, true, 0.0);
	gH_Cvar_Tomori_Filter_Punishment = AutoExecConfig_CreateConVar("tomori_filter_punishment", "3", "Punishment mode (0 - Warn, 1 - Block Msg, 2 - Gag, 3 - Kick, 4 - Ban)", 0, true, 0.0);
	gH_Cvar_Tomori_Filter_GagTime = AutoExecConfig_CreateConVar("tomori_filter_gagtime", "5", "Gag time on swear (if punishmennt is 2)", 0, true, 0.0);
	gH_Cvar_Tomori_Filter_BanTime = AutoExecConfig_CreateConVar("tomori_filter_bantime", "30", "Ban time on swear (if punishmennt is 4)", 0, true, 0.0);
	gH_Cvar_Tomori_Filter_GagTime_N = AutoExecConfig_CreateConVar("tomori_filter_warntime_gag", "3", "Gag after x warn (for multi punishment)", 0, true, 0.0);
	gH_Cvar_Tomori_Filter_BlockWebsiteAdvert = AutoExecConfig_CreateConVar("tomori_filter_block_website", "1", "Block website adverts in chat?", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Filter_BlockIPAdvert = AutoExecConfig_CreateConVar("tomori_filter_block_ip", "1", "Block ip adverts in chat?", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Filter_URL_Whitelist = AutoExecConfig_CreateConVar("tomori_filter_block_website_whitelist", "www.entity-sp.dev", "Whitelist of accepted URLs (Separate with ,)(Start with www.))", 0);
	gH_Cvar_Tomori_Filter_IP_Whitelist = AutoExecConfig_CreateConVar("tomori_filter_block_ip_whitelist", "1.1.1.1", "Whitelist of accepted URLs (Separate with ,) (Don't use ports))", 0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Filter_Enabled.SetInt(0, true, false);
	
	if (gH_Cvar_Tomori_Filter_Enabled.BoolValue) Filters_Loaded = true;
	else Filters_Loaded = false;
	
	CompileAllRegex();
	
	AddCommandListener(OnMessageSent, "say");
	AddCommandListener(OnMessageSent, "say_team");
}

stock void CompileAllRegex()
{
	R_Dot = CompileRegex("^[.]*$");
	
	char DefaultULRFIlter[512] = "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}";
	char WhiteList[1024], WhitelistAddon[1024];
	
	gH_Cvar_Tomori_Filter_IP_Whitelist.GetString(WhiteList, sizeof(WhiteList));
	
	if (strlen(WhiteList) > 0)
	{
		if (StrContains(WhiteList, ","))
		{
			char g_sIPs[8][32];
			int g_iIPCount = ExplodeString(WhiteList, ",", g_sIPs, sizeof(g_sIPs), sizeof(g_sIPs[]));
			
			FormatEx(WhitelistAddon, sizeof(WhitelistAddon), "^(?!");
			for (int i = 0; i < g_iIPCount; i++)
			{
				ReplaceString(g_sIPs[i], sizeof(g_sIPs), ".", "\\.");
				
				if (g_iIPCount != i+1) Format(WhitelistAddon, sizeof(WhitelistAddon), "%s%s|", WhitelistAddon, g_sIPs[i]);
				else Format(WhitelistAddon, sizeof(WhitelistAddon), "%s%s$)", WhitelistAddon, g_sIPs[i]);
			}
		}
		else
		{
			ReplaceString(WhiteList, sizeof(WhiteList), ".", "\\.");
			FormatEx(WhitelistAddon, sizeof(WhitelistAddon), "^(?!%s$)", WhiteList);
		}
	}
	
	Format(DefaultULRFIlter, sizeof(DefaultULRFIlter), "%s%s", WhitelistAddon, DefaultULRFIlter);
	R_Ip = CompileRegex(DefaultULRFIlter);
	
	char DefaultSiteFilter[1024] = "((https?|ftp|smtp):\\/\\/)?(www.)?[a-z0-9]+(\\.[a-z]{2,}){1,3}(#?\\/?[a-zA-Z0-9#]+)*\\/?(\\?[a-zA-Z0-9-_]+=[a-zA-Z0-9-%]+&?)*";

	gH_Cvar_Tomori_Filter_URL_Whitelist.GetString(WhiteList, sizeof(WhiteList));
	
	if (strlen(WhiteList) > 0)
	{
		if (StrContains(WhiteList, ","))
		{
			char g_sURls[8][32];
			int g_iUrlCount = ExplodeString(WhiteList, ",", g_sURls, sizeof(g_sURls), sizeof(g_sURls[]));
			
			FormatEx(WhitelistAddon, sizeof(WhitelistAddon), "^(?!");
			for (int i = 0; i < g_iUrlCount; i++)
			{
				ReplaceString(g_sURls[i], sizeof(g_sURls), ".", "\\.");
				
				if (g_iUrlCount != i+1) Format(WhitelistAddon, sizeof(WhitelistAddon), "%s%s|", WhitelistAddon, g_sURls[i]);
				else Format(WhitelistAddon, sizeof(WhitelistAddon), "%s%s$)", WhitelistAddon, g_sURls[i]);
			}
		}
		else
		{
			ReplaceString(WhiteList, sizeof(WhiteList), ".", "\\.");
			FormatEx(WhitelistAddon, sizeof(WhitelistAddon), "^(?!%s$)", WhiteList);
		}
	}
	
	Format(DefaultSiteFilter, sizeof(DefaultSiteFilter), "%s%s", WhitelistAddon, DefaultSiteFilter);
	R_Website = CompileRegex(DefaultSiteFilter);
}

public Action OnMessageSent(int client, const char[] command, int args)
{
	if (gH_Cvar_Tomori_Filter_Enabled.BoolValue && EMP_IsValidClient(client) && !BaseComm_IsClientGagged(client))
	{
		char buffer[1024], arg[128];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArgString(buffer, sizeof(buffer));
	
		ReplaceString(buffer, sizeof(buffer), "\"", NULL_STRING);
		
		if (strlen(buffer) == 0 || strcmp(buffer, " ") == 0)
			return Plugin_Handled;
	
		if (gH_Cvar_Tomori_Filter_FilterChat.BoolValue)
		{
			if (ContainsBad(buffer, client))
			{
				return Plugin_Handled;
			}
		}
		
		TrimString(buffer);
		
		if (gH_Cvar_Tomori_Filter_BlockWebsiteAdvert.BoolValue)
		{
			if (MatchRegex(R_Website, buffer) != 0 && MatchRegex(R_Dot, buffer) == 0)
			{
				FormatEx(buffer, sizeof(buffer), NULL_STRING);
				CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Filters BlockAdvert");
				return Plugin_Handled;
			}
		}
		
		if (gH_Cvar_Tomori_Filter_BlockIPAdvert.BoolValue)
		{
			if (MatchRegex(R_Ip, buffer) != 0)
			{
				FormatEx(buffer, sizeof(buffer), NULL_STRING);
				CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Filters BlockAdvert");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public void Filters_OnMapStart()
{
	if (gH_Cvar_Tomori_Filter_Enabled.BoolValue)
	{
		ReadWordList();
		for (int idx = 1; idx <= MaxClients; idx++)
		{
			if (EMP_IsValidClient(idx))
			{
				WarnedTimes[idx] = 0;
			}
		}
	}
}

stock void ClearWordList()
{
	for(int i; i <= WordLines; i++)
	{
		FormatEx(WordList[i], sizeof(WordList), NULL_STRING);
	}
	
	WordLines = 0;
	ReadCompleted = false;
}

public bool ContainsBad(char[] source, int client)
{
	if (ReadCompleted)
	{
		char Message[1024];
		
		strcopy(Message, sizeof(Message), source);

		char Search[2];
		for (int i = 0; i < 128; i++)
		{
			FormatEx(Search, 2, Replace_Special[i]);
			if (strlen(Search) > 0 && StrContains(Message, Search, false) != -1)
			{
				ReplaceString(Message, sizeof(Message), Search, NULL_STRING);
			}
		}
		
		for (int i = 0; i <= WordLines; i++)
		{
			if (strlen(WordCount[i]) > 0 && StrContains(Message, WordCount[i], false) != -1)
			{
				char Reason[64];
				if (WarnedTimes[client] < (gH_Cvar_Tomori_Filter_WarnTimes.IntValue - 1))
				{
					WarnedTimes[client]++;
					if (gH_Cvar_Tomori_Filter_GagTime_N.IntValue == WarnedTimes[client] && gH_Cvar_Tomori_Filter_GagTime_N.IntValue != 0)
					{
						FormatEx(Reason, sizeof(Reason), "%s %t", "[Tomori]", "Tomori Filter ChatSwear");
						ServerCommand("sm_gag #%i %i \"%s\"", GetClientUserId(client), gH_Cvar_Tomori_Filter_GagTime.IntValue, Reason);
					}
					
					CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Filter ChatSwear");
					return true;
				}
				else if ((WarnedTimes[client] == (gH_Cvar_Tomori_Filter_WarnTimes.IntValue - 1)) && (gH_Cvar_Tomori_Filter_Punishment.IntValue != 0))
				{
					WarnedTimes[client]++;
					if (gH_Cvar_Tomori_Filter_GagTime_N.IntValue == WarnedTimes[client] && gH_Cvar_Tomori_Filter_GagTime_N.IntValue != 0)
					{
						FormatEx(Reason, sizeof(Reason), "%s %t", "[Tomori]", "Tomori Filter ChatSwear");
						ServerCommand("sm_gag #%i %i \"%s\"", GetClientUserId(client), gH_Cvar_Tomori_Filter_GagTime.IntValue, Reason);
					}
				
					CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Filter ChatSwear OnceMore");
					return true;
				}
				else
				{
					FormatEx(Reason, sizeof(Reason), "%t", "Tomori Filter ChatSwear");
					switch (gH_Cvar_Tomori_Filter_Punishment.IntValue)
					{
						case 0:
						{
							CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Filter ChatSwear");
							WarnedTimes[client] = 0;
						}
						case 1:
						{
							CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Filter ChatSwear Blocked");
							WarnedTimes[client] = 0;
							return true;
						}
						case 2:
						{
							FormatEx(Reason, sizeof(Reason), "%s %t", "[Tomori]", "Tomori Filter ChatSwear");
							ServerCommand("sm_gag #%i %i \"%s\"", GetClientUserId(client), gH_Cvar_Tomori_Filter_GagTime.IntValue, Reason);
							CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Filter ChatSwear Gagged", gH_Cvar_Tomori_Filter_GagTime.IntValue);
							WarnedTimes[client] = 0;
							return true;
						}
						case 3:
						{
							FormatEx(Reason, sizeof(Reason), "%s %t", "[Tomori]", "Tomori Filter ChatSwear");
							WarnedTimes[client] = 0;
							KickClient(client, Reason);
							return true;
						}
						case 4:
						{
							FormatEx(Reason, sizeof(Reason), "%s %t", "[Tomori]", "Tomori Filter ChatSwear");
							WarnedTimes[client] = 0;
							ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(client), gH_Cvar_Tomori_Filter_BanTime.IntValue, Reason);
							return true;
						}
					}
				}
			}
		}
	}
	return false;
}

stock bool ReadWordList()
{
	ClearWordList();
	BuildPath(Path_SM, WordList, sizeof(WordList), "configs/Tomori/badwords.ini");	
	Handle BadWords = OpenFile(WordList, "rt");
	
	if (BadWords == INVALID_HANDLE)
	{
		#if (MODULE_LOGGING == 1)
		LogToFileEx(gShadow_Tomori_LogFile, "BadWords list is missing from configs/Tomori/");
		#endif
		return false;
	}
	
	while (!IsEndOfFile(BadWords))
	{
		char CurrentLine[64];
		if (!ReadFileLine(BadWords, CurrentLine, sizeof(CurrentLine)))
			break;
		
		TrimString(CurrentLine); ReplaceString(CurrentLine, sizeof(CurrentLine), " ", NULL_STRING);
		if (strlen(CurrentLine) == 0 || (CurrentLine[0] == '/' && CurrentLine[1] == '/'))
			continue;
		
		strcopy(WordCount[WordLines], sizeof(WordCount[]), CurrentLine);
		WordLines++;
	}
	
	EMP_FreeHandle(BadWords);
	ReadCompleted = true;
	return true;
}