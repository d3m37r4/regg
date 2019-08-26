#include <amxmodx>
#include "include/regg.inc"

const TASK_INFO_ID = 1;

new SyncHudStats;

public plugin_init() {
	register_plugin("[ReAPI] GunGame Informer", "0.1.0-alpha", "F@nt0M");
	SyncHudStats = CreateHudSyncObj();
}

public ReGG_Started() {
	set_task(1.0, "TaskInfo", TASK_INFO_ID, .flags = "b");
}

public ReGG_Finished() {
	remove_task(TASK_INFO_ID);
}

public TaskInfo() {
	new players[MAX_PLAYERS], num;
	get_players(players, num, "ach");

	set_hudmessage(250, 250, 250, -1.0, 0.85, 0, 0.0, 20.0, 0.0, 0.0, -1);
	for (new i = 0, level, points, levelPoints; i < num; i++) {
		level = ReGG_GetLevel(players[i]);
		points = ReGG_GetPoints(players[i]);
		levelPoints = ReGG_GetLevelPoints(players[i], level);
		ShowSyncHudMsg(players[i], SyncHudStats, "Level: %d^nKills: %d/%d", level + 1, points, levelPoints);
	}
}
