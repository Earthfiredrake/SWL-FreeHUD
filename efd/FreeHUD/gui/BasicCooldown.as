// Copyright 2018-2020, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-FreeHUD

import com.GameInterface.Game.Character;
import com.GameInterface.Game.Shortcut;
import com.GameInterface.Game.ShortcutData;
import com.GameInterface.InventoryItem;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.GameInterface.Utils;
import com.Utils.Colors;
import com.Utils.GlobalSignal;
import com.Utils.Signal;
import GUI.HUD.AbilityCooldown;

import efd.FreeHUD.lib.DebugUtils;
import efd.FreeHUD.lib.Mod;
import efd.FreeHUD.lib.etu.GemController;

// Abstract base class for cooldowns
// Provides triggers for activating a cooldown and GEM support

class efd.FreeHUD.gui.BasicCooldown extends MovieClip {

	public function BasicCooldown() {
        super();

		Clear();
		m_Gloss._visible = false;		
		Colors.ApplyColor(m_Background.background, 0);
		Colors.ApplyColor(m_Background.highlight, 4276545);
        AbilityIconLoader = new MovieClipLoader();

		GlobalSignal.SignalSetGUIEditMode.Connect(ManageGEM, this);
		SignalGeometryChanged = new Signal();
		
		var clientChar:Character = Character.GetClientCharacter();
		clientChar.SignalToggleCombat.Connect(NotifyInCombat, this);
		NotifyInCombat(clientChar.IsThreatened());
	}

	public function ChangeAbility(data:Object):Void {
		if (data.m_Icon) {
			LoadIconClip(Utils.CreateResourceString(data.m_Icon));
			Enabled = SlotID == GadgetSlot || data.m_Enabled;
		} else { Clear(); }
		UpdateVisuals();
	}

	public function EnableAbility(enabled:Boolean):Void {
		Enabled = enabled;
		UpdateVisuals();
	}

	public function SetOffCDBehaviour(hideReady:Boolean):Void {
		HideReady = hideReady;		
		UpdateVisuals();
	}
	
	public function SetOutOfCombatVisibility(hideOutOfCombat:Boolean):Void {
		HideOutOfCombat = hideOutOfCombat;
		UpdateVisuals();
	}
	
	public function SetShotgunSupportBehaviour(showReloads:Boolean, showHotkeys:Boolean): Void {
		ShowSGReloads = showReloads;
		ShowSGHotkeys = showHotkeys;
		UpdateVisuals();
	}

    private function Clear():Void {
        Enabled = true;

        if (IsLoaded) {
            AbilityIconLoader.unloadClip(AbilityIcon);
			IsLoaded = false;
        }
    }

    private function LoadIconClip(path:String):Void {
		if (IsLoaded) { AbilityIconLoader.unloadClip(AbilityIcon); }
        IsLoaded = AbilityIconLoader.loadClip(path, AbilityIcon);

        AbilityIcon._xscale = m_Background._width;
        AbilityIcon._yscale = m_Background._height;
    }

/// GUI Edit Mode

	private function ManageGEM(unlock:Boolean):Void {
		if (unlock && !GemManager) {
			GemManager = GemController.create("GuiEditModeInterface" + SlotID, _parent, _parent.getNextHighestDepth(), this);
			GemManager.lockAxis(0);
			GemManager.addEventListener("scrollWheel", this, "GemScroll");
			GemManager.addEventListener("endDrag", this, "ChangePosition");
		}
		if (!unlock) {
			GemManager.removeMovieClip();
			GemManager = null;
		}
		UpdateVisuals();
	}

	private function ChangePosition(event:Object):Void { SignalGeometryChanged.Emit(); }

	private function GemScroll(event:Object):Void {
		if (Key.isDown(Key.SHIFT)) { // Adjust transparency (TODO: Store this)
			var newAlpha:Number = Math.min(100, Math.max(10, _alpha + event.delta * 5));
			_alpha = newAlpha;
		} else { // Ajust scale
			var newScale:Number = Math.min(200, Math.max(30, _xscale + event.delta * 5));
			_xscale = newScale;
			_yscale = newScale;
			SignalGeometryChanged.Emit();
		}
	}

/// Cooldowns
    public function AddCooldown(cooldownStart:Number, cooldownEnd:Number, cooldownFlags:Number):Void {
		if (cooldownFlags & _global.Enums.TemplateLock.e_GlobalCooldown) { return; }
		AbilityIcon._alpha = 35;

		// Start or update cooldown
		if (CooldownOverlay == undefined) {
			CooldownOverlay = new AbilityCooldown(this, cooldownStart, cooldownEnd, cooldownFlags);
			CooldownOverlay.SignalDone.Connect(RemoveCooldown, this);
		} else {
			CooldownOverlay.OverwriteCooldown(cooldownStart, cooldownEnd, cooldownFlags);
		}
		UpdateVisuals();
    }

    public function RemoveCooldown():Void {
        if(CooldownOverlay != undefined) {
            AbilityIcon._alpha = 100;

            CooldownOverlay.SignalDone.Disconnect(RemoveCooldown, this);

            CooldownOverlay.RemoveCooldown();
            CooldownOverlay = undefined;
			UpdateVisuals();
		}
	}

/// Display Adjustments
	private function NotifyInCombat(inCombat:Boolean):Void {
		IsInCombat = inCombat;
		if (HideOutOfCombat) { UpdateVisuals(); }
	}

	private function SetOffCD():Void {
        m_CooldownLine._visible = false;
        m_OuterLine._visible = true;
		Colors.ApplyColor(m_OuterLine, Colors.e_ColorBlack);
    }

    public function SetDisabled():Void {
        SetOffCD();
        m_Background._visible = false;

        AbilityIcon._alpha = 50;
    }

    public function SetAvailable():Void {
        SetOffCD();
        m_Background._visible = true;

        AbilityIcon._alpha = 100;
        m_Background._alpha = 100;
    }

    private function UpdateVisuals():Void {
		_visible = GemManager ||
			(IsLoaded &&
			 (IsInCombat || !HideOutOfCombat) &&
			 ((ShowSGReloads && IsSGReload()) ||
			  ((!HideReady || CooldownOverlay) &&
			   (SlotID == GadgetSlot || HasAbilityCooldown()))));
		m_HotkeyLabel._visible = ShowSGHotkeys && IsSGReload();
        if (CooldownOverlay != undefined) { return; }
		if (Enabled) { SetAvailable(); }
		else { SetDisabled(); }
	}

	private function HasAbilityCooldown():Boolean {
		return TooltipDataProvider.GetSpellTooltip(Shortcut.m_ShortcutList[SlotID].m_SpellId, 0).m_RecastTime > 0;
	}

	private function IsSGReload():Boolean {
		var spellID:Number = Shortcut.m_ShortcutList[SlotID].m_SpellId - 9253300; // All shotgun reloads are 92533xx		
		return spellID ==  5 || // AP rounds
			   spellID == 14 || // DB rounds
			   spellID == 15 || // DU rounds
			   spellID == 16;   // AI rounds
	}

/// vars
    private var AbilityIcon:MovieClip;
    private var AbilityIconLoader:MovieClipLoader;
	private var IsLoaded:Boolean = false;

	private var HideReady:Boolean = false;
	private var HideOutOfCombat:Boolean = true;
	private var IsInCombat:Boolean = false;
	private var ShowSGReloads:Boolean = true;
	private var ShowSGHotkeys:Boolean = true;
	private var Enabled:Boolean;

	private var GemManager:GemController;
	private var SignalGeometryChanged:Signal;

	private var SlotID:Number;
	private static var GadgetSlot:Number = 0;

	private var CooldownOverlay:AbilityCooldown = undefined;

	// Library object elements
	private var m_OuterLine:MovieClip;
    private var m_BackgroundGradient:MovieClip;
	private var m_HotkeyLabel:MovieClip;

	// Referenced from AbilityCooldown library class, don't rename
	private var m_CooldownLine:MovieClip;
	private var m_Gloss:MovieClip;
	private var m_Background:MovieClip;
}
