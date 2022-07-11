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

ConVar	gH_Cvar_Tomori_AutoJoin_Enabled,				//Enable or disable AutoJoin Module (0 - Disable, 1 - Enabled)
		gH_Cvar_Tomori_AutoJoin_Mode,					//AutJoin Mode (0 - Given Team with ConVar, 1 - AutoAssign)
		gH_Cvar_Tomori_AutoJoin_Team,					//Team to join automatically (1 - Spectator, 2 - Terrorist, 3 - Counter-Terrorist)
		GraceTime;

bool 	AllowSpawn = true;

public void AutoJoin_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_AutoJoin", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_AutoJoin_Enabled = AutoExecConfig_CreateConVar("tomori_autojoin_enabled", "0", "Enable or disable AutoJoin Module (0 - Disable, 1 - Enabled)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_AutoJoin_Mode = AutoExecConfig_CreateConVar("tomori_autojoin_mode", "1", "AutJoin Mode (0 - Given Team with ConVar, 1 - AutoAssign)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_AutoJoin_Team = AutoExecConfig_CreateConVar("tomori_autojoin_team", "2", "Team to join automatically (1 - Spectator, 2 - Terrorist, 3 - Counter-Terrorist)", 0, true, 1.0, true, 3.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_AutoJoin_Enabled.SetInt(0, true, false);
		
	HookEvent("player_connect_full", Event_ConnectionComplete);
		
	GraceTime = FindConVar("mp_join_grace_time");
}

public Action AutoJoin_JoinTeamCmd(int client, char[] command, int argc)
{
	if (EMP_IsValidClient(client) && gH_Cvar_Tomori_AutoJoin_Enabled.BoolValue && argc > 1)
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		int toteam = StringToInt(arg);
		
		if (toteam != GetClientTeam(client))
		{
			if (gShadow_CTBanFound)
			{
				if ((CTBan_IsClientBanned(client)) && (toteam == CS_TEAM_CT))
					toteam = CS_TEAM_T;
			}
			
			if (gShadow_TeamBanFound)
			{
				if ((TeamBans_IsClientBanned(client)) && (toteam == CS_TEAM_CT))
					toteam = CS_TEAM_T;
			}
			
			if (gShadow_MYJBBanFound)
			{
				toteam = CS_TEAM_T;
			}
		
			if (IsPlayerAlive(client)) ForcePlayerSuicide(client);
			
			ChangeClientTeam(client, toteam);
		}
	}
	return Plugin_Continue;
}

public void Event_ConnectionComplete(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!EMP_IsValidClient(client) || !gH_Cvar_Tomori_AutoJoin_Enabled.BoolValue) return;

	int Team = 0;
	if (gH_Cvar_Tomori_AutoJoin_Mode.BoolValue)
	{
		if (GetTeamClientCount(CS_TEAM_T) > GetTeamClientCount(CS_TEAM_CT)) Team = 3;
		else if (GetTeamClientCount(CS_TEAM_T) <= GetTeamClientCount(CS_TEAM_CT)) Team = 2;
	}
	else
	{
		Team = gH_Cvar_Tomori_AutoJoin_Team.IntValue;
	}
	
	if (gShadow_CTBanFound)
	{
		if ((CTBan_IsClientBanned(client)) && (Team == CS_TEAM_CT))
			Team = CS_TEAM_T;
	}
	
	if (gShadow_TeamBanFound)
	{
		if ((TeamBans_IsClientBanned(client)) && (Team == CS_TEAM_CT))
			Team = CS_TEAM_T;
	}
	
	if (gShadow_MYJBBanFound)
	{
		return;
	}
	
	ChangeClientTeam(client, Team);

	if (!IsPlayerAlive(client) && (Team == CS_TEAM_T || Team == CS_TEAM_CT) && !(GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT)) && AllowSpawn)
	{
		CS_RespawnPlayer(client);
	}
}

public void AutoJoin_Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	if (GameRules_GetProp("m_bWarmupPeriod") != 1 && gH_Cvar_Tomori_AutoJoin_Enabled.BoolValue)
	{
		CreateTimer(GraceTime.FloatValue, Timer_BlockSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
		AllowSpawn = true;
	}
}

public Action Timer_BlockSpawn(Handle timer)
{
	AllowSpawn = false;
}