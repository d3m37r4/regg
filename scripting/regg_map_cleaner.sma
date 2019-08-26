#include <amxmodx>
#include <fakemeta>
#include <reapi>

new const MapEntityList[][] = {
	"func_bomb_target",
	"info_bomb_target",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"func_vip_safetyzone",
	"info_vip_start",
	"hostage_entity",
	"monster_scientist",
	"func_escapezone",
	"func_buyzone",
	"armoury_entity",
	"game_player_equip",
	"player_weaponstrip"
};

new EntitySpawnHook;

public plugin_precache() {	
	EntitySpawnHook = register_forward(FM_Spawn, "FwdEntitySpawn");
}

public plugin_init() {
	register_plugin("[ReAPI] GunGame Map Cleaner", "0.1.0-alpha", "F@nt0M");

	if (EntitySpawnHook) {
		unregister_forward(FM_Spawn, EntitySpawnHook);
	}
}

public FwdEntitySpawn(const ent) {
	if (is_nullent(ent)) {
		return FMRES_IGNORED;
	}

	for (new i = 0; i < sizeof MapEntityList; i++) {
		if (FClassnameIs(ent, MapEntityList[i])) {
			set_entvar(ent, var_flags, FL_KILLME);
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}
