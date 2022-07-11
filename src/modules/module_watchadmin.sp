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

ConVar gH_Cvar_Tomori_Watchadmin_Enabled;					//Enable or disable Watchadmin Module (0 - Disable, 1 - Enabled)
ConVar gH_Cvar_Tomori_Watchadmin_LogMode;					//LogMode for WatchAdmin (0 - Disabled, 1 - Log All CMD, 2 - Log Custom CFG)

char gShadow_Tomori_Admin_LogFile[PLATFORM_MAX_PATH];
char CMDList[PLATFORM_MAX_PATH];

public void Watchadmin_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Watchadmin", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Watchadmin_Enabled = AutoExecConfig_CreateConVar("tomori_watchadmin_enabled", "1", "Enable or disable watchadmin module in tomori:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_Watchadmin_LogMode = AutoExecConfig_CreateConVar("tomori_watchadmin_logmode", "2", "LogMode for WatchAdmin (0 - Disabled, 1 - Log All CMD, 2 - Log Custom CFG)", 0, true, 0.0, true, 2.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Watchadmin_Enabled.SetInt(0, true, false);
	
	char Folder[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, Folder, sizeof(Folder), "logs/Entity");
	EMP_DirExistsEx(Folder);
	EMP_SetLogFile(gShadow_Tomori_Admin_LogFile, "Tomori-Overwatch", "Entity");
	
	if (gH_Cvar_Tomori_Watchadmin_LogMode.IntValue == 1)
	{
		char Name[64];
		char Desc[255];
		int Flags;
		Handle CmdIter = GetCommandIterator();

		int AdminCmdCount;
		
		while(ReadCommandIterator(CmdIter, Name, sizeof(Name), Flags, Desc, sizeof(Desc)))
		{
			if(AddCommandListener(Tomori_Logthat, Name))
			{
				AdminCmdCount++;
			}
		}
		EMP_FreeHandle(CmdIter);
	}
	else if (gH_Cvar_Tomori_Watchadmin_LogMode.IntValue == 2)
	{
		ReadCMDList();
	}
}

public void Watchadmin_OnMapStart()
{
	if (gH_Cvar_Tomori_Watchadmin_Enabled.BoolValue)
	{
		ReadCMDList();
	}
}

stock bool ReadCMDList()
{
	BuildPath(Path_SM, CMDList, sizeof(CMDList), "configs/Tomori/cmd_to_log.ini");	
	Handle CMD = OpenFile(CMDList, "rt");
	
	if (CMD == INVALID_HANDLE)
	{
		#if (MODULE_LOGGING == 1)
		LogToFileEx(gShadow_Tomori_LogFile, "CMD_TO_LOG list is missing from configs/Tomori/");
		#endif
		return false;
	}
	
	while (!IsEndOfFile(CMD))
	{
		char CurrentLine[64];
		if (!ReadFileLine(CMD, CurrentLine, sizeof(CurrentLine)))
			break;
		
		TrimString(CurrentLine); ReplaceString(CurrentLine, sizeof(CurrentLine), " ", NULL_STRING);
		if (strlen(CurrentLine) == 0 || (CurrentLine[0] == '/' && CurrentLine[1] == '/'))
			continue;
		
		AddCommandListener(Tomori_Logthat, CurrentLine);
	}
	
	EMP_FreeHandle(CMD);
	return true;
}

public Action Tomori_Logthat(int client, const char[] command, int args)
{
	char argstring[512], temparg[64], logstring[512];
	for (int i = args; i > 0; i--)
	{
		GetCmdArg(i, temparg, sizeof(temparg));
		Format(argstring, sizeof(argstring), "%s %s", temparg, argstring);
	}
	
	FormatEx(logstring, sizeof(logstring), "%L - %s %s", client, command, argstring);
	LogToFileEx(gShadow_Tomori_Admin_LogFile, logstring);
}

public Action OnLogAction(Handle source, Identity ident, int client, int target,const char[] message)
{
	if (!EMP_IsValidClient(client) || GetUserAdmin(client) == INVALID_ADMIN_ID)
	{
		return Plugin_Continue;
	}
	
	if (gH_Cvar_Tomori_Watchadmin_LogMode.IntValue != 2) return Plugin_Handled;
	
	char logtag[64];
	GetPluginFilename(source, logtag, sizeof(logtag));
	LogToFileEx(gShadow_Tomori_Admin_LogFile, "[%s] %s", logtag, message);
	return Plugin_Handled;
}