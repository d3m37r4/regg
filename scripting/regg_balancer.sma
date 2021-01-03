#include <amxmodx>
#include <reapi>

new bool:BalanceTeams = false;

public plugin_init() {
	register_plugin("[ReAPI] GunGame Balancer", REGG_VERSION_STR, "F@nt0M");

	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);
	RegisterHookChain(RG_CBasePlayer_CanSwitchTeam, "CBasePlayer_CanSwitchTeam_Pre", false);
	register_event("TeamInfo", "EventTeamInfo", "a", "1>0", "2!UNASSIGNED");

	state none;
}

public CBasePlayer_Killed_Post() {
	if (BalanceTeams) {
		state balancing;
		rg_balance_teams();
		checkTeams();
		BalanceTeams = false;
		state none;
	}
}

public CBasePlayer_CanSwitchTeam_Pre(const id) {
	if (is_user_alive(id)) {
		SetHookChainReturn(ATYPE_INTEGER, 0);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public EventTeamInfo() <none> {
	BalanceTeams = checkTeams();
}

public EventTeamInfo() <balancing> {}

bool:checkTeams() {
	new numTerrorist = 0, numCT = 0;
	for (new player = 1; player <= MaxClients; player++) {
		if (is_user_connected(player) && !is_user_hltv(player)) {
			switch (TeamName:get_member(player, m_iTeam)) {
				case TEAM_TERRORIST: {
					numTerrorist++;
				}
				case TEAM_CT: {
					numCT++;
				}
			}
		}
	}
	set_member_game(m_iNumTerrorist, numTerrorist);
	set_member_game(m_iNumCT, numCT);

	return bool:(abs(numTerrorist - numCT) > 1);
}

// register_event("TeamInfo", "EventTeamInfo", "a", "1>0", "2!UNASSIGNED");
// public EventTeamInfo() {
//     enum { arg_player = 1, arg_team };

//     new player = read_data(arg_player);
//     new teamName[10];
//     read_data(arg_team, teamName, charsmax(teamName));
//     new TeamName:team;
//     switch (teamName[0]) {
//         case 'T': {
//             team = TEAM_TERRORIST;
//         }

//         case 'C': {
//             team = TEAM_CT;
//         }

//         default: {
//             team = TEAM_SPECTATOR;
//         }
//     }

//     server_print("^t Player %n change team to %d (%s)", player, team, teamName);
// }
