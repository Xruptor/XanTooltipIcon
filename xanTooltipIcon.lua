--I just wanted a simple mod that displayed the icon for items I click in chat.
--Sometimes I would tear my hair trying to find it in the bags because I didn't know
--what it looked like.
--Xruptor

local ADDON_NAME, addon = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local strsplit = strsplit
local tostring = tostring
local type = type
local select = select
local string_len = string.len
local string_format = string.format
local string_lower = string.lower
local string_match = string.match

local GetAchievementInfo = GetAchievementInfo
local GetAddOnMetadata = GetAddOnMetadata
local IsLoggedIn = IsLoggedIn
local hooksecurefunc = hooksecurefunc
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local print = print

local QUESTION_MARK_ICON = 134400
local OVERLAY_ACHIEVEMENT = "Interface\\AchievementFrame\\UI-Achievement-IconFrame"
local QUESTION_MARK_TEXTURE = "Interface\\Icons\\INV_Misc_QuestionMark"

if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local function OnEvent(self, event, ...)
	if event == "ADDON_LOADED" then
		local arg1 = ...
		if arg1 == ADDON_NAME then
			self:UnregisterEvent("ADDON_LOADED")
			self:RegisterEvent("PLAYER_LOGIN")
			if IsLoggedIn and IsLoggedIn() then
				self:EnableAddon()
				self:UnregisterEvent("PLAYER_LOGIN")
			end
		end
		return
	end

	if event == "PLAYER_LOGIN" then
		self:EnableAddon()
		self:UnregisterEvent("PLAYER_LOGIN")
		return
	end

	if self[event] then
		return self[event](self, event, ...)
	end
end

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent", OnEvent)

local function PrintMessage(message)
	if message == nil then return end
	local prefix = string_format("|cFF99CC33%s|r: ", ADDON_NAME)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(prefix .. message)
	else
		print(prefix .. message)
	end
end

local function RegisterSlashCommands()
	SLASH_XANTOOLTIPICON1 = "/xti"
	SLASH_XANTOOLTIPICON2 = "/xantooltipicon"

	local function PrintHelp()
		PrintMessage("Available commands:")
		PrintMessage("  /xti loaded - Toggle the addon loaded message at login.")
	end

	SlashCmdList["XANTOOLTIPICON"] = function(cmd)
		local subcmd = string_match(cmd or "", "^%s*(%S+)")
		if not subcmd then
			PrintHelp()
			return
		end

		subcmd = string_lower(subcmd)
		if subcmd == "loaded" or subcmd == "login" then
			XanTooltipIconDB.addonLoginMsg = not XanTooltipIconDB.addonLoginMsg
			PrintMessage("Addon loaded message at login: " .. (XanTooltipIconDB.addonLoginMsg and "|cFF20ff20ON|r" or "|cFFFF2020OFF|r"))
			return
		end

		PrintHelp()
	end
end

local function GetShortItemID(link)
	if link then
		if type(link) == "number" then
			link = tostring(link)
		end
		return link:match("item:(%d+):") or link:match("^(%d+):") or strsplit(";", link) or link
	end
end

local function GetSpellIcon(spellID)
	local spellInfo = (C_Spell and C_Spell.GetSpellInfo) or GetSpellInfo
	if not spellInfo then return nil end
	local result = spellInfo(spellID)
	if not result then return nil end
	if type(result) == "table" then
		return result.iconID
	end
	local _, _, icon = spellInfo(spellID)
	return icon
end

local function GetItemIcon(itemID)
	if not (C_Item and C_Item.GetItemIconByID) then return nil end
	local icon = C_Item.GetItemIconByID(itemID)
	if icon then return icon end
	local shortID = GetShortItemID(itemID)
	if shortID and shortID ~= itemID then
		return C_Item.GetItemIconByID(shortID)
	end
	return nil
end

local function GetAchievementIcon(achID)
	if not GetAchievementInfo then return nil end
	local _, _, _, _, _, _, _, _, _, icon = GetAchievementInfo(achID)
	return icon
end

local function ShowTooltipIcon(tooltip, link, ttType)
	if not (issecure() or not tooltip:IsForbidden()) then return end
	local button = tooltip.button
	if not button then return end

	local linkType, id

	if ttType then
		if ttType == 1 then -- Enum.TooltipDataType.Spell
			linkType = "spell"
		elseif ttType == 12 then -- Enum.TooltipDataType.Achievement
			linkType = "achievement"
		else
			linkType = "item"
		end
		id = link
	end

	if not (linkType and id) and link then
		linkType, id = link:match("^([^:]+):(%d+)")
	end

	if not (linkType and id) then
		return
	end

	local iconTex = QUESTION_MARK_ICON

	if linkType == "achievement" then
		local achIcon = GetAchievementIcon(id)
		if achIcon then
			button:SetNormalTexture(achIcon)
			button.doOverlay:Show()
			button.type = "achievement"
			return
		end
	elseif linkType == "spell" then
		button.doOverlay:Hide()
		local spellIcon = GetSpellIcon(id) or iconTex
		button:SetNormalTexture(spellIcon)
		button.type = "spell"
		return
	end

	local itemIcon = GetItemIcon(id) or iconTex
	button.doOverlay:Hide()
	button:SetNormalTexture(itemIcon)
	button.type = "item"
end

local function RegisterTooltip(tooltip)
	local b = CreateFrame("Button", nil, tooltip)
	b:SetWidth(37)
	b:SetHeight(37)
	b:SetPoint("TOPRIGHT", tooltip, "TOPLEFT", 0, -3)

	local t = b:CreateTexture(nil, "OVERLAY")
	t:SetTexture(GetAchievementInfo and OVERLAY_ACHIEVEMENT or QUESTION_MARK_TEXTURE)
	t:SetTexCoord(0, 0.5625, 0, 0.5625)
	t:SetPoint("CENTER", 0, 0)
	t:SetWidth(47)
	t:SetHeight(47)
	t:Hide()
	b.doOverlay = t

	tooltip.button = b
	tooltip.button.func = ShowTooltipIcon
end

local function hookTip()
	--create the button for the tooltip
	RegisterTooltip(ItemRefTooltip)

	ItemRefTooltip:HookScript("OnHide", function(self)
		local button = self.button
		if not button then return end
		button:SetNormalTexture(QUESTION_MARK_TEXTURE)
		button.doOverlay:Hide()
		button.type = nil
	end)

	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
		--Note: tooltip data type corresponds to the Enum.TooltipDataType types
		--i.e Enum.TooltipDataType.Unit it type 2
		--see https://github.com/Ketho/wow-ui-source-df/blob/e6d3542fc217592e6144f5934bf22c5d599c1f6c/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua
		local function OnTooltipSetAllTypes(tooltip, data)
			if tooltip ~= ItemRefTooltip or not data then return end
			ItemRefTooltip.button.func(ItemRefTooltip, data.hyperlink or data.id, data.type)
		end
		TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, OnTooltipSetAllTypes)
	else
		ItemRefTooltip:HookScript("OnTooltipSetItem", function(self)
			local name, link = self:GetItem()
			if name and string_len(name) > 0 and link then --recipes return nil for GetItem() so check for it
				self.button.func(self, link)
			end
		end)

		hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(self, link)
			if link then
				self.button.func(self, link)
			end
		end)
	end
end

function addon:EnableAddon()
	hookTip()

	XanTooltipIconDB = XanTooltipIconDB or {}
	if XanTooltipIconDB.addonLoginMsg == nil then
		XanTooltipIconDB.addonLoginMsg = true
	end

	RegisterSlashCommands()

	if XanTooltipIconDB.addonLoginMsg then
		local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
		local ver = (getMeta and getMeta(ADDON_NAME, "Version")) or "1.0"
		PrintMessage(string_format("[v|cFF20ff20%s|r] loaded:   /xti", ver))
	end
end
