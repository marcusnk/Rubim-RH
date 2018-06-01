---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Rubim.
--- DateTime: 01/06/2018 02:34
---

devRub = false
local debugframe = CreateFrame("Frame", "DebugFrame", UIParent)
local debugtext = debugframe:CreateFontString("DebugText", "OVERLAY")
if devRub == true then
    debugVarText = "DebugText"

    local event = function()
        if DEBUGonetime == nil then
            debugframe:SetWidth(240)
            debugframe:SetHeight(40)
            debugframe:SetPoint("CENTER", 0, 0) -- Baseado no chat?
            local tex = debugframe:CreateTexture("BACKGROUND")
            tex:SetAllPoints()
            tex:SetTexture(0, 0, 0); tex:SetAlpha(0.5)
            DEBUGonetime = 1
        end

        debugtext:SetFontObject(GameFontNormalSmall)
        debugtext:SetJustifyH("CENTER") --
        debugtext:SetPoint("CENTER", debugframe, "CENTER", 0, 0) -- Centralizado sempre / TODO Salvar localização em variavél.
        debugtext:SetFont("Fonts\\FRIZQT__.TTF", 20)
        debugtext:SetShadowOffset(1, -1)

        local t = GetTime()
        debugframe:SetScript("OnUpdate", function() --se tiver com problemas, colocar um delay usando o GetTime()
            if t - GetTime() <= 0.2 then
                debugtext:SetText(debugVarText)
                t = GetTime()
            end
        end)

        debugframe:SetMovable(true)
        debugframe:EnableMouse(true)
        debugframe:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and not self.isMoving then
                self:StartMoving();
                self.isMoving = true;
            end
        end)
        debugframe:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and self.isMoving then
                self:StopMovingOrSizing();
                self.isMoving = false;
            end
        end)
        debugframe:SetScript("OnHide", function(self)
            if ( self.isMoving ) then
                self:StopMovingOrSizing();
                self.isMoving = false;
            end
        end)
    end
end

debugframe:SetScript("OnEvent", event)
debugframe:RegisterEvent("PLAYER_LOGIN")