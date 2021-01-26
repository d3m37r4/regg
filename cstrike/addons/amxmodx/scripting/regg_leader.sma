#pragma semicolon 1

#include <amxmodx>
#include <regg>

const TASK_INFO_ID = 1;

new SyncHudStats;
new LeaderInfo[256];

public plugin_init() {
	register_plugin("[ReGG] Leader", REGG_VERSION_STR, "F@nt0M");
	SyncHudStats = CreateHudSyncObj();
	state none;
}

public ReGG_StartPost(const ReGG_Mode:mode) {
	switch(mode) {
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

public ReGG_TeamLevelPost(const slot, const value) <team> {
	checkLeaders();
}
public ReGG_TeamLevelPost(const slot, const value) <single,none> {}

public TaskInfo() {
	set_hudmessage(250, 250, 250, -1.0, 0.05, 0, 0.0, 20.0, 0.0, 0.0, -1);
	ShowSyncHudMsg(0, SyncHudStats, LeaderInfo);
}

checkLeaders() {
	new ReGG_Mode:mode = ReGG_Mode:ReGG_GetMode();
	new lastLeader = 0;
	new lastTeamLeader = 0;
	new leadersNum = 0;
	new leadersLevel = 0;
	new CT, TT;

	if(mode == ReGG_ModeTeam) {
		new lvlCT = ReGG_GetTeamLevel(ReGG_SlotCT);
		new lvlT = ReGG_GetTeamLevel(ReGG_SlotT);

		if(lvlCT > lvlT) {
			leadersNum = 1;
			leadersLevel = lvlCT;
			lastTeamLeader = CT;
		} else if (lvlT > lvlCT) {
			leadersNum = 1;
			leadersLevel = lvlT;
			lastTeamLeader = TT;
		} else {
			leadersNum = 2;
			leadersLevel = lvlCT;
		}
		
		if(leadersLevel <= 0) {
			return;
		}
	} else {
		new players[MAX_PLAYERS], num, player, i;
		new levels[MAX_PLAYERS + 1];
		get_players(players, num, "h");
		for(i = 0; i < num; i++) {
			player = players[i];
			levels[player] = ReGG_GetLevel(player);
			if(levels[player] > leadersLevel) {
				leadersLevel = levels[player];
			}
		}

		if(leadersLevel <= 0) {
			return;
		}

		for(i = 0; i < num; i++) {
			player = players[i];
			if(levels[player] >= leadersLevel) {
				lastLeader = player;
				leadersNum++;
			}
		}
	}
	if(leadersNum > 0) {
		new titleLeader[32];
		ReGG_GetLevelTitle(leadersLevel, titleLeader, charsmax(titleLeader));
		if(leadersNum > 1) {
			if(mode == ReGG_ModeTeam) {
				formatex(LeaderInfo, charsmax(LeaderInfo), "%L %L + %L  [ %s ]", LANG_PLAYER, "REGG_LEADER", LANG_PLAYER, "REGG_TEAM_LEADER_CT", LANG_PLAYER, "REGG_TEAM_LEADER_T", titleLeader);
			} else {
				formatex(LeaderInfo, charsmax(LeaderInfo), "%L %n + (%d) [ %s ]", LANG_PLAYER, "REGG_LEADER", lastLeader, leadersNum, titleLeader);
			}
		} else {
			if(mode == ReGG_ModeTeam) {
				formatex(LeaderInfo, charsmax(LeaderInfo), "%L %L [ %s ]", LANG_PLAYER, "REGG_LEADER",  LANG_PLAYER, lastTeamLeader == CT ? "REGG_TEAM_LEADER_CT" : "REGG_TEAM_LEADER_T", titleLeader);
			} else {
				formatex(LeaderInfo, charsmax(LeaderInfo), "%L %n [ %s ]", LANG_PLAYER, "REGG_LEADER", lastLeader, titleLeader);
			}
		}
	} else {
			formatex(LeaderInfo, charsmax(LeaderInfo), "%L", LANG_PLAYER, "REGG_NO_LEADER");
	}
}