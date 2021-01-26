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
	HookChain:HookThrowHeGrenade,
	HookChain:HookKilled,
};

new Hooks[hook_s];

registerHooks() {
	Hooks[HookDropClient] = RegisterHookChain(RH_SV_DropClient, "SV_DropClient_Post", true);
	Hooks[HookRestartRound] = RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound_Pre", false);
	Hooks[HookHasRestrictItem] = RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "CBasePlayer_HasRestrictItem_Pre", false);
	Hooks[HookDropPlayerItem] = RegisterHookChain(RG_CBasePlayer_DropPlayerItem, "CBasePlayer_DropPlayerItem_Pre", false);
	Hooks[HookFShouldSwitchWeapon] = RegisterHookChain(RG_CSGameRules_FShouldSwitchWeapon, "CSGameRules_FShouldSwitchWeapon_Pre", false);

	Hooks[HookOnSpawnEquip] = RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "CBasePlayer_OnSpawnEquip_Pre", false);
	Hooks[HookThrowHeGrenade] = RegisterHookChain(RG_ThrowHeGrenade, "CBasePlayer_ThrowHeGrenade_Post", true);
	Hooks[HookKilled] = RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);
}

disableHooks() {
	for(new i = 0; i < sizeof(Hooks); i++) {
		DisableHookChain(HookChain:Hooks[i]);
	}
}

toggleShouldSwitchWeapon(const bool:enable) {
    if(enable) {
        EnableHookChain(Hooks[HookFShouldSwitchWeapon]);
    } else {
        DisableHookChain(Hooks[HookFShouldSwitchWeapon]);
    }
}

public SV_DropClient_Post(const id) {
	if(Mode != ReGG_ModeTeam) {
		return HC_CONTINUE;
	}

	return HC_CONTINUE;
}

public CSGameRules_RestartRound_Pre() {
	if(!get_member_game(m_bCompleteReset)) {
		return HC_CONTINUE;
	}
	for(new player = 1; player <= MaxClients; player++) {
		Players[player][PlayerPoints] = 0;
		Players[player][PlayerLevel] = 0;

		if(is_user_connected(player) && (TEAM_TERRORIST <= TeamName:get_member(player, m_iTeam) <= TEAM_CT)) {
			rg_remove_all_items(player, true);
			giveDefaultWeapons(player);
			giveWeapon(player, 0);
		}
	}
	for(new slot = ReGG_SlotT; slot <= ReGG_SlotCT; slot++) {
		Teams[slot][TeamPoints] = 0;
		Teams[slot][TeamLevel] = 0;
	}
	return HC_CONTINUE;
}

public CBasePlayer_HasRestrictItem_Pre() {
	SetHookChainReturn(ATYPE_BOOL, true);
	return HC_SUPERCEDE;
}

public CBasePlayer_DropPlayerItem_Pre() {
	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

public CSGameRules_FShouldSwitchWeapon_Pre() {
	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

public CBasePlayer_OnSpawnEquip_Pre(const id) {
	if(!is_user_alive(id)) {
		return HC_CONTINUE;
	}

	if(!Players[id][PlayerJoined]) {
		playerJoin(id);
		Players[id][PlayerJoined] = true;
	}

	giveDefaultWeapons(id);
	if(Mode == ReGG_ModeTeam) {
		new slot = getTeamSlot(id);
		giveWeapon(id, Teams[slot][TeamLevel]);
	} else {
		giveWeapon(id, Players[id][PlayerLevel]);
	}

	set_member(id, m_iHideHUD, get_member(id, m_iHideHUD) | HIDEHUD_MONEY);

	return HC_SUPERCEDE;
}

public CBasePlayer_ThrowHeGrenade_Post(const id) {
	set_task(Config[CfgNadeRefresh], "TaskGiveGrenade", TASK_GRENADE_ID + id);
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

	remove_task(TASK_GRENADE_ID + victim);
	return HC_CONTINUE;
}
