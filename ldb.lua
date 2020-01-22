local addonName, addon = ...
if not addon.healthCheck then return end

local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not ldb then return end

local plugin = ldb:NewDataObject(addonName, {
	type = "data source",
	text = "N/A",
	icon = "Interface\\AddOns\\UpdateEquipmentSet\\Media\\icon",
	set = nil,
	status = nil,
})

function plugin.OnClick(self, button)
	if IsShiftKeyDown() then
		addon:UES_Discard()
	else
		addon:UES_Save()
	end
end

hooksecurefunc(addon, "UpdateDisplay", function()
	local text = nil

	if addon.previousSet then
		plugin.set = addon.previousSet

		if addon:UES_GetEquipedSet() then
			plugin.status = "|cff00ff00Saved|r"
		else
			plugin.status = "|cffff0000Not Saved|r"
		end

		text = addon.previousSet .. " - " .. plugin.status
	end

	plugin.text = text or "N/A"
	plugin.icon = addon:UES_GetEquipedSetIcon() or "Interface\\AddOns\\UpdateEquipmentSet\\Media\\icon"
end)

do
	local hint = "|cffeda55fClick|r save current Equipment Set with newly equiped items.|n|cffeda55fShift-Click|r discard changes to current Equipment Set."
	local line = "%d. %s (x%d)"
	function plugin.OnTooltipShow(tt)
		tt:AddLine(addonName)
		tt:AddLine(" ")
		tt:AddLine("Current Set: |cffffffff" .. (plugin.set or "None") .. "|r")
		tt:AddLine("Status: |cffffffff" .. (plugin.status or "N/A") .. "|r")
		tt:AddLine(" ")
		tt:AddLine(hint, 0.2, 1, 0.2, 1)
	end
end

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function()
	local icon = addon:UES_GetIcon();
	if not icon then return end
	if not UpdateEquipmentSetLDBIconDB then UpdateEquipmentSetLDBIconDB = { hide = false } end
	UpdateEquipmentSetLDBIconDB.hide = not UES_Options['minimap'];
	icon:Register(addonName, plugin, UpdateEquipmentSetLDBIconDB)
end)
f:RegisterEvent("PLAYER_LOGIN")
