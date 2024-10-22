local mediaPath, _A = ...
local U = _A.Cache.Utils -- U.playerGUID
local player
local string_lower = string.lower
local _tonumber = tonumber
local function uid(unit, spellID)
	if spellID then 
		for i=1, 40 do
			local pullingbuffname,_,_,_,_,_,_,_,_,_,pullingbuffid = _A.UnitBuff(unit, i)
			local pullingbuffname2,_,_,_,_,_,_,_,_,_,pullingbuffid2 = _A.UnitDebuff(unit, i)
			if _tonumber(spellID)~=nil then
				if pullingbuffid and pullingbuffid == spellID then return true end
				if pullingbuffid2 and pullingbuffid2 == spellID then return true end
			end
			if _tonumber(spellID)==nil then
				if pullingbuffname and string_lower(pullingbuffname) == string_lower(spellID) then return true end
				if pullingbuffname2 and string_lower(pullingbuffname2) == string_lower(spellID) then return true end
			end
		end
	end
	return false
end
local function uidme(unit, spellID)
	if spellID then 
		for i=1, 40 do
			local pullingbuffname,_,_,_,_,_,_,pullingbuffsource,_,_,pullingbuffid = _A.UnitBuff(unit, i)
			local pullingbuffname2,_,_,_,_,_,_,pullingbuffsource2,_,_,pullingbuffid2 = _A.UnitDebuff(unit, i)
			if _tonumber(spellID)~=nil then
				if pullingbuffid and pullingbuffid == spellID and pullingbuffsource and pullingbuffsource == "player" then return true end
				if pullingbuffid2 and pullingbuffid2 == spellID and pullingbuffsource2 and pullingbuffsource2 == "player" then return true end
			end
			if _tonumber(spellID)==nil then
				if pullingbuffname and string_lower(pullingbuffname) == string_lower(spellID) and pullingbuffsource and pullingbuffsource == "player" then return true end
				if pullingbuffname2 and string_lower(pullingbuffname2) == string_lower(spellID) and pullingbuffsource2 and pullingbuffsource2 == "player" then return true end
			end
		end
	end
	return false
end
local function uidremain(unit, spellID)
	if spellID then 
		for i=1, 40 do
			local pullingbuffname,_,_,_,_,_,endtime,pullingbuffsource,_,_,pullingbuffid = _A.UnitBuff(unit, i)
			local pullingbuffname2,_,_,_,_,_,endtime2,pullingbuffsource2,_,_,pullingbuffid2 = _A.UnitDebuff(unit, i)
			local systime = _A.GetTime()
			if _tonumber(spellID)~=nil then
				if pullingbuffid and pullingbuffid == spellID and pullingbuffsource and pullingbuffsource == "player" and endtime then return endtime - systime end
				if pullingbuffid2 and pullingbuffid2 == spellID and pullingbuffsource2 and pullingbuffsource2 == "player" and endtime2 then return endtime2 - systime  end
			end
			if _tonumber(spellID)==nil then
				if pullingbuffname and string_lower(pullingbuffname) == string_lower(spellID) and pullingbuffsource and pullingbuffsource == "player" and endtime then return endtime - systime  end
				if pullingbuffname2 and string_lower(pullingbuffname2) == string_lower(spellID) and pullingbuffsource2 and pullingbuffsource2 == "player" and endtime2 then return endtime2 - systime  end
			end
		end
	end
	return 0
end
local function castduration(spellID)
	local tempvar = (select(7,GetSpellInfo(spellID)))
	return tempvar and tempvar/1000 or 0
end
--=================================
--=================================
--=================================
local exeOnLoad = function()
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
				_A.print("ON")
				return true
			end
		end
		if slot==79 or slot == 7 then 
			if _A.DSL:Get("toggle")(_,"MasterToggle")~=false then
				_A.Interface:toggleToggle("mastertoggle", false)
				_A.print("OFF")
				return true
			end
		end
		--
		if slot ~= 79 and slot ~= 7 and slot ~= 73 and slot ~= 1 and clickType ~= nil then
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
	_A.mindflaytb = {}
	_A.casttimers = {} -- doesnt work with channeled spells
	_A.Listener:Add("delaycasts", {"COMBAT_LOG_EVENT_UNFILTERED", "UNIT_SPELLCAST_SUCCEEDED"}, function(event, _, subevent, guidsrc, srcname, weirdnumber, guiddest, destname, sameweirdnumber, idd,spellname,lowweirdnumber,totalamount,overheal,thirdnumber)-- new
		if guidsrc == U.playerGUID then
			if subevent=="SPELL_PERIODIC_DAMAGE" and spellname == "Mind Flay" then
				_A.mindflaytb[#_A.mindflaytb+1]=_A.GetTime()
				-- this voodoo is for counting mind flay ticks
				-- the point of this is to clip/self interrupt the channel right after the second tick, since the third ticks takes too long, apparently it's a dps increase or something
				-- this is what the "#_A.mindflaytb>=2" checks in InCombat are for
				print(#_A.mindflaytb)
			end
		end
	end)
	_A.Listener:Add("spellcasts", {"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED"}, function(event, unit, spellname)-- no work with channels
		if unit == "player" then
			_A.casttimers[string_lower(spellname)] = _A.GetTime()
		end
	end)
	function _A.castdelay(idd, delay) -- always use lowercase
		if delay == nil then return true end
		if _A.casttimers[idd]==nil then return true end
		return (_A.GetTime() - _A.casttimers[idd]) >= delay
	end
	--==============================================
	--==============================================
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
			-- if unit:BuffAny(_A.tbltostr(immunebuffs)) then return false end
			-- if unit:DebuffAny(_A.tbltostr(immunedebuffs)) then return false end
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
	_A.FakeUnits:Add('lowestEnemyInSpellRangeDOT', function(num,spell)
		local tempTable = {}
		for _, Obj in pairs(_A.OM:Get('EnemyCombat')) do
		-- for _, Obj in pairs(_A.OM:Get('Enemy')) do
			if _A.notimmune(Obj) and Obj:spellrange(spell) and not uidme(Obj.guid, "shadow word: pain") and Obj:los() then
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
	_A.FakeUnits:Add('lowestEnemyInSpellRangeExecute', function(num, spell)
		local tempTable = {}
		for _, Obj in pairs(_A.OM:Get('EnemyCombat')) do
		-- for _, Obj in pairs(_A.OM:Get('Enemy')) do
			if _A.notimmune(Obj) and Obj:spellrange(spell) and Obj:health()<15 and Obj:los() then
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
local exeOnUnload = function()
end
local YSP = {
	--=========================
	--========================= leveling
	--=========================
	
	smite = function()
		if not player:moving() then
			local target = Object("target")
			if target and target:enemy() and target:infront() and target:spellrange("smite") and target:los() then return target:cast("smite") end
		end
	end,
	
	--=========================
	--========================= Single Target
	--=========================
	shadowform_stance = function()
		if not player:buff("Shadowform") and player:SpellCooldown("Shadowform")<.3 then return player:Cast("Shadowform") end
	end,
	vampiric_touch = function()
		if not player:ischanneling("mind flay") or #_A.mindflaytb>=2 then
			if not player:moving() and _A.castdelay("vampiric touch", .3) then
				local target = Object("target")
				if target and target:enemy() and target:spellrange("Vampiric touch")
					then 
					if not uidme(target.guid,"vampiric touch") and target:los() then return target:cast("vampiric touch") end
					local debuffremain = uidremain(target.guid,"vampiric touch")
					if debuffremain>0 and debuffremain<(castduration("vampiric touch")+1) and target:los() then return target:cast("vampiric touch") end
				end
			end
		end
	end,
	shadowword_pain = function()
		if not player:ischanneling("mind flay") or #_A.mindflaytb>=2 then
			local target = Object("target")
			if target and target:enemy() and target:spellrange("shadow word: pain") then
				if not uidme(target.guid,"shadow word: pain") and target:los() then return target:cast("shadow word: pain") end
				local debuffremain2 = uidremain(target.guid,"shadow word: pain")
				if debuffremain2>0 and debuffremain2<1.5 and target:los() then return target:cast("shadow word: pain") end
			end
		end
	end,
	mindblast = function()
		if not player:ischanneling("mind flay") or #_A.mindflaytb>=2 then
			if not player:moving() and player:SpellCooldown("Mind Blast")<.3 then
				local target = Object("target")
				if target and target:enemy() and target:infront() and target:spellrange("mind blast") and target:los() then return target:cast("Mind Blast") end
			end
		end
	end,
	deathspell = function()
		if not player:ischanneling("mind flay") or #_A.mindflaytb>=2 then
			local target = Object("target")
			if target and target:enemy() and target:spellrange("shadow word: death") and target:Health()<20 and target:los() then return target:cast("shadow word: death") end
		end
	end,
	mindflay = function()
		if not player:ischanneling("mind flay") and not player:moving() then 
			local target = Object("target")
			if target and target:enemy() and target:spellrange("mind flay") and target:infront() and target:los() then return target:cast("mind flay") end
		end
	end,
	--=========================
	--========================= AOE filler
	--=========================
	shadowword_pain_any = function()
		if not player:ischanneling("mind flay") or #_A.mindflaytb>=2 then
			local lowest = Object("lowestEnemyInSpellRangeDOT(shadow word: pain)")
			if lowest then return lowest:cast("shadow word: pain") end
		end
	end,
	shadowword_execute_any = function()
		if not player:ischanneling("mind flay") or #_A.mindflaytb>=2 then
			local lowest = Object("lowestEnemyInSpellRangeExecute(shadow word: death)")
			if lowest then return lowest:cast("shadow word: death") end
		end
	end,
}
local inCombat = function()
	player = Object("player")
	if not player:ischanneling("mind flay") and #_A.mindflaytb>0 then _A.mindflaytb = {} end -- clean mindflay tick table when not casting
	if _A.buttondelayfunc()  then return end
	--============= Single Target Main rotation
	if not _A.modifier_shift() then
		YSP.shadowform_stance()
		YSP.vampiric_touch()
		YSP.shadowword_pain()
		YSP.mindblast()
		YSP.deathspell()
		YSP.mindflay()
	end
	--============= Leveling
	if player:level()<=15 then
		YSP.smite()
	end
	--============= AOE fill
	YSP.shadowword_execute_any()
	YSP.shadowword_pain_any()
end

local spellIds_Loc = {
}

local blacklist = {
}

_A.CR:Add("Priest", {
	name = "Youcef's Shadow Priest",
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