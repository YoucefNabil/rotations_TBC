local mediaPath, _A = ...

local GUI = {

}

local exeOnLoad = function()

end

local exeOnUnload = function()

end

local inCombat = {

}

local outCombat = {

}

local spellIds_Loc = {

}

local blacklist = {

}

_A.CR:Add(103, {
	name = "Druid feral (DSL mode)",
	ic = inCombat,
	ooc = outCombat,
	use_lua_engine = false,
	gui = GUI,
	gui_st = {title="CR Settings", color="87CEFA", width="315", height="370"},
	wow_ver = "5.4.8",
	apep_ver = "1.1",
	-- ids = spellIds_Loc,
	-- blacklist = blacklist,
	-- pooling = false,
	load = exeOnLoad,
	unload = exeOnUnload
})
