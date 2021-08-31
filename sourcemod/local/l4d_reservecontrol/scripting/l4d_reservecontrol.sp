#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define REQUIRE_PLUGIN
#include <dhooks>
#undef REQUIRE_PLUGIN

#define DEBUG 2
#define MISSING_AMMO_NOTIFS 1
#define PLUGIN_VERSION "rework-0.1"
#define GAMEDATA "l4d_reservecontrol"

#define TEAM_SURVIVOR 2

#pragma semicolon 1
#pragma newdecls required

bool g_bLateLoad, g_bL4D2;
//bool g_bL4D1 = false;

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
StringMap g_smWeaponData = null;
ConVar g_cvAmmoMaxItems, g_cvAmmoItemDump = null;
Handle g_hSDKCall_GetMaxClip1, g_hSDKCall_AmmoDefMaxCarry = null;
bool g_bAmmoItemDump = false;
int g_iAmmoMaxItems = -1;

// bool g_bInTransition[MAXPLAYERS+1] = false; // come back to this after we're done with a rework

public void OnPluginStart()
{
	LoadGameData();
	DoReserveStringMap(g_bL4D2);

	CreateConVar("l4d_reservecontrol_version", PLUGIN_VERSION, "'Reserve Control' plugin's version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	g_cvAmmoItemDump = CreateConVar("l4d_reservecontrol_ammopiles_dumpitems", "0", "If non-zero, display what indexes do the weapons reside in.", FCVAR_DONTRECORD);
	g_cvAmmoMaxItems = CreateConVar("l4d_reservecontrol_ammopiles_maxitems", "6", "How many items do we assume players can carry at once? DON'T TOUCH UNLESS YOU KNOW WHAT IT DOES.", FCVAR_DONTRECORD);
	g_cvAmmoMaxItems.AddChangeHook(CVChange_CacheAll);
	g_cvAmmoItemDump.AddChangeHook(CVChange_CacheAll);

	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("item_pickup", Event_ItemPickup);

	if( g_bLateLoad )
	{
		// Hook Ammo with OnUsePost
		for( int entity; (entity = FindEntityByClassname(entity, "weapon_ammo_spawn")) != INVALID_ENT_REFERENCE; )
		{		
			SDKHook(entity, SDKHook_Use, OnSDKUseAmmoPile);
		}
		for( int i=1; i < MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsSurvivor(i) )
			{
				SDKHook(i, SDKHook_WeaponEquipPost, OnSDKWeaponEquipPost);
			//	SDKHook(i, SDKHook_ReloadPost, OnSDKReloadPost); // not supported in L4D1
			}
		}
	}
}
// View the hl2sdk (or leaks) to better kow what the functions may be doing
void LoadGameData()
{
	GameData hGameData = new GameData(GAMEDATA);
	if( hGameData == null ) SetFailState("'x04Failed to find \"%s.txt\" gamedata!", GAMEDATA);

	// This: ENTITY
	// Params: N/A
	// Return: INT
	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseCombatWeapon::GetMaxClip1") )
	{
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDKCall_GetMaxClip1 = EndPrepSDKCall();
		if( !g_hSDKCall_GetMaxClip1 ) {
			LogError("Can't create SDKCall: 'CBaseCombatWeapon::GetMaxClip1'");
		}
	} else {
		LogError("Can't find signature: 'CBaseCombatWeapon::GetMaxClip1'");
	}

	// This: RAW
	// Params: INT [AmmoIndex], CBaseCombatCharacter const*
	// Return: INT
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CAmmoDef::MaxCarry") )
	{
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDKCall_AmmoDefMaxCarry = EndPrepSDKCall();
		if( !g_hSDKCall_AmmoDefMaxCarry ) {
			LogError("Can't create SDKCall: 'CAmmoDef::MaxCarry'");
		}
	} else {
		LogError("Can't find signature: 'CAmmoDef::MaxCarry'");
	}
		
	delete hGameData;
}
void DoReserveStringMap(bool is_l4d2)
{
	g_smWeaponData = new StringMap();

//	++ Defaults ++
//	--------------
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

// ++ Forwards ++ 
// --------------
public void OnEntityCreated(int entity, const char[] classname)
{
	if( strlen(classname) > 12 )
	{
		if( classname[8] == 'm' && classname[11] == '_' )
			SDKHook(entity, SDKHook_Use, OnSDKUseAmmoPile);
	}
}

// ++ Hooks ++ 
// -----------
// ===========
// -----------
// Events
public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	//PrintToChatAll("IsSurvivor: %i", IsSurvivor(client)); // this returns 0 even on post hooks
	int team = event.GetInt("team");
	int client = GetClientOfUserId(event.GetInt("userid"));

	if( team == TEAM_SURVIVOR )
		SDKHook(client, SDKHook_WeaponEquipPost, OnSDKWeaponEquipPost);
	else
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnSDKWeaponEquipPost); // You don't need to check if they already have a hook!
}
/* == STRING CHART ==
** Tested on 'https://spider.limetech.io/'
	weapon_smg_x == 11 chars
	weapon_rifle_x == 13 chars
	weapon_sniper_x == 14 chars
	weapon_pistol_x == 14 chars
	weapon_shotgun_x == 15 chars
	
	weapon_smg_mp5 == 13 chars
	weapon_smg_sil == 13 chars
	
	weapon_rifle_a == 13 chars
	weapon_rifle_d == 13 chars
	weapon_rifle_s == 13 chars
	weapon_rifle_m == 13 chars
	
	weapon_sniper_a == 14 chars
	weapon_sniper_m == 14 chars
	weapon_sniper_s == 14 chars
	
	weapon_shotgun_c == 15 chars
	weapon_shotgun_s == 15 chars

	weapon_autosho == 13 chars
	weapon_pumpsho == 13 chars
	weapon_hunting_r == 15 chars
	weapon_grenade_l == 15 chars
**
*/
public void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	char item[16];
	event.GetString("item", item, sizeof(item));
	Format(item, sizeof(item), "weapon_%s", item); // doesn't have the 'weapon_' prefix so
	#if DEBUG > 1
	PrintHintText(client, "len of %i: %s", strlen(item), item);
	#endif

	for( int i=0; i < g_iAmmoMaxItems; i++ )
	{
		int iWeapon = GetEntPropEnt(client, Prop_Data, "m_hMyWeapons", i);
		if( IsValidEntity(iWeapon) )
		{
			char sWeapon[16];
			GetEntityClassname(iWeapon, sWeapon, sizeof(sWeapon));
			int iIndex = BestWeaponStringIndex(sWeapon);
			#if DEBUG > 1
			PrintToChatAll("Index: %i; String cmp: %i, %i", iIndex, (sWeapon[9] == item[9]), (sWeapon[iIndex] == item[iIndex]) );
			#endif

			if( iIndex > 0 && (sWeapon[9] == item[9] && sWeapon[iIndex] == item[iIndex]) )
			{
				DataPack pack = new DataPack();
				pack.WriteCell(client);
				pack.WriteCell(iWeapon);
				pack.WriteCell(false);
				pack.WriteCell(-1);
				RequestFrame(DoRefillWeaponReserve, pack);
				break;
			}
		}
	}
}
// -----------
// SDKHooks
// - Players -
public void OnSDKWeaponEquipPost(int client, int weapon)
{
	char sWeapon[24];
	GetEntityClassname(weapon, sWeapon, sizeof sWeapon);
	int iReserve = GetEntProp(weapon, Prop_Data, "m_iExtraPrimaryAmmo");
	#if DEBUG > 0
	PrintToChatAll("\x01%N got %s [%i] \x05(%i reserve)", client, sWeapon, weapon, iReserve);
	PrintToChatAll("SDKCall: %i", SDKCall(g_hSDKCall_AmmoDefMaxCarry, weapon, client) );
	#endif

	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(weapon);
	pack.WriteCell(true);
	pack.WriteCell(iReserve);
	RequestFrame(DoRefillWeaponReserve, pack);
}
// - Ammo -
public Action OnSDKUseAmmoPile(int entity, int activator, int caller, UseType type, float value)
{
	bool bForceCancelInput = false;
	bool bFullWeaponFound = true;
	for( int i=0; i < g_iAmmoMaxItems; i++ )
	{
		int iWeapon = GetEntPropEnt(activator, Prop_Data, "m_hMyWeapons", i);
		bool bInvalidWeapon = true;	
		char sWeapon[24];
		if( IsValidEntity(iWeapon) )
		{
			bInvalidWeapon = false;
			int iAmmoType = GetEntProp(iWeapon, Prop_Data, "m_iPrimaryAmmoType");
			if( IsValidAmmoType(iAmmoType) )
			{
				int iAmmoMax = 0;
				int iAmmoCount = GetEntProp(activator, Prop_Data, "m_iAmmo", 4, iAmmoType);
				int iClip = GetEntProp(iWeapon, Prop_Data, "m_iClip1");
				int iMaxClip = SDKCall(g_hSDKCall_GetMaxClip1, iWeapon); // Psykotikism thank you for your github repo!!!!!! I can have fun trying out SDKCalls

				GetEntityClassname(iWeapon, sWeapon, sizeof(sWeapon));
				g_smWeaponData.GetValue(sWeapon, iAmmoMax);
				if( iAmmoCount != iAmmoMax || iClip != iMaxClip )
				{
					DataPack pack = new DataPack();
					pack.WriteCell(activator);
					pack.WriteCell(iWeapon);
					pack.WriteCell(false);
					pack.WriteCell(-1);
					RequestFrame(DoRefillWeaponReserve, pack);
				}
				else
					bForceCancelInput = true;

				bFullWeaponFound = true;
			}
		}
		if( g_bAmmoItemDump )
		{
			char sName[24];
			GetClientName(activator, sName, sizeof(sName));
			strcopy(sWeapon, 7, "<NULL>"); // this goes here otherwise its ugly

			if( !bInvalidWeapon ) 
				GetEntityClassname(iWeapon, sWeapon, sizeof(sWeapon));
				
			PrintToChatAll("\x01{%s} \x04#%i \x01is \x05%s", sName, i, sWeapon);
		}
	}
	if( !bFullWeaponFound || bForceCancelInput )
		return Plugin_Handled;
	
	return Plugin_Continue;
}
// -----------
// ConVars
public void CVChange_CacheAll(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bAmmoItemDump = g_cvAmmoItemDump.BoolValue;
	g_iAmmoMaxItems = g_cvAmmoMaxItems.IntValue;
}

// ++ Stocks ++ 
// ------------
// ============
// ------------
// "Macros"
stock bool IsValidAmmoType(int ammotype)
{
	return ammotype > 0 && ammotype < 32; // 32 == GetEntPropArraySize(client, Prop_Data, "m_iAmmo")
}
stock bool IsSurvivor(int client)
{
	return GetClientTeam(client) == TEAM_SURVIVOR;
}
stock int BestWeaponStringIndex(const char[] classname)
{
	int iIndex = -1;
	switch( classname[9] )
	{
		// PUMPSHOTGUN, AUTOSHOTGUN
		case 'm','t':
			iIndex = 9;

		// SMG, RIFLE
		// 1st - '\0', 'l', '5'
		// 2nd - '\0', 'a', 'd', 's', 'm'
		case 'g','f':
			iIndex = 13;

		// SNIPER, PISTOL
		// 1st - 'a', 's', 'm'
		case 'i','s':
			iIndex = 14;

		// H.RIFLE, SHOTGUNS [L4D2], G.LAUNCHER
		// 2nd - 'c', 's'
		case 'n','o','e':
			iIndex = 15;
	}
	return iIndex;
}
// ------------
// Ammo
stock void DoRefillWeaponReserve(DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int iWeapon = pack.ReadCell();
	/* ******* {}Exception cases{} *******
	// #1 - 'director_solo_mode'
	// #2 - Happens with the regular pistols
	// mostly when they transform into dualies
	*********************************** */
	if( IsClientInGame(client) && IsValidEntity(iWeapon) )
	{
		bool clamponly = pack.ReadCell();
		int forcecount = pack.ReadCell();
		RefillWeaponReserve(client, iWeapon, clamponly, forcecount);
	}
	#if DEBUG > 1
	else
		PrintToChatAll("\x01IsClientInGame: \x05%i, IsValidEntity: \x05%i", IsClientInGame(client), IsValidEntity(iWeapon));
	#endif
	delete pack;
}
// Non-'RequestFrame' variant
stock void RefillWeaponReserve(int client, int weapon, bool clamponly, int forcecount)
{
	int iAmmoType = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
	if( !IsValidAmmoType(iAmmoType) ) // Things like SI claws have "-1" ammo type!
		return;

	int iAmmoCount = GetEntProp(client, Prop_Data, "m_iAmmo", 4, iAmmoType);
	if( forcecount > 0 ) // Don't need anything else if this is active
	{
		#if DEBUG > 0
		char sWeapon[24];
		GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
		if( iAmmoCount != forcecount )
			PrintToChatAll("\x05FORCE: \x03%i \x05--> \x03%i\x01. [%s]", iAmmoCount, forcecount, sWeapon);
		#endif
		SetEntProp(client, Prop_Send, "m_iAmmo", forcecount, 4, iAmmoType);
		return;
	}
	else
	{
		char sWeapon[24];
		GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
		int iAmmoMax = 0;
		g_smWeaponData.GetValue(sWeapon, iAmmoMax);

		// Check for clamping, and if so, check if current ammo is less than max before we clamp.
		if( iAmmoMax > 0 && !(clamponly && iAmmoCount <= iAmmoMax) )
		{
			#if DEBUG > 0
			PrintToChatAll("\x05Reserve: \x03%i \x05--> \x03%i\x01. [%s]", iAmmoCount, iAmmoMax, sWeapon);
			#elseif defined MISSING_AMMO_NOTIFS
			PrintCenterText(client, "\x05Reserve: \x03%i \x05--> \x03%i\x01. [%s]", iAmmoCount, iAmmoMax, sWeapon);
			#endif
			// All good so set the ammo to the max
			iAmmoCount = iAmmoMax;
			int iMaxClip = SDKCall(g_hSDKCall_GetMaxClip1, weapon);
			int iClip = GetEntProp(weapon, Prop_Data, "m_iClip1"); // For things like shotguns, again a datamap will do for this

			if( iClip < iMaxClip )
			{
				int iExtraClip = iMaxClip - iClip;
				iAmmoCount += iExtraClip;
				#if DEBUG > 0 || defined MISSING_AMMO_NOTIFS
				PrintHintText(client, "\x01Extra \x03%i \x01reserve!", iExtraClip);
				#endif
			}
			SetEntProp(client, Prop_Send, "m_iAmmo", iAmmoCount, 4, iAmmoType);
		}
	}
}
