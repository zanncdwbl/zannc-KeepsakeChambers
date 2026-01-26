---@meta _
-- grabbing our dependencies,
-- these funky (---@) comments are just there
--	 to help VS Code find the definitions of things

---@diagnostic disable-next-line: undefined-global
local mods = rom.mods

---@diagnostic disable: lowercase-global
---@module 'LuaENVY-ENVY-auto'
mods["LuaENVY-ENVY"].auto()

---@diagnostic disable-next-line: undefined-global
rom = rom
---@diagnostic disable-next-line: undefined-global
_PLUGIN = _PLUGIN

---@module 'SGG_Modding-Hades2GameDef-Globals'
game = rom.game

---@module 'SGG_Modding-ModUtil'
modutil = mods["SGG_Modding-ModUtil"]

---@module 'SGG_Modding-Chalk'
chalk = mods["SGG_Modding-Chalk"]

---@module 'SGG_Modding-ReLoad'
reload = mods["SGG_Modding-ReLoad"]

---@module 'KeepsakeChambers-zannc-config'
config = chalk.auto("config.lua")
public.config = config

import_as_fallback(rom.game)

local function on_ready_late()
	if config.enabled == false then
		return
	end

	modutil.mod.Path.Context.Wrap.Static("AdvanceKeepsake", function()
		modutil.mod.Path.Wrap("IncrementTableValue", function(base, tableArg, key, amount)
			local startingKeepsakeLevel = nil

			local traitName = game.GameState.LastAwardTrait
			if game.GameState.LastAwardTrait ~= nil and game.HeroHasTrait(traitName) then
				startingKeepsakeLevel = game.GetKeepsakeLevel(traitName, true)
			end

			if startingKeepsakeLevel and startingKeepsakeLevel < 3 then
				amount = config.Increment
				base(tableArg, key, amount)
			else
				base(tableArg, key, amount)
			end
		end)
	end)
end

local function on_reload_late()
	local function drawMenu()
		local value, checked = rom.ImGui.Checkbox("Enabled", config.enabled)
		if checked then
			config.enabled = value
		end

		if config.enabled then
			local value, selected = rom.ImGui.SliderInt("Chamber(s)", config.Increment, 1, 75)
			if selected then
				config.Increment = value
			end
		end
	end

	rom.gui.add_imgui(function()
		if rom.ImGui.Begin("Keepsake Chambers") then
			drawMenu()
			rom.ImGui.End()
		end
	end)

	rom.gui.add_to_menu_bar(function()
		if rom.ImGui.BeginMenu("Configure") then
			drawMenu()
			rom.ImGui.EndMenu()
		end
	end)
end

local loader = reload.auto_multiple()

mods.on_all_mods_loaded(function()
	modutil.once_loaded.game(function()
		loader.load("late", on_ready_late, on_reload_late)
	end)
end)
