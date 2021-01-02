#if defined _regg_config_included
	#endinput
#endif

#define _regg_config_included

#include <amxmisc>

enum _:config_s {
    // ReGG_Mode:CfgMode,
    Float:CfgNadeRefresh,
    CfgStealMode,
    CfgStealValue,
    CfgAWPOneShot,
    CfgAmmoAmount,
    CfgRefillOnKill,
    CfgGiveArmor,
    CfgGiveHelmet,
};

enum config_section_s {
    CfgSectionNone,
    CfgSectionGrenade,
    CfgSectionLevel,
};

enum _:game_cvars_s {
    GCRoundInfinite[32],
    Float:GCForcerespawn,
    GCRefillBpammoWeapons,
    GCTimelimit,
    GCMaxrounds,
    GCFraglimit,
    GCFreeForAll,
    GCFriendlyFire,
    GCGivePlayerC4,
}

new config_section_s:CfgSection = CfgSectionNone;
new Config[config_s];
new GameCvars[game_cvars_s];

new const REGG_MOD_DIR_NAME[MAX_NAME_LENGTH] = "ReGunGame";
new const CONFIG_NAME[] = "ReGunGame.cfg";

registerCvars() {
    bind_pcvar_float(create_cvar(
        "regg_nade_refresh", "5.0",
        .has_min = true,
        .min_val = 1.0
    ), Config[CfgNadeRefresh]);

    // 0 - off, 1 - steal level, 2 - steal points
    bind_pcvar_num(create_cvar(
        "regg_steal_mode", "1",
        .has_min = true,
        .min_val = 0.0,
        .has_max = true,
        .max_val = 2.0
    ), Config[CfgStealMode]);

    bind_pcvar_num(create_cvar(
        "regg_steal_value", "1",
        .has_min = true,
        .min_val = 1.0
    ), Config[CfgStealValue]);

    bind_pcvar_num(create_cvar(
        "regg_awp_oneshot", "1",
        .has_min = true,
        .min_val = 0.0,
        .has_max = true,
        .max_val = 1.0
    ), Config[CfgAWPOneShot]);

    bind_pcvar_num(create_cvar(
        "regg_ammo_amount", "200",
        .has_min = true,
        .min_val = 1.0
    ), Config[CfgAmmoAmount]);

    bind_pcvar_num(create_cvar(
        "regg_refill_on_kill", "1",
        .has_min = true,
        .min_val = 1.0,
        .has_max = true,
        .max_val = 1.0
    ), Config[CfgRefillOnKill]);

    bind_pcvar_num(create_cvar(
        "regg_give_armor", "100",
        .has_min = true,
        .min_val = 0.0
    ), Config[CfgGiveArmor]);

    bind_pcvar_num(create_cvar(
        "regg_give_helmet", "1",
        .has_min = true,
        .min_val = 0.0,
        .has_max = true,
        .max_val = 1.0
    ), Config[CfgGiveHelmet]);
}

changeGameCvars() {
    new pcvar;

    pcvar = get_cvar_pointer("mp_round_infinite");
    get_pcvar_string(pcvar, GameCvars[GCRoundInfinite], charsmax(GameCvars[GCRoundInfinite]));
    set_pcvar_num(pcvar, 1);

    pcvar = get_cvar_pointer("mp_forcerespawn");
    GameCvars[GCForcerespawn] = get_pcvar_float(pcvar);
    set_pcvar_float(pcvar, 1.0);

    pcvar = get_cvar_pointer("mp_refill_bpammo_weapons");
    GameCvars[GCRefillBpammoWeapons] = get_pcvar_num(pcvar);
    set_pcvar_num(pcvar, 3);

    pcvar = get_cvar_pointer("mp_timelimit");
    GameCvars[GCTimelimit] = get_pcvar_num(pcvar);
    set_pcvar_num(pcvar, 0);

    pcvar = get_cvar_pointer("mp_maxrounds");
    GameCvars[GCMaxrounds] = get_pcvar_num(pcvar);
    set_pcvar_num(pcvar, 0);

    pcvar = get_cvar_pointer("mp_fraglimit");
    GameCvars[GCFraglimit] = get_pcvar_num(pcvar);
    set_pcvar_num(pcvar, 0);

    pcvar = get_cvar_pointer("mp_give_player_c4");
    GameCvars[GCGivePlayerC4] = get_pcvar_num(pcvar);
    set_pcvar_num(pcvar, 0);

    if (Mode == ReGG_ModeFFA) {
        pcvar = get_cvar_pointer("mp_freeforall");
        GameCvars[GCFreeForAll] = get_pcvar_num(pcvar);
        set_pcvar_num(pcvar, 1);
    } else {
        pcvar = get_cvar_pointer("mp_friendlyfire");
        GameCvars[GCFriendlyFire] = get_pcvar_num(pcvar);
        set_pcvar_num(pcvar, 1);
    }
}

restoreGameCvars() {
    new pcvar;

    pcvar = get_cvar_pointer("mp_round_infinite");
    set_pcvar_string(pcvar, GameCvars[GCRoundInfinite]);

    pcvar = get_cvar_pointer("mp_forcerespawn");
    set_pcvar_float(pcvar, GameCvars[GCForcerespawn]);

    pcvar = get_cvar_pointer("mp_refill_bpammo_weapons");
    set_pcvar_num(pcvar, GameCvars[GCRefillBpammoWeapons]);

    pcvar = get_cvar_pointer("mp_timelimit");
    set_pcvar_num(pcvar, GameCvars[GCTimelimit]);

    pcvar = get_cvar_pointer("mp_maxrounds");
    set_pcvar_num(pcvar, GameCvars[GCMaxrounds]);

    pcvar = get_cvar_pointer("mp_fraglimit");
    set_pcvar_num(pcvar, GameCvars[GCFraglimit]);

    pcvar = get_cvar_pointer("mp_give_player_c4");
    set_pcvar_num(pcvar, GameCvars[GCGivePlayerC4]);

    if (Mode == ReGG_ModeFFA) {
        pcvar = get_cvar_pointer("mp_freeforall");
        set_pcvar_num(pcvar, GameCvars[GCFreeForAll]);
    } else {
        pcvar = get_cvar_pointer("mp_friendlyfire");
        set_pcvar_num(pcvar, GameCvars[GCFriendlyFire]);
    }
}

loadCfg() {
    new filedir[MAX_RESOURCE_PATH_LENGTH];
    get_localinfo("amxx_configsdir", filedir, charsmax(filedir));
    format(filedir, charsmax(filedir), "%s/%s/%s", filedir, REGG_MOD_DIR_NAME, CONFIG_NAME);

    if(file_exists(filedir)) {
        server_cmd("exec %s", filedir);
    } else {
        set_fail_state("File '%s' not found!", filedir);
    }
}

bool:loadIni() {
    new INIParser:handle = INI_CreateParser();
    if (handle == Invalid_INIParser) {
        return false;
    }

    new file[MAX_RESOURCE_PATH_LENGTH];
    get_localinfo("amxx_configsdir", file, charsmax(file));
    format(file, charsmax(file), "%s/%s/regg-lvl.ini", file, REGG_MOD_DIR_NAME);

    INI_SetReaders(handle, "ConfigOnKeyValue", "ConfigOnNewSection");
    INI_SetParseEnd(handle, "ConfigOnParseEnd");
    return INI_ParseFile(handle, file);
}

public bool:ConfigOnNewSection(const INIParser:handle, const section[]) {
    if (CfgSection == CfgSectionLevel) {
        LevelsNum++;
    }

    if (strcmp(section, "GRENADE") == 0) {
        CfgSection = CfgSectionGrenade;
    } else if (strcmp(section, "LEVEL") == 0) {
        CfgSection = CfgSectionLevel;
    } else {
        CfgSection = CfgSectionNone;
    }
    return true;
}

public bool:ConfigOnKeyValue(const INIParser:handle, const key[], const value[]) {
    switch (CfgSection) {
        case CfgSectionGrenade: {
            if (GrenadeWeaponsNum < MAX_GRENADE_WEAPONS - 1) {
                new WeaponIdType:wid = rg_get_weapon_info(value, WI_ID);
                if (wid != WEAPON_NONE) {
                    GrenadeWeapons[GrenadeWeaponsNum] = wid;
                    GrenadeWeaponsNum++;
                }
            }
        }

        case CfgSectionLevel: {
            if (strcmp(key, "title") == 0) {
                copy(Levels[LevelsNum][LevelTitle], MAX_LEVEL_TITLE_LENGTH - 1, value);
            } else if (strcmp(key, "weapon") == 0) {
                Levels[LevelsNum][LevelWeaponID] = WeaponIdType:rg_get_weapon_info(value, WI_ID);
            } else if (strcmp(key, "points") == 0) {
                Levels[LevelsNum][LevelPoints] = str_to_num(value);
            } else if (strcmp(key, "mod") == 0) {
                Levels[LevelsNum][LevelMod] = str_to_num(value);
            }
        }
    }

    return true;
}

public ConfigOnParseEnd(INIParser:handle, bool:halted, any:data) {
    if (CfgSection == CfgSectionLevel) {
        LevelsNum++;
    }
    INI_DestroyParser(handle);
}