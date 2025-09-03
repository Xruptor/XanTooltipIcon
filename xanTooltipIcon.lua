--I just wanted a simple mod that displayed the icon for items I click in chat.
--Sometimes I would tear my hair trying to find it in the bags because I didn't know
--what it looked like.
--Xruptor

local debugf = tekDebug and tekDebug:GetFrame("xanTooltipIcon")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

--local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		if event == "ADDON_LOADED" then
			local arg1 = ...
			if arg1 and arg1 == ADDON_NAME then
				self:UnregisterEvent("ADDON_LOADED")
				self:RegisterEvent("PLAYER_LOGIN")
			end
			return
		end
		if IsLoggedIn() then
			self:EnableAddon(event, ...)
			self:UnregisterEvent("PLAYER_LOGIN")
		end
		return
	end
	if self[event] then
		return self[event](self, event, ...)
	end
end)

local function GetShortItemID(link)
	if link then
		if type(link) == "number" then link = tostring(link) end
		return link:match("item:(%d+):") or link:match("^(%d+):") or strsplit(";", link) or link
	end
end

local function showTooltipIcon(tooltip, link, ttType)
	if not (issecure() or not tooltip:IsForbidden()) then return end

	local linkType, id
	local typeSwitch = false

	if ttType then
		if ttType == 1 then
			linkType = "spell"
		elseif ttType == 12 then
			linkType = "achievement"
		else
			linkType = "item"
		end
		id = id or link

		if id and linkType then
			typeSwitch = true
		end
	end

	if not typeSwitch then
		linkType, id = link:match("^([^:]+):(%d+)")
	end

	local xGetNumSlots = (C_Spell and C_Spell.GetSpellInfo) or GetSpellInfo
	local iconTex = 134400 --question mark

	if GetAchievementInfo and linkType and linkType == "achievement" and id then
		if GetAchievementInfo(id) and select(10,GetAchievementInfo(id)) then
			tooltip.button:SetNormalTexture(select(10,GetAchievementInfo(id)))
			tooltip.button.doOverlay:Show()
			tooltip.button.type = "achievement"
		end
	elseif xGetNumSlots and linkType and linkType == "spell" and id then
		local iVal = xGetNumSlots(id)

		if iVal then
			if type(iVal) =="table" then
				iconTex = iVal.iconID
			else
				iconTex = select(3,xGetNumSlots(id)) or 134400
			end

			if iconTex then
				tooltip.button:SetNormalTexture(iconTex)
				tooltip.button.type = "spell"
			end
		end
	else
		if id and C_Item and C_Item.GetItemIconByID then
			local result = GetShortItemID(id)
			local iVal = C_Item.GetItemIconByID(id)

			iVal = iVal or (result and C_Item.GetItemIconByID(result))

			tooltip.button:SetNormalTexture(iVal or iconTex)
			tooltip.button.type = "item"
		end
	end

end

local function RegisterTooltip(tooltip)

	local b = CreateFrame("Button",nil,tooltip)
	b:SetWidth(37)
	b:SetHeight(37)
	b:SetPoint("TOPRIGHT",tooltip,"TOPLEFT",0,-3)

	local t = b:CreateTexture(nil,"OVERLAY")

	if GetAchievementInfo then
		t:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
	else
		t:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	end
	t:SetTexCoord(0,0.5625,0,0.5625)
	t:SetPoint("CENTER",0,0)
	t:SetWidth(47)
	t:SetHeight(47)
	t:Hide()
	b.doOverlay = t

	tooltip.button = b
	tooltip.button.func = showTooltipIcon
end

local function hookTip()

	--create the button for the tooltip
	RegisterTooltip(ItemRefTooltip)

	ItemRefTooltip:HookScript("OnHide", function(self)
		self.button:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		self.button.doOverlay:Hide()
		self.button.type = nil
	end)

	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then

		--Note: tooltip data type corresponds to the Enum.TooltipDataType types
		--i.e Enum.TooltipDataType.Unit it type 2
		--see https://github.com/Ketho/wow-ui-source-df/blob/e6d3542fc217592e6144f5934bf22c5d599c1f6c/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua

		local function OnTooltipSetAllTypes(tooltip, data)
			if (tooltip == ItemRefTooltip and data) then
				ItemRefTooltip.button.func(ItemRefTooltip, data.hyperlink or data.id, data.type)
			end
		end
		TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, OnTooltipSetAllTypes)

	else

		ItemRefTooltip:HookScript('OnTooltipSetItem', function(self)
			local name, link = self:GetItem()
			if name and string.len(name) > 0 and link then --recipes return nil for GetItem() so check for it
				self.button.func(self, link)
			end
		end)

		hooksecurefunc(ItemRefTooltip, 'SetHyperlink', function(self, link)
			if link then
				self.button.func(self, link)
			end
		end)

	end

end

function addon:EnableAddon()

	hookTip()

	local ver = C_AddOns.GetAddOnMetadata(ADDON_NAME,"Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded", ADDON_NAME, ver or "1.0"))
end
