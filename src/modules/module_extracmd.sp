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

ConVar 	gH_Cvar_Tomori_ExtraCMD_Enabled,					//Enable or disable ExtraCMD Module (0 - Disable, 1 - Enable)
		gH_Cvar_Tomori_ExtraCMD_Stealth,					//Enable or disable Stealth Command (0 - Disable, 1 - Enable)
		gH_Cvar_Tomori_ExtraCMD_Stealth_Flag,				//Flag to use stealth
		gH_Cvar_Tomori_ExtraCMD_ClearWep,					//Enable or disable Clear Dropped Weapons Command (0 - Disable, 1 - Enable)
		gH_Cvar_Tomori_ExtraCMD_ClearWep_Flag,				//Flag to use Clear dropped weapons command
		gH_Cvar_Tomori_ExtraCMD_Banhammer,					//Enable or disable Banhammer Command (0 - Disable, 1 - Enable)
		gH_Cvar_Tomori_ExtraCMD_Banhammer_Flag,				//Flag to use banhammer
		gH_Cvar_Tomori_ExtraCMD_Banhammer_BanTime;			//BanTime for BanHammer

bool gShadow_AdminHas_Banhammer[MAXPLAYERS+1];

int g_iDroppedEntity[MAXPLAYERS+1][12];

int g_iPlayerManager,
	g_iConnectedOffset,
	g_iAliveOffset,
	g_iTeamOffset,
	g_iPingOffset,
	g_iScoreOffset,
	g_iDeathsOffset,
	g_iHealthOffset;

public void ExtraCMD_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_ExtraCMD", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_ExtraCMD_Enabled = AutoExecConfig_CreateConVar("tomori_extracmd_enabled", "1", "Enable or disable extracmd module in tomori:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_ExtraCMD_Banhammer = AutoExecConfig_CreateConVar("tomori_extracmd_banhammer_enabled", "1", "Enable or disable banhammer command:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_ExtraCMD_ClearWep = AutoExecConfig_CreateConVar("tomori_extracmd_clearwep_enabled", "1", "Enable or disable Clear Dropped Weapons Command:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_ExtraCMD_ClearWep_Flag = AutoExecConfig_CreateConVar("tomori_extracmd_clearwep_flag", "b", "Flag to use sm_clearwep", 0);
	gH_Cvar_Tomori_ExtraCMD_Banhammer_BanTime = AutoExecConfig_CreateConVar("tomori_extracmd_banhammer_bantime", "0", "Bantime for Ban-Hammer", 0, true, 0.0);
	gH_Cvar_Tomori_ExtraCMD_Stealth = AutoExecConfig_CreateConVar("tomori_extracmd_stealth_enabled", "1", "Enable or disable stealth command:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_ExtraCMD_Stealth_Flag = AutoExecConfig_CreateConVar("tomori_extracmd_stealth_flag", "b", "Flag to use sm_stealth", 0);
	gH_Cvar_Tomori_ExtraCMD_Banhammer_Flag = AutoExecConfig_CreateConVar("tomori_extracmd_banhammer_flag", "b", "Flag to use sm_banhammer", 0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_ExtraCMD_Enabled.SetInt(0, true, false);

	if (gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue)
	{
		char stealth_flag[8], banhammer_flag[8], clearwep_flag[8];
	
		gH_Cvar_Tomori_ExtraCMD_Stealth_Flag.GetString(stealth_flag, sizeof(stealth_flag));
		gH_Cvar_Tomori_ExtraCMD_Banhammer_Flag.GetString(banhammer_flag, sizeof(banhammer_flag));
		gH_Cvar_Tomori_ExtraCMD_ClearWep_Flag.GetString(clearwep_flag, sizeof(clearwep_flag));
		
		int bh_flag = EMP_Flag_StringToInt(banhammer_flag);
		int st_flag = EMP_Flag_StringToInt(stealth_flag);
		int cw_flag = EMP_Flag_StringToInt(clearwep_flag);
	
		RegAdminCmd("sm_clearwep", Command_ClearWeapons, cw_flag, "Clear dropped weapons by players");
		RegAdminCmd("sm_stealth", Command_StealthMode, st_flag, "Set admins to stealth mode");
		RegAdminCmd("sm_banhammer", Command_Banhammer, bh_flag, "Gives the banhammer to the client");
		RegAdminCmd("sm_aborthammer", Command_AbortBanhammer, bh_flag, "Remive banhammer from the player");
	}

	if (FileExists("sound/tomori/lightning.mp3"))
	{
		AddFileToDownloadsTable("sound/tomori/lightning.mp3");
		PrecacheSoundAny("tomori/lightning.mp3");
	}
	if (FileExists("sound/tomori/fuckedup.mp3"))
	{
		AddFileToDownloadsTable("sound/tomori/fuckedup.mp3");
		PrecacheSoundAny("tomori/fuckedup.mp3");
	}
	
	g_iConnectedOffset = FindSendPropInfo("CCSPlayerResource", "m_bConnected");
	g_iAliveOffset = FindSendPropInfo("CCSPlayerResource", "m_bAlive");
	g_iTeamOffset = FindSendPropInfo("CCSPlayerResource", "m_iTeam");
	g_iPingOffset = FindSendPropInfo("CCSPlayerResource", "m_iPing");
	g_iScoreOffset = FindSendPropInfo("CCSPlayerResource", "m_iScore");
	g_iDeathsOffset = FindSendPropInfo("CCSPlayerResource", "m_iDeaths");
	g_iHealthOffset = FindSendPropInfo("CCSPlayerResource", "m_iHealth");
	
	if (gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue && gH_Cvar_Tomori_ExtraCMD_ClearWep.BoolValue)
	{
		for (int idx = 1; idx <= MaxClients; idx++)
		{
			if (EMP_IsValidClient(idx))
			{
				SDKHook(idx, SDKHook_WeaponDrop, WeaponDrop);
				SDKHook(idx, SDKHook_WeaponCanUse, WeaponPickup);
				
				for (int ent = 0; ent < 10; ent++)
				{
					if ((ent > 10) || !EMP_IsValidClient(ent)) break;
					
					if (g_iDroppedEntity[idx][ent] != 0)
						g_iDroppedEntity[idx][ent] = 0;
				}
			}
		}
	}
}

public void ExtraCMD_Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (EMP_IsValidClient(client) && gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue && gH_Cvar_Tomori_ExtraCMD_ClearWep.BoolValue)
	{
		for (int idx = 0; idx < 10; idx++)
		{
			if ((idx > 10) || !EMP_IsValidClient(client)) break;
			
			if (g_iDroppedEntity[client][idx] != 0)
				g_iDroppedEntity[client][idx] = 0;
		}
	}
}

public void ExtraCMD_OnClientPutInServer(int client)
{
	if (EMP_IsValidClient(client) && gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue && gH_Cvar_Tomori_ExtraCMD_ClearWep.BoolValue)
	{
		SDKHook(client, SDKHook_WeaponDrop, WeaponDrop);
		SDKHook(client, SDKHook_WeaponCanUse, WeaponPickup);
	}
}

public Action WeaponPickup(int client, int entity)
{
	if (EMP_IsValidClient(client) && gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue && gH_Cvar_Tomori_ExtraCMD_ClearWep.BoolValue)
	{
		if (Weapon_IsValid(entity))
		{
			for (int idx = 0; idx < 10; idx++)
			{
				if (idx > 10 || !EMP_IsValidClient(client)) break;
				if (g_iDroppedEntity[client][idx] == 0) continue;
				
				if (g_iDroppedEntity[client][idx] == entity)
				{
					g_iDroppedEntity[client][idx] = 0;
					break;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action WeaponDrop(int client, int weapon)
{
	if (gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue && gH_Cvar_Tomori_ExtraCMD_ClearWep.BoolValue && EMP_IsValidClient(client))
	{
		if (Weapon_IsValid(weapon))
		{
			bool HandledDrop = false;
			for (int idx = 0; idx < 10; idx++)
			{
				if (idx > 10) break;
				
				if (!HandledDrop && g_iDroppedEntity[client][idx] == 0)
				{
					g_iDroppedEntity[client][idx] = weapon;
					HandledDrop = true;
					break;
				}
			}
			
			if (!HandledDrop)
			{
				PerformCleanForClient(client);
				for (int idx = 1; idx <= MaxClients; idx++)
				{
					if (EMP_IsValidClient(idx))
					{
						CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori ClearWep Overflow", client);
					}
				}
				
				WeaponDrop(client, weapon);
			}
		}
	}
	return Plugin_Continue;
} 

public void PerformCleanForClient(int client)
{
	if (gH_Cvar_Tomori_ExtraCMD_ClearWep.BoolValue && EMP_IsValidClient(client))
	{
		int Entity;
		for (int idx = 0; idx < 10; idx++)
		{
			Entity = g_iDroppedEntity[client][idx];
			if (Entity != 0)
			{
				if (Weapon_IsValid(Entity))
					Entity_Kill(Entity);
				
				g_iDroppedEntity[client][idx] = 0;
			}
		}
	}
}

public void ExtraCMD_OnMapStart()
{
	if (FileExists("sound/tomori/lightning.mp3"))
	{
		AddFileToDownloadsTable("sound/tomori/lightning.mp3");
		PrecacheSoundAny("tomori/lightning.mp3");
	}
	if (FileExists("sound/tomori/fuckedup.mp3"))
	{
		AddFileToDownloadsTable("sound/tomori/fuckedup.mp3");
		PrecacheSoundAny("tomori/fuckedup.mp3");
	}
	
	if (gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue)
	{
		g_iPlayerManager = FindEntityByClassname(-1, "cs_player_manager");
		if(g_iPlayerManager != -1)
			SDKHook(g_iPlayerManager, SDKHook_ThinkPost, Hook_PMThink);
			
		for (int client = 1; client <= MaxClients; client++)
		{
			for (int idx = 0; idx < 10; idx++)
			{
				if ((idx > 10) || !EMP_IsValidClient(idx)) break;
				
				if (g_iDroppedEntity[client][idx] == 0)
					g_iDroppedEntity[client][idx] = 0;
			}
		}
	}
}

public void ExtraCMD_OnClientDisconnect(int client)
{
	gShadow_Admin_HideMe[client] = false;
	
	for (int idx = 0; idx < 10; idx++)
	{
		if ((idx > 10) || !EMP_IsValidClient(idx)) break;
		
		if (g_iDroppedEntity[client][idx] != 0)
			g_iDroppedEntity[client][idx] = 0;
	}
}

public Action OnTakeDamage(int target, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (gH_Cvar_Tomori_Enabled.BoolValue && gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue && gH_Cvar_Tomori_ExtraCMD_Banhammer.BoolValue)
	{
		if (gShadow_AdminHas_Banhammer[attacker])
		{
			char Reason[128];
			
			gShadow_AdminHas_Banhammer[attacker] = false;
			SDKUnhook(attacker, SDKHook_WeaponCanUse, BanhammerBlock);
			SDKUnhook(attacker, SDKHook_WeaponDrop, BanhammerBlock);
			
			if (FileExists("sound/tomori/lightning.mp3"))
			{
				EmitSoundToAllAny("tomori/lightning.mp3");
			}
			
			Client_RemoveAllWeapons(attacker);
			EMP_RestoreWeapons(attacker);
			
			if (!Client_HasWeapon(attacker, "weapon_knife"))
				EMP_EquipKnife(attacker);
			
			SetEntProp(attacker, Prop_Data, "m_takedamage", 2, 1);
			
			FormatEx(Reason, sizeof(Reason), "[Tomori] %t", "Tomori ExtraCMD BanHammer Reason", attacker);
			
			FakeClientCommand(attacker, "sm_ban #%i %i \"%s\"", GetClientUserId(target), gH_Cvar_Tomori_ExtraCMD_Banhammer_BanTime.IntValue, Reason);
			
			for (int idx = 1; idx <= MaxClients; idx++)
			{
				if (EMP_IsValidClient(idx))
				{
					SetEntityMoveType(idx, MOVETYPE_WALK);
					CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori ExtraCMD BanHammer Banned", target);
				}
			}
		}
	}
}

public Action Command_AbortBanhammer(int client, int args)
{
	if (gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue && gH_Cvar_Tomori_ExtraCMD_Banhammer.BoolValue)
	{
		if (gShadow_AdminHas_Banhammer[client])
		{
			gShadow_AdminHas_Banhammer[client] = false;
			SDKUnhook(client, SDKHook_WeaponCanUse, BanhammerBlock);
			SDKUnhook(client, SDKHook_WeaponDrop, BanhammerBlock);
			
			Client_RemoveAllWeapons(client);
			EMP_RestoreWeapons(client);
			
			if (!Client_HasWeapon(client, "weapon_knife"))
				EMP_EquipKnife(client);
			
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			
			for (int idx = 1; idx <= MaxClients; idx++)
			{
				if (EMP_IsValidClient(idx))
				{
					SetEntityMoveType(idx, MOVETYPE_WALK);
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_Banhammer(int client, int args)
{
	if (gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue && gH_Cvar_Tomori_ExtraCMD_Banhammer.BoolValue)
	{
		if (EMP_IsValidClient(client, false, false))
		{
			EMP_SaveWeapons(client);
			
			gShadow_AdminHas_Banhammer[client] = true;
			
			SDKHook(client, SDKHook_WeaponCanUse, BanhammerBlock);
			SDKHook(client, SDKHook_WeaponDrop, BanhammerBlock);
			
			int iClientWeapon = EMP_EquipWeapon(client, "weapon_hammer", true);
			
			int g_Offset_SecAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
			SetEntDataFloat(iClientWeapon, g_Offset_SecAttack, 5000.0);
			
			CreateTimer(1.0, TimerTick_Equipper, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			
			if (FileExists("sound/tomori/fuckedup.mp3"))
			{
				EmitSoundToAllAny("tomori/fuckedup.mp3");
			}
			
			for (int idx = 1; idx <= MaxClients; idx++)
			{
				if (EMP_IsValidClient(idx))
				{
					SetEntityMoveType(idx, MOVETYPE_NONE);
					SDKHook(idx, SDKHook_OnTakeDamage, OnTakeDamage);
					CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori ExtraCMD BanHammer Announce", client);
				}
			}
			
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		else
		{
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori ExtraCMD Alive", client);
		}
	}
	return Plugin_Handled;
}

public Action TimerTick_Equipper(Handle timer, int id)
{
	int client = GetClientOfUserId(id);
	if (!EMP_IsValidClient(client, false, false || !gShadow_AdminHas_Banhammer[client])) return Plugin_Stop;
	
	if (!Client_HasWeapon(client, "weapon_hammer"))
			EMP_EquipWeapon(client, "weapon_hammer");
	
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue && gH_Cvar_Tomori_ExtraCMD_Banhammer.BoolValue)
	{
		if (EMP_IsValidClient(client, false, false))
		{
			if (gShadow_AdminHas_Banhammer[client])
			{
				if(buttons & IN_ATTACK && buttons & IN_ATTACK2)
				{
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action BanhammerBlock(int client, int weapon)  
{
	if (gShadow_AdminHas_Banhammer[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_StealthMode(int client, int args)
{
	if (gH_Cvar_Tomori_ExtraCMD_Stealth.BoolValue && gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue)
	{
		if (EMP_IsValidClient(client))
		{
			if(!gShadow_Admin_HideMe[client])
			{
				for (int idx = 1; idx <= MaxClients; idx++)
				{
					if (EMP_IsValidClient(idx))
					{
						CPrintToChat(idx, "%t", "Tomori Stealth Disconnect", client);
					}
				}
			
				gShadow_Admin_HideMe[client] = true;
				gShadow_Tomori_ChangedTeamByTomori[client] = true;
				
				if(GetClientTeam(client) != CS_TEAM_SPECTATOR)
					ChangeClientTeam(client, CS_TEAM_SPECTATOR);
			}
			else
			{
				for (int idx = 1; idx <= MaxClients; idx++)
				{
					if (EMP_IsValidClient(idx))
					{
						CPrintToChat(idx, "%t", "Tomori Stealth Connect", client);
					}
				}
			
				gShadow_Admin_HideMe[client] = false;
			}
		}			
	}
	return Plugin_Continue;
}

public Action Command_ClearWeapons(int client, int args)
{
	if (gH_Cvar_Tomori_ExtraCMD_ClearWep.BoolValue && gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue)
	{
		if (EMP_IsValidClient(client))
		{
			for (int idx = 1; idx <= MaxClients; idx++)
			{
				if (EMP_IsValidClient(idx))
				{
					PerformCleanForClient(idx);
				}
			}
		}

		for (int idx = 1; idx <= MaxClients; idx++)
		{
			if (EMP_IsValidClient(idx))
			{
				CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori ClearWep AdminClear", client);
			}
		}
	}
	return Plugin_Continue;
}

public void Hook_PMThink(int entity)
{
	if (gH_Cvar_Tomori_ExtraCMD_Stealth.BoolValue && gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue)
	{
		for(int i = 1; i<= MaxClients; i++)
		{
			if(EMP_IsValidClient(i) && gShadow_Admin_HideMe[i])
			{
				SetEntData(g_iPlayerManager, g_iAliveOffset + (i * 4), false, 4, true);
				SetEntData(g_iPlayerManager, g_iConnectedOffset + (i * 4), false, 4, true);
				SetEntData(g_iPlayerManager, g_iTeamOffset + (i * 4), 0, 4, true);
				SetEntData(g_iPlayerManager, g_iPingOffset + (i * 4), 0, 4, true);
				SetEntData(g_iPlayerManager, g_iScoreOffset + (i * 4), 0, 4, true);
				SetEntData(g_iPlayerManager, g_iDeathsOffset + (i * 4), 0, 4, true);
				SetEntData(g_iPlayerManager, g_iHealthOffset + (i * 4), 0, 4, true);
			}
		}
	}
}

public void OnGameFrame()
{
	if (gH_Cvar_Tomori_ExtraCMD_Stealth.BoolValue && gH_Cvar_Tomori_ExtraCMD_Enabled.BoolValue)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(EMP_IsValidClient(i) && gShadow_Admin_HideMe[i])
			{
				SetEntData(g_iPlayerManager, g_iAliveOffset + (i * 4), false, 4, true);
				SetEntData(g_iPlayerManager, g_iConnectedOffset + (i * 4), false, 4, true);
				SetEntData(g_iPlayerManager, g_iTeamOffset + (i * 4), 0, 4, true);
				SetEntData(g_iPlayerManager, g_iPingOffset + (i * 4), 0, 4, true);
				SetEntData(g_iPlayerManager, g_iScoreOffset + (i * 4), 0, 4, true);
				SetEntData(g_iPlayerManager, g_iDeathsOffset + (i * 4), 0, 4, true);
				SetEntData(g_iPlayerManager, g_iHealthOffset + (i * 4), 0, 4, true);
			}
		}
	}
}