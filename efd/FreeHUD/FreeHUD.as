// Copyright 2018-2020, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-FreeHUD

import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Shortcut;
import com.GameInterface.Game.ShortcutData;
import com.GameInterface.Inventory;
import com.GameInterface.Utils;
import com.Utils.GlobalSignal;
import com.Utils.ID32;

import efd.FreeHUD.lib.Mod;
import efd.FreeHUD.lib.sys.ConfigManager;

// TODOS: New features and requests
//   Config window
//   Better handling of gimick abililites
//   Wings, Health Pots, Dodge, Belt, Repair?
//   Hide default interface

class efd.FreeHUD.FreeHUD extends Mod {
	private function GetModInfo():Object {
		return {
			// Debug flag at top so that commenting out leaves no hanging ','
			// Debug : true,
			Name : "FreeHUD",
			Version : "0.0.3.beta",
			Subsystems : {
				Config : {
					Init : ConfigManager.Create
				/*},
				Icon : {
					Init : ModIcon.Create,
					InitObj : {
						// LeftMouseInfo : IconMouse_ToggleConfigWindow,
						// RightMouseInfo : IconMouse_ToggleUserEnabled
					}
				},
				LinkVTIO : {
					Init : VTIOHelper.Create,
					InitObj : {
						// ConfigDV : "efdShowFreeHUDConfigWindow"
					}*/
				}
			}
		};
	}

	public function FreeHUD(hostMovie:MovieClip) {
		super(GetModInfo(), hostMovie);
		Config.NewSetting("CooldownLayout", GetDefaultLayout());
		Config.NewSetting("HideReady", false);
		Config.NewSetting("HideOutOfCombat", true);
		Config.NewSetting("ShowSGReloads", true);
		Config.NewSetting("ShowSGHotkeys", true);

		Equipment = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, Character.GetClientCharID().GetInstance()));
		
		CooldownWrapper = HostClip.createEmptyMovieClip("CooldownWrapper", HostClip.getNextHighestDepth());
	}

	private function Activate():Void {
		if (!CooldownViews) {
			CooldownViews = new Array;
			var layoutSettings:Array = Config.GetValue("CooldownLayout");
			for (var i:Number = 0; i < CooldownCount; ++i) {
				var layout:Object = layoutSettings[i];
				var cooldown:MovieClip = CooldownWrapper.attachMovie("efdFreeHUDGeneralCooldown", "CooldownDisplay" + i, CooldownWrapper.getNextHighestDepth(),
					{_x : layout.x, _y : layout.y, _xscale : layout.scale, _yscale : layout.scale, _alpha : layout.alpha,
					 SlotID : (i == GadgetIndex ? 0 : i + AbilityOffset),
					 HideReady : Config.GetValue("HideReady"),
					 HideOutOfCombat : Config.GetValue("HideOutOfCombat"),
					 ShowSGReloads :Config.GetValue("ShowSGReloads"),
					 ShowSGHotkeys : Config.GetValue("ShowSGHotkeys")});
				cooldown.ChangeAbility(i < AbilityCount ?
					Shortcut.m_ShortcutList[i + AbilityOffset] :
					Equipment.GetItemAt(_global.Enums.ItemEquipLocation.e_Aegis_Talisman_1));
				CooldownViews.push(cooldown);
			}
			LoadHotkeys();
		}		
		Shortcut.SignalShortcutAdded.Connect(AbilityChanged, this);
		Shortcut.SignalShortcutRemoved.Connect(AbilityChanged, this);
		Shortcut.SignalShortcutMoved.Connect(AbilityMoved, this);
		Shortcut.SignalShortcutEnabled.Connect(EnableAbility, this);
		Shortcut.SignalCooldownTime.Connect(AbilityCooldown, this);
		Shortcut.SignalSwapShortcut.Connect(AbilityChanged, this); //Shotgun reloads

		Equipment.SignalItemAdded.Connect(ItemChanged, this);
		Equipment.SignalItemLoaded.Connect(ItemChanged, this);
		Equipment.SignalItemRemoved.Connect(ItemChanged, this);
		Equipment.SignalItemCooldown.Connect(ItemCooldown, this);
		Equipment.SignalItemCooldownRemoved.Connect(ItemCooldown, this);
		
		Shortcut.SignalHotkeyChanged.Connect(LoadHotkeys, this);
	}

	private function Deactivate():Void {
		var layout = new Array();
		for (var i:Number = 0; i < CooldownCount; ++i) {
			var clip:MovieClip = CooldownViews[i];
			layout.push({x : clip._x, y : clip._y, scale : clip._xscale, alpha : clip._alpha});
		}
		Config.SetValue("CooldownLayout", layout);
	}

	private function LoadComplete():Void {
		// TODO: Setting DVs are frequently used, see about adding feature into lib.Config
		HideReadyDV = DistributedValue.Create(DVPrefix + ModName + "HideReady");
		HideReadyDV.SetValue(Config.GetValue("HideReady"));
		HideReadyDV.SignalChanged.Connect(HideReadyChanged, this);
		HideOutOfCombatDV = DistributedValue.Create(DVPrefix + ModName + "HideOutOfCombat");
		HideOutOfCombatDV.SetValue(Config.GetValue("HideOutOfCombat"));
		HideOutOfCombatDV.SignalChanged.Connect(HideOutOfCombatChanged, this);
		SGReloadsDV = DistributedValue.Create(DVPrefix + ModName + "ShowSGReloads");
		SGReloadsDV.SetValue(Config.GetValue("ShowSGReloads"));
		SGReloadsDV.SignalChanged.Connect(SGReloadsChanged, this);
		SGHotkeysDV = DistributedValue.Create(DVPrefix + ModName + "ShowSGHotkeys");
		SGHotkeysDV.SetValue(Config.GetValue("ShowSGHotkeys"));
		SGHotkeysDV.SignalChanged.Connect(SGHotkeysChanged, this);

		GlobalSignal.SignalSetGUIEditMode.Connect(ToggleGEM, this);
		var clientChar:Character = Character.GetClientCharacter();
		clientChar.SignalToggleCombat.Connect(UpdateWrapperVisibility, this);
		UpdateWrapperVisibility();
		
		super.LoadComplete();
	}

	private function UpdateWrapperVisibility():Void {
		CooldownWrapper._visible = EnableGEM ||
								   !Config.GetValue("HideOutOfCombat") ||
								   Character.GetClientCharacter().IsThreatened();
	}

	private function ToggleGEM(unlock:Boolean):Void {
		EnableGEM = unlock;
		UpdateWrapperVisibility();
	}

	private function ConfigChanged(setting:String, newValue, oldValue):Void {
		switch(setting) {
			case "CooldownLayout": {
				for (var i:Number = 0; i < CooldownCount; ++i) {
					var clip:MovieClip = CooldownViews[i];
					var layout = newValue[i];
					clip._x = layout.x;
					clip._y = layout.y;
					clip._xscale = layout.scale;
					clip._yscale = layout.scale;
					clip._alpha = layout.alpha;
				}
				break;
			}
			case "HideReady": {
				for (var i:Number = 0; i < CooldownCount; ++i) {
					CooldownViews[i].SetOffCDBehaviour(newValue);
				}
				break;
			}
			case "HideOutOfCombat": {
				UpdateWrapperVisibility();
				break;
			}
			case "ShowSGReloads": {
				var showHotkeys:Boolean = Config.GetValue("ShowSGHotkeys");
				for (var i:Number = 0; i < CooldownCount; ++i) {
					CooldownViews[i].SetShotgunSupportBehaviour(newValue, showHotkeys);
				}
				break;
			}
			case "ShowSGHotkeys": {
				var showReloads:Boolean = Config.GetValue("ShowSGReloads");
				for (var i:Number = 0; i < CooldownCount; ++i) {
					CooldownViews[i].SetShotgunSupportBehaviour(showReloads, newValue);
				}
				break;
			}
			default: super.ConfigChanged(setting, newValue, oldValue);
		}
	}

	private function HideReadyChanged(dv:DistributedValue):Void {
		Config.SetValue("HideReady", dv.GetValue());
	}
	
	private function HideOutOfCombatChanged(dv:DistributedValue):Void {
		Config.SetValue("HideOutOfCombat", dv.GetValue());
	}
	
	private function SGReloadsChanged(dv:DistributedValue):Void {
		Config.SetValue("ShowSGReloads", dv.GetValue());
	}
	
	private function SGHotkeysChanged(dv:DistributedValue):Void {
		Config.SetValue("ShowSGHotkeys", dv.GetValue());
	}

	private function UpdateMod(newVersion:String, oldVersion:String):Void {
		UpdateLayoutArray();
	}
	
	private function UpdateLayoutArray():Void {
		// Ensure that layout has been updated with the most recent display count and record properties
		// Situations where a value is removed will be corrected when serializing the data
		// Situations requiring conversions or other processing should be handled in UpdateMod prior to calling this function
		var layouts:Array = Config.GetValue("CooldownLayout");
		var defaultLayouts:Array = Config.GetDefault("CooldownLayout");
		for (var i:Number = 0; i < layouts.length; ++i) {
			for (var key:String in defaultLayouts[i]) { // Add any new properties to existing data
				if (layouts[i][key] == undefined) { layouts[i][key] = defaultLayouts[i][key]; }
			}
		}
		if (layouts.length < defaultLayouts.length) { // Add layouts for new cooldown displays
			for (var i:Number = layouts.length; i < defaultLayouts.length; ++i) {
				layouts.push(defaultLayouts[i]);
			}
		}
	}

	private function GetDefaultLayout():Array {
		var layout = new Array();
		for (var i:Number = 0; i < CooldownCount; ++i) {
			layout.push({x : 575 + i * 50, y : 450, scale : 100, alpha : 100});
		}
		return layout;
	}

	// Despite documentation to the contrary, SignalShortcutAdded only emits the first parameter
	private function AbilityChanged(pos:Number):Void {
		CooldownViews[pos-AbilityOffset].ChangeAbility(Shortcut.m_ShortcutList[pos]);
	}

	// Triggers once only
	private function AbilityMoved(oldPos:Number, newPos:Number):Void {
		AbilityChanged(oldPos);
		AbilityChanged(newPos);
	}

	private function EnableAbility(pos:Number, enabled:Boolean):Void {
		CooldownViews[pos-AbilityOffset].EnableAbility(enabled);
	}

	private function AbilityCooldown(pos:Number, start:Number, end:Number, type:Number):Void {
		var remains:Number = end - start;
		if (type > 0 && remains > 0) {
			CooldownViews[pos-AbilityOffset].AddCooldown(start, end, type)
		} else if (type == 0 && remains <= 0) {
			CooldownViews[pos-AbilityOffset].RemoveCooldown();
		}
	}

	private function ItemChanged(inventoryID:com.Utils.ID32, itemPos:Number):Void {
		if (itemPos == _global.Enums.ItemEquipLocation.e_Aegis_Talisman_1) {
			CooldownViews[GadgetIndex].ChangeAbility(Equipment.GetItemAt(_global.Enums.ItemEquipLocation.e_Aegis_Talisman_1));
		}
	}

	private function ItemCooldown(inventoryID:com.Utils.ID32, itemPos:Number, seconds:Number):Void {
		if (itemPos == _global.Enums.ItemEquipLocation.e_Aegis_Talisman_1) {
			if (seconds) {
				var now:Number = Utils.GetGameTime();
				CooldownViews[GadgetIndex].AddCooldown(now, now + seconds, 0);
			} else {
				Debug.TraceMsg("Cooldown force removed");
				CooldownViews[GadgetIndex].RemoveCooldown();
			}
		}
	}
	
	private function LoadHotkeys():Void {
		for (var i:Number = 0; i < CooldownCount; ++i) {
			var hotkey:MovieClip = CooldownViews[i].m_HotkeyLabel;
			hotkey.gotoAndStop("Text");
			hotkey.m_HotkeyText.autoSize = "left";
			hotkey.m_HotkeyText.text = "";
			hotkey.m_HotkeyText.text = "<variable name='hotkey_short:" + 
				(i == GadgetIndex ? 
					"Use_Gadget" :
					"Shortcutbar_" + (i + 1))
				+ "'/ >";
			if (hotkey.m_HotkeyText.text == "") {
				hotkey.m_Background._visible = false;
				if (i == 1) { hotkey.gotoAndStop("LMB"); }
				if (i == 3) { hotkey.gotoAndStop("RMB"); }
			} else {
				hotkey.m_Background._visible = true;
				hotkey.m_Background._width = Math.max(hotkey.m_HotkeyText._width, 22);
				hotkey.m_HotkeyText._x = hotkey.m_Background._width/2 - hotkey.m_HotkeyText._width/2;
			}
			hotkey._x = (CooldownViews[i]._width - hotkey._width) / 2;
		}
	}

	private static var AbilityOffset:Number = 100;
	private static var AbilityCount:Number = 6;
	private static var CooldownCount:Number = AbilityCount + 1;
	private static var GadgetIndex = AbilityCount;

	private var EnableGEM:Boolean = false;

	private var CooldownWrapper:MovieClip;
	private var CooldownViews:Array;
	private var HideReadyDV:DistributedValue;
	private var HideOutOfCombatDV:DistributedValue;
	private var SGReloadsDV:DistributedValue;
	private var SGHotkeysDV:DistributedValue;
	private var Equipment:Inventory;
}
