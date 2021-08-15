/*
*	Tongue Damage
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#define PLUGIN_VERSION 		"1.6_Orin2"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Tongue Damage
*	Author	:	SilverShot
*	Descrp	:	Control the Smokers tongue damage when pulling a Survivor.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=318959
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.6_Orin2 (15-Aug-2021)
	- Expanded the 'l4d_tongue_damage_hurtmode' values, mostly as compensation from forgetting about L4D1 support.
	- - All damage types have been stress tested, and only the meaningful ones are kept.
	- All ConVars no longer use the same function for change hooks, for mostly organization and less unnecessary memory used.
	- 'z_difficulty' now has a convar hook, previously it didn't.

1.6_Orin1 (13-Aug-2021)
	- Cached float values into a variable. This is for style consistency.
	- Difficulty scaling configuration for tongue damage with 'l4d_tongue_damage_diffscale'; for every difficulty level the tongue damage is added together with the diffscale convar.
	- Limited configuration of tongue's damage type; 3 options available with 'l4d_tongue_damage_hurtmode'.

1.6 (21-Jul-2021)
	- Better more optimized method to prevent timer errors happening.

1.5 (20-Jul-2021)
	- Fixed rare error when clients die during a tongue drag. Thanks to "asherkin" and "Dysphie" for finding the issue.

1.4 (15-May-2020)
	- Replaced "point_hurt" entity with "SDKHooks_TakeDamage" function.

1.3 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Plugin now fixes game bug: Survivors who are pulled when not touching the ground would be stuck floating.
	- This fix is applied to all gamemodes even when the plugin has been turned off.

1.2 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.1 (29-Nov-2019)
	- Fixed invalid timer errors - Thanks to "BlackSabbarh" for reporting.

1.0 (02-Oct-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define DEBUG 0

// Some are for debugging
#define DMG_INSECT_SWARM_L4D2 			DMG_ENERGYBEAM	// custom name; survivors say spitter voice line with this
#define DMG_CHOKE 						DMG_ACID		// DMG_POISON has same effect seemingly
#define DMG_FORCE_INCAPACITATE 			DMG_PARALYZE
#if DEBUG
#define DMG_BLAMELESS_FRIENDLY_FIRE 	DMG_PREVENT_PHYSICS_FORCE
#define DMG_DISMEMBER 					DMG_BUCKSHOT
#endif

#define CVAR_FLAGS			FCVAR_NOTIFY

ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarDamageBase, g_hCvarTime, g_hCvarDamageMulti, g_hCvarDamageHurtMode, g_hCvarDifficulty;
bool g_bCvarAllow, g_bMapStarted, g_bLateLoad, g_bL4D1;
float g_fCvarDamageBase, g_fCvarTime, g_fCvarDamageMulti, g_fDamage;
int g_iCvarDamageHurtMode;
bool g_bChoking[MAXPLAYERS+1], g_bBlockReset[MAXPLAYERS+1];
Handle g_hTimers[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Tongue Damage",
	author = "SilverShot; edited by Orin",
	description = "Control the Smokers tongue damage when pulling a Survivor.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=318959"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead )
		g_bL4D1 = true;
	else if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = true;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =			CreateConVar(	"l4d_tongue_damage_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_tongue_damage_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_tongue_damage_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_tongue_damage_modes_tog",		"3",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarDamageBase =		CreateConVar(	"l4d_tongue_damage_base",			"1.0",				"Default damage of the tongue.", CVAR_FLAGS );
	g_hCvarTime =			CreateConVar(	"l4d_tongue_damage_time",			"1.5",				"How often to damage players.", CVAR_FLAGS );
	g_hCvarDamageMulti =	CreateConVar(	"l4d_tongue_damage_diffscale",		"2.0",				"For every new difficulty, increase the base damage by this much.", CVAR_FLAGS );
	char sCvarDamageHurtModeDesc[256];
	switch( g_bL4D1 )
	{
		case true:
			strcopy(sCvarDamageHurtModeDesc, sizeof(sCvarDamageHurtModeDesc), "0 - Mimic infected claw slice. 1 - Non-incappeds mute 'sliced' sounds. 2 - Always incap players.");
		case false:
			strcopy(sCvarDamageHurtModeDesc, sizeof(sCvarDamageHurtModeDesc), "0 - Mimic infected claw slice. 1 - Non-incappeds mute 'sliced' sounds. 2 - Always incap players. 3 - Mode 0 + viewpunch (L4D2). 4 - Mode 1 + viewpunch (L4D2). 5 - Warn Spitter's Acid; damage is always 1, but old one is used for incaps (L4D2).");
	}
	g_hCvarDamageHurtMode =	CreateConVar(	"l4d_tongue_damage_hurtmodeee",		"1",				sCvarDamageHurtModeDesc, CVAR_FLAGS );
	CreateConVar(							"l4d_tongue_damage_version",		PLUGIN_VERSION,		"Tongue Damage plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	if( g_bLateLoad )
	{
		char sMapName[1];
		GetCurrentMap(sMapName, sizeof(sMapName));
		g_bMapStarted = (sMapName[0] != '\0');
	}
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarDifficulty =	FindConVar("z_difficulty");
	AutoExecConfig(true, "l4d_tongue_damage");

	// == Recheck Allow ==
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);

	// == Reload Cache ==
	g_hCvarDifficulty.AddChangeHook(ConVarChanged_CacheReload);
	g_hCvarDamageBase.AddChangeHook(ConVarChanged_CacheReload);
	g_hCvarTime.AddChangeHook(ConVarChanged_CacheReload);
	g_hCvarDamageMulti.AddChangeHook(ConVarChanged_CacheReload);
	g_hCvarDamageHurtMode.AddChangeHook(ConVarChanged_CacheReload);

	HookEvent("tongue_grab",		Event_GrabStart);
#if DEBUG
	HookEvent("player_hurt",		Event_PlayerHurt);
#endif
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
	ReloadCachedValues();
}

// VSCode - Reload Convars relating to if the plugin should be toggled.
public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

// VSCode - Reload Convars relating to the Smoker's Tongue Damage plugin itself.
public void ConVarChanged_CacheReload(Handle convar, const char[] oldValue, const char[] newValue)
{
	ReloadCachedValues();
}

void ReloadCachedValues()
{
	// Creates race conditions
//	if( !g_bCvarAllow )
//		return;

	g_fCvarDamageBase = g_hCvarDamageBase.FloatValue;
	g_fCvarTime = g_hCvarTime.FloatValue;
	g_fCvarDamageMulti = g_hCvarDamageMulti.FloatValue;
	g_iCvarDamageHurtMode = g_hCvarDamageHurtMode.IntValue;

	// Needs to be a length of 2 or nothing will show up, not sure why
	char sDifficulty[2];
	g_hCvarDifficulty.GetString(sDifficulty, sizeof(sDifficulty));
	g_fDamage = GetCachedTongueDamage( DifficultyStringToID(sDifficulty) );
}

// VSCode - Check if plugin is allowed to be enabled
void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("difficulty_changed",	Event_DifficultyChanged);
		HookEvent("choke_start",		Event_ChokeStart);
		HookEvent("choke_end",			Event_ChokeStop);
		HookEvent("tongue_release",		Event_GrabStop);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("difficulty_changed",	Event_DifficultyChanged);
		UnhookEvent("choke_start",			Event_ChokeStart);
		UnhookEvent("choke_end",			Event_ChokeStop);
		UnhookEvent("tongue_release",		Event_GrabStop);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( entity != -1 )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					FUNCTION
// ====================================================================================================
void ResetPlugin()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		delete g_hTimers[i];
		g_bBlockReset[i] = false;
	}
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

public void OnClientDisconnect(int client)
{
	delete g_hTimers[client];
	g_bBlockReset[client] = false;
}

public void Event_DifficultyChanged(Event event, const char[] name, bool dontBroadcast)
{
	int newDifficulty = event.GetInt("newDifficulty");
	g_fDamage = GetCachedTongueDamage(newDifficulty);
}

public void Event_ChokeStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bChoking[client] = true;
}

public void Event_ChokeStop(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	g_bChoking[client] = false;
}

public void Event_GrabStart(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("victim");
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) )
	{
		// Fix floating bug
		if( GetEntityFlags(client) & FL_ONGROUND == 0 )
			SetEntityMoveType(client, MOVETYPE_WALK);

		// Apply damage
		if( g_bCvarAllow )
		{
			delete g_hTimers[client];
			g_hTimers[client] = CreateTimer(g_fCvarTime, TimerDamage, userid, TIMER_REPEAT);
		}
	}
}

// VSCode - Stop applying damage, and clear timers.
public void Event_GrabStop(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("victim");
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) )
	{
		// Don't kill timer if events called from timer
		if( g_bBlockReset[client] )
		{
			g_bBlockReset[client] = false;
		} else {
			delete g_hTimers[client];
		}
	}
}

// VSCode - Perform the Tongue Damage
public Action TimerDamage(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) && IsPlayerAlive(client) )
	{
		if( g_bChoking[client] )
			return Plugin_Continue;

		if( GetEntProp(client, Prop_Send, "m_isHangingFromTongue") != 1 )
		{
			int attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
			if( attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) )
			{
				// Prevent errors when clients die from HurtEntity during timer callback triggering the "tongue_release" event and delete timer.
				// Thanks to "asherkin" and "Dysphie" for finding the issue.

				// Error log:
				// Plugin "l4d_tongue_damage.smx" encountered error 23: Native detected error
				// Invalid timer handle e745136f (error 1) during timer end, displayed function is timer callback, not the stack trace
				// Unable to call function "TimerDamage" due to above error(s).

				g_bBlockReset[client] = true;
				int damagetype;
				switch( g_iCvarDamageHurtMode )
				{
				#if !DEBUG
					case 0: damagetype = DMG_SLASH;
					case 1: damagetype = !(GetEntProp(client, Prop_Send, "m_isIncapacitated")) ? DMG_CHOKE : DMG_SLASH;
					case 2: damagetype = DMG_FORCE_INCAPACITATE;
					case 3: damagetype = DMG_CLUB;
					case 4: damagetype = !(GetEntProp(client, Prop_Send, "m_isIncapacitated")) ? DMG_CHOKE : DMG_CLUB;
					case 5: damagetype = DMG_INSECT_SWARM_L4D2;
					default: damagetype = DMG_CHOKE;
				#else
					case 0: damagetype = DMG_GENERIC;
					case 1: damagetype = DMG_CRUSH;
					case 2: damagetype = DMG_BULLET;
					case 3: damagetype = DMG_SLASH;
					case 4: damagetype = DMG_BURN;
					case 5: damagetype = DMG_VEHICLE;
					case 6: damagetype = DMG_FALL;
					case 7: damagetype = DMG_BLAST;
					case 8: damagetype = DMG_CLUB;
					case 9: damagetype = DMG_SHOCK;
					case 10: damagetype = DMG_SONIC;
					case 11: damagetype = DMG_INSECT_SWARM_L4D2; // DMG_ENERGYBEAM
					case 12: damagetype = DMG_BLAMELESS_FRIENDLY_FIRE; // DMG_PREVENT_PHYSICS_FORCE
					case 13: damagetype = DMG_NEVERGIB;
					case 14: damagetype = DMG_ALWAYSGIB;
					case 15: damagetype = DMG_DROWN;
					case 16: damagetype = DMG_FORCE_INCAPACITATE;
					case 17: damagetype = DMG_NERVEGAS;
					case 18: damagetype = DMG_POISON;
					case 19: damagetype = DMG_RADIATION;
					case 20: damagetype = DMG_DROWNRECOVER;
					case 21: damagetype = DMG_CHOKE; // DMG_ACID
					case 22: damagetype = DMG_SLOWBURN;
					case 23: damagetype = DMG_REMOVENORAGDOLL;
					case 24: damagetype = DMG_PHYSGUN;
					case 25: damagetype = DMG_PLASMA;
					case 26: damagetype = DMG_AIRBOAT;
					case 27: damagetype = DMG_DISSOLVE;
					case 28: damagetype = DMG_BLAST_SURFACE;
					case 29: damagetype = DMG_DIRECT;
					case 30: damagetype = DMG_DISMEMBER; // DMG_BUCKSHOT
					default: damagetype = DMG_CHOKE;
				#endif
				}
				HurtEntity(client, attacker, g_fDamage, damagetype);
				if( g_bBlockReset[client] == false )
				{
					g_hTimers[client] = null;
					return Plugin_Stop;
				}

				g_bBlockReset[client] = false;
				return Plugin_Continue;
			}
		}
	}

	g_hTimers[client] = null;
	return Plugin_Stop;
}

#if DEBUG
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int type = event.GetInt("type");
	PrintHintTextToAll("Recent Damage type is #%i", type);
}
#endif

void HurtEntity(int victim, int client, float damage, int damagetype = DMG_SLASH)
{
	SDKHooks_TakeDamage(victim, client, client, damage, damagetype);
}

int DifficultyStringToID(const char[] diffname)
{
	int iDifficulty = -1;
	switch ( CharToLower(diffname[0]) )
	{
		case 'e': iDifficulty = 0; // easy
		case 'n': iDifficulty = 1; // medium
		case 'h': iDifficulty = 2; // hard
		case 'i': iDifficulty = 3; // impossible
	}
	return iDifficulty;
}

float GetCachedTongueDamage(int difficulty)
{
	float fTotalDamage = g_fCvarDamageBase;
	for ( int i=0; i < difficulty; i++ )
	{
		fTotalDamage += g_fCvarDamageMulti;
	}
	return fTotalDamage;
}
