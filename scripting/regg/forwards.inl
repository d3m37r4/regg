#if defined _regg_forwards_included
	#endinput
#endif

#define _regg_forwards_included

#define REGISTER_FORWARD(%1,%2,%3) \
	Forwards[%1][FWD_Pre] = CreateMultiForward(%2, ET_STOP); \
	Forwards[%1][FWD_Post] = CreateMultiForward(%3, ET_IGNORE)

#define REGISTER_FORWARD_ARGS(%1,%2,%3,%4) \
	Forwards[%1][FWD_Pre] = CreateMultiForward(%2, ET_STOP, %4); \
	Forwards[%1][FWD_Post] = CreateMultiForward(%3, ET_IGNORE, %4)

#define EXECUTE_FORWARD_PRE(%1,%2) \
	ExecuteForward(Forwards[%1][FWD_Pre], FReturn); \
	if (FReturn == PLUGIN_HANDLED) return %2

#define EXECUTE_FORWARD_PRE_ARGS(%1,%2,%3) \
	ExecuteForward(Forwards[%1][FWD_Pre], FReturn, %3); \
	if (FReturn == PLUGIN_HANDLED) return %2

#define EXECUTE_FORWARD_POST(%1) \
	ExecuteForward(Forwards[%1][FWD_Post], FReturn)

#define EXECUTE_FORWARD_POST_ARGS(%1,%2) \
	ExecuteForward(Forwards[%1][FWD_Post], FReturn, %2)

enum {
	FWD_Pre,
	FWD_Post,
};

enum Forward {
	FWD_Start,
	FWD_Finish,
	FWD_PlayerPoints,
	FWD_TeamPoints,
	FWD_PlayerLevel,
	FWD_TeamLevel,
	FWD_GiveWeapon,
	FWD_KillEnemy,
	FWD_PlayerJoin,
};

new Forwards[Forward][2], FReturn;

registerForwards() {
	REGISTER_FORWARD_ARGS(FWD_Start, "ReGG_StartPre", "ReGG_StartPost", FP_CELL);
	REGISTER_FORWARD(FWD_Finish, "ReGG_FinishPre", "ReGG_FinishPost");
	REGISTER_FORWARD_ARGS(FWD_PlayerPoints, "ReGG_PlayerPointsPre", "ReGG_PlayerPointsPost", FP_CELL, FP_CELL);
	REGISTER_FORWARD_ARGS(FWD_TeamPoints, "ReGG_TeamPointsPre", "ReGG_TeamPointsPost", FP_CELL, FP_CELL);
	REGISTER_FORWARD_ARGS(FWD_PlayerLevel, "ReGG_PlayerLevelPre", "ReGG_PlayerLevelPost", FP_CELL, FP_CELL);
	REGISTER_FORWARD_ARGS(FWD_TeamLevel, "ReGG_TeamLevelPre", "ReGG_TeamLevelPost", FP_CELL, FP_CELL);
	REGISTER_FORWARD_ARGS(FWD_GiveWeapon, "ReGG_GiveWeaponPre", "ReGG_GiveWeaponPost", FP_CELL, FP_CELL);
	REGISTER_FORWARD_ARGS(FWD_KillEnemy, "ReGG_KillEnemyPre", "ReGG_KillEnemyPost", FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	REGISTER_FORWARD_ARGS(FWD_PlayerJoin, "ReGG_PlayerJoinPre", "ReGG_PlayerJoinPost", FP_CELL);
}

destroyForwards() {
	for (new i = 0; i < sizeof(Forwards); i++) {
		DestroyForward(Forwards[Forward:i][FWD_Pre]);
		DestroyForward(Forwards[Forward:i][FWD_Post]);
	}
}
