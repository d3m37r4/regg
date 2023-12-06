#if defined _regg_hooks_included
	#endinput
#endif

#define _regg_hooks_included

enum _:hook_s {
	HookChain:HookDropClient,
	HookChain:HookRestartRound,
	HookChain:HookHasRestrictItem,
	HookChain:HookDropPlayerItem,
	HookChain:HookFShouldSwitchWeapon,
	HookChain:HookOnSpawnEquip,
	HookChain:HookExplodeHeGrenade,
	HookChain:HookKilled,
};

new HookChain:Hooks[hook_s];

registerHooks() {
	Hooks[HookDropClient] = RegisterHookChain(RH_SV_DropClient, "SV_DropClient_Post", true);
	Hooks[HookRestartRound] = RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound_Pre", false);
	Hooks[HookHasRestrictItem] = RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "CBasePlayer_HasRestrictItem_Pre", false);
	Hooks[HookDropPlayerItem] = RegisterHookChain(RG_CBasePlayer_DropPlayerItem, "CBasePlayer_DropPlayerItem_Pre", false);
	Hooks[HookFShouldSwitchWeapon] = RegisterHookChain(RG_CSGameRules_FShouldSwitchWeapon, "CSGameRules_FShouldSwitchWeapon_Pre", false);
	Hooks[HookOnSpawnEquip] = RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "CBasePlayer_OnSpawnEquip_Post", true);
	Hooks[HookExplodeHeGrenade] = RegisterHookChain(RG_CGrenade_ExplodeHeGrenade, "CGrenade_ExplodeHeGrenade_Pre", false);
	Hooks[HookKilled] = RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);
}

disableHooks() {
	for(new i = 0; i < sizeof(Hooks); i++) {
		Hooks[i] && DisableHookChain(Hooks[i]);
	}
}

toggleShouldSwitchWeapon(const bool:enable) {
	enable ? EnableHookChain(Hooks[HookFShouldSwitchWeapon]) : DisableHookChain(Hooks[HookFShouldSwitchWeapon]);
}

public SV_DropClient_Post(const id) {
	if(Mode != ReGG_ModeTeam) {
		return HC_CONTINUE;
	}

	return HC_CONTINUE;
}

public CSGameRules_RestartRound_Pre() {
	if(get_member_game(m_bCompleteReset))  {
		resetPlayersStats();
		resetTeamsStats();
	}
}

public CBasePlayer_HasRestrictItem_Pre() {
	// SetHookChainReturn(ATYPE_BOOL, true);
	// return HC_SUPERCEDE;
}

public CBasePlayer_DropPlayerItem_Pre() {
	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

public CSGameRules_FShouldSwitchWeapon_Pre() {
	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

public CBasePlayer_OnSpawnEquip_Post(const id) {
	if(!is_user_alive(id)) {
		return HC_CONTINUE;
	}

	if(!Players[id][PlayerJoined]) {
		playerJoin(id);
		Players[id][PlayerJoined] = true;
	}

	if(Mode == ReGG_ModeTeam) {
		new slot = getTeamSlot(id);
		giveWeapon(id, Teams[slot][TeamLevel]);
	} else {
		giveWeapon(id, Players[id][PlayerLevel]);
	}

	set_member(id, m_iHideHUD, get_member(id, m_iHideHUD) | HIDEHUD_MONEY);
	return HC_CONTINUE;
}

public CGrenade_ExplodeHeGrenade_Pre(const this) {
	new id = get_entvar(this, var_owner);
	
	if(!is_user_connected(id)) {
		return HC_CONTINUE;
	}

	new level;
	if(Mode == ReGG_ModeTeam) {
		new slot = getTeamSlot(id);
		level = Teams[slot][TeamLevel];
	} else {
		level = Players[id][PlayerLevel];
	}
	
	if(Levels[level][LevelWeaponID] == WEAPON_HEGRENADE) {
		rg_give_item(id, "weapon_hegrenade");
	}

	return HC_CONTINUE;
}

public CBasePlayer_Killed_Post(const victim, const killer) {
	if(victim == killer) {
		suicide(victim);
		return HC_CONTINUE;
	}

	if(!is_user_connected(killer) || !rg_is_player_can_takedamage(victim, killer)) {
		return HC_CONTINUE;
	}

	if(get_member(victim, m_bKilledByGrenade)) {
		killGrenade(killer, victim);
	} else if(get_entvar(victim, var_dmg_inflictor) == killer){
		new weapon = get_member(killer, m_pActiveItem);
		if(get_member(weapon, m_iId) == WEAPON_KNIFE) {
			killKnife(killer, victim);
		} else {
			killWeapon(killer, victim, weapon);
		}
	}

	return HC_CONTINUE;
}
