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

ConVar 	gH_Cvar_Tomori_CountryFilter_Enabled,					//Enable or disable CountryFilter Module (0 - Disable, 1 - Enabled)
		gH_Cvar_Tomori_CountryFilter_Block_Connect,				//Enabled or disable CountryFilter for joining to server (0 - Disable, 1 - Enabled)
		gH_Cvar_Tomori_CountryFilter_Block_CT,					//Enabled or disable CountryFilter for joining ct team (0 - Disable, 1 - Enabled)
		gH_Cvar_Tomori_CountryFilter_BlockMode,					//Filter ListMode (0 - Whitelist, 1 - Blacklist)
		gH_Cvar_Tomori_CountryFilter_List;						//List (Used like BlockMode set)

char 	country[45];

public void CountryFilter_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_CountryFilter", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_CountryFilter_Enabled = AutoExecConfig_CreateConVar("tomori_countryfilter_enabled", "0", "Enable or disable CountryFilter module overall in tomori:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_CountryFilter_Block_Connect = AutoExecConfig_CreateConVar("tomori_countryfilter_enabled_connect", "1", "Enabled or disable CountryFilter for joining to server (0 - Disable, 1 - Enabled)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_CountryFilter_Block_CT = AutoExecConfig_CreateConVar("tomori_countryfilter_enabled_ct", "0", "Enabled or disable CountryFilter for joining ct team (0 - Disable, 1 - Enabled)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_CountryFilter_BlockMode = AutoExecConfig_CreateConVar("tomori_countryfilter_listmode", "0", "Filter ListMode (0 - Whitelist, 1 - Blacklist)", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_CountryFilter_List = AutoExecConfig_CreateConVar("tomori_countryfilter_list", "HU,RO", "List (Used like ListMode set)", 0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_CountryFilter_Enabled.SetInt(0, true, false);
}

public Action Country_JoinTeamCmd(int client, char[] command, int argc)
{
	if(EMP_IsValidClient(client) && argc > 1 && gH_Cvar_Tomori_CountryFilter_Enabled.BoolValue && gH_Cvar_Tomori_CountryFilter_Block_CT.BoolValue)
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		int toteam = StringToInt(arg);
		
		int Team = GetClientTeam(client);
		if (toteam == CS_TEAM_CT && toteam != Team)
		{
			char ip[16], code2[3];
			GetClientIP(client, ip, sizeof(ip));
			GeoipCode2(ip, code2);
			GeoipCountry(ip, country, sizeof(country));
			
			if (RejectJoin(code2))
			{
				CPrintToChat(client, "%s %t", gShadow_Tomori_ChatPrefix, "Tomori Country CT Blocked", country);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (gH_Cvar_Tomori_CountryFilter_Enabled.BoolValue && gH_Cvar_Tomori_CountryFilter_Block_Connect.BoolValue)
	{
		char ip[16], code2[3];
		GetClientIP(client, ip, sizeof(ip));
		GeoipCode2(ip, code2);
		GeoipCountry(ip, country, sizeof(country));

		if (RejectJoin(code2))
		{
			CreateTimer(0.1, cfTimer, client);
			FormatEx(rejectmsg, sizeof(maxlen), "%t", "Tomori Country Join Blocked", country);
		}
	}
	return true;
}

public bool RejectJoin(char[] code2)
{
	if (strlen(code2) == 0)
		return false;
		
	char raw_countries[255], countries[100][3];
	gH_Cvar_Tomori_CountryFilter_List.GetString(raw_countries, sizeof(raw_countries));
	int country_count = ExplodeString(raw_countries, ",", countries, 100, 3);
	
	if (country_count == 0)
		strcopy(countries[country_count++], 3, raw_countries);
		
	if(gH_Cvar_Tomori_CountryFilter_BlockMode.IntValue == 1)
	{
		for (int i = 0; i < country_count; i++)
		{
			if (strcmp(countries[i], code2) == 0)
				return true;
		}
	}
	else
	{
		bool reject = true;
		
		for (int i = 0; i < country_count; i++)
		{
			if (strcmp(countries[i], code2) == 0)
				reject = false;
		}
		
		return reject;
	}

	return false;
}

public Action cfTimer(Handle timer, any client)
{
	char rejectmsg[255];
	FormatEx(rejectmsg, sizeof(rejectmsg), "%t", "Tomori Country Join Blocked", country);
	KickClient(client, rejectmsg);
}