#include <sourcemod>
#define REQUIRE_PLUGIN
#include <left4dhooks>
#undef REQUIRE_PLUGIN

#define DEBUG 0		// 1 - Show animation hooking debug; 2 - Include Jockey keyboard input debug

#define PLUGIN_VERSION "1.1a"

bool g_bAnimHooked[MAXPLAYERS+1], g_bJockeyJumping[MAXPLAYERS+1], g_bLateLoad;
ConVar g_cvBotMimic;

/*========================================================================================
	Change Log:

1.1a (31-Aug-2021)
	- Band-aid fix to 'bot_mimic' breaking the plugin
	- Metadata: Plugin URL

1.1 (11-Aug-2021)
	- Tidied up code, and removed some debug code in doing so
	- Late load support
	- Prevented being able to cancel the pounce animation by pressing "Jump" again

1.0 (11-Aug-2021)
	- Plugin release

======================================================================================*/
public Plugin myinfo = 
{
	name = "[L4D2] Jockey Pounce Animation",
	author = "Orin",
	description = "Forces Jockies to use the unused Pounce animation when in ACT_JUMP.",
	version = PLUGIN_VERSION,
	url = "https://github.com/orinuse/kfc-survival-configs/tree/main/sourcemod/scripting/l4d2_jockeypounce_anim"
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 ) 
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

// ++ Load I/O ++
// --------------
public void OnPluginStart()
{
	CreateConVar("l4d2_jockeypounce_anim_version", PLUGIN_VERSION, "\"Jockey Pounce Animation\"'s plugin version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvBotMimic = FindConVar("bot_mimic");

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_OrinClearClient);
	HookEvent("player_disconnect", Event_OrinClearClient);
	HookEvent("player_team", Event_OrinClearClient);
	HookEvent("round_end", Event_RoundEnd);

	if( g_bLateLoad )
	{
		for( int i=1; i < MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsJockey(i) )
			{
				AnimHookEnable(i, INVALID_FUNCTION, OnAnimPost);
			}
		}
	}
}
public void OnPluginEnd()
{
	for( int i=1; i < MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsJockey(i) )
		{
			AnimHookDisable(i, INVALID_FUNCTION, OnAnimPost);
		}
	}
}

// ++ Forwards ++ 
// --------------
public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	// 'bot_mimic' breaks everything
	if( !g_cvBotMimic.BoolValue && IsJockey(client) )
	{
		// Keep track of when the Jockey presses their jump button
		if( buttons & IN_JUMP )
		{
			g_bJockeyJumping[client] = (GetEntProp(client, Prop_Data, "m_nSequence") != 11);
		}
		// This instead helps the anim hooks to know the Jockey isn't airborne anymore
		else if ( g_bJockeyJumping[client] && GetEntityFlags(client) & FL_ONGROUND )
		{
			#if DEBUG > 1
			PrintToChatAll("\x05OnPlayerRunCmd: \x04Jockey Landed.");
			#endif
			g_bJockeyJumping[client] = false;
		}
	}
	return Plugin_Continue;
}

// ++ Hooks ++
// -----------
// Events 
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	// In case for some reason the player is still hooked. Probably not necessary
	if( IsJockey(client) && !g_bAnimHooked[client] )
	{
		#if DEBUG > 0
		PrintToChatAll("\x05Event_PlayerSpawn:\x04 %N [%i]", client, userid);
		#endif
		AnimHookEnable(client, INVALID_FUNCTION, OnAnimPost);
		g_bAnimHooked[client] = true;
	}
}
public void Event_OrinClearClient(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	// 'player_death' event quirk; CIs are hooked to the event so they return 0
	// We also don't need to check for hooks, `AnimHookDisable` will not do anything if there's no hook
	if( userid != 0 && IsJockey(client) )
	{
		g_bJockeyJumping[client] = false;
		#if DEBUG > 0
		PrintToChatAll("\x03Event_OrinClearClient:\x04 %N [%i]", client, userid);
		#endif
		AnimHookDisable(client, INVALID_FUNCTION, OnAnimPost);
		g_bAnimHooked[client] = false;
	}
}
// Clear all hooks and reset our "Jockey Jumping" array
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		AnimHookDisable(i, INVALID_FUNCTION, OnAnimPost);
		g_bAnimHooked[i] = false;
		g_bJockeyJumping[i] = false;
	}
}
// ---------------------
// L4DHooks - AnimHooks
// These automatically are cleared on map end, and already check if a client is valid
// Everything else must be done manually

// ACT_JOCKEY_POUNCE is not defined in C++ code! We have to use this instead
// Uses "m_nSequence" animation numbers, which are different for each model.
Action OnAnimPost(int client, int &sequence)
{
	if( sequence == 10 )
	{
		if( !g_bJockeyJumping[client] )
		{
			sequence = 11;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

// ++ Macros ++ 
// ------------
#define ZOMBIE_JOCKEY 5
bool IsJockey(int client)
{
	return client ? GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIE_JOCKEY : false;
}
