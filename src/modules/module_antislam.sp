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

ConVar	gH_Cvar_Tomori_Antislam_Enabled,				//Enable or disable Antislam Module (0 - Disable, 1 - Enabled)
		gH_Cvar_Tomori_Antislam_Flag,					//Immune flag to mutes
		gH_Cvar_Tomori_Antislam_Punishment,				//Punishment mode for using HLDJ or SLAM
		gH_Cvar_Tomori_Antislam_Punish_Reason,			//Punishment Reason for using HLDJ or SLAM
		gH_Cvar_Tomori_Antislam_Ban_Time,				//Ban Time for punishment
		gH_Cvar_Tomori_Antislam_Mute_Time,				//Mute Time for punishment
		gH_Cvar_Tomori_Antislam_Logging;				//Enable or disable antislam logging (0 - Disable, 1 - Enabled)

public void Antislam_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Antislam", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Antislam_Enabled = AutoExecConfig_CreateConVar("tomori_antislam_enabled", "1", "Enable or disable Antislam module in tomori", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Antislam_Flag = AutoExecConfig_CreateConVar("tomori_antislam_immune_flag", "b", "Immune flag to HLDJ and SLAM mute", 0);
	gH_Cvar_Tomori_Antislam_Punishment = AutoExecConfig_CreateConVar("tomori_antislam_punishment", "1", "Punishment mode for using HLDJ or SLAM (0 - Mute, 1 - Kick, 2 - Ban)", 0, true, 0.0, true, 2.0);
	gH_Cvar_Tomori_Antislam_Punish_Reason = AutoExecConfig_CreateConVar("tomori_antislam_reason", "You are not allowed to use Soundboard.", "Punishment Reason for using HLDJ or SLAM", 0);
	gH_Cvar_Tomori_Antislam_Ban_Time = AutoExecConfig_CreateConVar("tomori_antislam_ban_time", "10", "Ban Time for punishment", 0, true, 0.0);
	gH_Cvar_Tomori_Antislam_Mute_Time = AutoExecConfig_CreateConVar("tomori_antislam_mute_time", "30", "Mute Time for punishment", 0, true, 0.0);
	gH_Cvar_Tomori_Antislam_Logging = AutoExecConfig_CreateConVar("tomori_antislam_logging", "1", "Enable or disable antislam logging (0 - Disable, 1 - Enabled)", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Antislam_Enabled.SetInt(0, true, false);
	
	if (gH_Cvar_Tomori_Antislam_Enabled.BoolValue) CreateTimer(1.0, Timer_CheckAudio, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckAudio(Handle timer, any data)
{
	if (gH_Cvar_Tomori_Antislam_Enabled.BoolValue)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if (EMP_IsValidClient(i))
			{
				QueryClientConVar(i, "voice_inputfromfile", CB_CheckAudio);
			}
		}
	}
}

public void CB_CheckAudio(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    if ((result == ConVarQuery_Okay && StringToInt(cvarValue) == 1) && gH_Cvar_Tomori_Antislam_Enabled.BoolValue)
	{
		char immune_flag[32];
		gH_Cvar_Tomori_Antislam_Flag.GetString(immune_flag, sizeof(immune_flag));
		
		int flag = EMP_Flag_StringToInt(immune_flag);
		
		if (Client_HasAdminFlags(client, flag))
		{
			return;
		}

		char reason[256];
		gH_Cvar_Tomori_Antislam_Punish_Reason.GetString(reason, sizeof(reason));
		Format(reason, sizeof(reason), "[Tomori] %s", reason);
		
		switch (gH_Cvar_Tomori_Antislam_Punishment.IntValue)
		{
			case 0:
			{
				if (!BaseComm_IsClientMuted(client))
				{
					ServerCommand("sm_mute #%i %i \"%s\"", GetClientUserId(client), gH_Cvar_Tomori_Antislam_Mute_Time.IntValue, reason);	
					return;
				}
			}
			case 1:
			{
				KickClient(client, reason);
				return;
			}
			case 2:
			{
				ServerCommand("sm_ban #%i %i \"%s\"", GetClientUserId(client), gH_Cvar_Tomori_Antislam_Ban_Time.IntValue, reason);	
				return;
			}
		}
		
		for (int idx = 1; idx <= MaxClients; idx++)
		{
			if (EMP_IsValidClient(idx))
			{
				CPrintToChat(idx, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Antislam Muted", client);
			}
		}
		
		if (gH_Cvar_Tomori_Antislam_Logging.BoolValue) LogToFileEx(gShadow_Tomori_LogFile, "%L triggered the Anti-Slam Module.", client);
    }
}