# Plugin Description
Individually control weapon reserves independant of `ammo_*` cvars. This allows ease for weapon script modders who wish to heavilly differentiate weapons that use the same ammo type from the rest, such as the Steyr Scout.

To configure reserve ammo, edit the `/addons/sourcemod/data/l4d_reservecontrol.cfg` file. Example file and example error cases are provided.

## Error Cases:
### ID #8
__"Section beginning without a matching ending."__
#### Repro Case \#1
```C
"ReserveControl"
{
	"weapon_autoshotgun" 80
```
### ID #9
__"Line contained too many invalid tokens."__
#### Repro Case \#1
```C
"ReserveControl"
{
	"weapon_smg"
	"weapon_pumpshotgun" 64
}
```
#### Repro Case \#2
```C
"ReserveControl"
{
	"weapon_smg 500
	"weapon_pumpshotgun" 64
}
```
#### Repro Case \#3
```C
"ReserveControl"
	"weapon_smg" 500
	"weapon_pumpshotgun" 64
}
```
### ID #11
__"A property was declared outside of a section."__
#### Repro Case \#1
```C
"ReserveControl"
{
	"weapon_pumpshotgun" 64
}
	"weapon_autoshotgun" 80
```
#### Repro Case \#2
```C
	"weapon_pumpshotgun" 64
	"weapon_autoshotgun" 80
```
