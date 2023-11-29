#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <regg>

#if !defined MAX_MAPNAME_LENGTH
	#define MAX_MAPNAME_LENGTH 64
#endif

#define rg_get_user_team(%0) get_member(%0, m_iTeam)

new const STYLES_URL[] = "http://localhost/regungame.css";

public plugin_init() {
	register_plugin("[ReGG] MOTD", REGG_VERSION_STR, "Jumper & d3m37r4");
}

public ReGG_FinishPost(const killer, const victim) {
	showMotd(killer, victim);
}

showMotd(const winner, const looser) {
	new nextMap[MAX_MAPNAME_LENGTH], teamWinner[MAX_NAME_LENGTH];
	get_cvar_string("amx_nextmap", nextMap, charsmax(nextMap));

	new ReGG_Mode:mode = ReGG_Mode:ReGG_GetMode();

	new winnerClassName[3], looserClassName[3];
	getTeamClassname(winner, winnerClassName, charsmax(winnerClassName));
	getTeamClassname(looser, looserClassName, charsmax(looserClassName));

	if (mode == ReGG_ModeTeam) {
		formatex(teamWinner, charsmax(teamWinner), "%L", LANG_PLAYER, rg_get_user_team(winner) == TEAM_CT ? "REGG_TEAM_CT" : "REGG_TEAM_T");
	}

	new motd[MAX_MOTD_LENGTH];
	new len = formatex(
		motd, charsmax(motd), 
		"<!DOCTYPE html>^n<html><head><meta charset=^"utf-8^"><link rel=^"stylesheet^" href=^"%s^"></head>",
		STYLES_URL
	);

	len += formatex(motd[len], charsmax(motd) - len, "<body><h3>[GUNGAME]</h3>");

	if (mode == ReGG_ModeTeam) {
		len += formatex(
			motd[len], charsmax(motd) - len,
			"<hr class=^"%s^"><div class=^"%s^">Команда <span class=^"name^">%s</span> победила!</div>",
			winnerClassName, winnerClassName, teamWinner
		);
	} else {
		len += formatex(
			motd[len], charsmax(motd) - len,
			"<hr class=^"%s^"><div class=^"%s^"><span class=^"name^">%n</span> победил!</div>",
			winnerClassName, winnerClassName, winner
		);
	}

	len += formatex(
		motd[len], charsmax(motd) - len,
		"<hr class=^"%s^"><div class=^"%s^">Последним был убит: <span class=^"name^">%n</span></div>",
		winnerClassName, looserClassName, looser
	);
	
	len += formatex(
		motd[len], charsmax(motd) - len,
		"<hr class=^"%s^"><div>Следующая карта: <span class=^"map^">%s</span></div>",
		winnerClassName, nextMap
		);

	formatex(motd[len], charsmax(motd) - len, "</body></html>");

	new players[MAX_PLAYERS], num;
	get_players(players, num, "ch");
	for (new i = 0; i < num; i++) {
		show_motd(players[i], motd, "GunGame");
	}
}

getTeamClassname(const id, buffer[], const len) {
	switch (rg_get_user_team(id)) {
		case TEAM_TERRORIST: return copy(buffer, len, "tt");
		case TEAM_CT: return copy(buffer, len, "сt");
	}
	return 0;
}
