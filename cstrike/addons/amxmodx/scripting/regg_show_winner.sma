#pragma semicolon 1

#include <amxmodx>
#include <regg>

enum color_s {
	red,
	green,
	blue,
};
new HudColor[color_s];

enum pos_s {
	Float:x,
	Float:y,
};
new Float:HudPos[pos_s];

enum {
	ShowWinnerType_Chat,
	ShowWinnerType_Hud,	
};
new ShowWinnerType;

new HudWinnerTime;
new SyncHud;

#define parseColors(%1,%2) parse(%1, %2[red], charsmax(%2[]), %2[green], charsmax(%2[]), %2[blue], charsmax(%2[]))
#define parseCoordinates(%1,%2) parse(%1, %2[x], charsmax(%2[]), %2[y], charsmax(%2[]))

public plugin_init() {
	register_plugin("[ReGG] Show Winner", REGG_VERSION_STR, "Jumper & d3m37r4");
	
	bind_pcvar_num(create_cvar(
		"regg_show_winner", "0",
		.has_min = true, .min_val = 0.0,
		.has_max = true, .max_val = 1.0
	), ShowWinnerType);
	
	bind_pcvar_num(create_cvar(
		"regg_show_winner_time", "10",
		.has_min = true, .min_val = 5.0
	), HudWinnerTime);

	new buffer[12];
	bind_pcvar_string(create_cvar(
		"regg_show_winner_hud_color", "255 255 255"
	), buffer, charsmax(buffer));

	if(!parseColorValue(buffer)) {
		set_fail_state("Invalid value from 'regg_show_winner_hud_color'.");
	}

	bind_pcvar_string(create_cvar(
		"regg_show_winner_hud_pos", "-1.0 0.65"
	), buffer, charsmax(buffer));

	if(!parseCoordinateValue(buffer)) {
		set_fail_state("Invalid value from 'regg_show_winner_hud_pos'.");
	}

	SyncHud = CreateHudSyncObj();
}

public ReGG_FinishPost(const killer, const victim) {
	showWinner(killer, victim);
}

showWinner(const winner, const looser) {
	new buffer[512], print_type;
	new ReGG_Mode:mode = ReGG_Mode:ReGG_GetMode();
	new slot = ReGG_GetPlayerSlot(winner);

	if(ShowWinnerType == ShowWinnerType_Chat) {
		if(mode == ReGG_ModeTeam) {
			print_type = (slot == ReGG_SlotT) ? print_team_red : print_team_blue;

			formatex(buffer, charsmax(buffer), 
				"%L %L %L^1!", LANG_PLAYER, "REGG_PREFIX", 
				LANG_PLAYER, "REGG_SHOW_WINNER_TEAM", 
				LANG_PLAYER, slot == ReGG_SlotT ? "REGG_TEAM_T" : "REGG_TEAM_CT"
			);
		} else {
			print_type = print_team_default;

			formatex(buffer, charsmax(buffer), 
				"%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER,
				mode == ReGG_ModeSingle ? "REGG_SHOW_WINNER" : "REGG_SHOW_WINNER_FFA", winner
			);	
		}

		client_print_color(0, print_type, buffer);
		client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "REGG_PREFIX", LANG_PLAYER, "REGG_SHOW_LOOSER", winner);
	}

	if(ShowWinnerType == ShowWinnerType_Hud) {
		if(mode == ReGG_ModeTeam) {
			formatex(buffer, charsmax(buffer), 
				"%L", LANG_PLAYER, "REGG_SHOW_WINNER_HUD_TEAM", 
				fmt("%L", LANG_PLAYER, slot == ReGG_SlotT ? "REGG_TEAM_T" : "REGG_TEAM_CT"), looser
			);
		} else {
			formatex(buffer, charsmax(buffer), "%L", LANG_PLAYER, "REGG_SHOW_WINNER_HUD", winner, looser);
		}

		set_hudmessage(HudColor[red], HudColor[green], HudColor[blue], HudPos[x], HudPos[y], .holdtime = float(HudWinnerTime));
		ShowSyncHudMsg(0, SyncHud, buffer);
	}
}

bool:parseColorValue(const value[]) {
    new color[color_s][color_s];
    if(value[0] == EOS || parseColors(value, color) != 3) {
    	return false;
    }

    for(new any:i; i < sizeof HudColor; i++) {
        HudColor[i] = str_to_num(color[i]);
    }

    return true;
}

bool:parseCoordinateValue(const value[]) {
    new coord[pos_s][6];
    if(value[0] == EOS || parseCoordinates(value, coord) != 2) {
    	return false;
    }

    for(new any:i; i < sizeof HudPos; i++) {
        HudPos[i] = str_to_float(coord[i]);
    }

    return true;
}
