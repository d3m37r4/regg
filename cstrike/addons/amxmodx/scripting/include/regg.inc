#if defined _regg_included
	#endinput
#endif

#define _regg_included

// for AMXX_VERSION_NUM < 1.10.0
#if !defined is_user_authorized
	native is_user_authorized(index);
#endif

/**
*	Given a version number MAJOR.MINOR.PATCH, increment the:
*	
*	MAJOR version when you make incompatible API changes
*	MINOR version when you add functionality in a backward compatible manner
*	PATCH version when you make backward compatible bug fixes
*	
*	Additional labels for pre-release and build metadata are available as extensions to the MAJOR.MINOR.PATCH format.
*	For an in-depth look at semantic versioning, check out this: https://semver.org
**/

#define REGG_MAJOR_VERSION				0
#define REGG_MINOR_VERSION				5
#define REGG_PATCH_VERSION				41

#define REGG_VERSION					str_to_num(fmt("%d%d%d", REGG_MAJOR_VERSION, REGG_MINOR_VERSION, REGG_PATCH_VERSION))
#define REGG_VERSION_STR				fmt("%d.%d.%d-beta", REGG_MAJOR_VERSION, REGG_MINOR_VERSION, REGG_PATCH_VERSION)

stock const REGG_DIR_NAME[MAX_NAME_LENGTH] = "regg";		// Mod directory name
stock const REGG_MAIN_CFG_FILE[] = "regg-main.cfg";		// Main config file of mod

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
	ReGG_ResultFinish,
};

enum ReGG_ChangeType {
	ReGG_ChangeTypeSet,
	ReGG_ChangeTypeAdd,
	ReGG_ChangeTypeSub,
};

forward ReGG_StartPre(const ReGG_Mode:mode);
forward ReGG_StartPost(const ReGG_Mode:mode);

forward ReGG_FinishPre(const killer, const victim);
forward ReGG_FinishPost(const killer, const victim);

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

forward ReGG_PlayerJoinPre(const id);
forward ReGG_PlayerJoinPost(const id);

forward ReGG_StealPointsPre(const killer, const victim, const value);
forward ReGG_StealPointsPost(const killer, const victim, const value);

forward ReGG_StealLevelsPre(const killer, const victim, const value);
forward ReGG_StealLevelsPost(const killer, const victim, const value);

forward ReGG_SuicidePre(const id);
forward ReGG_SuicidePost(const id);

native ReGG_Start(const ReGG_Mode:mode);
native ReGG_Finish();
native ReGG_GetMode();
native ReGG_GetPlayerSlot(const id);
native ReGG_GetPoints(const id);
native bool:ReGG_SetPoints(const id, const value, const ReGG_ChangetType:type, const bool:forwards = false);
native ReGG_GetTeamPoints(const slot);
native bool:ReGG_SetTeamPoints(const slot, const value, const ReGG_ChangetType:type, const bool:forwards = false);
native ReGG_GetLevel(const id);
native bool:ReGG_SetLevel(const id, const value, const ReGG_ChangetType:type, const bool:forwards = false);
native ReGG_GetTeamLevel(const slot);
native bool:ReGG_SetTeamLevel(const slot, const value, const ReGG_ChangetType:type, const bool:forwards = false);
native ReGG_GetLevelPoints(const level);
native ReGG_GetLevelTitle(const level, buffer[], const length);
native WeaponIdType:ReGG_GetLevelWeapon(const level);
native ReGG_GetLevelMax();
native ReGG_GetPlayerLevelPoints(const id);
native ReGG_GetTeamLevelPoints(const slot);
