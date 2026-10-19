
local ADDON = ...

-- Saved settings ------------------------------------------------------------------------------
local defaults = {rangeCheck = true}
local db = defaults

-- elite / rare nameplate border ------------------------------------------------------------------------------
local STAR_X, STAR_Y = 40, -18
local STAR_SIZE = 16
local GOLD_STAR = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Elite:40:37:0:0:256:128:138:256:0:128|t"
local SILVER_STAR = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite:40:37:0:0:256:128:138:256:0:128|t"

local stars = {}

local function GetPlateScale(plate)
    local unitFrame = plate.UnitFrame
    local bar = unitFrame and unitFrame.healthBar
    local width = bar and bar:GetWidth()

    if width and width > 0 then
        return width / 160
    end

    return 1
end

local function UpdateStar(plate, unit)
    local fs = stars[plate]
    if not fs then
        fs = plate:CreateFontString(nil, "OVERLAY")
        stars[plate] = fs
    end

    local scale = GetPlateScale(plate)

    if fs.appliedScale ~= scale then
        fs:ClearAllPoints()
        fs:SetPoint("RIGHT", plate, "RIGHT", STAR_X * scale, STAR_Y * scale)
        fs:SetFont("Fonts\\ARIALN.TTF", STAR_SIZE * scale, "OUTLINE")
        fs:SetScale(1)
        fs.appliedScale = scale
    end

    local classification = UnitClassification(unit)
    local text = ""

    if classification == "elite" or classification == "rareelite" then
        text = GOLD_STAR
    elseif classification == "rare" then
        text = SILVER_STAR
    end

    if fs.starText ~= text then
        fs:SetText(text)
        fs.starText = text
    end
end

-- range check nameplate ------------------------------------------------------------------------------
local X, Y = 22, -17
local SIZE = 12
local TARGET_SCALE = 1.2

local texts = {}

local function Apply(fs, isTarget)
    fs:SetFont("Fonts\\ARIALN.TTF", isTarget and SIZE * TARGET_SCALE or SIZE, "OUTLINE")
    fs.isTarget = isTarget
end

C_Timer.NewTicker(0.2, function()
    local canCheck = db.rangeCheck and not InCombatLockdown() and not IsInInstance()

    for i = 1, 40 do
        local unit = "nameplate" .. i
        local plate = C_NamePlate.GetNamePlateForUnit(unit)

        if plate then
            UpdateStar(plate, unit)


            local fs = texts[plate]
            local scale = GetPlateScale(plate)

            if not fs then
                fs = plate:CreateFontString(nil, "OVERLAY")
                texts[plate] = fs
                fs.appliedScale = nil
                fs.isTarget = nil
            end

            local isTarget = UnitIsUnit(unit, "target")

            if fs.appliedScale ~= scale or fs.isTarget ~= isTarget then
                fs:ClearAllPoints()
                fs:SetPoint("RIGHT", plate, "RIGHT", X * scale, Y * scale)
                fs:SetFont(
                    "Fonts\\ARIALN.TTF",
                    SIZE * scale * (isTarget and TARGET_SCALE or 1),
                    "OUTLINE"
                )
                fs.appliedScale = scale
                fs.isTarget = isTarget
            end

            fs:SetText("●")
            fs:SetShown(canCheck and not CheckInteractDistance(unit, 4))



        end
    end
end)

-- Options panel ------------------------------------------------------------------------------
local function CreateOptions()
    local panel = CreateFrame("Frame")
    panel.name = "NameplatesEliteForever"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(panel.name)

    local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)

    local text = checkbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    text:SetText("Enable +30yd range check")

    checkbox:SetScript("OnShow", function(self)
        self:SetChecked(db.rangeCheck)
    end)

    checkbox:SetScript("OnClick", function(self)
        db.rangeCheck = self:GetChecked()
    end)

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 4, -8)
    note:SetText("Displays a white dot at the bottom-right of the nameplate when the unit is over 30 yards.")

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)

    SLASH_NAMEPLATESELITEFOREVER1 = "/nef"
    SlashCmdList.NAMEPLATESELITEFOREVER = function()
        Settings.OpenToCategory(category:GetID())
    end
end

-- Initialization ------------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON then return end

    NameplatesEliteForeverDB = NameplatesEliteForeverDB or {}
    for key, value in pairs(defaults) do
        if NameplatesEliteForeverDB[key] == nil then
            NameplatesEliteForeverDB[key] = value
        end
    end
    db = NameplatesEliteForeverDB

    CreateOptions()
    self:UnregisterEvent("ADDON_LOADED")
end)
