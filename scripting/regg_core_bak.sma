#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#define rg_get_user_team(%1) TeamName:get_member(%1, m_iTeam)

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

#define CHECK_NATIVE_LEVEL(%1,%2) \
	if (%1 < 0 || %1 >= sizeof Levels) { \
		log_error(AMX_ERR_NATIVE, "Level out of range %d", %1); \
		return %2; \
	}

const TASK_GRENADE_ID = 50;

enum Forward {
	FWD_Starting,
	FWD_Started,
	FWD_Finishing,
	FWD_Finished,
	FWD_SettingPointsSingle,
	FWD_SettedPointsSingle,
	FWD_SettingPointsTeam,
	FWD_SettedPointsTeam,
	FWD_SettingLevelSingle,
	FWD_SettedLevelSingle,
	FWD_SettingLevelTeam,
	FWD_SettedLevelTeam,
};

enum _:Hook {
	HookChain:HookHasRestrictItem,
	HookChain:HookDropPlayerItem,
	HookChain:HookDeadPlayerWeapons,
	HookChain:HookDeadGiveC4,
	HamHook:HookPlayerEquip,
	HamHook:HookWeaponStrip,
	HookChain:HookFShouldSwitchWeapon,
	HookChain:HookOnSpawnEquip,
	HookChain:HookThrowHeGrenade,
	HookChain:HookKilled,
};

enum {
	ModeSingle,
	ModeTeam
};

enum (+=1) {
	TeamSlotInvalid = -1,
	TeamSlotT,
	TeamSlotCT,
}

enum _:Level {
	WeaponIdType:LevelWeaponID,
	LevelPoints,
};

enum _:Player {
	PlayerPoints,
};

enum _:Team {
	TeamPoints,
	TeamLevel,
};

new Hooks[Hook];
new Forwards[Forward], FReturn;
new Mode;

new Levels[][Level] = {
	{ WEAPON_P228, 1 },
	{ WEAPON_SCOUT, 1 },
	// { WEAPON_XM1014, 5 },
	// { WEAPON_MAC10, 5 },
	// { WEAPON_AUG, 5 },
	// { WEAPON_ELITE, 5 },
	// { WEAPON_FIVESEVEN, 5 },
	// { WEAPON_UMP45, 5 },
	// { WEAPON_SG550, 5 },
	// { WEAPON_GALIL, 5 },
	{ WEAPON_FAMAS, 1 },
	{ WEAPON_USP, 1 },
	// { WEAPON_GLOCK18, 5 },
	{ WEAPON_AWP, 1 },
	// { WEAPON_MP5N, 5 },
	// { WEAPON_M249, 5 },
	// { WEAPON_M5, 5 },
	{ WEAPON_M4A1, 1 },
	// { WEAPON_TMP, 5 },
	// { WEAPON_G5SG1, 5 },
	{ WEAPON_DEAGLE, 1 },
	// { WEAPON_SG552, 5 },
	{ WEAPON_AK47, 1 },
	// { WEAPON_P90, 5 },
	{ WEAPON_HEGRENADE, 2 },
	{ WEAPON_KNIFE, 1 }
};

new Players[MAX_PLAYERS + 1][Player];
new Teams[2][Team];
new PlayersLevel[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("[ReAPI] GunGame Core", "0.1.0-alpha", "F@nt0M");

	// RegisterHookChain(RH_SV_DropClient, "SV_DropClient_Post", true);
	Hooks[HookHasRestrictItem] = RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "CBasePlayer_HasRestrictItem_Pre", false);
	Hooks[HookDropPlayerItem] = RegisterHookChain(RG_CBasePlayer_DropPlayerItem, "CBasePlayer_DropPlayerItem_Pre", false);
	Hooks[HookDeadPlayerWeapons] = RegisterHookChain(RG_CSGameRules_DeadPlayerWeapons, "CSGameRules_DeadPlayerWeapons_Pre", false);
	Hooks[HookDeadGiveC4] = RegisterHookChain(RG_CSGameRules_GiveC4, "CSGameRules_GiveC4_Pre", false);
	Hooks[HookPlayerEquip] = RegisterHam(Ham_Use, "game_player_equip", "HamHookSupercede", false);
	Hooks[HookWeaponStrip] = RegisterHam(Ham_Use, "player_weaponstrip", "HamHookSupercede", false);

	Hooks[HookFShouldSwitchWeapon] = RegisterHookChain(RG_CSGameRules_FShouldSwitchWeapon, "CSGameRules_FShouldSwitchWeapon_Pre", false);

	Hooks[HookOnSpawnEquip] = RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "CBasePlayer_OnSpawnEquip_Pre", false);
	Hooks[HookThrowHeGrenade] = RegisterHookChain(RG_ThrowHeGrenade, "CBasePlayer_ThrowHeGrenade_Post", true);
	Hooks[HookKilled] = RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);

	DisableHookChain(Hooks[HookHasRestrictItem]);
	DisableHookChain(Hooks[HookDropPlayerItem]);
	DisableHookChain(Hooks[HookDeadPlayerWeapons]);
	DisableHookChain(Hooks[HookDeadGiveC4]);
	DisableHamForward(Hooks[HookPlayerEquip]);
	DisableHamForward(Hooks[HookWeaponStrip]);
	DisableHookChain(Hooks[HookFShouldSwitchWeapon]);
	DisableHookChain(Hooks[HookOnSpawnEquip]);
	DisableHookChain(Hooks[HookThrowHeGrenade]);
	DisableHookChain(Hooks[HookKilled]);

	registerForwards();
}

public plugin_cfg() {
	set_cvar_num("mp_round_infinite", 1);
	set_cvar_float("mp_forcerespawn", 1.0);
	set_cvar_num("mp_refill_bpammo_weapons", 3);
	set_cvar_num("mp_timelimit", 0);
	set_cvar_num("mp_maxrounds", 0);
	set_cvar_num("mp_fraglimit", 0);
}

public plugin_end() {
	destroyForwards();
}

public plugin_natives() {
	register_library("regg");
	registerNatives();
}

// public client_putinserver(id) {
// 	arrayset(Players[id], 0, sizeof(Players[]));
// }

// public SV_DropClient_Post(const id) {
// 	remove_task(TASK_GRENADE + id);
//	TODO: Recalculate points and level
// 	checkLeaders();
// }

public CBasePlayer_HasRestrictItem_Pre() {
	SetHookChainReturn(ATYPE_BOOL, true);
	return HC_SUPERCEDE;
}

public CBasePlayer_DropPlayerItem_Pre() {
	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

public CSGameRules_DeadPlayerWeapons_Pre() {
	SetHookChainReturn(ATYPE_INTEGER, GR_PLR_DROP_GUN_NO);
}

public CSGameRules_GiveC4_Pre() {
	return HC_SUPERCEDE;
}

public HamHookSupercede() {
	return HAM_SUPERCEDE;
}

public CSGameRules_FShouldSwitchWeapon_Pre() {
	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

public CBasePlayer_OnSpawnEquip_Pre(const id) {
	if (!is_user_alive(id)) {
		return HC_CONTINUE;
	}

	rg_give_item(id, "weapon_knife");

	giveWeapon(id, getLevel(id));
	return HC_SUPERCEDE;
}

public CBasePlayer_ThrowHeGrenade_Post(const id) {
	set_task(3.0, "TaskGiveGrenade", TASK_GRENADE_ID + id);
}

public CBasePlayer_Killed_Post(const victim, const killer) {
	if (victim == killer) {
		if (Mode == ModeSingle) {
			setLevelSingle(victim, -1);
		}
		return HC_CONTINUE;
	}

	if (!is_user_connected(killer) || !rg_is_player_can_takedamage(victim, killer)) {
		return HC_CONTINUE;
	}

	if (get_member(victim, m_bKilledByGrenade)) {
		killGrenade(killer);
	} else if (get_entvar(victim, var_dmg_inflictor) == killer){
		new weapon = get_member(killer, m_pActiveItem);
		if (get_member(weapon, m_iId) == WEAPON_KNIFE) {
			killKnife(victim, killer);
		} else {
			killWeapon(killer, weapon);
		}
	}

	remove_task(TASK_GRENADE_ID + victim);
	return HC_CONTINUE;
}

public TaskGiveGrenade(id) {
	id -= TASK_GRENADE_ID;
	if (!is_user_connected(id)) {
		return;
	}

	new level = getLevel(id);
	if (Levels[level][LevelWeaponID] == WEAPON_HEGRENADE) {
		rg_give_item(id, "weapon_hegrenade");
	}
}

getTeamSlot(const id) {
	switch (rg_get_user_team(id)) {
		case TEAM_TERRORIST: {
			return TeamSlotT;
		}

		case TEAM_CT: {
			return TeamSlotCT;
		}
	}
	return TeamSlotInvalid;
}

getTeamPlayers(const slot) {
	new num;
	for (new id = 1; id <= MaxClients; id++) {
		if (is_user_connected(id) && getTeamSlot(id) == slot) {
			num++;
		}
	}

	return num;
}

getLevel(const id) {
	if (Mode == ModeSingle) {
		return PlayersLevel[id];
	}

	new slot = getTeamSlot(id);
	return slot != TeamSlotInvalid ? Teams[slot][TeamLevel] : 0;
}

getPoints(const id) {
	if (Mode == ModeSingle) {
		return Players[id][PlayerPoints];
	}

	new slot = getTeamSlot(id);
	return slot != TeamSlotInvalid ? Teams[slot][TeamPoints] : 0;
}

getLevelPoints(const id, const level) {
	if (Mode == ModeSingle) {
		return Levels[level][LevelPoints];
	}

	new slot = getTeamSlot(id);
	return  slot != TeamSlotInvalid ? getTeamLevelPoitns(slot, level) : 0;
}

getTeamLevelPoitns(const slot, const level) {
	// gg_teamplay_knife_mod = register_cvar("gg_teamplay_knife_mod","0.33");
	// gg_teamplay_nade_mod = register_cvar("gg_teamplay_nade_mod","0.50");
	new num = getTeamPlayers(slot);
	if (Levels[level][LevelWeaponID] == WEAPON_KNIFE) {
		return floatround(float(num) * 0.33, floatround_ceil);
	}

	if (Levels[level][LevelWeaponID] == WEAPON_HEGRENADE) {
		return floatround(float(num) * 0.50, floatround_ceil);
	}

	return num * Levels[level][LevelPoints];
}

killWeapon(const killer, const weapon) {
	new level = getLevel(killer);
	if (Levels[level][LevelWeaponID] == WEAPON_HEGRENADE) {
		return;
	}

	if (!setPoints(killer, level, 1)) {
		rg_instant_reload_weapons(killer, weapon);
		
	} else {
		// client_cmd("spk sound/gungame/gg_levelup.wav");
	}
}

killGrenade(const killer) {
	new level = getLevel(killer);
	if (Levels[level][LevelWeaponID] != WEAPON_HEGRENADE) {
		return;
	}

	if (!setPoints(killer, level, 1)) {
		remove_task(TASK_GRENADE_ID + killer);
		rg_give_item(killer, "weapon_hegrenade", GT_REPLACE);
	}
}

killKnife(const victim, const killer) {
	new level = getLevel(killer);

	if (Mode == ModeSingle) {
		if (Levels[level][LevelWeaponID] == WEAPON_KNIFE) {
			finish();
		} else {
			client_print_color(0, killer, "^3%n ^1украл уровень у ^4%n", killer, victim);
			EnableHookChain(Hooks[HookFShouldSwitchWeapon]);
			if (Levels[level][LevelWeaponID] != WEAPON_HEGRENADE) {
				setLevel(killer, 1);
			}
			setLevel(victim, -1);
			DisableHookChain(Hooks[HookFShouldSwitchWeapon]);
		}
	} else {
		if (Levels[level][LevelWeaponID] != WEAPON_KNIFE) {
			client_print_color(0, killer, "^3%n ^1украл 3 очка у ^4%n", killer, victim);
			if (Levels[level][LevelWeaponID] != WEAPON_HEGRENADE) {
				EnableHookChain(Hooks[HookFShouldSwitchWeapon]);
				setPoints(killer, level, 3);
				DisableHookChain(Hooks[HookFShouldSwitchWeapon]);
			}
		} else if (setPoints(killer, level, 1)) {
			finish();
		}

		level = getLevel(victim);
		setPoints(victim, level, Levels[level][LevelWeaponID] != WEAPON_KNIFE ? -3 : -1);
	}
}

bool:setPoints(const id, const level, const value) {
	if (Mode == ModeSingle) {
		return setPointsSingle(id, level, value);
	}

	new slot = getTeamSlot(id);
	if (slot == TeamSlotInvalid) {
		return false;
	}
	
	return setPointsTeam(id, slot, level ,value);
}

bool:setPointsSingle(const id, const level, const value) {
	ExecuteForward(Forwards[FWD_SettingPointsSingle], FReturn, id, value);
	if (FReturn == PLUGIN_HANDLED) {
		return false;
	}

	Players[id][PlayerPoints] += value;

	ExecuteForward(Forwards[FWD_SettedPointsSingle], FReturn, id, value);

	if (Players[id][PlayerPoints] >= Levels[level][LevelPoints]) {
		return setLevelSingle(id, 1);
	} else if (Players[id][PlayerPoints] < 0) {
		return setLevelSingle(id, -1);
	}
	return false;
}

bool:setPointsTeam(const id, const slot, const level, const value) {
	ExecuteForward(Forwards[FWD_SettingPointsTeam], FReturn, slot, value);
	if (FReturn == PLUGIN_HANDLED) {
		return false;
	}

	Players[id][PlayerPoints] += value;
	Teams[slot][TeamPoints] += value;

	ExecuteForward(Forwards[FWD_SettedPointsTeam], FReturn, slot, value);

	if (Teams[slot][TeamPoints] >= getTeamLevelPoitns(slot, level)) {
		return setLevelTeam(slot, 1);
	} else if (Teams[slot][TeamPoints] < 0) {
		return setLevelTeam(slot, -1);
	}

	return false;
}

bool:setLevel(const id, const value) {
	if (Mode == ModeSingle) {
		return setLevelSingle(id, value);
	} else {
		new slot = getTeamSlot(id);
		if (slot != TeamSlotInvalid) {
			return setLevelTeam(slot, value);
		}
	}

	return false;

	// checkLeaders();
}

bool:setLevelSingle(const id, const value) {
	ExecuteForward(Forwards[FWD_SettingLevelSingle], FReturn, id, value);
	if (FReturn == PLUGIN_HANDLED) {
		return false;
	}

	new oldLevel = PlayersLevel[id];
	PlayersLevel[id] = clamp(PlayersLevel[id] + value, 0, sizeof Levels - 1);
	Players[id][PlayerPoints] = 0;
	if (oldLevel == PlayersLevel[id]) {
		return false;
	}
	
	removeWeapon(id, oldLevel);
	giveWeapon(id, PlayersLevel[id]);

	client_print_color(id, print_team_default, "^3Вы ^4%s ^1на ^4%d ^1уровень", value > 0 ? "поднялись" : "опустились", PlayersLevel[id]);

	ExecuteForward(Forwards[FWD_SettedLevelSingle], FReturn, id, value);
	return true;
}

bool:setLevelTeam(const slot, const value) {
	ExecuteForward(Forwards[FWD_SettingLevelTeam], FReturn, slot, value);
	if (FReturn == PLUGIN_HANDLED) {
		return false;
	}

	new oldLevel = Teams[slot][TeamLevel];
	Teams[slot][TeamLevel] = clamp(Teams[slot][TeamLevel] + value, 0, sizeof Levels - 1);
	Teams[slot][TeamPoints] = 0;
	if (oldLevel == Teams[slot][TeamLevel]) {
		return false;
	}

	for (new player = 1; player <= MaxClients; player++) {
		if (!is_user_connected(player) || getTeamSlot(player) != slot) {
			continue;
		}

		Players[player][PlayerPoints] = 0;
		removeWeapon(player, oldLevel);
		giveWeapon(player, Teams[slot][TeamLevel]);
	}

	switch (slot) {
		case TeamSlotT: {
			client_print_color(0, print_team_red, "^1Команда ^3террористов ^4%s ^1на ^4%d ^1уровень", value > 0 ? "поднялась" : "опустилась", Teams[slot][TeamLevel]);
		}

		case TeamSlotCT: {
			client_print_color(0, print_team_blue, "^1Команда ^3контр-террористов ^4%s ^1на ^4%d ^1уровень", value > 0 ? "поднялась" : "опустилась", Teams[slot][TeamLevel]);
		}
	}
	ExecuteForward(Forwards[FWD_SettedLevelTeam], FReturn, slot, value);
	return true;
}

giveWeapon(const id, const level) {
	switch (Levels[level][LevelWeaponID]) {
		case WEAPON_KNIFE: {}

		case WEAPON_HEGRENADE: {
			rg_give_item(id, "weapon_hegrenade");
		}

		case WEAPON_AWP: {
			new weapon = rg_give_item(id, "weapon_awp");
			if (!is_nullent(weapon)) {
				rg_set_user_ammo(id, WEAPON_AWP, 1);
				rg_set_user_bpammo(id, WEAPON_AWP, 200);
				rg_set_iteminfo(weapon, ItemInfo_iMaxClip, 1);
			}
		}

		default: {
			new wname[32];
			new WeaponIdType:wid = Levels[level][LevelWeaponID];
			rg_get_weapon_info(wid, WI_NAME, wname, charsmax(wname));
			rg_give_item(id, wname);
			rg_set_user_bpammo(id, wid, 200);
		}
	}
	
}

removeWeapon(const id, const level) {
	new WeaponIdType:wid = Levels[level][LevelWeaponID];
	if (wid != WEAPON_KNIFE) {
		new wname[32];
		rg_get_weapon_info(wid, WI_NAME, wname, charsmax(wname));
		rg_remove_item(id, wname, true);
	}
}

// API

start(const mode) {
	ExecuteForward(Forwards[FWD_Starting], FReturn);
	if (FReturn == PLUGIN_HANDLED) {
		return;
	}

	EnableHookChain(Hooks[HookHasRestrictItem]);
	EnableHookChain(Hooks[HookDropPlayerItem]);
	EnableHookChain(Hooks[HookDeadPlayerWeapons]);
	EnableHookChain(Hooks[HookDeadGiveC4]);
	EnableHamForward(Hooks[HookPlayerEquip]);
	EnableHamForward(Hooks[HookWeaponStrip]);
	EnableHookChain(Hooks[HookOnSpawnEquip]);
	EnableHookChain(Hooks[HookThrowHeGrenade]);
	EnableHookChain(Hooks[HookKilled]);

	Mode = mode;

	ExecuteForward(Forwards[FWD_Started], FReturn);

	set_cvar_num("sv_restart", 1);
}

finish() {
	ExecuteForward(Forwards[FWD_Finishing], FReturn);
	if (FReturn == PLUGIN_HANDLED) {
		return;
	}

	DisableHookChain(Hooks[HookHasRestrictItem]);
	DisableHookChain(Hooks[HookDropPlayerItem]);
	DisableHookChain(Hooks[HookDeadPlayerWeapons]);
	DisableHookChain(Hooks[HookDeadGiveC4]);
	DisableHamForward(Hooks[HookPlayerEquip]);
	DisableHamForward(Hooks[HookWeaponStrip]);
	DisableHookChain(Hooks[HookOnSpawnEquip]);
	DisableHookChain(Hooks[HookThrowHeGrenade]);
	DisableHookChain(Hooks[HookKilled]);

	ExecuteForward(Forwards[FWD_Finished], FReturn);
}

registerForwards() {
	Forwards[FWD_Starting] = CreateMultiForward("ReGG_Starting", ET_STOP);
	Forwards[FWD_Started] = CreateMultiForward("ReGG_Started", ET_IGNORE);
	Forwards[FWD_Finishing] = CreateMultiForward("ReGG_Finishing", ET_STOP);
	Forwards[FWD_Finished] = CreateMultiForward("ReGG_Finished", ET_IGNORE);
	Forwards[FWD_SettingPointsSingle] = CreateMultiForward("ReGG_SettingPointsSingle", ET_STOP, FP_CELL, FP_CELL);
	Forwards[FWD_SettedPointsSingle] = CreateMultiForward("ReGG_SettedPointsSignel", ET_IGNORE, FP_CELL, FP_CELL);
	Forwards[FWD_SettingPointsTeam] = CreateMultiForward("ReGG_SettingPointsTeam", ET_STOP, FP_CELL, FP_CELL);
	Forwards[FWD_SettedPointsTeam] = CreateMultiForward("ReGG_SettedPointsTeam", ET_IGNORE, FP_CELL, FP_CELL);
	Forwards[FWD_SettingLevelSingle] = CreateMultiForward("ReGG_SettingLevelSingle", ET_STOP, FP_CELL, FP_CELL);
	Forwards[FWD_SettedLevelSingle] = CreateMultiForward("ReGG_SettedLevelSingle", ET_IGNORE, FP_CELL, FP_CELL);
	Forwards[FWD_SettingLevelTeam] = CreateMultiForward("ReGG_SettingLevelTeam", ET_STOP, FP_CELL, FP_CELL);
	Forwards[FWD_SettedLevelTeam] = CreateMultiForward("ReGG_SettedLevelTeam", ET_IGNORE, FP_CELL, FP_CELL);
}

destroyForwards() {
	DestroyForward(Forwards[FWD_Starting]);
	DestroyForward(Forwards[FWD_Started]);
	DestroyForward(Forwards[FWD_Finishing]);
	DestroyForward(Forwards[FWD_Finished]);
	DestroyForward(Forwards[FWD_SettingPointsSingle]);
	DestroyForward(Forwards[FWD_SettedPointsSingle]);
	DestroyForward(Forwards[FWD_SettingPointsTeam]);
	DestroyForward(Forwards[FWD_SettedPointsTeam]);
	DestroyForward(Forwards[FWD_SettingLevelSingle]);
	DestroyForward(Forwards[FWD_SettedLevelSingle]);
	DestroyForward(Forwards[FWD_SettingLevelTeam]);
	DestroyForward(Forwards[FWD_SettedLevelTeam]);
}

registerNatives() {
	register_native("ReGG_Start", "NativeStart", 0);
	register_native("ReGG_Finish", "NativeFinish", 0);
	register_native("ReGG_GetMode", "NativeGetMode", 0);
	register_native("ReGG_GetSlot", "NativeGetSlot", 0);
	register_native("ReGG_GetLevel", "NativeGetLevel", 0);
	register_native("ReGG_GetPoints", "NativeGetPoints", 0);
	register_native("ReGG_GetLevelPoints", "NativeGetLevelPoints", 0);
}

public NativeStart(plugin, argc) {
	enum { arg_mode = 1 };
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	start(get_param(arg_mode));
	return 1;
}

public NativeFinish(plugin, argc) {
	finish();
	return 1;
}

public NativeGetMode(plugin, argc) {
	return Mode;
}

public NativeGetSlot(plugin, argc) {
	enum { arg_player = 1 };
	CHECK_NATIVE_ARGS_NUM(argc, 1, -1)
	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, -1)

	return getTeamSlot(player);
}

public NativeGetLevel(plugin, argc) {
	enum { arg_player = 1 };
	CHECK_NATIVE_ARGS_NUM(argc, 1, -1)
	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, -1)

	return getLevel(player);
}

public NativeGetPoints(plugin, argc) {
	enum { arg_player = 1 };
	CHECK_NATIVE_ARGS_NUM(argc, 1, -1)
	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, -1)

	return getPoints(player);
}

public NativeGetLevelPoints(plugin, argc) {
	enum { arg_player = 1, arg_level };
	CHECK_NATIVE_ARGS_NUM(argc, 1, -1)
	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, -1)
	new level = get_param(arg_level);
	CHECK_NATIVE_LEVEL(level, -1)
	return getLevelPoints(player, level);
}


stock get_level_goal(level,id=0)
{
	if(level < 1) return 1;

	// no teamplay, return preset goal
	if(!is_user_connected(id) || !get_pcvar_num(gg_teamplay))
	{
		if(is_user_bot(id)) return floatround(weaponGoal[level-1]*get_pcvar_float(gg_kills_botmod),floatround_ceil);
		return floatround(weaponGoal[level-1],floatround_ceil);
	}

	// one of this for every player on team
	new Float:result = weaponGoal[level-1] * float(team_player_count(cs_get_user_team(id)));
	
	// modifiers for nade and knife levels
	if(equal(weaponName[level-1],HEGRENADE)) result *= get_pcvar_float(gg_teamplay_nade_mod);
	else if(equal(weaponName[level-1],KNIFE)) result *= get_pcvar_float(gg_teamplay_knife_mod);
	
	if(result <= 0.0) result = 1.0;
	return floatround(result,floatround_ceil);
}
