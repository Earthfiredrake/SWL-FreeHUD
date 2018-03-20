// Copyright 2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-FreeHUD

import com.GameInterface.Game.Shortcut;
import com.GameInterface.Game.ShortcutData;

import efd.FreeHUD.lib.Mod;
import efd.FreeHUD.lib.sys.ConfigManager;

class efd.FreeHUD.FreeHUD extends Mod {
	private function GetModInfo():Object {
		return {
			// Debug flag at top so that commenting out leaves no hanging ','
			// Debug : true,
			Name : "FreeHUD",
			Version : "0.0.1.alpha",
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
	}

	private function Activate():Void {
		if (!CooldownViews) {
			CooldownViews = new Object;
			var layoutSettings:Array = Config.GetValue("CooldownLayout");
			for (var i:Number = 0; i < AbilityCount; ++i) {
				var layout:Object = layoutSettings[i];
				CooldownViews[i] = HostClip.attachMovie("efdFreeHUDCooldownDisplay", "CooldownDisplay" + i, HostClip.getNextHighestDepth(),
					{_x : layout.x, _y : layout.y, _xscale : layout.scale, _yscale : layout.scale, SlotID : i + AbilityOffset});
			}
		}
		Shortcut.SignalShortcutAdded.Connect(AbilityChanged, this);
		Shortcut.SignalShortcutRemoved.Connect(AbilityChanged, this);
		Shortcut.SignalShortcutMoved.Connect(AbilityMoved, this);
		Shortcut.SignalShortcutEnabled.Connect(EnableAbility, this);
		Shortcut.SignalCooldownTime.Connect(AbilityCooldown, this);
	}
	
	private function Deactivate():Void {
		var layout = new Array();
		for (var i:Number = 0; i < AbilityCount; ++i) {
			var clip:MovieClip = CooldownViews[i];
			layout.push({x : clip._x, y : clip._y, scale : clip._xscale});
		}
		Config.SetValue("CooldownLayout", layout);
	}
	
	private function ConfigChanged(setting:String, newValue, oldValue):Void {
		switch(setting) {
			case "CooldownLayout": {
				for (var i:Number = 0; i < AbilityCount; ++i) {
					var clip:MovieClip = CooldownViews[i];
					var layout = newValue[i];
					clip._x = layout.x;
					clip._y = layout.y;
					clip._xscale = layout.scale;
					clip._yscale = layout.scale;
				}
				break;
			}
			default: super.ConfigChanged(setting, newValue, oldValue);		
		}
	}
	
	private function GetDefaultLayout():Array {
		var layout = new Array();
		for (var i:Number = 0; i < AbilityCount; ++i) {
			layout.push({x : 575 + i * 50, y : 450, scale : 100});
		}
		return layout;
	}
	
	// Despite documentation to the contrary, SignalShortcutAdded only emits the first parameter
	private function AbilityChanged(pos:Number) {
		CooldownViews[pos-AbilityOffset].ChangeAbility();
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
	
	private var CooldownViews:Object;
	private static var AbilityOffset:Number = 100;
	private static var AbilityCount:Number = 6;
}
