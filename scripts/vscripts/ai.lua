print("AI is loading")

affix_table = {}
affix_keyvalues = LoadKeyValues("scripts/affix_list.txt")
affix_names = {}



function affix_list(unit)
	local unit_level = unit:GetLevel() 
	local affix_count = 0 
	local random_table = {}
	local range_type
	if unit:IsRangedAttacker() == true then
		range_type = "ranged"
	else
		range_type = "melee"
	end

	for key, value in pairs(affix_keyvalues) do
		
		if value.level_limit <= unit_level and (value.range_melee_type == "any" or value.range_melee_type == range_type) then
			table.insert( random_table, key)
			affix_count = affix_count + 1
		end
	end
	
	return random_table[math.random(affix_count)]
end



function affix_selector()
	return affix_names[math.random(affix_count)]
end


function affix( unit)
	
	local affix_to_set = nil

	local unit_name = unit:GetUnitName() 

	for key, value in pairs(affix_table) do
		if unit_name == key then
			affix_to_set = value

		end
	end

	if affix_to_set == nil then
		affix_to_set = affix_list(unit)
		affix_table[unit_name] = affix_to_set
	end

	unit:AddAbility(affix_to_set)
	unit:FindAbilityByName(affix_to_set):SetLevel(1)


end


function log_npc( event )
	local index = event.entindex
	local unit = EntIndexToHScript(index)
	if Convars:GetBool("developer") == true then
		print("Index: "..index.." Name: "..unit:GetUnitName().." Created time: "..GameRules:GetGameTime().." at x= "..unit:GetOrigin().x.." y= "..unit:GetOrigin().y)
	end

	if unit:GetTeam() == DOTA_TEAM_NEUTRALS then
		if unit.initial_neutral_position == nil then
			unit.initial_neutral_position = unit:GetAbsOrigin()
		end
		unit:SetContextThink("chase_distance_function", 
			function ()
				if unit:GetTeam() == DOTA_TEAM_NEUTRALS then
					if (unit.initial_neutral_position - unit:GetAbsOrigin()):Length2D() > 900 then
						unit:MoveToPosition(unit.initial_neutral_position) 

					end

					return math.random(2,6)
				else
					return nil
				end
			end
			, 5) 


		affix(unit)


	else


	end
end

if log_npc_loaded == nil then
	ListenToGameEvent( "npc_spawned", log_npc, nil )
	log_npc_loaded = true
end

function physical_ehp( unit )
	return unit:GetHealth() * ((0.06 * unit:GetPhysicalArmorValue()) / (1 + 0.06 * unit:GetPhysicalArmorValue()))
end

function tb_miniboss_think( event )
	local dead_units = false
	for number, unit in pairs(event.target_entities) do
		if unit:IsAlive() == false then
			dead_units = true
		end
	end
	if dead_units == true and event.ability:IsChanneling() == false and event.ability:IsFullyCastable() == true  then
		event.caster:CastAbilityNoTarget(event.caster:FindAbilityByName("tb_miniboss_animate_dead"), -1)
	end
end

function final_boss_think( event )
	local boss = event.caster
	local heroes_around = FindUnitsInRadius( DOTA_TEAM_NEUTRALS, boss:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
	local void_spell = boss:FindAbilityByName("final_boss_void_new")

	if void_spell:IsFullyCastable() == true and heroes_around[1] ~= nil then
		local target = heroes_around[1]
		local target_ehp = physical_ehp(target)

		for key, hero in pairs(heroes_around) do 
			local filtered_ehp = physical_ehp(hero)
			if filtered_ehp < target_ehp then
				target = hero
				target_ehp = filtered_ehp
			end 
		end

		boss:CastAbilityOnTarget(target, void_spell, -1)

		boss:SetForceAttackTarget(target)

		--boss:MoveToTargetToAttack(target) 
		--[[ExecuteOrderFromTable({
								UnitIndex = boss:entindex(), 
 								OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
 		 						TargetIndex = target:entindex()
								})]]
		
	else
		boss:SetForceAttackTarget(nil)
	end

	if boss:HasModifier("final_boss_powerup") == false then
		if (boss:GetHealth() / boss:GetMaxHealth()) <= 0.5 then
			boss:AddAbility("final_boss_buff")
			boss:FindAbilityByName("final_boss_buff"):SetLevel(1)
		end
	end
end

function final_boss_defeat( event )
 	Timers:CreateTimer({
    endTime = 4,
    callback = function()
     	GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
    end
  	})
	
end