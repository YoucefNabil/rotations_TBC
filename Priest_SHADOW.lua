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
	_A.mindflaytb = {}
	_A.casttimers = {} -- doesnt work with channeled spells
	_A.caststart = {} -- doesnt work with channeled spells
	_A.Listener:Add("delaycasts", {"COMBAT_LOG_EVENT_UNFILTERED", "UNIT_SPELLCAST_SUCCEEDED"}, function(event, _, subevent, guidsrc, srcname, weirdnumber, guiddest, destname, sameweirdnumber, idd,spellname,lowweirdnumber,totalamount,overheal,thirdnumber)-- new
		if guidsrc == U.playerGUID then
			if subevent=="SPELL_PERIODIC_DAMAGE" and spellname == "Mind Flay" then
				_A.mindflaytb[#_A.mindflaytb+1]=_A.GetTime()
				-- this voodoo is for counting mind flay ticks
				-- the point of this is to clip/self interrupt the channel right after the second tick, since the third tick takes too long, apparently it's a dps increase or something
				-- this is what the "#_A.mindflaytb>=2" checks in InCombat are for
			end
		end
	end)
	_A.Listener:Add("spellcasts", {"UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED"}, function(event, unit, spellname)-- no work with channels
		if unit == "player" then
			_A.casttimers[string_lower(spellname)] = _A.GetTime()
		end
	end)
	_A.Listener:Add("antistutter_event", "UNIT_SPELLCAST_START", function(event, unit, spellname)-- no work with channels
		if unit == "player" then
			print(spellname)
		end
	end)
	_A.Listener:Add("delayedspellcast", "UNIT_SPELLCAST_DELAYED", function(event, unit, spellname)-- no work with channels
		if unit == "player" then
			-- print("I got delayed!")
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
	_A.FakeUnits:Add('lowestEnemyInSpellRangeDOT', function(num,spell)
		local tempTable = {}
		for _, Obj in pairs(_A.OM:Get('EnemyCombat')) do
			if _A.notimmune(Obj) and Obj:spellrange(spell) and not Obj:debuff(spell) and Obj:los() then
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
	end
	)
	_A.FakeUnits:Add('lowestEnemyInSpellRangeExecute', function(num, spell)
		local tempTable = {}
		for _, Obj in pairs(_A.OM:Get('EnemyCombat')) do
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
	end
	)
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
local YSP = {
	--=========================
	--========================= leveling related
	--=========================
	smite = function()
		if not player:moving() and player:SpellCooldown("Smite")<=.3 and player:SpellUsable("Smite") and (not player:iscasting("Smite") or player:CastingRemaining() < 0.3) then
			local target = Object("lowestEnemyInSpellRange(Smite)")
			if target then return target:cast("Smite", true) end
		end
	end,
	--=========================
	--========================= Buffs
	--=========================
	innerfire = function()
		if not player:ischanneling("Mind Flay") and not player:buff("Inner Fire") and player:SpellCooldown("Inner Fire")<=.3 and player:SpellUsable("Inner Fire") then return player:Cast("Inner Fire") end
	end,
	fortitude = function()
		if not player:buff("Power Word: Fortitude") and player:SpellCooldown("Power Word: Fortitude")<=.3 and player:SpellUsable("Power Word: Fortitude") then return player:Cast("Power Word: Fortitude") end
	end,
	--=========================
	--========================= Single Target
	--=========================
	vampiric_embrace = function()
		if not player:ischanneling("Mind Flay") and player:SpellCooldown("Vampiric Embrace")<=.3 and player:SpellUsable("Vampiric Embrace") then
			local target = Object("target")
			if target and target:enemy() and target:spellrange("Vampiric Embrace") then
				if not target:debuff("Vampiric Embrace") and target:los() then return target:cast("Vampiric Embrace", true) end
			end
		end
	end,
	shadowform_stance = function()
		if not player:buff("Shadowform") and player:SpellCooldown("Shadowform")<=.3 and player:SpellUsable("Shadowform") then return player:Cast("Shadowform") end
	end,
	vampiric_touch = function()
		if #_A.mindflaytb>=2  or not player:ischanneling("Mind Flay") then
			if not player:moving() and _A.castdelay("Vampiric Touch", .2) and not player:iscasting("Vampiric Touch") and player:SpellCooldown("Vampiric Touch")<=.3 and player:SpellUsable("Vampiric Touch") then
				local target = Object("target")
				if target and target:enemy() and target:spellrange("Vampiric Touch")
					then 
					if not target:debuff("Vampiric Touch") and target:los() then return target:cast("Vampiric Touch") end
					local debuffremain = target:debuffduration("Vampiric Touch")
					if debuffremain and debuffremain>0 and debuffremain<(castduration("Vampiric Touch")+1) and target:los() then return target:cast("Vampiric Touch", true) end
				end
			end
		end
	end,
	shadowword_pain = function()
		if player:SpellCooldown("Shadow Word: Pain")<=.3 then
			if #_A.mindflaytb>=2  or not player:ischanneling("Mind Flay") then
				local target = Object("target")
				if target and target:enemy() and target:spellrange("Shadow Word: Pain") and player:SpellUsable("Shadow Word: Pain") then
					if not target:debuff("Shadow Word: Pain") and target:los() then return target:cast("Shadow Word: Pain", true) end
					local debuffremain2 = target:debuffduration("Shadow Word: Pain")
					if debuffremain2 and debuffremain2>0 and debuffremain2<1.5 and target:los() then return target:cast("Shadow Word: Pain", true) end
				end
			end
		end
	end,
	mindblast = function()
		if #_A.mindflaytb>=2 or not player:ischanneling("Mind Flay") then
			if not player:moving() and player:SpellCooldown("Mind Blast")<=.3 and not player:iscasting("Mind Blast") and player:SpellUsable("Mind Blast") then
				local target = Object("target")
				if target and target:enemy() and target:infront() and target:spellrange("Mind Blast") and target:los() then return target:cast("Mind Blast", true) end
			end
		end
	end,
	mindflay = function()
		if player:SpellCooldown("Mind Flay")<=.3 and player:SpellUsable("Mind Flay") then
			if not player:ischanneling("Mind Flay") and not player:moving() then 
				local target = Object("target")
				if target and target:enemy() and target:spellrange("Mind Flay") and target:infront() and target:los() then return target:cast("Mind Flay", true) end
			end
		end
	end,
	--=========================
	--========================= targetless
	--=========================
	shadowword_pain_any = function()
		if player:SpellCooldown("Shadow Word: Pain")<=.3 and player:SpellUsable("Shadow Word: Pain") then
			if not player:ischanneling("Mind Flay") or #_A.mindflaytb>=2 then
				local lowest = Object("lowestEnemyInSpellRangeDOT(Shadow Word: Pain)")
				if lowest then return lowest:cast("Shadow Word: Pain") end
			end
		end
	end,
	shadowword_execute_any = function()
		if player:SpellCooldown("Shadow Word: Death")<=.3 and player:SpellUsable("Shadow Word: Death") then
			if not player:ischanneling("Mind Flay") or #_A.mindflaytb>=2 then
				local lowest = Object("lowestEnemyInSpellRangeExecute(Shadow Word: Death)")
				if lowest then return lowest:cast("Shadow Word: Death") end
			end
		end
	end,
	mindblast_targetless = function()
		if #_A.mindflaytb>=2 or not player:ischanneling("Mind Flay") then
			if not player:moving() and player:SpellCooldown("Mind Blast")<=.3 and not player:iscasting("Mind Blast") and player:SpellUsable("Mind Blast") then
				local target = Object("lowestEnemyInSpellRange(Mind Blast)")
				if target then return target:cast("Mind Blast", true) end
			end
		end
	end,
	mindflay_targetless = function()
		if player:SpellCooldown("Mind Flay")<=.3 and player:SpellUsable("Mind Flay") then
			if not player:ischanneling("Mind Flay") and not player:moving() then 
				local target = Object("lowestEnemyInSpellRange(Mind Flay)")
				if target then return target:cast("Mind Flay", true) end
			end
		end
	end,
}
--==================== Running the rotation
local inCombat = function()
	if not player then player = Object("player") end
	if not player:ischanneling("Mind Flay") and #_A.mindflaytb>0 then _A.mindflaytb = {} end -- clean mindflay tick table when not casting
	--=============Debugging section
	--=============
	if _A.buttondelayfunc()  then return end -- pauses when pressing spells manually
	if (not player:IscastingAnySpell() or player:CastingRemaining() < 0.3) then
		--============= Buffs
		YSP.fortitude()
		YSP.innerfire()
		--============= Single Target Main rotation
		YSP.shadowword_execute_any() -- Execute
		YSP.shadowform_stance()
		if not _A.modifier_shift() then -- holding shift skips this
			YSP.vampiric_touch()
			YSP.shadowword_pain()
			YSP.vampiric_embrace()
			YSP.mindblast()
			YSP.mindflay()
		end
		--============= Targetless
		if not _A.modifier_shift() then -- holding shift skips this	
			YSP.mindblast_targetless()
		end
		YSP.shadowword_pain_any()
		if not _A.modifier_shift() then -- holding shift skips this	
			YSP.mindflay_targetless()
		end
		--============= Leveling
		if player:level()<20 then -- level at which mindflay is unlocked
			YSP.smite()
		end
	end
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