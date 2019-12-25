local DMW = DMW
local Shaman = DMW.Rotations.SHAMAN
local HealCommLib = LibStub("LibHealComm-4.0", true)
local Rotation = DMW.Helpers.Rotation
local Setting = DMW.Helpers.Rotation.Setting
local Player, Pet, Buff, Debuff, Spell, Target, Talent, Item, GCD, CDs, HUD, Enemy40Y, Enemy40YC, ComboPoints, HP, Friends30Y, Friends30YC,
      Enemy8YC, Enemy8Y, Enemy60Y, Enemy60YC, Enemy30Y, Enemy30YC, Enemy20Y, Enemy20YC, statHealing, Enemy5Y, Enemy5YC, Friends40Y,
      Friends40YC, Power, spellPower, hasMainHandEnchant, mainHandExpiration, mainHandEnchantID, hasOffHandEnchant, mainHandCharges


local CombatState, DeadState, FollowState, GrindingState, IdleState, MovingState, MiscState, LootingState =
    DMW.Tables.Grind.States.CombatState, DMW.Tables.Grind.States.DeadState, DMW.Tables.Grind.States.FollowState,
    DMW.Tables.Grind.States.GrindingState, DMW.Tables.Grind.States.IdleState, DMW.Tables.Grind.States.MovingState,
    DMW.Tables.Grind.States.MiscState, DMW.Tables.Grind.States.LootingState
-- Druid 	102 	Balance 	103 	Feral 	104 	Guardian 	105 	Restoration
-- Hunter 	253 	Beast Mastery 	254 	Marksmanship 	255 	Survival
-- Mage 	62 	Arcane 	63 	Fire 	64 	Frost
-- Monk 	268 	Brewmaster 	270 	Mistweaver 	269 	Windwalker
-- Paladin 	65 	Holy 	66 	Protection 	70 	Retribution
-- Priest 	256 	Discipline 	257 	Holy 	258 	Shadow
-- Rogue 	259 	Assassination 	260 	Outlaw 	261 	Subtlety
-- Shaman 	262 	Elemental 	263 	Enhancement 	264 	Restoration
-- Warlock 	265 	Affliction 	266 	Demonology 	267 	Destruction
-- Warrior 	71 	Arms 	72 	Fury 	73 	Protection
local groupRoles = {Tank = {73, 66, 103}, Heal = {257, 264, 65}, Melee = {71, 72}, Ranged = {}}

local function Locals()
    Player = DMW.Player
    Pet = DMW.Player.Pet
    Buff = Player.Buffs
    HP = Player.HP
    Debuff = Player.Debuffs
    Spell = Player.Spells
    Talent = Player.Talents
    Item = Player.Items
    Power = Player.PowerPct
    Target = Player.Target or false
    HUD = DMW.Settings.profile.HUD
    CDs = Player:CDs() and Target and Target.TTD > 5 and Target.Distance < 5
    Friends40Y, Friends40YC = Player:GetFriends(40)
    Friends30Y, Friends30YC = Player:GetFriends(30)
    Enemy60Y, Enemy60YC = Player:GetEnemies(60)
    Enemy40Y, Enemy40YC = Player:GetEnemies(40)
    Enemy30Y, Enemy30YC = Player:GetEnemies(30)
    Enemy20Y, Enemy20YC = Player:GetEnemies(20)
    Enemy8Y, Enemy8YC = Player:GetEnemies(8)
    Enemy5Y, Enemy5YC = Player:GetEnemies(5)
    hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant = GetWeaponEnchantInfo()
end






-- local function hardTotemCheck(stuff)
-- 	if not Setting("Heavy Totem Check") then
-- 		return false
-- 	else

-- 	end
-- end
-- TODO last cast
local function checkParty()
    if Setting("Res shit ooc") then
        for k, Friend in ipairs(DMW.Friends.Corpses) do
            if Friend:LineOfSight() and (not Friend.ResTime or DMW.Time - Friend.ResTime >= 3) then
                if Spell.AncestralSpirit:Cast(Friend) then return true end
            end
        end
    end
end


--------------
-- 5 Sec Rule--
--------------
local function FiveSecond()
    if FiveSecondRuleTime == nil then FiveSecondRuleTime = DMW.Time end
    local FiveSecondRuleCount = DMW.Time - FiveSecondRuleTime
    if FiveSecondRuleCount > 6.5 then FiveSecondRuleTime = DMW.Time end
    if Setting("Five Second Rule") and ((FiveSecondRuleCount) >= Setting("Five Second Cutoff") or (FiveSecondRuleCount <= 0.4)) then
        return true
    end
    -- print(FiveSecondRuleCount)
end
local function resGroup()
    local k
    if not Player.Combat and Spell.AncestralSpirit:IsReady() then
        for _, Friend in pairs(DMW.Friends.Units) do
            if Friend.Dead and (not Friend.ResTime or (DMW.Time - Friend.ResTime >= 5)) then
                if Spell.AncestralSpirit:Cast(Friend) then
                    Friend.ResTime = DMW.Time
                    return true
                end
            end
        end
        -- for _, Friend in pairs(DMW.Friends.Units) do
        -- 	if Friend.Dead then
        -- 		if Spell.AncestralSpirit:Cast(Friend) then return true end
        -- 	end
        -- end
        -- if k then return true end
    end
end
local function checkTotemForUnits(totem, ...)
    if Setting("Totem for Carries") then
        for i = 1, 5 do
            for k,v in pairs(DMW.Units) do
                if UnitGUID("party"..i) == v.GUID and not
                Spell[totem]:CheckTotem(v,...) then
                    return false
                end
            end
        end
        return true
    end
    if Spell[totem]:CheckTotem(Player,...) then
        return true
    end
end
local function Totems()
    ------------------
    --- Totems ---
    ------------------
    for k,v in pairs(DMW.Friends.Units) do
        if v:IsFeared() then
            if Spell.TremorTotem:CheckTotem(v) then
                if Spell.TremorTotem:Cast(Player) then return true end
            end
        end
    end
    local combatCheck = false
    local check = false
    local count = 0
    if IsInGroup() and GetNumSubgroupMembers() > 0 then
        for i = 1, 5 do
            local unit = "party" .. i
            if UnitClass(unit) == "Warrior" or UnitClass(unit) == "Rogue" then
                if UnitAffectingCombat(unit) then
                    check = true
                    break
                end
            end
        end
    end


    if check then
        if not Setting("WF/Grace Weaving") and not Setting("WF/Tranquil Weaving") then
            -- GraceOfAirTotem
            if Spell.GraceofAirTotem:Known() and Setting("Grace Of Air Totem") and
                Spell.GraceofAirTotem:CheckTotem(Player, "GroundingTotem") then
                if Spell.GraceofAirTotem:Cast(Player) then return true end
            end
            -- WindfuryTotem
            if Spell.WindfuryTotem:Known() and Setting("Windfury Totem") and checkTotemForUnits("WindfuryTotem") then--Spell.WindfuryTotem:CheckTotem(Player, "GroundingTotem") then
                if Spell.WindfuryTotem:Cast(Player) then return true end
            end
        end
        -- StrengthofEarthTotem
        if Spell.StrengthofEarthTotem:Known() and Setting("Strength Of Earth Totem") and
        checkTotemForUnits("StrengthofEarthTotem") then
            if Spell.StrengthofEarthTotem:Cast(Player) then return true end
        end
        if Spell.ManaSpringTotem:Known() and Setting("Mana Spring Totem") and checkTotemForUnits("ManaSpringTotem") then
            if Spell.ManaSpringTotem:Cast(Player) then return true end
        end
        -- selfcheckonly for now
        if Setting("WF/Grace Weaving") then
            if Spell.WindfuryTotem:LastCast(1) or
                (hasMainHandEnchant and (mainHandEnchantID == 564 or mainHandEnchantID == 563 or mainHandEnchantID == 1783) and
                    mainHandExpiration > 8) then
                if Spell.GraceofAirTotem:CheckTotem(Player) then
                    if Spell.GraceofAirTotem:Cast(Player, "GroundingTotem") then return true end
                end
            else
                if (not mainHandExpiration or mainHandExpiration < 2) and Spell.WindfuryTotem:Cast(Player, "GroundingTotem") then
                    return true
                end
            end
        elseif Setting("WF/Tranquil Weaving") then
            if hasMainHandEnchant and (mainHandEnchantID == 564 or mainHandEnchantID == 563 or mainHandEnchantID == 1783) and
                mainHandExpiration > 8 then
                if Spell.TranquilAirTotem:CheckTotem(Player) then
                    if Spell.TranquilAirTotem:Cast(Player, "GroundingTotem") then return true end
                end
            else
                if Spell.WindfuryTotem:Cast(Player, "GroundingTotem") then return true end
            end
        end

        -- -- Stoneskin Totem for 2+ mobs Defensive
        -- if Target and Target.ValidEnemy and Setting("Stoneskin Totem") and Player.Combat and Spell.StoneskinTotem:CheckTotem(Player) then
        --     if Spell.StoneskinTotem:Cast(Player) then return true end
        -- end
        -- -- Stone Claw Totem for 2+ mobs
        -- if Target and Target.ValidEnemy and Setting("Ston Claw Totem") and Player.Combat and GetTotemInfo(2) == false and Enemy5YC > 1 then
        --     if Spell.StoneclawTotem:Cast(Player) then return true end
        -- end
        -- -- Magma Totem
        -- if Spell.MagmaTotem:Known() and Setting("Magma Totem") and Player.Combat and GetTotemInfo(1) == false and Enemy8YC > 1 and
        --     Player.PowerPct > Setting("Magma Totem Mana") and Target and Target.ValidEnemy and Target.TTD > 5 then
        --     if Spell.MagmaTotem:Cast(Player) then return true end
        -- end
        -- Fire Nova Totem
        if Spell.FireNovaTotem:Known() and Setting("Fire Nova Totem") and Target and Target.ValidEnemy and Player.Combat and
            Spell.FireNovaTotem:CheckTotem(Player) and Player.PowerPct > Setting("Fire Nova Totem Mana") and Target.TTD > 5 then
            if Spell.FireNovaTotem:Cast(Player) then return true end
        end
        -- Searing Totem
        -- if Setting("Searing Totem") and Player.Combat and GetTotemInfo(1) == false and Player.PowerPct > Setting("Searing Totem Mana") and
        --     Target and Target.ValidEnemy and Target.TTD > 10 then if Spell.FrostResistanceTotem:Cast(Player) then return true end end
    end
end

local function Utility()
    ------------------
    --- Utility ---
    ------------------
    -- Purge

    -- Racials
    if Setting("Orc Racial") then
        if Player.HP > 60 and Target and Target.ValidEnemy and Target.HP > 70 and Player.Combat then
            if Spell.BloodFury:Cast(Player) then
                return true
            elseif Spell.BerserkingTroll:Cast(Player) then
                return true
            end
        end
    end
    -- Lightning Shield
    if Setting("Lightning Shield") and Spell.LightningShield:Known() then
        if Buff.LightningShield:Remain() < 30 and Spell.LightningShield:Cast(Player) then return true end
    elseif Setting("LightningShield") and Spell.ImprovedLightningShield:Known() then
        if Buff.ImprovedLightningShield:Remain() < 300 and Spell.ImprovedLightningShield:Cast(Player) then return true end
    end
    -- Earth Shock Interrupt
    if Setting("Earth Shock Interrupt") then
        for k, Unit in pairs(Enemy20Y) do
            if Unit.ValidEnemy and Unit.Distance < 20 and Unit:Interrupt() then
                if Spell.EarthShock:Cast(Unit, 1) then return true end
            end
        end
    end
    -- Poisons
    local poisonCount = 0
    if Setting("Dispel Poison") then
        for _, Friend in pairs(DMW.Friends.Units) do
            if Friend:Dispel(Spell.CurePoison) then
                poisonCount = poisonCount + 1
                if poisonCount >= 1 then
                    if Spell.PoisonCleansingTotem:CheckTotem(Friend) then
                        if Spell.PoisonCleansingTotem:Cast(Player) then return true end
                    else
                        if Spell.CurePoison:Cast(Friend) then return true end
                    end
                end
            end
        end
    end
    -- Diseases
    local diseaseCount = 0
    if Setting("Dispel Disease") then
        for _, Friend in pairs(DMW.Friends.Units) do
            if Friend:Dispel(Spell.CureDisease) then
                diseaseCount = diseaseCount + 1
                if diseaseCount >= 1 then
                    if Spell.DiseaseCleansingTotem:CheckTotem(Friend) then
                        if Spell.DiseaseCleansingTotem:Cast(Player) then return true end
                    else
                        if Spell.CureDisease:Cast(Friend) then return true end
                    end
                end
            end
        end
    end
end
local function DEF()
    ------------------
    --- Defensives ---
    ------------------
    -- In Combat healing
    if Setting("In Combat Heal") and HP < Setting("Lesser Heal HP") and Player.Combat and not Player.Moving then
        if Spell.LesserHealingWave:Known() then
            if Spell.LesserHealingWave:Cast(Player) then return true end
        elseif Spell.HealingWave:Cast(Player) then
            return true
        end
    end
    if Setting("OOC Healing") and not Player.Combat and not Player.Moving and HP <= Setting("OOC Healing Percent HP") and Player.PowerPct >
        Setting("OOC Healing Percent Mana") then if Spell.HealingWave:Cast(Player) then return true end end
    -- Cure Poison

    if Setting("Cure CurePoison") then
        for k, Friend in ipairs(Friends40Y) do
            if Friend:Dispel(Spell.CurePoison) and Player.PowerPct > 20 then
                if Spell.CurePoison:Cast(Player) then return true end
            end
        end
    end
    -- Cure Disease
    if Setting("Cure Disease") then
        for k, Friend in ipairs(Friends40Y) do
            if Friend:Dispel(Spell.CureDisease) and Player.PowerPct > 20 then
                if Spell.CureDisease:Cast(Player) then return true end
            end
        end
    end
end


local function raidChainHeal()
    local chainHeal = {}
    if HUD.Mana == 2 then
        for i = 3,1 do
            local bestUnit
            for k,v in pairs(DMW.Friends.Units) do
                local heal, overheal, chains = DMW.Tables.HealerStuff.chainHealSim(v, i)
                chainHeal[v.Pointer]= {["heal"] = heal, ["overheal"] = overheal, ["links"] = chains}
                if overheal == 0 and chains == 3 and (chainHeal["bestUnit"] == nil or heal > chainHeal["bestUnit"]["heal"]) then
                    chainHeal["bestUnit"] = {["heal"] = heal, ["overheal"] = overheal, ["links"] = chains}
                    bestUnit = v
                end
            end
            if bestUnit ~= nil then
                if Spell.ChainHeal:Cast(bestUnit, i) then return true end
            end
        end
    end
        local bestUnit
        for k,v in pairs(DMW.Friends.Units) do
            local heal, overheal, chains = DMW.Tables.HealerStuff.chainHealSim(v, 3)
            chainHeal[v.Pointer]= {["heal"] = heal, ["overheal"] = overheal, ["links"] = chains}
            if overheal == 0 and chains == 3 and (chainHeal["bestUnit"] == nil or heal > chainHeal["bestUnit"]["heal"]) then
                chainHeal["bestUnit"] = {["heal"] = heal, ["overheal"] = overheal, ["links"] = chains}
                bestUnit = v
            end
        end
        if bestUnit ~= nil then
            if Spell.ChainHeal:Cast(bestUnit, 1) then return true end
        end
    -- elseif HUD.Mana == 1 then
    --     local highestHealAmount, highestHealUnit, highestHealRank, overhealOnhighestHeal, highestLinks
    --     for k,Unit in pairs(Friends40Y) do
    --         if Unit.HealthDeficit > 0 then
    --             --amountHealed, amountOverhealed, Unit, chainCount, firstHeal
    --             local healReturn, overhealReturn, _, linksReturn  = chainHealSim(Unit, 1)
    --             if highestHealAmount == nil or healReturn > highestHealAmount then
    --                 highestHealAmount = healReturn
    --                 highestHealUnit = Unit
    --                 highestHealRank = 1
    --                 overhealOnhighestHeal = overhealReturn
    --                 highestLinks = linksReturn
    --             end
    --             if overhealOnhighestHeal < 300 and highestLinks == 3 then
    --                 highestHealRank = 1
    --                 if Spell.ChainHeal:Cast(highestHealUnit,highestHealRank) then return true end
    --             end
    --         end
    --     end
    -- end
end
local function HWHeal()
    local chainHeal = {}
    if HUD.Mana == 2 then
        local bestSkill, bestUnit, bestRank,bestHeal
        for i = 3,1 do
            -- local bestUnit
            for k,v in pairs(DMW.Friends.Units) do
                local heal, overheal, chains = DMW.Tables.HealerStuff.chainHealSim(v, i)
                chainHeal[v.Pointer]= {["heal"] = heal, ["overheal"] = overheal, ["links"] = chains}
                if overheal == 0 and chains == 3 and (chainHeal["bestUnit"] == nil or heal > chainHeal["bestUnit"]["heal"]) then
                    chainHeal["bestUnit"] = {["heal"] = heal, ["overheal"] = overheal, ["links"] = chains}
                    bestUnit = v
                    bestHeal = chainHeal["bestUnit"]["heal"]
                    bestRank = i
                    bestSkill = "ChainHeal"
                end
            end
            -- if bestUnit ~= nil then
            --     if Spell.ChainHeal:Cast(bestUnit, i) then return true end
            -- end
        end
        local highestHealAmount, highestHealUnit, highestRank
        for i = 9, 5, -1 do
            for k, Unit in pairs(Friends40Y) do
                if Unit.HealthDeficit > 0 then
                    local returnHeal, returnOverheal =  DMW.Tables.HealerStuff.predictHealAmount("HealingWave", i, Unit)
                    if returnOverheal == 0 and (highestHealAmount == nil or returnHeal > highestHealAmount) then
                        highestHealAmount = returnHeal
                        highestHealUnit = Unit
                        highestRank = i
                    end
                end
            end
        end
        if (highestHealAmount and bestHeal and bestHeal >= highestHealAmount) or bestHeal  then
            if Spell.ChainHeal:Cast(bestUnit, bestRank) then return true end
        else
            if highestHealAmount then
                if Spell.HealingWave:Cast(highestHealUnit, highestRank) then return true end
            end
        end
    end
    -- local highestHealAmount, highestHealUnit
    -- for k, Unit in pairs(Friends40Y) do
    --     if Unit.HealthDeficit > 0 then
    --         local returnHeal, returnOverheal =  DMW.Tables.HealerStuff.predictHealAmount("HealingWave", 5, Unit)
    --         if returnOverheal == 0 and (highestHealAmount == nil or returnHeal > highestHealAmount) then
    --             highestHealAmount = returnHeal
    --             highestHealUnit = Unit
    --         end
    --     end
    -- end
    -- if highestHealUnit ~= nil then
    --     if Spell.HealingWave:Cast(highestHealUnit, 5) then return true end
    -- end
end

local function Heal()
    table.sort(Friends40Y, function(x, y) return x.HealthDeficit > y.HealthDeficit end)

    -- for _, Friend in ipairs(Friends40Y) do
    -- 	if Friend:LineOfSight() then
    -- 		tinsert(Friend, HealTable)
    -- 	end
    -- end
    -- if #HealTable > 1 then
    -- 	table.sort(
    -- 		HealTable,
    -- 			function(x, y)
    -- 				return x.TTD < y.TTD
    -- 			end
    -- 		)
    -- end


    if not Player.Casting then
        for k,v in pairs(Friends40Y) do
            if v.Health <= 1500 and v.Combat then
                if Spell.LesserHealingWave:Cast(v) then return true end
            end
        end
        raidChainHeal()
        HWHeal()
    end
        -- raidChainHeal()
    -- for _, Friend in ipairs(Friends40Y) do
    --     -- if Setting("Party - Lesser Healing Wave") and Spell.LesserHealingWave:IsReady() and Friend.HP <=
    --     --     Setting("Party - Lesser Healing Wave") then if smartHeal("LesserHealingWave", Friend) then return true end end
    --     -- if Setting("Party - Healing Wave") and Spell.HealingWave:IsReady() and Friend.HP <= Setting("Party - Healing Wave") then
    --     --     if smartHeal("HealingWave", Friend) then return true end
    --     -- end
    --     -- -- Party Renew
    --     -- if Setting("Party - Chain Heal") and Friend.HP <= Setting("Party - Chain Heal") then
    --     --     if smartHeal("ChainHeal", Friend) then return true end
    --     -- end
    --     -- Party Flash Heal

    --     -- Greater Heal
    -- end
    if Setting("Keep Healing Way on party1") and UnitExists("party1") and not UnitIsDeadOrGhost("party1") and Spell.HealingWave:IsReady() then
        for _, Friend in pairs(Friends40Y) do
            if Friend.Pointer == ObjectPointer("party1") and (Buff.HealingWay:Stacks(Friend) < 3 or Buff.HealingWay:Remain(Friend) < 5) then
                if Spell.HealingWave:Cast(Friend, 1) then return true end
            end
        end
    end
end

function Shaman.Rotation()
    -- if DMW.Player.Casting then smarthealTimer = DMW.Time end

    -- if smarthealTimer ~= nil then
    -- 	if DMW.Player.Casting or  DMW.Time - smarthealTimer < 0.5 then
    -- 		return true
    -- 	end
    -- end

    Locals()
    -- for k,v in pairs(DMW.Units) do
    --     if v.Distance <= 50 and not v.Player then
    --         local lo,mo,zo,fo = UnitCastID(v.Pointer)
    --         if lo ~= 0 then
    --             print(lo.."    "..zo)
    --         elseif mo ~= 0 then
    --             print(mo.."    "..fo)
    --         end
    --     end
    -- end
    -- Spell.StrengthofEarthTotem:CheckTotem(Player, "blabla", "blabal", "TremorTotem")
    -- 	print("func true")
    -- end
    -- for k, Unit in pairs(DMW.Units) do
    -- 	if Unit.CanAttack and Unit:Dispel(DMW.Player.Spells.Purge) then
    -- 	--    print(Unit.Name)
    -- 	end
    --  end

    if not Player.Combat and not Player.Casting and not Player.Moving and Player.PowerPct <= 20 and not Player:AuraByName("Drink") then
        if Spell.ManaSpringTotem:IsReady() then Spell.ManaSpringTotem:Cast(Player) end
        RunMacro("drink")
        -- Player.Eating = true
        MovingState.Pause = DMW.Time + 2
        return true
    end
        if Player:AuraByName("Drink") then
            if Player.PowerPct >= 95 then RunMacroText("/stand") end
            return true
        end



        checkParty()
    -- if resGroup() then return true end
    Totems()
    -- if Setting("Auto Purge") and Spell.Purge:IsReady() then
    --     for k, Unit in ipairs(Enemy30Y) do
    --         if Unit:Dispel(Spell.Purge) then
    --             if Spell.Purge:Cast(Unit) then
    --                 print(Unit.Name)
    --                 return true
    --             end
    --         end
    --     end
    -- end
    if not Player.Moving and Heal() then
        FiveSecondRuleTime = DMW.Time
        return
    end
    if Setting("Auto Purge") and Spell.Purge:IsReady() then
        for k, Unit in ipairs(Enemy30Y) do
            if Unit:Dispel(Spell.Purge) then
                if Spell.Purge:Cast(Unit) then
                    print(Unit.Name)
                    return true
                end
            end
        end
    end

    if Utility() then return true end

    if DEF() then return true end
    -- if Totems() then return true end
    -----------------
    -- Targetting --
    -- 	-----------------
    --     if Setting("Auto Target Quest Units") then
    --        if Player:AutoTargetQuest(20, true) then
    -- 			return true
    --         end
    --     end
    --     if Player.Combat and Setting("Auto Target") then
    --         if Player:AutoTarget(20, true) then
    --             return true
    --         end
    -- 	end
    -- 	-----------------
    -- 	-- DPS --
    -- 	-----------------
    -- -- EarthShock
    -- 	if Setting("Earth Shock") and Target and Target.ValidEnemy and Target.Distance < 20 and Target.Facing and Player.PowerPct > Setting("Earth Shock Mana") and Target.TTD > 1 then
    -- 		if Spell.EarthShock:Cast(Target) then
    -- 			return
    -- 		end
    -- 	end
    -- -- Flame Shock
    -- 	if Setting("Flame Shock") and Target and Target.ValidEnemy and Target.Distance < 20 and Target.Facing and Player.PowerPct > Setting("Flame Shock Mana") and Target.TTD > 8  and not Debuff.FlameShock:Exist(Target) and Target.CreatureType ~= "Totem" and Target.CreatureType ~= "Elemental" and Target.Facing then
    -- 		if Spell.FlameShock:Cast(Target) then
    -- 			return
    -- 		end
    -- 	end
    -- -- Stormstrike
    --     if Setting("Stormstrike") and Target and Target.ValidEnemy and Target.Distance <= 5 then
    --        if Spell.Stormstrike:Cast(Target) then
    -- 			return true
    -- 		end
    -- 	end
    -- 	-- Autoattack
    --     if  Target and Target.ValidEnemy and Target.Distance <= 5 then
    --         StartAttack()
    -- 	end
    -- 	--Lightning Bolt
    -- 	if Setting("Lightning Bolt") and Target and Target.ValidEnemy and Target.Distance >= 20 and not Player.Moving and Target.Facing and not Spell.LightningBolt:LastCast() then
    -- 		if Spell.LightningBolt:Cast(Target, 1) then
    -- 		return true
    -- 		end
    -- 	end
end
