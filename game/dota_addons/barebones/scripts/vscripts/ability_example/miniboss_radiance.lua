LinkLuaModifier("modifier_miniboss_radiance_custom", "ability_example/miniboss_radiance.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_miniboss_radiance_debuff_custom", "ability_example/miniboss_radiance.lua", LUA_MODIFIER_MOTION_NONE)

miniboss_radiance_custom = miniboss_radiance_custom or class({})

function miniboss_radiance_custom:Spawn()
	if IsServer() then
		self:SetLevel(1)
	end
end

function miniboss_radiance_custom:GetIntrinsicModifierName()
	return "modifier_miniboss_radiance_custom"
end

---------------------------------------------------------------------------------------------------

modifier_miniboss_radiance_custom = modifier_miniboss_radiance_custom or class({})

function modifier_miniboss_radiance_custom:IsHidden()
	return false
end

function modifier_miniboss_radiance_custom:IsDebuff()
	return false
end

function modifier_miniboss_radiance_custom:IsPurgable()
	return false
end

function modifier_miniboss_radiance_custom:OnCreated()
	if not IsServer() then return end

	local ability = self:GetAbility()
	
	local dmg_per_second = ability:GetSpecialValueFor("aura_damage")
	local dmg_interval = ability:GetSpecialValueFor("aura_interval")

	self.radius = ability:GetSpecialValueFor("aura_radius")
	self.dmg_per_interval = dmg_per_second * dmg_interval

	self:StartIntervalThink(dmg_interval)
end

function modifier_miniboss_radiance_custom:OnIntervalThink()
	local parent = self:GetParent()

	-- Don't do anything if parent doesnt exist or it's dead (don't do damage on the corpse)
	if not parent or parent:IsNull() or not parent:IsAlive() then
		return
	end

	local enemies = FindUnitsInRadius(
		parent:GetTeamNumber(),
		parent:GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	local damage_table = {
		attacker = parent,
		damage = self.dmg_per_interval,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(),
	}

	for _, enemy in pairs(enemies) do
		if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() then
			damage_table.victim = enemy
			ApplyDamage(damage_table)
		end
	end
end

-- aura stuff

function modifier_miniboss_radiance_custom:IsAura()
	return true
end

function modifier_miniboss_radiance_custom:GetAuraSearchType()
	return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_miniboss_radiance_custom:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_miniboss_radiance_custom:GetAuraRadius()
	return self.radius
end

function modifier_miniboss_radiance_custom:GetModifierAura()
	return "modifier_miniboss_radiance_debuff_custom"
end

-- function modifier_miniboss_radiance_custom:GetTexture()
	-- return "miniboss_radiance"
-- end

---------------------------------------------------------------------------------------------------
-- Visual effect, dmg is on aura applier
modifier_miniboss_radiance_debuff_custom = modifier_miniboss_radiance_debuff_custom or class({})

function modifier_miniboss_radiance_debuff_custom:IsHidden()
	return false
end

function modifier_miniboss_radiance_debuff_custom:IsPurgable()
	return false
end

function modifier_miniboss_radiance_debuff_custom:IsDebuff()
	return true
end

-- function modifier_miniboss_radiance_debuff_custom:GetTexture()
	-- return "miniboss_radiance"
-- end
