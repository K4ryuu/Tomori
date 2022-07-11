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

ConVar gH_Cvar_Tomori_NoDisarm_Enabled;					//Enable or disable NoDisarm Module (0 - Disable, 1 - Enabled)

Address g_NoDisarmMod_Start, g_NoDisarmMod_End;
int g_NoDisarmModSave_Start;

public void NoDisarm_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_NoDisarm", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_NoDisarm_Enabled = AutoExecConfig_CreateConVar("tomori_nodisarm_enabled", "0", "Enable or disable disarm on fists hit for players. (0 - Turn on Disarm, 1 - Turn off Disarm)", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_NoDisarm_Enabled.SetInt(0, true, false);

	if (gH_Cvar_Tomori_NoDisarm_Enabled.BoolValue)
	{
		GameData hGameData = LoadGameConfigFile("Tomori_Disarm");
		
		if(!hGameData)
		{
			SetFailState("Failed to load NoDisarmMod GameData. Please install it from the given package.");
			return;
		}
		
		Address NoDisarmMod = hGameData.GetAddress("NoDisarmMod");
		
		if(NoDisarmMod == Address_Null)
		{
			PrintToServer("Please restart the server to make NoDisarm work again. Reload corrupt NoDisarm from working properly.");
			return;
		}
		
		g_NoDisarmMod_Start = NoDisarmMod + view_as<Address>(hGameData.GetOffset("NoDisarmMod_Start"));
		g_NoDisarmMod_End = NoDisarmMod + view_as<Address>(hGameData.GetOffset("NoDisarmMod_End"));
		
		hGameData.Close();
		
		if(LoadFromAddress(g_NoDisarmMod_Start, NumberType_Int8) != 0x80 || LoadFromAddress(g_NoDisarmMod_End, NumberType_Int8) != 0x8B)
		{
			SetFailState("Please re-install the GameData from the given package.");
			return;
		}
		
		g_NoDisarmModSave_Start = LoadFromAddress(g_NoDisarmMod_Start + view_as<Address>(1), NumberType_Int32);
		
		int jmp = view_as<int>(g_NoDisarmMod_End - g_NoDisarmMod_Start) - 5;
		
		StoreToAddress(g_NoDisarmMod_Start, 0xE9, NumberType_Int8);
		StoreToAddress(g_NoDisarmMod_Start + view_as<Address>(1), jmp, NumberType_Int32);
	}
}