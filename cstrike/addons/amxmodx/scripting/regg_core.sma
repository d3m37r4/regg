#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <regg>

const MAX_LEVELS = 30;
const MAX_LEVEL_TITLE_LENGTH = 32;
const MAX_GRENADE_WEAPONS = 5;

enum _:level_s {
	WeaponIdType:LevelWeaponID,
	LevelPoints,
	LevelTitle[MAX_LEVEL_TITLE_LENGTH],
	LevelRatio,
};

enum _:player_s {
	bool:PlayerJoined,
	PlayerPoints,
	PlayerLevel,
	PlayerLevelPoints,
};

enum _:team_s {
	TeamPoints,
	TeamLevel,
	TeamPlayers,
	TeamLevelPoints,
};

new ReGG_Mode:Mode = ReGG_ModeNone;
new Levels[MAX_LEVELS][level_s], LevelsNum;
new Players[MAX_PLAYERS + 1][player_s];
new Teams[2][team_s];
new WeaponIdType:GrenadeWeapons[MAX_GRENADE_WEAPONS], GrenadeWeaponsNum;

new bool:DebugMode;

#include "regg/config.inl"
#include "regg/forwards.inl"
#include "regg/hooks.inl"
#include "regg/functions.inl"
#include "regg/natives.inl"

public plugin_natives() {
	register_library("ReGunGame");
	registerNatives();
}

public plugin_init() {
	register_plugin("[ReGG] Core", REGG_VERSION_STR, "Jumper & d3m37r4");
	
	register_dictionary("regg.txt");

	registerCvars();
	registerHooks();
	disableHooks();
	registerForwards();
	loadCfg();
	loadIni();

	DebugMode = bool:(plugin_flags() & AMX_FLAG_DEBUG);
	DebugMode && log_amx("Debug mode is enable!");
}

public plugin_cfg() {
	register_cvar("regg_version", REGG_VERSION_STR, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);
}

public plugin_end() {
	destroyForwards();
	if(Mode != ReGG_ModeNone) {
		restoreGameCvars();
	}
}

public plugin_pause() {
	if(Mode != ReGG_ModeNone) {
		restoreGameCvars();
	}
}

public plugin_unpause() {
	if(Mode != ReGG_ModeNone) {
		changeGameCvars();
	}
}

public client_putinserver(id) {
	Players[id][PlayerJoined] = false;
	Players[id][PlayerPoints] = 0;
	Players[id][PlayerLevel] = 0;
}
