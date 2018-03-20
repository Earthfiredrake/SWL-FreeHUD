# SWL-FreeHUD
Free floating ability markers for easier cooldown tracking

## Overview


## Installation
Any packaged release should be unzipped (including the internal folder) into the appropriate folder and the client restarted.
<br/>TSW: [TSW Directory]\Data\Gui\Customized\Flash.
<br/>SWL: [SWL Directory]\Data\Gui\Custom\Flash.

The safest method for upgrading (required for installing) is to have the client closed and delete any existing .bxml files in the Cartographer directory. Hotpatching (using /reloadui) works as long as neither Modules.xml or LoginPrefs.xml have changed.

I intend to permit setting migration from the first public beta to v1.0.x, but this may be subject to change. As with my other mods, this update compatibility window will occasionally be shifted to reduce legacy code clutter.

## Change Log

Version Initial


## Known Issues

This is an early version of this mod. There are many issues, some of them are known.
I'm always open to hearing comments and suggestions as well, easier to start with good ideas than rewrite from bad ones.

As always, defect reports, suggestions, and contributions are welcome. They can be sent to Peloprata in SWL (by mail or pm), via the github issues system, or @Peloprata in #modding on discord.

## Wishlist

+ Let GEM mode reveal hidden icons so they can be positioned without swapping slots
+ Option to hide icon when not on cooldown, and to hide cooldown clock
+ Gadget (maybe pot) cooldowns
+ Work with action swap outs (Shotgun ammo, maybe fist/ele? what other weapons behave like this?)
+ Integrate with build manager and BooBuilds(?) so that icon placement can be customized on a per build basis

## Websites

Source Repository: https://github.com/Earthfiredrake/SWL-FreeHUD

Curse Mirror: TBD

## Building from Source
Requires copies of the SWL and Scaleform CLIK APIs. Existing project files are configured for Flash Pro CS5.5.

Master/Head is the most recent packaged release. Develop/Head is usually a commit or two behind my current test build. As much as possible I try to avoid regressions or unbuildable commits but new features may be incomplete and unstable and there may be additional debug code that will be removed or disabled prior to release.

Once built, 'FreeHUD.swf' and the contents of 'config' should be copied to the directory 'FreeHUD' in the game's mod directory. '/reloadui' is sufficient to force the game to load an updated swf or mod data file, but changes to the game config files (LoginPrefs.xml and Modules.xml) will require a restart of the client and possible deletion of .bxml caches from the mod directory.

## License and Attribution
Copyright (c) 2018 Earthfiredrake<br/>
Software and source released under the MIT License

Uses the TSW-AddonUtils library and graphical elements from the UI_Tweaks mod<br/>
Both copyright (c) 2015 eltorqiro and used under the terms of the MIT License<br/>
https://github.com/eltorqiro/TSW-Utils <br/>
https://github.com/eltorqiro/TSW-UITweaks

TSW, SWL, the related API, and most graphics elements are copyright (c) 2012 Funcom GmBH<br/>
Used under the terms of the Funcom UI License<br/>


Special Thanks to:<br/>
The TSW modding community for neglecting to properly secure important intel in their faction vaults<br/>
Shivvies for the idea<br/>
Everyone who provided suggestions, testing and feedback<br/>

