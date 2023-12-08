#if defined _regg_functions_included
	#endinput
#endif

#define _regg_functions_included

#define GET_PLAYER_SLOT(%1,%2,%3) if ((%2 = getTeamSlot(%1)) == ReGG_SlotInvalid) return %3

bool:start(const ReGG_Mode:mode) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_Start, false, mode);
	changeGameCvars();

	EnableHookChain(Hooks[HookDropClient]);
	EnableHookChain(Hooks[HookRestartRound]);
	EnableHookChain(Hooks[HookHasRestrictItem]);
	EnableHookChain(Hooks[HookDropPlayerItem]);
	EnableHookChain(Hooks[HookOnSpawnEquip]);
	EnableHookChain(Hooks[HookExplodeHeGrenade]);
	EnableHookChain(Hooks[HookKilled]);

	EXECUTE_FORWARD_POST_ARGS(FWD_Start, mode);

	Mode = mode;
	set_member_game(m_bCompleteReset, true);
	set_member_game(m_bGameStarted, true);

	rg_round_end(
		.tmDelay = 3.0, 
		.st = WINSTATUS_DRAW, 
		.event = ROUND_END_DRAW, 
		.message = "GunGame Mod started!",
		.sentence = "",
		.trigger = true
	);
	DebugMode && log_amx("GunGame Mod started!");

	return true;
}

bool:finish(const killer, const victim) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_Finish, false, killer, victim);
	restoreGameCvars();
	disableHooks();
	resetPlayersStats();
	resetTeamsStats();

	EXECUTE_FORWARD_POST_ARGS(FWD_Finish, killer, victim);

	Mode = ReGG_ModeNone;
	set_member_game(m_bCompleteReset, true);

	rg_round_end(
		.tmDelay = 3.0, 
		.st = WINSTATUS_DRAW, 
		.event = ROUND_END_DRAW, 
		.message = "Game over!",
		.sentence = "",
		.trigger = true
	);
	DebugMode && log_amx("GunGame Mod finished!");

	return true;
}

bool:playerJoin(const id) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_PlayerJoin, false, id);
	if(Mode == ReGG_ModeTeam) {
		new slot;
		GET_PLAYER_SLOT(id, slot, false);
		Players[id][PlayerPoints] = Teams[slot][TeamPoints];
		Players[id][PlayerLevel] = Teams[slot][TeamLevel];
		return true;
	}

	Players[id][PlayerPoints] = 0;

	new min, max;
	for(new player = 1, slot; player <= MaxClients; player++) {
		if(!is_user_connected(player) || is_user_hltv(player)) {
			continue;
		}

		slot = getTeamSlot(player);
		if(slot == ReGG_SlotInvalid) {
			continue;
		}

		if(Players[player][PlayerLevel] < min) {
			min = Players[player][PlayerLevel];
		}

		if(Players[player][PlayerLevel] > max) {
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

	new level;
	if(Mode == ReGG_ModeTeam) {
		new slot = getTeamSlot(killer);
		level = Teams[slot][TeamLevel];
	} else {
		level = Players[killer][PlayerLevel];
	}
	new ReGG_Result:result = ReGG_ResultNone;
	if(Levels[level][LevelWeaponID] != WEAPON_HEGRENADE) {
		result = addPoints(killer, 1);
	}
	if(Config[CfgRefillOnKill]) {
		rg_instant_reload_weapons(killer, weapon);
	}
	EXECUTE_FORWARD_POST_ARGS(FWD_KillEnemy, killer, victim, wid, result, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);
	return result;
}

ReGG_Result:killGrenade(const killer, const victim) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_KillEnemy, ReGG_ResultNone, killer, victim, WEAPON_HEGRENADE, ReGG_ResultNone, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);

	new level;
	if(Mode == ReGG_ModeTeam) {
		new slot = getTeamSlot(killer);
		level = Teams[slot][TeamLevel];
	} else {
		level = Players[killer][PlayerLevel];
	}

	if(Levels[level][LevelWeaponID] != WEAPON_HEGRENADE) {
		EXECUTE_FORWARD_POST_ARGS(FWD_KillEnemy, killer, victim, WEAPON_HEGRENADE, ReGG_ResultNone, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);
		return ReGG_ResultNone;
	}

	new ReGG_Result:result = addPoints(killer, 1);
	if(Config[CfgRefillOnKill] && result == ReGG_ResultPointsUp) {
		rg_give_item(killer, "weapon_hegrenade", GT_REPLACE);
	}
	EXECUTE_FORWARD_POST_ARGS(FWD_KillEnemy, killer, victim, WEAPON_HEGRENADE, result, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);
	return result;
}

ReGG_Result:killKnife(const killer, const victim) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_KillEnemy, ReGG_ResultNone, killer, victim, WEAPON_KNIFE, ReGG_ResultNone, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);

	toggleShouldSwitchWeapon(true);
	new ReGG_Result:result = steal(killer, victim);
	toggleShouldSwitchWeapon(false);

	EXECUTE_FORWARD_POST_ARGS(FWD_KillEnemy, killer, victim, WEAPON_KNIFE, result, Players[killer][PlayerPoints], Players[killer][PlayerLevel]);
	if(result == ReGG_ResultFinish) {
		finish(killer, victim);
	}
	return result;
}

bool:giveWeapon(const id, const level) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_GiveWeapon, false, id, Levels[level][LevelWeaponID]);
	switch (Levels[level][LevelWeaponID]) {
		case WEAPON_KNIFE: {}
		case WEAPON_HEGRENADE: {
			rg_give_item(id, "weapon_hegrenade");
			for(new i = 0, weapon, wname[32]; i < GrenadeWeaponsNum; i++) {
				rg_get_weapon_info(GrenadeWeapons[i], WI_NAME, wname, charsmax(wname));
				weapon = rg_give_item(id, wname);
				if(!is_nullent(weapon)) {
					rg_set_user_bpammo(id, GrenadeWeapons[i], Config[CfgAmmoAmount]);
				}
			}
		}
		case WEAPON_AWP: {
			new weapon = rg_give_item(id, "weapon_awp");
			if(!is_nullent(weapon)) {
				rg_set_user_bpammo(id, WEAPON_AWP, Config[CfgAmmoAmount]);

				if(Config[CfgAWPOneShot]) {
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
			if(!is_nullent(weapon)) {
				rg_set_user_bpammo(id, wid, Config[CfgAmmoAmount]);
			}
		}
	}
	EXECUTE_FORWARD_POST_ARGS(FWD_GiveWeapon, id, Levels[level][LevelWeaponID]);
	return true;
}

removeWeapon(const id, const level) {
	if(level < 0 || level >= LevelsNum) {
		return;
	}
	new WeaponIdType:wid = Levels[level][LevelWeaponID];
	new wname[32];
	if(wid == WEAPON_HEGRENADE) {
		for(new i = 0; i < GrenadeWeaponsNum; i++) {
			rg_get_weapon_info(GrenadeWeapons[i], WI_NAME, wname, charsmax(wname));
			rg_remove_item(id, wname, true);
		}
		rg_get_weapon_info(wid, WI_NAME, wname, charsmax(wname));
		rg_remove_item(id, wname, true);
	}
	else if(wid != WEAPON_KNIFE) {
		rg_get_weapon_info(wid, WI_NAME, wname, charsmax(wname));
		rg_remove_item(id, wname, true);
	}
}

bool:suicide(const id) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_Suicide, false, id);

	if(Mode == ReGG_ModeTeam) {
		return false;
	}

	subPlayerLevel(id, 1);
	setPlayerPoints(id, 0);
	EXECUTE_FORWARD_POST_ARGS(FWD_Suicide, id);
	return true;
}

ReGG_Result:steal(const killer, const victim) {
	if(Mode == ReGG_ModeTeam) {
		return stealPoints(killer, victim, Config[CfgTeamStealValue]);
	} else {
		switch(Config[CfgStealMode]) {
			case 1: {
				return stealLevels(killer, victim, Config[CfgStealValue]);
			}
			case 2: {
				return stealPoints(killer, victim, Config[CfgStealValue]);
			}
		}
    }
	return addPoints(killer, 1);
}

ReGG_Result:stealPoints(const killer, const victim, const value) {
	EXECUTE_FORWARD_PRE_ARGS(FWD_StealPoints, ReGG_ResultNone, killer, victim, value);

	new ReGG_Result:result;
	new level;
	if(Mode == ReGG_ModeTeam) {
		new slot = getTeamSlot(killer);
		level = Teams[slot][TeamLevel];
	} else {
		level = Players[killer][PlayerLevel];
	}

	switch(Levels[level][LevelWeaponID]) {
		case WEAPON_KNIFE: {
			result = addPoints(killer, 1);
		}

		case WEAPON_HEGRENADE: {
			result = ReGG_ResultNone;
		}

		default: {
			result = addPoints(killer, value);
		}
	}
	subPoints(victim, value);
	EXECUTE_FORWARD_POST_ARGS(FWD_StealPoints, killer, victim, value);
	return result;
}

ReGG_Result:stealLevels(const killer, const victim, const value, const bool:forwards = true) {
	if(forwards) EXECUTE_FORWARD_PRE_ARGS(FWD_StealLevels, ReGG_ResultNone, killer, victim, value);

	new ReGG_Result:result;
	new level = Players[killer][PlayerLevel];
	switch(Levels[level][LevelWeaponID]) {
		case WEAPON_KNIFE: {
			result = addPoints(killer, 1);
		}

		case WEAPON_HEGRENADE: {
			result = ReGG_ResultNone;
		}

		default: {
			result = addLevel(killer, value);
			if (result != ReGG_ResultNone) {
				setPoints(killer, 0);
			}
		}
	}

	subLevel(victim, value);
	setPoints(victim, 0);
	if(forwards) EXECUTE_FORWARD_POST_ARGS(FWD_StealLevels, killer, victim, value);
	return result;
}

ReGG_Result:addPoints(const id, const value, const bool:forwards = true) {
	if(value <= 0) {
		return ReGG_ResultNone;
	}

	if(Mode != ReGG_ModeTeam) {
		return addPlayerPoints(id, value, forwards);
	}

	new slot;
	GET_PLAYER_SLOT(id, slot, ReGG_ResultNone);
	return addTeamPoints(slot ,value, forwards);
}

ReGG_Result:addPlayerPoints(const id, const value, const bool:forwards = true) {
	new points = Players[id][PlayerPoints] + value;
	new level = Players[id][PlayerLevel];
	new needPoints = Levels[level][LevelPoints];
	new ReGG_Result:result = ReGG_ResultPointsUp;

	while(points >= needPoints) {
		level++;
		if(level >= LevelsNum) {
			level = LevelsNum - 1;
			points = 0;
			result = ReGG_ResultFinish;
			break;
		}

		points -= needPoints;
		needPoints = Levels[level][LevelPoints];
		result = ReGG_ResultLevelUp;
	}

	if(result != ReGG_ResultPointsUp && !setPlayerLevel(id, level, forwards)) {
		return ReGG_ResultNone;
	}

	if(!setPlayerPoints(id, points, forwards)) {
		return ReGG_ResultNone;
	}
	return result;
}

ReGG_Result:addTeamPoints(const slot, const value, const bool:forwards = true) {
	new points = Teams[slot][TeamPoints] + value;
	new level = Teams[slot][TeamLevel];
	new needPoints = getTeamLevelPoints(slot, level);
	new ReGG_Result:result = ReGG_ResultPointsUp;

	while(points >= needPoints) {
		level++;
		if(level >= LevelsNum) {
			level = LevelsNum - 1;
			points = 0;
			result = ReGG_ResultFinish;
			break;
		}

		points -= needPoints;
		needPoints = getTeamLevelPoints(slot, level);
		result = ReGG_ResultLevelUp;
	}

	if(result != ReGG_ResultPointsUp && !setTeamLevel(slot, level, forwards)) {
		return ReGG_ResultNone;
	}

	if(!setTeamPoints(slot, points, forwards)) {
		return ReGG_ResultNone;
	}
	return result;
}

ReGG_Result:subPoints(const id, const value, const bool:forwards = true) {
	if(value <= 0) {
		return ReGG_ResultNone;
	}

	if(Mode != ReGG_ModeTeam) {
		return subPlayerPoints(id, value, forwards);
	}

	new slot;
	GET_PLAYER_SLOT(id, slot, ReGG_ResultNone);
	return subTeamPoints(slot, value, forwards);
}

ReGG_Result:subPlayerPoints(const id, const value, const bool:forwards = true) {
	new points = Players[id][PlayerPoints] - value;
	new level = Players[id][PlayerLevel];
	new needPoints =  Levels[level][LevelPoints];
	new ReGG_Result:result = ReGG_ResultPointsDown;

	while(points < 0) {
		level--;
		if(level < 0) {
			level = 0;
			points = 0;
			break;
		}

		points += needPoints;
		needPoints =  Levels[level][LevelPoints];
		result = ReGG_ResultLevelDown;
	}

	if(result != ReGG_ResultPointsDown && !setPlayerLevel(id, level, forwards)) {
		return ReGG_ResultNone;
	}
	if(!setPlayerPoints(id, points, forwards)) {
		return ReGG_ResultNone;
	}
	return result;
}

ReGG_Result:subTeamPoints(const slot, const value, const bool:forwards = true) {
	new points = Teams[slot][TeamPoints] - value;
	new level = Teams[slot][TeamLevel];
	new needPoints = getTeamLevelPoints(slot, level);
	new ReGG_Result:result = ReGG_ResultPointsDown;

	while(points < 0) {
		level--;
		if(level < 0) {
			level = 0;
			points = 0;
			break;
		}

		points += needPoints;
		needPoints = getTeamLevelPoints(slot, level);
		result = ReGG_ResultLevelDown;
	}

	if(result != ReGG_ResultPointsDown && !setTeamLevel(slot, level, forwards)) {
		return ReGG_ResultNone;
	}
	if(!setTeamPoints(slot, points, forwards)) {
		return ReGG_ResultNone;
	}
	return result;
}

bool:setPoints(const id, const value, const bool:forwards = true) {
	if(Mode != ReGG_ModeTeam) {
		return setPlayerPoints(id, value, forwards);
	}

	new slot;
	GET_PLAYER_SLOT(id, slot, false);
	return setTeamPoints(slot, value, forwards);
}

bool:setPlayerPoints(const id, const value, const bool:forwards = true) {
	if(forwards) EXECUTE_FORWARD_PRE_ARGS(FWD_PlayerPoints, false, id, value);
	Players[id][PlayerPoints] = value;
	if(forwards) EXECUTE_FORWARD_POST_ARGS(FWD_PlayerPoints, id, value);
	return true;
}

bool:setTeamPoints(const slot, const value, const bool:forwards = true) {
	if(forwards) EXECUTE_FORWARD_PRE_ARGS(FWD_TeamPoints, false, slot, value);
	Teams[slot][TeamPoints] = value;
	for(new player = 1, playerSlot; player <= MaxClients; player++) {
		if(!is_user_connected(player) || is_user_hltv(player)) {
			continue;
		}

		playerSlot = getTeamSlot(player);
		if(playerSlot == slot) {
			setPlayerPoints(player, value, forwards);
		}
	}
	if(forwards) EXECUTE_FORWARD_POST_ARGS(FWD_TeamPoints, slot, value);
	return true;
}

ReGG_Result:addLevel(const id, const value, const bool:forwards = true) {
	if(value <= 0) {
		return ReGG_ResultNone;
	}

	if(Mode != ReGG_ModeTeam) {
		return addPlayerLevel(id, value, forwards);
	}

	new slot;
	GET_PLAYER_SLOT(id, slot, ReGG_ResultNone);
	return addTeamLevel(slot, value, forwards);
}

ReGG_Result:addPlayerLevel(const id, const value, const bool:forwards = true) {
	new level = Players[id][PlayerLevel] + value;
	new ReGG_Result:result = ReGG_ResultLevelUp;
	if(level >= LevelsNum) {
		level = LevelsNum - 1;
		result = ReGG_ResultFinish;
	}
	if(!setPlayerLevel(id, level, forwards)) {
		return ReGG_ResultNone;
	}
	return result;
}

ReGG_Result:addTeamLevel(const slot, const value, const bool:forwards = true) {
	new level = Teams[slot][TeamLevel] + value;
	new ReGG_Result:result = ReGG_ResultLevelUp;
	if(level >= LevelsNum) {
		level = LevelsNum - 1;
		result = ReGG_ResultFinish;
	}
	if(!setTeamLevel(slot, level, forwards)) {
		return ReGG_ResultNone;
	}
	return result;
}

ReGG_Result:subLevel(const id, const value, const bool:forwards = true) {
	if(value <= 0) {
		return ReGG_ResultNone;
	}

	if(Mode != ReGG_ModeTeam) {
		return subPlayerLevel(id, value, forwards);
	}

	new slot;
	GET_PLAYER_SLOT(id, slot, ReGG_ResultNone);
	return subTeamLevel(slot ,value, forwards);
}

ReGG_Result:subPlayerLevel(const id, const value, const bool:forwards = true) {
	new level = Players[id][PlayerLevel] - value;
	if(level < 0) {
		level = 0;
	}
	return setPlayerLevel(id, level, forwards) ? ReGG_ResultLevelDown : ReGG_ResultNone;
}

ReGG_Result:subTeamLevel(const slot, const value, const bool:forwards = true) {
	new level = Teams[slot][TeamLevel] - value;
	if(level < 0) {
		level = 0;
	}
	return setTeamLevel(slot, level, forwards) ? ReGG_ResultLevelDown : ReGG_ResultNone;
}

bool:setLevel(const id, const value, const bool:forwards = true) {
	if(Mode != ReGG_ModeTeam) {
		return setPlayerLevel(id, value, forwards);
	}

	new slot;
	GET_PLAYER_SLOT(id, slot, false);
	return setTeamLevel(slot ,value, forwards);
}

bool:setPlayerLevel(const id, const value, const bool:forwards = true) {
	if(forwards) EXECUTE_FORWARD_PRE_ARGS(FWD_PlayerLevel, false, id, value);
	new oldValue = Players[id][PlayerLevel];
	Players[id][PlayerLevel] = value;
	if(oldValue != Players[id][PlayerLevel]) {
		Levels[value][LevelWeaponID] != WEAPON_KNIFE ? removeWeapon(id, oldValue) : rg_give_default_items(id);
		giveWeapon(id, Players[id][PlayerLevel]);
	}

	if(forwards) EXECUTE_FORWARD_POST_ARGS(FWD_PlayerLevel, id, value);
	return true;
}

bool:setTeamLevel(const slot, const value, const bool:forwards = true) {
	if(forwards) EXECUTE_FORWARD_PRE_ARGS(FWD_TeamLevel, false, slot, value);
	new oldValue = Teams[slot][TeamLevel];
	Teams[slot][TeamLevel] = value;
	for(new player = 1, playerSlot; player <= MaxClients; player++) {
		if (!is_user_connected(player) || is_user_hltv(player)) {
			continue;
		}

		playerSlot = getTeamSlot(player);
		if(playerSlot == slot) {
			if(oldValue != Teams[slot][TeamLevel]) {
				Levels[value][LevelWeaponID] != WEAPON_KNIFE ? removeWeapon(player, oldValue) : rg_give_default_items(player);
				giveWeapon(player, Teams[slot][TeamLevel]);
			}
		}
	}

	if(forwards) EXECUTE_FORWARD_POST_ARGS(FWD_TeamLevel, slot, value);
	return true;
}

getTeamSlot(const id) {
	switch(TeamName:get_member(id, m_iTeam)) {
		case TEAM_TERRORIST: {
			return ReGG_SlotT;
		}
		case TEAM_CT: {
			return ReGG_SlotCT;
		}
	}
	return ReGG_SlotInvalid;
}

getTeamLevelPoints(const slot, const level) {
	new points;
	new point_s = getTeamPlayers(slot) * Levels[level][LevelPoints];
	new lvlmod = Levels[level][LevelMod];
	if(lvlmod != 100) {
		points = roundPoints(lvlmod, point_s);
	} else {
		points = point_s;
	}

	return points;
}

roundPoints(num1, num2) {
	new Float:fNum1 = float(num1);
	new Float:fNum2 = float(num2);
	new Float:value = fNum1 * fNum2 / 100.0;
	new num = floatround(value, floatround_ceil);

	return num;
}

getTeamPlayers(const slot) {
	return slot == ReGG_SlotT
		? get_member_game(m_iNumTerrorist)
		: get_member_game(m_iNumCT);
}

resetPlayersStats() {
	for(new player = 1; player <= MaxClients; player++) {
		Players[player][PlayerPoints] = 0;
		Players[player][PlayerLevel] = 0;
	}
}

resetTeamsStats() {
	for(new slot = ReGG_SlotT; slot <= ReGG_SlotCT; slot++) {
		Teams[slot][TeamPoints] = 0;
		Teams[slot][TeamLevel] = 0;
	}
}
