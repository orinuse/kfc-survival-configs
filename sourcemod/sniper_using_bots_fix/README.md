# Plugin Description
Survivor Bots with Snipers won't switch to pistols like they're using a shotgun. They are blocked from doing so until their Snipers are:
- Out of reserve ammo; This also includeS:
- - Has an empty clip.
- - Not in reloading state.<br>
This is a plugin authored by a 3rd party with no permission consulted, sereky. Read the disclaimer at the repository's main `README.md` for more info.

## Source
Original Author: sereky, cravenge
https://forums.alliedmods.net/showthread.php?p=1744063

### Changelog
__1.2_Orin2__
- Cleaned up code, like syntax issues.
- - Cleared debug messages that ruined readability and isn't as important.

__1.2_Orin1__
- #### A
- - Code rework
- - Metadata of plugin properly set up
- #### B
- - 'AskPluginLoad2()' instead of 'GetGameFolderName()' to validate the game
- - Allows bots to swap to pistols when using the 'bot_mimic' command, mini QOL
- #### C
- - '!= INVALID_ENT_REFERENCE' discarded because 'IsValidEntity()' does the same seemingly
- #### D
- - 'Event_PlayerTeam' instead of 'OnClientPutInGame'
- - Replaced GetEntData() with GetEntProp(), seemed like a leftover from ancient Sourcemod [no need to manually get offset anymore]
- - Checks for the Snipers's "m_iClip1"
- - Supports Snipers with custom ammo type
- #### E
- - Reviewed the code
- - - Also cleaned up the debugging tools
- - Removed over- -engineered code
- - - E.g. Bundled all Sniper rifle weapons into one if statement
- #### F
- - Third pass (Saw silvers's Sourcepawn scripting tutorial)
- - Improved "late load" support
- - Threw away full string comparisons in the Hook, now compares by character instead
- - Organized DEBUG code, keeping them behind for historical reasons
- - Supports Magnum now
- - Check for snipers being reloaded

### Convars

| 		  Name           		|  Default	|    Is Edit	| Description |
| -----------------------------	| --------- | -------------	| ----------- |
| l4d_sniper_bots_fix_version		| 1.2_Orin2	|	  ✖️		| 'Sniper Bots with Pistols Fix' plugin's version. |
