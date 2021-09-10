# Plugin Description
Made possible with ![Psykotikism's Library of L4Ds Signatures](https://github.com/Psykotikism/L4D1-2_Signatures)!

Individually control weapons's reserve counts independent of the `ammo_*` cvars. For weapon stat modders so fighting with ammo types to set reserve counts for ~~CSS Sniper~~ weapons is avoided.

## Customization
Edit the `/addons/sourcemod/data/l4d_reservecontrol.cfg` file. Example usage is provided, with also example error cases.

## Bugs
* On listen servers, weapons from the `give` command won't start with the correct reserve count, till ammo is refilled.

### Changelog
1.0a (09-Sep-2021)
- New root admin command to reload config: `sm_rc_reload`. Also has an alias, `sm_reservecontrol_reload`.

1.0 (07-Sep-2021)
- Initial release

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
