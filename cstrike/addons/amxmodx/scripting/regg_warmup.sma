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
	GCWeaponsAllowMapPlaced,
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

new ReGG_Mode:Mode = ReGG_ModeNone;
new WarmupTime;
new SyncHud;

new bool:DebugMode;

#define getLangKey(%0) fmt("%l", %0)

public plugin_init() {
	register_plugin("[ReGG] WarmUp", REGG_VERSION_STR, "Jumper & d3m37r4");

	registerHooks();
	toggleHooks(StateDisable);

	bind_pcvar_num(create_cvar(
		"regg_warmup_time", "60",
		.has_min = true, .min_val = 0.0
	), WarmupTime);

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

public CBasePlayer_HasRestrictItem_Pre(const id, const ItemID:item, const ItemRestType:type) {
	if(item == ITEM_KNIFE) {
		return HC_CONTINUE;
	}

	SetHookChainReturn(ATYPE_BOOL, true);
	return HC_SUPERCEDE;
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

	set_member_game(m_bCompleteReset, false);
	rg_round_end(
		.tmDelay = 0.0, 
		.st = WINSTATUS_DRAW, 
		.event = ROUND_GAME_COMMENCE, 
		.message = _replace_string_ex(getLangKey("REGG_WARMUP_START"), "$n", "^r", true),  
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
	Hooks[HookHasRestrictItem] = RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "CBasePlayer_HasRestrictItem_Pre", false);
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

	pcvar = get_cvar_pointer("mp_weapons_allow_map_placed");
	GameCvars[GCWeaponsAllowMapPlaced] = get_pcvar_num(pcvar);
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

	pcvar = get_cvar_pointer("mp_weapons_allow_map_placed");
	set_pcvar_num(pcvar, GameCvars[GCWeaponsAllowMapPlaced]);
}

// https://github.com/d3m37r4/AMXX_Plugins/blob/aecab54d525389c0cc9cc274ff87a518b9369521/Simple_WarmUp_Mode/simple_warmup_mode.sma#L514
stock _replace_string_ex(const _buffer[], const _search[], const _string[], bool:_caseSensitive = true) {
    new buffer[MAX_FMT_LENGTH];

    formatex(buffer, charsmax(buffer), _buffer);
    replace_string(buffer, charsmax(buffer), _search, _string, _caseSensitive);

    return buffer;
}