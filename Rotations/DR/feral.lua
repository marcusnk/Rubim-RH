---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Rubim.
--- DateTime: 21/06/2018 01:23
---

--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local RubimRH = LibStub("AceAddon-3.0"):GetAddon("RubimRH")
local addonName, addonTable = ...;
-- AethysCore
local AC = AethysCore;
local Cache = AethysCache;
local Unit = AC.Unit;
local Player = Unit.Player;
local Target = Unit.Target;
local Spell = AC.Spell;
local Item = AC.Item;
--- ============================ CONTENT ============================
-- Spells
if not Spell.Druid then
    Spell.Druid = {};
end
Spell.Druid.Feral = {
    -- Racials
    Berserking = Spell(26297),
    Shadowmeld = Spell(58984),
    -- Abilities
    Berserk = Spell(106951),
    FerociousBite = Spell(22568),
    Maim = Spell(22570),
    MoonfireCat = Spell(155625),
    PredatorySwiftness = Spell(69369),
    Prowl = Spell(5215),
    ProwlJungleStalker = Spell(102547),
    Rake = Spell(1822),
    RakeDebuff = Spell(155722),
    Rip = Spell(1079),
    Shred = Spell(5221),
    Swipe = Spell(106785),
    Thrash = Spell(106830),
    TigersFury = Spell(5217),
    WildCharge = Spell(49376),
    -- Talents
    BalanceAffinity = Spell(197488),
    Bloodtalons = Spell(155672),
    BloodtalonsBuff = Spell(145152),
    BrutalSlash = Spell(202028),
    ElunesGuidance = Spell(202060),
    GuardianAffinity = Spell(217615),
    Incarnation = Spell(102543),
    JungleStalker = Spell(252071),
    JaggedWounds = Spell(202032),
    LunarInspiration = Spell(155580),
    RestorationAffinity = Spell(197492),
    Sabertooth = Spell(202031),
    SavageRoar = Spell(52610),
    MomentOfClarity = Spell(236068),
    -- Artifact
    AshamanesFrenzy = Spell(210722),
    -- Defensive
    Regrowth = Spell(8936),
    Renewal = Spell(108238),
    SurvivalInstincts = Spell(61336),
    -- Utility
    SkullBash = Spell(106839),
    -- Shapeshift
    BearForm = Spell(5487),
    CatForm = Spell(768),
    MoonkinForm = Spell(197625),
    TravelForm = Spell(783),
    -- Legendaries
    FieryRedMaimers = Spell(236757),
    -- Tier Set
    ApexPredator = Spell(252752), -- TODO: Verify T21 4-Piece Buff SpellID
    -- Misc
    RipAndTear = Spell(203242),
    Clearcasting = Spell(135700),
    PoolEnergy = Spell(9999000010)
    -- Macros

};
local S = Spell.Druid.Feral;
S.Rip:RegisterPMultiplier({ S.BloodtalonsBuff, 1.2 }, { S.SavageRoar, 1.15 }, { S.TigersFury, 1.15 });
--S.Thrash:RegisterPMultiplier({S.BloodtalonsBuff, 1.2}, {S.SavageRoar, 1.15}, {S.TigersFury, 1.15}); Don't need it but add moment of clarity scaling if we add it
S.Rake:RegisterPMultiplier(
        S.RakeDebuff,
        { function()
            return Player:IsStealthed(true, true) and 2 or 1;
        end },
        { S.BloodtalonsBuff, 1.2 }, { S.SavageRoar, 1.15 }, { S.TigersFury, 1.15 }
);

-- Items
if not Item.Druid then
    Item.Druid = {};
end
Item.Druid.Feral = {
    -- Legendaries
    LuffaWrappings = Item(137056, { 9 }),
    AiluroPouncers = Item(137024, { 8 })
};
local I = Item.Druid.Feral;

-- Rotation Var
local RakeAura, RipAura, ThrashAura;
do
    local JW = 0.8;
    local Pandemic = 0.3;
    local ComputeDurations = function(Nominal)
        return {
            BaseDuration = Nominal,
            JWDuration = Nominal * JW;
            BaseThreshold = Nominal * Pandemic,
            JWThreshold = Nominal * (Pandemic * JW);
        };
    end
    RakeAura = ComputeDurations(S.RakeDebuff:BaseDuration());
    RipAura = ComputeDurations(S.Rip:BaseDuration());
    ThrashAura = ComputeDurations(S.Thrash:BaseDuration());
end
local MoonfireThreshold = S.MoonfireCat:PandemicThreshold();

function Player:EnergyTimeToXP (Amount, Offset)
    if self:EnergyRegen() == 0 then
        return -1;
    end
    return Amount > self:EnergyPredicted() and (Amount - self:EnergyPredicted()) / (self:EnergyRegen() * (1 - (Offset or 0))) or 0;
end

local useTrash = 0
poolResource = {
    { skill = "None", qty = "0", isActive = false }
}

local MeleeRange, AoERadius, RangedRange = 0, 0, 0
local RakeDuration, RipDuration, ThrashDuration = 0, 0, 0
local RakeThreshold, RipThreshold, ThrashThreshold = 0, 0, 0
--- ======= ACTION LISTS =======
-- Put here acti lists only if they are called multiple times in the APL
-- If it's only put one time, it's doing a closure call for nothing.
--- ======= MAIN =======
local function Generators()
    --actions.st_generators=regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points>=2&cooldown.ashamanes_frenzy.remains<gcd
    if S.Regrowth:IsReady() and (S.Bloodtalons:IsAvailable() and Player:Buff(S.PredatorySwiftness) and not Player:Buff(S.BloodtalonsBuff) and Player:ComboPoints() >= 2 and (S.AshamanesFrenzy:CooldownRemainsP() < Player:GCD())) then
        return S.Regrowth:ID()
    end

    --actions.st_generators+=/regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points=4&dot.rake.remains<4
    if S.Regrowth:IsReady() and (S.Bloodtalons:IsAvailable() and Player:Buff(S.PredatorySwiftness) and not Player:Buff(S.BloodtalonsBuff) and Player:ComboPoints() == 4 and Target:DebuffRemainsP(S.RakeDebuff) < 4) then
        return S.Regrowth:ID()
    end

    --actions.st_generators+=/regrowth,if=equipped.ailuro_pouncers&talent.bloodtalons.enabled&(buff.predatory_swiftness.stack>2|(buff.predatory_swiftness.stack>1&dot.rake.remains<3))&buff.bloodtalons.down
    if S.Regrowth:IsReady() and (I.AiluroPouncers:IsEquipped() and S.Bloodtalons:IsAvailable() and (Player:BuffStack(S.PredatorySwiftness) > 2 or (Player:BuffStack(S.PredatorySwiftness) > 1 and Target:DebuffRemainsP(S.RakeDebuff) < 3)) and not Player:Buff(S.BloodtalonsBuff)) then
        return S.Regrowth:ID()
    end

    --actions.st_generators+=/brutal_slash,if=spell_targets.brutal_slash>desired_targets
    if S.BrutalSlash:IsAvailable() and S.BrutalSlash:IsReady() and Cache.EnemiesCount[AoERadius] > 1 then
        return 194612
    end

    --actions.st_generators+=/pool_resource,for_next=1
    if (Target:DebuffRefreshableP(S.Thrash, ThrashThreshold) and (Cache.EnemiesCount[ThrashRadius] > 2)) and not S.Thrash:IsReady() then
        poolResource[1].skill = S.Thrash
        poolResource[1].spellName = "Thrash"
        poolResource[1].isActive = true
        return 233159
    end

    --actions.st_generators+=/thrash_cat,if=refreshable&(spell_targets.thrash_cat>2)
    if S.Thrash:IsReady() and Target:DebuffRefreshableP(S.Thrash, ThrashThreshold) and (Cache.EnemiesCount[ThrashRadius] > 2) then
        return S.Thrash:ID()
    end

    --actions.st_generators+=/pool_resource,for_next=1
    if not Target:Debuff(S.RakeDebuff) or (not S.Bloodtalons:IsAvailable() and Target:DebuffRefreshableP(S.RakeDebuff, RakeThreshold)) and Target:TimeToDie() > 4 then
        poolResource[1].skill = S.Rake
        poolResource[1].spellName = "Rake"
        poolResource[1].isActive = true
        return 233159
    end

    --actions.st_generators+=/rake,target_if=!ticking|(!talent.bloodtalons.enabled&remains<duration*0.3)&target.time_to_die>4
    if S.Rake:IsReady() and not Target:Debuff(S.RakeDebuff) or (not S.Bloodtalons:IsAvailable() and Target:DebuffRefreshableP(S.RakeDebuff, RakeThreshold)) and Target:TimeToDie() > 4 then
        return S.Rake:ID()
    end

    --actions.st_generators+=/pool_resource,for_next=1
    if S.Rake:IsReady() and S.Bloodtalons:IsAvailable() and Player:Buff(S.BloodtalonsBuff) and ((Target:DebuffRemainsP(S.RakeDebuff) <= 7) and Player:PMultiplier(S.Rake) > Target:PMultiplier(S.Rake) * 0.85) and Target:TimeToDie() > 4 then
        poolResource[1].skill = S.Rake
        poolResource[1].spellName = "Rake"
        poolResource[1].isActive = true
        return 233159
    end

    --actions.st_generators+=/rake,target_if=talent.bloodtalons.enabled&buff.bloodtalons.up&((remains<=7)&persistent_multiplier>dot.rake.pmultiplier*0.85)&target.time_to_die>4
    if S.Rake:IsReady() and S.Bloodtalons:IsAvailable() and Player:Buff(S.BloodtalonsBuff) and ((Target:DebuffRemainsP(S.RakeDebuff) <= 7) and Player:PMultiplier(S.Rake) > Target:PMultiplier(S.Rake) * 0.85) and Target:TimeToDie() > 4 then
        return S.Rake:ID()
    end

    --actions.st_generators+=/brutal_slash,if=spell_targets.brutal_slash>desired_targets
    if S.BrutalSlash:IsAvailable() and S.BrutalSlash:IsReady() and Cache.EnemiesCount[AoERadius] > 1 then
        return 194612
    end

    --actions.st_generators+=/pool_resource,for_next=1
    if (Target:DebuffRefreshableP(S.Thrash, ThrashThreshold) and (Cache.EnemiesCount[ThrashRadius] > 2)) and not S.Thrash:IsReady() then
        poolResource[1].skill = S.Thrash
        poolResource[1].spellName = "Thrash"
        poolResource[1].isActive = true
        return 233159
    end

    --actions.st_generators+=/thrash_cat,if=refreshable&(spell_targets.thrash_cat>2)
    if S.Thrash:IsReady() and Target:DebuffRefreshableP(S.Thrash, ThrashThreshold) and (Cache.EnemiesCount[ThrashRadius] > 2) then
        return S.Thrash:ID()
    end

    --
    --actions.st_generators+=/brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))
    if S.BrutalSlash:IsAvailable() and S.BrutalSlash:IsReady(AoERadius, true) and Player:Buff(S.TigersFury) then
        return 194612
    end

    --actions.st_generators+=/moonfire_cat,target_if=refreshable
    if S.LunarInspiration:IsAvailable() and S.MoonfireCat:IsReady(RangedRange) and Target:DebuffRefreshableP(S.MoonfireCat, MoonfireThreshold) then
        return S.LunarInspiration:ID()
    end

    --actions.st_generators+=/pool_resource,for_next=1
    if Target:DebuffRefreshableP(S.Thrash, ThrashThreshold) and (useTrash == 2 or Cache.EnemiesCount[ThrashRadius] > 1) then
        poolResource[1].skill = S.Thrash
        poolResource[1].spellName = "Thrash"
        poolResource[1].isActive = true
        spellPool = S.Thrash
        return 233159
    end

    --actions.st_generators+=/thrash_cat,if=refreshable&(variable.use_thrash=2|spell_targets.thrash_cat>1)
    if S.Thrash:IsReady() and Target:DebuffRefreshableP(S.Thrash, ThrashThreshold) and (useTrash == 2 or Cache.EnemiesCount[ThrashRadius] > 1) then
        return S.Thrash:ID()
    end

    --actions.st_generators+=/thrash_cat,if=refreshable&variable.use_thrash=1&buff.clearcasting.react
    if S.Thrash:IsReady(ThrashRadius, true) and Target:DebuffRefreshableP(S.Thrash, ThrashThreshold) and useTrash == 1 and Player:Buff(S.Clearcasting) then
        return S.Thrash:ID()
    end

    --actions.st_generators+=/pool_resource,for_next=1
    if not S.BrutalSlash:IsAvailable() and not S.BrutalSlash:IsAvailable() and AoEON() and Cache.EnemiesCount[AoERadius] >= 2 then
        poolResource[1].skill = S.BrutalSlash
        poolResource[1].spellName = "BrutalSlash"
        poolResource[1].isActive = true
        return 233159
    end

    --actions.st_generators+=/swipe_cat,if=spell_targets.swipe_cat>1
    if S.Swipe:IsReady() and not S.BrutalSlash:IsAvailable() and AoEON() and Cache.EnemiesCount[AoERadius] >= 2 then
        return 194612
    end

    --actions.st_generators+=/shred,if=dot.rake.remains>(action.shred.cost+action.rake.cost-energy)%energy.regen|buff.clearcasting.react
    if S.Shred:IsReady() and (Target:DebuffRemainsP(S.RakeDebuff) > Player:EnergyTimeToXP(S.Shred:Cost() + S.Rake:Cost()) or Player:BuffP(S.Clearcasting)) then
        return S.Shred:ID()
    end
end

local function Finishers()
    -- actions.st_finishers=pool_resource,for_next=1
    if S.SavageRoar:IsAvailable() and S.SavageRoar:CooldownRemainsP() == 0 and not Player:Buff(S.SavageRoar) then
        poolResource[1].skill = S.SavageRoar
        poolResource[1].spellName = "SavageRoar"
        poolResource[1].isActive = true
        return 233159
    end

    -- actions.st_finishers+=/savage_roar,if=buff.savage_roar.down
    if S.SavageRoar:IsAvailable() and S.SavageRoar:IsReady() and not Player:Buff(S.SavageRoar) then
        return S.SavageRoar:ID()
    end

    -- actions.st_finishers+=/pool_resource,for_next=1
    if (Target:DebuffRefreshableP(S.Rip, 0) or (Target:DebuffRefreshableP(S.Rip, RipThreshold) and Target:HealthPercentage() >= 25 and not S.Sabertooth:IsAvailable()) or (Target:DebuffRefreshableP(S.Rip, RipDuration * 0.8) and Player:PMultiplier(S.Rip) > Target:PMultiplier(S.Rip) and Target:TimeToDie() > 8)) then
        poolResource[1].skill = S.Rip
        poolResource[1].spellName = "Rip"
        poolResource[1].isActive = true
        return 233159
    end
    -- actions.st_finishers+=/rip,target_if=!ticking|(remains<=duration*0.3)&(target.health.pct>25&!talent.sabertooth.enabled)|(remains<=duration*0.8&persistent_multiplier>dot.rip.pmultiplier)&target.time_to_die>8
    if S.Rip:IsReady() and (Target:DebuffRefreshableP(S.Rip, 0) or (Target:DebuffRefreshableP(S.Rip, RipThreshold) and Target:HealthPercentage() >= 25 and not S.Sabertooth:IsAvailable()) or (Target:DebuffRefreshableP(S.Rip, RipDuration * 0.8) and Player:PMultiplier(S.Rip) > Target:PMultiplier(S.Rip) and Target:TimeToDie() > 8)) then
        return S.Rip:ID()
    end

    -- actions.st_finishers+=/pool_resource,for_next=1
    if not Player:Buff(S.SavageRoar) and S.SavageRoar:IsAvailable() then
        poolResource[1].skill = S.SavageRoar
        poolResource[1].spellName = "SavageRoar"
        poolResource[1].isActive = true
        return 233159
    end

    -- actions.st_finishers+=/savage_roar,if=buff.savage_roar.remains<12
    if S.SavageRoar:IsAvailable() and S.SavageRoar:IsReady() and not Player:Buff(S.SavageRoar) then
        return S.SavageRoar:ID()
    end

    -- actions.st_finishers+=/maim,if=buff.fiery_red_maimers.up
    if S.Maim:IsReady() and Player:Buff(S.FieryRedMaimers) then
        return S.Main:ID()
    end

    -- actions.st_finishers+=/ferocious_bite,max_energy=1
    if S.FerociousBite:IsReady() and Player:Energy() >= 50 then
        return S.FerociousBite:ID()
    end

end

local function Cooldowns()
    -- actions.cooldowns=dash,if=!buff.cat_form.up

    -- actions.cooldowns+=/prowl,if=buff.incarnation.remains<0.5&buff.jungle_stalker.up
    if S.ProwlJungleStalker:IsReady() and (Player:BuffRemainsP(S.Incarnation) < 0.5) and Player:Buff(S.JungleStalker) then
        return S.Prowl:ID()
    end

    -- actions.cooldowns+=/berserk,if=energy>=30&(cooldown.tigers_fury.remains>5|buff.tigers_fury.up)
    if CDsON() and S.Berserk:IsReady() and Player:EnergyPredicted() >= 30 and (S.TigersFury:CooldownRemainsP() > 5 or Player:Buff(S.TigersFury)) then
        return S.Berserk:ID()
    end

    -- actions.cooldowns+=/tigers_fury,if=energy.deficit>=60
    if S.TigersFury:IsReady() and Player:EnergyDeficitPredicted() >= 60 then
        return S.TigersFury:ID()
    end

    -- actions.cooldowns+=/berserking
    if CDsON() and S.Berserking:IsReady() then
        return S.Berserking:ID()
    end

    -- actions.cooldowns+=/elunes_guidance,if=combo_points=0&energy>=50
    if S.ElunesGuidance:IsReady() and Player:ComboPoints() == 0 and Player:EnergyPredicted() >= 50 then
        return S.ElunesGuidance:ID()
    end

    -- actions.cooldowns+=/incarnation,if=energy>=30&(cooldown.tigers_fury.remains>15|buff.tigers_fury.up)
    if S.Incarnation:IsAvailable() and S.Incarnation:IsReady() and Player:EnergyPredicted() >= 30 and (S.TigersFury:CooldownRemainsP() > 15 or Player:Buff(S.TigersFury)) then
        return 124309
    end

    -- actions.cooldowns+=/potion,name=prolonged_power,if=target.time_to_die<65|(time_to_die<180&(buff.berserk.up|buff.incarnation.up))


    -- actions.cooldowns+=/ashamanes_frenzy,if=combo_points>=2&(!talent.bloodtalons.enabled|buff.bloodtalons.up)
    if S.AshamanesFrenzy:IsReady() and Player:ComboPoints() >= 2 and (not S.Bloodtalons:IsAvailable() or Player:Buff(S.BloodtalonsBuff)) then
        return S.AshamanesFrenzy:ID()
    end

    -- actions.cooldowns+=/shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
    if S.Shadowmeld:IsReady() and Player:ComboPoints() < 5 and Player:Energy() >= S.Rake:Cost() and Target:PMultiplier(S.Rake) < 2.1
            and Player:Buff(S.TigersFury) and (Player:Buff(S.BloodtalonsBuff) or not S.Bloodtalons:IsAvailable())
            and (not S.Incarnation:IsAvailable() or S.Incarnation:CooldownRemainsP() > 18) and not Player:Buff(S.Incarnation) then
        return S.Shadowmeld:ID()
    end
    -- actions.cooldowns+=/use_items
end

local function SingleTarget()
    -- actions.single_target=cat_form,if=!buff.cat_form.up
    if not Player:Buff(S.CatForm) then
        return S.CatForm:ID()
    end

    -- actions.single_target+=/rake,if=buff.prowl.up|buff.shadowmeld.up
    if S.Rake:IsReady() and (Player:Buff(S.Prowl) or Player:Buff(S.Shadowmeld)) then
        return S.Rake:ID()
    end

    --actions.single_target +=/call_action_list, name = cooldowns
    if Cooldowns() ~= nil then
        return Cooldowns()
    end

    -- actions.single_target+=/ferocious_bite,target_if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>10&(target.health.pct<25|talent.sabertooth.enabled)
    if S.FerociousBite:IsReady() and Target:DebuffP(S.Rip) and Target:DebuffRemainsP(S.Rip) < 3 and Target:TimeToDie() > 10 and ((Target:HealthPercentage() < 25) or S.Sabertooth:IsAvailable()) then
        return S.FerociousBite:ID()
    end

    -- actions.single_target+=/regrowth,if=combo_points=5&buff.predatory_swiftness.up&talent.bloodtalons.enabled&buff.bloodtalons.down&(!buff.incarnation.up|dot.rip.remains<8)
    if S.Regrowth:IsCastable() and Player:ComboPoints() == 5 and Player:BuffP(S.PredatorySwiftness) and S.Bloodtalons:IsAvailable() and Player:BuffDownP(S.BloodtalonsBuff) and (Player:BuffDownP(S.Incarnation) or (Target:DebuffRemainsP(S.Rip) < 8)) then
        return S.Regrowth:ID()
    end
    -- actions.single_target+=/regrowth,if=combo_points>3&talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.apex_predator.up&buff.incarnation.down
    if S.Regrowth:IsCastable() and Player:ComboPoints() > 3 and S.Bloodtalons:IsAvailable() and Player:BuffP(S.PredatorySwiftness) and Player:BuffP(S.ApexPredator) and Player:BuffDownP(S.Incarnation) then
        return S.Regrowth:ID()
    end
    -- actions.single_target+=/ferocious_bite,if=buff.apex_predator.up&((combo_points>4&(buff.incarnation.up|talent.moment_of_clarity.enabled))|(talent.bloodtalons.enabled&buff.bloodtalons.up&combo_points>3))
    if S.FerociousBite:IsCastable() and Player:ComboPoints() >= 1 and Player:BuffP(S.ApexPredator) and ((Player:ComboPoints() > 4 and (Player:BuffP(S.Incarnation) or S.MomentOfClarity:IsAvailable())) or (S.Bloodtalons:IsAvailable() and Player:BuffP(S.BloodtalonsBuff) and Player:ComboPoints() > 3)) then
        return S.FerociousBite:ID()
    end

    --actions.single_target+ = /run_action_list, name = st_finishers, if = combo_points>4
    if Finishers() ~= nil and (Player:ComboPoints() > 4 and Target:IsInRange(MeleeRange)) then
        return Finishers()
    end

    if Generators() ~= nil then
        return Generators()
    end
end

function DruidFeral()
    if I.LuffaWrappings:IsEquipped() then
        useTrash = 1
    else
        useTrash = 0
    end
    -- Local Update
    -- TODO: Move Affinity & JW check on an Event Handler on talent update.
    if S.BalanceAffinity:IsAvailable() then
        -- Have to use the spell itself since Balance Affinity is a special range increase
        MeleeRange = S.Shred;
        AoERadius = 13;
        ThrashRadius = I.LuffaWrappings:IsEquipped() and 16.25 or AoERadius;
        RangedRange = 45;
    else
        MeleeRange = "Melee";
        AoERadius = 8;
        ThrashRadius = I.LuffaWrappings:IsEquipped() and 10 or AoERadius;
        RangedRange = 40;
    end
    if S.JaggedWounds:IsAvailable() then
        RakeDuration, RakeThreshold = RakeAura.JWDuration, RakeAura.JWThreshold;
        RipDuration, RipThreshold = RipAura.JWDuration, RipAura.JWThreshold;
        ThrashDuration, ThrashThreshold = ThrashAura.JWDuration, ThrashAura.JWThreshold;
    else
        RakeDuration, RakeThreshold = RakeAura.BaseDuration, RakeAura.BaseThreshold;
        RipDuration, RipThreshold = RipAura.BaseDuration, RipAura.BaseThreshold;
        ThrashDuration, ThrashThreshold = ThrashAura.BaseDuration, ThrashAura.BaseThreshold;
    end

    -- Unit Update
    AC.GetEnemies(ThrashRadius, true); -- Thrash
    AC.GetEnemies(AoERadius, true); -- Swipe


    if not Player:AffectingCombat() then
        poolResource[1].skill = "Nil"
        poolResource[1].spellName = "0"
        poolResource[1].isActive = false
    end

    if UnitChannelInfo("player") ~= nil or UnitCastingInfo("player") ~= nil then
        return 248999
    end
    -- Defensives
    if classSpell[1].isActive and S.Renewal:IsReady() and Player:HealthPercentage() <= RubimRH.db.profile.dr.renewal then
        return S.Renewal:ID()
    end

    if classSpell[2].isActive and S.Regrowth:IsReady() and Player:Buff(S.PredatorySwiftness) and Player:HealthPercentage() <= RubimRH.db.profile.dr.regrowth then
        return S.Regrowth:ID()
    end

    if not TargetIsValid() then
        return 233159
    end

    if poolResource[1].isActive == true and Player:PrevGCD(1, poolResource[1].skill) then
        poolResource[1].skill = "Nil"
        poolResource[1].spellName = "0"
        poolResource[1].isActive = false
        return 233159
    end

    if poolResource[1].spellName == "Rake" and S.Rake:IsReady() and S.Rake:CooldownRemainsP() == 0 then
        return S.Rake:ID()
    end

    if poolResource[1].spellName == "BrutalSlash" and S.BrutalSlash:IsReady() and S.BrutalSlash:ChargesFractional() >= 1 then
        return 194612
    end

    if Player:ComboPoints() >= 1 then
        if poolResource[1].spellName == "Thrash" and S.Thrash:IsReady() and S.Thrash:CooldownRemainsP() == 0 then
            return S.Thrash:ID()
        end

        if poolResource[1].spellName == "Rip" and S.Rip:IsReady() and S.Rip:CooldownRemainsP() == 0 then
            return S.Rip:ID()
        end

        if poolResource[1].spellName == "SavageRoar" and S.SavageRoar:IsReady() and S.SavageRoar:CooldownRemainsP() == 0 then
            return S.SavageRoar:ID()
        end
    end

    if poolResource[1].isActive == true and Player:ComboPoints() > 1 then
        return 233159
    end
    --debugVarText = Player:PrevGCD()

    -- actions=run_action_list,name=single_target,if=dot.rip.ticking|time>15
    if SingleTarget() ~= nil and Target:IsInRange(MeleeRange) and (Target:DebuffRemainsP(S.Rip) > 0 or AC.CombatTime() > 15) then
        return SingleTarget()
    end

    -- actions+=/rake,if=!ticking|buff.prowl.up
    if S.Rake:IsReady() and (Target:DebuffRefreshableP(S.RakeDebuff, 0) or Player:IsStealthed()) then
        return S.Rake:ID()
    end

    -- actions+=/dash,if=!buff.cat_form.up
    -- actions+=/auto_attack

    -- actions+=/moonfire_cat,if=talent.lunar_inspiration.enabled&!ticking
    if S.LunarInspiration:IsAvailable() and S.MoonfireCat:IsReady() and Target:DebuffRefreshableP(S.MoonfireCat, 0) then
        return S.MoonfireCat:ID()
    end

    -- actions+=/savage_roar,if=!buff.savage_roar.up
    if S.SavageRoar:IsAvailable() and S.SavageRoar:IsReady() and not Player:Buff(S.SavageRoar) then
        return S.SavageRoar:ID()
    end

    -- actions+=/berserk
    -- actions+=/incarnation
    if CDsON() then
        -- berserk
        if S.Berserk:IsReady() then
            return S.Berserk:ID()
        end
        -- incarnation
        if S.Incarnation:IsAvailable() and S.Incarnation:IsReady() then
            return 124309
        end
    end

    -- actions+=/tigers_fury
    if S.TigersFury:IsReady() then
        return S.TigersFury:ID()
    end

    -- actions+=/ashamanes_frenzy
    if CDsON() and S.AshamanesFrenzy:IsReady() then
        return S.AshamanesFrenzy:ID()
    end

    -- actions+=/regrowth,if=(talent.sabertooth.enabled|buff.predatory_swiftness.up)&talent.bloodtalons.enabled&buff.bloodtalons.down&combo_points=5
    if S.Regrowth:IsReady() and (S.Bloodtalons:IsAvailable() or Player:Buff(S.PredatorySwiftness) and S.Bloodtalons:IsAvailable() and not Player:Buff(S.BloodtalonsBuff) and Player:ComboPoints() == 5) then
        return S.Regrowth:ID()
    end

    -- actions+=/rip,if=combo_points=5
    if S.Rip:IsReady() and Player:ComboPoints() == 5 then
        return S.Rip:ID()
    end

    -- actions+=/thrash_cat,if=!ticking&variable.use_thrash>0
    if S.Thrash:IsReady() and useTrash > 0 and (not (Target:DebuffRemainsP(S.Thrash) > 1)) then
        return S.Thrash:ID()
    end

    -- actions+=/shred
    if S.Shred:IsReady() then
        return S.Shred:ID()
    end
    return 233159
end


--- ======= SIMC =======
-- Imported Current APL on 2018-04-16, 04:18 CEST
-- # Default consumables
-- potion=potion_of_prolonged_power
-- flask=seventh_demon
-- food=lemon_herb_filet
-- augmentation=defiled

-- # This default action priority list is automatically created based on your character.
-- # It is a attempt to provide you with a action list that is both simple and practicable,
-- # while resulting in a meaningful and good simulation. It may not result in the absolutely highest possible dps.
-- # Feel free to edit, adapt and improve it to your own needs.
-- # SimulationCraft is always looking for updates and improvements to the default action lists.

-- # Executed before combat begins. Accepts non-harmful actions only.
-- actions.precombat=flask
-- actions.precombat+=/food
-- actions.precombat+=/augmentation
-- actions.precombat+=/regrowth,if=talent.bloodtalons.enabled
-- actions.precombat+=/variable,name=use_thrash,value=0
-- actions.precombat+=/variable,name=use_thrash,value=1,if=equipped.luffa_wrappings
-- actions.precombat+=/cat_form
-- actions.precombat+=/prowl
-- # Snapshot raid buffed stats before combat begins and pre-potting is done.
-- actions.precombat+=/snapshot_stats
-- actions.precombat+=/potion

-- # Executed every time the actor is available.
-- actions=run_action_list,name=single_target,if=dot.rip.ticking|time>15
-- actions+=/rake,if=!ticking|buff.prowl.up
-- actions+=/dash,if=!buff.cat_form.up
-- actions+=/auto_attack
-- actions+=/moonfire_cat,if=talent.lunar_inspiration.enabled&!ticking
-- actions+=/savage_roar,if=!buff.savage_roar.up
-- actions+=/berserk
-- actions+=/incarnation
-- actions+=/tigers_fury
-- actions+=/ashamanes_frenzy
-- actions+=/regrowth,if=(talent.sabertooth.enabled|buff.predatory_swiftness.up)&talent.bloodtalons.enabled&buff.bloodtalons.down&combo_points=5
-- actions+=/rip,if=combo_points=5
-- actions+=/thrash_cat,if=!ticking&variable.use_thrash>0
-- actions+=/shred

-- actions.cooldowns=dash,if=!buff.cat_form.up
-- actions.cooldowns+=/prowl,if=buff.incarnation.remains<0.5&buff.jungle_stalker.up
-- actions.cooldowns+=/berserk,if=energy>=30&(cooldown.tigers_fury.remains>5|buff.tigers_fury.up)
-- actions.cooldowns+=/tigers_fury,if=energy.deficit>=60
-- actions.cooldowns+=/berserking
-- actions.cooldowns+=/elunes_guidance,if=combo_points=0&energy>=50
-- actions.cooldowns+=/incarnation,if=energy>=30&(cooldown.tigers_fury.remains>15|buff.tigers_fury.up)
-- actions.cooldowns+=/potion,name=prolonged_power,if=target.time_to_die<65|(time_to_die<180&(buff.berserk.up|buff.incarnation.up))
-- actions.cooldowns+=/ashamanes_frenzy,if=combo_points>=2&(!talent.bloodtalons.enabled|buff.bloodtalons.up)
-- actions.cooldowns+=/shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
-- actions.cooldowns+=/use_items

-- actions.single_target=cat_form,if=!buff.cat_form.up
-- actions.single_target+=/rake,if=buff.prowl.up|buff.shadowmeld.up
-- actions.single_target+=/auto_attack
-- actions.single_target+=/call_action_list,name=cooldowns
-- actions.single_target+=/ferocious_bite,target_if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>10&(target.health.pct<25|talent.sabertooth.enabled)
-- actions.single_target+=/regrowth,if=combo_points=5&buff.predatory_swiftness.up&talent.bloodtalons.enabled&buff.bloodtalons.down&(!buff.incarnation.up|dot.rip.remains<8)
-- actions.single_target+=/regrowth,if=combo_points>3&talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.apex_predator.up&buff.incarnation.down
-- actions.single_target+=/ferocious_bite,if=buff.apex_predator.up&((combo_points>4&(buff.incarnation.up|talent.moment_of_clarity.enabled))|(talent.bloodtalons.enabled&buff.bloodtalons.up&combo_points>3))
-- actions.single_target+=/run_action_list,name=st_finishers,if=combo_points>4
-- actions.single_target+=/run_action_list,name=st_generators

-- actions.st_finishers=pool_resource,for_next=1
-- actions.st_finishers+=/savage_roar,if=buff.savage_roar.down
-- actions.st_finishers+=/pool_resource,for_next=1
-- actions.st_finishers+=/rip,target_if=!ticking|(remains<=duration*0.3)&(target.health.pct>25&!talent.sabertooth.enabled)|(remains<=duration*0.8&persistent_multiplier>dot.rip.pmultiplier)&target.time_to_die>8
-- actions.st_finishers+=/pool_resource,for_next=1
-- actions.st_finishers+=/savage_roar,if=buff.savage_roar.remains<12
-- actions.st_finishers+=/maim,if=buff.fiery_red_maimers.up
-- actions.st_finishers+=/ferocious_bite,max_energy=1

-- actions.st_generators=regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points>=2&cooldown.ashamanes_frenzy.remains<gcd
-- actions.st_generators+=/regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points=4&dot.rake.remains<4
-- actions.st_generators+=/regrowth,if=equipped.ailuro_pouncers&talent.bloodtalons.enabled&(buff.predatory_swiftness.stack>2|(buff.predatory_swiftness.stack>1&dot.rake.remains<3))&buff.bloodtalons.down
-- actions.st_generators+=/brutal_slash,if=spell_targets.brutal_slash>desired_targets
-- actions.st_generators+=/pool_resource,for_next=1
-- actions.st_generators+=/thrash_cat,if=refreshable&(spell_targets.thrash_cat>2)
-- actions.st_generators+=/pool_resource,for_next=1
-- actions.st_generators+=/thrash_cat,if=spell_targets.thrash_cat>3&equipped.luffa_wrappings&talent.brutal_slash.enabled
-- actions.st_generators+=/pool_resource,for_next=1
-- actions.st_generators+=/rake,target_if=!ticking|(!talent.bloodtalons.enabled&remains<duration*0.3)&target.time_to_die>4
-- actions.st_generators+=/pool_resource,for_next=1
-- actions.st_generators+=/rake,target_if=talent.bloodtalons.enabled&buff.bloodtalons.up&((remains<=7)&persistent_multiplier>dot.rake.pmultiplier*0.85)&target.time_to_die>4
-- actions.st_generators+=/brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))
-- actions.st_generators+=/moonfire_cat,target_if=refreshable
-- actions.st_generators+=/pool_resource,for_next=1
-- actions.st_generators+=/thrash_cat,if=refreshable&(variable.use_thrash=2|spell_targets.thrash_cat>1)
-- actions.st_generators+=/thrash_cat,if=refreshable&variable.use_thrash=1&buff.clearcasting.react
-- actions.st_generators+=/pool_resource,for_next=1
-- actions.st_generators+=/swipe_cat,if=spell_targets.swipe_cat>1
-- actions.st_generators+=/shred,if=dot.rake.remains>(action.shred.cost+action.rake.cost-energy)%energy.regen|buff.clearcasting.react