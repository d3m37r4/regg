#include <amxmodx>
#include <reapi>
#include <regg>

public plugin_init() {
	register_plugin("[ReGG] Block Weapon Animation", REGG_VERSION_STR, "Jumper & d3m37r4");

	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "CBasePlayerWeapon_DefaultDeploy_Pre", false);
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "CBasePlayerWeapon_DefaultDeploy_Post", true);
}

public CBasePlayerWeapon_DefaultDeploy_Pre(const item, szViewModel[], szWeaponModel[], anim, szAnimExt[], skiplocal) {
	if(IsItemGrenade(item)) {
		return HC_CONTINUE;
	}

	SetHookChainArg(4, ATYPE_INTEGER, 0);

	return HC_CONTINUE;
}

public CBasePlayerWeapon_DefaultDeploy_Post(const item, szViewModel[], szWeaponModel[], anim, szAnimExt[], skiplocal) {
	if(IsItemGrenade(item)) {
		return HC_CONTINUE;
	}

	set_member(get_member(item, m_pPlayer), m_flNextAttack, 0.0);
	set_member(item, m_Weapon_flTimeWeaponIdle, 0.0);

	return HC_CONTINUE;
}

bool:IsItemGrenade(const item) {
	new WeaponIdType:wId = get_member(item, m_iId);
	if(wId == WEAPON_HEGRENADE || wId == WEAPON_SMOKEGRENADE || wId == WEAPON_FLASHBANG) {
		return true;
	}

	return false;
}
