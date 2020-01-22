local addonName, addon = ...

local UES_Version = "1.0.5";
local UES_Name = "Update Equipment Set";
local UES_BLUE = "|c000099ff";
local UES_YELLOW = "|cffffff55";
local UES_END_COLOR = "|r";
local UES_Title = UES_BLUE .. UES_Name .. ":" .. UES_END_COLOR .. " ";

local icon = LibStub("LibDBIcon-1.0", true);

-----------------------------------------------------------------------
-- Make sure we are prepared
--

local function print(...) _G.print(UES_Title, ...) end
if not LibStub then
	print("LibStub is required.")
	return
end

-- We seem fine, let the world access us.
_G[addonName] = addon
addon.healthCheck = true

function addon:UpdateDisplay()
	-- noop, hooked by displays
end

addon.previousSet = nil;

local EVENTS = {};

EVENTS.PLAYER_LOGIN = "PLAYER_LOGIN";
EVENTS.ADDON_LOADED = "ADDON_LOADED";
EVENTS.EQUIPMENT_SWAP_PENDING = "EQUIPMENT_SWAP_PENDING";
EVENTS.PLAYER_EQUIPMENT_CHANGED = "PLAYER_EQUIPMENT_CHANGED";
EVENTS.EQUIPMENT_SETS_CHANGED = "EQUIPMENT_SETS_CHANGED";

local options = {
	debug = {message = "Debugging"},
	minimap = {message = "Minimap Button"},
}

function UES_OnLoad(self)
	addon.previousSet = nil;

	for _,v in pairs(EVENTS) do
		self:RegisterEvent(strupper(v));
	end

	UES_RegisterSlashCommands();
	UES_LocalMessage(UES_BLUE .. UES_Name .. " v" .. UES_Version .. " by Tiago Costa." .. UES_END_COLOR);
	UES_LocalMessage("Type /ues or /updateequipmentset for options.");
end

function UES_RegisterSlashCommands()
	SlashCmdList["UES4832_"] = UES_ProcessSlashCommand;
	SLASH_UES4832_1 = "/updateequipmentset";
	SLASH_UES4832_2 = "/ues";
end

function UES_ProcessSlashCommand(option)
	option = strlower(option);

	if option == "debug" then
		UES_Toggle(option);
	elseif option == "save" then
		addon:UES_Save();
	elseif option == "discard" then
		addon:UES_Discard();
	elseif option == "status" then
		UES_ShowStatus("debug");
		UES_ShowStatus("minimap");
	elseif option == "toggle" then
		addon:UES_UpdateButton();
	else
		UES_ShowHelp();
	end
end

function UES_Toggle(option)
	UES_Options[option] = not UES_Options[option];
	UES_ShowStatus(option);
end

function addon:UES_UpdateButton()
	UES_Toggle('minimap');

	if UES_Options['minimap'] then
		icon:Show(addonName);
	else
		icon:Hide(addonName);
	end
end

function addon:UES_Save()
	local message = nil;

	if addon.previousSet then
		if not addon:UES_GetEquipedSet() then
			SaveEquipmentSet(addon.previousSet, nil);

			message = UES_Title .. "Equipment Set '" .. addon.previousSet .. "' updated with new items."
		else
			message = UES_Title .. "There are no changes to the current Set."
		end
	else
		message = UES_Title .. "No Set equiped!"
	end

	addon:UpdateDisplay();

	UES_Alert(message);
end

function addon:UES_Discard()
	local message = nil;

	if addon.previousSet then
		if not addon:UES_GetEquipedSet() then
			local equipped = UseEquipmentSet(addon.previousSet);

			if equipped then
				message = UES_Title .. "Changes discarded for Set '" .. addon.previousSet .. "'."
			else
				message = UES_Title .. "There was an error discarding changes. Try re-equiping the Set '" .. addon.previousSet .. "'."
			end
		else
			message = UES_Title .. "There are no changes to the current Set."
		end
	else
		message = UES_Title .. "No Set equiped!"
	end

	addon:UpdateDisplay();

	UES_Alert(message);
end

function UES_ShowStatus(option)
	local message = UES_Title;
	message = message .. options[option].message .. " is ";
	message = message .. (UES_Options[option] and ((options[option].status and options[option].status[1]) or "enabled") or ((options[option].status and options[option].status[2]) or "disabled")) .. ".";

	UES_Alert(message);
end

function UES_ShowHelp()
	UES_LocalMessage(UES_BLUE .. UES_Name .." v" .. UES_Version .. UES_END_COLOR);
	UES_LocalMessage(UES_YELLOW .. "Usage:");
	UES_LocalMessage(UES_YELLOW .. "    /ues toggle -" .. UES_END_COLOR .. " Toggle minimap button.");
	UES_LocalMessage(UES_YELLOW .. "    /ues save -" .. UES_END_COLOR .. " Updates the current Equipment Set with the newly equiped items.");
	UES_LocalMessage(UES_YELLOW .. "    /ues discard -" .. UES_END_COLOR .. " Discards the changes to the current Equipment Set.");
end

function UES_OnEvent(self, event, ...)
	local currentSet = addon:UES_GetEquipedSet();

	if event == EVENTS.ADDON_LOADED and ... == "UpdateEquipmentSet" then
		if not UES_Options then
			UES_Options = {
				debug = false,
				minimap = true,
			};
		end

		if not UES_ContainsOption('minimap') then UES_Options['minimap'] = true end
	elseif event == EVENTS.PLAYER_LOGIN then
		addon.previousSet = currentSet;
	elseif (event == EVENTS.EQUIPMENT_SWAP_PENDING or event == EVENTS.PLAYER_EQUIPMENT_CHANGED or event == EVENTS.EQUIPMENT_SETS_CHANGED) and (addon.previousSet == nil or addon.previousSet ~= currentSet) and currentSet then
		addon.previousSet = currentSet;
	end

	addon:UpdateDisplay();
end

function addon:UES_GetEquipedSet()
	if not CanUseEquipmentSets() then
		return nil;
	end

	for i = 1 , GetNumEquipmentSets() do
		local name, _, _, isEquipped, _, _, _, _, _ = GetEquipmentSetInfo(i);

		if (isEquipped) then
			return name;
		end
	end

	return nil;
end

function addon:UES_GetEquipedSetIcon()
	if not CanUseEquipmentSets() then
		return nil;
	end

	for i = 1 , GetNumEquipmentSets() do
		local _, icon, _, isEquipped, _, _, _, _, _ = GetEquipmentSetInfo(i);

		if (isEquipped) then
			return icon;
		end
	end

	return nil;
end

function addon:UES_GetIcon()
	return icon;
end

function UES_HUDMsg(message)
   UIErrorsFrame:AddMessage(tostring(message), 1.0, 1.0, 1.0, 1.0, UIERRORS_HOLD_TIME);
end

function UES_LocalMessage(message)
	DEFAULT_CHAT_FRAME:AddMessage(tostring(message));
end

function UES_Debug(message)
	if UES_Options.debug then
		UES_LocalMessage(UES_Title .. "[DEBUG] " .. tostring(message));
	end
end

function UES_Alert(message)
	UES_LocalMessage(message);
	UES_HUDMsg(message);
end

function UES_ContainsOption(element)
  for key, _ in pairs(UES_Options) do
    if key == element then
      return true
    end
  end
  return false
end
