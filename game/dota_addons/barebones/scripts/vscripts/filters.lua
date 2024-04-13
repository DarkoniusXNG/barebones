-- Order Filter; order can be casting an ability, moving, clicking to attack, using scan (radar), glyph etc.
function barebones:OrderFilter(filter_table)
	--PrintTable(filter_table)

	local order = filter_table.order_type
	local units = filter_table.units
	local playerID = filter_table.issuer_player_id_const

	-- Order enums:
	-- DOTA_UNIT_ORDER_NONE = 0
	-- DOTA_UNIT_ORDER_MOVE_TO_POSITION = 1
	-- DOTA_UNIT_ORDER_MOVE_TO_TARGET = 2
	-- DOTA_UNIT_ORDER_ATTACK_MOVE = 3
	-- DOTA_UNIT_ORDER_ATTACK_TARGET = 4
	-- DOTA_UNIT_ORDER_CAST_POSITION = 5
	-- DOTA_UNIT_ORDER_CAST_TARGET = 6
	-- DOTA_UNIT_ORDER_CAST_TARGET_TREE = 7
	-- DOTA_UNIT_ORDER_CAST_NO_TARGET = 8
	-- DOTA_UNIT_ORDER_CAST_TOGGLE = 9
	-- DOTA_UNIT_ORDER_HOLD_POSITION = 10
	-- DOTA_UNIT_ORDER_TRAIN_ABILITY = 11
	-- DOTA_UNIT_ORDER_DROP_ITEM = 12
	-- DOTA_UNIT_ORDER_GIVE_ITEM = 13
	-- DOTA_UNIT_ORDER_PICKUP_ITEM = 14
	-- DOTA_UNIT_ORDER_PICKUP_RUNE = 15
	-- DOTA_UNIT_ORDER_PURCHASE_ITEM = 16
	-- DOTA_UNIT_ORDER_SELL_ITEM = 17
	-- DOTA_UNIT_ORDER_DISASSEMBLE_ITEM = 18
	-- DOTA_UNIT_ORDER_MOVE_ITEM = 19
	-- DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO = 20
	-- DOTA_UNIT_ORDER_STOP = 21
	-- DOTA_UNIT_ORDER_TAUNT = 22
	-- DOTA_UNIT_ORDER_BUYBACK = 23
	-- DOTA_UNIT_ORDER_GLYPH = 24
	-- DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH = 25
	-- DOTA_UNIT_ORDER_CAST_RUNE = 26
	-- DOTA_UNIT_ORDER_PING_ABILITY = 27
	-- DOTA_UNIT_ORDER_MOVE_TO_DIRECTION = 28
	-- DOTA_UNIT_ORDER_PATROL = 29
	-- DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION = 30
	-- DOTA_UNIT_ORDER_RADAR = 31
	-- DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK = 32
	-- DOTA_UNIT_ORDER_CONTINUE = 33
	-- DOTA_UNIT_ORDER_VECTOR_TARGET_CANCELED = 34
	-- DOTA_UNIT_ORDER_CAST_RIVER_PAINT = 35
	-- DOTA_UNIT_ORDER_PREGAME_ADJUST_ITEM_ASSIGNMENT = 36
	-- DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN = 37
	-- DOTA_UNIT_ORDER_TAKE_ITEM_FROM_NEUTRAL_ITEM_STASH = 39

	-- Example 1: If the order is an ability
	if order == DOTA_UNIT_ORDER_CAST_POSITION or order == DOTA_UNIT_ORDER_CAST_TARGET or order == DOTA_UNIT_ORDER_CAST_NO_TARGET or order == DOTA_UNIT_ORDER_CAST_TOGGLE or order == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO then
		local ability_index = filter_table.entindex_ability
		local ability
		if ability_index then
			ability = EntIndexToHScript(ability_index)
		end
		local caster
		if units and units["0"] then
			caster = EntIndexToHScript(units["0"])
		end
	end

	-- Example 2: If the order is a simple move command
	if order == DOTA_UNIT_ORDER_MOVE_TO_POSITION and units then
		local destination_x = filter_table.position_x
		local destination_y = filter_table.position_y
		local unit_with_order
		if units["0"] then
			unit_with_order = EntIndexToHScript(units["0"])
		end
	end
	
	-- Example 3: Disable item sharing for a custom courier that everyone can control
	--[[
	if order == DOTA_UNIT_ORDER_DROP_ITEM or order == DOTA_UNIT_ORDER_GIVE_ITEM then
		local unit_with_order = EntIndexToHScript(units["0"])
		local ability_index = filter_table.entindex_ability
		local ability = EntIndexToHScript(ability_index)

		if unit_with_order:IsCourier() and ability and ability:IsItem() then
			local purchaser = ability:GetPurchaser()
			if purchaser and purchaser:GetPlayerID() ~= playerID then
				CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#hud_error_courier_cant_order_item" })
				return false
			end
		end
	end
	]]

	return true
end

-- Damage filter function
function barebones:DamageFilter(keys)
	--PrintTable(keys)

	local attacker
	local victim
	if keys.entindex_attacker_const and keys.entindex_victim_const then
		attacker = EntIndexToHScript(keys.entindex_attacker_const)
		victim = EntIndexToHScript(keys.entindex_victim_const)
	else
		return false
	end

	local damage_type = keys.damagetype_const
	local inflictor = keys.entindex_inflictor_const	-- keys.entindex_inflictor_const is nil if damage is not caused by an ability
	local damage_after_reductions = keys.damage 	-- keys.damage is damage after reductions without spell amplifications

	-- Damage types:
	-- DAMAGE_TYPE_NONE = 0
	-- DAMAGE_TYPE_PHYSICAL = 1
	-- DAMAGE_TYPE_MAGICAL = 2
	-- DAMAGE_TYPE_PURE = 4
	-- DAMAGE_TYPE_ALL = 7
	-- DAMAGE_TYPE_HP_REMOVAL = 8

	-- Find the ability/item that dealt the dmg, if normal attack or no ability/item it will be nil
	local damaging_ability
	if inflictor then
		damaging_ability = EntIndexToHScript(inflictor)
	end

	-- Lack of entities handling (illusions error fix)
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	-- Update the gold bounty of the hero before he dies
	if USE_CUSTOM_HERO_GOLD_BOUNTY then
		if attacker:IsControllableByAnyPlayer() and victim:IsRealHero() and not victim:IsSpiritBearCustom() and not victim:IsTempestDouble() and not victim:IsClone() and damage_after_reductions >= victim:GetHealth() then
			-- Get his killing streak
			local hero_streak = victim:GetStreak()
			-- Get his level
			local hero_level = victim:GetLevel()
			-- Adjust Gold bounty
			local gold_bounty
			if hero_streak > 2 then
				gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL + (hero_streak-2)*HERO_KILL_GOLD_PER_STREAK
			else
				gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL
			end

			victim:SetMinimumGoldBounty(gold_bounty)
			victim:SetMaximumGoldBounty(gold_bounty)
		end
	end

	return true
end

-- Modifier (buffs, debuffs) filter function
function barebones:ModifierFilter(keys)
	--PrintTable(keys)

	local unit_with_modifier 
	if keys.entindex_parent_const then
		unit_with_modifier = EntIndexToHScript(keys.entindex_parent_const)
	end
	local modifier_name = keys.name_const
	local modifier_duration = keys.duration
	local caster
	if keys.entindex_caster_const then
		caster = EntIndexToHScript(keys.entindex_caster_const)
	end

	return true
end

-- Experience filter function
function barebones:ExperienceFilter(keys)
	--PrintTable(keys)
	local experience = keys.experience
	local playerID = keys.player_id_const
	local reason = keys.reason_const

	-- Reasons:
	-- DOTA_ModifyXP_Unspecified = 0
	-- DOTA_ModifyXP_HeroKill = 1
	-- DOTA_ModifyXP_CreepKill = 2
	-- DOTA_ModifyXP_RoshanKill = 3
	-- DOTA_ModifyXP_TomeOfKnowledge = 4
	-- DOTA_ModifyXP_Outpost = 5
	-- DOTA_ModifyXP_MAX = 6

	return true
end

-- Tracking Projectile (attack and spell projectiles) filter function
function barebones:ProjectileFilter(keys)
	--PrintTable(keys)

	local can_be_dodged = keys.dodgeable                   -- values: 1 for yes, 0 for no
	local ability_index = keys.entindex_ability_const      -- value if not ability: -1
	local source_index = keys.entindex_source_const
	local target_index = keys.entindex_target_const
	local expire_time = keys.expire_time
	local is_an_attack_projectile = keys.is_attack         -- values: 1 for yes or 0 for no
	local max_impact_time = keys.max_impact_time
	local projectile_speed = keys.move_speed

	return true
end

-- Bounty Rune Filter, can be used to modify Alchemist's Greevil Greed for example
function barebones:BountyRuneFilter(keys)
	--PrintTable(keys)

	local gold_bounty = keys.gold_bounty
	local playerID = keys.player_id_const
	local xp_bounty = keys.xp_bounty		-- value: 0

	return true
end

-- Healing Filter, can be used to modify how much hp regen and healing a unit is gaining
-- Triggers every time a unit gains health
function barebones:HealingFilter(keys)
	--PrintTable(keys)

	local healing_target_index = keys.entindex_target_const
	local heal_amount = keys.heal -- heal amount of the ability or health restored with hp regen during server tick
	local healer_index = keys.entindex_healer_const
	local healing_ability_index = keys.entindex_inflictor_const

	local healing_target
	if healing_target_index then
		healing_target = EntIndexToHScript(healing_target_index)
	end

	-- Find the source of the heal - the healer
	local healer
	if healer_index then
		healer = EntIndexToHScript(healer_index)
	else
		healer = healing_target -- hp regen
	end

	-- Find healing ability
	-- Abilities that give bonus hp regen don't count as healing abilities!!!
	local healing_ability
	if healing_ability_index then
		healing_ability = EntIndexToHScript(healing_ability_index)
	end
	-- If healing_ability is nil then the 'source' of the heal is unit's hp regen

	return true
end

-- Gold filter, can be used to modify how much gold player gains/loses
function barebones:GoldFilter(keys)
	--PrintTable(keys)

	local gold = keys.gold
	local playerID = keys.player_id_const
	local reason = keys.reason_const
	local reliable = keys.reliable

	-- Reasons:
	-- DOTA_ModifyGold_Unspecified = 0
	-- DOTA_ModifyGold_Death = 1
	-- DOTA_ModifyGold_Buyback = 2
	-- DOTA_ModifyGold_PurchaseConsumable = 3
	-- DOTA_ModifyGold_PurchaseItem = 4
	-- DOTA_ModifyGold_AbandonedRedistribute = 5
	-- DOTA_ModifyGold_SellItem = 6
	-- DOTA_ModifyGold_AbilityCost = 7
	-- DOTA_ModifyGold_CheatCommand = 8
	-- DOTA_ModifyGold_SelectionPenalty = 9
	-- DOTA_ModifyGold_GameTick = 10
	-- DOTA_ModifyGold_Building = 11
	-- DOTA_ModifyGold_HeroKill = 12
	-- DOTA_ModifyGold_CreepKill = 13
	-- DOTA_ModifyGold_NeutralKill = 14
	-- DOTA_ModifyGold_RoshanKill = 15
	-- DOTA_ModifyGold_CourierKill = 16
	-- DOTA_ModifyGold_BountyRune = 17
	-- DOTA_ModifyGold_SharedGold = 18
	-- DOTA_ModifyGold_AbilityGold = 19
	-- DOTA_ModifyGold_WardKill = 20

	-- Disable all hero kill gold
	if DISABLE_ALL_GOLD_FROM_HERO_KILLS then
		if reason == DOTA_ModifyGold_HeroKill then
			return false
		end
	end

	return true
end

-- Inventory filter, triggers every time a unit picks up or buys an item, doesn't trigger when you change item's slot inside inventory
function barebones:InventoryFilter(keys)
	--PrintTable(keys)

	local unit_with_inventory_index = keys.inventory_parent_entindex_const -- -1 if not defined
	local item_index = keys.item_entindex_const
	local owner_index = keys.item_parent_entindex_const -- -1 if not defined
	local item_slot = keys.suggested_slot -- slot in which the item should be put, usually its -1 meaning put in the first free slot

	-- Item slots:
	-- Inventory slots: DOTA_ITEM_SLOT_1 - DOTA_ITEM_SLOT_9
	-- Backpack slots: DOTA_ITEM_SLOT_7 - DOTA_ITEM_SLOT_9
	-- Stash slots: DOTA_STASH_SLOT_1 - DOTA_STASH_SLOT_6
	-- Teleport scroll slot: DOTA_ITEM_TP_SCROLL = 15
	-- Neutral item slot: DOTA_ITEM_NEUTRAL_SLOT = 16
	-- Other constants:
	-- DOTA_ITEM_INVENTORY_SIZE = 9 (DOTA_ITEM_SLOT_1 = 0; DOTA_ITEM_SLOT_9 = 8)
	-- DOTA_ITEM_STASH_MIN = 9 (same as DOTA_STASH_SLOT_1)
	-- DOTA_ITEM_STASH_MAX = 15
	-- DOTA_ITEM_TRANSIENT_ITEM = 17
	-- DOTA_ITEM_TRANSIENT_RECIPE = 18
	-- DOTA_ITEM_MAX = 19
	-- DOTA_ITEM_TRANSIENT_CAST_ITEM = 20

	local unit_with_inventory
	local unit_name
	if unit_with_inventory_index and unit_with_inventory_index ~= -1 then
		unit_with_inventory = EntIndexToHScript(unit_with_inventory_index)
		unit_name = unit_with_inventory:GetUnitName()
	end

	local item 
	if item_index then
		item = EntIndexToHScript(item_index)
	end
	local item_name
	if item then
		item_name = item:GetName()
	end

	local owner_of_this_item
	if owner_index and owner_index ~= -1 then
		-- not reliable
		owner_of_this_item = EntIndexToHScript(owner_index)
	elseif item then
		owner_of_this_item = item:GetPurchaser()
	end

	local owner_name
	if owner_of_this_item then
		if owner_of_this_item.GetUnitName then
			-- owner is an NPC
			owner_name = owner_of_this_item:GetUnitName()
		elseif owner_of_this_item.IsPlayer and (owner_of_this_item:IsPlayer() or owner_of_this_item:IsPlayerController()) then
			-- owner is a player
			owner_name = owner_of_this_item:GetName() -- not ideal but you get the idea
		end
	end

	return true
end
