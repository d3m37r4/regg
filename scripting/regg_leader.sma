#pragma semicolon 1

#include <amxmodx>
#include "include/regg.inc"

const TASK_INFO_ID = 1;

// new const COMMANDS[][] = {
// 	"Террористов",
// 	"Контр-Террористов"
// };

new SyncHudStats;
new LeaderInfo[256];

public plugin_init() {
	register_plugin("[ReAPI] GunGame Leader", REGG_VERSION_STR, "F@nt0M");
	SyncHudStats = CreateHudSyncObj();
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

	set_task(1.0, "TaskInfo", TASK_INFO_ID, .flags = "b");
}

public ReGG_FinishPost() {
	state none;
	remove_task(TASK_INFO_ID);
}

public ReGG_PlayerLevelPost(const id, const value) <single> {
	checkLeaders();
}
public ReGG_PlayerLevelPost(const id, const value) <team,none> {}

public TaskInfo() {
	set_hudmessage(250, 250, 250, -1.0, 0.05, 0, 0.0, 20.0, 0.0, 0.0, -1);
	ShowSyncHudMsg(0, SyncHudStats, LeaderInfo);
}

checkLeaders() {
	new lastLeader = 0;
	new leadersNum = 0;
	new leadersLevel = 0;

	new players[MAX_PLAYERS], num, player, i;
	new levels[MAX_PLAYERS + 1];
	get_players(players, num, "h");
	for (i = 0; i < num; i++) {
		player = players[i];
		levels[player] = ReGG_GetLevel(player);
		if (levels[player] > leadersLevel) {
			leadersLevel = levels[player];
		}
	}

	if (leadersLevel <= 0) {
		return;
	}
	for (i = 0; i < num; i++) {
		player = players[i];
		if (levels[player] >= leadersLevel) {
			lastLeader = player;
			leadersNum++;
		}
	}

	if (leadersNum > 0) {
		new title[32];
		ReGG_GetLevelTitle(leadersLevel, title, charsmax(title));
		if (leadersNum > 1) {
			formatex(LeaderInfo, charsmax(LeaderInfo), "Лидер: %n + %d^nУровень %d (%s)", lastLeader, leadersNum, leadersLevel + 1, title);
		} else {
			formatex(LeaderInfo, charsmax(LeaderInfo), "Лидер: %n^nУровень %d (%s)", lastLeader, leadersLevel + 1, title);
		}
	} else {
		formatex(LeaderInfo, charsmax(LeaderInfo), "Лидер: Отсутсвует");
	}
}