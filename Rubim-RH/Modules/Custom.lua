---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Rubim.
--- DateTime: 01/06/2018 02:40
---

--local addonName, addonTable = ...;
local HL = HeroLib;
local Cache = HeroCache;
local Unit = HL.Unit;
local Player = Unit.Player;
local Target = Unit.Target;
local Spell = HL.Spell;
local Item = HL.Item;

--- ============================   CUSTOM   ============================
function RubimRH.TargetIsValid()
    local isValid = false

    if Target:Exists() and Player:CanAttack(Target) and not Target:IsDeadOrGhost() then
        isValid = true
    end
    HL.GetEnemies(8, true)

    if Cache.EnemiesCount[8] >= 1 then
        isValid = true
    end

    return isValid
end

local function round2(num, idp)
    mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function ttd(unit)
    unit = unit or "target";
    if thpcurr == nil then
        thpcurr = 0
    end
    if thpstart == nil then
        thpstart = 0
    end
    if timestart == nil then
        timestart = 0
    end
    if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
        if currtar ~= UnitGUID(unit) then
            priortar = currtar
            currtar = UnitGUID(unit)
        end
        if thpstart == 0 and timestart == 0 then
            thpstart = UnitHealth(unit)
            timestart = GetTime()
        else
            thpcurr = UnitHealth(unit)
            timecurr = GetTime()
            if thpcurr >= thpstart then
                thpstart = thpcurr
                timeToDie = 999
            else
                if ((timecurr - timestart) == 0) or ((thpstart - thpcurr) == 0) then
                    timeToDie = 999
                else
                    timeToDie = round2(thpcurr / ((thpstart - thpcurr) / (timecurr - timestart)), 2)
                end
            end
        end
    elseif not UnitExists(unit) or currtar ~= UnitGUID(unit) then
        currtar = 0
        priortar = 0
        thpstart = 0
        timestart = 0
        timeToDie = 9999999999999999
    end
    if timeToDie == nil then
        return 99999999
    else
        return timeToDie
    end
end

local activeUnitPlates = {}
local function AddNameplate(unitID)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitID)
    local unitframe = nameplate.UnitFrame

    -- store nameplate and its unitID
    activeUnitPlates[unitframe] = unitID
end

local function RemoveNameplate(unitID)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitID)
    local unitframe = nameplate.UnitFrame
    -- recycle the nameplate
    activeUnitPlates[unitframe] = nil
end

RubimRH.Listener:Add('Rubim_Events', 'NAME_PLATE_UNIT_ADDED', function(...)
    local unitID = ...
    AddNameplate(unitID)
end)

RubimRH.Listener:Add('Rubim_Events', 'NAME_PLATE_UNIT_REMOVED', function(...)
    local unitID = ...
    RemoveNameplate(unitID)
end)

function DiyingIn()
    HL.GetEnemies(10, true); -- Blood Boil
    totalmobs = 0
    dyingmobs = 0
    for _, CycleUnit in pairs(Cache.Enemies[10]) do
        totalmobs = totalmobs + 1;
        if CycleUnit:TimeToDie() <= 20 then
            dyingmobs = dyingmobs + 1;
        end
    end
    if dyingmobs == 0 then
        return 0
    else
        return totalmobs / dyingmobs
    end
end

function GetTotalMobs()
    local totalmobs = 0
    for reference, unit in pairs(activeUnitPlates) do
        if CheckInteractDistance(unit, 3) then
            totalmobs = totalmobs + 1
        end
    end
    return totalmobs
end

function GetMobsDying()
    local totalmobs = 0
    local dyingmobs = 0
    for reference, unit in pairs(activeUnitPlates) do
        if CheckInteractDistance(unit, 3) then
            totalmobs = totalmobs + 1
            if ttd(unit) <= 6 then
                dyingmobs = dyingmobs + 1
            end
        end
    end

    if totalmobs == 0 then
        return 0
    end

    return (dyingmobs / totalmobs) * 100
end

function GetMobs(spellId)
    local totalmobs = 0
    for reference, unit in pairs(activeUnitPlates) do
        if IsSpellInRange(GetSpellInfo(spellId), unit) then
            totalmobs = totalmobs + 1
        end
    end
    return totalmobs
end

local SpellsInterrupt = {
    194610, 198405, 194657, 199514, 199589, 216197, --Maw of Souls
    0
}

local function ShouldInterrupt()
    local importantCast = false
    local castName, _, _, _, castStartTime, castEndTime, _, _, notInterruptable, spellID = UnitCastingInfo("target")

    if castName == nil then
        local castName, nameSubtext, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible = UnitChannelInfo("unit")
    end

    if spellID == nil or notInterruptable == true then
        return false
    end

    for i, v in ipairs(SpellsInterrupt) do
        if spellID == v then
            importantCast = true
            break
        end
    end

    if spellID == nil or castInterruptable == false then
        return false
    end

    if int_smart == false then
        importantCast = false
    end

    if importantCast == false then
        return false
    end

    local timeSinceStart = (GetTime() * 1000 - castStartTime) / 1000
    local timeLeft = ((GetTime() * 1000 - castEndTime) * -1) / 1000
    local castTime = castEndTime - castStartTime
    local currentPercent = timeSinceStart / castTime * 100000
    local interruptPercent = math.random(10, 30)
    if currentPercent >= interruptPercent then
        return true
    end
    return false
end

local movedTimer = 0
function RubimRH.lastMoved()
    if Player:IsMoving() then
        movedTimer = GetTime()
    end
    return GetTime() - movedTimer
end

local playerGUID
local damageAmounts, damageTimestamps = {}, {}
damageInLast3Seconds = 0
local lastMeleeHit = 0

local combatLOG = CreateFrame("Frame")
combatLOG:RegisterEvent("PLAYER_LOGIN")
combatLOG:SetScript("OnEvent", function(self, event)
    playerGUID = UnitGUID("player")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:SetScript("OnEvent", function()
        local timestamp, event, arg3, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg12, arg13, arg14, arg15, arg16 = CombatLogGetCurrentEventInfo()

        if destGUID ~= playerGUID then
            return
        end
        local amount = nil
        if event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "RANGE_DAMAGE" then
            amount = arg15
            --amount = camount
        elseif event == "SWING_DAMAGE" then
            lastMeleeHit = GetTime()
            amount = arg12
        elseif event == "ENVIRONMENTAL_DAMAGE" then
            amount = arg13
        end
        if amount then
            -- Record new damage at the top of the log:
            tinsert(damageAmounts, 1, amount)
            tinsert(damageTimestamps, 1, timestamp)
            -- Clear out old entries from the bottom, and add up the remaining ones:
            local cutoff = timestamp - 3
            damageInLast3Seconds = 0
            for i = #damageTimestamps, 1, -1 do
                local timestamp = damageTimestamps[i]
                if timestamp < cutoff then
                    damageTimestamps[i] = nil
                    damageAmounts[i] = nil
                else
                    damageInLast3Seconds = damageInLast3Seconds + damageAmounts[i]
                end
            end
        end
    end)
end)

function RubimRH.lastSwing()
    return GetTime() - lastMeleeHit
end

function RubimRH.lastDamage(option)
    if option == nil then
        return damageInLast3Seconds
    else
        return (damageInLast3Seconds * 100) / UnitHealthMax("player")
    end
end

function RubimRH.SetFramePos(frame, x, y, w, h)
    local xOffset0 = 1
    if frame == nil then
        return
    end
    if GetCVar("gxMaximize") == "0" then
        xOffset0 = 0.9411764705882353
    end
    xPixel, yPixel, wPixel, hPixel = x, y, w, h
    xRes, yRes = string.match(({ GetScreenResolutions() })[GetCurrentResolution()], "(%d+)x(%d+)");
    uiscale = UIParent:GetScale();
    XCoord = xPixel * (768.0 / xRes) * GetMonitorAspectRatio() / uiscale / xOffset0
    YCoord = yPixel * (768.0 / yRes) / uiscale;
    Weight = wPixel * (768.0 / xRes) * GetMonitorAspectRatio() / uiscale
    Height = hPixel * (768.0 / yRes) / uiscale;
    if x and y then
        frame:SetPoint("TOPLEFT", XCoord, YCoord)
    end
    if w and h then
        frame:SetSize(Weight, Height)
    end
end

function RubimRH.ColorOnOff(boolean)
    if boolean == true then
        return "|cFF00FF00"
    else
        return "|cFFFF0000"
    end
end

RubimRH.castSpellSequence = {}
local lastCast = 1

function RubimRH.CastSequence()
    if not Player:AffectingCombat() then
        lastCast = 1
        return nil
    end

    if RubimRH.castSpellSequence ~= nil and Player:PrevGCD(1, RubimRH.castSpellSequence[lastCast]) then
        lastCast = lastCast + 1
    end

    if lastCast > #RubimRH.castSpellSequence then
        RubimRH.castSpellSequence = {}
        return nil
    end

    return RubimRH.castSpellSequence[lastCast]
end

RubimRH.queuedSpell = { nil, 0 }

function Spell:Queue(powerExtra)
    local powerEx = powerExtra or 0
    RubimRH.queuedSpell = { self, powerEx }
end

--/run RubimRH.queuedSpell ={ HeroLib.Spell(49020), 0 }

function Spell:Queued(powerEx)
    local powerExtra = powerEx or 0
    if RubimRH.queuedSpell[1] == nil then
        return false
    end

    local powerCost = GetSpellPowerCost(self:ID())
    local powerCostQ = GetSpellPowerCost(RubimRH.queuedSpell[1]:ID())
    local costType = nil
    local costTypeQ = nil
    local costs = nil
    local costsQ = nil

    for i = 1, #powerCost do
        if powerCost[i].cost > 0 then
            costType = powerCost[i].type
            break
        end
    end

    for i = 1, #powerCostQ do
        if powerCostQ[i].cost > 0 then
            costTypeQ = powerCostQ[i].type
            costsQ = powerCostQ[i].cost
            break
        end
    end
    if Player:PrevGCD(1, RubimRH.queuedSpell[1]) and UnitPower("player", costTypeQ) >= costsQ + RubimRH.queuedSpell[2] then
        RubimRH.queuedSpell = { nil, 0 }
        return false
    end

    if self:ID() == RubimRH.queuedSpell[1]:ID() then
        return false
    end

    if costType ~= costTypeQ then
        return false
    end
    return true
end

function Spell:IsAvailable (CheckPet)
    return CheckPet and IsSpellKnown(self.SpellID, true) or IsPlayerSpell(self.SpellID);
end

function Spell:IsCastableP (Range, AoESpell, ThisUnit, BypassRecovery, Offset)
    if not RubimRH.isSpellEnabled(self:ID()) then
        return false
    end
    if Range then
        local RangeUnit = ThisUnit or Target;
        return self:IsLearned() and self:CooldownRemainsP(BypassRecovery, Offset or "Auto") == 0 and RangeUnit:IsInRange(Range, AoESpell);
    else
        return self:IsLearned() and self:CooldownRemainsP(BypassRecovery, Offset or "Auto") == 0;
    end
end

function Spell:IsCastable(Range, AoESpell, ThisUnit)
    if not self:IsAvailable() or self:Queued() then
        return false
    end
    if not RubimRH.isSpellEnabled(self:ID()) then
        return false
    end
    if Range then
        local RangeUnit = ThisUnit or Target;
        return self:IsLearned() and self:CooldownUp() and RangeUnit:IsInRange(Range, AoESpell);
    else
        return self:IsLearned() and self:CooldownUp();
    end
end

function RubimRH.TargetNext(Range, Texture)
    if Target:Exists() then return nil end

    if Range == "Melee" then
        HL.GetEnemies(10, true);
        if RubimRH.db.profile.mainOption.startattack == true and Cache.EnemiesCount[10] >= 1 then
            return Texture
        end
    end

    if Range == "Ranged" then
        HL.GetEnemies(40, true);
        if RubimRH.db.profile.mainOption.startattack == true and Cache.EnemiesCount[40] >= 1 then
            return Texture
        end
    end

    return nil
end

function Spell:IsReady(Range, AoESpell, ThisUnit)
    if not self:IsAvailable() or self:Queued() then
        return false
    end
    if not RubimRH.isSpellEnabled(self:ID()) then
        return false
    end
        return self:IsCastable(Range, AoESpell, ThisUnit) and self:IsUsable();
end

function Spell:IsCastableMorph(Range, AoESpell, ThisUnit)
    if not RubimRH.isSpellEnabled(self:ID()) then
        return false
    end
    if Range then
        local RangeUnit = ThisUnit or Target;
        return self:IsLearned() and self:CooldownUp() and RangeUnit:IsInRange(Range, AoESpell);
    else
        return self:IsLearned() and self:CooldownUp();
    end
end

function Spell:IsReadyMorph(Range, AoESpell, ThisUnit)
    if not RubimRH.isSpellEnabled(self:ID()) then
        return false
    end
    if maxRange ~= nil then
        HL.GetEnemies(maxRange, true);
        if RubimRH.db.profile.mainOption.startattack == true and self:IsCastable() and self:IsUsable() and Cache.EnemiesCount[maxRange] >= 1 then
            return true
        end
    end
    return self:IsCastableMorph(Range, AoESpell, ThisUnit) and self:IsUsable();
end

function RubimRH.isSpellEnabled(spellIDs)
    local isEnabled = true

    for _, spellID in pairs(RubimRH.db.profile.mainOption.disabledSpells) do
        if spellIDs == spellID then
            isEnabled = false
        end
    end
    return isEnabled
end

function RubimRH.addSpellDisabled(spellIDs)
    local exists = false
    for pos, spellID in pairs(RubimRH.db.profile.mainOption.disabledSpells) do
        if spellIDs == spellID then
            table.remove(RubimRH.db.profile.mainOption.disabledSpells, pos)
            exists = true
            print("|cFF00FF00Unblocking|r - " .. GetSpellInfo(spellIDs) .. " (" .. spellIDs .. ")")
            break
        end
    end

    if exists == false then
        table.insert(RubimRH.db.profile.mainOption.disabledSpells, spellIDs)
        print("|cFFFF0000Blocking|r - " .. GetSpellInfo(spellIDs) .. " (" .. spellIDs .. ")")
    end
end

function Spell:Cast()
        return RubimRH.GetTexture(self)
end

function Spell:SetTexture(id)
    self.TextureID = id
end

function RubimRH.GetTexture (Object)
    -- Spells
    local SpellID = Object.SpellID;

    if SpellID then
        if Object.TextureSpellID ~= nil then
            if #Object.TextureSpellID == 1 then
                return GetSpellTexture(Object.TextureSpellID[1]);
            else
                return Object.TextureSpellID[2];
            end
        else
            return GetSpellTexture(SpellID);
        end

    end
    -- Items
    local ItemID = Object.ItemID;
    if ItemID then
        local TextureCache = Cache.Persistent.Texture.Item;
        if not TextureCache[ItemID] then
            -- name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice
            local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(ItemID);
            TextureCache[ItemID] = texture;
        end
        return TextureCache[ItemID];
    end
end


-- Player On Cast Success Listener
HL:RegisterForSelfCombatEvent(function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
    for i, spell in ipairs(RubimRH.allSpells) do
        if SpellID == spell.SpellID then
            spell.LastCastTime = HL.GetTime()
            spell.LastHitTime = HL.GetTime() + spell:TravelTime()
        end
    end
end, "SPELL_CAST_SUCCESS")

-- Pet On Cast Success Listener
HL:RegisterForPetCombatEvent(function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
    for i, spell in ipairs(RubimRH.allSpells) do
        if SpellID == spell.SpellID then
            spell.LastCastTime = HL.GetTime()
            spell.LastHitTime = HL.GetTime() + spell:TravelTime()
        end
    end
end, "SPELL_CAST_SUCCESS")

-- Player Aura Applied Listener
HL:RegisterForSelfCombatEvent(function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
    for i, spell in ipairs(RubimRH.allSpells) do
        if SpellID == spell.SpellID then
            spell.LastAppliedOnPlayerTime = HL.GetTime()
        end
    end
end, "SPELL_AURA_APPLIED")

-- Player Aura Removed Listener
HL:RegisterForSelfCombatEvent(function(_, _, _, _, _, _, _, _, _, _, _, SpellID)
    for i, spell in ipairs(RubimRH.allSpells) do
        if SpellID == spell.SpellID then
            spell.LastRemovedFromPlayerTime = HL.GetTime()
        end
    end
end, "SPELL_AURA_REMOVED")

local PvPDummyUnits = {
    -- City (SW, Orgri, ...)
    [114840] = true, -- Raider's Training Dummy
}

function Unit:IsPvPDummy()
    local NPCID = self:NPCID()
    return NPCID >= 0 and PvPDummyUnits[NPCID] == true
end

-- Incoming damage as percentage of Unit's max health
<<<<<<< HEAD
function RubimRH.IncDmgPercentage(UIDENTIFIER)
    UIDENTIFIER = UIDENTIFIER or "player"
    local IncomingDPS = (RubimRH.getDMG(UIDENTIFIER) / UnitHealthMax(UIDENTIFIER)) * 100
=======
function Unit:IncDmgPercentage()
    local IncomingDPS = (RubimRH.getDMG(self.UnitID) / self:MaxHealth()) * 100
>>>>>>> fab427a82e10cc2000e05f86669d34b906f6c022
    return (math.floor((IncomingDPS * ((100) + 0.5)) / (100)))
end