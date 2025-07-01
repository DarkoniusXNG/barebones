modifier_chaos_knight_reality_rift_custom = modifier_chaos_knight_reality_rift_custom or class({})

function modifier_chaos_knight_reality_rift_custom:IsHidden()
	return false
end

function modifier_chaos_knight_reality_rift_custom:IsPurgable()
	return true
end

function modifier_chaos_knight_reality_rift_custom:IsDebuff()
	return true
end

-- Modifiers exist both on server and client, so be careful which methods and functions you use
function modifier_chaos_knight_reality_rift_custom:OnCreated()
	local ability = self:GetAbility()
	self.armor_reduction = ability:GetSpecialValueFor("armor_reduction")
end

modifier_chaos_knight_reality_rift_custom.OnRefresh = modifier_chaos_knight_reality_rift_custom.OnCreated

function modifier_chaos_knight_reality_rift_custom:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_chaos_knight_reality_rift_custom:GetModifierPhysicalArmorBonus()
	return 0 - math.abs(self.armor_reduction)
end

function modifier_chaos_knight_reality_rift_custom:GetEffectName()
	-- Chaos Knight Reality Rift uses Medallion of Courage particle
	return "particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift_buff.vpcf"
end

function modifier_chaos_knight_reality_rift_custom:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_chaos_knight_reality_rift_custom:ShouldUseOverheadOffset()
	return true
end
