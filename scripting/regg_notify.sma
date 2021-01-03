#include <amxmodx>
#include "include/regg.inc"

new const COMMANDS[][] = {
	"Террористов",
	"Контр-Террористов"
};

public plugin_precache() {
	precache_sound("buttons/bell1.wav");
	precache_sound("sound/gungame/gg_levelup.wav");
	precache_sound("sound/ambience/xtal_down1.wav");
}

public plugin_init() {
    register_plugin("[ReAPI] GunGame Notify", REGG_VERSION_STR, "F@nt0M");
    state none;
}

public ReGG_StartPost(const ReGG_Mode:mode) {
	switch (mode) {
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
}

public ReGG_KillEnemyPost(const killer, const victim, const WeaponIdType:value, const ReGG_Result:result) <single> {
	switch (result) {
		case ReGG_ResultPointsUp: {
			client_cmd(killer, "spk ^"%s^"", "buttons/bell1.wav");
		}

		case ReGG_ResultPointsDown: {}

		case ReGG_ResultLevelUp: {
			client_cmd(killer, "spk ^"%s^"", "sound/gungame/gg_levelup.wav");

			new level = ReGG_GetLevel(killer);
			new title[32];
			ReGG_GetLevelTitle(level, title, charsmax(title));
			client_print_color(killer, print_team_default, "^3Вы ^4поднялись ^1на ^4%d ^1[^4%s^1] уровень.", level + 1, title);
		}

		case ReGG_ResultLevelDown: {
			client_cmd(killer, "spk ^"%s^"", "sound/ambience/xtal_down1(e70)");
			new level = ReGG_GetLevel(killer);
			new title[32];
			ReGG_GetLevelTitle(level, title, charsmax(title));
			client_print_color(killer, print_team_default, "^3Вы ^4опустились ^1на ^4%d ^1[^4%s^1] уровень.", level + 1, title);
		}
	}
}
public ReGG_KillEnemyPost(const killer, const victim, const WeaponIdType:value, const ReGG_Result:result) <team> {
	if (result == ReGG_ResultPointsUp) {
		client_cmd(killer, "spk ^"%s^"", "buttons/bell1.wav");
	}
}

public ReGG_KillEnemyPost(const killer, const victim, const WeaponIdType:value, const ReGG_Result:result) <none> {}

new oldTeamLevel;
public ReGG_TeamLevelPre(const slot, const value) {
	oldTeamLevel = ReGG_GetTeamLevel(slot);
}

public ReGG_TeamLevelPost(const slot, const value) {
	if (oldTeamLevel != value) {
		notifyTeam(slot, value, oldTeamLevel < value ? ReGG_ResultLevelUp : ReGG_ResultLevelDown);
	}
}


notifyTeam(const slot, const level, const ReGG_Result:result) {
	new title[32];
	ReGG_GetLevelTitle(level, title, charsmax(title));

	new players[MAX_PLAYERS], num;
	get_players(players, num, "ch");
	for (new i = 0, player, playerSlot; i < num; i++) {
		player = players[i];
		playerSlot = ReGG_GetPlayerSlot(player);
		if (playerSlot == ReGG_SlotInvalid) {
			continue;
		}

		switch (result) {
			case ReGG_ResultLevelUp: {
				if (playerSlot == slot) {
					client_cmd(player, "spk ^"%s^"", "sound/gungame/gg_levelup.wav");
					client_print_color(player, print_team_default, "^3Ваша ^1команда ^4поднялась ^1на ^4%d ^1[^4%s^1] уровень.", level + 1, title);
				} else {
					client_print_color(
						player, slot == ReGG_SlotT ? print_team_red : print_team_blue,
						"^1Команда ^4%s ^4поднялась ^1на ^4%d ^1[^4%s^1] уровень.", COMMANDS[slot], level + 1, title
					);
				}
			}

			case ReGG_ResultLevelDown: {
				if (playerSlot == slot) {
					client_cmd(player, "spk ^"%s^"", "sound/ambience/xtal_down1(e70)");
					client_print_color(player, print_team_default, "^3Ваша ^1команда ^4опустилась ^1на ^4%d ^1[^4%s^1] уровень.", level + 1, title);
				} else {
					client_print_color(
						player, slot == ReGG_SlotT ? print_team_red : print_team_blue,
						"^1Команда ^4%s ^4опустилась ^1на ^4%d ^1[^4%s^1] уровень.", COMMANDS[slot], level + 1, title
					);
				}
			}
		}
	}
}
