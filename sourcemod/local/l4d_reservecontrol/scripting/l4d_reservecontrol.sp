#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define REQUIRE_PLUGIN
#include <dhooks>
#undef REQUIRE_PLUGIN

#define DEBUG 0
#define BEAT_THE_RUSH 1
#define GAMEDATA "l4d_reservecontrol"
#define PLUGIN_VERSION "rework-0.2"

#pragma semicolon 1
#pragma newdecls required

bool g_bL4D2, g_bLateLoad;
public Plugin myinfo = 
{
	name = "[L4D/L4D2] Reserve Control",
	author = "Orin, Psykotikism [Signatures]",
	description = "Individually control weapon reserve independant of 'ammo_*' cvars.",
	version = PLUGIN_VERSION,
	url = "[PRIVATE]"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
/*	if( engine == Engine_Left4Dead )
		g_bL4D1 = true;
	else */
	if( engine == Engine_Left4Dead2 )
		g_bL4D2 = true;
	else if( engine != Engine_Left4Dead )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

// ++ OnLoad ++ 
// ------------
StringMap g_smWeaponData;
DynamicDetour g_dynAmmoDefMaxCarry;

public void OnPluginStart()
{
	LoadGameData();
	DoReserveStringMap(g_bL4D2);
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
// View the hl2sdk (or leaks) to better kow what the functions may be doing
void LoadGameData()
{
	GameData hGameData = new GameData(GAMEDATA);
	if( !hGameData ) SetFailState("'x04Failed to find \"%s.txt\" gamedata!", GAMEDATA);

	// This: RAW
	// Params: INT [AmmoIndex], CBaseCombatCharacter const*
	// Return: INT
	g_dynAmmoDefMaxCarry = DynamicDetour.FromConf(hGameData, "CAmmoDef::MaxCarry");
	if (!g_dynAmmoDefMaxCarry)
		SetFailState("Failed to setup dhook for CAmmoDef::MaxCarry!");
	else if (!g_dynAmmoDefMaxCarry.Enable(Hook_Pre, Detour_AmmoDefMaxCarry))
		SetFailState("Failed to enable detour for CAmmoDef::MaxCarry!");

	PrintToServer("CAmmoDef::MaxCarry detoured!");
	delete hGameData;
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
			int val;
			g_smWeaponData.GetValue(sWeapon, val);

			hReturn.Value = val;
			return MRES_ChangedOverride;
		}
	}
	return MRES_Handled;
}

// -----------
// SDKHooks
public void OnSDKWeaponEquipPost(int client, int weapon)
{
	char sWeapon[24];
	GetEntityClassname(weapon, sWeapon, sizeof sWeapon);
	int iReserve = GetEntProp(weapon, Prop_Data, "m_iExtraPrimaryAmmo");
	int iConfigReserve;
	g_smWeaponData.GetValue(sWeapon, iConfigReserve);
	// to fix CAmmoDef::MaxCarry not changing max reserve if its lower than the max :L.
	if( iReserve > iConfigReserve )
		SetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo", iConfigReserve);

	#if DEBUG
	PrintToChatAll("\x01%N got %s [%i] \x05(%i --> %i reserve)", client, sWeapon, weapon, iReserve, iConfigReserve);
	#elseif BEAT_THE_RUSH
	PrintHintText(client, "%s \n(%i --> %i reserve)", sWeapon, iReserve, iConfigReserve);
	#endif
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
void DoReserveStringMap(bool is_l4d2)
{
	g_smWeaponData = new StringMap();
//	g_smWeaponData.SetValue("weapon_pistol", 65535); // irrelevant
	g_smWeaponData.SetValue("weapon_smg", 500);
	g_smWeaponData.SetValue("weapon_pumpshotgun", 64);
	g_smWeaponData.SetValue("weapon_rifle", 400);
	g_smWeaponData.SetValue("weapon_autoshotgun", 80);
	g_smWeaponData.SetValue("weapon_hunting_rifle", 120);
	if( is_l4d2 )
	{
		g_smWeaponData.SetValue("weapon_smg_silenced", 260);
		g_smWeaponData.SetValue("weapon_shotgun_chrome", 72); // 3rd longest, 21 chars
		g_smWeaponData.SetValue("weapon_rifle_desert", 400);
		g_smWeaponData.SetValue("weapon_rifle_ak47", 200);
		g_smWeaponData.SetValue("weapon_shotgun_spas", 72);
		g_smWeaponData.SetValue("weapon_sniper_military", 150); // 2nd longest, 22 chars

		g_smWeaponData.SetValue("weapon_smg_mp5", 480);
		g_smWeaponData.SetValue("weapon_rifle_sg552", 320);
		g_smWeaponData.SetValue("weapon_sniper_scout", 90);
		g_smWeaponData.SetValue("weapon_sniper_awp", 72);

		g_smWeaponData.SetValue("weapon_grenade_launcher", 30); // Longest, 23 chars
//		g_smWeaponData.SetValue("weapon_pistol_magnum", 65535); // irrelevant
//		g_smWeaponData.SetValue("weapon_rifle_m60", 120);
	}
}
stock bool IsSurvivor(int client)
{
	return GetClientTeam(client) == TEAM_SURVIVOR;
}
