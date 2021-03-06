local RubimRH = LibStub("AceAddon-3.0"):GetAddon("RubimRH")

local addonName, addonTable = ...;
-- HeroLib
local HL = HeroLib;
local Cache = HeroCache;
local Unit = HL.Unit;
local Player = Unit.Player;
local Target = Unit.Target;
local Spell = HL.Spell;
local Item = HL.Item;
-- Spell Localization
local S = RubimRH.Spell[104]
-- Optional debug to chat window
local PrintDebug = false
-- Item localization // Declaration
if not Item.Druid then Item.Druid = {} end
Item.Druid.Guardian = { EkowraithCreatorofWorlds = Item(137015, {5}), LuffaWrappings = Item(137056, {9}) }
local I = Item.Druid.Guardian
-- Range array declaration
local RangeMod = S.BalanceAffinity:IsAvailable() and true or false
local R = {
	Moonfire = (RangeMod) and 43 or 40,
	Mangle = (RangeMod) and 8 or "Melee",
	Thrash = (RangeMod) and 11 or 8,
	Swipe = (RangeMod) and 11 or 8,
	Maul = (RangeMod) and 8 or "Melee",
	Pulverize = (RangeMod) and 8 or "Melee",
	SkullBash = (RangeMod) and 13 or 10 }
-- Keep track of whether or not we're tanking
local IsTanking = false

local function Bear()
	--- Defensives / Healing

	-- Bristling Fur
	if S.BristlingFur:IsReady()
			and (Player:NeedMinorHealing() or Player:NeedMajorHealing()) then
		return S.BristlingFur:Cast()
	end

	-- Survival Instincts
	if S.SurvivalInstincts:ChargesFractional() >= 1
			and not Player:Buff(S.Barkskin)
			and not Player:Buff(S.SurvivalInstincts)
			and Player:NeedPanicHealing() then
		return S.Berserking:Cast()
	end

	-- TODO: Fix texture after GGLoader properly updates the Barkskin pixels
	-- Barkskin
	if S.Barkskin:IsReady()
			and not Player:Buff(S.SurvivalInstincts)
			and not Player:Buff(S.Barkskin)
			and Player:NeedMajorHealing() then
		return S.Barkskin:Cast()
	end

	-- Ironfur
	if S.Ironfur:IsReady()
			and Player:BuffRemains(S.Ironfur) <= Player:GCD()
			and (IsTanking or Player:NeedMinorHealing()) then
		return S.Ironfur:Cast()
	end

	-- Frenzied Regeneration
	local FrenziedRegenerationHeal = (Player:Buff(S.GuardianOfEluneBuff)) and 21 or 18
	local FrenziedOverHeal = (FrenziedRegenerationHeal + Player:HealthPercentage() >= 100) and true or false
	if S.FrenziedRegeneration:IsReady()
		and not FrenziedOverHeal
		and (Player:NeedMinorHealing() or Player:NeedMajorHealing() or Player:NeedPanicHealing()) then
		return S.FrenziedRegeneration:Cast()
	end

	--- Main Damage Rotation

	-- Moonfire
	if Target:DebuffRemains(S.MoonfireDebuff) <= Player:GCD()
			and S.Moonfire:IsReadyMorph(R.Moonfire) then
		return S.Moonfire:Cast()
	end

	-- Thrash
	if S.Thrash:IsReadyMorph(R.Thrash, true)
			and Target:DebuffStack(S.ThrashDebuff) < 3 then
		return S.Thrash:Cast()
	end

	-- Pulverize
	if Target:DebuffStack(S.ThrashDebuff) == 3
			and S.Pulverize:IsReadyMorph(R.Pulverize) then
		return S.Pulverize:Cast()
	end

	-- Mangle
	if S.Mangle:IsReadyMorph(R.Mangle) then
		return S.Mangle:Cast()
	end

	-- Thrash
	if S.Thrash:IsReadyMorph(R.Thrash, true) then
		return S.Thrash:Cast()
	end

	-- Moonfire
	if S.Moonfire:IsReadyMorph(R.Moonfire)
			and Player:Buff(S.GalacticGuardianBuff) then
		return S.Moonfire:Cast()
	end

	-- Maul
	if S.Maul:IsReady(R.Maul)
			and Player:Rage() >= 90 then
		return S.Maul:Cast()
	end

	-- Swipe -> Requires IsReadyMorph
	if S.Swipe:IsReadyMorph(R.Swipe, true) then
		return S.Swipe:Cast()
	end
end

-- TODO: Cat AoE
local function Cat()
	local CatWeave = S.FeralAffinity:IsAvailable()
	if CatWeave then
		if Player:ComboPoints() == 5
				and Target:DebuffRemains(S.Rip) <= Player:GCD() * 5
				and S.Rip:IsReadyMorph("Melee") then
			return S.Rip:Cast()
		end

		if Player:ComboPoints() == 5
				and Target:DebuffRemains(S.Rip) >= Player:GCD() * 5
				and S.FerociousBite:IsReadyMorph("Melee") then
			return S.FerociousBite:Cast()
		end

		if Player:ComboPoints() <= 5
				and Target:DebuffRemains(S.RakeDebuff) <= Player:GCD() then
			return S.Rake:Cast()
		end
	end

	if S.ThrashCat:IsReadyMorph("Melee")
			and Target:DebuffRemains(S.ThrashCat) <= Player:GCD() then
		return S.ThrashCat:Cast()
	end

	return S.Shred:Cast()
end

local function Moonkin()
	-- Base cast range for Balance Affinity is 43 yards on all abilities
	local R = 43

	-- Moonfire
	if S.Moonfire:IsReadyMorph(R.Moonfire)
			and (Target:DebuffRemains(S.MoonfireDebuff) <= Player:GCD() or Player:Buff(S.GalacticGuardianBuff)) then
		return S.Moonfire:Cast()
	end

	-- Sunfire
	if S.Sunfire:IsReadyMorph(R.Moonfire)
			and Target:DebuffRemains(S.SunfireDebuff) <= Player:GCD() then
		return S.Sunfire:Cast()
	end

	-- Stationary damage rotation
	if not Player:IsMoving() then

		-- Starsurge
		if S.Starsurge:IsReadyMorph(R.Moonfire)
				and not Player:Buff(S.LunarEmpowerment)
				and not Player:Buff(S.SolarEmpowerment) then
			return S.Starsurge:Cast()
		end

		-- Lunar Strike
		if S.LunarStrike:IsReadyMorph(R.Moonfire) and
				Player:Buff(S.LunarEmpowerment) then
			return S.LunarStrike:Cast()
		end

		-- Wrath spam
		if S.Wrath:IsReadyMorph(R.Moonfire) then return S.Wrath:Cast() end
	else
		-- Moonfire spam on the move
		if S.Moonfire:IsReadyMorph(R.Moonfire) then return S.Moonfire:Cast() end
	end

	return nil
end

local function UpdateVars()
	-- Check if we're tanking
	IsTanking = Player:IsTankingAoE(8) or Player:IsTanking(Target)
	-- Determine if the player is using the Balance affinity
	RangeMod = S.BalanceAffinity:IsAvailable() and true or false
	-- Reevaluate ranges -> If player's spec has changed to Balance Affinity
	R.Moonfire = (RangeMod) and 43 or 40
	R.Mangle = (RangeMod) and 8 or "Melee"
	R.Thrash = (RangeMod) and 11 or 8
	R.Swipe = (RangeMod) and 11 or 8
	R.Maul = (RangeMod) and 8 or "Melee"
	R.Pulverize = (RangeMod) and 8 or "Melee"
	R.SkullBash = (RangeMod) and 13 or 10
	-- Adjust Thrash range if player has Luffa Wrappings equipped 
	R.Thrash = (I.LuffaWrappings:IsEquipped()) and R.Thrash * 1.25 or R.Thrash
	-- Update enemies within ability ranges
	HL.GetEnemies("Melee") -- 5 Yards
	HL.GetEnemies(R.Moonfire) -- 40-43 Yards
	HL.GetEnemies(R.Mangle) -- 5-8 Yards
	HL.GetEnemies(R.Thrash, true) -- 8-11 Yards
	HL.GetEnemies(R.SkullBash) -- 10-13 Yards
end    

local function APL()
	UpdateVars()

	if not Player:AffectingCombat() then return 0, 462338 end

	-- TODO: Mighty Bash, Typhoon, Entanglement -> GGLoader textures not working

	local Form = GetShapeshiftForm("player")
	if Form == 1 and Bear() ~= nil then 
		return Bear() 
	elseif Form == 2 and Cat() ~= nil 
		then return Cat()
	elseif Form == 4 and Moonkin() ~= nil then 
		return Moonkin() 
	end

	return 0, 135328
end

RubimRH.Rotation.SetAPL(104, APL);

local function PASSIVE()
	return RubimRH.Shared()
end

RubimRH.Rotation.SetPASSIVE(104, PASSIVE);