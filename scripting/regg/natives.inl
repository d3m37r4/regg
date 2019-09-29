#if defined _regg_natives_included
	#endinput
#endif

#define _regg_natives_included

#define CHECK_NATIVE_ARGS_NUM(%1,%2,%3) \
	if (%1 < %2) { \
		log_error(AMX_ERR_NATIVE, "Invalid num of arguments %d. Expected %d", %1, %2); \
		return %3; \
	}

#define CHECK_NATIVE_PLAYER(%1,%2) \
	if (!is_user_connected(%1)) { \
		log_error(AMX_ERR_NATIVE, "Invalid player %d", %1); \
		return %2; \
	}

#define CHECK_NATIVE_SLOT(%1,%2) \
	if (%1 != ReGG_SlotT && %1 != ReGG_SlotCT) { \
		log_error(AMX_ERR_NATIVE, "Invalid slot %d", %1); \
		return %2; \
	}

#define CHECK_NATIVE_LEVEL(%1,%2) \
	if (%1 < 0 || %1 >= sizeof Levels) { \
		log_error(AMX_ERR_NATIVE, "Level out of range %d", %1); \
		return %2; \
	}

#define CHECK_NATIVE_MODE(%1) \
	if (Mode == ReGG_ModeNone) { \
		log_error(AMX_ERR_NATIVE, "Game not started"); \
		return %1; \
	}

registerNatives() {
	register_native("ReGG_Start", "NativeStart", 0);
	register_native("ReGG_Finish", "NativeFinish", 0);
	register_native("ReGG_GetMode", "NativeGetMode", 0);
	register_native("ReGG_GetPlayerSlot", "NativeGetPlayerSlot", 0);
	register_native("ReGG_GetPoints", "NativeGetPoints", 0);
	register_native("ReGG_SetPoints", "NativeSetPoints", 0);
	register_native("ReGG_GetTeamPoints", "NativeGetTeamPoints", 0);
	register_native("ReGG_SetTeamPoints", "NativeSetTeamPoints", 0);
	register_native("ReGG_GetLevel", "NativeGetLevel", 0);
	register_native("ReGG_SetLevel", "NativeSetLevel", 0);
	register_native("ReGG_GetTeamLevel", "NativeGetTeamLevel", 0);
	register_native("ReGG_SetTeamLevel", "NativeSetTeamLevel", 0);
	register_native("ReGG_GetLevelPoints", "NativeGetLevelPoints", 0);
	register_native("ReGG_GetLevelTitle", "NativeGetLevelTitle", 0);
	register_native("ReGG_GetLevelWeapon", "NativeGetLevelWeapon", 0);
	register_native("ReGG_GetPlayerLevelPoints", "NativeGetPlayerLevelPoints", 0);
	register_native("ReGG_GetTeamLevelPoints", "NativeGetTeamLevelPoints", 0);
}

public bool:NativeStart(const plugin, const argc) {
	enum { arg_mode = 1 };
	CHECK_NATIVE_ARGS_NUM(argc, arg_mode, false)
	new ReGG_Mode:mode = ReGG_Mode:get_param(arg_mode);
	if (mode <= ReGG_ModeNone || mode > ReGG_ModeFFA) {
		return false;
	}
	return start(mode);
}

public bool:NativeFinish(const plugin, const argc) {
	return finish();
}

public ReGG_Mode:NativeGetMode(const plugin, const argc) {
	return Mode;
}

public NativeGetPlayerSlot(const plugin, const argc) {
	enum { arg_player = 1 };
	CHECK_NATIVE_ARGS_NUM(argc, arg_player, ReGG_SlotInvalid)
	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, ReGG_SlotInvalid)

	return getTeamSlot(player);
}

public NativeGetPoints(const plugin, const argc) {
	enum { arg_player = 1 };

	CHECK_NATIVE_MODE(-1)
	CHECK_NATIVE_ARGS_NUM(argc, arg_player, -1)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, -1)

	if (Mode != ReGG_ModeTeam) {
		return Players[player][PlayerPoints];
	}

	new slot = getTeamSlot(player);
	CHECK_NATIVE_SLOT(slot, -1)

	return Teams[slot][TeamPoints];
}

public ReGG_Result:NativeSetPoints(const plugin, const argc) {
	enum { arg_player = 1, arg_points, arg_forwards };

	CHECK_NATIVE_MODE(ReGG_ResultNone)
	CHECK_NATIVE_ARGS_NUM(argc, arg_points, ReGG_ResultNone)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, ReGG_ResultNone)

	new bool:forwards = false;
	if (argc >= arg_forwards) { // HACK. Cant compile with ternary operator
		forwards = bool:get_param(arg_forwards);
	}

	if (Mode != ReGG_ModeTeam) {
		return setPlayerPoints(player, get_param(arg_points), forwards);
	}

	new slot = getTeamSlot(player);
	CHECK_NATIVE_SLOT(slot, ReGG_ResultNone)
	return setTeamPoints(slot, get_param(arg_points), forwards);
}

public NativeGetTeamPoints(const plugin, const argc) {
	enum { arg_slot = 1 };

	CHECK_NATIVE_MODE(-1)

	if (Mode != ReGG_ModeTeam) {
		log_error(AMX_ERR_NATIVE, "Available only in team mode");
		return -1;
	}

	CHECK_NATIVE_ARGS_NUM(argc, arg_slot, -1)
	new slot = get_param(arg_slot);
	CHECK_NATIVE_SLOT(slot, -1)

	return Teams[slot][TeamPoints];
}

public ReGG_Result:NativeSetTeamPoints(const plugin, const argc) {
	enum { arg_slot = 1, arg_points, arg_forwards };

	CHECK_NATIVE_MODE(ReGG_ResultNone)

	if (Mode != ReGG_ModeTeam) {
		log_error(AMX_ERR_NATIVE, "Available only in team mode");
		return ReGG_ResultNone;
	}
	CHECK_NATIVE_ARGS_NUM(argc, arg_points, ReGG_ResultNone)
	new slot = get_param(arg_slot);
	CHECK_NATIVE_SLOT(slot, ReGG_ResultNone)

	new bool:forwards = false;
	if (argc >= arg_forwards) { // HACK. Cant compile with ternary operator
		forwards = bool:get_param(arg_forwards);
	}
	return setTeamPoints(slot, get_param(arg_points), forwards);
}

public NativeGetLevel(const plugin, const argc) {
	enum { arg_player = 1 };

	CHECK_NATIVE_MODE(-1)
	CHECK_NATIVE_ARGS_NUM(argc, arg_player, -1)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, -1)

	if (Mode != ReGG_ModeTeam) {
		return Players[player][PlayerLevel];
	}

	new slot = getTeamSlot(player);
	CHECK_NATIVE_SLOT(slot, -1)

	return Teams[slot][TeamLevel];
}

public ReGG_Result:NativeSetLevel(const plugin, const argc) {
	enum { arg_player = 1, arg_level, arg_forwards };

	CHECK_NATIVE_MODE(ReGG_ResultNone)
	CHECK_NATIVE_ARGS_NUM(argc, arg_level, ReGG_ResultNone)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, ReGG_ResultNone)

	new bool:forwards = false;
	if (argc >= arg_forwards) { // HACK. Cant compile with ternary operator
		forwards = bool:get_param(arg_forwards);
	}

	if (Mode != ReGG_ModeTeam) {
		return setPlayerLevel(player, get_param(arg_level), forwards);
	}

	new slot = getTeamSlot(player);
	CHECK_NATIVE_SLOT(slot, ReGG_ResultNone)
	return setTeamLevel(slot, get_param(arg_level), forwards);
}

public NativeGetTeamLevel(const plugin, const argc) {
	enum { arg_slot = 1 };

	CHECK_NATIVE_MODE(-1)

	if (Mode != ReGG_ModeTeam) {
		log_error(AMX_ERR_NATIVE, "Available only in team mode");
		return -1;
	}

	CHECK_NATIVE_ARGS_NUM(argc, arg_slot, -1)
	new slot = get_param(arg_slot);
	CHECK_NATIVE_SLOT(slot, -1)

	return Teams[slot][TeamLevel];
}

public ReGG_Result:NativeSetTeamLevel(const plugin, const argc) {
	enum { arg_slot = 1, arg_level, arg_forwards };

	CHECK_NATIVE_MODE(ReGG_ResultNone)

	if (Mode != ReGG_ModeTeam) {
		log_error(AMX_ERR_NATIVE, "Available only in team mode");
		return ReGG_ResultNone;
	}
	CHECK_NATIVE_ARGS_NUM(argc, arg_level, ReGG_ResultNone)
	new slot = get_param(arg_slot);
	CHECK_NATIVE_SLOT(slot, ReGG_ResultNone)

	new bool:forwards = false;
	if (argc >= arg_forwards) { // HACK. Cant compile with ternary operator
		forwards = bool:get_param(arg_forwards);
	}
	return setTeamLevel(slot, get_param(arg_level), forwards);
}

public NativeGetLevelPoints(const plugin, const argc) {
	enum { arg_level = 1 };

	CHECK_NATIVE_ARGS_NUM(argc, arg_level, 0)
	new level = get_param(arg_level);
	CHECK_NATIVE_LEVEL(level, 0)

	return Levels[level][LevelPoints];
}

public NativeGetLevelTitle(const plugin, const argc) {
	enum { arg_level = 1, arg_buffer, arg_length };

	CHECK_NATIVE_ARGS_NUM(argc, arg_length, 0)
	new level = get_param(arg_level);
	CHECK_NATIVE_LEVEL(level, 0)

	return set_string(arg_buffer, Levels[level][LevelTitle], get_param(arg_length));
}

public WeaponIdType:NativeGetLevelWeapon(const plugin, const argc) {
	enum { arg_level = 1 };

	CHECK_NATIVE_ARGS_NUM(argc, arg_level, WEAPON_NONE)
	new level = get_param(arg_level);
	CHECK_NATIVE_LEVEL(level, WEAPON_NONE)

	return Levels[level][LevelWeaponID];
}

public NativeGetPlayerLevelPoints(const plugin, const argc) {
	enum { arg_player = 1 };

	CHECK_NATIVE_MODE(-1)
	CHECK_NATIVE_ARGS_NUM(argc, arg_player, -1)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, -1)

	if (Mode != ReGG_ModeTeam) {
		return getPlayerLevelPoints(player);
	}

	new slot = getTeamSlot(player);
	CHECK_NATIVE_SLOT(slot, -1)
	return getTeamLevelPoints(slot);
}

public NativeGetTeamLevelPoints(const plugin, const argc) {
	enum { arg_slot = 1 };

	CHECK_NATIVE_MODE(-1)

	if (Mode != ReGG_ModeTeam) {
		log_error(AMX_ERR_NATIVE, "Available only in team mode");
		return -1;
	}

	CHECK_NATIVE_ARGS_NUM(argc, arg_slot, -1)
	new slot = get_param(arg_slot);
	CHECK_NATIVE_SLOT(slot, -1)

	return getTeamLevelPoints(slot);
}
