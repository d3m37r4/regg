#if defined _regg_included
	#endinput
#endif

#define _regg_included

enum ReGG_Mode {
	ReGG_ModeNone,
	ReGG_ModeSingle,
	ReGG_ModeTeam,
	ReGG_ModeFFA,
};

enum (+=1) {
	ReGG_SlotInvalid = -1,
	ReGG_SlotT,
	ReGG_SlotCT,
};

enum ReGG_Result {
	ReGG_ResultNone,
	ReGG_ResultPointsUp,
	ReGG_ResultPointsDown,
	ReGG_ResultLevelUp,
	ReGG_ResultLevelDown,
};

forward ReGG_StartPre(const ReGG_Mode:mode);
forward ReGG_StartPost(const ReGG_Mode:mode);

forward ReGG_FinishPre();
forward ReGG_FinishPost();

forward ReGG_PlayerPointsPre(const id, const value);
forward ReGG_PlayerPointsPost(const id, const value);

forward ReGG_TeamPointsPre(const slot, const value);
forward ReGG_TeamPointsPost(const slot, const value);

forward ReGG_PlayerLevelPre(const id, const value);
forward ReGG_PlayerLevelPost(const id, const value);

forward ReGG_TeamLevelPre(const slot, const value);
forward ReGG_TeamLevelPost(const slot, const value);

forward ReGG_GiveWeaponPre(const id, const WeaponIdType:value);
forward ReGG_GiveWeaponPost(const id, const WeaponIdType:value);

forward ReGG_KillEnemyPre(const killer, const victim, const WeaponIdType:value, const ReGG_Result:result, const oldPoints, const oldLevel);
forward ReGG_KillEnemyPost(const killer, const victim, const WeaponIdType:value, const ReGG_Result:result, const newPoints, const newLevel);

native ReGG_Start(const ReGG_Mode:mode);
native ReGG_Finish();
native ReGG_GetMode();
native ReGG_GetPlayerSlot(const id);
native ReGG_GetPoints(const id);
native ReGG_Result:ReGG_SetPoints(const id, const value, const bool:forwards = false);
native ReGG_GetTeamPoints(const slot);
native ReGG_Result:ReGG_SetTeamPoints(const slot, const value, const bool:forwards = false);
native ReGG_GetLevel(const id);
native ReGG_Result:ReGG_SetLevel(const id, const value, const bool:forwards = false);
native ReGG_GetTeamLevel(const slot);
native ReGG_Result:ReGG_SetTeamLevel(const slot, const value, const bool:forwards = false);
native ReGG_GetLevelPoints(const level);
native ReGG_GetLevelTitle(const level, buffer[], const length);
native WeaponIdType:ReGG_GetLevelWeapon(const level);
native ReGG_GetPlayerLevelPoints(const id);
native ReGG_GetTeamLevelPoints(const slot);
