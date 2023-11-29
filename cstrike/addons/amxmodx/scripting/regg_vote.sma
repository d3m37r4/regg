#include <amxmodx>
#include <amxmisc>
#include <regg>
#include <reapi>
#include <time>

new const CONFIG_NAME[] = "regg-vote.ini";

#define TASK_STARTVOTE 39731

enum _:VoteMode {
	ModeSingle = 0,
	ModeTeam,
	ModeFFA
};

enum setting_s {
	startvotetime,
	votetime,
	freeze,
	screenfade,
	sound
};

enum (+=1) {
	SectionNone = -1,
	SectionMode,
	SectionSetting
};

new const ModeName[VoteMode][] = {
	"REGG_MODE_SINGLE",
	"REGG_MODE_TEAM",
	"REGG_MODE_FFA"
};

new const Sound[][] = {
	"sound/fvox/one.wav", "sound/fvox/two.wav", "sound/fvox/three.wav", "sound/fvox/four.wav", "sound/fvox/five.wav",
	"sound/fvox/six.wav", "sound/fvox/seven.wav", "sound/fvox/eight.wav", "sound/fvox/nine.wav", "sound/fvox/ten.wav"
};

new bool:playerVoted[MAX_PLAYERS +1], iVote[VoteMode], bool:voteStarted = false, bool:voteEnded = false;
new voteTimer;
new setting[setting_s], gSection, ReGG_Mode:mode_s[VoteMode];

public plugin_init() {
	register_plugin("[ReGG] Vote", REGG_VERSION_STR, "Jumper & d3m37r4");
	
	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn", true);
}

public plugin_precache() {
	new filedir[MAX_RESOURCE_PATH_LENGTH];
	get_localinfo("amxx_configsdir", filedir, charsmax(filedir));
	format(filedir, charsmax(filedir), "%s/%s/%s", filedir, REGG_DIR_NAME, CONFIG_NAME);

	if(!file_exists(filedir)) {
		set_fail_state("File '%s' not found!", filedir);
	}

	if(!parseConfigINI(filedir)) {
		set_fail_state("Fatal parse error!");
	}
}

public client_putinserver(id) {
	playerVoted[id] = false;
}

public ReGG_StartPre(const ReGG_Mode:mode) {
	if(setting[startvotetime] < 0) {
		return;
	}
	if(!voteStarted && !voteEnded) {
		voteTimer = setting[startvotetime] +1;
		set_task_ex(1.0, "StartVotePre", TASK_STARTVOTE, .flags = SetTask_Repeat);
	}
}

public CBasePlayer_Spawn(id) {
	if(!is_user_authorized(id)) {
		return HC_CONTINUE;
	}
	if(!playerVoted[id] && voteStarted) {
		menu_vote(id);
	}

	return HC_CONTINUE;
}

public StartVotePre() {
	voteTimer--;

	if(voteTimer) {
		new sec = voteTimer % SECONDS_IN_MINUTE;
		client_print(0, print_center, "До начала голосования за режим игры: %d сек.", sec);
		if(setting[sound] != 0 && voteTimer <= 10) {
			rg_send_audio(0, Sound[voteTimer -1]);
		}
	} else {
		remove_task(TASK_STARTVOTE);
		client_print(0, print_center, "Голосование за режим игры началось!");
		StartVote();
	}
}

public StartVote() {
	voteStarted = true;
	new players[MAX_PLAYERS], count;
	get_players_ex(players, count, GetPlayers_ExcludeBots|GetPlayers_ExcludeHLTV);

	for(new i, id; i < count; i++) {
		id = players[i];
		if(!is_user_authorized(id)) {
			continue;
		}
		if(!playerVoted[id] && voteStarted) {
			menu_vote(id);
		}
	}

	set_task_ex(float(setting[votetime]), "EndVote");
}

public EndVote() {
	voteStarted = false;
	voteEnded = true;
	new win = 0;
	for(new i = 0; i < VoteMode; i++) {
		if(iVote[i] > iVote[win]) {
			win = i;
		}
	}
	client_print(0, print_center, "Голосование за режим игры окончено!^rВыбран режим: %s", fmt("%L", LANG_PLAYER, ModeName[win]));
	client_print_color(0, print_team_default, "%L", LANG_PLAYER, "REGG_END_VOTE", fmt("%L", LANG_PLAYER, ModeName[win]));

	ReGG_Start(ReGG_Mode:mode_s[win]);
}

public menu_vote(const id) {
	new menu = menu_create(fmt("%L", LANG_PLAYER, "REGG_VOTE_MENU"), "vote_menu_handler");
	if(mode_s[ModeSingle] != 0) {
		menu_additem(menu, fmt("%L", LANG_PLAYER, "REGG_MODE_SINGLE"), "0");
	}
	if(mode_s[ModeTeam] != 0) {
		menu_additem(menu, fmt("%L", LANG_PLAYER, "REGG_MODE_TEAM"), "1");
	}
	if(mode_s[ModeFFA] != 0) {
		menu_additem(menu, fmt("%L", LANG_PLAYER, "REGG_MODE_FFA"), "2");
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);

	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public vote_menu_handler(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if(voteEnded) {
		client_print_color(0, print_team_default, "%L", LANG_PLAYER, "REGG_VOTE_ENDED");
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new data[6], name[MAX_NAME_LENGTH], access, callback;
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback);

	new key = str_to_num(data);

	playerVoted[id] = true;
	++iVote[key];
	
	client_print_color(0, print_team_default, "%L", LANG_PLAYER, "REGG_PLAYER_VOTE", id, name);
	
	menu_destroy(menu);
	
	return PLUGIN_HANDLED;
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
	
	if(equal(section, "vote_mode")) {
		gSection = SectionMode;
		return true;
	}
	
	if(equal(section, "vote_setting")) {
		gSection = SectionSetting;
		return true;
	}

	return false;
}

public bool:ReadCFGKeyValue(INIParser:handle, const key[], const value[]) {
	switch(gSection) {
		case SectionNone: {
			 return false;
		}
		case SectionMode: {
			if(strcmp(key, "single") == 0) {
				mode_s[ModeSingle] = ReGG_Mode:ReGG_ModeSingle;
			} else if(strcmp(key, "team") == 0) {
				mode_s[ModeTeam] = ReGG_Mode:ReGG_ModeTeam;
			} else if(strcmp(key, "ffa") == 0) {
				mode_s[ModeFFA] = ReGG_Mode:ReGG_ModeFFA;
			}
		}
		case SectionSetting: {
			if(strcmp(key, "startvotetime") == 0) {
				setting[startvotetime] = str_to_num(value);
			} else if(strcmp(key, "votetime") == 0) {
				setting[votetime] = str_to_num(value);
			}  else if(strcmp(key, "freeze") == 0) {
				setting[freeze] = str_to_num(value);
			} else if(strcmp(key, "screenfade") == 0) {
				setting[screenfade] = str_to_num(value);
			} else if(strcmp(key, "sound") == 0) {
				setting[sound] = str_to_num(value);
			}
		}
	}

	return true;
}
