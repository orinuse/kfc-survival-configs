# Plugin Description
Forces Jockies to use the unused Pounce animation when in ACT_JUMP.<br>
This plugin will break if `bot_mimic` is active, since its using `OnPlayerRunCmd` to determine if the Jockey landed. This is done to avoid using "Think" hooks.

## Requirements
- [Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?t=321696) \(Minimum required version: v1.06\)