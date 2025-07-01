-- Creates illusion out of CDOTA_BaseNPC (hero, unit...) for the caster;
-- returns a handle of created illusion
-- Required arguments: caster, ability and duration; Other arguments are optional;
-- Has 2 methods
-- The method 1 creates a new hero/unit first and then makes him an illusion. This method is default.
-- The method 2 literally creates an empty unit and then turns his model and stats to be the same as the target.
-- Both methods can cause lag. But second method has more bugs.
-- Known issues (for both methods): Morphling Morph wrong attributes, power treads are always strength, 
-- terrorblade custom illusions during metamorphosis are missing attack projectiles;
-- custom illusions are missing talent trees (but visually only)
if CDOTA_BaseNPC then
  function CDOTA_BaseNPC:CreateIllusion(caster, ability, duration, position, damage_dealt, damage_taken, controllable, method)
	if caster:IsNull() or ability:IsNull() or duration == nil then
		print("caster, ability and duration need to be defined for CreateIllusion!")
		return
	end

	local playerID = caster:GetPlayerID()
	local unit_name = self:GetUnitName()
	local unit_HP = self:GetHealth()
	local unit_MP = self:GetMana()
	local owner = caster:GetOwner() or caster
	local origin = position or self:GetAbsOrigin() + RandomVector(150)
	local illusion_damage_dealt = damage_dealt or 0
	local illusion_damage_taken = damage_taken or 0
	local unit_ability_count = self:GetAbilityCount()

	if controllable == nil then
		controllable = true
	end

	if method ~= 1 and method ~= 2 then
		method = 1
	end

	-- Modifiers that we want to apply but don't have AllowIllusionDuplicate or their GetRemainingTime is 0
	local wanted_modifiers = {
		"modifier_item_armlet_unholy_strength",
		"modifier_alchemist_chemical_rage",
		"modifier_terrorblade_metamorphosis"
	}

	-- Modifiers that we DON'T want to apply - modifiers that cause bugs
	local modifier_ignore_list = {
		"modifier_terrorblade_metamorphosis_transform_aura",
		"modifier_terrorblade_metamorphosis_transform_aura_applier",
		"modifier_meepo_divided_we_stand"
	}

	-- Abilities that cause bugs
	local ability_ignore_list = {
		"meepo_divided_we_stand",
		"skeleton_king_reincarnation",
		"special_bonus_reincarnation_200",
		"roshan_spell_block",
		"roshan_bash",
		"roshan_slam",
		"roshan_inherent_buffs",
		"roshan_devotion",
		"ability_capture",
		"abyssal_underlord_portal_warp",
		"twin_gate_portal_warp",
		"ability_lamp_use",
		"ability_pluck_famango",
	}

	local illusion
	if method == 1 then
		if self:IsHero() then
			-- CDOTA_BaseNPC is a hero or an illusion (of a hero or a creep), that's how IsHero() works -> weird I know
			local unit_level = self:GetLevel()

			-- handle_UnitOwner needs to be nil, else it will crash the game.
			illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
			illusion:SetPlayerID(playerID)
			if controllable then
				illusion:SetControllableByPlayer(playerID, true)
			end
			illusion:SetOwner(owner)
			FindClearSpaceForUnit(illusion, origin, false)

			-- Level Up the illusion to the same level as the hero
			for i = 1, unit_level-1 do
				illusion:HeroLevelUp(false) -- false because we don't want to see level up effects
			end

			-- Set the skill points to 0 and learn the skills of the caster
			illusion:SetAbilityPoints(0)
			for ability_slot = 0, unit_ability_count-1 do
				local current_ability = self:GetAbilityByIndex(ability_slot)
				if current_ability then 
					local current_ability_level = current_ability:GetLevel()
					local current_ability_name = current_ability:GetAbilityName()
					local illusion_ability = illusion:FindAbilityByName(current_ability_name)
					if illusion_ability then
						local skip = false
						for i = 1, #ability_ignore_list do
							if current_ability_name == ability_ignore_list[i] then
								skip = true
							end
						end
						if not skip then
							illusion_ability:SetLevel(current_ability_level)
						else
							--illusion:RemoveAbility(illusion_ability:GetAbilityName())
						end
					end
				end
			end

			-- Recreate the items of the CDOTA_BaseNPC to be the same on illusion
			for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
				local item = self:GetItemInSlot(item_slot)
				if item then
					local item_name = item:GetName()
					local new_item = CreateItem(item_name, illusion, illusion)
					illusion:AddItem(new_item)
					new_item:SetStacksWithOtherOwners(true)
					new_item:SetPurchaser(nil)
					if new_item:RequiresCharges() then
						new_item:SetCurrentCharges(item:GetCurrentCharges())
					end
					if new_item:IsToggle() and item:GetToggleState() then
						new_item:ToggleAbility()
					end
				end
			end

			for _, modifier in ipairs(self:FindAllModifiers()) do
				local modifier_name = modifier:GetName()
				-- This doesn't work for vanilla modifiers because they don't have AllowIllusionDuplicate
				if modifier.AllowIllusionDuplicate and modifier:AllowIllusionDuplicate() and modifier:GetDuration() ~= -1 then
					local skip = false
					for i = 1, #modifier_ignore_list do
						if modifier_name == modifier_ignore_list[i] then
							skip = true
						end
					end
					if not skip then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetRemainingTime() })
					end
				end

				for i = 1, #wanted_modifiers do
					if modifier_name == wanted_modifiers[i] then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetDuration() })
					end
				end
			end

			-- Setting health and mana to be the same as the CDOTA_BaseNPC with items, abilities, buffs, debuffs...
			illusion:SetHealth(unit_HP)
			illusion:SetMana(unit_MP)

			-- Preventing dropping and selling items in inventory
			illusion:SetHasInventory(false)
			illusion:SetCanSellItems(false)

			-- Set the unit as an illusion
			-- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
			illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = duration, outgoing_damage = illusion_damage_dealt, incoming_damage = illusion_damage_taken})

			-- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
			illusion:MakeIllusion()
		else
			-- CDOTA_BaseNPC is a creep and not an illusion of a creep
			illusion = CreateUnitByName(unit_name, origin, true, caster, caster, caster:GetTeamNumber())
			if controllable then
				illusion:SetControllableByPlayer(playerID, true)
			end
			illusion:SetOwner(owner)
			FindClearSpaceForUnit(illusion, origin, false)

			for ability_slot = 0, unit_ability_count-1 do
				local current_ability = self:GetAbilityByIndex(ability_slot)
				if current_ability then 
					local current_ability_level = current_ability:GetLevel()
					local current_ability_name = current_ability:GetAbilityName()
					local illusion_ability = illusion:FindAbilityByName(current_ability_name)
					if illusion_ability then
						local skip = false
						for i = 1, #ability_ignore_list do
							if illusion_ability:GetAbilityName() == ability_ignore_list[i] then
								skip = true
							end
						end
						if not skip then
							illusion_ability:SetLevel(current_ability_level)
						else
							illusion:RemoveAbility(illusion_ability:GetAbilityName())
						end
					end
				end
			end

			for _, modifier in ipairs(self:FindAllModifiers()) do
				local modifier_name = modifier:GetName()
				if modifier.AllowIllusionDuplicate and modifier:AllowIllusionDuplicate() and modifier:GetDuration() ~= -1 then
					local skip = false
					for i = 1, #modifier_ignore_list do
						if modifier_name == modifier_ignore_list[i] then
							skip = true
						end
					end
					if not skip then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetRemainingTime() })
					end
				end

				for i = 1, #wanted_modifiers do
					if modifier_name == wanted_modifiers[i] then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetDuration() })
					end
				end
			end

			illusion:SetHealth(unit_HP)
			illusion:SetMana(unit_MP)

			illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = duration, outgoing_damage = illusion_damage_dealt, incoming_damage = illusion_damage_taken})
			illusion:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

			illusion:MakeIllusion()
		end
	elseif method == 2 then
		illusion = CreateUnitByName("npc_dota_custom_illusion_base", origin, true, caster, caster, caster:GetTeamNumber())

		if controllable then
			illusion:SetControllableByPlayer(playerID, true)
		end

		FindClearSpaceForUnit(illusion, origin, false)

		for ability_slot = 0, unit_ability_count-1 do
			local current_ability = self:GetAbilityByIndex(ability_slot)
			if current_ability then 
				local current_ability_level = current_ability:GetLevel()
				local current_ability_name = current_ability:GetAbilityName()
				local illusion_ability = illusion:FindAbilityByName(current_ability_name)
				if illusion_ability then
					illusion_ability:SetLevel(current_ability_level)
				else
					illusion_ability = illusion:AddAbility(current_ability_name)
					illusion_ability:SetLevel(current_ability_level) 
				end
			end
		end

		illusion:SetBaseMaxHealth(self:GetMaxHealth())
		illusion:SetMaxHealth(self:GetMaxHealth())
		illusion:SetHealth(self:GetHealth())
		illusion:SetBaseDamageMax(self:GetBaseDamageMax())
		illusion:SetBaseDamageMin(self:GetBaseDamageMin())
		illusion:SetPhysicalArmorBaseValue(self:GetPhysicalArmorValue())
		illusion:SetBaseAttackTime(self:GetBaseAttackTime())
		illusion:SetBaseMoveSpeed(self:GetBaseMoveSpeed())

		local model = self:GetModelName()
		illusion:SetOriginalModel(model)
		illusion:SetModel(model)
		illusion:SetModelScale(self:GetModelScale())

		local movement_capability = DOTA_UNIT_CAP_MOVE_NONE
		if self:HasMovementCapability() then
			movement_capability = DOTA_UNIT_CAP_MOVE_GROUND
			if self:HasFlyMovementCapability() then
				movement_capability = DOTA_UNIT_CAP_MOVE_FLY
			end
		end

		illusion:SetMoveCapability(movement_capability)
		illusion:SetAttackCapability(self:GetAttackCapability())
		illusion:SetUnitName(self:GetUnitName())

		if self:IsRangedAttacker() then
			illusion:SetRangedProjectileName(self:GetRangedProjectileName())
		end

		for _, modifier in ipairs(self:FindAllModifiers()) do
				local modifier_name = modifier:GetName()
				if modifier.AllowIllusionDuplicate and modifier:AllowIllusionDuplicate() then
					local skip = false
					for i = 1, #modifier_ignore_list do
						if modifier_name == modifier_ignore_list[i] then
							skip = true
						end
					end
					if not skip then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetRemainingTime() })
					end
				end

				for i = 1, #wanted_modifiers do
					if modifier_name == wanted_modifiers[i] then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetDuration() })
					end
				end
			end

		for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
			local item = self:GetItemInSlot(item_slot)
			if item then
				local item_name = item:GetName()
				local new_item = CreateItem(item_name, illusion, illusion)
				illusion:AddItem(new_item)
				new_item:SetStacksWithOtherOwners(true)
				new_item:SetPurchaser(nil)
				if new_item:RequiresCharges() then
					new_item:SetCurrentCharges(item:GetCurrentCharges())
				end
				if new_item:IsToggle() and item:GetToggleState() then
					new_item:ToggleAbility()
				end
			end
		end

		illusion:SetHasInventory(false)
		illusion:SetCanSellItems(false)

		illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = duration, outgoing_damage = illusion_damage_dealt, incoming_damage = illusion_damage_taken})

		for _, wearable in ipairs(self:GetChildren()) do
			if wearable:GetClassname() == "dota_item_wearable" and wearable:GetModelName() ~= "" then
				local newWearable = CreateUnitByName("npc_dota_custom_dummy_unit", illusion:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
				newWearable:SetOriginalModel(wearable:GetModelName())
				newWearable:SetModel(wearable:GetModelName())
				newWearable:AddNewModifier(caster, ability, "modifier_kill", { duration = duration })
				newWearable:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration })
				newWearable:SetParent(illusion, nil)
				newWearable:FollowEntity(illusion, true)
				Timers:CreateTimer(1, function()
					if illusion and not illusion:IsNull() and illusion:IsAlive() then
						return 0.25
					else
						UTIL_Remove(newWearable)
					end
				end)
			end
		end

		illusion:MakeIllusion()
	end

	if illusion then
		if illusion.custom_illusion == nil then
			illusion.custom_illusion = true
		end
	end

	return illusion
  end

  -- Is this CDOTA_BaseNPC a custom created illusion?
  -- Returns boolean
  function CDOTA_BaseNPC:IsCustomIllusion()
	if self == nil then
		return nil
	end
	if self.custom_illusion == true then
		return true
	end

	return false
  end
end
