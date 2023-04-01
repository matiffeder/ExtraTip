local ExtraTip = {
	version = 1.31,
}
_G.ExtraTip = ExtraTip
local ChangeAlpha
local loading = 0
local update = 0
local health = {}
local def = {
		["All"] = true,
		["Width"] = 10,
		["Alpha"] = 1,
		["Player"] = true,
		["Monster"] = true,
		["Pet"] = true,
		["1v1"] = true,
		["Mana"] = false,
		["Hbar"] = true,
		["Cbar"] = true,
		["Class"] = true,
		["Diff"] = false,
		["Buff"] = true,
		["BuffSec"] = 61,
		["Fix"] = false,
		["Anchor"] = "BOTTOMRIGHT",
		["X"] = 0,
		["Y"] = 0,
}

local function Print(str, ...)
	DEFAULT_CHAT_FRAME:AddMessage(str:format(...), 1, 1, 1)
end

local function Dec(value)
	local k
	while true do
		value, k = string.gsub(value, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return value
end

function SlashCmdList.ExtraTip(editbox, msg)
	if tonumber(msg)~=nil then
		ExtraTipSet["Width"] = tonumber(msg)
		Print("|cffFF285FExtraTip|r - %s|cffFF285F%s|r", ExtraTip.Lang["Width"], msg)
	else
		if XBARVERSION and XBARVERSION>=1.51 then
			XAddon_ShowPage("ExtraTipGUI")
		else
			ToggleUIFrame(ExtraTipGUI)
		end
	end
end

function SlashCmdList.ExtraTipBuff(editbox, msg)
	if tonumber(msg)~=nil then
		ExtraTipSet["BuffSec"] = tonumber(msg)
		Print("|cffFF285FExtraTip|r - %s|cffFF285F%s|r", ExtraTip.Lang["BuffDesc"], msg)
	end
end

SLASH_ExtraTip1 = "/et"
SLASH_ExtraTip2 = "/extratip"
SLASH_ExtraTipBuff1 = "/etbuff"
SLASH_ExtraTipBuff2 = "/etb"

local function PopClick(key)
	if key=="LBUTTON" then
		XAddon_ShowPage("ExtraTipGUI")
	else
		if ExtraTipSet["All"] then
			ExtraTipSet["All"] = false
		else
			ExtraTipSet["All"] = true
		end
		ExtraTipGUIEnable:SetChecked(ExtraTipSet["All"])
	end
end

local function PopText()
	if ExtraTipSet["All"] then
		return "ExtraTip - "..ON
	else
		return "ExtraTip - "..C_OFF
	end
end

--fixed and simplify pbInfo MobHealth code
local function UpdateMobHealth(target)
	if UnitExists(target) and not UnitIsPlayer(target) and UnitLevel(target)>0 then
		local name = UnitName(target)
		local ml = UnitLevel(target)
		local mc = UnitClass(target)
		local HMaxInfo = UnitChangeHealth(target)
		if UnitHealth(target)==100 and (health[name..ml..mc] or 0)<HMaxInfo then
			health[name..ml..mc] = HMaxInfo
		end
	end
end

local function GetNameSex()
	local sex = UnitSex("mouseover")
	local st = ""

	if UnitIsPlayer("mouseover") then
		if sex==0 then
			st = UnitName("mouseover").."|cffAADDFF".." (♂)|r"
		else
			st = UnitName("mouseover").."|cffFFAADD".." (♀)|r"
		end
	elseif UnitMaster("mouseover")~=nil then
		st = "|cffA6D7FF"..UnitName("mouseover").."|r"
	elseif not UnitIsPlayer("mouseover") and UnitCanAttack("player","mouseover") then
		if sex==2 then
			st = "|cff5276B5("..C_ELITE..")|r ".."|cffFFCC00"..UnitName("mouseover").."|r"
		elseif sex>2 then
			st = "|cffB32516("..ExtraTip.Lang["Boss"]..")|r ".."|cffFFCC00"..UnitName("mouseover").."|r"
		else
			st = "|cffFFCC00"..UnitName("mouseover").."|r"
		end
	end
	return st
end

local function GetClassColor(class)
	local c = "|cffFFFFFF"
	if not ExtraTipSet["Class"] then
		return c
	end

	if class==TEXT("SYS_CLASSNAME_MAGE") then
		c = "|cffFF8800"
	elseif class==TEXT("SYS_CLASSNAME_AUGUR") then
		c = "|cff0080FF"
	elseif class==TEXT("SYS_CLASSNAME_WARRIOR") then
		c = "|cffFF285F"
	elseif class==TEXT("SYS_CLASSNAME_THIEF") then
		c = "|cff88EECC"
	elseif class==TEXT("SYS_CLASSNAME_RANGER") then
		c = "|cffA6FF00"
	elseif class==TEXT("SYS_CLASSNAME_KNIGHT") then
		c = "|cffFFF666"
	elseif class==TEXT("SYS_CLASSNAME_DRUID") then
		c = "|cff0CF310"
	elseif class==TEXT("SYS_CLASSNAME_WARDEN") then
		c = "|cffCC22DD"
	elseif class==TEXT("SYS_CLASSNAME_HARPSYN") then
		c = "|cff8B35FF"
	elseif class==TEXT("SYS_CLASSNAME_PSYRON") then
		c = "|cff6363FF"
	end
	return c
end

local function Difficulty(level)
	local c = "|cffFFFFFF"
	if not ExtraTipSet["Diff"] then
		return c
	end

	if level>=7 then
		c = "|cffFF0000"
	elseif level>=4 then
		c = "|cffFFFF00"
	elseif level>=-3 then
		c = "|cff00C4F2"
	elseif level>=-6 then
		c = "|cff00FF00"
	elseif level>=-9 then
		c = "|cffFFFFFF"
	else
		c = "|cff999999"
	end
	return c
end

local function GetManaColor(skill)
	local c
	if skill==1 then
		c = "|cff88AAFF"
	elseif skill==2 then
		c = "|cffFFFF88"
	elseif skill==3 then
		c = "|cff88FF88"
	elseif skill==4 then
		c = "|cffC388FF"
	end
	return c
end

local function QuestAdd(orig)
	for line in string.gmatch(orig, "([^\n]+)") do
		local name
		for i = 1, GetNumQuestBookButton_QuestBook() do
			local _, _, title = GetQuestInfo(i)
			local r1, r2 = string.find(line, title, 1, true)
			if r1 and r1>0 then
				name = string.sub(line, r1, r2)
				GameTooltip:AddDoubleLine(name, "|cffFFFF00"..line:match("(%d+ / %d+)").."|r" or "")
				break
			end
		end
		if not name then
			local desc, count = string.match(line, "(.+)%( (%d+ / %d+) %)")
			if not count then desc, count = line, "" end
			GameTooltip:AddDoubleLine(desc, "|cffFFFF00"..count.."|r")
		end
	end
end

local function UpdateText()
	local uch = "|cffFF0000"
	local ucm, ucs
	if UnitManaType("mouseover")==1 then
		local MPercent = math.ceil(UnitMana("mouseover") / UnitMaxMana("mouseover") * 100)
		if MPercent==100 then
			ucm = GetManaColor(UnitManaType("mouseover"))..Dec(UnitMana("mouseover")).." / ".."100%|r"
		else
			ucm = GetManaColor(UnitManaType("mouseover"))..Dec(UnitMana("mouseover")).." / "..Dec(UnitMaxMana("mouseover")).." ("..MPercent.."%)|r"
		end
	else
		ucm = GetManaColor(UnitManaType("mouseover"))..Dec(UnitMana("mouseover")).." / "..Dec(UnitMaxMana("mouseover")).."|r"
	end
	if UnitSkillType("mouseover")==1 then
		local SPercent = math.ceil(UnitSkill("mouseover") / UnitMaxSkill("mouseover") * 100)
		if SPercent==100 then
			ucs = GetManaColor(UnitSkillType("mouseover"))..Dec(UnitSkill("mouseover")).." / ".."100%|r"
		else
			ucs = GetManaColor(UnitSkillType("mouseover"))..Dec(UnitSkill("mouseover")).." / "..Dec(UnitMaxSkill("mouseover")).." ("..SPercent.."%)|r"
		end
	else
		ucs = GetManaColor(UnitSkillType("mouseover"))..Dec(UnitSkill("mouseover")).." / "..Dec(UnitMaxSkill("mouseover")).."|r"
	end
	if not UnitIsDeadOrGhost("mouseover") then
		if UnitIsPlayer("mouseover") or UnitMaster("mouseover")~=nil then
			local HPercent = math.ceil(UnitHealth("mouseover") / UnitMaxHealth("mouseover") * 100)
			if HPercent==100 then
				uch = "|cff00FF00"..Dec(UnitHealth("mouseover")).." / ".."100%|r"
			elseif HPercent>30 then
				uch = "|cff00FF00"..Dec(UnitHealth("mouseover")).." / "..Dec(UnitMaxHealth("mouseover")).." ("..HPercent.."%)|r"
			else
				uch = uch..Dec(UnitHealth("mouseover")).." / "..Dec(UnitMaxHealth("mouseover")).." ("..HPercent.."%)|r"
			end

		else
			UpdateMobHealth("mouseover")
			local HMax = health[UnitName("mouseover")..UnitLevel("mouseover")..UnitClass("mouseover")] or 0
			local HString = HMax>0 and Dec(math.ceil(HMax * UnitHealth("mouseover") / 100)).." / "..Dec(HMax).." ("..UnitHealth("mouseover").."%)|r" or UnitHealth("mouseover").."%|r"
			if UnitHealth("mouseover")==100 then
				uch = uch..Dec(UnitChangeHealth("mouseover")).." / ".."100%|r"
			elseif UnitHealth("mouseover")>20 then
				uch = uch..HString
			else
				uch = "|cff00FF00"..HString.."|r"
			end
		end
	end

	if UnitIsDeadOrGhost("mouseover") then
		uch = "|cffAAAAAA"..ExtraTip.Lang["Dead"].."|r"
	end

	local ut
	if UnitExists("mouseovertarget") then
		ut = "→ "..GetClassColor(UnitClass("mouseovertarget")).."Lv"..UnitLevel("mouseovertarget").." |r"..UnitName("mouseovertarget")
	end

	local questMsg = UnitQuestMsg("mouseover")
	local mc, sc = UnitClass("mouseover")
	local ml, sl = UnitLevel("mouseover")

	GameTooltip:ClearLines()
	GameTooltip:AddLine(GetNameSex())
	if UnitMaster("mouseover")~=nil then
		GameTooltip:AddLine( string.format(TEXT("TOOLTIP_PET_NAME"), UnitMaster("mouseover"), " ") )
	end
	if UnitCanAttack("player", "mouseover") and not UnitIsPlayer("mouseover") then
		local diffLevel = UnitLevel("mouseover") - UnitLevel("player")
		GameTooltip:AddLine(Difficulty(diffLevel).."Lv"..ml.."|r - "..GetClassColor(mc)..mc.."|r")
		if sl>0 then
			GameTooltip:AddLine(Difficulty(diffLevel).."Lv"..sl.."|r - "..GetClassColor(sc)..sc.."|r")
		end
	else
		GameTooltip:AddLine("Lv"..ml.." - "..GetClassColor(mc)..mc.."|r")
		if sl>0 then
			GameTooltip:AddLine("Lv"..sl.." - "..GetClassColor(sc)..sc.."|r ")
		end
	end
	GameTooltip:AddLine(UnitRace("mouseover"))
	GameTooltip:AddLine(uch)
	if ExtraTipSet["Mana"] then
		if UnitMaxMana("mouseover")>0 then
			GameTooltip:AddLine(ucm)
		end
		if UnitMaxSkill("mouseover")>0 then
			GameTooltip:AddLine(ucs)
		end
	end
	GameTooltip:AddLine(ut)

	if questMsg~=nil and questMsg~="" then
		GameTooltip:AddLine("\n")
		QuestAdd(questMsg)
	end
	if DailyNotes then
		DailyNotes.UPDATE_MOUSEOVER_UNIT()
	end
	if vyCardInfo then
		vyMouseOverUnit()
	end
	if ZzaburCompendium then
		ZzaburCompendium.GameTooltipUpdate()
	end
	if yaCIt then
		yaCIt.MouseOverUnit()
	end

	GameTooltip:SetWidth(GameTooltip:GetWidth() + ExtraTipSet["Width"])
	if ExtraTipBuffTooltip:IsVisible() then
		if GameTooltip:GetWidth()<ExtraTipBuffTooltip:GetWidth() then
			GameTooltip:SetWidth(ExtraTipBuffTooltip:GetWidth())
		elseif GameTooltip:GetWidth()>=ExtraTipBuffTooltip:GetWidth() then
			ExtraTipBuffTooltip:SetWidth(GameTooltip:GetWidth())
		end
	end
	if ExtraTipSet["Fix"] and GameTooltip.cursor then
		GameTooltip.cursor = nil
		GameTooltip:ClearAllAnchors()
		GameTooltip:SetAnchor(ExtraTipSet["Anchor"], ExtraTipSet["Anchor"], "ExtraTipDummy", 0, 0)
	end
	ExtraTipHealthBar:SetWidth(GameTooltip:GetWidth() - 6)
end

local function ShowOrNot()
	if not ExtraTipSet["1v1"] then
		if UnitIsUnit("playertarget","mouseover") and UnitIsUnit("mouseovertarget", "player") then
			GameTooltip:Hide()
			return
		end
	end
	if not ExtraTipSet["Player"] then
		if UnitIsPlayer("mouseover") then
			return
		end
	end
	if not ExtraTipSet["Monster"] then
		if UnitCanAttack("player","mouseover") and not UnitIsPlayer("mouseover") then
			return
		end
	end
	if not ExtraTipSet["Pet"] then
		if UnitMaster("mouseover")~=nil then
			return
		end
	end

	if UnitExists("mouseover") and (UnitCanAttack("player", "mouseover") or UnitIsPlayer("mouseover") or UnitMaster("mouseover")~=nil) then
		UpdateText()
		GameTooltip:SetBackdropTileAlpha(ExtraTipSet["Alpha"])
		ExtraTipBuffTooltip:SetBackdropTileAlpha(ExtraTipSet["Alpha"])
	else
		GameTooltip:SetBackdropTileAlpha(1.0)
		if ExtraTipSet["Fix"] and not UnitExists("mouseover") then
			GameTooltip:Hide()
		end
	end
end

function ExtraTip.OnLoad(this)
	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("LOADING_END")
	this:RegisterEvent("UNIT_TARGET_CHANGED")
	this:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	this:RegisterEvent("UNIT_HEALTH")
	this:RegisterEvent("UNIT_MANA")
	ExtraTipSet = {}

	local lang = GetLanguage():upper()
	local _, err = loadfile("Interface/Addons/ExtraTip/Locales/"..lang..".lua")
	if err then
		Print("|cff993333ExtraTip can't find translation, ENUS.lua loaded.|r")
		dofile("Interface/Addons/ExtraTip/Locales/ENUS.lua")
	else
		dofile("Interface/Addons/ExtraTip/Locales/"..lang..".lua")
	end
end

function ExtraTip.OnEvent(event)
	if event=="VARIABLES_LOADED" then
		for k,v in pairs(def) do
			if ExtraTipSet[k]==nil then
				ExtraTipSet[k] = v
			end
		end
		SaveVariables("ExtraTipSet")
		Print("|cffFF285FExtraTip %s|r %s |cffFF285F/et|r %s", ExtraTip.version, ExtraTip.Lang["Load"], ExtraTip.Lang["ToConfig"])
		ExtraTipDummy:ClearAllAnchors()
		ExtraTipDummy:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", ExtraTipSet["X"], ExtraTipSet["Y"])
		PetHeadHealthBarValueText:SetScale(0.85)
		PetHeadHealthBarValueText:SetText(UnitHealth("pet").."/"..UnitMaxHealth("pet"))
		PetHeadManaBarValueText:SetScale(0.85)
		PetHeadManaBarValueText:SetText(UnitMana("pet").."/"..UnitMaxMana("pet"))
		if XBARVERSION and XBARVERSION>=1.51 then
			XAddon_Register(
			{gui={{
				name = "ExtraTip",
				version = ExtraTip.version,
				window = "ExtraTipGUI",
			}},
			popup={{
				icon = "Interface/Addons/ExtraTip/ET_H",
				GetText = function() return PopText() end,
				GetTooltip = function() return "/et, /et XX, /etb XX\n\n"..ExtraTip.Lang["XAddonTip1"].."\n"..ExtraTip.Lang["XAddonTip2"] end,
				OnClick = function(this, key) PopClick(key) end,
			}}})
		end
	end
	if loading==0 and event=="LOADING_END" then
		if DailyNotes then
			DailyNotesFrame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		end
		if vyCardInfo then
			vyCardInfo:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		end
		if ZzaburCompendium then
			CardBookFrame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		end
		if yaCIt then
			yaCItFrame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		end
		loading = nil
	end

	if ExtraTipSet["All"] then
		if event=="UPDATE_MOUSEOVER_UNIT" or (event=="UNIT_HEALTH" and arg1~="player") or (event=="UNIT_MANA" and arg1~="player") then
			ShowOrNot()
		end
		if event=="UNIT_TARGET_CHANGED" or (event=="UNIT_HEALTH" and arg1=="target") then
			UpdateMobHealth("target")
			if UnitExists("target") then
				if TargetHealthBarValueText:GetText()=="100%" then
					TargetHealthBarValueText:SetText(UnitChangeHealth("target").."/100%")
				end
				if not UnitIsPlayer("target") and UnitHealth("target")<100 then
					UpdateMobHealth("target")
					local HMaxT = health[UnitName("target")..UnitLevel("target")..UnitClass("target")] or 0
					if HMaxT>0 then
						TargetHealthBarValueText:SetText(math.ceil(HMaxT * UnitHealth("target") / 100).."/"..HMaxT)
					end
				end
			end
		end
	end
end

function ExtraTip.HealthBar(this)
	if UnitExists("mouseover") and not UnitIsPlayer("mouseover") and UnitCanAttack("player", "mouseover") then
		UpdateMobHealth("mouseover")
		local HMax = health[UnitName("mouseover")..UnitLevel("mouseover")..UnitClass("mouseover")] or 0
		if UnitHealth("mouseover")>20 then
			this:SetBarColor(1, 0, 0, 0.5)
		else
			this:SetBarColor(0, 1, 0, 0.5)
		end
		this:Show()
		this:SetValue(UnitHealth("mouseover"))
		ExtraTipHealthBarText:SetText(HMax>0 and math.ceil(HMax * UnitHealth("mouseover") / 100).." / "..UnitHealth("mouseover").."%|r" or UnitHealth("mouseover").."%|r")
	elseif UnitExists("mouseover") and UnitIsPlayer("mouseover") or UnitMaster("mouseover")~=nil then
		local HPercent = math.ceil(UnitHealth("mouseover") / UnitMaxHealth("mouseover") * 100)
		if HPercent>30 then
			this:SetBarColor(0, 1, 0, 0.5)
		else
			this:SetBarColor(1, 0, 0, 0.5)
		end
		this:Show()
		this:SetValue(HPercent)
		ExtraTipHealthBarText:SetText(UnitHealth("mouseover").." / "..HPercent.."%")
	else
		this:Hide()
	end
end

function ExtraTip.CastingBar(this)
	if UnitExists("mouseover") and UnitCanAttack("player", "mouseover") then
		local cName, cMax, cNow = UnitCastingTime("mouseover")
		if cName then
			local cLeft = math.ceil( (cMax - cNow) * 10) / 10
			this:Show()
			this:SetValue(math.ceil(cNow / cMax * 100))
			ExtraTipCastingBarText:SetText(cName..": "..cLeft)
			if ExtraTipCastingBarText:GetWidth()>(GameTooltip:GetWidth() - 6) then
				GameTooltip:SetWidth(ExtraTipCastingBarText:GetWidth() + 12)
			end
			this:SetWidth(GameTooltip:GetWidth() - 6)
			ExtraTipHealthBar:SetWidth(GameTooltip:GetWidth() - 6)
			ExtraTipCastingBarSpark:ClearAllAnchors()
			ExtraTipCastingBarSpark:SetAnchor("CENTER", "LEFT", "$parent", math.ceil(cNow / cMax * this:GetWidth()), 0)
			if cLeft==0 then
				ChangeAlpha = 1
			else
				ChangeAlpha = 0
				this:SetAlpha(1)
			end
		else
			this:Hide()
		end
	else
		this:Hide()
	end
end

function ExtraTip.CastingBarFadeOut(this, elapsedTime)
	if ChangeAlpha==1 then
		local alpha = this:GetAlpha() - elapsedTime
		if alpha>0 then
			this:SetAlpha(alpha)
		else
			this:Hide()
			ChangeAlpha = 0
			this:SetAlpha(1)
		end
	end
end

function ExtraTip.BuffEvent(this)
	if ExtraTipSet["All"] and ExtraTipSet["Buff"] then
		ExtraTip.BuffTime(this)
		if ExtraTipSet["Fix"] and UnitExists("mouseover") and (UnitIsPlayer("mouseover") or UnitMaster("mouseover")~=nil) then
			GameTooltip.cursor = nil
			GameTooltip:ClearAllAnchors()
			if this:IsVisible() and string.find(ExtraTipSet["Anchor"], "BOTTOM") then
				this:ClearAllAnchors()
				this:SetAnchor(ExtraTipSet["Anchor"], ExtraTipSet["Anchor"], "ExtraTipDummy", 0, 0)
				GameTooltip:SetAnchor("BOTTOMLEFT", "TOPLEFT", this, 0, 0)
			else
				GameTooltip:SetAnchor(ExtraTipSet["Anchor"], ExtraTipSet["Anchor"], "ExtraTipDummy", 0, 0)
				this:ClearAllAnchors()
				this:SetAnchor("TOPLEFT", "BOTTOMLEFT", "GameTooltip", 0, 0)
			end
		end
	end
end

function ExtraTip.BuffTime(this)
	if UnitExists("mouseover") and (UnitIsPlayer("mouseover") or UnitMaster("mouseover")~=nil) then
		this:SetText("")
		this:Hide()
		for i = 1, 24 do
			local bName = UnitBuff("mouseover", i)
			if bName then
				local bTime = UnitBuffLeftTime("mouseover", i)
				if bTime and bTime<ExtraTipSet["BuffSec"] then
					this:Show()
					this:AddLine(bName.." : |cffFFFF00"..math.floor(bTime).."|r")
				end
			end
		end
		if GameTooltip:GetWidth()<this:GetWidth() then
			GameTooltip:SetWidth(this:GetWidth())
		elseif GameTooltip:GetWidth()>this:GetWidth() then
			this:SetWidth(GameTooltip:GetWidth())
		end
		ExtraTipCastingBar:SetWidth(GameTooltip:GetWidth() - 6)
		ExtraTipHealthBar:SetWidth(GameTooltip:GetWidth() - 6)
	else
		this:Hide()
	end
end

function ExtraTip.BuffTimeUpdate(this, elapsedTime)
	if ExtraTipSet["All"] and ExtraTipSet["Buff"] then
		update = update + elapsedTime
		if update>1 then
			ExtraTip.BuffTime(this)
			update = 0
		end
	end
end

function ExtraTip.GUIAlpha(this)
	local value = string.format("%.2f",this:GetValue())
	ExtraTipGUIAlphaText:SetText("|cffFFD200"..ExtraTip.Lang["Alpha"].."|r"..(value*100).."%")
	ExtraTipSet["Alpha"] = tonumber(value)
end

function ExtraTip.GUIShow(this)
	ExtraTipGUIEnable:SetChecked(ExtraTipSet["All"])
	ExtraTipGUIWidth:SetText(ExtraTipSet["Width"])
	ExtraTipGUIFix:SetChecked(ExtraTipSet["Fix"])
	ExtraTipGUIX:SetText(ExtraTipSet["X"])
	ExtraTipGUIY:SetText(ExtraTipSet["Y"])
	ExtraTipGUIAlpha:SetValue(ExtraTipSet["Alpha"])
	ExtraTipGUIPlayer:SetChecked(ExtraTipSet["Player"])
	ExtraTipGUIMonster:SetChecked(ExtraTipSet["Monster"])
	ExtraTipGUIPet:SetChecked(ExtraTipSet["Pet"])
	ExtraTipGUI1v1:SetChecked(ExtraTipSet["1v1"])
	ExtraTipGUIMana:SetChecked(ExtraTipSet["Mana"])
	ExtraTipGUIHealthBar:SetChecked(ExtraTipSet["Hbar"])
	ExtraTipGUICastingBar:SetChecked(ExtraTipSet["Cbar"])
	ExtraTipGUIClass:SetChecked(ExtraTipSet["Class"])
	ExtraTipGUIDifficulty:SetChecked(ExtraTipSet["Diff"])
	ExtraTipGUIBuff:SetChecked(ExtraTipSet["Buff"])
	ExtraTipGUIBuffSec:SetText(ExtraTipSet["BuffSec"])

	ExtraTipGUITitle:SetText("ExtraTip")
	ExtraTipGUIWidthName:SetText(ExtraTip.Lang["Width"])
	ExtraTipGUIFixName:SetText(ExtraTip.Lang["Fix"])
	ExtraTipGUIDummy:SetText(ExtraTip.Lang["Dummy"])
	ExtraTipGUIXName:SetText("X: ")
	ExtraTipGUIYName:SetText("Y: ")
	ExtraTipGUIPlayerName:SetText(ExtraTip.Lang["Player"])
	ExtraTipGUIMonsterName:SetText(ExtraTip.Lang["Monster"])
	ExtraTipGUIPetName:SetText(ExtraTip.Lang["Pet"])
	ExtraTipGUI1v1Name:SetText(ExtraTip.Lang["1v1"])
	ExtraTipGUIManaName:SetText(RUNE_EXCHANGE_TYPE_MP)
	ExtraTipGUIHealthBarName:SetText(ExtraTip.Lang["Hbar"])
	ExtraTipGUICastingBarName:SetText(ExtraTip.Lang["Cbar"])
	ExtraTipGUIClassName:SetText(ExtraTip.Lang["Class"])
	ExtraTipGUIDifficultyName:SetText(ExtraTip.Lang["Diff"])
	ExtraTipGUIBuffName:SetText(ExtraTip.Lang["Buff"])
	ExtraTipGUIBuffSecName:SetText(ExtraTip.Lang["BuffSec"])
	ExtraTipGUIVersion:SetText(ExtraTip.version)
	if XBARVERSION and XBARVERSION>=1.51 then
		XAddon_Page(this)
		XAddon_HideBack1(this)
		ExtraTipGUITitle:SetText("")
		ExtraTipGUIVersion:SetText("")
	end
end

function ExtraTip.DummyShow()
	_G["ExtraTipDummy"..ExtraTipSet["Anchor"]]:SetChecked(true)
end

function ExtraTip.DummyMove(this)
	this:StopMovingOrSizing()
	this:Hide()
	_, _, _, ExtraTipSet["X"], ExtraTipSet["Y"] = this:GetAnchor()
	ExtraTipGUIX:SetText(ExtraTipSet["X"])
	ExtraTipGUIY:SetText(ExtraTipSet["Y"])
end

function ExtraTip.Offset()
	ExtraTipSet["X"] = ExtraTipGUIX:GetText()
	ExtraTipSet["Y"] = ExtraTipGUIY:GetText()
	ExtraTipDummy:ClearAllAnchors()
	ExtraTipDummy:SetAnchor("TOPLEFT", "TOPLEFT", "UIParent", ExtraTipSet["X"], ExtraTipSet["Y"])
end
