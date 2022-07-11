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

ConVar 	gH_Cvar_Tomori_Name_Enabled,					//Enable or disable Name Module
		gH_Cvar_Tomori_Name_ExtraChars,					//Add extra characters to allow in name
		gH_Cvar_Tomori_Name_Badname_AutoChange,			//AutoChange illegal names
		gH_Cvar_Tomori_Name_Badname_AutoChangeTo,		//Rename to this name + random number
		gH_Cvar_Tomori_Name_MaxChanges,					//Punish After x name change in a map
		gH_Cvar_Tomori_Name_MaxChanges_Punishment,		//Punishment type
		gH_Cvar_Tomori_Name_MaxChanges_Bantime,			//Bantime (if type is ban)
		gH_Cvar_Tomori_Name_MaxChanges_Reason,			//Ban/Kick reason for bad name
		gH_Cvar_Tomori_Name_Website_Filter,				//Filter websites from names
		gH_Cvar_Tomori_Name_IP_Filter,					//Filter IPs from names
		gH_Cvar_Tomori_Name_Badword_Filter;				//Filter badwords from names

int 	gShadow_Client_ChangedTime[MAXPLAYERS+1] = 0;

bool 	gShadow_Client_ChangedByTomori[MAXPLAYERS+1] 	= false,
		gShadow_Client_ChangedOnJoin[MAXPLAYERS+1] 		= false;
		
char 	gShadow_Client_NameToChange[MAXPLAYERS+1];

static Regex R_Name;

public void Name_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Name", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Name_Enabled = AutoExecConfig_CreateConVar("tomori_name_enabled", "1", "Enable or disable name module in tomori:", 0, true, 0.0, true, 1.0);
	
	gH_Cvar_Tomori_Name_ExtraChars = AutoExecConfig_CreateConVar("tomori_name_extrachars", "áéűúőóíüö」「", "Add your custom chars to allow in names");
	gH_Cvar_Tomori_Name_Badname_AutoChange = AutoExecConfig_CreateConVar("tomori_name_badname_autochange", "1", "Enable or disable change names with illegal characters", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Name_Badname_AutoChangeTo = AutoExecConfig_CreateConVar("tomori_name_badname_changeto", "Changed", "Bad named players will be rename to this");
	
	gH_Cvar_Tomori_Name_MaxChanges = AutoExecConfig_CreateConVar("tomori_name_maxchanges", "3", "How many times player allowed to change name in a map", 0, true, 0.0);
	gH_Cvar_Tomori_Name_MaxChanges_Punishment = AutoExecConfig_CreateConVar("tomori_name_maxchanges_punishment", "1", "Punishment for bad name (0 - Just Block, 1 - Kick, 2 - Ban)", 0, true, 0.0);
	gH_Cvar_Tomori_Name_MaxChanges_Bantime = AutoExecConfig_CreateConVar("tomori_namemaxchanges_bantime", "30", "Bantime for maxchange (if punishment type is ban)", 0, true, 0.0);
	gH_Cvar_Tomori_Name_MaxChanges_Reason = AutoExecConfig_CreateConVar("tomori_name_maxchanges_reason", "You've changed your name too many times.", "Ban/Kick reason for bad name");
	
	gH_Cvar_Tomori_Name_Website_Filter = AutoExecConfig_CreateConVar("tomori_name_website_filter", "1", "Enable or disable change names with website in it", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Name_IP_Filter = AutoExecConfig_CreateConVar("tomori_name_ip_filter", "1", "Enable or disable change names with ip in it", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Name_Badword_Filter = AutoExecConfig_CreateConVar("tomori_name_badword_filter", "1", "Enable or disable change names with bad words in it", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_changename", NameBlock);
	HookEvent("player_team", NameBlock_AnnounceJoin, EventHookMode_Pre);
	
	HookUserMessage(GetUserMessageId("SayText2"), BlockRenameText, true);
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Name_Enabled.SetInt(0, true, false);
}

public Action NameBlock_AnnounceJoin(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(gH_Cvar_Tomori_Name_Enabled.BoolValue && EMP_IsValidClient(client))
	{
		if(!event.GetBool("disconnect") && (event.GetInt("oldteam") == CS_TEAM_NONE))
		{
			if (gShadow_Client_ChangedOnJoin[client])
			{
				CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NameChange Changed Illegal", client);
			}
		}
	}
}

public Action BlockRenameText(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if (gH_Cvar_Tomori_Name_Enabled.BoolValue)
	{
		if(!reliable)
		{
			return Plugin_Continue;
		}

		char buffer[25];

		if(GetUserMessageType() == UM_Protobuf)
		{
			PbReadString(bf, "msg_name", buffer, sizeof(buffer));

			if(strcmp(buffer, "#Cstrike_Name_Change") == 0)
				return Plugin_Handled;
		}
		else
		{
			BfReadChar(bf);
			BfReadChar(bf);
			BfReadString(bf, buffer, sizeof(buffer));

			if(strcmp(buffer, "#Cstrike_Name_Change") == 0)
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
} 

public void Name_OnMapEnd()
{
	if (gH_Cvar_Tomori_Name_Enabled.BoolValue) RunNameCommands();
}

public void Name_OnMapStart()
{
	if (gH_Cvar_Tomori_Name_Enabled.BoolValue) RunNameCommands();
}

stock void RunNameCommands()
{
	char tempname[MAX_NAME_LENGTH], TomoriName[MAX_NAME_LENGTH];
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (EMP_IsValidClient(idx))
		{
			gShadow_Client_ChangedTime[idx] = 0;
			GetClientName(idx, tempname, sizeof(tempname));
			
			if (CheckNameAll(tempname))
			{
				gH_Cvar_Tomori_Name_Badname_AutoChangeTo.GetString(TomoriName, sizeof(TomoriName));
				ENT_RenameIllegal(idx, TomoriName);
				return;
			}
		}
	}
}

stock bool CheckNameAll(char[] name)
{
	char Search[2];
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (EMP_IsValidClient(idx))
		{
			if (ENT_ContainIllegal(name))
			{
				return true;
			}
			
			if (Filters_Loaded)
			{
				if (gH_Cvar_Tomori_Name_Website_Filter.BoolValue && (MatchRegex(R_Website, name) != 0 && MatchRegex(R_Dot, name) == 0))
				{
					return true;
				}
				
				if (gH_Cvar_Tomori_Name_IP_Filter.BoolValue && (MatchRegex(R_Ip, name) != 0))
				{
					return true;
				}
				
				if (ReadCompleted && gH_Cvar_Tomori_Name_Badword_Filter.BoolValue)
				{
					for (int i = 0; i < 128; i++)
					{
						FormatEx(Search, 2, name[i]);
						if (strlen(Search) > 0 && StrContains(name, Search, false) != -1)
						{
							ReplaceString(name, MAX_NAME_LENGTH, Search, NULL_STRING);
						}
					}
					
					for (int i = 0; i <= WordLines; i++)
					{
						if (strlen(WordCount[i]) > 0 && StrContains(name, WordCount[i], false) != -1)
						{
							return true;
						}
					}
				}
			}
		}
	}
	return false;
}

public Action NameBlock(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (EMP_IsValidClient(client))
	{
		if (gH_Cvar_Tomori_Name_Enabled.BoolValue && !gShadow_Client_ChangedByTomori[client])
		{
			char playerName[MAX_NAME_LENGTH], tempname[MAX_NAME_LENGTH], TomoriName[MAX_NAME_LENGTH];
			GetEventString(event, "newname", playerName, sizeof(playerName));

			SetEventBroadcast(event, true);

			bool banned = false;
			for (int idx = 1; idx <= MaxClients; idx++)
			{
				if (EMP_IsValidClient(idx))
				{
					GetClientName(idx, tempname, sizeof(tempname));
					
					if (strcmp(tempname, playerName) == 0)
					{
						ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(client), 0, "[Tomori] NameCopy Cheat - Automatically banned");
						
						banned = true;
						return Plugin_Handled;
					}
				}
			}
			
			if (banned)
			{
				for (int idx = 1; idx <= MaxClients; idx++)
				{
					if (EMP_IsValidClient(idx))
					{
						CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NameChange Banned CheatCopy", client);
					}
				}
			}
			
			if (CheckNameAll(playerName))
			{
				char oldname[MAX_NAME_LENGTH];
				GetEventString(event, "oldname", oldname, sizeof(oldname));
				SetEventString(event, "newname", oldname);
				
				if (CheckNameAll(oldname))
					SetClientName(client, oldname);
				else
				{
					gH_Cvar_Tomori_Name_Badname_AutoChangeTo.GetString(TomoriName, sizeof(TomoriName));
					ENT_RenameIllegal(client, TomoriName);
				}
					
				FormatEx(gShadow_Client_NameToChange[client], sizeof(gShadow_Client_NameToChange), oldname);
				CreateTimer(0.5, Timer_NameFix, client, TIMER_FLAG_NO_MAPCHANGE);
				
				CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NameChange Change Blocked Illegal");
				return Plugin_Changed;
			}
			
			if ((gShadow_Client_ChangedTime[client] != gH_Cvar_Tomori_Name_MaxChanges.IntValue) && ((gH_Cvar_Tomori_Name_MaxChanges.IntValue - (gShadow_Client_ChangedTime[client] + 1)) != 0))
			{
				++gShadow_Client_ChangedTime[client];
				char TempName[MAX_NAME_LENGTH], NewName[MAX_NAME_LENGTH], OldName[MAX_NAME_LENGTH];
				GetClientName(client, TempName, sizeof(TempName));
				FormatEx(OldName, sizeof(OldName), "\x07%s\x0B", TempName);
				GetEventString(event, "newname", playerName, sizeof(playerName));
				FormatEx(NewName, sizeof(NewName), "\x07%s\x0B", playerName);
				
				for (int idx = 1; idx <= MaxClients; idx++)
				{
					if (EMP_IsValidClient(idx))
					{
						CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori ChangedName", OldName, NewName);
					}
				}
				
				CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NameChange ChangesLeft", (gH_Cvar_Tomori_Name_MaxChanges.IntValue - gShadow_Client_ChangedTime[client]));
			}
			else if ((gShadow_Client_ChangedTime[client] != gH_Cvar_Tomori_Name_MaxChanges.IntValue) && ((gH_Cvar_Tomori_Name_MaxChanges.IntValue - (gShadow_Client_ChangedTime[client] + 1)) == 0))
			{
				++gShadow_Client_ChangedTime[client];
				char TempName[MAX_NAME_LENGTH], NewName[MAX_NAME_LENGTH], OldName[MAX_NAME_LENGTH];
				GetClientName(client, TempName, sizeof(TempName));
				FormatEx(OldName, sizeof(OldName), "\x07%s\x0B", TempName);
				GetEventString(event, "newname", playerName, sizeof(playerName));
				FormatEx(NewName, sizeof(NewName), "\x07%s\x0B", playerName);
				
				for (int idx = 1; idx <= MaxClients; idx++)
				{
					if (EMP_IsValidClient(idx))
					{
						CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori ChangedName", OldName, NewName);
					}
				}
	
				CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NameChange Changes NoMore");
			}
			else if (gShadow_Client_ChangedTime[client] == gH_Cvar_Tomori_Name_MaxChanges.IntValue)
			{
				char Reason[512], tempstring[512];
				gH_Cvar_Tomori_Name_MaxChanges_Reason.GetString(tempstring, sizeof(tempstring));
				FormatEx(Reason, sizeof(Reason), "%s %s", "[Tomori]", tempstring);
				
				switch (gH_Cvar_Tomori_Name_MaxChanges_Punishment.IntValue)
				{
					case 0:
					{
						char oldname[MAX_NAME_LENGTH];
						GetEventString(event, "oldname", oldname, sizeof(oldname));
						SetEventString(event, "newname", oldname);
						
						if (!CheckNameAll(oldname))
							SetClientName(client, oldname);
						else
						{
							gH_Cvar_Tomori_Name_Badname_AutoChangeTo.GetString(TomoriName, sizeof(TomoriName));
							ENT_RenameIllegal(client, TomoriName);
						}
				
						FormatEx(gShadow_Client_NameToChange[client], sizeof(gShadow_Client_NameToChange), oldname);
						CreateTimer(0.5, Timer_NameFix, client, TIMER_FLAG_NO_MAPCHANGE);
						
						CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NameChange Change Blocked Limit");
						return Plugin_Handled;
					}
					case 1:
					{
						KickClient(client, Reason);
						
						for (int idx = 1; idx <= MaxClients; idx++)
						{
							if (EMP_IsValidClient(idx))
							{
								CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NameChange Kicked TooMuch", client);
							}
						}
						return Plugin_Handled;
					}
					case 2:			
					{
						
						ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(client), gH_Cvar_Tomori_Name_MaxChanges_Bantime.IntValue, Reason);

						for (int idx = 1; idx <= MaxClients; idx++)
						{
							if (EMP_IsValidClient(idx))
							{
								CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NameChange Banned TooMuch", client);
							}
						}
						return Plugin_Handled;
					}
				}
			}
			return Plugin_Continue;
		}
		else if (gShadow_Client_ChangedByTomori[client])
		{
			gShadow_Client_ChangedByTomori[client] = false;
		}
	}
	return Plugin_Continue;
}

public void Name_OnClientDisconnect(int client)
{
	if (gH_Cvar_Tomori_Name_Enabled.BoolValue && EMP_IsValidClient(client))
	{
		gShadow_Client_ChangedTime[client] = 0;
		gShadow_Client_ChangedByTomori[client] = false;
		gShadow_Client_ChangedOnJoin[client] = false;
	}
}

public void Name_OnClientPutInServer(int client)
{
	if (gH_Cvar_Tomori_Name_Enabled.BoolValue && gH_Cvar_Tomori_Name_Badname_AutoChange.BoolValue)
	{
		if (EMP_IsValidClient(client))
		{
			char TempName[MAX_NAME_LENGTH];
			GetClientName(client, TempName, sizeof(TempName));
			
			if (CheckNameAll(TempName))
			{
				char TomoriName[MAX_NAME_LENGTH];
				gH_Cvar_Tomori_Name_Badname_AutoChangeTo.GetString(TomoriName, sizeof(TomoriName));
				ENT_RenameIllegal(client, TomoriName);
				gShadow_Client_ChangedOnJoin[client] = true;
			}
			else
				gShadow_Client_ChangedOnJoin[client] = false;
		}
	}
}

public Action Timer_NameFix(Handle timer, int client)
{
	gShadow_Client_ChangedByTomori[client] = true;
	SetClientName(client, gShadow_Client_NameToChange[client]);
	return Plugin_Stop;
}

stock bool ENT_ContainIllegal(char[] checkit)
{
	ReplaceString(checkit, MAX_NAME_LENGTH, " ", NULL_STRING);
	
	bool Illegal = false;
	char AllowedCharacters_Extra[512];
	gH_Cvar_Tomori_Name_ExtraChars.GetString(AllowedCharacters_Extra, sizeof(AllowedCharacters_Extra));
	Format(AllowedCharacters_Extra, sizeof(AllowedCharacters_Extra), "^[a-zA-Z0-9. %s§'~\"+^!%/`=()-¸.:;?,*<>_@&#$[{}×|^\\\\-\\]]*$", AllowedCharacters_Extra);
	
	R_Name = CompileRegex(AllowedCharacters_Extra);
	
	if (MatchRegex(R_Name, checkit) == 0)
	{
		Illegal = true;
	}
	return Illegal;
}

stock void ENT_RenameIllegal(int client, const char[] DefaultName = "Changed")
{
	char NewNameToGo[MAX_NAME_LENGTH];
	FormatEx(NewNameToGo, sizeof(NewNameToGo), ENT_GenerateName(DefaultName, 0, 999999));
	
	char CheckName[MAX_NAME_LENGTH];
	
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (EMP_IsValidClient(idx) && (idx != client))
		{
			GetClientName(client, CheckName, sizeof(CheckName));
			if (strcmp(CheckName, NewNameToGo) == 0)
				FormatEx(NewNameToGo, sizeof(NewNameToGo), ENT_GenerateName(DefaultName, 0, 999999));
		}
	}
	
	gShadow_Client_ChangedByTomori[client] = true;
	SetClientName(client, NewNameToGo);
	CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NameChange Changed Illegal", client);
}

stock char ENT_GenerateName(const char[] Main = "Changed", int min, int max)
{
	char RandomName[MAX_NAME_LENGTH], RandomIntToName[16];
	IntToString(GetRandomInt(min, max), RandomIntToName, sizeof(RandomIntToName));
	
	FormatEx(RandomName, sizeof(RandomName), "%s%s", Main, RandomIntToName);
	return RandomName;
}