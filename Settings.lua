local DMW = DMW
DMW.Rotations.SHAMAN = {}
local Shaman = DMW.Rotations.SHAMAN
local UI = DMW.UI

function Shaman.Settings()
	DMW.Helpers.Rotation.StandingCheck = false
	DMW.Helpers.Rotation.CastingCheck = false
	UI.HUD.Options = {
		[1] = {
			Mana = {
				[1] = {Text = "|cFF00FF00HpME", Tooltip = ""},
				[2] = {Text = "|cFFFFFF00HpS", Tooltip = ""}
			}
		}
	}
    UI.AddHeader("Totems", "use totems", true)
	UI.AddToggle("Strength Of Earth Totem", nil, false)
	UI.AddToggle("Windfury Totem", nil, false)
	UI.AddToggle("Mana Spring Totem", nil, false)
	UI.AddToggle("Grace Of Air Totem", nil, false)
	UI.AddToggle("Searing Totem", nil, false)
	UI.AddRange("Searing Totem Mana", nil, 0, 100, 1, 79)
	UI.AddToggle("Magma Totem","use on 2+ mobs", nil, true)
	UI.AddRange("Magma Totem Mana", nil, 0, 100, 1, 79)
	UI.AddToggle("Fire Nova Totem","use on 2+ mobs", nil, true)
	UI.AddRange("Fire Nova Totem Mana", nil, 0, 100, 1, 79)
	UI.AddHeader("Utility")
    UI.AddToggle("Auto Target Quest Units", nil, false)
	UI.AddToggle("Orc Racial", nil, true)
	UI.AddToggle("Lightning Shield", nil, true)
    UI.AddToggle("Earth Shock Interrupt", "Rank 1 earth shock to interrupt", nil, true)
		UI.AddHeader("Defensives")
	UI.AddToggle("Stoneskin Totem", nil, false)
	UI.AddToggle("Ston Claw Totem","taunt when 2+ mobs", nil, true)
	UI.AddHeader("Self healing")
	UI.AddToggle("In Combat Heal", nil, false)
	UI.AddRange("Lesser Heal HP", nil, 0, 100, 1, 29)
	UI.AddToggle("OOC Healing", nil, true)
	UI.AddRange("OOC Healing Percent HP", nil, 0, 100, 1, 50)
	UI.AddRange("OOC Healing Percent Mana", nil, 0, 100, 1, 50)
	UI.AddHeader("Opener")
	UI.AddToggle("Lightning Bolt","Rank 1 to pull", nil, true)
	UI.AddHeader("DPS")
	UI.AddToggle("Earth Shock", nil, true)
	UI.AddRange("Earth Shock Mana", nil, 0, 100, 1, 50)
	UI.AddToggle("Flame Shock", nil, false)
	UI.AddRange("Flame Shock Mana", nil, 0, 100, 1, 50)
	UI.AddToggle("Stormstrike",nil,true)
		UI.AddHeader("Featured")
	UI.AddToggle("WF/Grace Weaving",nil,false)
	UI.AddToggle("WF/ToA Weaving",nil,false)
		UI.AddHeader("Party Healing")
	UI.AddToggle("Five Second Rule", "Set time to not break 5 second rule")
	UI.AddRange("Five Second Cutoff", "Set time to not break 5 second rule", 0, 5, 0.1, 4.5)
	UI.AddToggle("Party - Lesser Healing Wave",nil)
	UI.AddRange("Party - Lesser Healing Wave", nil, 0, 100, 5 ,50)
	UI.AddToggle("Party - Healing Wave",nil)
	UI.AddRange("Party - Healing Wave", nil, 0, 100, 5 ,50)
	UI.AddToggle("Party - Chain Heal",nil)
	UI.AddRange("Party - Chain Heal", nil, 0, 100, 5 ,50)
	UI.AddToggle("Keep Healing Way on party1", nil, false)
	UI.AddToggle("Auto Purge",nil, false)
	UI.AddToggle("Check Overheal",nil, false)
	UI.AddToggle("Totem for Carries",nil, false)
	UI.AddToggle("Res shit ooc",nil, false)
	UI.AddToggle("Downranking", nil, false)
	UI.AddToggle("Dispel Poison", nil, false)
	UI.AddToggle("Dispel Disease", nil, false)
end
