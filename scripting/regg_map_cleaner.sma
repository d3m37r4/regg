#include <amxmodx>
#include <engine>
#include <reapi>
#include "include/regg.inc"

new BlockMapConditions;
new bool:Blocked = false;
new HookChain:CheckMapConditionsPre, HookChain:CleanUpMapPost, HookChain:RestartRoundPost, HookChain:PlayerSpawnPost;
new bool:CTCantBuy, bool:TCantBuy;
new bool:MapHasBombTarget, bool:MapHasBombZone, bool:MapHasRescueZone, bool:MapHasBuyZone, bool:MapHasEscapeZone, bool:MapHasVIPSafetyZone;

public plugin_init() {
	register_plugin("[ReAPI] GunGame Map Cleaner", "0.1.0-alpha", "F@nt0M");

	bind_pcvar_num(create_cvar(
		"regg_block_map_conditions", "1",
		.has_min = true, .min_val = 0.0,
		.has_max = true, .max_val = 1.0
	), BlockMapConditions);

	CheckMapConditionsPre = RegisterHookChain(RG_CSGameRules_CheckMapConditions, "CSGameRules_CheckMapConditions_Pre", false);
	CleanUpMapPost = RegisterHookChain(RG_CSGameRules_CleanUpMap, "CSGameRules_CleanUpMap_Post", true);
	RestartRoundPost = RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound_Post", true);
	PlayerSpawnPost = RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Post", true);
	DisableHookChain(CheckMapConditionsPre);
	DisableHookChain(CleanUpMapPost);
	DisableHookChain(RestartRoundPost);
	DisableHookChain(PlayerSpawnPost);
}

public plugin_pause() {
	if (Blocked) {
		toggleBlock(false);
	}
}

public ReGG_StartPost(const ReGG_Mode:mode) {
	toggleBlock(true);
}

public ReGG_FinishPost() {
	toggleBlock(false);
}

public CSGameRules_CheckMapConditions_Pre() {
	set_member_game(m_bCTCantBuy, true);
	set_member_game(m_bTCantBuy, true);
	return HC_SUPERCEDE;
}

public CSGameRules_CleanUpMap_Post() {
	if (BlockMapConditions) {
		removeHostageEntities();
	}
	removeArmouryEntities();
}

public CSGameRules_RestartRound_Post() {
	removeHostageEntities();
}

public CBasePlayer_Spawn_Post(const id) {
	set_member(id, m_tmHandleSignals, get_gametime() + 9999.0);
}

toggleBlock(const bool:blocked = true) {
	if (blocked == Blocked) {
		return;
	}
	Blocked = blocked;
	if (Blocked) {
		if (BlockMapConditions) {
			EnableHookChain(CheckMapConditionsPre);
			EnableHookChain(RestartRoundPost);
			EnableHookChain(PlayerSpawnPost);

			CTCantBuy = get_member_game(m_bCTCantBuy);
			TCantBuy = get_member_game(m_bTCantBuy);
			MapHasBombTarget = get_member_game(m_bMapHasBombTarget);
			MapHasBombZone = get_member_game(m_bMapHasBombZone);
			MapHasRescueZone = get_member_game(m_bMapHasRescueZone);
			MapHasBuyZone = get_member_game(m_bMapHasBuyZone);
			MapHasEscapeZone = get_member_game(m_bMapHasEscapeZone);
			MapHasVIPSafetyZone = get_member_game(m_bMapHasVIPSafetyZone);

			set_member_game(m_bCTCantBuy, true);
			set_member_game(m_bTCantBuy, true);
			set_member_game(m_bMapHasBombTarget, false);
			set_member_game(m_bMapHasBombZone, false);
			set_member_game(m_bMapHasRescueZone, false);
			set_member_game(m_bMapHasBuyZone, false);
			set_member_game(m_bMapHasEscapeZone, false);
			set_member_game(m_bMapHasVIPSafetyZone, false);

			removeHostageEntities();
		}

		EnableHookChain(CleanUpMapPost);
		removeArmouryEntities();
		removeTargetNameEntities();
	} else {
		if (BlockMapConditions) {
			DisableHookChain(CheckMapConditionsPre);
			DisableHookChain(RestartRoundPost);
			DisableHookChain(PlayerSpawnPost);

			set_member_game(m_bCTCantBuy, CTCantBuy);
			set_member_game(m_bTCantBuy, TCantBuy);
			set_member_game(m_bMapHasBombTarget, MapHasBombTarget);
			set_member_game(m_bMapHasBombZone, MapHasBombZone);
			set_member_game(m_bMapHasRescueZone, MapHasRescueZone);
			set_member_game(m_bMapHasBuyZone, MapHasBuyZone);
			set_member_game(m_bMapHasEscapeZone, MapHasEscapeZone);
			set_member_game(m_bMapHasVIPSafetyZone, MapHasVIPSafetyZone);

			restoreHostageEntities();

			for (new player = 1; player <= MaxClients; player++) {
				if (is_user_connected(player)) {
					set_member(player, m_tmHandleSignals, 0.0);
				}
			}
		}

		DisableHookChain(CleanUpMapPost);
		restoreArmouryEntities();
		restoreTargetNameEntities();
	}
}

removeHostageEntities() {
	new ent;
	while((ent = rg_find_ent_by_class(ent, "hostage_entity"))) {
		set_entvar(ent, var_health, 0.0);
		set_entvar(ent, var_takedamage, DAMAGE_NO);
		set_entvar(ent, var_movetype, MOVETYPE_NONE);
		set_entvar(ent, var_deadflag, DEAD_DEAD);              
		set_entvar(ent, var_effects, get_entvar(ent, var_effects) | EF_NODRAW);
		set_entvar(ent, var_solid, SOLID_NOT);
		set_entvar(ent, var_nextthink, -1.0);
	}
	while((ent = rg_find_ent_by_class(ent, "monster_scientist"))) {
		set_entvar(ent, var_health, 0.0);
		set_entvar(ent, var_takedamage, DAMAGE_NO);
		set_entvar(ent, var_movetype, MOVETYPE_NONE);
		set_entvar(ent, var_deadflag, DEAD_DEAD);              
		set_entvar(ent, var_effects, get_entvar(ent, var_effects) | EF_NODRAW);
		set_entvar(ent, var_solid, SOLID_NOT);
		set_entvar(ent, var_nextthink, -1.0);
	}
}

restoreHostageEntities() {
	new ent;
	while((ent = rg_find_ent_by_class(ent, "hostage_entity"))) {
		set_entvar(ent, var_health, Float:get_entvar(ent, var_max_health));
		set_entvar(ent, var_takedamage, DAMAGE_YES);
		set_entvar(ent, var_movetype, MOVETYPE_STEP);
		set_entvar(ent, var_deadflag, DEAD_NO);              
		set_entvar(ent, var_effects, get_entvar(ent, var_effects) & ~EF_NODRAW);
		set_entvar(ent, var_solid, SOLID_SLIDEBOX);
		set_entvar(ent, var_nextthink, get_gametime() + 0.01);
	}
	while((ent = rg_find_ent_by_class(ent, "monster_scientist"))) {
		set_entvar(ent, var_health, Float:get_entvar(ent, var_max_health));
		set_entvar(ent, var_takedamage, DAMAGE_YES);
		set_entvar(ent, var_movetype, MOVETYPE_STEP);
		set_entvar(ent, var_deadflag, DEAD_NO);              
		set_entvar(ent, var_effects, get_entvar(ent, var_effects) & ~EF_NODRAW);
		set_entvar(ent, var_solid, SOLID_SLIDEBOX);
		set_entvar(ent, var_nextthink, get_gametime() + 0.01);
	}
}

removeArmouryEntities() {
	new ent;
	while((ent = rg_find_ent_by_class(ent, "armoury_entity"))) {
		set_entvar(ent, var_effects, get_entvar(ent, var_effects) | EF_NODRAW);
		set_entvar(ent, var_solid, SOLID_NOT);
	}
}

restoreArmouryEntities() {
	new ent;
	while((ent = rg_find_ent_by_class(ent, "armoury_entity"))) {
		set_entvar(ent, var_effects, get_entvar(ent, var_effects) & ~EF_NODRAW);
		set_entvar(ent, var_solid, SOLID_TRIGGER);
	}
}

removeTargetNameEntities() {
	new ent;
	while((ent = rg_find_ent_by_class(ent, "player_weaponstrip"))) {
		set_entvar(ent, var_targetname, "stripper_dummy");
	}
	while((ent = rg_find_ent_by_class(ent, "game_player_equip"))) {
		set_entvar(ent, var_targetname,"equipment_dummy");
	}
}

restoreTargetNameEntities() {
	new ent;
	while((ent = rg_find_ent_by_class(ent, "player_weaponstrip"))) {
		set_entvar(ent, var_targetname, "stripper");
	}
	while((ent = rg_find_ent_by_class(ent, "game_player_equip"))) {
		set_entvar(ent, var_targetname,"equipment");
	}
}
