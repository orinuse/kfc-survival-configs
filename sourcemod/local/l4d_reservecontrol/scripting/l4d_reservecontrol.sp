#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define REQUIRE_PLUGIN
#include <dhooks>
#undef REQUIRE_PLUGIN

#define DEBUG 0
#define GAMEDATA "l4d_reservecontrol"
#define PLUGIN_VERSION "1.0"

#pragma semicolon 1
#pragma newdecls required

bool g_bLateLoad;
public Plugin myinfo = 
{
	name = "[L4D/L4D2] Reserve Control",
	author = "Orin, Psykotikism [Signatures]",
	description = "Individually control weapon reserve independant of 'ammo_*' cvars.",
	version = PLUGIN_VERSION,
	url = "https://github.com/orinuse/kfc-survival-configs/tree/main/sourcemod/l4d_reservecontrol"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
/*	if( engine == Engine_Left4Dead )
		g_bL4D1 = true;
	else if( engine == Engine_Left4Dead2 )
		g_bL4D2 = true;
*/
	if( engine != Engine_Left4Dead && engine != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

// ++ OnLoad ++ 
// ------------
static StringMap g_smReserveData;
static DynamicDetour g_dynAmmoDefMaxCarry;

public void OnPluginStart()
{
	LoadGameData();
	LoadConfigSMC();
	CreateConVar("l4d_reservecontrol_version", PLUGIN_VERSION, "'Reserve Control' plugin's version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	HookEvent("player_team", Event_PlayerTeam);

	if( g_bLateLoad )
	{
		for( int i=1; i < MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsSurvivor(i) )
				SDKHook(i, SDKHook_WeaponEquipPost, OnSDKWeaponEquipPost);
		}
	}
}
// ------------
// GameData
void LoadGameData()
{
	GameData hGameData = new GameData(GAMEDATA);
	if( !hGameData ) SetFailState("'x04Failed to find \"%s.txt\" gamedata!", GAMEDATA);

	// This: RAW
	// Params: INT [AmmoIndex], CBaseCombatCharacter const*
	// Return: INT
	g_dynAmmoDefMaxCarry = DynamicDetour.FromConf(hGameData, "CAmmoDef::MaxCarry");
	// Which if + else if style do you prefer?
	if (!g_dynAmmoDefMaxCarry)
		SetFailState("Failed to setup dhook for CAmmoDef::MaxCarry!");
	else if (!g_dynAmmoDefMaxCarry.Enable(Hook_Post, Detour_AmmoDefMaxCarry))
		SetFailState("Failed to enable detour for CAmmoDef::MaxCarry!");

	delete hGameData;
}
// ------------
// SMCParser
// Code is based from: 'l4d_info_editor.sp'
void LoadConfigSMC()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/l4d_reservecontrol.cfg");

	if( FileExists(sPath) )
	{
		SMCParser parser = new SMCParser();
		parser.OnKeyValue = SMC_OnKeyValue;

		// Setup error logging
		char sError[128];
		int iLine, iCol;
		SMCError result = parser.ParseFile(sPath, iLine, iCol);
		if( result != SMCError_Okay )
		{
			if( parser.GetErrorString(result, sError, sizeof(sError)) )
			{
				SetFailState("CONFIG ERROR ID: #%d, %s. (line %d, column %d) [FILE: %s]", result, sError, iLine, iCol, sPath);
			}
			else
			{
				SetFailState("Unable to load config. Bad format? Check for missing { } etc.");
			}
		}

		delete parser;
		return;
	}
	SetFailState("Could not load CFG '%s'! Plugin aborted.", sPath);
}
public SMCResult SMC_OnKeyValue(Handle smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if( !g_smReserveData )
		g_smReserveData = new StringMap();

	#if DEBUG
	PrintToServer("SMC: %s and %s", key, value);
	#endif
	g_smReserveData.SetValue(key, StringToInt(value));

	// FYI: If you don't return, its this anyways
	return SMCParse_Continue;
}

// ++ Hooks ++
// -----------
// DHooks
#define MAX_INVENTORY_SLOTS 5
public MRESReturn Detour_AmmoDefMaxCarry(DHookReturn hReturn, DHookParam hParams)
{
	int ammoindex	= hParams.Get(1);
	int client		= hParams.Get(2); // Its not like NPCs with guns exist in L4D

	for( int i=0; i < MAX_INVENTORY_SLOTS; i++ )
	{
		int iWeapon = GetPlayerWeaponSlot(client, i);
		if( !IsValidEntity(iWeapon) )
			continue;

		int iPrimaryAmmoType = GetEntProp(iWeapon, Prop_Data, "m_iPrimaryAmmoType");
		if( ammoindex == iPrimaryAmmoType )
		{
			char sWeapon[32];
			GetEntityClassname(iWeapon, sWeapon, sizeof(sWeapon));
			int iConfigReserve;

			if( g_smReserveData.GetValue(sWeapon, iConfigReserve) )
			{
				hReturn.Value = iConfigReserve;
				return MRES_Override;
			}
			return MRES_Handled;
		}
	}
	return MRES_Ignored;
}
// -----------
// SDKHooks
// CAmmoDef::MaxCarry does not change max reserve if its lower than the max, :L
public void OnSDKWeaponEquipPost(int client, int weapon)
{
	char sWeapon[24];
	GetEntityClassname(weapon, sWeapon, sizeof sWeapon);
	int iReserve = GetEntProp(weapon, Prop_Data, "m_iExtraPrimaryAmmo");

	int iConfigReserve;
	if( g_smReserveData.GetValue(sWeapon, iConfigReserve) && iReserve > iConfigReserve )
	{
		SetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo", iConfigReserve);

		#if DEBUG
		PrintToChatAll("\x01%N got %s [%i] \x05(Fixed %i --> %i max reserve)", client, sWeapon, weapon, iReserve, iConfigReserve);
		#endif
	}
}

// -----------
// Events
#define TEAM_SURVIVOR 2
public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int team = event.GetInt("team");
	int client = GetClientOfUserId(event.GetInt("userid"));

	if( team == TEAM_SURVIVOR )
		SDKHook(client, SDKHook_WeaponEquipPost, OnSDKWeaponEquipPost);
	else
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnSDKWeaponEquipPost); // You don't need to check if they already have a hook!
}
// ++ Helpers ++
// -------------
bool IsSurvivor(int client)
{
	return GetClientTeam(client) == TEAM_SURVIVOR;
}
/*
// ++ KeyValues ++
// ---------------
//Not what we need! We wamt a dynamic iterable config file, and KeyValues can't do it..
void LoadKeyValues()
{
	KeyValues kvReserveData = new KeyValues("ReserveControl");
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/l4d_reservecontrol.cfg");
	if( !kvReserveData.ImportFromFile(sPath) )
	{
		delete kvReserveData;
		SetFailState("Could not load CFG '%s'! Plugin aborted.", sPath);
	}

	#if DEBUG
	char buffer[256];
	//kvReserveData.GetSectionName(buffer, sizeof(buffer)); // 'ReserveControl'
	PrintToServer("LoadConfigSMC: %s", buffer);
	#endif
	delete kvReserveData;
}
*/
