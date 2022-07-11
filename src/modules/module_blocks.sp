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

ConVar 	gH_Cvar_Tomori_Blocks_Enabled,					//Enable or disable Blocks Module (0 - Disable, 1 - Enabled)
		gH_Cvar_Tomori_Blocks_Friendlyfire,				//Enable or disable block friendlyfire announce (0 - Original, 1 - Custom, 2 - Block both)
		gH_Cvar_Tomori_Blocks_TeamChange,				//Enable or disable block teamchange announce (0 - Original, 1 - Custom, 2 - Block both)
		gH_Cvar_Tomori_Blocks_Connect,					//Enable or disable block connect announce (0 - Original, 1 - Custom, 2 - Block both)
		gH_Cvar_Tomori_Blocks_Disconnect,				//Enable or disable block disconnect announce (0 - Original, 1 - Custom, 2 - Block both)
		gH_Cvar_Tomori_Blocks_Cash,						//Enable or disable block cvarchange announce (0 - Enable, 1 - Disable)
		gH_Cvar_Tomori_Blocks_Radio,					//Enable or disable block cvarchange announce (0 - Enable, 1 - Disable)
		gH_Cvar_Tomori_Blocks_SavedPlayer,				//Enable or disable block cvarchange announce (0 - Enable, 1 - Disable)
		gH_Cvar_Tomori_Blocks_Status,					//Enable or disable block status in console (0 - Enable, 1 - Disable)
		gH_Cvar_Tomori_Blocks_Ping,						//Enable or disable block ping in console (0 - Enable, 1 - Disable)
		gH_Cvar_Tomori_Blocks_Symbols;					//Enable or disable block color symbol exploit (0 - Enable, 1 - Disable)

public void Blocks_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Blocks", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Blocks_Enabled = AutoExecConfig_CreateConVar("tomori_blocks_enabled", "1", "Enable or disable blocks module in tomori:", 0, true, 0.0, true, 1.0);
	
	gH_Cvar_Tomori_Blocks_Friendlyfire = AutoExecConfig_CreateConVar("tomori_blocks_friendlyfire", "1", "Enable or disable friendlyfire chat announce block  (0 - Disable, 1 - Enable)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Blocks_SavedPlayer = AutoExecConfig_CreateConVar("tomori_blocks_savedplayer", "1", "Enable or disable saved player chat announce block  (0 - Disable, 1 - Enable)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Blocks_Cash = AutoExecConfig_CreateConVar("tomori_blocks_cashandpoint", "1", "Enable or disable cash and point chat announce (0 - Disable, 1 - Enable)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Blocks_Radio = AutoExecConfig_CreateConVar("tomori_blocks_radio", "1", "Enable or disable radio chat announce  (0 - Disable, 1 - Enable))", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Blocks_TeamChange = AutoExecConfig_CreateConVar("tomori_blocks_teamchange", "1", "Change method of teamchange chat announce  (0 - Original, 1 - Custom, 2 - Block both)", 0, true, 0.0, true, 2.0);
	gH_Cvar_Tomori_Blocks_Connect = AutoExecConfig_CreateConVar("tomori_blocks_connect", "1", "Change method of connect chat announce  (0 - Original, 1 - Custom, 2 - Block both)", 0, true, 0.0, true, 2.0);
	gH_Cvar_Tomori_Blocks_Disconnect = AutoExecConfig_CreateConVar("tomori_blocks_disconnect", "1", "Change method of disconnect chat announce  (0 - Original, 1 - Custom, 2 - Block both)", 0, true, 0.0, true, 2.0);
	
	gH_Cvar_Tomori_Blocks_Status = AutoExecConfig_CreateConVar("tomori_blocks_status", "1", "Enable or disable status block (0 - Disable, 1 - Enable)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Blocks_Ping = AutoExecConfig_CreateConVar("tomori_blocks_ping", "1", "Enable or disable block ping in console (0 - Enable, 1 - Disable)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Blocks_Symbols = AutoExecConfig_CreateConVar("tomori_blocks_symbol_exploit", "1", "Enable or disable block color symbol exploit [Requires module_tags] (0 - Enable, 1 - Disable)", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	HookUserMessage(GetUserMessageId("SayText2"), BlockText, true);
	HookUserMessage(GetUserMessageId("TextMsg"), BlockMsg, true);
	HookUserMessage(GetUserMessageId("RadioText"), BlockRadio, true);
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Blocks_Enabled.SetInt(0, true, false);

	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);

	if (gH_Cvar_Tomori_Blocks_Enabled.BoolValue && gH_Cvar_Tomori_Blocks_Status.BoolValue) SetCommandFlags("status", FCVAR_CHEAT);
	if (gH_Cvar_Tomori_Blocks_Enabled.BoolValue && gH_Cvar_Tomori_Blocks_Ping.BoolValue) SetCommandFlags("ping", FCVAR_CHEAT);
}

public void Blocks_OnMapStart()
{
	if (gH_Cvar_Tomori_Blocks_Enabled.BoolValue)
	{
		if (gH_Cvar_Tomori_Blocks_Status.BoolValue) SetCommandFlags("status", FCVAR_CHEAT);
		else SetCommandFlags("status", FCVAR_NONE);
		
		if (gH_Cvar_Tomori_Blocks_Ping.BoolValue) SetCommandFlags("ping", FCVAR_CHEAT);
		else SetCommandFlags("ping", FCVAR_NONE);
	}
}

public Action BlockRadio(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (gH_Cvar_Tomori_Blocks_Enabled.BoolValue && gH_Cvar_Tomori_Blocks_Radio.BoolValue) return Plugin_Handled;
	return Plugin_Continue;
}

public Action BlockText(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if (gH_Cvar_Tomori_Blocks_Enabled.BoolValue)
	{
		if(!reliable)
		{
			return Plugin_Continue;
		}

		char buffer[25];
		if(GetUserMessageType() == UM_Protobuf)
		{
			PbReadString(bf, "msg_name", buffer, sizeof(buffer));

			if(strcmp(buffer, "#Cstrike_TitlesTXT_Killed_Teammate") == 0 && gH_Cvar_Tomori_Blocks_Friendlyfire.BoolValue)
				return Plugin_Handled;
		}
		else
		{
			BfReadChar(bf);
			BfReadChar(bf);
			BfReadString(bf, buffer, sizeof(buffer));

			if(strcmp(buffer, "#Cstrike_TitlesTXT_Killed_Teammate") == 0 && gH_Cvar_Tomori_Blocks_Friendlyfire.BoolValue)
				return Plugin_Handled;	
		}
	}
	return Plugin_Continue;
}

public Action BlockMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (gH_Cvar_Tomori_Blocks_Enabled.BoolValue)
	{
		char buffer[64];
		PbReadString(msg, "params", buffer, sizeof(buffer), 0);
		
		if (gH_Cvar_Tomori_Blocks_Cash.BoolValue)
		{
			if (strcmp(buffer, "#Player_Cash_Award_Killed_Enemy") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Win_Hostages_Rescue") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Win_Defuse_Bomb") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Win_Time") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Elim_Bomb") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Elim_Hostage") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_T_Win_Bomb") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Point_Award_Assist_Enemy_Plural") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Point_Award_Assist_Enemy") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Point_Award_Killed_Enemy_Plural") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Point_Award_Killed_Enemy") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Kill_Hostage") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Damage_Hostage") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Get_Killed") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Respawn") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Interact_Hostage") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Killed_Enemy") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Rescued_Hostage") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Bomb_Defused") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Bomb_Planted") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Killed_Enemy_Generic") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Killed_VIP") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_Kill_Teammate") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Win_Hostage_Rescue") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Loser_Bonus") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Loser_Zero") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Rescued_Hostage") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Hostage_Interaction") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Hostage_Alive") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Planted_Bomb_But_Defused") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_CT_VIP_Escaped") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_T_VIP_Killed") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_no_income") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Generic") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Custom") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_no_income_suicide") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_ExplainSuicide_YouGotCash") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_ExplainSuicide_TeammateGotCash") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_ExplainSuicide_EnemyGotCash") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Cash_Award_ExplainSuicide_Spectators") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Team_Award_Killed_Enemy") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Team_Award_Killed_Enemy_Plural") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Team_Award_Bonus_Weapon") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Team_Award_Bonus_Weapon_Plural") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Team_Award_Bonus_Weapon_Plural") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Team_Cash_Award_Survive_GuardianMode_Wave") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Point_Award_Killed_Enemy_NoWeapon") == 0)
				return Plugin_Handled;
			if (strcmp(buffer, "#Player_Point_Award_Killed_Enemy_NoWeapon_Plural") == 0)
				return Plugin_Handled;
		}
		
		if ((StrContains(buffer, "teammate") != -1) && gH_Cvar_Tomori_Blocks_Friendlyfire.BoolValue) 
			return Plugin_Handled;
		
		if (gH_Cvar_Tomori_Blocks_SavedPlayer.BoolValue)
		{
			if (StrContains(buffer, "#Chat_SavePlayer_", false) != -1)
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}


public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(gH_Cvar_Tomori_Blocks_Enabled.BoolValue && EMP_IsValidClient(client))
	{
		if (gH_Cvar_Tomori_Blocks_Connect.IntValue != 0)
			event.BroadcastDisabled = true;
	}
	
	return Plugin_Continue;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if((gH_Cvar_Tomori_Blocks_Enabled.BoolValue) && EMP_IsValidClient(client) && (gH_Cvar_Tomori_Blocks_Connect.IntValue == 1))
	{
		char Name[64], Country[64], IP[64];
		GetClientName(client, Name, sizeof(Name));
		Format(Name, sizeof(Name), "\x07%s\x0B", Name);
		
		if (GetClientIP(client, IP, sizeof(IP) && GeoipCountry(IP, Country, sizeof(Country))))
		{
			for (int idx = 1; idx <= MaxClients; idx++)
			{
				if (EMP_IsValidClient(idx))
					CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Connect", Name, Country);
			}
		}
	}
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(gH_Cvar_Tomori_Blocks_Enabled.BoolValue && EMP_IsValidClient(client))
	{
		if (gH_Cvar_Tomori_Blocks_Disconnect.IntValue == 2)
			event.BroadcastDisabled = true;
		else if(gH_Cvar_Tomori_Blocks_Disconnect.IntValue == 1)
		{
			event.BroadcastDisabled = true;
			
			char Name[64];
			GetEventString(event, "name", Name, sizeof(Name));
			Format(Name, sizeof(Name), "\x07%s\x0B", Name);
			
			for (int idx = 1; idx <= MaxClients; idx++)
			{
				if (EMP_IsValidClient(idx))
					CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Disconnect", Name);
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(EMP_IsValidClient(client))
	{
		if(!event.GetBool("disconnect"))
		{
			if (gShadow_Tomori_ChangedTeamByTomori[client])
			{
				gShadow_Tomori_ChangedTeamByTomori[client] = false;
				event.SetBool("silent", true);
				SetEventBroadcast(event, true);
				
				Event fakeevent = CreateEvent("player_team");
				fakeevent.SetInt("userid", GetClientUserId(client));
				fakeevent.FireToClient(client);
				CancelCreatedEvent(fakeevent);
				return Plugin_Handled;
			}
			else
			{
				gShadow_Admin_HideMe[client] = false;
			}
			
			if (gH_Cvar_Tomori_Blocks_Enabled.BoolValue)
			{
				if (gH_Cvar_Tomori_Blocks_TeamChange.IntValue == 2)
				{
					event.SetBool("silent", true);
					SetEventBroadcast(event, true);
					
					Event fakeevent = CreateEvent("player_team");
					fakeevent.SetInt("userid", GetClientUserId(client));
					fakeevent.FireToClient(client);
					CancelCreatedEvent(fakeevent);
				}
				else if (gH_Cvar_Tomori_Blocks_TeamChange.IntValue == 1)
				{
					char TeamName[64];
					
					if (event.GetInt("team") == CS_TEAM_T) FormatEx(TeamName, sizeof(TeamName), "%t", "Tomori Terrorist");
					else if (event.GetInt("team") == CS_TEAM_CT) FormatEx(TeamName, sizeof(TeamName), "%t", "Tomori CounterTerrorist");
					else if (event.GetInt("team") == CS_TEAM_SPECTATOR) FormatEx(TeamName, sizeof(TeamName), "%t", "Tomori Spectator");
				
					char Name[64];
					GetClientName(client, Name, sizeof(Name));
					Format(Name, sizeof(Name), "\x07%s\x0B", Name);
					Format(TeamName, sizeof(TeamName), "\x07%s\x0B", TeamName);
					
					for (int idx = 1; idx <= MaxClients; idx++)
					{
						if (EMP_IsValidClient(idx))
						{
							CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori ChangedTeam", Name, TeamName);
						}
					}

					event.SetBool("silent", true);
					SetEventBroadcast(event, true);
					
					Event fakeevent = CreateEvent("player_team");
					fakeevent.SetInt("userid", GetClientUserId(client));
					fakeevent.FireToClient(client);
					CancelCreatedEvent(fakeevent);
					
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}