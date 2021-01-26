#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <regg>

new bool:BlockAnim = false;

public plugin_init() {
	register_plugin("[ReGG] Block Send Wpn Anim", REGG_VERSION_STR, "F@nt0M");
	for (new WeaponIdType:wid = WEAPON_P228, wname[32]; wid <= WEAPON_P90; wid++) {
		switch (wid) {
			case WEAPON_GLOCK, WEAPON_C4, WEAPON_HEGRENADE, WEAPON_SMOKEGRENADE, WEAPON_FLASHBANG: {}

			default: {
				rg_get_weapon_info(wid, WI_NAME, wname, charsmax(wname));
				RegisterHam(Ham_CS_Weapon_SendWeaponAnim, wname, "CS_Weapon_SendWeaponAnim_Pre", false);
				RegisterHam(Ham_Item_Deploy, wname, "Item_Deploy_Pre", false);
				RegisterHam(Ham_Item_Deploy, wname, "Item_Deploy_Post", true);
				// RegisterHam(Ham_Weapon_Reload, wname, "Weapon_Reload_Pre", false);
				// RegisterHam(Ham_Weapon_Reload, wname, "Weapon_Reload_Post", true);
			}
		}
		
	}
}

public CS_Weapon_SendWeaponAnim_Pre() {
	return BlockAnim ? HAM_SUPERCEDE : HAM_IGNORED;
}

public Item_Deploy_Pre() {
	BlockAnim = true;
}

public Item_Deploy_Post(const item) {
	set_member(get_member(item, m_pPlayer), m_flNextAttack, 0.0);
	set_member(item, m_Weapon_flTimeWeaponIdle, 0.0);
	BlockAnim = false;
}

public Weapon_Reload_Pre(const item) {
	set_member(get_member(item, m_pPlayer), m_flNextAttack, 0.0);
	set_member(item, m_Weapon_flTimeWeaponIdle, 0.0);
	BlockAnim = true;
}

public Weapon_Reload_Post(const item) {
	BlockAnim = false;
}
