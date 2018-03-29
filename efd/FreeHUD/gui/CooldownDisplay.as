// Copyright 2018, Earthfiredrake
// Released under the terms of the MIT License
// https://github.com/Earthfiredrake/SWL-FreeHUD

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

class efd.FreeHUD.gui.CooldownDisplay extends MovieClip {

	public function CooldownDisplay() {
        super();

		Clear();
		m_Gloss._visible = false;
		Colors.ApplyColor(m_Background.background, 0);
		Colors.ApplyColor(m_Background.highlight, 4276545);
        AbilityIconLoader = new MovieClipLoader();

		GlobalSignal.SignalSetGUIEditMode.Connect(ManageGEM, this);
		SignalGeometryChanged = new Signal();
	}

	public function ChangeAbility(data:Object):Void {
		if (data.m_Icon) {
			SetIcon(Utils.CreateResourceString(data.m_Icon));
			if (SlotID > 0 && !data.m_Enabled) { DebugUtils.TraceMsgS("Ability disabled on creation"); }
		} else { Clear(); }
		UpdateVisuals();
	}

	public function EnableAbility(enabled:Boolean):Void {
		Enabled = enabled;
		UpdateVisuals();
	}

	public function SetVisibilityBehaviour(hideReady:Boolean):Void {
		HideReady = hideReady;
		UpdateVisuals();
	}

    private function Clear():Void {
        Enabled = true;

        if (IsLoaded) {
            AbilityIconLoader.unloadClip(AbilityIcon);
			IsLoaded = false;
        }
    }

    private function SetIcon(path:String):Void {
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
			GemManager.addEventListener("scrollWheel", this, "ChangeScale");
			GemManager.addEventListener("endDrag", this, "ChangePosition");
		}
		if (!unlock) {
			GemManager.removeMovieClip();
			GemManager = null;
		}
		UpdateVisuals();
	}

	private function ChangePosition(event:Object):Void { SignalGeometryChanged.Emit(); }

	private function ChangeScale(event:Object):Void {
		var newScale:Number = _xscale + event.delta * 5;
		newScale = Math.min(200, Math.max(30, newScale));
		_xscale = newScale;
		_yscale = newScale;
		SignalGeometryChanged.Emit();
	}

/// Cooldowns
    public function AddCooldown(cooldownStart:Number, cooldownEnd:Number, cooldownFlags:Number):Void {
		if (cooldownFlags & _global.Enums.TemplateLock.e_GlobalCooldown) { return; }
		// Unneeded? update visuals now, to avoid being forever stuck in the wrong state if other abilities are spammed
		// UpdateVisualState();
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
		_visible = GemManager || (!HideReady || CooldownOverlay) && IsLoaded && (SlotID == 0 || TooltipDataProvider.GetSpellTooltip(Shortcut.m_ShortcutList[SlotID].m_SpellId, 0).m_RecastTime > 0);
        if (CooldownOverlay != undefined) { return; }
		UpdateVisualState();
	}

	private function UpdateVisualState():Void {
        if (Enabled) { SetAvailable(); }
		else { SetDisabled(); }
    }

/// vars
    private var AbilityIcon:MovieClip;
    private var AbilityIconLoader:MovieClipLoader;
	private var IsLoaded:Boolean = false;

	private var HideReady:Boolean = false;
	private var Enabled:Boolean;

	private var GemManager:GemController;
	private var SignalGeometryChanged:Signal;

	private var SlotID:Number;

	private var CooldownOverlay:AbilityCooldown = undefined;

	// Library object elements
	private var m_OuterLine:MovieClip;
    private var m_BackgroundGradient:MovieClip;

	// Referenced from AbilityCooldown library class, don't rename
	private var m_CooldownLine:MovieClip;
	private var m_Gloss:MovieClip;
	private var m_Background:MovieClip;
}
