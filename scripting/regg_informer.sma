#include <amxmodx>
#include <reapi>
#include "include/regg.inc"

const TASK_INFO_ID = 1;

new SyncHudStats;

public plugin_init() {
	register_plugin("[ReAPI] GunGame Informer", "0.1.0-alpha", "F@nt0M");
	SyncHudStats = CreateHudSyncObj();
}

public plugin_precache() {
	precache_sound("buttons/bell1.wav");
	precache_sound("sound/gungame/gg_levelup.wav");
	precache_sound("sound/ambience/xtal_down1.wav");
}

// new ReGG_Mode:Mode;
// new bool:NadeLevelAnnounced = false;
// new bool:KnifeLevelAnnounced = false;

public ReGG_StartPost(const ReGG_Mode:mode) {
	// Mode = mode;
	set_task(1.0, "TaskInfo", TASK_INFO_ID, .flags = "b");
}

public ReGG_FinishPost() {
	remove_task(TASK_INFO_ID);
}

public ReGG_KillEnemyPost(const killer, const victim, const WeaponIdType:value, const ReGG_Result:result) {
	switch (result) {
		case ReGG_ResultPointsUp: {
			client_cmd(killer, "spk ^"%s^"", "buttons/bell1.wav");
		}
		case ReGG_ResultPointsDown: {
			// client_cmd(id, "spk ^"%s^"", "sound/gungame/gg_levelup.wav");
		}

		case ReGG_ResultLevelUp: {
			client_cmd(killer, "spk ^"%s^"", "sound/gungame/gg_levelup.wav");
		}

		case ReGG_ResultLevelDown: {
			client_cmd(killer, "spk ^"%s^"", "sound/ambience/xtal_down1(e70)");
		}
	}
}

public TaskInfo() {
	new players[MAX_PLAYERS], num;
	get_players(players, num, "ach");

	set_hudmessage(250, 250, 250, -1.0, 0.85, 0, 0.0, 20.0, 0.0, 0.0, -1);
	for (new i = 0, player, level, points, levelPoints, title[32]; i < num; i++) {
		player = players[i];
		points = ReGG_GetPoints(player);
		level = ReGG_GetLevel(player);
		levelPoints = ReGG_GetPlayerLevelPoints(player);
		ReGG_GetLevelTitle(level, title, charsmax(title));
		ShowSyncHudMsg(players[i], SyncHudStats, "Level: %d (%s)^nKills: %d/%d", level + 1, title, points, levelPoints);
	}
}
