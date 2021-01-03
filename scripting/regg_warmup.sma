#include <amxmodx>
#include <reapi>
#include <regg>

enum _:game_cvars_s {
	GCRoundInfinite[32],
	Float:GCForcerespawn,
	GCTimelimit,
	GCFraglimit,
}
new GameCvars[game_cvars_s];

enum status_s {
	StatusNone,
	StatusStarted,
	StatusFinished,
}

new HookChain:HookHasRestrictItem;
new SyncHud;
new ReGG_Mode:Mode = ReGG_ModeNone;
new status_s:Status = StatusNone;
new WarmupTime, WarmupTimeOut;

public plugin_init() {
	register_plugin("[ReAPI] GunGame Informer", REGG_VERSION_STR, "F@nt0M");

	HookHasRestrictItem = RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "CBasePlayer_HasRestrictItem_Pre", false);
	DisableHookChain(HookHasRestrictItem);
	SyncHud = CreateHudSyncObj();

	bind_pcvar_num(create_cvar(
		"regg_warmup_time", "60",
		.has_min = true, .min_val = 0.0
	), WarmupTime);
}

public plugin_pause() {
	if (Status != StatusStarted) {
		return;
	}
	restoreGameCvars();
	DisableHookChain(HookHasRestrictItem);
	Status = StatusNone;
}

public ReGG_StartPre(const ReGG_Mode:mode) {
	if (Status == StatusFinished || WarmupTime == 0.0) {
		return PLUGIN_CONTINUE;
	}

	if (Status == StatusStarted) {
		return PLUGIN_HANDLED;
	}

	changeGameCvars();
	EnableHookChain(HookHasRestrictItem);
	Mode = mode;
	Status = StatusStarted;
	WarmupTimeOut = WarmupTime;
	set_task(1.0, "TaskInfo", .flags = "b");
	return PLUGIN_HANDLED;
}

public TaskInfo(const id) {
	if (Status != StatusStarted) {
		remove_task(id);
		return;
	}

	WarmupTimeOut--;
	if (WarmupTimeOut < -1) {
		remove_task(id);
		restoreGameCvars();
		DisableHookChain(HookHasRestrictItem);
		Status = StatusFinished;
		ReGG_Start(Mode);
	} else if (WarmupTimeOut > 0) {
		set_hudmessage(255, 255, 255, -1.0, 0.4, 0, 6.0, 1.0, 0.1, 0.2);
		ShowSyncHudMsg(0, SyncHud, "Разминочный раунд: осталось %i секунд", WarmupTimeOut);
	} else {
		set_hudmessage(255, 255, 255, -1.0, 0.4, 0, 6.0, 1.0, 0.1, 0.2);
		ShowSyncHudMsg(0, SyncHud, "Разминочный раунд закончился!");
	}
}

public CBasePlayer_HasRestrictItem_Pre(const id, const ItemID:item, const ItemRestType:type) {
	if (item == ITEM_KNIFE) {
		return HC_CONTINUE;
	}
	SetHookChainReturn(ATYPE_BOOL, true);
	return HC_SUPERCEDE;
}

changeGameCvars() {
	new pcvar;

	pcvar = get_cvar_pointer("mp_round_infinite");
	get_pcvar_string(pcvar, GameCvars[GCRoundInfinite], charsmax(GameCvars[GCRoundInfinite]));
	set_pcvar_num(pcvar, 1);

	pcvar = get_cvar_pointer("mp_forcerespawn");
	GameCvars[GCForcerespawn] = get_pcvar_float(pcvar);
	set_pcvar_float(pcvar, 1.0);

	pcvar = get_cvar_pointer("mp_timelimit");
	GameCvars[GCTimelimit] = get_pcvar_num(pcvar);
	set_pcvar_num(pcvar, 0);

	pcvar = get_cvar_pointer("mp_fraglimit");
	GameCvars[GCFraglimit] = get_pcvar_num(pcvar);
	set_pcvar_num(pcvar, 0);
}

restoreGameCvars() {
	new pcvar;

	pcvar = get_cvar_pointer("mp_round_infinite");
	set_pcvar_string(pcvar, GameCvars[GCRoundInfinite]);

	pcvar = get_cvar_pointer("mp_forcerespawn");
	set_pcvar_float(pcvar, GameCvars[GCForcerespawn]);

	pcvar = get_cvar_pointer("mp_timelimit");
	set_pcvar_num(pcvar, GameCvars[GCTimelimit]);

	pcvar = get_cvar_pointer("mp_fraglimit");
	set_pcvar_num(pcvar, GameCvars[GCFraglimit]);
}