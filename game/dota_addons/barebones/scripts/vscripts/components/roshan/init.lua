-- Sponsored by Dota 2 Skirmish, dota2skirmish.com
-- Author: EarthSalamander42
-- Date: 31/07/2023

if not Roshan then
	Roshan = class({})

	require("components/roshan/events")

	Roshan.bonusMinuteBuff = 0 -- Starting strength of Roshan (e.g. if put 1200 Roshan's starting stats are the same as he would be at 20 min)

	ListenToGameEvent('npc_spawned', Dynamic_Wrap(Roshan, 'OnNPCSpawned'), Roshan)
end

function Roshan:GetBuffTime()
	return Roshan.bonusMinuteBuff
end
