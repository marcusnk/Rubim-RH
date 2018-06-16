---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Rubim.
--- DateTime: 06/06/2018 05:05
---
local healingToggle = true

function roundscale(num, idp)
    mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

if healingToggle then

    local AceGUI = LibStub("AceGUI-3.0")

    local HealTargeting = CreateFrame("Frame");
    HealTargeting:SetScript("OnUpdate", function(self, sinceLastUpdate)
        HealTargeting:onUpdate(sinceLastUpdate);
    end);

    function HealTargeting:onUpdate(sinceLastUpdate)
        self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
        if (self.sinceLastUpdate >= 0.2) then
            -- in seconds
            --MainFunctions
            self.sinceLastUpdate = 0;
        end
    end

    local height
    local currentHeight = tonumber(string.match(({ GetScreenResolutions() })[GetCurrentResolution()], "%d+x(%d+)"))
    if roundscale(GetScreenHeight()) == currentHeight then
        height = GetScreenHeight()
    elseif GetCVar("useuiscale") == "1" and GetCVar("gxMaximize") == "1" then
        height = currentHeight
    elseif GetCVar("useuiscale") == "0" and GetCVar("gxMaximize") == "0" then
        height = roundscale(GetScreenHeight())
    elseif GetCVar("useuiscale") == "1" and GetCVar("gxMaximize") == "0" then
        SetCVar("useuiScale", 0)
        return
    end
    local myscale1 = 0.42666670680046 * (1080 / height)
    local myscale2 = 0.17777778208256 * (1080 / height)

    function roundscale(num, idp)
        mult = 10 ^ (idp or 0)
        return math.floor(num * mult + 0.5) / mult
    end

    function SetFrameScale(frame, input, x, y, w, h)
        local xOffset0 = 1
        if frame:GetEffectiveScale() == nil then
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
        local myscale = input * (1080 / height)
        if frame:GetEffectiveScale() ~= myscale then
            frame:SetPoint("TOPLEFT", XCoord, YCoord)
            frame:SetSize(Weight, Height)
            frame:SetScale(myscale / (frame:GetParent() and frame:GetParent():GetEffectiveScale() or 1))
        end
    end

    TargetColor = CreateFrame("Frame", nil, UIParent)
    TargetColor:SetBackdrop(nil)
    TargetColor:SetFrameStrata("HIGH")
    TargetColor:SetSize(1, 1)
    TargetColor:SetScale(1);
    TargetColor:SetPoint("TOPLEFT", 442, 0)
    TargetColor.texture = TargetColor:CreateTexture(nil, "TOOLTIP")
    TargetColor.texture:SetAllPoints(true)
    TargetColor.texture:SetColorTexture(0, 0, 0, 1.0)
    TargetColor:Show()

    SetFrameScale(TargetColor, 0.71111112833023, 442, 0, 1, 1)

    function CalculateHP(t)
        incomingheals = UnitGetIncomingHeals(t) and UnitGetIncomingHeals(t) or 0
        local PercentWithIncoming = 100 * (UnitHealth(t) + incomingheals) / UnitHealthMax(t)
        local ActualWithIncoming = (UnitHealthMax(t) - (UnitHealth(t) + incomingheals))
        return PercentWithIncoming, ActualWithIncoming
    end

    function CanHeal(t)
        if UnitInRange(t)
                --Missing LOS Check
                and UnitCanCooperate("player", t)
                and not UnitIsCharmed(t)
                and not UnitIsDeadOrGhost(t)
                and UnitIsConnected(t)
        --          and UnitDebuffID(t,104451) == nil -- Ice Tomb
        --          and UnitDebuffID(t,76577) == nil -- Smoke Bomb
        then
            return true
        else
            return false
        end
    end

    function HealingEngine(MO, LOWHP, ACTUALHP)
        R_Tanks = { }
        local MouseoverCheck = MO or false
        local ActualHP = ACTUALHP or false
        local LowHPTarget = LOWHP or 80
        members = { { Unit = "player", HP = CalculateHP("player"), GUID = UnitGUID("player"), AHP = select(2, CalculateHP("player")) } }

        -- Check if the Player is apart of the Custom Table
        for i = 1, #R_CustomT do
            if UnitGUID("player") == R_CustomT[i].GUID then
                R_CustomT[i].Unit = "player"
                R_CustomT[i].HP = CalculateHP("player")
                R_CustomT[i].AHP = select(2, CalculateHP("player"))
            end
        end

        if IsInRaid() then
            group = "raid"
        elseif IsInGroup() then
            group = "party"
        end

        for i = 1, GetNumGroupMembers() do
            local member, memberhp = group .. i, CalculateHP(group .. i)

            -- Checking all Party/Raid Members for Range/Health
            if CanHeal(member) then
                -- Checking if Member has threat
                if UnitThreatSituation(member) == 3 then
                    memberhp = memberhp - 3
                end
                -- Checking if Member has Beacon on them
                if UnitAura(member, GetSpellInfo(53563)) then
                    memberhp = memberhp + 3
                end
                -- Searing Plasma Check
                --          if UnitDebuffID(member, 109379) then memberhp = memberhp - 9 end
                -- Checking if Member is a tank
                if UnitGroupRolesAssigned(member) == "TANK" then
                    memberhp = memberhp - 1
                    table.insert(R_Tanks, { Unit = member, HP = memberhp, AHP = select(2, CalculateHP(member)) })
                end
                -- If they are in the Custom Table add their info in
                for i = 1, #R_CustomT do
                    if UnitGUID(member) == R_CustomT[i].GUID then
                        R_CustomT[i].Unit = member
                        R_CustomT[i].HP = memberhp
                        R_CustomT[i].AHP = select(2, CalculateHP(member))
                    end
                end

                table.insert(members, { Unit = group .. i, HP = memberhp, GUID = UnitGUID(group .. i), AHP = select(2, CalculateHP(group .. i)) })
            end

            -- Checking Pets in the group
            if CanHeal(group .. i .. "pet") then
                local memberpet, memberpethp = nil, nil
                if UnitAffectingCombat("player") then
                    memberpet = group .. i .. "pet"
                    memberpethp = CalculateHP(group .. i .. "pet") * 2
                else
                    memberpet = group .. i .. "pet"
                    memberpethp = CalculateHP(group .. i .. "pet")
                end

                -- Checking if Pet is apart of the CustomTable
                for i = 1, #R_CustomT do
                    if UnitGUID(memberpet) == R_CustomT[i].GUID then
                        R_CustomT[i].Unit = memberpet
                        R_CustomT[i].HP = memberpethp
                        R_CustomT[i].AHP = select(2, CalculateHP(memberpet))
                    end
                end
                table.insert(members, { Unit = memberpet, HP = memberpethp, GUID = UnitGUID(memberpet), AHP = select(2, CalculateHP(memberpet)) })
            end
        end

        -- So if we pass that ActualHP is true, then we will sort by most health missing. If not, we sort by lowest % of health.
        if not ActualHP then
            table.sort(members, function(x, y)
                return x.HP < y.HP
            end)
            if #R_Tanks > 0 then
                table.sort(R_Tanks, function(x, y)
                    return x.HP < y.HP
                end)
            end
        elseif ActualHP then
            table.sort(members, function(x, y)
                return x.AHP > y.AHP
            end)
            if #R_Tanks > 0 then
                table.sort(R_Tanks, function(x, y)
                    return x.AHP > y.AHP
                end)
            end
        end

        -- Checking Priority Targeting
        --    if CanHeal("target") then
        --        table.sort(members, function(x)
        --            return UnitIsUnit("target", x.Unit)
        --        end)
        if CanHeal("mouseover") and GetMouseFocus() ~= WorldFrame and MouseoverCheck then
            table.sort(members, function(x)
                return UnitIsUnit("mouseover", x.Unit)
            end)
        end
    end

    R_CustomT = { }
    local t = GetTime()
    if t - GetTime() <= 0.2 then
        t = GetTime()
    end

    -- Setting Low HP Members variable for AoE Healing
    function AoEHealing(HP)
        local lowhpmembers = 0
        for i = 1, #members do
            if members[i].HP < HP then
                lowhpmembers = lowhpmembers + 1
            end
        end
        return lowhpmembers
    end

    local healingTarget = "None"
    local healingTargetG = "None"
    local function setHealingTarget(tar)
        local target = tar or nil
        if target == nil and members[1].HP < 100 then
            healingTarget = members[1].Unit
            healingTargetG = members[1].GUID
        end
    end

    function getHealingTarget(option)
        if UnitGUID("target") == healingTargetG then
            return nil
        end

        if option == nil then
            return healingTarget
        else
            return healingTargetG
        end
    end

    function setColorTarget()
        TargetColor.texture:SetColorTexture(0, 0, 0, 1.0)
        if healingTarget == nil or ((UnitGUID("target") or UnitGuid("player")) == healingTargetG) then
            healingTarget = "None"
            healingTargetG = "None"
            TargetColor.texture:SetColorTexture(0, 0, 0, 1.0)
            return
        end

        --Party
        if getHealingTarget() == "party1" then
            TargetColor.texture:SetColorTexture(0.192157, 0.878431, 0.015686, 1.0)
            return
        end
        if getHealingTarget() == "party2" then
            TargetColor.texture:SetColorTexture(0.780392, 0.788235, 0.745098, 1.0)
            return
        end
        if getHealingTarget() == "party3" then
            TargetColor.texture:SetColorTexture(0.498039, 0.184314, 0.521569, 1.0)
            return
        end
        if getHealingTarget() == "party4" then
            TargetColor.texture:SetColorTexture(0.627451, 0.905882, 0.882353, 1.0)
            return
        end

        if getHealingTarget() == "player" then
            TargetColor.texture:SetColorTexture(0.145098, 0.658824, 0.121569, 1.0)
            return
        end

        --PartyPET
        if getHealingTarget() == "partypet1" then
            TargetColor.texture:SetColorTexture(0.486275, 0.176471, 1.000000, 1.0)
            return
        end
        if getHealingTarget() == "partypet2" then
            TargetColor.texture:SetColorTexture(0.031373, 0.572549, 0.152941, 1.0)
            return
        end
        if getHealingTarget() == "partypet3" then
            TargetColor.texture:SetColorTexture(0.874510, 0.239216, 0.239216, 1.0)
            return
        end
        if getHealingTarget() == "partypet4" then
            TargetColor.texture:SetColorTexture(0.117647, 0.870588, 0.635294, 1.0)
            return
        end

        --Raid
        if getHealingTarget() == "raid1" then
            TargetColor.texture:SetColorTexture(0.192157, 0.878431, 0.015686, 1.0)
            return
        end
        if getHealingTarget() == "raid2" then
            TargetColor.texture:SetColorTexture(0.780392, 0.788235, 0.745098, 1.0)
            return
        end
        if getHealingTarget() == "raid3" then
            TargetColor.texture:SetColorTexture(0.498039, 0.184314, 0.521569, 1.0)
            return
        end
        if getHealingTarget() == "raid4" then
            TargetColor.texture:SetColorTexture(0.627451, 0.905882, 0.882353, 1.0)
            return
        end
        if getHealingTarget() == "raid5" then
            TargetColor.texture:SetColorTexture(0.145098, 0.658824, 0.121569, 1.0)
            return
        end
        if getHealingTarget() == "raid6" then
            TargetColor.texture:SetColorTexture(0.639216, 0.490196, 0.921569, 1.0)
            return
        end
        if getHealingTarget() == "raid7" then
            TargetColor.texture:SetColorTexture(0.172549, 0.368627, 0.427451, 1.0)
            return
        end
        if getHealingTarget() == "raid8" then
            TargetColor.texture:SetColorTexture(0.949020, 0.333333, 0.980392, 1.0)
            return
        end
        if getHealingTarget() == "raid9" then
            TargetColor.texture:SetColorTexture(0.109804, 0.388235, 0.980392, 1.0)
            return
        end
        if getHealingTarget() == "raid10" then
            TargetColor.texture:SetColorTexture(0.615686, 0.694118, 0.435294, 1.0)
            return
        end
        if getHealingTarget() == "raid11" then
            TargetColor.texture:SetColorTexture(0.066667, 0.243137, 0.572549, 1.0)
            return
        end
        if getHealingTarget() == "raid12" then
            TargetColor.texture:SetColorTexture(0.113725, 0.129412, 1.000000, 1.0)
            return
        end
        if getHealingTarget() == "raid13" then
            TargetColor.texture:SetColorTexture(0.592157, 0.023529, 0.235294, 1.0)
            return
        end
        if getHealingTarget() == "raid14" then
            TargetColor.texture:SetColorTexture(0.545098, 0.439216, 1.000000, 1.0)
            return
        end
        if getHealingTarget() == "raid15" then
            TargetColor.texture:SetColorTexture(0.890196, 0.800000, 0.854902, 1.0)
            return
        end
        if getHealingTarget() == "raid16" then
            TargetColor.texture:SetColorTexture(0.513725, 0.854902, 0.639216, 1.0)
            return
        end
        if getHealingTarget() == "raid17" then
            TargetColor.texture:SetColorTexture(0.078431, 0.541176, 0.815686, 1.0)
            return
        end
        if getHealingTarget() == "raid18" then
            TargetColor.texture:SetColorTexture(0.109804, 0.184314, 0.666667, 1.0)
            return
        end
        if getHealingTarget() == "raid19" then
            TargetColor.texture:SetColorTexture(0.650980, 0.572549, 0.098039, 1.0)
            return
        end
        if getHealingTarget() == "raid20" then
            TargetColor.texture:SetColorTexture(0.541176, 0.466667, 0.027451, 1.0)
            return
        end
        if getHealingTarget() == "raid21" then
            TargetColor.texture:SetColorTexture(0.000000, 0.988235, 0.462745, 1.0)
            return
        end
        if getHealingTarget() == "raid22" then
            TargetColor.texture:SetColorTexture(0.211765, 0.443137, 0.858824, 1.0)
            return
        end
        if getHealingTarget() == "raid23" then
            TargetColor.texture:SetColorTexture(0.949020, 0.949020, 0.576471, 1.0)
            return
        end
        if getHealingTarget() == "raid24" then
            TargetColor.texture:SetColorTexture(0.972549, 0.800000, 0.682353, 1.0)
            return
        end
        if getHealingTarget() == "raid25" then
            TargetColor.texture:SetColorTexture(0.031373, 0.619608, 0.596078, 1.0)
            return
        end
        if getHealingTarget() == "raid26" then
            TargetColor.texture:SetColorTexture(0.670588, 0.925490, 0.513725, 1.0)
            return
        end
        if getHealingTarget() == "raid27" then
            TargetColor.texture:SetColorTexture(0.647059, 0.945098, 0.031373, 1.0)
            return
        end
        if getHealingTarget() == "raid28" then
            TargetColor.texture:SetColorTexture(0.058824, 0.490196, 0.054902, 1.0)
            return
        end
        if getHealingTarget() == "raid29" then
            TargetColor.texture:SetColorTexture(0.050980, 0.992157, 0.239216, 1.0)
            return
        end
        if getHealingTarget() == "raid30" then
            TargetColor.texture:SetColorTexture(0.949020, 0.721569, 0.388235, 1.0)
            return
        end
        if getHealingTarget() == "raid31" then
            TargetColor.texture:SetColorTexture(0.254902, 0.749020, 0.627451, 1.0)
            return
        end
        if getHealingTarget() == "raid32" then
            TargetColor.texture:SetColorTexture(0.470588, 0.454902, 0.603922, 1.0)
            return
        end
        if getHealingTarget() == "raid33" then
            TargetColor.texture:SetColorTexture(0.384314, 0.062745, 0.266667, 1.0)
            return
        end
        if getHealingTarget() == "raid34" then
            TargetColor.texture:SetColorTexture(0.639216, 0.168627, 0.447059, 1.0)
            return
        end
        if getHealingTarget() == "raid35" then
            TargetColor.texture:SetColorTexture(0.874510, 0.058824, 0.400000, 1.0)
            return
        end
        if getHealingTarget() == "raid36" then
            TargetColor.texture:SetColorTexture(0.925490, 0.070588, 0.713725, 1.0)
            return
        end
        if getHealingTarget() == "raid37" then
            TargetColor.texture:SetColorTexture(0.098039, 0.803922, 0.905882, 1.0)
            return
        end
        if getHealingTarget() == "raid38" then
            TargetColor.texture:SetColorTexture(0.243137, 0.015686, 0.325490, 1.0)
            return
        end
        if getHealingTarget() == "raid39" then
            TargetColor.texture:SetColorTexture(0.847059, 0.376471, 0.921569, 1.0)
            return
        end
        if getHealingTarget() == "raid40" then
            TargetColor.texture:SetColorTexture(0.341176, 0.533333, 0.231373, 1.0)
            return
        end
        if getHealingTarget() == "raidpet1" then
            TargetColor.texture:SetColorTexture(0.458824, 0.945098, 0.784314, 1.0)
            return
        end
        if getHealingTarget() == "raidpet2" then
            TargetColor.texture:SetColorTexture(0.239216, 0.654902, 0.278431, 1.0)
            return
        end
        if getHealingTarget() == "raidpet3" then
            TargetColor.texture:SetColorTexture(0.537255, 0.066667, 0.905882, 1.0)
            return
        end
        if getHealingTarget() == "raidpet4" then
            TargetColor.texture:SetColorTexture(0.333333, 0.415686, 0.627451, 1.0)
            return
        end
        if getHealingTarget() == "raidpet5" then
            TargetColor.texture:SetColorTexture(0.576471, 0.811765, 0.011765, 1.0)
            return
        end
        if getHealingTarget() == "raidpet6" then
            TargetColor.texture:SetColorTexture(0.517647, 0.164706, 0.627451, 1.0)
            return
        end
        if getHealingTarget() == "raidpet7" then
            TargetColor.texture:SetColorTexture(0.439216, 0.074510, 0.941176, 1.0)
            return
        end
        if getHealingTarget() == "raidpet8" then
            TargetColor.texture:SetColorTexture(0.984314, 0.854902, 0.376471, 1.0)
            return
        end
        if getHealingTarget() == "raidpet9" then
            TargetColor.texture:SetColorTexture(0.082353, 0.286275, 0.890196, 1.0)
            return
        end
        if getHealingTarget() == "raidpet10" then
            TargetColor.texture:SetColorTexture(0.058824, 0.003922, 0.964706, 1.0)
            return
        end
        if getHealingTarget() == "raidpet11" then
            TargetColor.texture:SetColorTexture(0.956863, 0.509804, 0.949020, 1.0)
            return
        end
        if getHealingTarget() == "raidpet12" then
            TargetColor.texture:SetColorTexture(0.474510, 0.858824, 0.031373, 1.0)
            return
        end
        if getHealingTarget() == "raidpet13" then
            TargetColor.texture:SetColorTexture(0.509804, 0.882353, 0.423529, 1.0)
            return
        end
        if getHealingTarget() == "raidpet14" then
            TargetColor.texture:SetColorTexture(0.337255, 0.647059, 0.427451, 1.0)
            return
        end
        if getHealingTarget() == "raidpet15" then
            TargetColor.texture:SetColorTexture(0.611765, 0.525490, 0.352941, 1.0)
            return
        end
        if getHealingTarget() == "raidpet16" then
            TargetColor.texture:SetColorTexture(0.921569, 0.129412, 0.913725, 1.0)
            return
        end
        if getHealingTarget() == "raidpet17" then
            TargetColor.texture:SetColorTexture(0.117647, 0.933333, 0.862745, 1.0)
            return
        end
        if getHealingTarget() == "raidpet18" then
            TargetColor.texture:SetColorTexture(0.733333, 0.015686, 0.937255, 1.0)
            return
        end
        if getHealingTarget() == "raidpet19" then
            TargetColor.texture:SetColorTexture(0.819608, 0.392157, 0.686275, 1.0)
            return
        end
        if getHealingTarget() == "raidpet20" then
            TargetColor.texture:SetColorTexture(0.823529, 0.976471, 0.541176, 1.0)
            return
        end
        if getHealingTarget() == "raidpet21" then
            TargetColor.texture:SetColorTexture(0.043137, 0.305882, 0.800000, 1.0)
            return
        end
        if getHealingTarget() == "raidpet22" then
            TargetColor.texture:SetColorTexture(0.737255, 0.270588, 0.760784, 1.0)
            return
        end
        if getHealingTarget() == "raidpet23" then
            TargetColor.texture:SetColorTexture(0.807843, 0.368627, 0.058824, 1.0)
            return
        end
        if getHealingTarget() == "raidpet24" then
            TargetColor.texture:SetColorTexture(0.364706, 0.078431, 0.078431, 1.0)
            return
        end
        if getHealingTarget() == "raidpet25" then
            TargetColor.texture:SetColorTexture(0.094118, 0.901961, 1.000000, 1.0)
            return
        end
        if getHealingTarget() == "raidpet26" then
            TargetColor.texture:SetColorTexture(0.772549, 0.690196, 0.047059, 1.0)
            return
        end
        if getHealingTarget() == "raidpet27" then
            TargetColor.texture:SetColorTexture(0.415686, 0.784314, 0.854902, 1.0)
            return
        end
        if getHealingTarget() == "raidpet28" then
            TargetColor.texture:SetColorTexture(0.470588, 0.733333, 0.047059, 1.0)
            return
        end
        if getHealingTarget() == "raidpet29" then
            TargetColor.texture:SetColorTexture(0.619608, 0.086275, 0.572549, 1.0)
            return
        end
        if getHealingTarget() == "raidpet30" then
            TargetColor.texture:SetColorTexture(0.517647, 0.352941, 0.678431, 1.0)
            return
        end
        if getHealingTarget() == "raidpet31" then
            TargetColor.texture:SetColorTexture(0.003922, 0.149020, 0.694118, 1.0)
            return
        end
        if getHealingTarget() == "raidpet32" then
            TargetColor.texture:SetColorTexture(0.454902, 0.619608, 0.831373, 1.0)
            return
        end
        if getHealingTarget() == "raidpet33" then
            TargetColor.texture:SetColorTexture(0.674510, 0.741176, 0.050980, 1.0)
            return
        end
        if getHealingTarget() == "raidpet34" then
            TargetColor.texture:SetColorTexture(0.560784, 0.713725, 0.784314, 1.0)
            return
        end
        if getHealingTarget() == "raidpet35" then
            TargetColor.texture:SetColorTexture(0.400000, 0.721569, 0.737255, 1.0)
            return
        end
        if getHealingTarget() == "raidpet36" then
            TargetColor.texture:SetColorTexture(0.094118, 0.274510, 0.392157, 1.0)
            return
        end
        if getHealingTarget() == "raidpet37" then
            TargetColor.texture:SetColorTexture(0.298039, 0.498039, 0.462745, 1.0)
            return
        end
        if getHealingTarget() == "raidpet38" then
            TargetColor.texture:SetColorTexture(0.125490, 0.196078, 0.027451, 1.0)
            return
        end
        if getHealingTarget() == "raidpet39" then
            TargetColor.texture:SetColorTexture(0.937255, 0.564706, 0.368627, 1.0)
            return
        end
        if getHealingTarget() == "raidpet40" then
            TargetColor.texture:SetColorTexture(0.929412, 0.592157, 0.501961, 1.0)
            return
        end

        --Stuff
        if getHealingTarget() == "player" then
            TargetColor.texture:SetColorTexture(0.788235, 0.470588, 0.858824, 1.0)
            return
        end
        if getHealingTarget() == "focus" then
            TargetColor.texture:SetColorTexture(0.615686, 0.227451, 0.988235, 1.0)
            return
        end
        if getHealingTarget() == PLACEHOLDER then
            TargetColor.texture:SetColorTexture(0.411765, 0.760784, 0.176471, 1.0)
            return
        end
        if getHealingTarget() == PLACEHOLDER then
            TargetColor.texture:SetColorTexture(0.780392, 0.286275, 0.415686, 1.0)
            return
        end
        if getHealingTarget() == PLACEHOLDER then
            TargetColor.texture:SetColorTexture(0.584314, 0.811765, 0.956863, 1.0)
            return
        end
        if getHealingTarget() == PLACEHOLDER then
            TargetColor.texture:SetColorTexture(0.513725, 0.658824, 0.650980, 1.0)
            return
        end
        if getHealingTarget() == PLACEHOLDER then
            TargetColor.texture:SetColorTexture(0.913725, 0.180392, 0.737255, 1.0)
            return
        end
        if getHealingTarget() == PLACEHOLDER then
            TargetColor.texture:SetColorTexture(0.576471, 0.250980, 0.160784, 1.0)
            return
        end
        if getHealingTarget() == PLACEHOLDER then
            TargetColor.texture:SetColorTexture(0.803922, 0.741176, 0.874510, 1.0)
            return
        end
        if getHealingTarget() == PLACEHOLDER then
            TargetColor.texture:SetColorTexture(0.647059, 0.874510, 0.713725, 1.0)
            return
        end
        if getHealingTarget() == PLACEHOLDER then
            --was party5
            TargetColor.texture:SetColorTexture(0.007843, 0.301961, 0.388235, 1.0)
            return
        end
        if getHealingTarget() == PLACEHOLDER then
            --was party5pet
            TargetColor.texture:SetColorTexture(0.572549, 0.705882, 0.984314, 1.0)
            return
        end
    end

    function getLowestHP(HP)
        HealingEngine()
        if members[1].HP <= HP then
            setHealingTarget()
            setColorTarget()
            return true
        end
        return false
    end

    function checkTarget()
        local castName, _, _, _, castStartTime, castEndTime, _, _, notInterruptable, spellID = UnitCastingInfo("target")
        if castName == nil then
            local castName, nameSubtext, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible = UnitChannelInfo("unit")
        end
        if castName ~= nil then
            return false
        end
        if UnitGUID("target") == healingTargetG then
            return true
        end
        return false
    end

    local total = 0
    local function onUpdate(self, elapsed)
        total = total + elapsed
        if total >= 0.2 then
            getLowestHP(95)
            total = 0
        end
    end

    local updateHealing = CreateFrame("frame")
    updateHealing:SetScript("OnUpdate", onUpdate)

    --Not Needed
    local function DrawGroup1(container)
        local Checkbox = AceGUI:Create("CheckBox")
        Checkbox:SetLabel("Holy Shock:")
        Checkbox:SetRelativeWidth(0.5)
        container:AddChild(Checkbox)

        local Slider = AceGUI:Create("Slider")
        Slider:SetLabel("Percent:")
        Slider:SetRelativeWidth(0.5)
        Slider:SetSliderValues(5, 100, 5)
        container:AddChild(Slider)

        local Checkbox = AceGUI:Create("CheckBox")
        Checkbox:SetLabel("Holy Light:")
        Checkbox:SetRelativeWidth(0.5)
        container:AddChild(Checkbox)

        local Slider2 = AceGUI:Create("Slider")
        Slider2:SetLabel("Percent:")
        Slider2:SetRelativeWidth(0.5)
        Slider2:SetSliderValues(5, 100, 5)
        container:AddChild(Slider2)

        local Checkbox = AceGUI:Create("CheckBox")
        Checkbox:SetLabel("Flash of Light:")
        Checkbox:SetRelativeWidth(0.5)
        container:AddChild(Checkbox)

        local Slider3 = AceGUI:Create("Slider")
        Slider3:SetLabel("Percent:")
        Slider3:SetRelativeWidth(0.5)
        Slider3:SetSliderValues(5, 100, 5)
        container:AddChild(Slider3)
    end

    -- function that draws the widgets for the second tab
    local function DrawGroup2(container)
        local desc = AceGUI:Create("Label")
        desc:SetText("This is Tab 2")
        desc:SetFullWidth(true)
        container:AddChild(desc)

        local button = AceGUI:Create("Button")
        button:SetText("Tab 2 Button")
        button:SetWidth(200)
        container:AddChild(button)
    end

    -- Callback function for OnGroupSelected
    local function SelectGroup(container, event, group)
        container:ReleaseChildren()
        if group == "tab1" then
            DrawGroup1(container)
        elseif group == "tab2" then
            DrawGroup2(container)
        end
    end

    -- Create the frame container
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Paladin Holy")
    frame:SetStatusText("Rubim")
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
    end)
    -- Fill Layout - the TabGroup widget will fill the whole frame
    --frame:SetLayout("Flow")
    frame:SetLayout("Fill")
    frame:SetWidth(300)
    frame:SetHeight(280)

    local tab = AceGUI:Create("TabGroup")
    tab:SetLayout("Flow")
    -- Setup which tabs to show
    tab:SetTabs({ { text = "Spells", value = "tab1" }, { text = "Cooldowns", value = "tab2" } })
    -- Register callback
    tab:SetCallback("OnGroupSelected", SelectGroup)
    -- Set initial Tab (this will fire the OnGroupSelected callback)
    tab:SelectTab("tab1")

    -- add to the frame container
    frame:AddChild(tab)

end

