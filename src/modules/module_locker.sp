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

ConVar 	gH_Cvar_Tomori_Status_Enabled,					//Enable or disable Custom Status Module (0 - Disable, 1 - Enabled)
		gH_Cvar_Tomori_Status_Flag;

Handle 	Rcon_Password,
		Rcon_Min,
		Rcon_Max;
		
char 	Rcon_Password_Save[256];

public void Locker_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Locker", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Status_Enabled = AutoExecConfig_CreateConVar("tomori_status_enabled", "1", "Enable or disable status module in tomori:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Status_Flag = AutoExecConfig_CreateConVar("tomori_extracmd_status_flag", "", "Flag to get the player list in status (Empty for public)", 0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Status_Enabled.SetInt(0, true, false);
		
	PTaH(PTaH_ExecuteStringCommandPre, Hook, ExecuteStringCommand);
	
	Rcon_Password = FindConVar("rcon_password");
	HookConVarChange(Rcon_Password, Lock_Rcon);
	
	Rcon_Min = FindConVar("sv_rcon_minfailures");
	Rcon_Max = FindConVar("sv_rcon_maxfailures");
	
	SetConVarBounds(Rcon_Min, ConVarBound_Upper, false);
	SetConVarBounds(Rcon_Max, ConVarBound_Upper, false);
}

public void Lock_Rcon(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (!StrEqual(newValue, Rcon_Password_Save))
		SetConVarString(Rcon_Password, Rcon_Password_Save, true, false);
}

public void Lock_OnConfigsExecuted()
{
	GetConVarString(Rcon_Password, Rcon_Password_Save, sizeof(Rcon_Password_Save));
	
	if (GetConVarInt(Rcon_Min) == 5)
		SetConVarInt(Rcon_Min, 10000, true, true);
		
	if (GetConVarInt(Rcon_Max) == 10)
		SetConVarInt(Rcon_Max, 10000, true, true);
}

public Action ExecuteStringCommand(int client, char sCommandString[512])
{
	if (EMP_IsValidClient(client) && gH_Cvar_Tomori_Status_Enabled.BoolValue)
	{
		static char sMessage[512];
		strcopy(sMessage, sizeof(sMessage), sCommandString);
		TrimString(sMessage);
		
		if (StrContains(sMessage, "status ") == 0 || StrEqual(sMessage, "status", false))
		{
			char buffer[256];
			
			PrintToConsole(client, "———————————————————————————————————————————————————————————————————————————————");
			PrintToConsole(client, "#");
			Format(buffer, sizeof(buffer), "#	Server name: 	{hostname}"); EMP_ReplaceFormats(buffer, sizeof(buffer));
			PrintToConsole(client, buffer);
			Format(buffer, sizeof(buffer), "#	Server IP: 	{server_ip}"); EMP_ReplaceFormats(buffer, sizeof(buffer));
			PrintToConsole(client, buffer);
			Format(buffer, sizeof(buffer), "#	Player count: 	{player_count}({connecting_players})/{maxplayers}"); EMP_ReplaceFormats(buffer, sizeof(buffer));
			PrintToConsole(client, buffer);
			Format(buffer, sizeof(buffer), "#	Current date: 	{current_date}"); EMP_ReplaceFormats(buffer, sizeof(buffer));
			PrintToConsole(client, buffer);
			Format(buffer, sizeof(buffer), "#	Current time: 	{current_time}"); EMP_ReplaceFormats(buffer, sizeof(buffer));
			PrintToConsole(client, buffer);
			Format(buffer, sizeof(buffer), "#	Current map: 	{currentmap}"); EMP_ReplaceFormats(buffer, sizeof(buffer));
			PrintToConsole(client, buffer);
			Format(buffer, sizeof(buffer), "#	Nextmap: 	{nextmap}"); EMP_ReplaceFormats(buffer, sizeof(buffer));
			PrintToConsole(client, buffer);
			PrintToConsole(client, "#");
			PrintToConsole(client, "# by: Entity");
			PrintToConsole(client, "# Credit: Brum Brum & Bara");
			PrintToConsole(client, "———————————————————————————————————————————————————————————————————————————————");
			PrintToConsole(client, "# UserID  | Playername 		| 	 SteamID      |  Connection time  |  Ip");
			
			char status_flag[8];
			gH_Cvar_Tomori_Status_Flag.GetString(status_flag, sizeof(status_flag));
			
			if (strlen(status_flag) > 0)
			{
				int istatus_flag = EMP_Flag_StringToInt(status_flag);
				
				if (Client_HasAdminFlags(client, istatus_flag))
				{
					for (int idx = 1; idx <= MaxClients; idx++)
					{
						if (EMP_IsValidClient(idx) && !gShadow_Admin_HideMe[idx])
						{
							Format(buffer, sizeof(buffer), "# {userid}	    {playername} 		  {steam32}	  {connection_time}            {client_ip}"); EMP_ReplaceFormats(buffer, sizeof(buffer), idx);
							PrintToConsole(client, buffer);
						}
					}
				}
				else
				{
					Format(buffer, sizeof(buffer), "# {userid}	    {playername} 		  {steam32}	  {connection_time}            {client_ip}"); EMP_ReplaceFormats(buffer, sizeof(buffer), client);
					PrintToConsole(client, buffer);
				}
			}
			else
			{
				for (int idx = 1; idx <= MaxClients; idx++)
				{
					if (EMP_IsValidClient(idx) && !gShadow_Admin_HideMe[idx])
					{
						Format(buffer, sizeof(buffer), "# {userid}	    {playername} 		  {steam32}	  {connection_time}            {client_ip}"); EMP_ReplaceFormats(buffer, sizeof(buffer), idx);
						PrintToConsole(client, buffer);
					}
				}
			}
			
			PrintToConsole(client, "———————————————————————————————————————————————————————————————————————————————");
			return Plugin_Handled;
		}
		else if (StrContains(sMessage, "ping ") == 0 || StrEqual(sMessage, "ping", false))
		{
			PrintToConsole(client, "Pong >.<");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}