#pragma semicolon 1
#pragma newdecls required

#define DEBUG 0

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo = 
{
	name = "[L4D2] No Post-Jockeyed Shoves",
	author = "Sir; Edited by Orin",
	description = "L4D2 has a nasty bug which Survivors would exploit and this fixes that. (Holding out a melee and spamming shove, even if the jockey was behind you, would self-clear yourself after the Jockey actually landed.",
	version = "1.0_Orin1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

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
	#if DEBUG
	PrintToChatAll("\x04OnEntityShoved: %N", client);
	#endif
	return DoShoveCancelCheck(client, entity);
}

Action DoShoveCancelCheck(int client, int target)
{
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

	return GetEntProp(client, Prop_Send, "m_zombieClass") == 5;
}
bool IsJockeyed(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0;
}