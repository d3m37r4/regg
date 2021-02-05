#pragma semicolon 1

#include <amxmodx>
#include <regg>

#define MAX_LENGTH 15

enum color {
	R,
	G,
	B
};

enum pos {
	Float:X,
	Float:Y
};

new SyncszWinnerMsg, ShowWinnerType, HudWinnerColor[MAX_LENGTH], HudWinnerPos[MAX_LENGTH], HudWinnerTime;
new HudColor[color], Float:HudPos[pos];

public plugin_init() {
	register_plugin("[ReGG] Show Winner", REGG_VERSION_STR, "Jumper & d3m37r4");
	
	SyncszWinnerMsg = CreateHudSyncObj();
	
	bind_pcvar_num(create_cvar(
		"regg_show_winner", "0",
		.has_min = true, .min_val = 0.0,
		.has_max = true, .max_val = 1.0
	), ShowWinnerType);
	
	bind_pcvar_string(create_cvar(
		"regg_show_winner_hud_color", "255 255 255"
	), HudWinnerColor, charsmax(HudWinnerColor));
	
	bind_pcvar_string(create_cvar(
		"regg_show_winner_hud_pos", "-1.0 0.65"
	), HudWinnerPos, charsmax(HudWinnerPos));
	
	bind_pcvar_num(create_cvar(
		"regg_show_winner_time", "10",
		.has_min = true, .min_val = 5.0
	), HudWinnerTime);
}

public plugin_cfg() {
	new sColor[color][4], sPos[pos][6];
	if(parse(HudWinnerColor, sColor[R], charsmax(sColor[]), sColor[G], charsmax(sColor[]), sColor[B], charsmax(sColor[])) == 3) {
		HudColor[R] = str_to_num(sColor[R]);
		HudColor[G] = str_to_num(sColor[G]);
		HudColor[B] = str_to_num(sColor[B]);
	}
	if(parse(HudWinnerPos, sPos[X], charsmax(sPos[]), sPos[Y], charsmax(sPos[])) == 2) {
		HudPos[X] = str_to_float(sPos[X]);
		HudPos[Y] = str_to_float(sPos[Y]);
	}
}

public ReGG_FinishPost(const killer, const victim) {
	showWinner(killer, victim);
}

showWinner(const winner, const looser) {
	new ReGG_Mode:mode = ReGG_Mode:ReGG_GetMode();
	new slotWinner = ReGG_GetPlayerSlot(winner);
	new szWinnerMsg[191], szHudMsg[256];
	if(ShowWinnerType == 0) {
		switch(mode) {
			case ReGG_ModeTeam: {
				formatex(szWinnerMsg, charsmax(szWinnerMsg), "%L %L %L^1!!!", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_SHOW_WINNER_TEAM", LANG_PLAYER, slotWinner == ReGG_SlotT ? "REGG_TEAM_T" : "REGG_TEAM_CT");
				client_print_color(0, slotWinner == ReGG_SlotT ? print_team_red : print_team_blue, szWinnerMsg);
			}
			case ReGG_ModeSingle: {
				formatex(szWinnerMsg, charsmax(szWinnerMsg), "%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_SHOW_WINNER", winner);
			}
			case ReGG_ModeFFA: {
				formatex(szWinnerMsg, charsmax(szWinnerMsg), "%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_SHOW_WINNER_FFA", winner);
			}
		}
		if(mode != ReGG_ModeTeam) {
			client_print_color(0, print_team_default, szWinnerMsg);
		}
		client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_SHOW_LOOSER", winner);
	} else if(ShowWinnerType == 1) {
		if(mode == ReGG_ModeTeam) {
			formatex(szHudMsg, charsmax(szHudMsg), "%L", LANG_PLAYER, "REGG_SHOW_WINNER_HUD_TEAM", fmt("%L", LANG_PLAYER, slotWinner == ReGG_SlotT ? "REGG_TEAM_T" : "REGG_TEAM_CT"), looser);
		} else {
			formatex(szHudMsg, charsmax(szHudMsg), "%L", LANG_PLAYER, "REGG_SHOW_WINNER_HUD", winner, looser);
		}

		set_hudmessage(HudColor[R], HudColor[G], HudColor[B], HudPos[X], HudPos[Y], .holdtime = float(HudWinnerTime));
		ShowSyncHudMsg(0, SyncszWinnerMsg, szHudMsg);
	}
}
