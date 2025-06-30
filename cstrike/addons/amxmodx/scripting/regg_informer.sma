#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <regg>

const Float:MaxHudHoldTime = 256.0;

new SyncHudInformer, SyncHudLeader;
new ShowInformer, ShowLeader;
new cvar_buffer[12];

enum {CT, TT};

enum color_s {
	red,
	green,
	blue
};

new leaderColor[color_s];
new informerColor[color_s];

enum pos_s {
	Float:x,
	Float:y
};

new Float:leaderPos[pos_s];
new Float:informerPos[pos_s];

enum _:informerDisplay {
	INF_TPL_WEAPON,
	INF_TPL_LEVEL,
	INF_TPL_MAXLEVEL,
	INF_TPL_SAMELEVEL,
	INF_TPL_POINTS,
	INF_TPL_NEEDPOINTS,
	INF_TPL_LEADER,
	INF_TPL_LWEAPON
};

new informerBitSum;

new informerTplKeys[informerDisplay][] = {
	"<weapon>",
	"<level>",
	"<maxlevel>",
	"<samelevel>",
	"<points>",
	"<needpoints>",
	"<leader>",
	"<lweapon>"
};

#define parseColors(%1,%2) parse(%1, %2[red], charsmax(%2[]), %2[green], charsmax(%2[]), %2[blue], charsmax(%2[]))
#define parseCoordinates(%1,%2) parse(%1, %2[x], charsmax(%2[]), %2[y], charsmax(%2[]))

public plugin_init() {
	register_plugin("[ReGG] Informer", REGG_VERSION_STR, "Jumper & d3m37r4");

	state disabled;

	registerCvars();

	RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);

	SyncHudInformer = CreateHudSyncObj();
	SyncHudLeader = CreateHudSyncObj();
}

public CBasePlayer_Spawn_Post(const id) <disabled> {}

public CBasePlayer_Spawn_Post(const id) <enabled> {
	if(!is_user_authorized(id) || !is_user_connected(id)) {
		return;
	}

	Show_HudInformer(id);
	Show_HudLeader(id);
	return;
}

public CBasePlayer_Killed_Post(const id) <disabled> {}

public CBasePlayer_Killed_Post(const id) <enabled> {
	if(!is_user_connected(id)) {
		return;
	}

	ClearSyncHud(id, SyncHudInformer);
	return;
}

public ReGG_StartPre(const ReGG_Mode:mode) {
	state disabled;
}

public ReGG_StartPost(const ReGG_Mode:mode) { 
	state enabled;

	new players[MAX_PLAYERS], num;
	get_players(players, num, "h");

	for (new i = 0, player; i < num; i++) {
		player = players[i];
		Show_HudLeader(player);
	}
}

public ReGG_FinishPost() {
	state disabled;

	ClearSyncHud(0, SyncHudInformer);
	ClearSyncHud(0, SyncHudLeader);
}

public ReGG_PlayerJoinPost(const id) <disabled> {}

public ReGG_PlayerJoinPost(const id) <enabled> {
	Show_HudLeader(id);
	Show_HudInformer(id);
}

public ReGG_PlayerPointsPost(const id) <disabled> { }

public ReGG_PlayerPointsPost(const id) <enabled> {
	Show_HudLeader(id);
	Show_HudInformer(id);
}

public ReGG_PlayerLevelPost(const id, const value) <disabled> { }

public ReGG_PlayerLevelPost(const id, const value) <enabled> {
	Show_HudLeader(id);
	Show_HudInformer(id);
}

public Show_HudLeader(const id) <disabled> {}

public Show_HudLeader(const id) <enabled> {
	if(!ShowLeader)
		return;

	if(!is_user_connected(id)) {
		return;
	}

	ClearSyncHud(id, SyncHudLeader);

	new ReGG_Mode:mode = ReGG_Mode:ReGG_GetMode();
	new playersnum = regg_get_level_playersnum();
		
	new message[312], tmp[MAX_NAME_LENGTH];
	formatex(message, charsmax(message), "%L", LANG_PLAYER, "REGG_LEADER");
	
	for(new i ;  i < informerDisplay ; ++i) {
		if(informerBitSum & (1 << i)) {
			switch(i) {
				case INF_TPL_SAMELEVEL: {
					if(!playersnum || playersnum == 1 || mode == ReGG_ModeTeam)
						tmp[0] = 0;
					else
						formatex(tmp, charsmax(tmp), " (+%d)", playersnum);
					
					replace(message, charsmax(message), informerTplKeys[i], tmp);
				}
				case INF_TPL_LEADER: {
					new lastLeader = regg_get_last_leader();

					if(mode == ReGG_ModeTeam) {
						if(playersnum > 1) {
							formatex(tmp, charsmax(tmp), "%L", LANG_PLAYER, lastLeader == CT ? "REGG_TEAM_LEADER_CT" : "REGG_TEAM_LEADER_T");
						} else {
							formatex(tmp, charsmax(tmp), "%L + %L", LANG_PLAYER, "REGG_TEAM_LEADER_CT", LANG_PLAYER, "REGG_TEAM_LEADER_T");
						}
					} else {
						formatex(tmp, charsmax(tmp), "%n", lastLeader);
					}
					replace(message, charsmax(message), informerTplKeys[i], tmp);
				}
				case INF_TPL_LWEAPON: {
					new titleLeader[MAX_NAME_LENGTH];
					new leadersLevel = regg_get_leader_level();
					ReGG_GetLevelTitle(leadersLevel, titleLeader, charsmax(titleLeader));
					formatex(tmp, charsmax(tmp), "%s", titleLeader);
					replace(message, charsmax(message), informerTplKeys[i], tmp);
				} 
			}
		}
	}
	
	set_hudmessage(leaderColor[red], leaderColor[green], leaderColor[blue], leaderPos[x], leaderPos[y], 0, 0.0, MaxHudHoldTime, 0.1, 0.1, -1);
	ShowSyncHudMsg(id, SyncHudLeader, message);
		
	return;
}

public Show_HudInformer(const id) <disabled> {}

public Show_HudInformer(const id) <enabled> {
	if(!ShowInformer)
		return;

	if(!is_user_connected(id)) {
		return;
	}

	ClearSyncHud(id, SyncHudInformer);

	new ReGG_Mode:mode = ReGG_Mode:ReGG_GetMode();
	new points = ReGG_GetPoints(id);
	new level = ReGG_GetLevel(id);
	new levelMax = ReGG_GetLevelMax();
	new levelPoints = ReGG_GetPlayerLevelPoints(id);
	new playersnum = regg_get_level_playersnum();
	new title[MAX_NAME_LENGTH];
	ReGG_GetLevelTitle(level, title, charsmax(title));

	if(!is_user_alive(id))
		return;
		
	new message[312], tmp[MAX_NAME_LENGTH];
	formatex(message, charsmax(message), "%L", LANG_PLAYER, "REGG_INFORMER");
	
	for(new i ;  i < informerDisplay ; ++i) {
		if(informerBitSum & (1 << i)) {
			switch(i) {
				case INF_TPL_WEAPON: replace(message, charsmax(message), informerTplKeys[i], title);
				case INF_TPL_LEVEL: {
					num_to_str(level + 1, tmp, charsmax(tmp));
					replace(message,charsmax(message), informerTplKeys[i], tmp);
				}
				case INF_TPL_MAXLEVEL: {
					num_to_str(levelMax, tmp, charsmax(tmp));
					replace(message, charsmax(message), informerTplKeys[i], tmp);
				}case INF_TPL_SAMELEVEL: {
					if(!playersnum || playersnum == 1 || mode == ReGG_ModeTeam)
						tmp[0] = 0;
					else
						formatex(tmp, charsmax(tmp), " (+%d)", playersnum);
					
					replace(message, charsmax(message), informerTplKeys[i], tmp);
				}
				case INF_TPL_POINTS: {
					num_to_str(points, tmp, charsmax(tmp));
					replace(message, charsmax(message), informerTplKeys[i], tmp);
				}
				case INF_TPL_NEEDPOINTS: {
					num_to_str(levelPoints, tmp, charsmax(tmp));
					replace(message, charsmax(message), informerTplKeys[i], tmp);
				}
				case INF_TPL_LEADER: {
					new lastLeader = regg_get_last_leader();
					if(mode == ReGG_ModeTeam) {
						if(playersnum > 1) {
							formatex(tmp, charsmax(tmp), "%L", LANG_PLAYER, lastLeader == CT ? "REGG_TEAM_LEADER_CT" : "REGG_TEAM_LEADER_T");
						} else {
							formatex(tmp, charsmax(tmp), "%L + %L", LANG_PLAYER, "REGG_TEAM_LEADER_CT", LANG_PLAYER, "REGG_TEAM_LEADER_T");
						}
					} else {
						formatex(tmp, charsmax(tmp), "%n", lastLeader);
					}
					replace(message, charsmax(message), informerTplKeys[i], tmp);
				}
				case INF_TPL_LWEAPON: {
					new titleLeader[MAX_NAME_LENGTH];
					new leadersLevel = regg_get_leader_level();
					ReGG_GetLevelTitle(leadersLevel, titleLeader, charsmax(titleLeader));
					formatex(tmp, charsmax(tmp), "%s", titleLeader);
					replace(message, charsmax(message), informerTplKeys[i], tmp);
				} 
			}
		}
	}
	
	set_hudmessage(informerColor[red], informerColor[green], informerColor[blue], informerPos[x], informerPos[y], 0, 0.0, MaxHudHoldTime, 0.1, 0.1, -1);
	ShowSyncHudMsg(id, SyncHudInformer, message);
		
	return;
}

regg_get_leader_level() {
	new ReGG_Mode:mode = ReGG_Mode:ReGG_GetMode();
	new leadersLevel = 0;

	if(mode == ReGG_ModeTeam) {
		new lvlCT = ReGG_GetTeamLevel(ReGG_SlotCT);
		new lvlT = ReGG_GetTeamLevel(ReGG_SlotT);

		if(lvlCT > lvlT) {
			leadersLevel = lvlCT;
		} else {
			leadersLevel = lvlT;
		}
	} else {
		new players[MAX_PLAYERS], num, player, i;
		new levels[MAX_PLAYERS + 1];

		get_players(players, num, "ch");

		for(i = 0; i < num; i++) {
			player = players[i];
			levels[player] = ReGG_GetLevel(player);
			if(levels[player] > leadersLevel) {
				leadersLevel = levels[player];
			}
		}
	}

	if(leadersLevel <= 0)
		return 0;	

	return leadersLevel;
}

regg_get_level_playersnum() {
	new ReGG_Mode:mode = ReGG_Mode:ReGG_GetMode();
	new leadersNum = 0;
	new leadersLevel = 0;

	if(mode == ReGG_ModeTeam) {
		new lvlCT = ReGG_GetTeamLevel(ReGG_SlotCT);
		new lvlT = ReGG_GetTeamLevel(ReGG_SlotT);

		if(lvlCT == lvlT) {
			leadersNum = 2;
		} else {
			leadersNum = 1;
		}
	} else {
		new players[MAX_PLAYERS], num, player, i;
		new levels[MAX_PLAYERS + 1];
		leadersLevel = regg_get_leader_level();
		get_players(players, num, "ch");

		for(i = 0; i < num; i++) {
			player = players[i];
			levels[player] = ReGG_GetLevel(player);
			if(levels[player] >= leadersLevel) {
				leadersNum++;
			}
		}
	}

	return leadersNum;
}

regg_get_last_leader() {
	new ReGG_Mode:mode = ReGG_Mode:ReGG_GetMode();
	new lastLeader = 0;
	new leadersLevel = 0;
		
	if(mode == ReGG_ModeTeam) {
		new lvlCT = ReGG_GetTeamLevel(ReGG_SlotCT);
		new lvlT = ReGG_GetTeamLevel(ReGG_SlotT);

		if(lvlCT > lvlT) {
			lastLeader = CT;
		} else if (lvlT > lvlCT) {
			lastLeader = TT;
		}
	} else {
		new players[MAX_PLAYERS], num, player, i;
		new levels[MAX_PLAYERS + 1];
		leadersLevel = regg_get_leader_level();
		get_players(players, num, "ch");

		for(i = 0; i < num; i++) {
			player = players[i];
			levels[player] = ReGG_GetLevel(player);
			if(levels[player] >= leadersLevel) {
				lastLeader = player;
			}
		}
	}

	return lastLeader;
}

registerCvars() {
	bind_pcvar_num(create_cvar(
		"regg_show_informer", "1",
		.has_min = true, .min_val = 0.0, 
		.has_max = true, .max_val = 1.0
	), ShowInformer);

	if(ShowInformer) {
		new informerText[312];
		formatex(informerText, charsmax(informerText), "%L", LANG_SERVER, "REGG_INFORMER");

		for(new i ; i < informerDisplay ; ++i)
			if(contain(informerText, informerTplKeys[i]) != -1)
				informerBitSum |= (1 << i);
	}

	bind_pcvar_string(create_cvar(
		"regg_show_informer_hud_color", "255 255 255"
	), cvar_buffer, charsmax(cvar_buffer));

	if(!parseColorValue(cvar_buffer, informerColor)) {
		set_fail_state("Invalid value from 'regg_show_informer_hud_color'.");
	}

	bind_pcvar_string(create_cvar(
		"regg_show_informer_hud_pos", "-1.0 0.85"
	), cvar_buffer, charsmax(cvar_buffer));

	if(!parseCoordinateValue(cvar_buffer, informerPos)) {
		set_fail_state("Invalid value from 'regg_show_informer_hud_pos'.");
	}

	bind_pcvar_num(create_cvar(
		"regg_show_leader", "1",
		.has_min = true, .min_val = 0.0, 
		.has_max = true, .max_val = 1.0
	), ShowLeader);

	if(ShowInformer) {
		new informerText[312];
		formatex(informerText, charsmax(informerText), "%L", LANG_SERVER, "REGG_LEADER");

		for(new i ; i < informerDisplay ; ++i)
			if(contain(informerText, informerTplKeys[i]) != -1)
				informerBitSum |= (1 << i);
	}

	bind_pcvar_string(create_cvar(
		"regg_show_leader_hud_color", "255 255 255"
	), cvar_buffer, charsmax(cvar_buffer));

	if(!parseColorValue(cvar_buffer, leaderColor)) {
		set_fail_state("Invalid value from 'regg_show_leader_hud_color'.");
	}

	bind_pcvar_string(create_cvar(
		"regg_show_leader_hud_pos", "-1.0 0.05"
	), cvar_buffer, charsmax(cvar_buffer));

	if(!parseCoordinateValue(cvar_buffer, leaderPos)) {
		set_fail_state("Invalid value from 'regg_show_leader_hud_pos'.");
	}
}

bool:parseColorValue(const value[], HudColor[color_s]) {
	new color[color_s][color_s];
	if(value[0] == EOS || parseColors(value, color) != 3) {
		return false;
    }

	for(new any:i; i < sizeof HudColor; i++) {
		HudColor[i] = str_to_num(color[i]);
	}

	return true;
}

bool:parseCoordinateValue(const value[], Float:HudPos[pos_s]) {
	new coord[pos_s][6];
	if(value[0] == EOS || parseCoordinates(value, coord) != 2) {
		return false;
	}

	for(new any:i; i < sizeof HudPos; i++) {
		HudPos[i] = str_to_float(coord[i]);
	}

	return true;
}
