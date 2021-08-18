# Plugin Description
Provides Smoker with the ability to deal damage in all modes when pulling a Survivors, with more configurations.<br>
This is a plugin authored by a 3rd party with no permission consulted, SilverShot (or Silvers). Read both the disclaimer at the repository's main `README.md`, and this plugin's license in the source code for more info.

## Source
Original Author: SilverShot
https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

### Changelog
1.6_Orin2a (19-Aug-2021)
- Fixed 'l4d_tongue_damage_hurtmode' being named as 'l4d_tongue_damage_hurtmodeee'.
	
1.6_Orin2 (15-Aug-2021)
- Expanded the 'l4d_tongue_damage_hurtmode' values, mostly as compensation from forgetting about L4D1 support.
- - All damage types have been stress tested, and only the meaningful ones are kept.
- All ConVars no longer use the same function for change hooks, for mostly organization and less unnecessary memory used.	- 'z_difficulty' now has a convar hook, previously it didn't.

1.6_Orin1 (13-Aug-2021)
- Cached float values into a variable. This is for style consistency.
- Difficulty scaling configuration for tongue damage with 'l4d_tongue_damage_diffscale'; for every difficulty level the tongue damage is added together with the diffscale convar.
- Limited configuration of tongue's damage type; 3 options available.

### Convars
Commands are to be stored in `/cfg/sourcemod/l4d_tongue_control.cfg`; auto-generated on plugin start if it doesn't exist.

| 		  Name           		|  Default	|    Is Edit	| Description |
| -----------------------------	| --------- | -------------	| ----------- |
| l4d_tongue_damage_allow		|	  1		|	  ✖️		| 0=Plugin off, 1=Plugin on. |
| l4d_tongue_damage_modes		|	 N/A	|	  ✖️		| Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all). |
| l4d_tongue_damage_modes_off	|	 N/A	|	  ✖️		| Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none). |
| l4d_tongue_damage_modes_tog	|	  3		|	  ✖️		| Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together. |
| l4d_tongue_damage_base		|	 1.0	|	  ☑️		| Default damage of the tongue. |
| l4d_tongue_damage_time		|	 1.5	|	  ✖️		| How often to damage players. |
| l4d_tongue_damage_diffscale	|	 2.0	|	  ☑️		| For every new difficulty, increase the base damage by this much. |
| l4d_tongue_damage_hurtmode	|	  1		|	  ☑️		| 0 - Mimic infected claw slice. 1 - Non-incappeds mute 'sliced' sounds. 2 - Always incap players. 3 - Mode 0 + viewpunch (L4D2). 4 - Mode 1 + viewpunch (L4D2). 5 - Warn Spitter's Acid; damage is always 1, but old one is used for incaps (L4D2). |
| l4d_tongue_damage_version		| 1.6_Orin2a|	  ✖️		| Tongue Damage plugin version. |

#### Tongue Damage Chart
Glossary:<br>
`-` \- Plays `player/pz/hit/zombie_slice_*` hurt sounds on the player. It won't play if the damage would incap a survivor. In L4D1, 'punch' the survivor's view if they're not incapacitated.<br>
`*` \- Applies extra velocity to survivor's ragdolls
|                    Name 						|            Value			|  New Effects	|
| ---------------------------------------------	| ------------------------- | -------------	|
| \#0 \- `DMG_GENERIC`							|	0						| \[*MODE 0+1*\] \*\- |
| \#1 \- `DMG_CRUSH`							|	1 << 0	\- 1			| \- |
| \#2 \- `DMG_BULLET`							|	1 << 1	\- 2			| \*\- |
| \#3 \- `DMG_SLASH`							|	1 << 2	\- 4			| \*\- |
| \#4 \- `DMG_BURN`								|	1 << 3	\- 8			| Add a fire screen overlay. (first person only) |
| \#5 \- `DMG_VEHICLE`							|	1 << 4	\- 16			| \*\- |
| \#6 \- `DMG_FALL`								|	1 << 5	\- 32			| \- |
| \#7 \- `DMG_BLAST`							|	1 << 6	\- 64			| \*If `l4d_tongue_damage_base` is at least 28, apply the 'deafen' effect and ringing sound. |
| \#8 \- `DMG_CLUB`								|	1 << 7	\- 128			| \[*MODE 3+4*\] \*In L4D2, 'punch' the survivor's view if they're not incapacitated. This is the default damage type for SI claws. |
| \#9 \- `DMG_SHOCK`							|	1 << 8	\- 256			| \*\- |
| \#10 \- `DMG_SONIC`							|	1 << 9	\- 512			| \*\- |
| \#11 \- `DMG_ENERGYBEAM`						|	1 << 10	\- 1024			| \[*MODE 5*\] \*In L4D2, survivors warn about spitter acid, but the tongue will be set to 1 damage if it won't incap the survivor. |
| \#12 \- `DMG_BLAMELESS_FRIENDLY_FIRE`			|	1 << 11	\- 2048			| \- |
| \#13 \- `DMG_NEVERGIB`						|	1 << 12	\- 4096			| \*\- |
| \#14 \- `DMG_ALWAYSGIB`						|	1 << 13	\- 8192			| \*\- |
| \#15 \- `DMG_DROWN`							|	1 << 14	\- 16384		| \- |
| \#16 \- `DMG_FORCE_INCAPACITATE`				|	1 << 15	\- 32768		| \[*MODE 2*\] Forces the incapacitated state, but do note the quirks of each game. |
| \#17 \- `DMG_NERVEGAS`						|	1 << 16	\- 65536		| \- |
| \#18 \- `DMG_POISON`							|	1 << 17	\- 131072		| Mutes the 'slice' hit sounds. |
| \#19 \- `DMG_RADIATION`						|	1 << 18	\- 262144		| \- |
| \#20 \- `DMG_DROWNRECOVER`					|	1 << 19	\- 524288		| \- |
| \#21 \- `DMG_CHOKE`							|	1 << 20	\- 1048576		| \[*MODE 1+4*\] Does what `DMG_POISON` does, but additionally plays the 'neck snap' sound.|
| \#22 \- `DMG_SLOWBURN`						|	1 << 21	\- 2097152		| \- |
| \#23 \- `DMG_REMOVENORAGDOLL`					|	1 << 22	\- 4194304		| \- |
| \#24 \- `DMG_PHYSGUN`							|	1 << 23	\- 8388608		| \- |
| \#25 \- `DMG_PLASMA`							|	1 << 24	\- 16777216		| \- |
| \#26 \- `DMG_AIRBOAT`							|	1 << 25	\- 33554432		| \*\- |
| \#27 \- `DMG_DISSOLVE`						|	1 << 26	\- 67108864		| \*\- |
| \#28 \- `DMG_BLAST_SURFACE`					|	1 << 27	\- 134217728	| \*\- |
| \#29 \- `DMG_DIRECT`							|	1 << 28	\- 268435456	| \*\- |
| \#30 \- `DMG_DISMEMBER`						|	1 << 29	\- 536870912	| \*\- |
