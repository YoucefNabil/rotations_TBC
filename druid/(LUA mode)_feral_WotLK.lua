local mediaPath, _A = ...


local GUI = {

}

local exeOnLoad = function()

end

local exeOnUnload = function()

end

local inCombat = function()

end

local outCombat = function()

end

local spellIds_Loc = {

}

local blacklist = {

}

_A.CR:Add("Druid", {
	name = "Druid feral (LUA mode)",
	ic = inCombat,
	ooc = outCombat,
	use_lua_engine = true,
	gui = GUI,
	gui_st = {title="CR Settings", color="87CEFA", width="315", height="370"},
	wow_ver = "3.3.5",
	apep_ver = "1.1",
	-- ids = spellIds_Loc,
	-- blacklist = blacklist,
	-- pooling = false,
	load = exeOnLoad,
	unload = exeOnUnload
})
