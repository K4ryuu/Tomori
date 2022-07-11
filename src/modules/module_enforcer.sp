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

ConVar gH_Cvar_Tomori_Enforcer_Enabled;				//Enable or disable Enforcer Module (0 - Disable, 1 - Enabled)

ArrayList 	g_hCvarList,
			g_hValueList;

public void Enforcer_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_Enforcer", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_Enforcer_Enabled = AutoExecConfig_CreateConVar("tomori_enforcer_enabled", "0", "Enable or disable Purge module in Tomori", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_Enforcer_Enabled.SetInt(0, true, false);

	if (gH_Cvar_Tomori_Enforcer_Enabled.BoolValue)
		EnforceAllCvars(0);
}

public void Enforcer_OnMapStart()
{
	if (gH_Cvar_Tomori_Enforcer_Enabled.BoolValue) EnforceAllCvars(0);
}

public void EnforceAllCvars(int client)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/Tomori/enforce_cvar.cfg");
	
	if(FileExists(sPath))
	{
		Handle hFile = OpenFile(sPath, "r");
		
		if(hFile != null)
		{		
			char sCvar[256];
			int iSize = GetArraySize(g_hCvarList);
			ConVar c;
			for(int idx; idx < iSize; idx++)
			{
				GetArrayString(g_hCvarList, idx, sCvar, sizeof(sCvar));
				
				c = FindConVar(sCvar);
				
				if(c != null)
				{
					UnhookConVarChange(c, OnConVarChanged);
					delete c;
				}
			}
			
			ClearArray(g_hCvarList);
			ClearArray(g_hValueList);
			
			char sLine[256], sLineExploded[2][256];
			while(!IsEndOfFile(hFile))
			{
				ReadFileLine(hFile, sLine, sizeof(sLine));
				if(strlen(sLine) > 0)
				{
					ReplaceString(sLine, sizeof(sLine), "\n", NULL_STRING);
					ExplodeString(sLine, " ", sLineExploded, sizeof(sLineExploded), sizeof(sLineExploded[]), true);
					ReplaceString(sLineExploded[0], sizeof(sLineExploded[]), "\"", NULL_STRING);
					ReplaceString(sLineExploded[1], sizeof(sLineExploded[]), "\"", NULL_STRING);
					
					EnforceConVar(sLineExploded[0], sLineExploded[1]);
				}
			}
			
			delete hFile;
		}
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(!gH_Cvar_Tomori_Enforcer_Enabled.BoolValue)
		return;
	
	char sCvarName[256], sCvarListCvar[256], sValue[256];
	convar.GetName(sCvarName, sizeof(sCvarName));
	
	int iSize = GetArraySize(g_hCvarList);
	for(int idx; idx < iSize; idx++)
	{
		GetArrayString(g_hCvarList, idx, sCvarListCvar, sizeof(sCvarListCvar));
		
		if(strcmp(sCvarName, sCvarListCvar) == 0)
		{
			GetArrayString(g_hValueList, idx, sValue, sizeof(sValue));
			
			if(strcmp(newValue, sValue) != 0)
			{
				convar.SetString(sValue);
			}
		}
	}
}

void EnforceConVar(const char[] sCvar, const char[] sValue)
{
	ConVar c = FindConVar(sCvar);
	
	if(c != null)
	{
		HookConVarChange(c, OnConVarChanged);
		
		PushArrayString(g_hCvarList, sCvar);
		PushArrayString(g_hValueList, sValue);
		
		char sCurrentValue[128];
		c.GetString(sCurrentValue, sizeof(sCurrentValue));
		if(strcmp(sValue, sCurrentValue) != 0)
		{
			c.SetString(sValue);
		}
		
		delete c;
	}
}