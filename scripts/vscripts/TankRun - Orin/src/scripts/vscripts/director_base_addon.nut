Msg("VSCRIPT: Running director_base_addon SCRIPT TANKRUN; Orin's!\n")
// Just for readability, this weak reference doesn't actually help (and failsafe somewhat)
local DirectorOptions = DirectorOptions.weakref()

if( Director.GetGameMode() != "tankrun" )
	return false;

function AddTableToTable( dest, src )
{
	foreach( key, val in src )
	{
		dest[key] <- val
	}
}

AddTableToTable( g_ModeScript.DirectorOptions,
{
	cm_NoSurvivorBots = true,
	WaterSlowsMovement = false,

	DefaultItems =
	[
		"weapon_pistol",
		"weapon_pistol",
		"weapon_defibrillator",
		"weapon_adrenaline"
	]
	function GetDefaultItem(index)
	{
		if( index < DefaultItems.len() )
			return DefaultItems[index]
	},
	// Returning nothing is same as false
	function ConvertWeaponSpawn(classname)
	{
		if( classname == "weapon_first_aid_kit" )
			return RandomInt(0,1) == 1 ? "weapon_adrenaline" : "weapon_pain_pills";
		else if( classname == "weapon_defibrillator" )
			return "upgrade_laser_sight"
	},
	function AllowWeaponSpawn(classname)
	{
		if( classname == "weapon_first_aid_kit" || classname in DefaultItems )
			return true
	},
	function AllowFallenSurvivorItem(classname)
	{
		if( classname in DefaultItems )
			return true
	},
})

function OnGameEvent_player_death( params )
{
	printl("wassup")
	if( !params.rawin("userid") )
		return;

	local player = GetPlayerFromUserID(params.userid)
	if( player.IsSurvivor() )
	{
		EntFire("survivor_death_model", "BecomeRagdoll")
	}
}
