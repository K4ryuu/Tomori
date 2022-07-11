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

ConVar gH_Cvar_Tomori_AI_Enabled;					//Enable or disable AI Module (0 - Disable, 1 - Enabled)
ConVar gH_Cvar_Tomori_AI_AutoReply;					//Enable or disable AutoReply (0 - Disable, 1 - Enabled)
ConVar gH_Cvar_Tomori_AI_Advert_Enabled;			//Enable or disable Advertisements (0 - Disable, 1 - Enabled)
ConVar gH_Cvar_Tomori_AI_Advert_Time;				//Time between two adverts
ConVar gH_Cvar_Tomori_AI_Custom_Tag;				//Custom Tag for (Leave empty to use Tomori Chat Prefix instea od custom)

static char REPLY_PATH[PLATFORM_MAX_PATH];
static char ADVERT_PATH[PLATFORM_MAX_PATH];

char Words[100][30][512];
bool Array[100][32];
char Chats[100][1][512];

int ChatMaxCount;

public void AI_OnPluginStart()
{
	AutoExecConfig_SetFile("Module_AI", "Tomori");
	AutoExecConfig_SetCreateFile(true);

	gH_Cvar_Tomori_AI_Enabled = AutoExecConfig_CreateConVar("tomori_ai_enabled", "1", "Enable or disable AI module in tomori:", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_AI_AutoReply = AutoExecConfig_CreateConVar("tomori_ai_autoreply", "1", "Enable or disable autoreply", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_AI_Advert_Enabled = AutoExecConfig_CreateConVar("tomori_ai_advert_enabled", "1", "Enable or disable advertisements", 0, true, 0.0, true, 1.0);
	gH_Cvar_Tomori_AI_Advert_Time = AutoExecConfig_CreateConVar("tomori_ai_advert_time", "60", "Time between two adverts", 0, true, 0.0);
	gH_Cvar_Tomori_AI_Custom_Tag = AutoExecConfig_CreateConVar("tomori_ai_custom_tag", "", "Custom Tag for advertisements (Leave empty to use Tomori Chat Prefix instead of custom)", 0, true, 0.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	if (!gH_Cvar_Tomori_Enabled.BoolValue)
		gH_Cvar_Tomori_AI_Enabled.SetInt(0, true, false);

	BuildPath(Path_SM, REPLY_PATH, sizeof(REPLY_PATH), "configs/Tomori/replies.cfg");
	BuildPath(Path_SM, ADVERT_PATH, sizeof(ADVERT_PATH), "configs/Tomori/advertisements.cfg");

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	LoadWord();
	LoadAutoChatWords();
	
	CreateTimer(0.1, AutoChat);
}

public void AI_OnMapStart()
{
	LoadWord();
	LoadAutoChatWords();
}

public void LoadAutoChatWords()
{
	if (gH_Cvar_Tomori_AI_Advert_Enabled.BoolValue && gH_Cvar_Tomori_AI_Enabled.BoolValue) 
	{
		Handle DB = CreateKeyValues("Chat");
		char ChatMessege[256];
		
		FileToKeyValues(DB, ADVERT_PATH);
		KvJumpToKey(DB, "AutoChat", true);	//Start
		
		int i = 0; char IntI[8];
		while(i < 100)
		{
			IntToString(i, IntI, sizeof(IntI));
			KvGetString(DB, IntI, ChatMessege, sizeof(ChatMessege));
			ChatMaxCount = i - 1;
			if(StrEqual(ChatMessege, NULL_STRING))
				break;
				
			EMP_ProcessColors(ChatMessege, sizeof(ChatMessege));
			Chats[i][0] = ChatMessege;
			i++;
		}
		CloseHandle(DB);
	}
}

public Action AutoChat(Handle timer)
{
	if (gH_Cvar_Tomori_AI_Advert_Enabled.BoolValue && gH_Cvar_Tomori_AI_Enabled.BoolValue)
	{
		int RandomInt = GetRandomInt(2, 3);
		int client = GetRandomPlayer(RandomInt);
		
		if(client == -1)
		{
			client = GetRandomPlayer(2);
		}
		if(client == -1)
		{
			client = GetRandomPlayer(3);
		}
		
		char name[32];
		
		if(client != -1)
		{
			GetClientName(client, name, sizeof(name));
		}
		else
		{
			name = "Server is Empty now!";
		}
		
		int RandomChatNum;
		RandomChatNum = GetRandomInt(0, ChatMaxCount);
		char FinalChat[512];
		FinalChat = Chats[RandomChatNum][0];

		ReplaceFormats(FinalChat);
		EMP_ReplaceFormats(FinalChat, sizeof(FinalChat), client);

		if (StrContains(FinalChat, "{randomname}"))
		{
			ReplaceString(FinalChat, sizeof(FinalChat), "{randomname}", name);
		}

		char buffer[128];
		GetConVarString(gH_Cvar_Tomori_AI_Custom_Tag, buffer, sizeof(buffer));
		
		if (strlen(buffer) > 0)
		{
			EMP_ProcessColors(buffer, sizeof(buffer));
		}
		else
		{
			FormatEx(buffer, sizeof(buffer), gShadow_Tomori_ChatPrefix);
		}

		CPrintToChatAll("%s %s", buffer, FinalChat);
		
		int IsEnable = GetConVarInt(gH_Cvar_Tomori_AI_Advert_Time);
		
		CreateTimer(float(IsEnable), AutoChat);
	}
}

stock void ReplaceFormats(char string[512])
{
	char buffer[256];
	if (StrContains(string, "{uptime"))
	{
		int UpTime = GetTime();
		
		int Year, Month, Day, Hour, Minute, Second;
		UnixToTime(InitializeTime, Year, Month, Day, Hour, Minute, Second, UT_TIMEZONE_SERVER);
		
		int iYear, iMonth, iDay, iHour, iMinute, iSecond;
		UnixToTime(UpTime, iYear, iMonth, iDay, iHour, iMinute, iSecond, UT_TIMEZONE_SERVER);
		
		iSecond = (((iYear - Year) * 31556926) + ((iMonth - Month) * 2629743) + ((iDay - Day) * 86400) + ((iHour - Hour) * 3600) + ((iMinute - Minute) * 60) + (iSecond - Second));
		iYear 	= iSecond	/	31556926; 	iSecond = iSecond % 31556926;
		iMonth 	= iSecond	/	2629743; 	iSecond = iSecond % 2629743;
		iDay 	= iSecond	/	86400; 		iSecond = iSecond % 86400;
		iHour 	= iSecond	/	3600; 		iSecond = iSecond % 3600;
		iMinute = iSecond	/	60; 		iSecond = iSecond % 60;

		if (StrContains(string, "{uptime_year}"))
		{			
			IntToString(iYear, buffer, sizeof(buffer));
			ReplaceString(string, sizeof(string), "{uptime_year}", buffer);
		}
	
		if (StrContains(string, "{uptime_month}"))
		{			
			IntToString(iMonth, buffer, sizeof(buffer));
			ReplaceString(string, sizeof(string), "{uptime_month}", buffer);
		}
	
		if (StrContains(string, "{uptime_day}"))
		{			
			IntToString(iDay, buffer, sizeof(buffer));
			ReplaceString(string, sizeof(string), "{uptime_day}", buffer);
		}
		
		if (StrContains(string, "{uptime_hour}"))
		{			
			IntToString(iHour, buffer, sizeof(buffer));
			ReplaceString(string, sizeof(string), "{uptime_hour}", buffer);
		}
		
		if (StrContains(string, "{uptime_min}"))
		{			
			IntToString(iMinute, buffer, sizeof(buffer));
			ReplaceString(string, sizeof(string), "{uptime_min}", buffer);
		}
		
		if (StrContains(string, "{uptime_sec}"))
		{			
			IntToString(iSecond, buffer, sizeof(buffer));
			ReplaceString(string, sizeof(string), "{uptime_sec}", buffer);
		}
	}
}

stock int GetRandomPlayer(int team)
{
	int clients[MAXPLAYERS+1];
	int clientCount;
	
	for (int i = 1; i <= MaxClients; i++)
		if (EMP_IsValidClient(i, false, true, team))
			clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

public void LoadWord()
{
	if (gH_Cvar_Tomori_AI_AutoReply.BoolValue && gH_Cvar_Tomori_AI_Enabled.BoolValue)
	{
		Handle DB = CreateKeyValues("Replies");
		char equal[32], answer[256], condition[32], Stypetime[32], contains[32], action[256];
		char temp_name[32], name[32];
		char Aanswer[256], Banswer[256], Canswer[256], Danswer[256], Eanswer[256], Scount[32];
		char Aequal[32], Bequal[32], Cequal[32];
		char Acontains[32], Bcontains[32], Ccontains[32];
		char block[32], flags[64], Scooldown[32], cooldownwarn[32];
		
		int count, i = 1;
		float typetime, cooldown;
		
		FileToKeyValues(DB, REPLY_PATH);
		KvGotoFirstSubKey(DB);
		
		KvGetString(DB, "equal", equal, 32);
		KvGetString(DB, "answer", answer, 256);
		KvGetString(DB, "condition", condition, 32);
		typetime = KvGetFloat(DB, "typetime", 0.5);
		FloatToString(typetime, Stypetime, sizeof(Stypetime));
		KvGetString(DB, "contains", contains, 32);
		KvGetString(DB, "action", action, 256);
		KvGetString(DB, "answer2", Aanswer, 256);
		KvGetString(DB, "answer3", Banswer, 256);
		KvGetString(DB, "answer4", Canswer, 256);
		KvGetString(DB, "answer5", Danswer, 256);
		KvGetString(DB, "answer6", Eanswer, 256);
		KvGetString(DB, "equal2", Aequal, 32);
		KvGetString(DB, "equal3", Bequal, 32);
		KvGetString(DB, "equal4", Cequal, 32);
		KvGetString(DB, "contains2", Acontains, 32);
		KvGetString(DB, "contains3", Bcontains, 32);
		KvGetString(DB, "contains4", Ccontains, 32);
		KvGetString(DB, "block", block, 32);
		KvGetString(DB, "flags", flags, 32);
		KvGetString(DB, "cooldownwarn", cooldownwarn, 32);
		count = KvGetNum(DB, "count", 1);
		IntToString(count, Scount, sizeof(Scount));
		cooldown = KvGetFloat(DB, "cooldown", 3.0);
		FloatToString(cooldown, Scooldown, sizeof(Scooldown));
		Words[0][0] = equal;
		Words[0][1] = answer;
		Words[0][2] = condition;
		Words[0][3] = Stypetime;
		Words[0][4] = contains;
		Words[0][5] = action;
		Words[0][6] = Scount;
		Words[0][7] = Aanswer;
		Words[0][8] = Banswer;
		Words[0][9] = Canswer;
		Words[0][10] = Danswer;
		Words[0][11] = Eanswer;
		Words[0][12] = Aequal;
		Words[0][13] = Bequal;
		Words[0][14] = Cequal;
		Words[0][15] = Acontains;
		Words[0][16] = Bcontains;
		Words[0][17] = Ccontains;
		Words[0][18] = block;
		Words[0][19] = flags;
		Words[0][20] = Scooldown;
		Words[0][21] = "1";
		Words[0][22] = cooldownwarn;
		KvGetSectionName(DB, temp_name, sizeof(temp_name));
		
		while(i < 100)
		{
			KvGotoNextKey(DB);
			KvGetSectionName(DB, name, sizeof(name));
			if(StrEqual(temp_name, name))
				break;
			
			KvGetString(DB, "equal", equal, 32);
			KvGetString(DB, "answer", answer, 256);
			KvGetString(DB, "condition", condition, 32);
			typetime = KvGetFloat(DB, "typetime", 0.5);
			FloatToString(typetime, Stypetime, sizeof(Stypetime));
			KvGetString(DB, "contains", contains, 32);
			KvGetString(DB, "action", action, 256);
			KvGetString(DB, "answer2", Aanswer, 256);
			KvGetString(DB, "answer3", Banswer, 256);
			KvGetString(DB, "answer4", Canswer, 256);
			KvGetString(DB, "answer5", Danswer, 256);
			KvGetString(DB, "answer6", Eanswer, 256);
			KvGetString(DB, "equal2", Aequal, 32);
			KvGetString(DB, "equal3", Bequal, 32);
			KvGetString(DB, "equal4", Cequal, 32);
			KvGetString(DB, "contains2", Acontains, 32);
			KvGetString(DB, "contains3", Bcontains, 32);
			KvGetString(DB, "contains4", Ccontains, 32);
			KvGetString(DB, "block", block, 32);
			KvGetString(DB, "flags", flags, 32);
			KvGetString(DB, "cooldownwarn", cooldownwarn, 32);
			count = KvGetNum(DB, "count", 1);
			IntToString(count, Scount, sizeof(Scount));
			cooldown = KvGetFloat(DB, "cooldown", 3.0);
			FloatToString(cooldown, Scooldown, sizeof(Scooldown));
			Words[i][0] = equal;
			Words[i][1] = answer;
			Words[i][2] = condition;
			Words[i][3] = Stypetime;
			Words[i][4] = contains;
			Words[i][5] = action;
			Words[i][6] = Scount;
			Words[i][7] = Aanswer;
			Words[i][8] = Banswer;
			Words[i][9] = Canswer;
			Words[i][10] = Danswer;
			Words[i][11] = Eanswer;
			Words[i][12] = Aequal;
			Words[i][13] = Bequal;
			Words[i][14] = Cequal;
			Words[i][15] = Acontains;
			Words[i][16] = Bcontains;
			Words[i][17] = Ccontains;
			Words[i][18] = block;
			Words[i][19] = flags;
			Words[i][20] = Scooldown;
			Words[i][21] = "1";
			Words[i][22] = cooldownwarn;
			KvGetSectionName(DB, temp_name, sizeof(temp_name));
			i++;
		}
		CloseHandle(DB);
	}
}

public Action Command_Say(int client, int args)
{
	if (gH_Cvar_Tomori_AI_AutoReply.BoolValue && gH_Cvar_Tomori_AI_Enabled.BoolValue && !BaseComm_IsClientGagged(client))
	{
		char arg1[32], Sclient[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		IntToString(client, Sclient, sizeof(Sclient));
		
		if (StrEqual(arg1, "") || StrEqual(arg1, " "))
			return Plugin_Handled;
			
		int i = 0;
		while(i < 100)
		{
			if(!StrEqual(Words[i][0], ""))
			{
				int SWord, Iblock; 
				float typetime;
				
				SWord = StringToInt(Words[i][2]);
				typetime = StringToFloat(Words[i][3]);
				Iblock = StringToInt(Words[i][18]);
				
				if((StrEqual(arg1, Words[i][0], false) || StrEqual(arg1, Words[i][12], false) || StrEqual(arg1, Words[i][13], false) || StrEqual(arg1, Words[i][14], false)) && StrEqual(Words[i][2], NULL_STRING))
				{
					DataPack pack = new DataPack();
					CreateTimer(typetime, DelayChat, pack);
					pack.WriteCell(i);
					pack.WriteString(Sclient);
					Array[i][client] = true;
					if(Iblock == 1)
					{
						return Plugin_Handled;
					}
				}
				else if ((StrEqual(arg1, Words[i][0], false) || StrEqual(arg1, Words[i][12], false) || StrEqual(arg1, Words[i][13], false) || StrEqual(arg1, Words[i][14], false)) && !StrEqual(Words[i][2], NULL_STRING))
				{
					if(Array[SWord][client] == true)
					{
						DataPack pack = new DataPack();
						CreateTimer(typetime, DelayChat, pack);
						pack.WriteCell(i);
						pack.WriteString(Sclient);
						Array[i][client] = true;
						Array[SWord][client] = false;
						if(Iblock == 1)
						{
							return Plugin_Handled;
						}
					}
				}
			}
			i++;
		}
		
		i = 0;
		while(i < 100)
		{
			if(!StrEqual(Words[i][4], "") && !StrEqual(Words[i][15], "") && !StrEqual(Words[i][16], "") && !StrEqual(Words[i][17], ""))
			{
				int SWord, Iblock; 
				float typetime;
				
				SWord = StringToInt(Words[i][2]);
				typetime = StringToFloat(Words[i][3]);
				Iblock = StringToInt(Words[i][18]);
				
				if(((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1) || (StrContains(arg1, Words[i][16], false) != -1) || (StrContains(arg1, Words[i][17], false) != -1)) && StrEqual(Words[i][2], NULL_STRING))
				{
					DataPack pack = new DataPack();
					CreateTimer(typetime, DelayChat, pack);
					pack.WriteCell(i);
					pack.WriteString(Sclient);
					Array[i][client] = true;
					if(Iblock == 1)
					{
						return Plugin_Handled;
					}
				}
				else if (((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1) || (StrContains(arg1, Words[i][16], false) != -1) || (StrContains(arg1, Words[i][17], false) != -1)) && !StrEqual(Words[i][2], NULL_STRING))
				{
					if(Array[SWord][client] == true)
					{
						DataPack pack = new DataPack();
						CreateTimer(typetime, DelayChat, pack);
						pack.WriteCell(i);
						pack.WriteString(Sclient);
						Array[i][client] = true;
						Array[SWord][client] = false;
						if(Iblock == 1)
						{
							return Plugin_Handled;
						}
					}
				}
			}
			else if(!StrEqual(Words[i][4], "") && !StrEqual(Words[i][15], "") && !StrEqual(Words[i][16], ""))
			{
				int SWord, Iblock; 
				float typetime;
				
				SWord = StringToInt(Words[i][2]);
				typetime = StringToFloat(Words[i][3]);
				Iblock = StringToInt(Words[i][18]);
				
				if(((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1) || (StrContains(arg1, Words[i][16], false) != -1)) && StrEqual(Words[i][2], NULL_STRING))
				{
					DataPack pack = new DataPack();
					CreateTimer(typetime, DelayChat, pack);
					pack.WriteCell(i);
					pack.WriteString(Sclient);
					Array[i][client] = true;
					if(Iblock == 1)
					{
						return Plugin_Handled;
					}
				}
				else if (((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1) || (StrContains(arg1, Words[i][16], false) != -1)) && !StrEqual(Words[i][2], NULL_STRING))
				{
					if(Array[SWord][client] == true)
					{
						DataPack pack = new DataPack();
						CreateTimer(typetime, DelayChat, pack);
						pack.WriteCell(i);
						pack.WriteString(Sclient);
						Array[i][client] = true;
						Array[SWord][client] = false;
						if(Iblock == 1)
						{
							return Plugin_Handled;
						}
					}
				}
			}
			else if(!StrEqual(Words[i][4], "") && !StrEqual(Words[i][15], ""))
			{
				int SWord, Iblock; 
				float typetime;
				
				SWord = StringToInt(Words[i][2]);
				typetime = StringToFloat(Words[i][3]);
				Iblock = StringToInt(Words[i][18]);
				
				if(((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1)) && StrEqual(Words[i][2], NULL_STRING))
				{
					DataPack pack = new DataPack();
					CreateTimer(typetime, DelayChat, pack);
					pack.WriteCell(i);
					pack.WriteString(Sclient);
					Array[i][client] = true;
					if(Iblock == 1)
					{
						return Plugin_Handled;
					}
				}
				else if (((StrContains(arg1, Words[i][4], false) != -1) || (StrContains(arg1, Words[i][15], false) != -1)) && !StrEqual(Words[i][2], NULL_STRING))
				{
					if(Array[SWord][client] == true)
					{
						DataPack pack = new DataPack();
						CreateTimer(typetime, DelayChat, pack);
						pack.WriteCell(i);
						pack.WriteString(Sclient);
						Array[i][client] = true;
						Array[SWord][client] = false;
						if(Iblock == 1)
						{
							return Plugin_Handled;
						}
					}
				}
			}
			else if(!StrEqual(Words[i][4], ""))
			{
				int SWord, Iblock; 
				float typetime;
				
				SWord = StringToInt(Words[i][2]);
				typetime = StringToFloat(Words[i][3]);
				Iblock = StringToInt(Words[i][18]);
				
				if((StrContains(arg1, Words[i][4], false) != -1) && StrEqual(Words[i][2], NULL_STRING))
				{
					DataPack pack = new DataPack();
					CreateTimer(typetime, DelayChat, pack);
					pack.WriteCell(i);
					pack.WriteString(Sclient);
					Array[i][client] = true;
					if(Iblock == 1)
					{
						return Plugin_Handled;
					}
				}
				else if ((StrContains(arg1, Words[i][4], false) != -1) && !StrEqual(Words[i][2], NULL_STRING))
				{
					if(Array[SWord][client] == true)
					{
						DataPack pack = new DataPack();
						CreateTimer(typetime, DelayChat, pack);
						pack.WriteCell(i);
						pack.WriteString(Sclient);
						Array[i][client] = true;
						Array[SWord][client] = false;
						if(Iblock == 1)
						{
							return Plugin_Handled;
						}
					}
				}
			}
			i++;
		}
	}
	return Plugin_Continue;
}

public Action DelayChat(Handle timer, Handle pack)
{
	int IChatEnable, i;
	IChatEnable = GetConVarInt(gH_Cvar_Tomori_AI_AutoReply);
	ResetPack(pack);
	i = ReadPackCell(pack);
	if((IChatEnable == 1) && StrEqual(Words[i][21], "1"))
	{
		char Sclient[32], m_gzWord[512];
		int client, RandomInt, count;
		ReadPackString(pack, Sclient, sizeof(Sclient));
		client = StringToInt(Sclient);
		
		m_gzWord = Words[i][1];
		count = StringToInt(Words[i][6]);
		if(count > 1)
		{
			RandomInt = GetRandomInt(1, count);
			switch(RandomInt)
			{
				case 1 :
					m_gzWord = Words[i][1];
				case 2 :
					m_gzWord = Words[i][7];
				case 3 :
					m_gzWord = Words[i][8];
				case 4 :
					m_gzWord = Words[i][9];
				case 5 :
					m_gzWord = Words[i][10];
				case 6 :
					m_gzWord = Words[i][11];
			}
		}

		ReplaceFormats(m_gzWord);
		EMP_ReplaceFormats(m_gzWord, sizeof(m_gzWord), client);
		
		int flags = ReadFlagString(Words[i][19]);
		if(GetUserFlagBits(client) & flags == flags)
		{
			if(!StrEqual(m_gzWord, ""))
			{
				CPrintToChatAll("%s %s", gShadow_Tomori_ChatPrefix, m_gzWord);
			}
		}
		m_gzWord = Words[i][5];
		
		ReplaceFormats(m_gzWord);
		EMP_ReplaceFormats(m_gzWord, sizeof(m_gzWord), client);
		
		if(GetUserFlagBits(client) & flags == flags)
		{
			ServerCommand("%s", m_gzWord);
		}
		Words[i][21] = "0";
		float cooldown = StringToFloat(Words[i][20]);
		DataPack Spack = new DataPack();
		Spack.WriteCell(i);
		CreateTimer(cooldown, CooldownTime, Spack);
		CloseHandle(pack);
	}
	else if((IChatEnable == 1) && StrEqual(Words[i][21], "0"))
	{
		char Sclient[32], m_gzWord[512];
		int client;
		
		ReadPackString(pack, Sclient, sizeof(Sclient));
		client = StringToInt(Sclient);
		
		m_gzWord = Words[i][22];
		
		ReplaceFormats(m_gzWord);
		EMP_ReplaceFormats(m_gzWord, sizeof(m_gzWord), client);
		
		if(!StrEqual(m_gzWord, ""))
		{
			CPrintToChatAll("%s %s", gShadow_Tomori_ChatPrefix, m_gzWord);
		}
		
		CloseHandle(pack);
	}
}

public Action CooldownTime(Handle timer, Handle Spack)
{
	int i;
	ResetPack(Spack);
	i = ReadPackCell(Spack);
	Words[i][21] = "1";
	CloseHandle(Spack);
}