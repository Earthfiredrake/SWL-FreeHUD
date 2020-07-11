# SWL-FreeHUD
Free-floating ability icons for easier cooldown tracking

## Overview
Mirrors the active ability and gadget slots from the ability bar as individual free-floating icons that can be customized using the standard GUI edit mode (lock icon at the right end of the topbar, drag to place, scroll-wheel to resize). Abilities with no possible cooldown are hidden automatically, and the others can be set to only display when on cooldown with `/setoption efdFreeHUDHideReady true`.

Each icon links to one ability slot, layout may need adjustment between builds.

## Installation
Any packaged release should be unzipped (including the internal folder) into the appropriate folder and the client restarted.
<br/>SWL: [SWL Directory]\Data\Gui\Custom\Flash.

The safest method for upgrading (required for installing) is to have the client closed and delete any existing .bxml files in the Cartographer directory. Hotpatching (using /reloadui) works as long as none of Modules.xml, LoginPrefs.xml, or CharPrefs.xml have changed.

Upgrading should retain settings as much as possible. All settings are currently saved per character.

## Change Log
Version 0.0.3-beta
+ Hides when out of combat (can toggle with /setoption efdFreeHUDHideOutOfCombat)
+ Fixes bug where multi character hotkey codes (mostly "MB#") were being truncated when displayed

Version 0.0.2-beta
+ Additional support for Shotgun users
    + Reload options now appear when replacing any ability (even those not generally displayed)
	+ Hotkey reminders are displayed for reload options (as their replacement is semi-random)
	+ Either part can be disabled with /setoption (efdFreeHudShowSGReloads and efdFreeHudShowSGHotkeys)
+ Fixes bug where abilities were inaccurately reflecting the disabled state when first loaded

Version 0.0.1-beta
+ Initial release
+ Active ability and gadget icons
+ Customizable layout (on ability slots, one per character)
+ Option to only show running cooldowns (/setoption efdFreeHUDHideReady true)

## Known Issues

This is still an early version of this mod, so there's likely to be a few issues discovered:
+ Default layout doesn't match the ability bar (Won't fix: whole point is to rearrange them anyway)

As always, defect reports, suggestions, and contributions are welcome. They can be sent to Peloprata in SWL (by mail or pm), via the github issues system, or @Peloprata in #modding on discord.

## Wishlist

+ Option to hide when going into cooldown (opposite behaviour to HideReady)
+ Option to hide cooldown clock display
+ Pot cooldowns?
+ Work with action swap outs (Shotgun ammo, maybe fist/ele? what other weapons behave like this?)
+ Integrate with build manager and BooBuilds(?) so that icon placement can be customized on a per build basis

## Websites

Source Repository: https://github.com/Earthfiredrake/SWL-FreeHUD

Curse Mirror: https://www.curseforge.com/swlegends/tswl-mods/freehud

## Building from Source
Requires copies of the SWL and Scaleform CLIK APIs. Existing project files are configured for Flash Pro CS5.5.

Master/Head is the most recent packaged release. Develop/Head is usually a commit or two behind my current test build. As much as possible I try to avoid regressions or unbuildable commits but new features may be incomplete and unstable and there may be additional debug code that will be removed or disabled prior to release.

Once built, 'FreeHUD.swf' and the contents of 'config' should be copied to the directory 'FreeHUD' in the game's mod directory. '/reloadui' is sufficient to force the game to load an updated swf or mod data file, but changes to the game config files (*Prefs.xml and Modules.xml) will require a restart of the client and possible deletion of .bxml caches from the mod directory.

## License and Attribution
Copyright (c) 2018-2020 Earthfiredrake<br/>
Software and source released under the MIT License

Uses the TSW-AddonUtils library and graphical elements from the UI_Tweaks mod<br/>
Both copyright (c) 2015 eltorqiro and used under the terms of the MIT License<br/>
https://github.com/eltorqiro/TSW-Utils <br/>
https://github.com/eltorqiro/TSW-UITweaks

TSW, SWL, the related API, and most graphics elements are copyright (c) 2012 Funcom GmBH<br/>
Used under the terms of the Funcom UI License<br/>

Curseforge icon based off of game assets and:
https://commons.wikimedia.org/wiki/File:Simpleicons_Interface_unlocked-padlock.svg (CC Attribution 3.0)

Special Thanks to:<br/>
The usual suspects<br/>
Shivvies for the idea<br/>
Theck for pushing on the Shotgun support<br/>
Everyone who provided suggestions, testing and feedback<br/>
