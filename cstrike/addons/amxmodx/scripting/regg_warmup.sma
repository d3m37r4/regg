#include <amxmodx>
#include <reapi>
#include <regg>

const Float:MaxHudHoldTime = 256.0;

enum _:game_cvars_s {
	Float:GCRoundTime,
	GCRoundInfinite[32],
	Float:GCForceRespawn,
	GCTimelimit,
	GCFraglimit,
    GCGivePlayerC4,
	GCWeaponsAllowMapPlaced,
    GCTDefaultGrenades[32],
    GCTDefaultWeaponsSecondary[32],
    GCTDefaultWeaponsPrimary[32],
    GCCTDefaultGrenades[32],
    GCTGivePlayerKnife,
    GCCTGivePlayerKnife,
    GCCTDefaultWeaponsSecondary[32],
    GCCTDefaultWeaponsPrimary[32],
	GCRefillBpammoWeapons,
	GCStartMoney,
	GCBuyAnywhere,
    Float:GCBuyTime,
    GCItemStaytime,
};
new GameCvars[game_cvars_s];

enum _:hook_s {
	HookChain:HookHasRestrictItem,
	HookChain:HookPlayerSpawn,
	HookChain:HookPlayerKilled,
	HookChain:HookRoundEnd,
};
new HookChain:Hooks[hook_s];

enum color_s {
	red,
	green,
	blue,
};
new const HudColor[color_s] = { 120, 80, 0 };

enum coord_s { 
	Float:x, 
	Float:y,
};
new const Float:HudPos[coord_s] = { -1.0, 0.85 };

enum status_s {
	StatusNone,
	StatusStarted,
	StatusFinished,
};
new status_s:Status = StatusNone;

enum state_s {
	StateEnable,
	StateDisable,
};

enum warmuptype_s {
	WarmupTypeAllWeapons,
	WarmupTypeOnlyKnife,
};
new warmuptype_s:WarmupType;

enum costtype_s {
	CostTypeWeapon,
	CostTypeClip,
};
new WeaponIdType:DefaultWeaponCost[WeaponIdType][costtype_s];

new ReGG_Mode:Mode = ReGG_ModeNone;
new WarmupTime;
new SyncHud;

new bool:DebugMode;

public plugin_init() {
	register_plugin("[ReGG] WarmUp", REGG_VERSION_STR, "Jumper & d3m37r4");

	registerHooks();
	toggleHooks(StateDisable);
	getDefaultWeaponCost();

	bind_pcvar_num(create_cvar(
		"regg_warmup_time", "60",
		.has_min = true, .min_val = 0.0
	), WarmupTime);
	bind_pcvar_num(create_cvar(
		"regg_warmup_type", "1",
		.has_min = true, .min_val = 0.0, 
		.has_max = true, .max_val = 1.0
	), WarmupType);

	SyncHud = CreateHudSyncObj();
	DebugMode = bool:(plugin_flags() & AMX_FLAG_DEBUG);
	DebugMode && log_amx("Debug mode is enable!");
}

public plugin_pause() {
	if(Status != StatusStarted) {
		return;
	}

	restoreGameCvars();
	toggleHooks(StateDisable);
	(WarmupType == WarmupTypeAllWeapons) && makeAllWeaponsFree(.make_free = true);

	Status = StatusNone;
}

public ReGG_StartPre(const ReGG_Mode:mode) {
	if(Status == StatusFinished) {
		return PLUGIN_CONTINUE;
	}

	if(Status == StatusStarted) {
		return PLUGIN_HANDLED;
	}

	// Block the launch of mod and call start of warmup
	Mode = mode;
	startWarmUp();

	return PLUGIN_HANDLED;
}

public CBasePlayer_Spawn_Post(const id) {
	if(!is_user_alive(id)) {
		return HC_CONTINUE;
	}

	set_member(id, m_iHideHUD, get_member(id, m_iHideHUD) | HIDEHUD_MONEY);

	set_hudmessage(HudColor[red], HudColor[green], HudColor[blue], HudPos[x], HudPos[y], .holdtime = MaxHudHoldTime);
	ShowSyncHudMsg(id, SyncHud, "%L", LANG_PLAYER, "REGG_WARMUP_HUD");

	return HC_CONTINUE;
}

public CBasePlayer_Killed_Post(const id) {
	if(!is_user_authorized(id)) {
		return HC_CONTINUE;
	}

	ClearSyncHud(id, SyncHud);
	return HC_CONTINUE;
}

public RoundEnd_Pre(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay) {
	if(Status == StatusStarted && status == WINSTATUS_DRAW && event == ROUND_GAME_COMMENCE) {
		return HC_CONTINUE;
	}

	SetHookChainArg(1, ATYPE_INTEGER, WINSTATUS_NONE);
	SetHookChainArg(2, ATYPE_INTEGER, ROUND_NONE);
	stopWarmUp();
	return HC_CONTINUE;
}

public startWarmUp() {
	if(Status == StatusStarted) {
		return;
	}

	Status = StatusStarted;

	changeGameCvars();
	toggleHooks(StateEnable);
	(WarmupType == WarmupTypeAllWeapons) && makeAllWeaponsFree(.make_free = true);

	set_member_game(m_bCompleteReset, false);
	rg_round_end(
		.tmDelay = 0.0, 
		.st = WINSTATUS_DRAW, 
		.event = ROUND_GAME_COMMENCE, 
		.message = "",  
		.sentence = "", 
		.trigger = true
	);

	DebugMode && log_amx("Warmup mode is started!");
}

public stopWarmUp() {
	if(Status == StatusFinished) {
		return;
	}

	Status = StatusFinished;

	restoreGameCvars();
	toggleHooks(StateDisable);
	(WarmupType == WarmupTypeAllWeapons) && makeAllWeaponsFree(.make_free = false);

	for(new player = 1; player <= MaxClients; player++) {
		if(!is_user_alive(player)) {
			continue;
		}

		set_member(player, m_iHideHUD, get_member(player, m_iHideHUD) & ~HIDEHUD_MONEY);
		ClearSyncHud(player, SyncHud);	
	}

	client_print(0, print_center, "%L", LANG_PLAYER, "REGG_WARMUP_END");

	ReGG_Start(Mode);
	DebugMode && log_amx("Warmup mode is finished!");
}

registerHooks() {
	Hooks[HookPlayerSpawn] = RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Post", true);
	Hooks[HookPlayerKilled] = RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);
	Hooks[HookRoundEnd] = RegisterHookChain(RG_RoundEnd, "RoundEnd_Pre", false);
}

toggleHooks(state_s:_state) {
	for(new i; i < hook_s; i++) {
		if(Hooks[i]) {
			_state == StateEnable ? EnableHookChain(Hooks[i]) : DisableHookChain(Hooks[i]);
		}
	}
}

changeGameCvars() {
	new pcvar;

	pcvar = get_cvar_pointer("mp_roundtime");
	GameCvars[GCRoundTime] = get_pcvar_float(pcvar);
	set_pcvar_float(pcvar, float(WarmupTime) / 60.0);

	pcvar = get_cvar_pointer("mp_round_infinite");
	get_pcvar_string(pcvar, GameCvars[GCRoundInfinite], charsmax(GameCvars[GCRoundInfinite]));
	set_pcvar_string(pcvar, "bcdefg");

	pcvar = get_cvar_pointer("mp_forcerespawn");
	GameCvars[GCForceRespawn] = get_pcvar_float(pcvar);
	set_pcvar_float(pcvar, 1.0);

	pcvar = get_cvar_pointer("mp_timelimit");
	GameCvars[GCTimelimit] = get_pcvar_num(pcvar);
	set_pcvar_num(pcvar, 0);

	pcvar = get_cvar_pointer("mp_fraglimit");
	GameCvars[GCFraglimit] = get_pcvar_num(pcvar);
	set_pcvar_num(pcvar, 0);

	pcvar = get_cvar_pointer("mp_give_player_c4");
	GameCvars[GCGivePlayerC4] = get_pcvar_num(pcvar);
	set_pcvar_num(pcvar, 0);

	pcvar = get_cvar_pointer("mp_weapons_allow_map_placed");
	GameCvars[GCWeaponsAllowMapPlaced] = get_pcvar_num(pcvar);
	set_pcvar_num(pcvar, 0);

	if(WarmupType == WarmupTypeOnlyKnife) {
		pcvar = get_cvar_pointer("mp_t_default_grenades");
		get_pcvar_string(pcvar, GameCvars[GCTDefaultGrenades], charsmax(GameCvars[GCTDefaultGrenades]));
		set_pcvar_string(pcvar, "");

		pcvar = get_cvar_pointer("mp_t_default_weapons_secondary");
		get_pcvar_string(pcvar, GameCvars[GCTDefaultWeaponsSecondary], charsmax(GameCvars[GCTDefaultWeaponsSecondary]));
		set_pcvar_string(pcvar, "");

		pcvar = get_cvar_pointer("mp_t_default_weapons_primary");
		get_pcvar_string(pcvar, GameCvars[GCTDefaultWeaponsPrimary], charsmax(GameCvars[GCTDefaultWeaponsPrimary]));
		set_pcvar_string(pcvar, "");

		pcvar = get_cvar_pointer("mp_ct_default_grenades");
		get_pcvar_string(pcvar, GameCvars[GCCTDefaultGrenades], charsmax(GameCvars[GCCTDefaultGrenades]));
		set_pcvar_string(pcvar, "");

		pcvar = get_cvar_pointer("mp_ct_default_weapons_secondary");
		get_pcvar_string(pcvar, GameCvars[GCCTDefaultWeaponsSecondary], charsmax(GameCvars[GCCTDefaultWeaponsSecondary]));
		set_pcvar_string(pcvar, "");

		pcvar = get_cvar_pointer("mp_ct_default_weapons_primary");
		get_pcvar_string(pcvar, GameCvars[GCCTDefaultWeaponsPrimary], charsmax(GameCvars[GCCTDefaultWeaponsPrimary]));
		set_pcvar_string(pcvar, "");
	}

	pcvar = get_cvar_pointer("mp_t_give_player_knife");
	GameCvars[GCTGivePlayerKnife] = get_pcvar_num(pcvar);
	set_pcvar_num(pcvar, 1);

	pcvar = get_cvar_pointer("mp_ct_give_player_knife");
	GameCvars[GCCTGivePlayerKnife] = get_pcvar_num(pcvar);
	set_pcvar_num(pcvar, 1);

	if(WarmupType == WarmupTypeAllWeapons) {
		pcvar = get_cvar_pointer("mp_refill_bpammo_weapons");
		GameCvars[GCRefillBpammoWeapons] = get_pcvar_num(pcvar);
		set_pcvar_num(pcvar, 3);

		pcvar = get_cvar_pointer("mp_startmoney");
		GameCvars[GCStartMoney] = get_pcvar_num(pcvar);
		set_pcvar_num(pcvar, 999999);	// We set maximum possible value, it will still be trimmed taking into account 'mp_maxmoney'.

		pcvar = get_cvar_pointer("mp_buy_anywhere");
		GameCvars[GCBuyAnywhere] = get_pcvar_num(pcvar);
		set_pcvar_num(pcvar, 1);
	}

	pcvar = get_cvar_pointer("mp_buytime");
	GameCvars[GCBuyTime] = get_pcvar_float(pcvar);
	set_pcvar_float(pcvar, WarmupType == WarmupTypeOnlyKnife ? 0.0 : -1.0);

	pcvar = get_cvar_pointer("mp_item_staytime");
	GameCvars[GCItemStaytime] = get_pcvar_num(pcvar);
	set_pcvar_num(pcvar, 0);
}

restoreGameCvars() {
	new pcvar;

	pcvar = get_cvar_pointer("mp_roundtime");
	set_pcvar_float(pcvar, GameCvars[GCRoundTime]);

	pcvar = get_cvar_pointer("mp_round_infinite");
	set_pcvar_string(pcvar, GameCvars[GCRoundInfinite]);

	pcvar = get_cvar_pointer("mp_forcerespawn");
	set_pcvar_float(pcvar, GameCvars[GCForceRespawn]);

	pcvar = get_cvar_pointer("mp_timelimit");
	set_pcvar_num(pcvar, GameCvars[GCTimelimit]);

	pcvar = get_cvar_pointer("mp_fraglimit");
	set_pcvar_num(pcvar, GameCvars[GCFraglimit]);

	pcvar = get_cvar_pointer("mp_give_player_c4");
	set_pcvar_num(pcvar, GameCvars[GCGivePlayerC4]);

	pcvar = get_cvar_pointer("mp_weapons_allow_map_placed");
	set_pcvar_num(pcvar, GameCvars[GCWeaponsAllowMapPlaced]);

	if(WarmupType == WarmupTypeOnlyKnife) {
		pcvar = get_cvar_pointer("mp_t_default_grenades");
		set_pcvar_string(pcvar, GameCvars[GCTDefaultGrenades]);

		pcvar = get_cvar_pointer("mp_t_default_weapons_secondary");
		set_pcvar_string(pcvar, GameCvars[GCTDefaultWeaponsSecondary]);

		pcvar = get_cvar_pointer("mp_t_default_weapons_primary");
		set_pcvar_string(pcvar, GameCvars[GCTDefaultWeaponsPrimary]);

		pcvar = get_cvar_pointer("mp_ct_default_grenades");
		set_pcvar_string(pcvar, GameCvars[GCCTDefaultGrenades]);

		pcvar = get_cvar_pointer("mp_ct_default_weapons_secondary");
		set_pcvar_string(pcvar, GameCvars[GCCTDefaultWeaponsSecondary]);

		pcvar = get_cvar_pointer("mp_ct_default_weapons_primary");
		set_pcvar_string(pcvar, GameCvars[GCCTDefaultWeaponsPrimary]);
	}

	pcvar = get_cvar_pointer("mp_t_give_player_knife");
	set_pcvar_num(pcvar, GameCvars[GCTGivePlayerKnife]);

	pcvar = get_cvar_pointer("mp_ct_give_player_knife");
	set_pcvar_num(pcvar, GameCvars[GCCTGivePlayerKnife]);

	if(WarmupType == WarmupTypeAllWeapons) {
		pcvar = get_cvar_pointer("mp_refill_bpammo_weapons");
		set_pcvar_num(pcvar, GameCvars[GCRefillBpammoWeapons]);

		pcvar = get_cvar_pointer("mp_startmoney");
		set_pcvar_num(pcvar, GameCvars[GCStartMoney]);

		pcvar = get_cvar_pointer("mp_buy_anywhere");
		set_pcvar_num(pcvar, GameCvars[GCBuyAnywhere]);
	}

	pcvar = get_cvar_pointer("mp_buytime");
	set_pcvar_float(pcvar, GameCvars[GCBuyTime]);

	pcvar = get_cvar_pointer("mp_item_staytime");
	set_pcvar_num(pcvar, GameCvars[GCItemStaytime]);
}

getDefaultWeaponCost() {
	for(new WeaponIdType:weapon = WEAPON_P228; weapon <= WEAPON_P90; weapon++) {
		if(weapon != WEAPON_C4 && weapon != WEAPON_KNIFE) {
			DefaultWeaponCost[weapon][CostTypeWeapon] = rg_get_weapon_info(weapon, WI_COST);
			DefaultWeaponCost[weapon][CostTypeClip] = rg_get_weapon_info(weapon, WI_CLIP_COST);
		}
	}
}

// Алексеич (https://dev-cs.ru/members/3/) would have thought that we were talking about French fries *kappa*
makeAllWeaponsFree(bool:make_free = true) {
	for(new WeaponIdType:weapon = WEAPON_P228; weapon <= WEAPON_P90; weapon++) {
		if(weapon != WEAPON_C4 && weapon != WEAPON_KNIFE) {
			rg_set_weapon_info(weapon, WI_COST, make_free ? 0 : DefaultWeaponCost[weapon][CostTypeWeapon]);
			rg_set_weapon_info(weapon, WI_CLIP_COST, make_free ? 0 : DefaultWeaponCost[weapon][CostTypeClip]);
		}          
	}
}
