/**
TODOS
1. 
 */

#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <map_manager>

#define rg_get_user_team(%1) TeamName:get_member(%1, m_iTeam)

#define MAX_LEVELS 10

#define TASK_INFO 1
#define TASK_GRENADE 50

new const MapEntityList[][] = {
	"func_bomb_target",
	"info_bomb_target",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"func_vip_safetyzone",
	"info_vip_start",
	"hostage_entity",
	"monster_scientist",
	"func_escapezone",
	"func_buyzone",
	"armoury_entity",
	"game_player_equip",
	"player_weaponstrip"
};

new EntitySpawnHook, HookChain:FShouldSwitchWeapon;

new SyncHudLeader, SyncHudStats;

enum _:LEVEL {
	WeaponIdType:LevelWeaponID,
	LevelPoints,
};

new Levels[][LEVEL] = {
	{ WEAPON_P228, 5 },
	{ WEAPON_SCOUT, 5 },
	// { WEAPON_XM1014, 5 },
	// { WEAPON_MAC10, 5 },
	// { WEAPON_AUG, 5 },
	// { WEAPON_ELITE, 5 },
	// { WEAPON_FIVESEVEN, 5 },
	// { WEAPON_UMP45, 5 },
	// { WEAPON_SG550, 5 },
	// { WEAPON_GALIL, 5 },
	{ WEAPON_FAMAS, 5 },
	{ WEAPON_USP, 5 },
	// { WEAPON_GLOCK18, 5 },
	{ WEAPON_AWP, 5 },
	// { WEAPON_MP5N, 5 },
	// { WEAPON_M249, 5 },
	// { WEAPON_M5, 5 },
	{ WEAPON_M4A1, 5 },
	// { WEAPON_TMP, 5 },
	// { WEAPON_G5SG1, 5 },
	{ WEAPON_DEAGLE, 5 },
	// { WEAPON_SG552, 5 },
	{ WEAPON_AK47, 5 },
	// { WEAPON_P90, 5 },
	{ WEAPON_HEGRENADE, 2 },
	{ WEAPON_KNIFE, 1 }
};

enum {
	ModeSingle,
	ModeTeam
};

enum _:Player {
	PlayerLevel,
	PlayerPoints,
};

enum _:Team {
	TeamPlayersNum,
	TeamPoints,
	TeamNeedPoints,
	TeamLevel
}

new Players[MAX_PLAYERS + 1][Player];
new Teams[2][Team];

new bool:IsLeader[MAX_PLAYERS + 1], LastLeader, LeadersNum, LeadersLevel;

new ModePcvar, Mode;

public plugin_precache() {	
	EntitySpawnHook = register_forward(FM_Spawn, "FwdEntitySpawn");
}

public plugin_init() {
	register_plugin("[ReAPI] GunGame", REGG_VERSION_STR, "F@nt0M");

	if (EntitySpawnHook) {
		unregister_forward(FM_Spawn, EntitySpawnHook);
	}

	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "CBasePlayer_OnSpawnEquip_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);
	RegisterHookChain(RH_SV_DropClient, "SV_DropClient_Post", true);
	RegisterHookChain(RG_ThrowHeGrenade, "CBasePlayer_ThrowHeGrenade_Post", true);
	FShouldSwitchWeapon = RegisterHookChain(RG_CSGameRules_FShouldSwitchWeapon, "CSGameRules_FShouldSwitchWeapon_Pre", false);
	DisableHookChain(FShouldSwitchWeapon);

	RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "CBasePlayer_HasRestrictItem_Pre", false);
	RegisterHookChain(RG_CBasePlayer_DropPlayerItem, "CBasePlayer_DropPlayerItem_Pre", false);
	RegisterHookChain(RG_CSGameRules_DeadPlayerWeapons, "CSGameRules_DeadPlayerWeapons_Pre", false);
	RegisterHookChain(RG_CSGameRules_GiveC4, "CSGameRules_GiveC4_Pre", false);
	RegisterHam(Ham_Use, "game_player_equip", "HamHookSupercede", false);
	RegisterHam(Ham_Use, "player_weaponstrip", "HamHookSupercede", false);

	SyncHudLeader = CreateHudSyncObj();
	SyncHudStats = CreateHudSyncObj();

	set_task(1.0, "TaskInfo", TASK_INFO, .flags = "b");


	ModePcvar = create_cvar("gg_mode", "0", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 1.0);
}

public plugin_cfg() {
	set_cvar_num("mp_round_infinite", 1);
	set_cvar_float("mp_forcerespawn", 1.0);
	set_cvar_num("mp_refill_bpammo_weapons", 3);
	set_cvar_num("mp_timelimit", 0);
	set_cvar_num("mp_maxrounds", 0);
	set_cvar_num("mp_fraglimit", 0);

	Mode = get_pcvar_num(ModePcvar);
	Mode = ModeTeam;
}

public client_putinserver(id) {
	arrayset(Players[id], 0, sizeof(Players[]));
}

public SV_DropClient_Post(const id) {
	remove_task(TASK_GRENADE + id);
	checkLeaders();
}

public FwdEntitySpawn(const ent) {
	if (is_nullent(ent)) {
		return FMRES_IGNORED;
	}

	for (new i = 0; i < sizeof MapEntityList; i++) {
		if (FClassnameIs(ent, MapEntityList[i])) {
			set_entvar(ent, var_flags, FL_KILLME);
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
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

public CBasePlayer_OnSpawnEquip_Pre(const id) {
	if (!is_user_alive(id)) {
		return HC_CONTINUE;
	}

	rg_give_item(id, "weapon_knife");

	new level = getLevel(id);
	giveWeapon(id, Levels[level][LevelWeaponID]);
	return HC_SUPERCEDE;
}

public CBasePlayer_Spawn_Post(const id) {
	if (!is_user_alive(id)) {
		return HC_CONTINUE;
	}

	new TeamName:team = rg_get_user_team(id);
	new slot = getTeamSlot(team);
	if (slot == -1) {
		return HC_CONTINUE;
	}
	
	new num = getPTeamlayersNum(team);

	if (num != Teams[slot][TeamPlayersNum]) {
		Teams[slot][TeamPlayersNum] = num;
		new level = Teams[slot][TeamLevel];
		Teams[slot][TeamNeedPoints] = Levels[level][LevelPoints] * num;
	}

	return HC_CONTINUE;
}

getTeamSlot(const TeamName:team) {
	switch (team) {
		case TEAM_TERRORIST: {
			return 0;
		}

		case TEAM_CT: {
			return 1;
		}
	}
	return -1;
}

getPTeamlayersNum(const TeamName:team) {
	new num;
	for (new id = 1; id <= MaxClients; id++) {
		if (is_user_connected(id) && rg_get_user_team(id) == team) {
			num++;
		}
	}

	return num;
}

public CBasePlayer_Killed_Post(const victim, const killer) {
	if (victim == killer) {
		levelDown(victim);
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

	remove_task(TASK_GRENADE + victim);

	return HC_CONTINUE;
}

public CBasePlayer_ThrowHeGrenade_Post(const id) {
	set_task(3.0, "TaskGiveGrenade", TASK_GRENADE + id);
}

public CSGameRules_FShouldSwitchWeapon_Pre() {
	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

public TaskGiveGrenade(id) {
	id -= TASK_GRENADE;
	new level = getLevel(id);
	if (Levels[level][LevelWeaponID] == WEAPON_HEGRENADE) {
		giveWeapon(id, WEAPON_HEGRENADE);
	}
}

public TaskInfo() {
	new players[MAX_PLAYERS], num;
	get_players(players, num, "ach");
	// for (i = 0; i < num; i++) {
	// 	player = players[i];
	// }

	// if (LeadersNum > 0) {
	// 	set_hudmessage(250, 250, 250, -1.0, 0.05, 0, 0.0, 20.0, 0.0, 0.0, -1);
	// 	new name[MAX_NAME_LENGTH];
	// 	get_entvar(LastLeader, var_netname, name, charsmax(name));
	// 	if (LeadersNum > 1) {
	// 		ShowSyncHudMsg(player, SyncHudLeader, "Leaders: %s + %d^nLevel %d", name, LeadersNum, LeadersLevel + 1);
	// 	} else {
	// 		ShowSyncHudMsg(player, SyncHudLeader, "Leader: %s^nLevel %d", name, LeadersLevel + 1);
	// 	}
	// }

	set_hudmessage(250, 250, 250, -1.0, 0.85, 0, 0.0, 20.0, 0.0, 0.0, -1);
	for (new i = 0, level, points, levelPoints; i < num; i++) {
		level = getLevel(players[i]);
		points = getPoints(players[i]);
		levelPoints = getLevelPoints(players[i], level);
		ShowSyncHudMsg(players[i], SyncHudStats, "Level: %d^nKills: %d/%d", level + 1, points, levelPoints);
	}
}

getLevel(const id) {
	if (Mode == ModeSingle) {
		return Players[id][PlayerLevel];
	}

	new slot = getTeamSlot(rg_get_user_team(id));
	return Teams[slot][TeamLevel];
}

getPoints(const id) {
	if (Mode == ModeSingle) {
		return Players[id][PlayerPoints];
	}

	new slot = getTeamSlot(rg_get_user_team(id));
	return Teams[slot][TeamPoints];
}

getLevelPoints(const id, const level) {
	if (Mode == ModeSingle) {
		return Levels[level][LevelPoints];
	}

	new slot = getTeamSlot(rg_get_user_team(id));
	return Levels[level][LevelPoints] * Teams[slot][TeamPlayersNum];
}

killKnife(const victim, const killer) {
	new level = getLevel(killer);

	if (Levels[level][LevelWeaponID] == WEAPON_KNIFE) {
		mapm_start_vote(VOTE_BY_SCHEDULER);
		return;
	}

	if (Levels[level][LevelWeaponID] != WEAPON_HEGRENADE) {
		addPointsKnife(victim, killer);
	}
}

killGrenade(const killer) {
	new level = getLevel(killer);
	if (Levels[level][LevelWeaponID] != WEAPON_HEGRENADE) {
		return;
	}

	if (addPoints(killer, level)) {
		levelUp(killer);
	} else {
		giveWeapon(killer, WEAPON_HEGRENADE);
	}
}

killWeapon(const killer, const weapon) {
	new level = getLevel(killer);
	if (Levels[level][LevelWeaponID] == WEAPON_HEGRENADE) {
		return;
	}

	if (addPoints(killer, level)) {
		levelUp(killer);
	} else {
		rg_instant_reload_weapons(killer, weapon);
	}
}

addPoints(const id, const level) {
	Players[id][PlayerPoints]++;

	if (Mode == ModeSingle) {
		return bool:(Players[id][PlayerPoints] >= Levels[level][LevelPoints]);
	} else {
		// Players[id][PlayerPoints]++;
	}

	return false;
}

addPointsKnife(const victim, const killer) {
	if (Mode == ModeSingle) {
		EnableHookChain(FShouldSwitchWeapon);
		levelUp(killer);
		levelDown(victim);
		DisableHookChain(FShouldSwitchWeapon);
	} else {
		//
	}
}

giveWeapon(const id, const WeaponIdType:wid) {
	switch (wid) {
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
			rg_get_weapon_info(wid, WI_NAME, wname, charsmax(wname));
			rg_give_item(id, wname);
			rg_set_user_bpammo(id, wid, 200);
		}
	}
	
}

removeWeapon(const id, const WeaponIdType:wid) {
	if (wid != WEAPON_KNIFE) {
		new wname[32];
		rg_get_weapon_info(wid, WI_NAME, wname, charsmax(wname));
		rg_remove_item(id, wname, true);
	}
}

levelUp(const id) {
	if (Players[id][PlayerLevel] >= sizeof Levels) {
		return;
	}
	new oldLevel = Players[id][PlayerLevel];
	Players[id][PlayerLevel]++;
	new newLevel = Players[id][PlayerLevel];
	Players[id][PlayerPoints] = 0;
	removeWeapon(id, Levels[oldLevel][LevelWeaponID]);
	if (newLevel < sizeof Levels) {
		giveWeapon(id, Levels[newLevel][LevelWeaponID]);
	}

	checkLeaders();
}

levelDown(const id) {
	if (Players[id][PlayerLevel] <= 0) {
		return;
	}

	new oldLevel = Players[id][PlayerLevel];
	Players[id][PlayerLevel]--;
	new newLevel = Players[id][PlayerLevel];
	Players[id][PlayerPoints] = 0;
	removeWeapon(id, Levels[oldLevel][LevelWeaponID]);
	giveWeapon(id, Levels[newLevel][LevelWeaponID]);

	checkLeaders();
}

checkLeaders() {
	arrayset(IsLeader, false, sizeof IsLeader);
	LastLeader = 0;
	LeadersNum = 0;
	LeadersLevel = 0;

	new players[MAX_PLAYERS], num, player, i;
	get_players(players, num, "h");
	for (i = 0; i < num; i++) {
		player = players[i];
		if (Players[player][PlayerLevel] > LeadersLevel) {
			LeadersLevel = Players[player][PlayerLevel];
		}
	}

	if (LeadersLevel <= 0) {
		return;
	}
	for (i = 0; i < num; i++) {
		player = players[i];
		if (Players[player][PlayerLevel] >= LeadersLevel) {
			IsLeader[player] = true;
			LastLeader = player;
			LeadersNum++;
		}
	}
}

/*
enum _:Player {
    bool:IsProtected,
    bool:SkipFrame,
    bool:IsAlive,
    Float:ProtectionEndTime
}
new Players[MAX_PLAYERS + 1][Player];

HookChainThink = RegisterHookChain(RG_CBasePlayer_PostThink, "CBasePlayer_PostThink_Post", true);

public client_putinserver(id) {
    Players[id][IsProtected] = false;
    Players[id][SkipFrame] = false;
    Players[id][IsAlive] = false;
    Players[id][ProtectionEndTime] = 0.0;
}

public CBasePlayer_PostThink_Post(const id) {
    if (!Players[id][IsAlive] || !Players[id][IsProtected]) {
        return HC_CONTINUE;
    }

    if (Players[id][SkipFrame]) {
        Players[id][SkipFrame] = false;
        return HC_CONTINUE;
    }
    
    if ((get_member(id, m_afButtonPressed) & ~IN_SCORE) > 0 || get_gametime() >= Players[id][ProtectionEndTime]) {
        disableProtection(id);
    }
    
    return HC_CONTINUE;
}

enableProtection(const id) {
    Players[id][IsProtected] = true;
    Players[id][SkipFrame] = true;
    Players[id][ProtectionEndTime] = get_gametime() + ProtectionTime;

    set_entvar(id, var_takedamage, DAMAGE_NO);
    set_entvar(id, var_rendermode, kRenderTransAdd);
    set_entvar(id, var_renderamt, 100.0);
}

disableProtection(const id) {
    Players[id][IsProtected] = false;
    Players[id][SkipFrame] = false;
    Players[id][ProtectionEndTime] = 0.0;

    set_entvar(id, var_takedamage, DAMAGE_AIM);
    set_entvar(id, var_rendermode, kRenderNormal);
}
*/