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

#include <adminmenu>

ConVar 	gH_Cvar_Tomori_Gathering_Enabled,					//Enable or disable Gathering Module (0 - Disable, 1 - Enabled);
		gH_Cvar_Tomori_Gathering_Flag,						//Flag to use Gathering
		gH_Cvar_Tomori_Gathering_Command;					//The command to use Gathering

int 	gShadow_Tomori_Target[MAXPLAYERS+1],
		gShadow_Tomori_AdminChat[MAXPLAYERS+1] 					= false,
		gShadow_Tomori_AdminBanning[MAXPLAYERS+1] 				= false,
		gShadow_Tomori_AdminCTBanning[MAXPLAYERS+1] 			= false,
		gShadow_Tomori_AdminKicking[MAXPLAYERS+1] 				= false,
		gShadow_Tomori_AdminInGag[MAXPLAYERS+1] 				= false,
		gShadow_Tomori_AdminInMute[MAXPLAYERS+1] 				= false,
		gShadow_Tomori_AdminInSil[MAXPLAYERS+1] 				= false,
		gShadow_Tomori_AdminBanning_Reason[MAXPLAYERS+1] 		= false,
		gShadow_Tomori_AdminBanning_Length_Temp[MAXPLAYERS+1];

public void Gather_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Gathering", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Gathering_Enabled = AutoExecConfig_CreateConVar("tomori_gathering_enabled", "1", "Enable or disable gathering module in tomori:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Gathering_Flag = AutoExecConfig_CreateConVar("tomori_gathering_flag", "b", "Flag to use sm_player", 0);
	gH_Cvar_Tomori_Gathering_Command = AutoExecConfig_CreateConVar("tomori_gathering_command", "sm_player", "Command to use the gathering menu", 0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	if (gH_Cvar_Tomori_Gathering_Enabled.BoolValue)
	{
		char gat_flag[32], gathering_command[128];
		gH_Cvar_Tomori_Gathering_Flag.GetString(gat_flag, sizeof(gat_flag));
		gH_Cvar_Tomori_Gathering_Command.GetString(gathering_command, sizeof(gathering_command));
		
		int gr_flag = EMP_Flag_StringToInt(gat_flag);
		RegAdminCmd(gathering_command, Command_Player, gr_flag, "Open gathering menu for targeted player");
	}
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue || !gH_Cvar_Tomori_Profile_Enabled.BoolValue)
	{
		gH_Cvar_Tomori_Gathering_Enabled.SetInt(0, true, false);
		LogError("Tomori - module_gathering disabled because Tomori or module_profile disabled");
	}
}

public Action Command_Player(int client, int args)
{
	if (gH_Cvar_Tomori_Gathering_Enabled.BoolValue && EMP_IsValidClient(client))
	{
		if (args < 1)
		{
			ShowPlayerList(client);
		}
		else if (args == 1)
		{
			char sTarget[MAX_NAME_LENGTH];
			GetCmdArg(1, sTarget, sizeof(sTarget));

			char sClientName[MAX_TARGET_LENGTH];
			int aiTargetList[MAXPLAYERS];
			bool b_tn_is_ml;
			ProcessTargetString(sTarget, client, aiTargetList, MaxClients, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_MULTI, sClientName, sizeof(sClientName), b_tn_is_ml);
			
			int iTarget = aiTargetList[0];
			
			if(iTarget && EMP_IsValidClient(iTarget))
			{
				gShadow_Tomori_Target[client] = iTarget;
				ShowData(client, iTarget, 1);
			}
		}
	}
	return Plugin_Handled;
}

stock Action ShowPlayerList(int client)
{
	if (EMP_IsValidClient(client))
	{
		Menu menu = CreateMenu(MenuHandler_Player);
		
		char title[100], clientid[32], name[64];
		FormatEx(title, sizeof(title), "-=| %t |=-\n ", "Tomori PlayerMenu");
		menu.SetTitle(title);
		
		for (int idx = 1; idx <= MaxClients; idx++)
		{
			if (EMP_IsValidClient(idx))
			{
				IntToString(idx, clientid, sizeof(clientid));
				GetClientName(idx, name, sizeof(name));
			
				menu.AddItem(clientid, name);
			}
		}
		
		menu.Display(client, MENU_TIME_FOREVER);	
	}
}

public int MenuHandler_Player(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		EMP_FreeHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		int userid = StringToInt(info);

		if (userid == 0)
		{
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori NoLongerAvailable");
		}
		else if (!CanUserTarget(client, userid))
		{
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori UnableToTarget");
		}
		else
		{
			gShadow_Tomori_Target[client] = userid;
			ShowData(client, userid, 1);
		}
	}
}

stock Action ShowData(int client, int target, int itemNum)
{
	if (EMP_IsValidClient(client))
	{
		char databuffer[128];
		FormatEx(databuffer, sizeof(databuffer), "-=| %N |=-\n \n", target);
		if (gShadow_Tomori_Client_Prime[target] == true) Format(databuffer, sizeof(databuffer), "%s%t: %t\n", databuffer, "Tomori Prime", "Tomori Yes");
		else if (gShadow_Tomori_Client_Prime[target] == false) Format(databuffer, sizeof(databuffer), "%s%t: %t\n", databuffer, "Tomori Prime", "Tomori No");
		
		Format(databuffer, sizeof(databuffer), "%s%t: %i\n", databuffer, "Tomori SteamLevel", gShadow_Tomori_Client_Level[target]);
		Format(databuffer, sizeof(databuffer), "%s%t: %i\n", databuffer, "Tomori PlayHours", gShadow_Tomori_Client_Hour[target]);
		Format(databuffer, sizeof(databuffer), "%s%t: %i\n ", databuffer, "Tomori UserID", GetClientUserId(target));

		Menu menu = CreateMenu(MenuHandler_DataChoice);
		menu.SetTitle(databuffer);
		
		FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori AdminControl");
		menu.AddItem("admin", databuffer);
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_DataChoice(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		EMP_FreeHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		if (strcmp(info, "admin") == 0)
		{
			AdminControl(client, 1);
		}
	}
}

stock Action AdminControl(int client, int itemNum)
{
	if (EMP_IsValidClient(client))
	{
		char databuffer[128];
		FormatEx(databuffer, sizeof(databuffer), "-=| %t |=-\n ", "Tomori AdminControl");
		Menu menu = CreateMenu(MenuHandler_AdminChoice);
		menu.SetTitle(databuffer);
		
		FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori AdminBan");
		menu.AddItem("ban", databuffer);
		FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori AdminKick");
		menu.AddItem("kick", databuffer);
		FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori AdminGag");
		menu.AddItem("gag", databuffer);
		FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori AdminMute");
		menu.AddItem("mute", databuffer);
		FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori AdminSilence");
		menu.AddItem("silence", databuffer);
		
		if (gShadow_CTBanFound)
		{
			FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori CTBan Commands");
			menu.AddItem("ctbancmd", databuffer);
		}
		
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_AdminChoice(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		EMP_FreeHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if (strcmp(info, "ban") == 0)
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminBanning[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteTime");
		}
		else if (strcmp(info, "kick") == 0)
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminBanning_Reason[client] = true;
			gShadow_Tomori_AdminKicking[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteReason");
		}
		else if (strcmp(info, "gag") == 0)
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminInGag[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteTime");
		}
		else if (strcmp(info, "mute") == 0)
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminInMute[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteTime");
		}
		else if (strcmp(info, "silence") == 0)
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminInSil[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteTime");
		}
		else if (gShadow_CTBanFound && strcmp(info, "ctbancmd") == 0)
		{
			CtbanControl(client, 1);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ShowData(client, gShadow_Tomori_Target[client], 1);
	}
}

stock Action CtbanControl(int client, int itemNum)
{
	if (EMP_IsValidClient(client))
	{
		char databuffer[128];
		FormatEx(databuffer, sizeof(databuffer), "-=| %t |=-\n ", "Tomori CTBan Commands");
		Menu menu = CreateMenu(MenuHandler_CTBanChoice);
		menu.SetTitle(databuffer);
		
		FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori CTBan BanCT");
		menu.AddItem("ctban", databuffer);
		FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori CTBan RemoveCTBan");
		menu.AddItem("unctban", databuffer);
		FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori CTBan ForceCT");
		menu.AddItem("forcect", databuffer);
		FormatEx(databuffer, sizeof(databuffer), "%t", "Tomori CTBan Isbanned");
		menu.AddItem("isbanned", databuffer);
		
		menu.ExitButton = true;
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_CTBanChoice(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		EMP_FreeHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		if (strcmp(info, "ctban") == 0)
		{
			gShadow_Tomori_AdminChat[client] = true;
			gShadow_Tomori_AdminCTBanning[client] = true;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteTime");
		}
		else if (strcmp(info, "unctban") == 0)
		{
			FakeClientCommand(client, "sm_unctban #%i", GetClientUserId(gShadow_Tomori_Target[client]));
		}
		else if (strcmp(info, "forcect") == 0)
		{
			FakeClientCommand(client, "sm_forcect #%i", GetClientUserId(gShadow_Tomori_Target[client]));
		}
		else if (strcmp(info, "isbanned") == 0)
		{
			FakeClientCommand(client, "sm_isbanned #%i", GetClientUserId(gShadow_Tomori_Target[client]));
		}
	}
	else if (action == MenuAction_Cancel)
	{
		AdminControl(client, 1);
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] message)
{
	if (gShadow_Tomori_AdminChat[client] && EMP_IsValidClient(client))
	{
		if (strcmp(message, "!cancel") == 0 || strcmp(message, "/cancel") == 0)
		{
			gShadow_Tomori_AdminChat[client] = false;
			gShadow_Tomori_AdminBanning[client] = false;
			gShadow_Tomori_AdminCTBanning[client] = false;
			gShadow_Tomori_AdminKicking[client] = false;
			gShadow_Tomori_AdminInGag[client] = false;
			gShadow_Tomori_AdminInMute[client] = false;
			gShadow_Tomori_AdminInSil[client] = false;
			gShadow_Tomori_AdminBanning_Reason[client] = false;
			CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin AbortSuccess");
			return Plugin_Handled;
		}
		else
		{
			if (!gShadow_Tomori_AdminBanning_Reason[client])
			{
				if (!String_IsNumeric(message))
				{
					gShadow_Tomori_AdminBanning[client] = false;
					gShadow_Tomori_AdminBanning_Reason[client] = false;
					CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin InvalidTime");
					return Plugin_Handled;
				}
				else
				{
					gShadow_Tomori_AdminBanning_Reason[client] = true;
					gShadow_Tomori_AdminBanning_Length_Temp[client] = StringToInt(message, 10);
					CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Admin WriteReason");
					return Plugin_Handled;
				}
			}
			else
			{
				if (gShadow_Tomori_AdminBanning[client])
					FakeClientCommand(client, "sm_ban #%i %i \"%s\"", GetClientUserId(gShadow_Tomori_Target[client]), gShadow_Tomori_AdminBanning_Length_Temp[client], message);
				else if (gShadow_Tomori_AdminKicking[client])
					FakeClientCommand(client, "sm_kick #%i %s", GetClientUserId(gShadow_Tomori_Target[client]), message);
				else if (gShadow_Tomori_AdminInGag[client])
					FakeClientCommand(client, "sm_gag #%i %i \"%s\"", GetClientUserId(gShadow_Tomori_Target[client]), gShadow_Tomori_AdminBanning_Length_Temp[client], message);
				else if (gShadow_Tomori_AdminInMute[client])
					FakeClientCommand(client, "sm_mute #%i %i \"%s\"", GetClientUserId(gShadow_Tomori_Target[client]), gShadow_Tomori_AdminBanning_Length_Temp[client], message);
				else if (gShadow_Tomori_AdminInSil[client])
					FakeClientCommand(client, "sm_silence #%i %i \"%s\"", GetClientUserId(gShadow_Tomori_Target[client]), gShadow_Tomori_AdminBanning_Length_Temp[client], message);
				else if (gShadow_Tomori_AdminCTBanning[client])
					FakeClientCommand(client, "sm_ctban #%i %i \"%s\"", GetClientUserId(gShadow_Tomori_Target[client]), gShadow_Tomori_AdminBanning_Length_Temp[client], message);
					
				gShadow_Tomori_AdminChat[client] = false;
				gShadow_Tomori_AdminBanning[client] = false;
				gShadow_Tomori_AdminCTBanning[client] = false;
				gShadow_Tomori_AdminKicking[client] = false;
				gShadow_Tomori_AdminInGag[client] = false;
				gShadow_Tomori_AdminInMute[client] = false;
				gShadow_Tomori_AdminInSil[client] = false;
				gShadow_Tomori_AdminBanning_Reason[client] = false;
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}