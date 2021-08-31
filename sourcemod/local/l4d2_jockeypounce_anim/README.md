# Plugin Description
Forces Jockies to use the unused Pounce animation when in ACT_JUMP.<br>
This plugin will break if `bot_mimic` is active, since its using `OnPlayerRunCmd` to determine if the Jockey landed. This is done to avoid using "Think" hooks.

### Changelog
1.1a (31-Aug-2021)
- Band-aid fix to 'bot_mimic' breaking the plugin
- Metadata: Plugin URL

1.1 (11-Aug-2021)
- Tidied up code, and removed some debug code in doing so
- Late load support
- Prevented being able to cancel the pounce animation by pressing "Jump" again

1.0 (Unknown)
- Plugin release (private)

## Requirements
- [Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?t=321696) \(Minimum required version: v1.06\)
