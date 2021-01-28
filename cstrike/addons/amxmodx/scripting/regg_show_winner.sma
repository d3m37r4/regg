#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <regg>

public plugin_init() {
	register_plugin("[ReGG] Show Winner", REGG_VERSION_STR, "F@nt0M");
}

public ReGG_FinishPost(const killer, const victim) {
	showWinner(killer, victim);
}

showWinner(const winner, const looser) {
	new ReGG_Mode:mode = ReGG_Mode:ReGG_GetMode();

	if (mode == ReGG_ModeTeam) {
		new slotWinner = ReGG_GetPlayerSlot(winner);
		new slotLooser = ReGG_GetPlayerSlot(winner);

		client_print_color(
			0, 
			slotWinner == ReGG_SlotT ? print_team_red : print_team_blue, 
			"%L %L %L^1!!!", 
			LANG_PLAYER, "REGG_PREFIX", 
			LANG_PLAYER, "REGG_SHOW_WINNER_TEAM",
			LANG_PLAYER, slotWinner == ReGG_SlotT ? "REGG_TEAM_T" : "REGG_TEAM_CT"
		);
		client_print_color(
			0, 
			slotLooser == ReGG_SlotT ? print_team_red : print_team_blue, 
			"%L %L", 
			LANG_PLAYER, "REGG_PREFIX", 
			LANG_PLAYER, "REGG_SHOW_LOOSER",
			looser
		);
	} else if(mode == ReGG_ModeSingle){
		client_print_color(
			0, 
			print_team_default, 
			"%L %L^1!!!", 
			LANG_PLAYER, "REGG_PREFIX", 
			LANG_PLAYER, "REGG_SHOW_WINNER" 
		);
		client_print_color(
			0, 
			print_team_default, 
			"%L %L", 
			LANG_PLAYER, "REGG_PREFIX", 
			LANG_PLAYER, "REGG_SHOW_LOOSER",
			looser
		);
	} else {
		client_print_color(
			0, 
			print_team_default, 
			"%L %L %L^1!!!", 
			LANG_PLAYER, "REGG_PREFIX", 
			LANG_PLAYER, "REGG_SHOW_WINNER_FFA",
			winner
		);
		client_print_color(
			0, 
			print_team_default, 
			"%L %L", 
			LANG_PLAYER, "REGG_PREFIX", 
			LANG_PLAYER, "REGG_SHOW_LOOSER_FFA",
			looser
		);
	}
}
