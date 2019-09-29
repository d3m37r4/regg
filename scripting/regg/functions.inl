#if defined _regg_functions_included
	#endinput
#endif

#define _regg_functions_included

#define GET_PLAYER_SLOT(%1,%2,%3) if ((%2 = getTeamSlot(%1)) == ReGG_SlotInvalid) return %3

bool:playerJoin(const id) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_PlayerJoin, false, id);
	if (Mode == ReGG_ModeTeam) {
		new slot;
		GET_PLAYER_SLOT(id, slot, false);
		Players[id][PlayerPoints] = Teams[slot][TeamPoints];
		Players[id][PlayerLevel] = Teams[slot][TeamLevel];
		return true;
	}

	Players[id][PlayerPoints] = 0;

	new min, max;
	for (new player = 1, slot; player <= MaxClients; player++) {
		if (!is_user_connected(player) || is_user_hltv(player)) {
			continue;
		}

		slot = getTeamSlot(player);
		if (slot == ReGG_SlotInvalid) {
			continue;
		}

		if (Players[player][PlayerLevel] < min) {
			min = Players[player][PlayerLevel];
		}

		if (Players[player][PlayerLevel] > max) {
			max = Players[player][PlayerLevel];
		}
	}

	Players[id][PlayerLevel] = min + ((max - min) / 2);
	EXECUTE_FORWARD_POST_ARGS(FWD_PlayerJoin, id);
	return true;
}

ReGG_Result:killWeapon(const killer, const victim, const weapon) {
	new WeaponIdType:wid = WeaponIdType:get_member(weapon, m_iId);
	EXECUTE_FORWARD_PRE_ARGS(FWD_KillEnemy, ReGG_ResultNone, killer, victim, wid, ReGG_ResultNone, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);

	new level = Players[killer][PlayerLevel];
	new ReGG_Result:result = ReGG_ResultNone;
	if (Levels[level][LevelWeaponID] != WEAPON_HEGRENADE) {
		result = setPoints(killer, 1);
	}
	if (Config[CfgRefillOnKill]) {
		rg_instant_reload_weapons(killer, weapon);
	}
	EXECUTE_FORWARD_POST_ARGS(FWD_KillEnemy, killer, victim, wid, result, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);
	return result;
}

ReGG_Result:killGrenade(const killer, const victim) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_KillEnemy, ReGG_ResultNone, killer, victim, WEAPON_HEGRENADE, ReGG_ResultNone, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);

	new level = Players[killer][PlayerLevel];
	if (Levels[level][LevelWeaponID] != WEAPON_HEGRENADE) {
		EXECUTE_FORWARD_POST_ARGS(FWD_KillEnemy, killer, victim, WEAPON_HEGRENADE, ReGG_ResultNone, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);
		return ReGG_ResultNone;
	}

	new ReGG_Result:result = setPoints(killer, 1);
	if (Config[CfgRefillOnKill] && result == ReGG_ResultPointsUp) {
		remove_task(TASK_GRENADE_ID + killer);
		rg_give_item(killer, "weapon_hegrenade", GT_REPLACE);
	}
	EXECUTE_FORWARD_POST_ARGS(FWD_KillEnemy, killer, victim, WEAPON_HEGRENADE, result, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);
	return result;
}

ReGG_Result:killKnife(const killer, const victim) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_KillEnemy, ReGG_ResultNone, killer, victim, WEAPON_KNIFE, ReGG_ResultNone, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);

	new ReGG_Result:result = ReGG_ResultNone;
	new level = Players[killer][PlayerLevel];
	if (Levels[level][LevelWeaponID] == WEAPON_KNIFE) {
		toggleShouldSwitchWeapon(true);
		result = setPoints(killer, 1);
		toggleShouldSwitchWeapon(false);
	} else if (Levels[level][LevelWeaponID] != WEAPON_HEGRENADE) {
		toggleShouldSwitchWeapon(true);
		switch (Config[CfgKnifeStealMode]) {
			case 1: {
				if (Mode == ReGG_ModeTeam) {
					result = setPoints(killer, Config[CfgKnifeStealPoints]);
				} else {
					result = setPlayerLevel(killer, 1);
				}
			}
			case 2: {
				result = setPoints(killer, Config[CfgKnifeStealPoints]);
			}
			
			default: {
				result = setPoints(killer, 1);
			}
		}
		toggleShouldSwitchWeapon(false);
	}

	if (result == ReGG_ResultFinish) {
		EXECUTE_FORWARD_POST_ARGS(FWD_KillEnemy, killer, victim, WEAPON_KNIFE, result, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);
		finish();
		return ReGG_ResultFinish;
	}

	stealPoints(killer, victim);
	EXECUTE_FORWARD_POST_ARGS(FWD_KillEnemy, killer, victim, WEAPON_KNIFE, result, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);
	return result;
}

giveDefaultWeapons(const id) {
	if (Config[CfgGiveArmor] > 0) {
		rg_set_user_armor(id, Config[CfgGiveArmor], Config[CfgGiveHelmet] ? ARMOR_VESTHELM : ARMOR_KEVLAR);
	}

	rg_give_item(id, "weapon_knife");
}

bool:giveWeapon(const id, const level) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_GiveWeapon, false, id, Levels[level][LevelWeaponID]);
	switch (Levels[level][LevelWeaponID]) {
		case WEAPON_KNIFE: {}

		case WEAPON_HEGRENADE: {
			rg_give_item(id, "weapon_hegrenade");
			for (new i = 0, weapon, wname[32]; i < GrenadeWeaponsNum; i++) {
				rg_get_weapon_info(GrenadeWeapons[i], WI_NAME, wname, charsmax(wname));
				weapon = rg_give_item(id, wname);
				if (!is_nullent(weapon)) {
					rg_set_user_bpammo(id, GrenadeWeapons[i], Config[CfgAmmoAmount]);
				}
			}
		}

		case WEAPON_AWP: {
			new weapon = rg_give_item(id, "weapon_awp");
			if (!is_nullent(weapon)) {
				rg_set_user_bpammo(id, WEAPON_AWP, Config[CfgAmmoAmount]);

				if (Config[CfgAWPOneShot]) {
					rg_set_user_ammo(id, WEAPON_AWP, 1);
					rg_set_iteminfo(weapon, ItemInfo_iMaxClip, 1);
				}
			}
		}

		default: {
			new wname[32];
			new WeaponIdType:wid = Levels[level][LevelWeaponID];
			rg_get_weapon_info(wid, WI_NAME, wname, charsmax(wname));
			new weapon = rg_give_item(id, wname);
			if (!is_nullent(weapon)) {
				rg_set_user_bpammo(id, wid, Config[CfgAmmoAmount]);
			}
		}
	}
	EXECUTE_FORWARD_POST_ARGS(FWD_GiveWeapon, id, Levels[level][LevelWeaponID]);
	return true;
}

removeWeapon(const id, const level) {
	if (level < 0 || level >= LevelsNum) {
		return;
	}
	new WeaponIdType:wid = Levels[level][LevelWeaponID];
	if (wid != WEAPON_KNIFE) {
		new wname[32];
		rg_get_weapon_info(wid, WI_NAME, wname, charsmax(wname));
		rg_remove_item(id, wname, true);
	}
}

bool:start(const ReGG_Mode:mode) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_Start, false, mode);

	Mode = mode;

	changeGameCvars();

	EnableHookChain(Hooks[HookDropClient]);
	EnableHookChain(Hooks[HookRestartRound]);
	EnableHookChain(Hooks[HookHasRestrictItem]);
	EnableHookChain(Hooks[HookDropPlayerItem]);
	EnableHookChain(Hooks[HookDeadPlayerWeapons]);
	EnableHookChain(Hooks[HookDeadGiveC4]);
	EnableHookChain(Hooks[HookOnSpawnEquip]);
	EnableHookChain(Hooks[HookThrowHeGrenade]);
	EnableHookChain(Hooks[HookKilled]);

	EXECUTE_FORWARD_POST_ARGS(FWD_Start, mode);
	rg_restart_round();
	return true;
}

bool:finish() {
	EXECUTE_FORWARD_PRE(FWD_Finish, false);
	restoreGameCvars();
	disableHooks();
	EXECUTE_FORWARD_POST(FWD_Finish);

	Mode = ReGG_ModeNone;
	rg_restart_round();
	return true;
}

ReGG_Result:stealPoints(const killer, const victim) {
	#pragma unused killer
	if (Config[CfgKnifeStealMode] == 0) {
		return ReGG_ResultNone;
	}
	new level = Players[victim][PlayerLevel];
	if (Mode != ReGG_ModeTeam && Config[CfgKnifeStealMode] == 1) {
		return level > 0 ? setLevel(victim, -1) : ReGG_ResultNone;
	}

	return setPoints(victim, -Config[CfgKnifeStealPoints]);
}

ReGG_Result:setPoints(const id, const value) {
	if (Mode != ReGG_ModeTeam) {
		return setPlayerPoints(id, value);
	}

	new slot;
	GET_PLAYER_SLOT(id, slot, ReGG_ResultNone);
	return setTeamPoints(slot ,value);
}

ReGG_Result:setPlayerPoints(const id, const value, const bool:add = true, const bool:forwards = true) {
	if (value == 0) {
		return ReGG_ResultNone;
	}

	if (forwards) EXECUTE_FORWARD_PRE_ARGS(FWD_PlayerPoints, ReGG_ResultNone, id, value);

	new oldValue = Players[id][PlayerPoints];
	if (add) {
		Players[id][PlayerPoints] += value;
	} else {
		Players[id][PlayerPoints] = value;
	}

	new ReGG_Result:result = ReGG_ResultNone;
	if (Players[id][PlayerPoints] >= getPlayerLevelPoints(id)) {
		result = setPlayerLevel(id, 1);
	} else if (Players[id][PlayerPoints] < 0) {
		result = setPlayerLevel(id, -1);
	}
	if (forwards) EXECUTE_FORWARD_POST_ARGS(FWD_PlayerPoints, id, value);

	if (result != ReGG_ResultNone) {
		return result;
	}
	return Players[id][PlayerPoints] > oldValue ? ReGG_ResultPointsUp : ReGG_ResultPointsDown;
}

ReGG_Result:setTeamPoints(const slot, const value, const bool:add = true, const bool:forwards = true) {
	if (value == 0) {
		return ReGG_ResultNone;
	}

	if (forwards) EXECUTE_FORWARD_PRE_ARGS(FWD_TeamPoints, ReGG_ResultNone, slot, value);

	new oldValue = Teams[slot][TeamPoints];
	if (add) {
		Teams[slot][TeamPoints] += value;
	} else {
		Teams[slot][TeamPoints] = value;
	}

	for (new player = 1, slot; player <= MaxClients; player++) {
		if (!is_user_connected(player) || is_user_hltv(player)) {
			continue;
		}

		slot = getTeamSlot(player);
		if (slot == ReGG_SlotInvalid) {
			continue;
		}

		Players[player][PlayerPoints] = Teams[slot][TeamPoints];
		EXECUTE_FORWARD_POST_ARGS(FWD_PlayerPoints, player, value);
	}

	new ReGG_Result:result = ReGG_ResultNone;
	if (Teams[slot][TeamPoints] >= getTeamLevelPoints(slot)) {
		result = setTeamLevel(slot, 1);
	} else if (Teams[slot][TeamPoints] < 0) {
		result = setTeamLevel(slot, -1);
	}

	if (forwards) EXECUTE_FORWARD_POST_ARGS(FWD_TeamPoints, slot, value);

	if (result != ReGG_ResultNone) {
		return result;
	}
	return Teams[slot][TeamPoints] > oldValue ? ReGG_ResultPointsUp : ReGG_ResultPointsDown;
}

ReGG_Result:setLevel(const id, const value) {
	if (Mode != ReGG_ModeTeam) {
		return setPlayerLevel(id, value);
	}

	new slot;
	GET_PLAYER_SLOT(id, slot, ReGG_ResultNone);
	return setTeamLevel(slot, value);
}

ReGG_Result:setPlayerLevel(const id, const value, const bool:add = true, const bool:forwards = true) {
	if (add && value == 0) {
		return ReGG_ResultNone;
	}

	if (forwards) EXECUTE_FORWARD_PRE_ARGS(FWD_PlayerLevel, ReGG_ResultNone, id, value);
	new ReGG_Result:result = ReGG_ResultNone;
	new oldValue = Players[id][PlayerLevel];
	if (add) {
		Players[id][PlayerLevel] += value;
	} else {
		Players[id][PlayerLevel] = value;
	}

	if (Players[id][PlayerLevel] >= LevelsNum) {
		Players[id][PlayerLevel] = LevelsNum - 1;
		result = ReGG_ResultFinish;
	}

	if (Players[id][PlayerLevel] < 0) {
		Players[id][PlayerLevel] = 0;
	}

	if (result == ReGG_ResultNone) {
		result = Players[id][PlayerLevel] > oldValue ? ReGG_ResultLevelUp : ReGG_ResultLevelDown;
	}

	Players[id][PlayerPoints] = 0;

	if (oldValue != Players[id][PlayerLevel]) {
		new newLevel =  Players[id][PlayerLevel];
		if (Levels[newLevel][LevelWeaponID] != WEAPON_KNIFE) {
			removeWeapon(id, oldValue);
		} else {
			rg_remove_all_items(id, true);
			giveDefaultWeapons(id);
		}
		giveWeapon(id, Players[id][PlayerLevel]);
	}

	if (forwards) EXECUTE_FORWARD_POST_ARGS(FWD_PlayerLevel, id, value);
	return result;
}

ReGG_Result:setTeamLevel(const slot, const value, const bool:add = true, const bool:forwards = true) {
	if (value == 0) {
		return ReGG_ResultNone;
	}

	if (forwards) EXECUTE_FORWARD_PRE_ARGS(FWD_TeamLevel, ReGG_ResultNone, slot, value);
	new ReGG_Result:result = ReGG_ResultNone;
	new oldValue = Teams[slot][TeamLevel];
	if (add) {
		Teams[slot][TeamLevel] += value;
	} else {
		Teams[slot][TeamLevel] = value;
	}
	
	if (Teams[slot][TeamLevel] >= LevelsNum) {
		Teams[slot][TeamLevel] = LevelsNum - 1;
		result = ReGG_ResultFinish;
	}

	if (Teams[slot][TeamLevel] < 0) {
		Teams[slot][TeamLevel] = 0;
	}

	if (result == ReGG_ResultNone) {
		result = Teams[slot][TeamLevel] > oldValue ? ReGG_ResultLevelUp : ReGG_ResultLevelDown;
	}

	Teams[slot][TeamPoints] = 0;

	new newValue = Teams[slot][TeamLevel];
	for (new player = 1, playerSlot; player <= MaxClients; player++) {
		if (!is_user_connected(player) || is_user_hltv(player)) {
			continue;
		}

		playerSlot = getTeamSlot(player);
		if (playerSlot != slot) {
			continue;
		}

		Players[player][PlayerPoints] = 0;
		Players[player][PlayerLevel] = Teams[slot][TeamLevel];
		EXECUTE_FORWARD_POST_ARGS(FWD_PlayerLevel, player, value);

		if (oldValue != Teams[slot][TeamLevel]) {
			if (Levels[newValue][LevelWeaponID] != WEAPON_KNIFE) {
				removeWeapon(player, oldValue);
			} else {
				rg_remove_all_items(player, true);
				giveDefaultWeapons(player);
			}
			giveWeapon(player, Teams[slot][TeamLevel]);
		}
	}

	if (forwards) EXECUTE_FORWARD_POST_ARGS(FWD_TeamLevel, slot, value);
	return result;
}

getTeamSlot(const id) {
	switch (TeamName:get_member(id, m_iTeam)) {
		case TEAM_TERRORIST: {
			return ReGG_SlotT;
		}

		case TEAM_CT: {
			return ReGG_SlotCT;
		}
	}
	return ReGG_SlotInvalid;
}

getPlayerLevelPoints(const id) {
	new level = Players[id][PlayerLevel];
	return Levels[level][LevelPoints];
}

getTeamLevelPoints(const slot) {
	new level = Teams[slot][TeamLevel];
	new points = getTeamPlayers(slot) * Levels[level][LevelPoints];
	return Levels[level][LevelMod] != 100 ? Levels[level][LevelMod] * points / 100 : points;
}

getTeamPlayers(const slot) {
	rg_initialize_player_counts();
	return slot == ReGG_SlotT
		? get_member_game(m_iNumTerrorist)
		: get_member_game(m_iNumCT);
}
