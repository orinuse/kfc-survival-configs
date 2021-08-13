# Source
Original Author: SilverShot
https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers
## Changelog
1.6_Orin1 (13-Aug-2021)
	- Cached float values into a variable. This is for style consistency.
	- Difficulty scaling configuration for tongue damage with 'l4d_tongue_damage_diffscale'; for every difficulty level the tongue damage is added together with the diffscale convar.
	- Limited configuration of tongue's damage type; 3 options available.

# Plugin Description
Provides Smoker with the ability to deal damage in all modes when pulling a Survivors, with more configurations.

This is a plugin authored by a 3rd party with no permission consulted, SilverShot (or Silvers). Read the disclaimer at the repository's main README.md for more info.

## Convars
Commands are to be stored in `/cfg/sourcemod/l4d_tongue_control.cfg`; auto-generated on plugin start if it doesn't exist.

        Name           		|  Default	|  Is Orin Edit | Description |
--------------------------- | --------- | ------------- | ----------- |
l4d_tongue_damage_allow		|	  1		|				| 0=Plugin off, 1=Plugin on. |
l4d_tongue_damage_modes		|	 N/A	|				| Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).
l4d_tongue_damage_modes_off |	 N/A	|				| Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).
l4d_tongue_damage_modes_tog |	  3		|				| Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.
l4d_tongue_damage_base		|	 1.0	|		✅		| Default damage of the tongue.
l4d_tongue_damage_time		|	 1.5	|				| How often to damage players.
l4d_tongue_damage_diffscale	|	 2.0	|		✅		| For every new difficulty, increase the base damage by this much.
l4d_tongue_damage_hurtmode	|	  1		|		✅		| 0 - Mimic the infected melee attack's feedback. 1 - 'Slash' hurt sounds are muted on non-incappeds. 2 - Survivors may warn about goo when damaged during a newly recent tongue grab.
l4d_tongue_damage_version	| 1.6_Orin1	|				| Tongue Damage plugin version. |
