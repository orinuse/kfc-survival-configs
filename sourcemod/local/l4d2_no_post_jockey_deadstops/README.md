# Plugin Description
xes melees's shoves not being cancelled and carrying over to Jockey-ied state, causing immediate deadstops when a ride starts.<br>
This is a plugin authored by a 3rd party with a license provided; author being SirPlease (or Sir). Read both the disclaimer at the repository's main `README.md`, and this plugin's license in its source repository for more info.

## Source
Original Author: SirPlease
https://github.com/SirPlease/L4D2-Competitive-Rework

### Changelog
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
