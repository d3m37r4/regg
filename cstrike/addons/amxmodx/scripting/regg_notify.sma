#include <amxmodx>
#include <reapi>
#include <regg>

new const CONFIG_NAME[] = "regg-notify.ini";

new const COMMANDS[][] = {
	"REGG_TEAM_T",
	"REGG_TEAM_CT"
};

enum (+=1) {
	SectionNone = -1,
	SectionLevelUp,
	SectionLevelDown,
	SectionGrenadeLevel,
	SectionKnifeLevel,
	SectionWinner
};

#define IsMp3Format(%1)	bool:(equali(%1[strlen(%1) - 4], ".mp3"))
#define IsWavFormat(%1)	bool:(equali(%1[strlen(%1) - 4], ".wav"))

new bool:fistGrenadeLvl, bool:firtKnifeLvl;

new Array:LevelUp, Array:LevelDown, Array:GrenadeLevel, Array:KnifeLevel, Array:Winner;
new LevelUpNum, LevelDownNum, GrenadeLevelNum, KnifeLevelNum, WinnerNum, gSection;

public plugin_precache() {
	LevelUp = ArrayCreate(MAX_RESOURCE_PATH_LENGTH);
	LevelDown = ArrayCreate(MAX_RESOURCE_PATH_LENGTH);
	GrenadeLevel = ArrayCreate(MAX_RESOURCE_PATH_LENGTH);
	KnifeLevel = ArrayCreate(MAX_RESOURCE_PATH_LENGTH);
	Winner = ArrayCreate(MAX_RESOURCE_PATH_LENGTH);

	new filedir[MAX_RESOURCE_PATH_LENGTH];
	get_localinfo("amxx_configsdir", filedir, charsmax(filedir));
	format(filedir, charsmax(filedir), "%s/%s/%s", filedir, REGG_DIR_NAME, CONFIG_NAME);

	if(!file_exists(filedir)) {
		set_fail_state("File '%s' not found!", filedir);
	}

	if(!parseConfigINI(filedir)) {
		set_fail_state("Fatal parse error!");
	}

	if(LevelUp) {
		LevelUpNum = ArraySize(LevelUp);
	}

	if(LevelDown) {
		LevelDownNum = ArraySize(LevelDown);
	}

	if(GrenadeLevel) {
		GrenadeLevelNum = ArraySize(GrenadeLevel);
	}

	if(KnifeLevel) {
		KnifeLevelNum = ArraySize(KnifeLevel);
	}

	if(Winner) {
		WinnerNum = ArraySize(Winner);
	}
}

public plugin_init() {
	register_plugin("[ReGG] Notify", REGG_VERSION_STR, "F@nt0M");
	state none;
	
	firtKnifeLvl = true;
	fistGrenadeLvl = true;
}

public ReGG_StartPost(const ReGG_Mode:mode) {
	switch(mode) {
		case ReGG_ModeSingle, ReGG_ModeFFA: {
			state single;
		}

		case ReGG_ModeTeam: {
			state team;
		}

		default: {
			state none;
		}
	}
}

public ReGG_FinishPost() {
	state none;
	PlaySound(0, fmt("%a", ArrayGetStringHandle(Winner, random(WinnerNum))));
}

public ReGG_KillEnemyPost(const killer, const victim, const WeaponIdType:value, const ReGG_Result:result) <single> {
	switch(result) {
		case ReGG_ResultPointsUp: {
			client_cmd(killer, "spk ^"%s^"", "buttons/bell1.wav");
		}

		case ReGG_ResultPointsDown: {}

		case ReGG_ResultLevelUp: {
			PlaySound(killer, fmt("%a", ArrayGetStringHandle(LevelUp, random(LevelUpNum))));

			new level = ReGG_GetLevel(killer);
			new title[32];
			ReGG_GetLevelTitle(level, title, charsmax(title));
			client_print_color(killer, print_team_default, "%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_LVL_UP", level + 1, title);
		}

		case ReGG_ResultLevelDown: {
			PlaySound(killer, fmt("%a", ArrayGetStringHandle(LevelDown, random(LevelDownNum))));
			new level = ReGG_GetLevel(killer);
			new title[32];
			ReGG_GetLevelTitle(level, title, charsmax(title));
			client_print_color(killer, print_team_default, "%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_LVL_DOWN", level + 1, title);
		}
	}
}
public ReGG_KillEnemyPost(const killer, const victim, const WeaponIdType:value, const ReGG_Result:result) <team> {
	if(result == ReGG_ResultPointsUp) {
		client_cmd(killer, "spk ^"%s^"", "buttons/bell1.wav");
	}
}

public ReGG_KillEnemyPost(const killer, const victim, const WeaponIdType:value, const ReGG_Result:result) <none> {}

new oldTeamLevel;
public ReGG_TeamLevelPre(const slot, const value) {
	oldTeamLevel = ReGG_GetTeamLevel(slot);
}

public ReGG_TeamLevelPost(const slot, const value) {
	if(oldTeamLevel != value) {
		notifyTeam(slot, value, oldTeamLevel < value ? ReGG_ResultLevelUp : ReGG_ResultLevelDown);
	}
}

notifyTeam(const slot, const level, const ReGG_Result:result) {
	new title[32];
	ReGG_GetLevelTitle(level, title, charsmax(title));

	new players[MAX_PLAYERS], num;
	get_players(players, num, "ch");
	for(new i = 0, player, playerSlot; i < num; i++) {
		player = players[i];
		playerSlot = ReGG_GetPlayerSlot(player);
		if(playerSlot == ReGG_SlotInvalid) {
			continue;
		}

		switch(result) {
			case ReGG_ResultLevelUp: {
				if(playerSlot == slot) {
					PlaySound(player, fmt("%a", ArrayGetStringHandle(LevelUp, random(LevelUpNum))));
					client_print_color(player, print_team_default, "%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_LVL_TEAM_UP", level + 1, title);
				} else {
					client_print_color(
						player, slot == ReGG_SlotT ? print_team_red : print_team_blue,
						"%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_LVL_TEAM_UP_ALL", fmt("%L", LANG_PLAYER, COMMANDS[slot]), level + 1, title
					);
				}
			}

			case ReGG_ResultLevelDown: {
				if(playerSlot == slot) {
					PlaySound(player, fmt("%a", ArrayGetStringHandle(LevelDown, random(LevelDownNum))));
					client_print_color(player, print_team_default, "%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_LVL_TEAM_DOWN", level + 1, title);
				} else {
					client_print_color(
						player, slot == ReGG_SlotT ? print_team_red : print_team_blue,
						"%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_LVL_TEAM_DOWN_ALL", fmt("%L", LANG_PLAYER, COMMANDS[slot]), level + 1, title
					);
				}
			}
		}
	}
}

public ReGG_StealLevelsPost(const killer, const victim, const value) <single> {
	client_print_color(0, killer, "%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_STEAL_LVL", killer, victim);
}

public ReGG_StealLevelsPost(const killer, const victim, const value) <team, none> {}

public ReGG_StealPointsPost(const killer, const victim, const value) <single, team> {
	client_print_color(0, killer, "%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_STEAL_POINTS", killer, value, victim);
}

public ReGG_StealPointsPost(const killer, const victim, const value) <none> {}

public ReGG_GiveWeaponPost(const id, const WeaponIdType:value) {
	if(fistGrenadeLvl && value == WEAPON_HEGRENADE) {
		fistGrenadeLvl = false;
		PlaySound(0, fmt("%a", ArrayGetStringHandle(GrenadeLevel, random(GrenadeLevelNum))));
	} else if (firtKnifeLvl && value == WEAPON_KNIFE) {
		firtKnifeLvl = false;
		PlaySound(0, fmt("%a", ArrayGetStringHandle(KnifeLevel, random(KnifeLevelNum))));
	}
}

bool:parseConfigINI(const configFile[]) {
	new INIParser:parser = INI_CreateParser();

	if(parser != Invalid_INIParser) {
		INI_SetReaders(parser, "ReadCFGKeyValue", "ReadCFGNewSection");
		INI_ParseFile(parser, configFile);
		INI_DestroyParser(parser);
		return true;
	}

	return false;
}

public bool:ReadCFGNewSection(INIParser:handle, const section[], bool:invalid_tokens, bool:close_bracket) {
	if(!close_bracket) {
		log_amx("Closing bracket was not detected! Current section name '%s'.", section);
		return false;
	}
	
	if(equal(section, "level_up")) {
		gSection = SectionLevelUp;
		return true;
	}
	
	if(equal(section, "level_down")) {
		gSection = SectionLevelDown;
		return true;
	}

	if(equal(section, "grenade_lvl")) {
		gSection = SectionGrenadeLevel;
		return true;
	}
	
	if(equal(section, "knife_lvl")) {
		gSection = SectionKnifeLevel;
		return true;
	}
	
	if(equal(section, "winner")) {
		gSection = SectionWinner;
		return true;
	}

	return false;
}

public bool:ReadCFGKeyValue(INIParser:handle, const key[], const value[]) {
	switch(gSection) {
		case SectionNone: {
			 return false;
		}
		case SectionLevelUp: {
			 PrecacheSoundEx(LevelUp, key);
		}
		case SectionLevelDown: {
			 PrecacheSoundEx(LevelDown, key);
		}
		case SectionGrenadeLevel: {
			 PrecacheSoundEx(GrenadeLevel, key);
		}
		case SectionKnifeLevel: {
			 PrecacheSoundEx(KnifeLevel, key);
		}
		case SectionWinner: {
			 PrecacheSoundEx(Winner, key);
		}
	}

	return true;
}

bool:PrecacheSoundEx(Array:arr, const keys[]) {
	if(!IsWavFormat(keys) && !IsMp3Format(keys)) {
		log_amx("Invalid sound file! Parse string '%s'. Only sound files in wav or mp3 format should be used!", keys);
		return false;
	}
	static Sound[MAX_RESOURCE_PATH_LENGTH];
	formatex(Sound, charsmax(Sound), "sound/%s", keys);
	ArrayPushString(arr, Sound);
	if(!file_exists(Sound)) {
		log_amx("File missing '%s'.", Sound);
		return false;
	}
	if(IsMp3Format(keys)) {
		precache_generic(Sound);
	} else {
		precache_sound(keys);
	}

	return true;
}

PlaySound(const id, const sound[]) {
	if(IsMp3Format(sound)) {
		client_cmd(id, "stopsound; mp3 play %s", sound);
	} else {
		rg_send_audio(id, sound);
	}
}