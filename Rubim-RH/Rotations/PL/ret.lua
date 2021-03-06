--- Localize Vars
local addonName, addonTable = ...;
-- HeroLib
local HL = HeroLib;
local Cache = HeroCache;
local Unit = HL.Unit;
local Player = Unit.Player;
local Target = Unit.Target;
local Spell = HL.Spell;
local Item = HL.Item;
-- Lua
local pairs = pairs;
local RubimRH = LibStub("AceAddon-3.0"):GetAddon("RubimRH")

--- APL Local Vars
local S = RubimRH.Spell[70]
local G = RubimRH.Spell[1] -- General Skills

S.AvengingWrath.TextureSpellID = { 55748 }
S.Crusade.TextureSpellID = { 55748 }


-- Items
if not Item.Paladin then
	Item.Paladin = {};
end
Item.Paladin.Retribution = {
	-- Legendaries
	JusticeGaze = Item(137065, { 1 }),
	LiadrinsFuryUnleashed = Item(137048, { 11, 12 }),
	WhisperoftheNathrezim = Item(137020, { 15 }),
	AshesToDust = Item(144358, { 3 })
}
local I = Item.Paladin.Retribution;
-- Rotation Var

-- APL Action Lists (and Variables)
local function Judged()
	return Target:Debuff(S.JudgmentDebuff) or S.Judgment:CooldownRemains() > Player:GCD() * 2;
end

local T202PC, T204PC = HL.HasTier("T20");
local T212PC, T214PC = HL.HasTier("T21");

local function Cooldowns()
	
	if RubimRH.CDsON() and S.HolyWrath:IsReady() then
		return S.HolyWrath:Cast()
	end
	--actions.cooldowns+=/shield_of_vengeance
	--actions.cooldowns+=/avenging_wrath,if=buff.inquisition.up|!talent.inquisition.enabled
	if RubimRH.CDsON() and S.AvengingWrath:IsReady() and (Player:Buff(S.Inquisition) or not S.Inquisition:IsAvailable()) then
		return S.AvengingWrath:Cast()
	end
	--actions.cooldowns+=/crusade,if=holy_power>=4
	if RubimRH.CDsON() and S.Crusade:IsReady() and Player:HolyPower() >= 4 then
		return S.Crusade:Cast()
	end

	--actions.cooldowns+=/lights_judgment,if=spell_targets.lights_judgment>=2|(!raid_event.adds.exists|raid_event.adds.in>75)
	if RubimRH.CDsON() and G.LightsJudgment:IsReady() and Cache.EnemiesCount[8] >= 2 then
		return G.LightsJudgment:Cast()
	end

	--actions.cooldowns+=/potion,if=(buff.bloodlust.react|buff.avenging_wrath.up|buff.crusade.up&buff.crusade.remains<25|target.time_to_die<=40)
	if RubimRH.PotionON() and It.OldWar:IsReady() and (Player:HasHeroism() or Player:Buff(S.AvengingWrath) or (Player:Buff(S.Crusade) and Player:BuffRemains(S.Crusade) < 25) or Target:TimeToDie() <= 40) then
	return G.PotionSpell:Cast()
	end
	
end


local varDSCastable
local function Finishers()


 --- Azerite should work
 -- actions.finishers=variable,name=ds_castable,      value=spell_targets.divine_storm>=3|!talent.righteous_verdict.enabled&talent.divine_judgment.enabled&spell_targets.divine_storm>=2|azerite.divine_right.enabled&target.health.pct<=20&buff.divine_right.down
    varDSCastable = RubimRH.AoEON() and (Cache.EnemiesCount[8] >= 3 or (not S.RighteousVerdict:IsAvailable() and S.DivineJudgement:IsAvailable() and Cache.EnemiesCount[8] >= 2) or (RubimRH.azerite(5, 453) or RubimRH.azerite(1, 453) or RubimRH.azerite(3, 453) and Target:HealthPercentage() <= 20 and not Player:Buff(S.DivineStormBuffAzerite)))

	--actions.finishers+=/inquisition,if=buff.inquisition.down|buff.inquisition.remains<5&holy_power>=3|talent.execution_sentence.enabled&cooldown.execution_sentence.remains<10&buff.inquisition.remains<15|
	--cooldown.avenging_wrath.remains<15&buff.inquisition.remains<20&holy_power>=3
	if (S.Inquisition:IsAvailable() and S.Inquisition:IsReady()) and (not Player:Buff(S.Inquisition)
			or Player:BuffRemains(S.Inquisition) < 5 and Player:HolyPower() >= 3
			or S.ExecutionSentence:IsAvailable() and S.ExecutionSentence:CooldownRemains() < 10 and Player:BuffRemains(S.Inquisition) < 15 or S.AvengingWrath:CooldownRemains() < 15 and Player:BuffRemains(S.Inquisition) < 20 and Player:HolyPower() >= 3) then
		return S.Inquisition:Cast()
	end

	--actions.finishers+=/execution_sentence,if=spell_targets.divine_storm<=3&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)
	if S.ExecutionSentence:IsReady("Melee") and (Target:IsInRange(20) and Cache.EnemiesCount[8] <= 3 and ((not S.Crusade:IsAvailable() or S.Crusade:CooldownRemains() > Player:GCD() * 2) or not RubimRH.CDsON())) then
		return S.ExecutionSentence:Cast()
	end

	--actions.finishers+=/divine_storm,if=variable.ds_castable&buff.divine_purpose.react
	if S.DivineStorm:IsReady("Melee") and varDSCastable and Player:Buff(S.DivinePurposeBuff) then
		return S.DivineStorm:Cast()
	end

	--actions.finishers+=/divine_storm,if=variable.ds_castable&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)
	if S.DivineStorm:IsReady("Melee") and (varDSCastable and ((not S.Crusade:IsAvailable() or S.Crusade:CooldownRemains() > Player:GCD() * 2) or not RubimRH.CDsON())) then
		return S.DivineStorm:Cast()
	end

	--actions.finishers+=/templars_verdict,if=buff.divine_purpose.react&(!talent.execution_sentence.enabled|cooldown.execution_sentence.remains>gcd)
	if S.TemplarsVerdict:IsReady("Melee") and (Player:Buff(S.DivinePurposeBuff) and (not S.ExecutionSentence:IsAvailable() or S.ExecutionSentence:CooldownRemains() > Player:GCD())) then
		return S.TemplarsVerdict:Cast()
	end

	--actions.finishers+=/templars_verdict,if=(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)&(!talent.execution_sentence.enabled|buff.crusade.up&buff.crusade.stack<10|cooldown.execution_sentence.remains>gcd*2)
	if S.TemplarsVerdict:IsReady("Melee") and ((not S.Crusade:IsAvailable() or S.Crusade:CooldownRemains() >= Player:GCD() * 2)
			and (not S.ExecutionSentence:IsAvailable() or Player:Buff(S.Crusade) and Player:BuffStack(S.Crusade) < 10 or S.ExecutionSentence:CooldownRemains() > Player:GCD() * 2)) then
		return S.TemplarsVerdict:Cast()
	end
end

local HoW
local function Generators()

--actions.generators = variable, name=HoW, value = (!talent.hammer_of_wrath.enabled|target.health.pct>=20&(buff.avenging_wrath.down|buff.crusade.down))
	HoW = (not S.HammerofWrath:IsAvailable() or (Target:Exists() and Target:HealthPercentage() >= 20) and (not Player:Buff(S.AvengingWrath) or not Player:Buff(S.Crusade)))

	--actions.generators+ = /call_action_list, name = finishers, if = holy_power>=5
	if Player:HolyPower() >= 5 and Finishers() ~= nil then
		return Finishers()
	end

	--actions.generators+ = /wake_of_ashes, if= (holy_power<=0|holy_power = 1&cooldown.blade_of_justice.remains>gcd)
	if S.WakeofAshes:IsReady() and Cache.EnemiesCount["Melee"] >= 1 and (Player:HolyPower() <= 0 or Player:HolyPower() == 1 and S.BladeofJustice:CooldownRemains() > Player:GCD()) then
		return S.WakeofAshes:Cast()
	end

	--actions.generators+ =/blade_of_justice, if = holy_power<=2|(holy_power = 3&(cooldown.hammer_of_wrath.remains>gcd*2|variable.HoW))
	if S.BladeofJustice:IsReady("Melee") and (Player:HolyPower() <= 2 or (Player:HolyPower() == 3 and (S.HammerofWrath:CooldownRemains() > Player:GCD() * 2 or HoW))) then
		return S.BladeofJustice:Cast()
	end

	--actions.generators+ = /judgment, if =holy_power<=2|(holy_power<=4&(cooldown.blade_of_justice.remains>gcd*2|variable.HoW))
	if S.Judgment:IsReady(30) and (Player:HolyPower() <= 2 or (Player:HolyPower() <= 4 and (S.BladeofJustice:CooldownRemains() > Player:GCD() * 2 or HoW))) then
		return S.Judgment:Cast()
	end

	--actions.generators+ =/hammer_of_wrath, if = holy_power<=4
	if S.HammerofWrath:IsReady("Melee") and Player:HolyPower() <= 4 then
		return S.HammerofWrath:Cast()
	end

	--actions.generators+ = /consecration, if = holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power = 4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2
	if (S.Consecration:IsAvailable() and S.Consecration:IsReady() and RubimRH.lastMoved() > 0.2) and (Player:HolyPower() <= 2 or Player:HolyPower() <= 3 and S.BladeofJustice:CooldownRemains() > Player:GCD() * 2 or
			Player:HolyPower() == 4 and S.BladeofJustice:CooldownRemains() > Player:GCD() * 2 and S.Judgment:CooldownRemains() > Player:GCD() * 2) then
		return S.Consecration:Cast()
	end

	--actions.generators+ = /call_action_list, name = finishers, if = talent.hammer_of_wrath.enabled&(target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up)&(buff.divine_purpose.up|buff.crusade.stack<10)
	if Finishers() ~= nil
			and (S.HammerofWrath:IsAvailable()
				and (((Target:Exists() and Target:HealthPercentage() <= 20) or Player:Buff(S.AvengingWrath) or Player:Buff(S.Crusade))
				and (Player:Buff(S.DivinePurposeBuff)
				or Player:BuffStack(S.Crusade) < 10))) then
		return Finishers()
	end

	--actions.generators+= /crusader_strike, if = cooldown.crusader_strike.charges_fractional>=1.75&(holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power = 4&cooldown.blade_of_justice.remains>gcd*2&
	--cooldown.judgment.remains>gcd*2&cooldown.consecration.remains>gcd*2)
	if S.CrusaderStrike:IsReady("Melee") and (S.CrusaderStrike:ChargesFractional() >= 1.75 and
			(Player:HolyPower() <= 2 or Player:HolyPower() <= 3 and S.BladeofJustice:CooldownRemains() > Player:GCD() * 2 or Player:HolyPower() == 4 and S.BladeofJustice:CooldownRemains() > Player:GCD() * 2)) then
		return S.CrusaderStrike:Cast()
	end

	--actions.generators+ = /call_action_list, name = finishers
	if Finishers() ~= nil then
		return Finishers()
	end

	--actions.generators+ = /crusader_strike, if = holy_power<=4
	if S.CrusaderStrike:IsReady("Melee") and Player:HolyPower() <= 4 then
		return S.CrusaderStrike:Cast()
	end

	--actions.generators+ = /arcane_torrent, if= (debuff.execution_sentence.up|(talent.hammer_of_wrath.enabled&(target.health.pct>=20|buff.avenging_wrath.down|buff.crusade.down))|!talent.execution_sentence.enabled|!talent.hammer_of_wrath.enabled)&holy_power<=4
end

local function Opener()

	--actions.opener =  /sequence, if = talent.wake_of_ashes.enabled&talent.crusade.enabled&talent.execution_sentence.enabled&!talent.hammer_of_wrath.enabled,
	--name = wake_opener_ES_CS:shield_of_vengeance:blade_of_justice:judgment:crusade:templars_verdict:wake_of_ashes:templars_verdict:crusader_strike:execution_sentence
	if S.WakeofAshes:IsAvailable() and S.Crusade:IsAvailable() and S.ExecutionSentence:IsAvailable() and not S.HammerofWrath:IsAvailable() then
		RubimRH.castSpellSequence = {
			S.BladeofJustice,
			S.Judgment,
			S.Crusade,
			S.TemplarsVerdict,
			S.WakeofAshes,
			S.TemplarsVerdict,
			S.CrusaderStrike,
			S.ExecutionSentence,
		}
	end

	--actions.opener+ = /sequence, if = talent.wake_of_ashes.enabled&talent.crusade.enabled&!talent.execution_sentence.enabled&!talent.hammer_of_wrath.enabled,
	--name = wake_opener_CS:shield_of_vengeance:blade_of_justice:judgment:crusade:templars_verdict:wake_of_ashes:templars_verdict:crusader_strike:templars_verdict
	if S.WakeofAshes:IsAvailable() and S.Crusade:IsAvailable() and not S.ExecutionSentence:IsAvailable() and not S.HammerofWrath:IsAvailable() then
		RubimRH.castSpellSequence = {
			S.BladeofJustice,
			S.Judgment,
			S.Crusade,
			S.TemplarsVerdict,
			S.WakeofAshes,
			S.TemplarsVerdict,
			S.CrusaderStrike,
			S.TemplarsVerdict,
		}
	end

	--actions.opener+ = /sequence, if = talent.wake_of_ashes.enabled&talent.crusade.enabled&talent.execution_sentence.enabled&talent.hammer_of_wrath.enabled,
	--name = wake_opener_ES_HoW:shield_of_vengeance:blade_of_justice:judgment:crusade:templars_verdict:wake_of_ashes:templars_verdict:hammer_of_wrath:execution_sentence
	if S.WakeofAshes:IsAvailable() and S.Crusade:IsAvailable() and S.ExecutionSentence:IsAvailable() and S.HammerofWrath:IsAvailable() then
		RubimRH.castSpellSequence = {
			S.BladeofJustice,
			S.Judgment,
			S.Crusade,
			S.TemplarsVerdict,
			S.WakeofAshes,
			S.TemplarsVerdict,
			S.HammerofWrath,
			S.ExecutionSentence,
		}
	end
	--actions.opener+ = /sequence, if = talent.wake_of_ashes.enabled&talent.crusade.enabled&!talent.execution_sentence.enabled&talent.hammer_of_wrath.enabled,
	--name = wake_opener_HoW:shield_of_vengeance:blade_of_justice:judgment:crusade:templars_verdict:wake_of_ashes:templars_verdict:hammer_of_wrath:templars_verdict
	if S.WakeofAshes:IsAvailable() and S.Crusade:IsAvailable() and not S.ExecutionSentence:IsAvailable() and S.HammerofWrath:IsAvailable() then
		RubimRH.castSpellSequence = {
			S.BladeofJustice,
			S.Judgment,
			S.Crusade,
			S.TemplarsVerdict,
			S.WakeofAshes,
			S.TemplarsVerdict,
			S.HammerofWrath,
			S.TemplarsVerdict,
		}
	end
	--actions.opener+ = /sequence, if = talent.wake_of_ashes.enabled&talent.inquisition.enabled, n
	--ame = wake_opener_Inq:shield_of_vengeance:blade_of_justice:judgment:inquisition:avenging_wrath:wake_of_ashes
	if S.WakeofAshes:IsAvailable() and S.Inquisition:IsAvailable() then
		RubimRH.castSpellSequence = {
			S.BladeofJustice,
			S.Judgment,
			S.Inquisition,
			S.AvengingWrath,
			S.WakeofAshes,
		}
	end


	if RubimRH.CastSequence() ~= nil and RubimRH.CastSequence():IsReady() then
		return RubimRH.CastSequence():Cast()
	end
end

local function APL()
	--Area Enemies
	HL.GetEnemies("Melee");
	HL.GetEnemies(8, true);
	HL.GetEnemies(10, true);
	HL.GetEnemies(20, true);

	if not Player:AffectingCombat() then
		return 0, 462338
	end

	if RubimRH.config.Spells[1].isActive and S.JusticarsVengeance:IsReady() and Target:IsInRange("Melee") then
		-- Divine Purpose
		if Player:HealthPercentage() <= RubimRH.db.profile[70].justicarglory and Player:Buff(S.DivinePurposeBuff) then
			return S.JusticarsVengeance:Cast()
		end
		-- Regular
		if Player:HealthPercentage() <= RubimRH.db.profile[70].justicarglory - 5 and Player:HolyPower() >= 5 then
			return S.JusticarsVengeance:Cast()
		end
	end

	--    if RubimRH.config.Spells[1].isActive and S.WorldofGlory:IsReady() then
	-- Divine Purpose
	--        if Player:HealthPercentage() <= RubimRH.db.profile.Paladin.Retribution.justicarglory * 100 and Player:Buff(S.DivinePurposeBuff) then
	--            return S.JusticarsVengeance:Cast()
	--        end
	--        -- Regular
	--        if Player:HealthPercentage() <= RubimRH.db.profile.Paladin.Retribution.justicarglory * 100 - 5 and Player:HolyPower() >= 3 then
	--            return S.JusticarsVengeance:Cast()
	--        end
	--    end

	if RubimRH.config.Spells[2].isActive and S.FlashOfLight:IsReady() and Player:BuffStack(S.SelfLessHealerBuff) == 4 and RubimRH.db.profile[70].flashoflight then
		return S.FlashOfLight:Cast()
	end

	--# Executed every time the actor is available.
	--actions=auto_attack
	--actions+=/rebuke
	--actions+=/call_action_list,name=opener,if=time<2
	if HL.CombatTime() < 2 and Opener~= nil and RubimRH.CDsON() and Target:IsInRange("Melee") then
		return Opener()
	end

	--actions+=/call_action_list,name=cooldowns
	if Cooldowns() ~= nil then
		return Cooldowns()
	end

	--actions+=/call_action_list,name=generators
	if Generators() ~= nil then
		return Generators()
	end
	--Nothing to CAST
	return 0, 135328
end
RubimRH.Rotation.SetAPL(70, APL);

local function PASSIVE()

end

RubimRH.Rotation.SetPASSIVE(70, PASSIVE);

--actions.finishers=variable,name=ds_castable,value=spell_targets.divine_storm>=3|talent.divine_judgment.enabled&spell_targets.divine_storm>=2|azerite.divine_right.enabled&target.health.pct<=20&buff.divine_right.down
--actions.finishers+=/inquisition,if=buff.inquisition.down|buff.inquisition.remains<5&holy_power>=3|talent.execution_sentence.enabled&cooldown.execution_sentence.remains<10&buff.inquisition.remains<15|cooldown.avenging_wrath.remains<15&buff.inquisition.remains<20&holy_power>=3
--actions.finishers+=/execution_sentence,if=spell_targets.divine_storm<=3&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)
--actions.finishers+=/divine_storm,if=variable.ds_castable&buff.divine_purpose.react
--actions.finishers+=/divine_storm,if=variable.ds_castable&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)
--actions.finishers+=/templars_verdict,if=buff.divine_purpose.react&(!talent.execution_sentence.enabled|cooldown.execution_sentence.remains>gcd)
--actions.finishers+=/templars_verdict,if=(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2)&(!talent.execution_sentence.enabled|buff.crusade.up&buff.crusade.stack<10|cooldown.execution_sentence.remains>gcd*2)

--actions.generators = variable, name=HoW, value = (!talent.hammer_of_wrath.enabled|target.health.pct>=20&(buff.avenging_wrath.down|buff.crusade.down))
--actions.generators+ = /call_action_list, name = finishers, if = holy_power>=5
--actions.generators+ = /wake_of_ashes, if= (!raid_event.adds.exists|raid_event.adds. in >20)&(holy_power<=0|holy_power = 1&cooldown.blade_of_justice.remains>gcd)
--actions.generators+ =/blade_of_justice, if = holy_power<=2|(holy_power = 3&(cooldown.hammer_of_wrath.remains>gcd*2|variable.HoW))
--actions.generators+ = /judgment, if =holy_power<=2|(holy_power<=4&(cooldown.blade_of_justice.remains>gcd*2|variable.HoW))
--actions.generators+ =/hammer_of_wrath, if = holy_power<=4
--actions.generators+ = /consecration, if = holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power = 4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2
--actions.generators+ = /call_action_list, name = finishers, if = talent.hammer_of_wrath.enabled&(target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up)&(buff.divine_purpose.up|buff.crusade.stack<10)
--actions.generators+= /crusader_strike, if = cooldown.crusader_strike.charges_fractional>=1.75&(holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power = 4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2&cooldown.consecration.remains>gcd*2)
--actions.generators+ = /call_action_list, name = finishers
--actions.generators+ = /crusader_strike, if = holy_power<=4
--actions.generators+ = /arcane_torrent, if= (debuff.execution_sentence.up|(talent.hammer_of_wrath.enabled&(target.health.pct>=20|buff.avenging_wrath.down|buff.crusade.down))|!talent.execution_sentence.enabled|!talent.hammer_of_wrath.enabled)&holy_power<=4

--actions.opener =  /sequence,   if = talent.wake_of_ashes.enabled&talent.crusade.enabled&talent.execution_sentence.enabled&!talent.hammer_of_wrath.enabled, name = wake_opener_ES_CS:shield_of_vengeance:blade_of_justice:judgment:crusade:templars_verdict:wake_of_ashes:templars_verdict:crusader_strike:execution_sentence
--actions.opener+ = /sequence, if = talent.wake_of_ashes.enabled&talent.crusade.enabled&!talent.execution_sentence.enabled&!talent.hammer_of_wrath.enabled, name = wake_opener_CS:shield_of_vengeance:blade_of_justice:judgment:crusade:templars_verdict:wake_of_ashes:templars_verdict:crusader_strike:templars_verdict
--actions.opener+ = /sequence, if = talent.wake_of_ashes.enabled&talent.crusade.enabled&talent.execution_sentence.enabled&talent.hammer_of_wrath.enabled, name = wake_opener_ES_HoW:shield_of_vengeance:blade_of_justice:judgment:crusade:templars_verdict:wake_of_ashes:templars_verdict:hammer_of_wrath:execution_sentence
--actions.opener+ = /sequence, if = talent.wake_of_ashes.enabled&talent.crusade.enabled&!talent.execution_sentence.enabled&talent.hammer_of_wrath.enabled, name = wake_opener_HoW:shield_of_vengeance:blade_of_justice:judgment:crusade:templars_verdict:wake_of_ashes:templars_verdict:hammer_of_wrath:templars_verdict
--actions.opener+ = /sequence, if = talent.wake_of_ashes.enabled&talent.inquisition.enabled, name = wake_opener_Inq:shield_of_vengeance:blade_of_justice:judgment:inquisition:avenging_wrath:wake_of_ashes


