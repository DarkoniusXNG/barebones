chaos_knight_reality_rift_barebones = chaos_knight_reality_rift_barebones or class({})

LinkLuaModifier("modifier_chaos_knight_reality_rift_custom", "ability_example/modifier_chaos_knight_reality_rift_custom.lua", LUA_MODIFIER_MOTION_NONE)

function chaos_knight_reality_rift_barebones:IsStealable()
	return true
end

function chaos_knight_reality_rift_barebones:IsHiddenWhenStolen()
	return false
end

-- CastFilterResultTarget runs on client side first
function chaos_knight_reality_rift_barebones:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if default_result == UF_FAIL_MAGIC_IMMUNE_ENEMY then
		local caster = self:GetCaster()
		-- Talent that allows Reality Rift to target Spell Immune units ("special_bonus_unique_chaos_knight_custom_2")
		local pierces_immunity = self:GetSpecialValueFor("pierces_immunity") == 1
		if pierces_immunity then
			return UF_SUCCESS
		end
	end

	return default_result
end

function chaos_knight_reality_rift_barebones:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local caster_location = caster:GetAbsOrigin()
	local target_location = target:GetAbsOrigin()

	-- Calculate direction
	local direction = (target_location - caster_location):Normalized()
	direction.z = 0

	-- Calculate distance
	local distance = (target_location - caster_location):Length2D()

	-- Calculate the end position
	local min_range = self:GetSpecialValueFor("min_range")
	local max_range = self:GetSpecialValueFor("max_range")
	self.end_position = caster_location + direction*distance*RandomFloat(min_range, max_range)

	-- Sound and cast animation on the caster
	caster:EmitSound("Hero_ChaosKnight.RealityRift")
	caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_2)

	self.FX = {}
	local oRiftFX = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(oRiftFX, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster_location, true)
	ParticleManager:SetParticleControlEnt(oRiftFX, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
	ParticleManager:SetParticleControl(oRiftFX, 2, self.end_position)
	ParticleManager:SetParticleControlOrientation(oRiftFX, 2, direction, Vector(0,1,0), Vector(1,0,0))
	table.insert(self.FX, oRiftFX)

	local search_radius = self:GetSpecialValueFor("illusion_search_radius")
	self.illusions = FindUnitsInRadius(caster:GetTeamNumber(), caster_location, nil, search_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED, FIND_ANY_ORDER, false)

	for _, illusion in ipairs(self.illusions) do
		if caster ~= illusion and illusion:IsIllusion() and illusion:GetPlayerOwnerID() == caster:GetPlayerOwnerID() then
			illusion:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_2)
			local iRiftFX = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_CUSTOMORIGIN, target)
			ParticleManager:SetParticleControlEnt(iRiftFX, 0, illusion, PATTACH_POINT_FOLLOW, "attach_hitloc", illusion:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(iRiftFX, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
			ParticleManager:SetParticleControl(iRiftFX, 2, self.end_position)
			ParticleManager:SetParticleControlOrientation(iRiftFX, 2, direction, Vector(0,1,0), Vector(1,0,0))
			table.insert(self.FX, iRiftFX)
		end
	end

	return true
end

function chaos_knight_reality_rift_barebones:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	for _, fx in pairs(self.FX) do
		if fx then
			ParticleManager:DestroyParticle(fx, false)
			ParticleManager:ReleaseParticleIndex(fx)
		end
	end
	for _, illusion in pairs(self.illusions) do
		if not illusion:IsNull() then
			if caster ~= illusion and illusion:IsIllusion() and illusion:GetPlayerOwnerID() == caster:GetPlayerOwnerID() then
				illusion:RemoveGesture(ACT_DOTA_OVERRIDE_ABILITY_2)
			end
		end
	end

	caster:StopSound("Hero_ChaosKnight.RealityRift")
end

-- OnSpellStart works only on the Server
function chaos_knight_reality_rift_barebones:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	for _, fx in pairs(self.FX) do
		if fx then
			--ParticleManager:DestroyParticle(fx, true)
			ParticleManager:ReleaseParticleIndex(fx)
		end
	end

	local duration = self:GetSpecialValueFor("reduction_duration")

	-- Check if target exists and if it has Spell Block
	if target and not target:TriggerSpellAbsorb(self) then
		
		-- Sound on the target
		target:EmitSound("Hero_ChaosKnight.RealityRift.Target")
		
		-- Teleport
		FindClearSpaceForUnit(caster, self.end_position, true)
		FindClearSpaceForUnit(target, self.end_position, true)
		
		-- Facing of the caster and the target
		caster:FaceTowards(target:GetAbsOrigin()) 	-- FaceTowards exists only on Server
		target:FaceTowards(caster:GetAbsOrigin())
		
		target:AddNewModifier(caster, self, "modifier_chaos_knight_reality_rift_custom", {duration = duration})
		
		caster:MoveToTargetToAttack(target)			-- MoveToTargetToAttack exists only on Server
		
		for _, illusion in pairs(self.illusions) do
			if not illusion:IsNull() then
				if caster ~= illusion and illusion:IsIllusion() and illusion:GetPlayerOwnerID() == caster:GetPlayerOwnerID() then
					FindClearSpaceForUnit(illusion, self.end_position, true)
					illusion:FaceTowards(target:GetAbsOrigin())
					illusion:MoveToTargetToAttack(target)
				end
			end
		end
	end
end

function chaos_knight_reality_rift_barebones:ProcsMagicStick()
	return true
end
