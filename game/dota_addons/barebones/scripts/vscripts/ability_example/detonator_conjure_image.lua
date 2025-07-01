require('libraries/custom_illusions')

detonator_conjure_image = detonator_conjure_image or class({})

function detonator_conjure_image:IsStealable()
	return true
end

function detonator_conjure_image:IsHiddenWhenStolen()
	return false
end

function detonator_conjure_image:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()

	if not target or target:IsNull() then
		return
	end

	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if (not target:TriggerSpellAbsorb(self)) or (target:GetTeamNumber() == caster:GetTeamNumber()) then
		-- Target is a friend or an enemy that doesn't have Spell Block
		local duration = self:GetSpecialValueFor("duration")
		local damage_dealt = self:GetSpecialValueFor("illusion_damage_out")
		local damage_taken = self:GetSpecialValueFor("illusion_damage_in")
		if target:IsRealHero() or target:IsSpiritBearCustom() or target:IsTempestDouble() or target:IsClone() then
			local illu_table = {
				outgoing_damage = damage_dealt,
				incoming_damage = damage_taken,
				bounty_base = 1,
				bounty_growth = 1,
				outgoing_damage_structure = damage_dealt,
				outgoing_damage_roshan = damage_dealt,
				duration = duration,
			}

			-- Use Valve's function
			CreateIllusions(caster, target, illu_table, 1, target:GetHullRadius(), false, true)
		elseif target.CreateIllusion ~= nil then
			-- Use function from custom_illusions.lua
			target:CreateIllusion(caster, self, duration, nil, damage_dealt, damage_taken, true, 1)
		end
		-- Sound on the target
		target:EmitSound("Hero_Terrorblade.ConjureImage")
	end
end

function detonator_conjure_image:ProcsMagicStick()
	return true
end
