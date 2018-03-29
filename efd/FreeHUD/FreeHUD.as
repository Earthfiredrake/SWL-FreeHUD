// Copyright 2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-FreeHUD

import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Shortcut;
import com.GameInterface.Game.ShortcutData;
import com.GameInterface.Inventory;
import com.GameInterface.Utils;
import com.Utils.ID32;

import efd.FreeHUD.lib.Mod;
import efd.FreeHUD.lib.sys.ConfigManager;

class efd.FreeHUD.FreeHUD extends Mod {
	private function GetModInfo():Object {
		return {
			// Debug flag at top so that commenting out leaves no hanging ','
			// Debug : true,
			Name : "FreeHUD",
			Version : "0.0.1.beta",
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

		Equipment = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, Character.GetClientCharID().GetInstance()));
	}

	private function Activate():Void {
		if (!CooldownViews) {
			CooldownViews = new Array;
			var layoutSettings:Array = Config.GetValue("CooldownLayout");
			var hideReady:Boolean = Config.GetValue("HideReady");
			for (var i:Number = 0; i < CooldownCount; ++i) {
				var layout:Object = layoutSettings[i];
				var cooldown:MovieClip = HostClip.attachMovie("efdFreeHUDCooldownDisplay", "CooldownDisplay" + i, HostClip.getNextHighestDepth(),
					{_x : layout.x, _y : layout.y, _xscale : layout.scale, _yscale : layout.scale,
					 SlotID : (i == GadgetIndex ? 0 : i + AbilityOffset),
					 HideReady : hideReady});
				cooldown.ChangeAbility(i < AbilityCount ?
					Shortcut.m_ShortcutList[i + AbilityOffset] :
					Equipment.GetItemAt(_global.Enums.ItemEquipLocation.e_Aegis_Talisman_1));
				CooldownViews.push(cooldown);
			}
		}
		Shortcut.SignalShortcutAdded.Connect(AbilityChanged, this);
		Shortcut.SignalShortcutRemoved.Connect(AbilityChanged, this);
		Shortcut.SignalShortcutMoved.Connect(AbilityMoved, this);
		Shortcut.SignalShortcutEnabled.Connect(EnableAbility, this);
		Shortcut.SignalCooldownTime.Connect(AbilityCooldown, this);

		Equipment.SignalItemAdded.Connect(ItemChanged, this);
		Equipment.SignalItemLoaded.Connect(ItemChanged, this);
		Equipment.SignalItemRemoved.Connect(ItemChanged, this);
		Equipment.SignalItemCooldown.Connect(ItemCooldown, this);
		Equipment.SignalItemCooldownRemoved.Connect(ItemCooldown, this);
	}

	private function Deactivate():Void {
		var layout = new Array();
		for (var i:Number = 0; i < CooldownCount; ++i) {
			var clip:MovieClip = CooldownViews[i];
			layout.push({x : clip._x, y : clip._y, scale : clip._xscale});
		}
		Config.SetValue("CooldownLayout", layout);
	}

	private function LoadComplete():Void {
		VisibilityBehaviourDV = DistributedValue.Create(DVPrefix + ModName + "HideReady");
		VisibilityBehaviourDV.SetValue(Config.GetValue("HideReady"));
		VisibilityBehaviourDV.SignalChanged.Connect(VisibilityBehaviourChanged, this);
		super.LoadComplete();
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
				}
				break;
			}
			case "HideReady": {
				for (var i:Number = 0; i < CooldownCount; ++i) {
					CooldownViews[i].SetVisibilityBehaviour(newValue);
				}
				break;
			}
			default: super.ConfigChanged(setting, newValue, oldValue);
		}
	}

	private function VisibilityBehaviourChanged(dv:DistributedValue):Void {
		Config.SetValue("HideReady", dv.GetValue());
	}

	private function UpdateMod(newVersion:String, oldVersion:String):Void {
		var layouts:Array = Config.GetValue("CooldownLayout");
		var defaultLayouts:Array = Config.GetDefault("CooldownLayout");
		if (layouts.length < defaultLayouts.length) {
			for (var i:Number = layouts.length; i < defaultLayouts.length; ++i) {
				layouts.push(defaultLayouts[i]);
			}
		}
	}

	private function GetDefaultLayout():Array {
		var layout = new Array();
		for (var i:Number = 0; i < CooldownCount; ++i) {
			layout.push({x : 575 + i * 50, y : 450, scale : 100});
		}
		return layout;
	}

	// Despite documentation to the contrary, SignalShortcutAdded only emits the first parameter
	private function AbilityChanged(pos:Number) {
		CooldownViews[pos-AbilityOffset].ChangeAbility(Shortcut.m_ShortcutList[pos]);
	}

	// Triggers once only
	private function AbilityMoved(oldPos:Number, newPos:Number) {
		AbilityChanged(oldPos);
		AbilityChanged(newPos);
	}

	private function EnableAbility(pos:Number, enabled:Boolean):Void {
		CooldownViews[pos-AbilityOffset].EnableAbility(enabled);
	}

	private function AbilityCooldown(pos:Number, start:Number, end:Number, type:Number) {
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

	private static var AbilityOffset:Number = 100;
	private static var AbilityCount:Number = 6;
	private static var CooldownCount:Number = AbilityCount + 1;
	private static var GadgetIndex = AbilityCount;

	private var CooldownViews:Array;
	private var VisibilityBehaviourDV:DistributedValue;
	private var Equipment:Inventory;
}
