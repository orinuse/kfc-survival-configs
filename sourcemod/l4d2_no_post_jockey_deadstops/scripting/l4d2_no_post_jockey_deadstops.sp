#pragma semicolon 1
#pragma newdecls required

#define DEBUG 1

#include <sourcemod>
#define REQUIRE_PLUGIN
#include <left4dhooks>
#undef REQUIRE_PLUGIN

public Plugin myinfo = 
{
	name = "[L4D2] No Post-Jockeyed Shoves",
	author = "Sir; Edited by Orin",
	description = "Fixes melees's shoves not being cancelled and carrying over to Jockey-ied state, causing immediate deadstops when a ride starts.",
	version = "1.0_Orin2",
	url = "https://github.com/orinuse/kfc-survival-configs/tree/main/sourcemod/l4d2_no_post_jockey_deadstops"
};

/*========================================================================================
	Change Log:

1.0_Orin2 (31/08/2021)
	- Deleted debug messages that are no longer necessary
	- Updated the REQUIRE_PLUGIN "defines"
	- Used enums instead of define constants for teans
	-- Added ZOMBIE_JOCKEY define
	- Metedata: Plugin description and URL

1.0_Orin1 (Unknown)
	- Adjusted the syntax / style of the (helper) functions; names and contents
	-- Also added defines that act as makeshfit enums
	- Removed `L4D_OnShovedBySurvivor` forward; the extra callback isn't necessary.

======================================================================================*/

/* // too early
public Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDir[3])
{
	#if DEBUG
	PrintToChatAll("\x04OnShovedBySurvivor: %N", client);
	#endif
	return DoShoveCancelCheck(client, victim);
}
*/
public Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vecDir[3], bool bIsHighPounce)
{
	return DoShoveCancelCheck(client, entity);
}

Action DoShoveCancelCheck(int client, int target)
{
	// race condition debug; always false for 'L4D_OnShovedBySurvivor'
	#if DEBUG
	PrintToChatAll("Is %N Jockeyed? %i", client, IsJockeyed(client));
	#endif
	if (IsValidSurvivor(client) && IsValidJockey(target) && IsJockeyed(client))
	{
		#if DEBUG
		PrintToChatAll("Cancelled a shove from %N!", client);
		#endif
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// ++ 'Stocks' ++
// --------------
enum
{
	TEAM_UNDEFINED = 0,
	TEAM_SPECTATOR = 1,
	TEAM_SURVIVOR = 2,
	TEAM_INFECTED = 3
}
#define ZOMBIE_JOCKEY 5

// General Generics
bool IsValidClient(int client)
{
	// first part is for validating if its a client or a regular entity 
	return (client > 0 && client <= MaxClients) && IsClientInGame(client);
}
bool IsValidSurvivor(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}
bool IsValidInfected(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED;
}
// Jockey related
bool IsValidJockey(int client)  
{
	if (!IsValidInfected(client))
		return false;
		
	if (!IsPlayerAlive(client))
		return false;

	return GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIE_JOCKEY;
}
bool IsJockeyed(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0;
}
