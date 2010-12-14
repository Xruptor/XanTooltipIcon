--I just wanted a simple mod that displayed the icon for items I click in chat.
--Sometimes I would tear my hair trying to find it in the bags because I didn't know
--what it looked like.
--Xruptor

local registry = {}

local hookfactory = function(hook,orig)
	return function(self,...)
		local reg = registry[self]
		if reg[orig] then reg[orig](self,...) end
		hook(reg.button,self,...)
	end
end

local setItem = hookfactory(function(icon,self)
    local _,id = self:GetItem()
    if id then
		icon:SetNormalTexture(GetItemIcon(id))
		icon.link = id
		icon.type = "item"
	end
end,"setItem")


local cleared = hookfactory(function(icon,self)
    	icon:SetNormalTexture(nil)
	icon.doOverlay:Hide()
	icon.type = nil
	icon.link = nil
end,"cleared")


local setHyperlink = hookfactory(function(icon,self,link)
	if not (link and type(link) == "string") then return end
	local linkType,id = link:match("^([^:]+):(%d+)")
	if linkType == "achievement" and id then
		icon.link = GetAchievementLink(id)
		icon:SetNormalTexture(select(10,GetAchievementInfo(id)))
		icon.doOverlay:Show()
		icon.type = "achievement"
	elseif linkType == "spell" and id then
		icon.link = GetSpellLink(id)
		icon:SetNormalTexture(select(3,GetSpellInfo(id)))
		icon.type = "spell"
	end
end,"setHyperlink")

local function RegisterTooltip(tooltip)

	if registry[tooltip] then return end
	local reg = {}
	registry[tooltip] = reg
		
	local b = CreateFrame("Button",nil,tooltip)
	b:SetWidth(37)
	b:SetHeight(37)
	b:SetPoint("TOPRIGHT",tooltip,"TOPLEFT",0,-3)
	reg.button = b
	
	local t = b:CreateTexture(nil,"OVERLAY")
	t:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
	t:SetTexCoord(0,0.5625,0,0.5625)
	t:SetPoint("CENTER",0,0)
	t:SetWidth(47)
	t:SetHeight(47)	
	t:Hide()
	b.doOverlay = t
		
	reg.setItem = tooltip:GetScript("OnTooltipSetItem")
	reg.cleared = tooltip:GetScript("OnTooltipCleared")
	reg.setHyperlink = tooltip.SetHyperlink
	tooltip:SetScript("OnTooltipSetItem",setItem)
	tooltip:SetScript("OnTooltipCleared",cleared)
	tooltip.SetHyperlink  = setHyperlink
end

RegisterTooltip(ItemRefTooltip)
