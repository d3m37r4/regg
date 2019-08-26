#if defined _regg_included
	#endinput
#endif

#define _regg_included

enum ReGG_Mode {
	ReGG_ModeSingle,
	ReGG_ModeTeam
};

enum (+=1) {
	ReGG_SlotInvalid = -1,
	ReGG_SlotT,
	ReGG_SlotCT,
};

forward ReGG_Starting();
forward ReGG_Started();
forward ReGG_Finishing();
forward ReGG_Finished();
forward ReGG_SettingPointsSingle(const id, const value);
forward ReGG_SettedPointsSignel(const id, const value);
forward ReGG_SettingPointsTeam(const slot, const value);
forward ReGG_SettedPointsTeam(const slot, const value);
forward ReGG_SettingLevelSingle(const id, const value);
forward ReGG_SettedLevelSingle(const id, const value);
forward ReGG_SettingLevelTeam(const slot, const value);
forward ReGG_SettedLevelTeam(const slot, const value);

native ReGG_Start(ReGG_Mode:mode);
native ReGG_Finish();
native ReGG_GetMode();
native ReGG_GetSlot(const player);
native ReGG_GetLevel(const player);
native ReGG_GetPoints(const player);
native ReGG_GetLevelPoints(const player, const level);
