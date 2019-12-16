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

DMW.Tables.HealerStuff = {}
local CalcHeals = DMW.Tables.HealerStuff

function avg(a, b) return (a + b) / 2 end

CalcHeals.spellData = {}

CalcHeals.spellData["ChainHeal"] = {
    coeff = 2.5 / 3.5,
    levels = {40, 46, 54},
    averages = {
        {avg(320, 368), avg(322, 371), avg(325, 373), avg(327, 376), avg(330, 378), avg(332, 381)},
        {avg(405, 465), avg(407, 468), avg(410, 471), avg(413, 474), avg(416, 477), avg(419, 479)},
        {avg(551, 629), avg(554, 633), avg(557, 636), avg(560, 639), avg(564, 643), avg(567, 646)}
    }
}
CalcHeals.spellData["HealingWave"] = {
    levels = {1, 6, 12, 18, 24, 32, 40, 48, 56, 60},
    averages = {
        {avg(34, 44), avg(34, 45), avg(35, 46), avg(36, 47)},
        {avg(64, 78), avg(65, 79), avg(66, 80), avg(67, 81), avg(68, 82), avg(69, 83)},
        {avg(129, 155), avg(130, 157), avg(132, 158), avg(133, 160), avg(135, 161), avg(136, 163)},
        {avg(268, 316), avg(270, 319), avg(272, 321), avg(274, 323), avg(277, 326), avg(279, 328)},
        {avg(376, 440), avg(378, 443), avg(381, 446), avg(384, 449), avg(386, 451), avg(389, 454)},
        {avg(536, 622), avg(539, 626), avg(542, 629), avg(545, 632), avg(549, 636), avg(552, 639)},
        {avg(740, 854), avg(743, 858), avg(747, 862), avg(751, 866), avg(755, 870), avg(759, 874)},
        {avg(1017, 1167), avg(1021, 1172), avg(1026, 1177), avg(1031, 1182), avg(1035, 1186), avg(1040, 1191)},
        {avg(1367, 1561), avg(1372, 1567), avg(1378, 1572), avg(1383, 1578), avg(1389, 1583)}, {avg(1620, 1850)}
    }
}
CalcHeals.spellData["LesserHealingWave"] = {
    coeff = 1.5 / 3.5,
    levels = {20, 28, 36, 44, 52, 60},
    averages = {
        {avg(162, 186), avg(163, 188), avg(165, 190), avg(167, 192), avg(168, 193), avg(170, 195)},
        {avg(247, 281), avg(249, 284), avg(251, 286), avg(253, 288), avg(255, 290), avg(257, 29)},
        {avg(337, 381), avg(339, 384), avg(342, 386), avg(344, 389), avg(347, 391), avg(349, 394)},
        {avg(458, 514), avg(461, 517), avg(464, 520), avg(467, 523), avg(470, 526), avg(473, 529)},
        {avg(631, 705), avg(634, 709), avg(638, 713), avg(641, 716), avg(645, 720), avg(649, 723)}, {avg(832, 928)}
    }
}

function CalcHeals.getBaseHealAmount(spellData, Spell, Rank)
    spellData = spellData[Spell]
    local average = spellData.averages[Rank]
    if type(average) == "number" then return average end
    local requiresLevel = spellData.levels[Rank]
    return average[min(DMW.Player.Level - requiresLevel + 1, #average)]
end

function CalcHeals.calculateGeneralAmount(level, amount, spellPower, spModifier, healModifier)
    local penalty = level > 20 and 1 or (1 - ((20 - level) * 0.0375))
    spellPower = spellPower * penalty
    return healModifier * (amount + (spellPower * spModifier))
end

function CalcHeals.predictHealAmount(Spell, Rank, Unit, returnTable)
    -- Spell:HealCommFix(Rank)
    local amountHealed, amountOverhealed
    local healAmount = CalcHeals.getBaseHealAmount(CalcHeals.spellData, Spell, Rank)
    local healModifier, spModifier = 1, 1
    local PurificationIncrease = 0.02 * Talent.Purification.Rank
    local spellPower = GetSpellBonusHealing()
    local returnTable = returnTable or {}
    local function finalHealFunc(Unit, healAmount)
        local modifier = HealCommLib:GetHealModifier(Unit.GUID) or 1
        local finalHeal = healAmount * modifier
        local overhealAmount = Unit.HealthDeficit > finalHeal and 0 or (finalHeal - Unit.HealthDeficit)
        local finalFinalHeal = overhealAmount == 0 and finalHeal or Unit.HealthDeficit
        return finalFinalHeal, overhealAmount
    end
    healAmount = healAmount * (1 + PurificationIncrease)
    if Spell == "ChainHeal" then
        spellPower = spellPower * CalcHeals.spellData[Spell].coeff
    elseif Spell == "HealingWave" then
        local hwStacks = Buff.HealingWay:Stacks(Unit)
        if hwStacks > 0 then healAmount = healAmount * ((hwStacks * 0.06) + 1) end
        local castTime = Rank > 3 and 3 or Rank == 3 and 2.5 or Rank == 2 and 2 or 1.5
        spellPower = spellPower * (castTime / 3.5)
    elseif Spell == "LesserHealingWave" then
        spellPower = spellPower * CalcHeals.spellData[Spell].coeff
    end
    healAmount = CalcHeals.calculateGeneralAmount(CalcHeals.spellData[Spell].levels[Rank], healAmount, spellPower, spModifier, healModifier)
    local healAmountCeil = math.ceil(healAmount)
    amountHealed, amountOverhealed = finalHealFunc(Unit, healAmountCeil)
    if Setting("DownRanking") then
        if Rank > 0 then
            returnTable[Rank] = {amountHealed, amountOverhealed}
            Rank = Rank - 1
            CalcHeals.predictHealAmount(Spell, Rank, Unit, returnTable)
        end
            return returnTable
    else
        -- if amountOverhealed == 0 then
        -- print(Spell .. " R." .. Rank .. " will heal " .. Unit.Name .. " for " .. amountHealed .. " plus " .. amountOverhealed ..
        --   " overhealed ")
        -- end
        return amountHealed, amountOverhealed
    end
end

function CalcHeals.chainHealSim(Unit, Rank, returnTable)
    local chainTarget, chainTargetHPDeficit, ChainUnits, ChainUnitsCount, amountHealed, chainCount, amountOverhealed, healAmount,
          overhealAmount, firstHeal
    local usedPointers = {}
    local returnTable = returnTable or {}
    -- local HealCalc = CalcHeals.predictHealAmount("ChainHeal", Rank, Unit)
    -- local function finalHealFunc(Unit, HealCalc, link)
    --     local modifier = HealCommLib:GetHealModifier(Unit.GUID) or 1
    --     local finalHeal = HealCalc * modifier / (2 ^ (link - 1))
    --     local overhealAmount = Unit.HealthDeficit - finalHeal > 0 and 0 or (finalHeal - Unit.HealthDeficit)
    --     local finalFinalHeal = overhealAmount == 0 and finalHeal or Unit.HealthDeficit
    --     -- print(HealCalc,finalHeal,overhealAmount,finalFinalHeal)
    --     return finalFinalHeal, overhealAmount
    -- end
    --------------------------------Initial Heal there--------------------------------
    chainCount = 1
    local firstHeal, overhealAmount = CalcHeals.predictHealAmount("ChainHeal", Rank, Unit)
    amountHealed = firstHeal
    amountOverhealed = overhealAmount
    --------------------------------2nd Jump there--------------------------------
    ChainUnits, ChainUnitsCount = Unit:GetFriends(10, 100, true)
    if ChainUnitsCount > 1 then
        usedPointers[Unit.Pointer] = false
        local maxDeficit, secondTarget, maxSecondHeal
        for _, Friend in pairs(ChainUnits) do
            local modifier = HealCommLib:GetHealModifier(Friend.GUID) or 1
            local secondJumpHeal = firstHeal / 2 * modifier
            if not usedPointers[Friend.Pointer] and Friend.HealthDeficit > secondJumpHeal then
                if maxDeficit == nil or maxDeficit < Friend.HealthDeficit then
                    secondTarget = Friend
                    maxSecondHeal = secondJumpHeal
                    maxDeficit = Friend.HealthDeficit
                end
            end
        end
        if secondTarget ~= nil then
            chainCount = chainCount + 1
            amountHealed = amountHealed + maxSecondHeal
        end
        --------------------------------3rd Jump there--------------------------------
        ChainUnits, ChainUnitsCount = secondTarget:GetFriends(10, 100, true)
        if ChainUnitsCount > 1 then
            usedPointers[secondTarget.Pointer] = false
            local maxDeficit, lastTarget, maxThirdHeal
            for _, Friend in pairs(ChainUnits) do
                local modifier = HealCommLib:GetHealModifier(Friend.GUID) or 1
                local thirdJumpHeal = firstHeal / 2 * modifier
                if not usedPointers[Friend.Pointer] and Friend.HealthDeficit > thirdJumpHeal then
                    if not maxDeficit or maxDeficit < Friend.HealthDeficit then
                        lastTarget = Friend
                        maxDeficit = Friend.HealthDeficit
                        maxThirdHeal = thirdJumpHeal
                    end
                end
            end
            if lastTarget ~= nil then
                chainCount = chainCount + 1
                amountHealed = amountHealed + maxThirdHeal
            end
        end
    end
    -- if Setting("DownRanking") then
    --     if Rank > 0 then
    --         returnTable[Rank] = amountHealed, amountOverhealed, Unit, chainCount, firstHeal
    --         Rank = Rank - 1
    --         CalcHeals.chainHealSim(Unit, Rank, returnTable)
    --     else
    --         return returnTable
    --     end
    -- else
        return amountHealed
    -- end
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
    if Setting("Totem for Carries") then
        for k,v in pairs(DMW.Friends.Units) do
            if Spell.StoneskinTotem:CheckTotem(v) then
                count = count + 1
            end
        end
    end
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
    if count >= 3 and check then
        if not Setting("WF/Grace Weaving") and not Setting("WF/Tranquil Weaving") then
            -- GraceOfAirTotem
            if Spell.GraceofAirTotem:Known() and Setting("Grace Of Air Totem") and
                Spell.GraceofAirTotem:CheckTotem(Player, "GroundingTotem") then
                if Spell.GraceofAirTotem:Cast(Player) then return true end
            end
            -- WindfuryTotem
            if Spell.WindfuryTotem:Known() and Setting("Windfury Totem") and Spell.WindfuryTotem:CheckTotem(Player, "GroundingTotem") then
                if Spell.WindfuryTotem:Cast(Player) then return true end
            end
        end
        -- StrengthofEarthTotem
        if Spell.StrengthofEarthTotem:Known() and Setting("Strength Of Earth Totem") and
            Spell.StrengthofEarthTotem:CheckTotem(Player, "TremorTotem") then
            if Spell.StrengthofEarthTotem:Cast(Player) then return true end
        end
        if Spell.ManaSpringTotem:Known() and Setting("Mana Spring Totem") and Spell.ManaSpringTotem:CheckTotem(Player) then
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

        -- Stoneskin Totem for 2+ mobs Defensive
        if Target and Target.ValidEnemy and Setting("Stoneskin Totem") and Player.Combat and Spell.StoneskinTotem:CheckTotem(Player) then
            if Spell.StoneskinTotem:Cast(Player) then return true end
        end
        -- Stone Claw Totem for 2+ mobs
        if Target and Target.ValidEnemy and Setting("Ston Claw Totem") and Player.Combat and GetTotemInfo(2) == false and Enemy5YC > 1 then
            if Spell.StoneclawTotem:Cast(Player) then return true end
        end
        -- Magma Totem
        if Spell.MagmaTotem:Known() and Setting("Magma Totem") and Player.Combat and GetTotemInfo(1) == false and Enemy8YC > 1 and
            Player.PowerPct > Setting("Magma Totem Mana") and Target and Target.ValidEnemy and Target.TTD > 5 then
            if Spell.MagmaTotem:Cast(Player) then return true end
        end
        -- Fire Nova Totem
        if Spell.FireNovaTotem:Known() and Setting("Fire Nova Totem") and Target and Target.ValidEnemy and Player.Combat and
            Spell.FireNovaTotem:CheckTotem(Player) and Player.PowerPct > Setting("Fire Nova Totem Mana") and Target.TTD > 5 then
            if Spell.FireNovaTotem:Cast(Player) then return true end
        end
        -- Searing Totem
        if Setting("Searing Totem") and Player.Combat and GetTotemInfo(1) == false and Player.PowerPct > Setting("Searing Totem Mana") and
            Target and Target.ValidEnemy and Target.TTD > 10 then if Spell.FrostResistanceTotem:Cast(Player) then return true end end
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
local healTable = {}
local function Healsmartaf()
    for _, Friend in ipairs(Friends40Y) do
        local tempHeal = {}
        tempHeal.Pointer = Friend.Pointer
        tempHeal.HealthDeficit = Friend.HealthDeficit
    end
end

local function raidChainHeal()
    if HUD.Mana == 2 then
        local highestHealAmount, highestHealUnit
        for k, Unit in pairs(Friends40Y) do
            if Unit.HealthDeficit > 0 then
                -- amountHealed, amountOverhealed, Unit, chainCount, firstHeal
                local healReturn, overhealReturn, linksReturn = CalcHeals.chainHealSim(Unit, 3)
                if overhealReturn == 0 and linksReturn == 3 and (highestHealAmount == nil or healReturn > highestHealAmount) then
                    highestHealAmount = healReturn
                    highestHealUnit = Unit
                end
            end
        end
        if highestHealUnit ~= nil then
            if Spell.ChainHeal:Cast(highestHealUnit, 3) then return true end
        end
        -- local highestHealAmount, highestHealUnit
        -- for k, Unit in pairs(Friends40Y) do
        --     if Unit.HealthDeficit > 0 then
        --         local healReturn, overhealReturn, linksReturn = chainHealSim(Unit, 2)
        --         if overhealReturn == 0 and linksReturn == 3 and (highestHealAmount == nil or healReturn > highestHealAmount) then
        --             highestHealAmount = healReturn
        --             highestHealUnit = Unit
        --         end
        --     end
        -- end
        -- if highestHealUnit ~= nil then
        --     if Spell.ChainHeal:Cast(highestHealUnit, 2) then return true end
        -- end
    end
    local highestHealAmount, highestHealUnit
    for k, Unit in pairs(Friends40Y) do
        if Unit.HealthDeficit > 0 then
            -- amountHealed, amountOverhealed, Unit, chainCount, firstHeal
            local healReturn, overhealReturn, linksReturn = CalcHeals.chainHealSim(Unit, 1)
            if overhealReturn == 0 and linksReturn == 3 and (highestHealAmount == nil or healReturn > highestHealAmount) then
                highestHealAmount = healReturn
                highestHealUnit = Unit
            end
        end
    end
    if highestHealUnit ~= nil then
        if Spell.ChainHeal:Cast(highestHealUnit, 1) then return true end
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
    if HUD.Mana == 2 then
        local highestHealAmount, highestHealUnit
        for k, Unit in pairs(Friends40Y) do
            if Unit.HealthDeficit > 0 then
                local returnHeal, returnOverheal =  CalcHeals.predictHealAmount("HealingWave", 5, Unit)
                if returnOverheal == 0 and (highestHealAmount == nil or returnHeal > highestHealAmount) then
                    highestHealAmount = returnHeal
                    highestHealUnit = Unit
                end
            end
        end
        if highestHealUnit ~= nil then
            if Spell.HealingWave:Cast(highestHealUnit, 8) then return true end
        end
    end
    local highestHealAmount, highestHealUnit
    for k, Unit in pairs(Friends40Y) do
        if Unit.HealthDeficit > 0 then
            local returnHeal, returnOverheal =  CalcHeals.predictHealAmount("HealingWave", 5, Unit)
            if returnOverheal == 0 and (highestHealAmount == nil or returnHeal > highestHealAmount) then
                highestHealAmount = returnHeal
                highestHealUnit = Unit
            end
        end
    end
    if highestHealUnit ~= nil then
        if Spell.HealingWave:Cast(highestHealUnit, 5) then return true end
    end
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

    if Totems() then return true end
    -- if not Player.Casting then
        raidChainHeal()
        HWHeal()
    -- end
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
    checkParty()
    if Setting("Auto Purge") and Spell.Purge:IsReady() then
        for k, Unit in ipairs(Enemy30Y) do
            if Unit:Dispel(Spell.Purge) then
                if Spell.Purge:Cast(Unit) then
                    -- print(Unit.Name)
                    return true
                end
            end
        end
    end
    if not Player.Combat and not Player.Casting and not Player.Moving and Player.PowerPct <= 20 and not Player:AuraByName("Drink") and not Player.Eating then
        if Spell.ManaSpringTotem:IsReady() then Spell.ManaSpringTotem:Cast(Player) end
        RunMacro("drink")
        Player.Eating = true
        MovingState.Pause = DMW.Time + 2
        return true
    end
        if Player:AuraByName("Drink") then
            if Player.PowerPct >= 95 then RunMacroText("/stand") end
            return true
        end

    -- if resGroup() then return true end
    Totems()
    if not Player.Moving and Heal() then
        FiveSecondRuleTime = DMW.Time
        return
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
