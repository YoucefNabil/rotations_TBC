local mediaPath, _A, _Y = ...
local U = _A.Cache.Utils -- U.playerGUID
local player
local string_lower = string.lower
local _tonumber = tonumber
--============================== Misc Functions
local function castduration(spellID)
	local tempvar = (select(7,GetSpellInfo(spellID)))
	return tempvar and tempvar/1000 or 0
end
local exeOnUnload = function()
end
local exeOnLoad = function() --==================== loading stuff for this profile specifically
	--==================== Manual Button Hooks (this does 2 things: the first and seventh button in your action bars starts/stops the rotation. Casting a macro or a spell pauses the rotation to let the user cast stuff)
	_A.pressedbuttonat = 0
	_A.buttondelay = 0.6
	_A.hooksecurefunc("UseAction", function(...)
		local slot, target, clickType = ...
		local Type, id, subType, spellID
		-- print(slot)
		player = player or Object("player")
		if slot==73 or slot==1 then 
			_A.pressedbuttonat = 0
			if _A.DSL:Get("toggle")(_,"MasterToggle")~=true then
				_A.Interface:toggleToggle("mastertoggle", true)
				-- _A.print("ON")
				return true
			end
		end
		if slot==79 or slot == 7 then 
			if _A.DSL:Get("toggle")(_,"MasterToggle")~=false then
				_A.Interface:toggleToggle("mastertoggle", false)
				-- _A.print("OFF")
				return true
			end
		end
		--
		if slot ~= (79 and 7 and 73 and  1) and clickType ~= nil then
			Type, id, subType = _A.GetActionInfo(slot)
			if Type == "spell" or Type == "macro" -- remove macro?
				then
				_A.pressedbuttonat = _A.GetTime()
				-- print("trying to cast something!")
			end
		end
	end)
	_A.buttondelayfunc = function()
		if _A.GetTime() - _A.pressedbuttonat < _A.buttondelay then return true end
		return false
	end
	function _A.modifier_shift()
		local modkeyb = IsShiftKeyDown()
		if modkeyb then
			return true
			else
			return false
		end
	end
	--==================== Events and event related
	_A.casttimers = {} -- doesnt work with channeled spells
	_A.Listener:Add("stuff", "COMBAT_LOG_EVENT_UNFILTERED", function(event, _, subevent, guidsrc, srcname, weirdnumber, guiddest, destname, sameweirdnumber, idd,spellname,lowweirdnumber,totalamount,overheal,thirdnumber)-- new
		if guidsrc == U.playerGUID then
		end
	end)
	_A.Listener:Add("spellcasts", {"UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED"}, function(event, unit, spellname)-- no work with channels
		if unit == "player" then
			_A.casttimers[string_lower(spellname)] = _A.GetTime()
		end
	end)
	function _A.castdelay(idd, delay)
		if delay == nil then return true end
		iddd = string_lower(idd)
		if _A.casttimers[iddd]==nil then return true end
		return (_A.GetTime() - _A.casttimers[iddd]) >= delay
	end
	--==================== Custom UnitIDs
	function _A.tbltostr(tbl)
		local result = {}
		for _, value in ipairs(tbl) do
			table.insert(result, tostring(value))
		end
		return table.concat(result, " || ")
	end
	immunebuffs = {
		"Deterrence",
		"Hand of Protection",
		"Dematerialize",
		-- "Smoke Bomb",
		"Cloak of Shadows",
		"Ice Block",
		"Divine Shield"
	}
	immunedebuffs = {
		"Cyclone"
		-- "Smoke Bomb"
	}
	healimmunebuffs = {
	}
	healimmunedebuffs = {
		"Cyclone"
	}
	function _A.notimmune(unit) -- needs to be object
		if unit then 
			if unit:immune("all") then return false end
			if unit:BuffAny(_A.tbltostr(immunebuffs)) then return false end
			if unit:DebuffAny(_A.tbltostr(immunedebuffs)) then return false end
		end
		return true
	end
	function _A.nothealimmune(unit)
		player = Object("player")
		if unit then 
			if unit:DebuffAny("Cyclone || Spirit of Redemption || Beast of Nightmares") then return false end
			if unit:BuffAny("Spirit of Redemption") then return false end
		end
		return true
	end
	_A.FakeUnits:Add('lowestEnemyInSpellRange', function(num, spell)
		local tempTable = {}
		local target = Object("target")
		-- if target and target:enemy() and target:spellRange(spell) and target:Infront() and _A.dontbreakcc(target) and _A.notimmune(target)  and target:los() then
		if target and target:enemy() and target:spellRange(spell) and target:Infront() and _A.notimmune(target)  and target:los() then
			return target and target.guid
		end
		for _, Obj in pairs(_A.OM:Get('EnemyCombat')) do
			-- if Obj:spellRange(spell) and _A.dontbreakcc(Obj) and _A.notimmune(Obj) and  Obj:Infront() and Obj:los() then
			if Obj:spellRange(spell) and _A.notimmune(Obj) and  Obj:Infront() and Obj:los() then
				tempTable[#tempTable+1] = {
					guid = Obj.guid,
					health = Obj:health(),
					isplayer = Obj.isplayer and 1 or 0
				}
			end
		end
		if #tempTable>1 then
			table.sort( tempTable, function(a,b) return (a.isplayer > b.isplayer) or (a.isplayer == b.isplayer and a.health < b.health) end )
		end
		return tempTable[num] and tempTable[num].guid
	end)
end
--==================== Rotation Table
local YRET = {
}
--==================== Running the rotation
local inCombat = function()
	if not player then player = Object("player") end
	--=============Debugging section
	--=============
	if _A.buttondelayfunc()  then return end -- pauses when pressing spells manually
	if (not player:IscastingAnySpell() or player:CastingRemaining() < 0.3) then
	
	end
end
local spellIds_Loc = {
	}

local blacklist = {
}
_A.CR:Add("TEMPLATE", {
	name = "TEMPLATE",
	ic = inCombat,
	ooc = inCombat,
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