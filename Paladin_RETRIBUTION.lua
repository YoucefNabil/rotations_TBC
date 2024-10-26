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
	_A.nextattackat = 0
	_A.currentattackspeed = UnitAttackSpeed("player") or 3.5
	_A.Listener:Add("stuff", "COMBAT_LOG_EVENT_UNFILTERED", function(event, _, subevent, guidsrc, srcname, weirdnumber, guiddest, destname, sameweirdnumber, idd,spellname,lowweirdnumber,totalamount,overheal,thirdnumber)-- new
		if guidsrc == U.playerGUID then
			-- debugging, checking if both seals are damaging
			if subevent == "SPELL_DAMAGE" then
				-- print(spellname.." ".._A.GetTime())
			end
			--
			if subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED" then
				_A.currentattackspeed = UnitAttackSpeed("player")
				_A.nextattackat = _A.GetTime()+_A.currentattackspeed 
			end
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
--==================== Always Running
local function sealweave()
	if _A.modifier_shift() and _A.nextattackat and _A.nextattackat - _A.GetTime() <= .3 then -- attack ready -- <= .3 works fine
		local target = Object("target")
		if IsCurrentSpell(6603)~=nil and IsCurrentSpell(6603)==1 and target and target:enemy() and target:debuff("Judgement of the Crusader") and target:inmelee() and target:infront() and target:los() then 
			if not player:buff("Seal of Blood") and player:spellcooldown("Seal of Blood")<.3 then return player:cast("Seal of Blood") end
			if not player:buff("Seal of the Martyr") and player:spellcooldown("Seal of the Martyr")<.3 then return player:cast("Seal of the Martyr") end
		end
	end
end
local function MyTickerCallback(ticker)
	if not player then player = Object("player") end
	-- functions that run
	sealweave()
	--
	local newDuration = _A.Parser.frequency or .02
	local updatedDuration = ticker:UpdateTicker(newDuration)
end
C_Timer.NewTicker(1, MyTickerCallback, false, "WeavingSeals")
--==================== Rotation Table
local YRET = {
	-- Misc
	autoattack_on = function()
		local target = Object("target")
		if IsCurrentSpell(6603)~=nil and IsCurrentSpell(6603)~=1 and target and target:enemy() and target:inmelee() and target:infront() and target:los() then 
			return player:cast(6603)
		end
	end,
	-- Buff
	blessing_kings = function()
		if not player:buff("Blessing of Kings") and player:spellcooldown("Blessing of Kings") then return player:cast("Blessing of Kings") end
	end,
	-- Rotation
	SealoftheCrusader = function()
		local target = Object("target")
		if target and target:enemy() and not target:debuff("Judgement of the Crusader") then
			if player:spellcooldown("Seal of the Crusader")<.3 and not player:buff("Seal of the Crusader") then return player:cast("Seal of the Crusader") end
		end
	end,
	Judgement_Crusader = function()
		if player:spellcooldown("Judgement")==0 and player:buff("Seal of the Crusader") then
			local target = Object("target")
			if target and target:enemy() and target:spellRange("Judgement") and not target:debuff("Judgement of the Crusader") and target:infront() and target:los() then return target:cast("Judgement", true) end
		end
	end,
	SealofCommand = function() -- maybe mana check, big line is just to slot this between 0.4 and 1.7 right after an attack
		local systime = _A.GetTime()
		local target = Object("target")
		if target and target:enemy() and target:debuff("Judgement of the Crusader") then
			if (_A.nextattackat and ((((_A.nextattackat - systime) > 1.7) and ((_A.nextattackat - systime) < (_A.currentattackspeed - 0.4))) or not (IsCurrentSpell(6603)~=nil and IsCurrentSpell(6603)==1 and target and target:enemy() and target:inmelee() and target:infront() and target:los())))then
				if _A.modifier_shift() and player:spellcooldown("Seal of Command")<.3 and not player:buff("Seal of Command") then return player:cast("Seal of Command(Rank 1)") end
				if player:spellcooldown("Seal of Blood")<.3 and not player:buff("Seal of Blood") then return player:cast("Seal of Blood") end
				if player:spellcooldown("Seal of the Martyr")<.3 and not player:buff("Seal of the Martyr") then return player:cast("Seal of the Martyr") end
			end
		end
	end,
	Judgement_Blood = function()
		local systime = _A.GetTime()
		if _A.modifier_shift() and _A.nextattackat and (((_A.nextattackat - systime) > 1.7) and ((_A.nextattackat - systime) < (_A.currentattackspeed - 0.4))) then
			if player:spellcooldown("Judgement")==0 and player:buff("Seal of Blood") then
				local target = Object("target")
				if target and target:enemy() and target:spellRange("Judgement") and target:debuff("Judgement of the Crusader") and target:infront() and target:los() then return target:cast("Judgement", true) end
			end
		end
	end,
	CS = function()
		local systime = _A.GetTime()
		if _A.nextattackat and (((_A.nextattackat - systime) > 1.7) and ((_A.nextattackat - systime) < (_A.currentattackspeed - 0.4))) then
			if player:spellcooldown("Crusader Strike")<.3 and player:buff("Seal of Blood") then
				local target = Object("target")
				if target and target:enemy() and target:inmelee() and target:infront() and target:debuff("Judgement of the Crusader") and target:los() then return target:cast("Crusader Strike") end
			end
		end
	end,
}
--==================== Running the rotation
local inCombat = function()
	if not player then player = Object("player") end
	--=============Debugging section
	--=============
	if _A.buttondelayfunc()  then return end -- pauses when pressing spells manually
	if (not player:IscastingAnySpell() or player:CastingRemaining() < 0.3) then
		--BUFFS
		YRET.blessing_kings()
		--Misc
		YRET.autoattack_on() -- could be stupid in pvp against cc or something
		--ROTATION
		YRET.SealoftheCrusader()
		YRET.Judgement_Crusader()
		YRET.CS()
		YRET.SealofCommand() -- mana intensive, maybe add a mana check?
		YRET.Judgement_Blood()
	end
end
local spellIds_Loc = {
}

local blacklist = {
}
_A.CR:Add("Paladin", {
	name = "Youcef's Retri Paladin",
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