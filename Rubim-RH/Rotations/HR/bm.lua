--- Localize Vars
-- Addon
local addonName, addonTable = ...;
-- HeroLib
local HL = HeroLib;
local Cache = HeroCache;
local Unit = HL.Unit;
local Player = Unit.Player;
local Pet = Unit.Pet;
local Target = Unit.Target;
local Spell = HL.Spell;
local Item = HL.Item;
-- Spells

local S = RubimRH.Spell[253]

-- Items
if not Item.Hunter then
    Item.Hunter = { };
end
Item.Hunter.BeastMastery = {
    -- Legendaries
    CalloftheWild = Item(137101, { 9 }),
    TheMantleofCommand = Item(144326, { 3 }),
    ParselsTongue = Item(151805, { 5 }),
    QaplaEredunWarOrder = Item(137227, { 8 }),
    SephuzSecret = Item(132452, { 11, 12 }),
    -- Trinkets
    ConvergenceofFates = Item(140806, { 13, 14 }),
    -- Potions
    PotionOfProlongedPower = Item(142117),
};
local I = Item.Hunter.BeastMastery;

--- APL Main
local function APL ()
    -- Unit Update
    HL.GetEnemies(40);
    -- Defensives
    -- Exhilaration
    --if S.Exhilaration:IsReady() and Player:HealthPercentage() <= HPCONFIG then
    --        return S.Exhilaration:Cast()
    --    end
    -- Out of Combat
    if not Player:AffectingCombat() then
        -- Flask
        -- Food
        -- Rune
        -- PrePot w/ Bossmod Countdown
        -- Opener
        if RubimRH.TargetIsValid() and Target:IsInRange(40) then
            if RubimRH.CDsON() then
                if S.AMurderofCrows:IsReady() then
                    return S.AMurderofCrows:Cast()
                end
            end
            if RubimRH.CDsON() and S.BestialWrath:IsReady() and not Player:Buff(S.BestialWrath) then
                return S.BestialWrath:Cast()
            end
            -- if S.BarbedShot:IsReady() then

            -- end
            if S.KillCommand:IsReady() then
                return S.KillCommand:Cast()
            end
            if S.CobraShot:IsReady() then
                return S.CobraShot:Cast()
            end
        end
        return 0, 462338
    end

    if Pet:IsActive() and Pet:HealthPercentage() > 0 and Pet:HealthPercentage() <= RubimRH.db.profile[253].mendpet and not Pet:Buff(S.MendPet) then
        return S.MendPet:Cast()
    end

    if S.AspectoftheTurtle:IsReady() and Player:HealthPercentage() <= RubimRH.db.profile[253].aspectoftheturtle then
        S.AspectoftheTurtle:Cast()
    end

    -- In Combat
    if RubimRH.TargetIsValid() then

        -- Counter Shot -> User request
        if S.CounterShot:IsReady(40)
                and ((Target:IsCasting()
                and Target:IsInterruptible()
                and Target:CastRemains() <= 0.7)
                or Target:IsChanneling()) then
            return S.CounterShot:Cast()
        end

        -- actions+=/counter_shot,if=target.debuff.casting.react // Sephuz Specific
        if RubimRH.CDsON() then
            -- actions+=/arcane_torrent,if=focus.deficit>=30
            --if S.ArcaneTorrent:IsReady() and Player:FocusDeficit() >= 30 then

            --end
            -- actions+=/berserking,if=cooldown.bestial_wrath.remains>30
            if S.Berserking:IsReady() and RubimRH.RacialON() and S.BestialWrath:CooldownRemains() > 30 then
                return S.Berserking:Cast()
            end
            -- actions+=/blood_fury,if=buff.bestial_wrath.remains>7
            if S.BloodFury:IsReady() and RubimRH.RacialON() and S.BestialWrath:CooldownRemains() > 30 then
                return S.BloodFury:Cast()
            end
            -- actions+=/ancestral_call,if=cooldown.bestial_wrath.remains>30
            if S.AncestralCall:IsReady() and RubimRH.RacialON() and S.BestialWrath:CooldownRemains() > 30 then
                return S.AncestralCall:Cast()
            end
            -- actions+=/fireblood,if=cooldown.bestial_wrath.remains>30
            if S.Fireblood:IsReady() and RubimRH.RacialON() and S.BestialWrath:CooldownRemains() > 30 then
                return S.Fireblood:Cast()
            end
            -- actions+=/lights_judgment
            if S.LightsJudgment:IsReady() and RubimRH.RacialON() then
                return S.LightsJudgment:Cast()
            end
        end
        -- actions+=/potion,if=buff.bestial_wrath.up&buff.aspect_of_the_wild.up
        -- barbed_shot,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<=gcd.max
        if S.BarbedShot:IsReady() and (Pet:BuffP(S.FrenzyBuff) and Pet:BuffRemainsP(S.FrenzyBuff) <= Player:GCD()) then
            return S.BarbedShot:Cast()
        end
        -- a_murder_of_crows
        if S.AMurderofCrows:IsReady() and (true) then
            return S.AMurderofCrows:Cast()
        end
        -- spitting_cobra
        if S.SpittingCobra:IsReady() and (true) then
            return S.SpittingCobra:Cast()
        end
        -- stampede,if=buff.bestial_wrath.up|cooldown.bestial_wrath.remains<gcd|target.time_to_die<15
        if S.Stampede:IsReady() and (Player:BuffP(S.BestialWrathBuff) or S.BestialWrath:CooldownRemainsP() < Player:GCD() or Target:TimeToDie() < 15) then
            return S.Stampede:Cast()
        end
        -- aspect_of_the_wild
        if S.AspectoftheWild:IsReady() and (true) then
            return S.AspectoftheWild:Cast()
        end
        -- bestial_wrath,if=!buff.bestial_wrath.up
        if RubimRH.CDsON() and S.BestialWrath:IsReady() and (not Player:BuffP(S.BestialWrathBuff)) then
            return S.BestialWrath:Cast()
        end
        -- multishot,if=spell_targets>2&(pet.cat.buff.beast_cleave.remains<gcd.max|pet.cat.buff.beast_cleave.down)
        if RubimRH.AoEON() and S.Multishot:IsReady() and (Cache.EnemiesCount[40] > 2 and (Pet:BuffRemainsP(S.BeastCleaveBuff) < Player:GCD() or Pet:BuffDownP(S.BeastCleaveBuff))) then
            return S.Multishot:Cast()
        end
        -- chimaera_shot
        if S.ChimaeraShot:IsReady() and (true) then
            return S.ChimaeraShot:Cast()
        end
        -- kill_command
        if S.KillCommand:IsReady() and (true) then
            return S.KillCommand:Cast()
        end
        -- dire_beast
        if S.DireBeast:IsReady() and (true) then
            return S.DireBeast:Cast()
        end
        -- barbed_shot,if=pet.cat.buff.frenzy.down&charges_fractional>1.4|full_recharge_time<gcd.max|target.time_to_die<9
        if S.BarbedShot:IsReady() and (Pet:BuffDownP(S.FrenzyBuff) and S.BarbedShot:ChargesFractional() > 1.4 or S.BarbedShot:FullRechargeTimeP() < Player:GCD() or Target:TimeToDie() < 9) then
            return S.BarbedShot:Cast()
        end
        -- multishot,if=spell_targets>1&(pet.cat.buff.beast_cleave.remains<gcd.max|pet.cat.buff.beast_cleave.down)
        if RubimRH.AoEON() and S.Multishot:IsReady() and (Cache.EnemiesCount[40] > 1 and (Pet:BuffRemainsP(S.BeastCleaveBuff) < Player:GCD() or Pet:BuffDownP(S.BeastCleaveBuff))) then
            return S.Multishot:Cast()
        end
        -- cobra_shot,if=(active_enemies<2|cooldown.kill_command.remains>focus.time_to_max)&(buff.bestial_wrath.up&active_enemies>1|cooldown.kill_command.remains>1+gcd&cooldown.bestial_wrath.remains>focus.time_to_max|focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost)
        if S.CobraShot:IsReady() and ((Cache.EnemiesCount[40] < 2 or S.KillCommand:CooldownRemainsP() > Player:FocusTimeToMaxPredicted()) and (Player:BuffP(S.BestialWrathBuff) and Cache.EnemiesCount[40] > 1 or S.KillCommand:CooldownRemainsP() > 1 + Player:GCD() and S.BestialWrath:CooldownRemainsP() > Player:FocusTimeToMaxPredicted() or Player:Focus() - S.CobraShot:Cost() + Player:FocusRegen() * (S.KillCommand:CooldownRemainsP() - 1) > S.KillCommand:Cost())) then
            return S.CobraShot:Cast()
        end

    end
    return 0, 135328
end

RubimRH.Rotation.SetAPL(253, APL);

local function PASSIVE()
    return RubimRH.Shared()
end

RubimRH.Rotation.SetPASSIVE(253, PASSIVE);
--- Last Update: 07/17/2018

-- # Executed before combat begins. Accepts non-harmful actions only.
-- actions.precombat=flask
-- actions.precombat+=/augmentation
-- actions.precombat+=/food
-- actions.precombat+=/summon_pet
-- # Snapshot raid buffed stats before combat begins and pre-potting is done.
-- actions.precombat+=/snapshot_stats
-- actions.precombat+=/potion
-- actions.precombat+=/aspect_of_the_wild

-- # Executed every time the actor is available.
-- actions=auto_shot
-- actions+=/counter_shot,if=equipped.sephuzs_secret&target.debuff.casting.react&cooldown.buff_sephuzs_secret.up&!buff.sephuzs_secret.up
-- actions+=/use_items
-- actions+=/berserking,if=cooldown.bestial_wrath.remains>30
-- actions+=/blood_fury,if=cooldown.bestial_wrath.remains>30
-- actions+=/ancestral_call,if=cooldown.bestial_wrath.remains>30
-- actions+=/fireblood,if=cooldown.bestial_wrath.remains>30
-- actions+=/lights_judgment
-- actions+=/potion,if=buff.bestial_wrath.up&buff.aspect_of_the_wild.up
-- actions+=/barbed_shot,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<=gcd.max
-- actions+=/a_murder_of_crows
-- actions+=/spitting_cobra
-- actions+=/stampede,if=buff.bestial_wrath.up|cooldown.bestial_wrath.remains<gcd|target.time_to_die<15
-- actions+=/aspect_of_the_wild
-- actions+=/bestial_wrath,if=!buff.bestial_wrath.up
-- actions+=/multishot,if=spell_targets>2&(pet.cat.buff.beast_cleave.remains<gcd.max|pet.cat.buff.beast_cleave.down)
-- actions+=/chimaera_shot
-- actions+=/kill_command
-- actions+=/dire_beast
-- actions+=/barbed_shot,if=pet.cat.buff.frenzy.down&charges_fractional>1.4|full_recharge_time<gcd.max|target.time_to_die<9
-- actions+=/barrage
-- actions+=/multishot,if=spell_targets>1&(pet.cat.buff.beast_cleave.remains<gcd.max|pet.cat.buff.beast_cleave.down)
-- actions+=/cobra_shot,if=(active_enemies<2|cooldown.kill_command.remains>focus.time_to_max)&(buff.bestial_wrath.up&active_enemies>1|cooldown.kill_command.remains>1+gcd&cooldown.bestial_wrath.remains>focus.time_to_max|focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost)
