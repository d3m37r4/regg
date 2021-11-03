#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <regg>

const TASK_INFO_ID = 1;

new SyncHudStats;
new PlayerInfos[MAX_PLAYERS + 1][256];

public plugin_init() {
	register_plugin("[ReGG] Informer", REGG_VERSION_STR, "Jumper & d3m37r4");
	SyncHudStats = CreateHudSyncObj();
	state disabled;
}

public client_putinserver(id) {
	arrayset(PlayerInfos[id], EOS, sizeof(PlayerInfos[]));
}

public ReGG_StartPost(const ReGG_Mode:mode) {
	state enabled;
	set_task(1.0, "TaskInfo", TASK_INFO_ID, .flags = "b");
}

public ReGG_FinishPost() {
	state disabled;
	remove_task(TASK_INFO_ID);
	ClearSyncHud(0, SyncHudStats);
}

public ReGG_PlayerJoinPost(const id) <enabled> {
	makeInfoString(id);
}
public ReGG_PlayerJoinPost(const id) <disabled> {}

public ReGG_PlayerPointsPost(const id) <enabled> {
	makeInfoString(id);
}
public ReGG_PlayerPointsPost(const id) <disabled> {}

public ReGG_PlayerLevelPost(const id, const value) <enabled> {
	makeInfoString(id);
}
public ReGG_PlayerLevelPost(const id) <disabled> {}

public TaskInfo() {
	new players[MAX_PLAYERS], num;
	get_players(players, num, "ach");

	set_hudmessage(250, 250, 250, -1.0, 0.85, 0, 0.0, 20.0, 0.0, 0.0, -1);
	for (new i = 0, player; i < num; i++) {
		player = players[i];
		if (PlayerInfos[player][0] == EOS) {
			makeInfoString(player);
		}
		ShowSyncHudMsg(players[i], SyncHudStats, PlayerInfos[player]);
	}
}

makeInfoString(const id) {
	new points = ReGG_GetPoints(id);
	new level = ReGG_GetLevel(id);
	new levelMax = ReGG_GetLevelMax();
	new levelPoints = ReGG_GetPlayerLevelPoints(id);
	new title[32];
	ReGG_GetLevelTitle(level, title, charsmax(title));

	formatex(PlayerInfos[id], charsmax(PlayerInfos[]), "%L", LANG_PLAYER, "REGG_INFORMER", title, level + 1, levelMax, points, levelPoints);
}
