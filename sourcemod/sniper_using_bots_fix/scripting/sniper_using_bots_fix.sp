#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define	TEAM_SURVIVOR	2
#define	SLOT_PRIMARY	0

#define DEBUG 0
#define PLUGIN_VERSION "1.2_Orin2"

#pragma tabsize 4
#pragma semicolon 1
#pragma newdecls required

bool g_bLateLoad = false;
ConVar g_cvBotMimic = null;

#if DEBUG
bool g_bAmmoNoticePrinted[MAXPLAYERS + 1];
#endif

/*
==== Stable changes up until now for '1.2_Orin2' ====
// 1.2_Orin2
// - Cleaned up code, like syntax issues
// - - Cleared debug messages that ruined readability and isn't as important

==== Stable changes up until now for '1.2_Orin1' ====
// 1.2_Orin1
// A
// - Code rework
// - Metadata of plugin properly set up
// B
// - 'AskPluginLoad2()' instead of 'GetGameFolderName()' to validate the game
// - Allows bots to swap to pistols when using the 'bot_mimic' command, mini QOL
// C
// - '!= INVALID_ENT_REFERENCE' discarded because 'IsValidEntity()' does the same seemingly
// D
// - 'Event_PlayerTeam' instead of 'OnClientPutInGame'
// - Replaced GetEntData() with GetEntProp(), seemed like a leftover from ancient Sourcemod [no need to manually get offset anymore]
// - Checks for the Snipers's "m_iClip1"
// - Supports Snipers with custom ammo type
// E
// - Reviewed the code
// -- Also cleaned up the debugging tools
// - Removed over-engineered code
// -- E.g. Bundled all Sniper rifle weapons into one if statement
// F
// - Third pass (Saw silvers's Sourcepawn scripting tutorial)
// - Improved "late load" support
// - Threw away full string comparisons in the Hook, now compares by character instead
// - Organized DEBUG code, keeping them behind for historical reasons
// - Supports Magnum now
// - Check for snipers being reloaded
==============================================
*/

public Plugin myinfo = 
{
	name = "[L4D/L4D2] Sniper Bots with Pistols Fix",
	author = "sereky; Edited by cravenge & Orin",
	description = "Survivor Bots with Snipers won't switch to pistols.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1744063"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if( engine != Engine_Left4Dead && engine != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_sniper_bots_fix_version", PLUGIN_VERSION, "'Sniper Bots with Pistols Fix' plugin's version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	g_cvBotMimic = FindConVar("bot_mimic");	
	HookEvent("player_team", Event_PlayerTeam);

	if( g_bLateLoad )
	{
		// 0 is always invalid
		for( int i=1; i < MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsFakeClient(i) && IsSurvivor(i) )
				SDKHook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
		}
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	// Can't use IsSurvivor() for this I'm assuming, VScript has post gamevent hooks yet prints the survivor is NOT in survivor team yet
	// I'm assuming it'll be the same case here
	int team = event.GetInt("team");
	if( team == TEAM_SURVIVOR )
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
//		PrintToChatAll("IsSurvivor: %i", IsSurvivor(client)); // this returns 0
		if( IsFakeClient(client) )
			SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	}
}

public Action OnWeaponSwitch(int client, int weapon)
{
	// Odd cases
	//// 1st is well, bot_mimic
	//// 2nd is because bots can force slot switching even if the weapon doesn't exist
	if ( g_cvBotMimic.BoolValue || !IsValidEntity(weapon) )
		return Plugin_Continue;
	
	if ( !IsSurvivor(client) || IsIncapacitated(client) )
		return Plugin_Continue;
	
	char sClassname[24];
	GetEntityClassname(weapon, sClassname, sizeof(sClassname));

	// weapon_pisto[l], weapon_pisto[l]_magnum
	if ( sClassname[12] == 'l' )
	{
		int iPrimary = GetPlayerWeaponSlot(client, SLOT_PRIMARY);
		if( IsValidEntity(iPrimary) )
		{
			char sPrimary[24];
			GetEntityClassname(iPrimary, sPrimary, sizeof(sPrimary));

			// weapon_hunti[n]g, weapon_snipe[r]
			if ( sPrimary[12] == 'n' || sPrimary[12] == 'r' )
			{
				// Mods can change the ammo type, and that changes how we'll need to fetch the ammo count
				// Yes, this is how you check a weapon's ammo capacity.. Feels like it was for a different game.. isn't it
				int iSniperClip = GetEntProp(iPrimary, Prop_Send, "m_iClip1"); // Clip might also have ammo, need to check that
				int iSniperAmmoType = GetEntProp(iPrimary, Prop_Send, "m_iPrimaryAmmoType");
				bool bSniperHasReserve = (GetEntProp(client, Prop_Send, "m_iAmmo", 4, iSniperAmmoType) > 0);
				bool bSniperReloading = (GetEntProp(iPrimary, Prop_Send, "m_bInReload") == 1);

				#if DEBUG
				char sName[32];			
				GetClientName(client, sName, sizeof(sName));
				if( !g_bAmmoNoticePrinted[client] )
				{
					char sHasReserve[7];
					char sReloading[6];
					bSniperHasReserve ? strcopy(sHasReserve, sizeof(sHasReserve), "active") : strcopy(sHasReserve, sizeof(sHasReserve), "empty");
					bSniperReloading ? strcopy(sReloading, sizeof(sReloading), "true") : strcopy(sReloading, sizeof(sReloading), "false");

					PrintToChatAll("\x04%s's %s has \x03%i \x04clip. Ammo reserve is \x05%s\x04. Reloading: \x05%s", sName, sPrimary, iSniperClip, sHasReserve, sReloading);
					g_bAmmoNoticePrinted[client] = true;
				}
				#endif
				if( bSniperHasReserve || iSniperClip > 0 || bSniperReloading )
					return Plugin_Handled;

				return Plugin_Continue;
			}
		}
	}
#if DEBUG
	g_bAmmoNoticePrinted[client] = false;
#endif
	return Plugin_Continue;
}

stock bool IsSurvivor(int client)
{
	return GetClientTeam(client) == TEAM_SURVIVOR;
}
stock bool IsIncapacitated(int client)
{
	// testing this "int to bool" trick
	//// Is expression true, then is the opposite of it true, THEN is the opposite-opposite of it true?
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated");
}