--I just wanted a simple mod that displayed the icon for items I click in chat.
--Sometimes I would tear my hair trying to find it in the bags because I didn't know
--what it looked like.
--Xruptor

local debugf = tekDebug and tekDebug:GetFrame("xanTooltipIcon")
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local function showTooltipIcon(tooltip, link, ttType)
	if not (issecure() or not tooltip:IsForbidden()) then return end
	
	local linkType, id
	
	if isRetail and ttType then
		if ttType == 1 then
			linkType = "spell"
		elseif ttType == 12 then
			linkType = "achievement"
		else
			linkType = "item"
		end
		id = id or link
	else
		linkType, id = link:match("^([^:]+):(%d+)")
	end

	if isRetail and linkType == "achievement" and id then
		if GetAchievementInfo(id) and select(10,GetAchievementInfo(id)) then
			tooltip.button:SetNormalTexture(select(10,GetAchievementInfo(id)))
			tooltip.button.doOverlay:Show()
			tooltip.button.type = "achievement"
		end
	elseif linkType == "spell" and id then
		if GetSpellInfo(id) and select(3,GetSpellInfo(id)) then
			tooltip.button:SetNormalTexture(select(3,GetSpellInfo(id)))
			tooltip.button.type = "spell"
		end
	else
		if id and GetItemIcon(id) then
			tooltip.button:SetNormalTexture(GetItemIcon(id))
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
	
	if isRetail then
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
	
	if isRetail then
	
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

hookTip()
