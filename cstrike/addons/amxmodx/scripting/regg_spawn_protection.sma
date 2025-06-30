#include <amxmodx>
#include <reapi>
#include <regg>

new bool:DebugMode;

enum state_s {
	StateEnable,
	StateDisable,
};
enum _:hook_s {
	HookChain:HookPlayerSpawn,
    HookChain:HookPlayerTakeDamage,
};
new HookChain:Hooks[hook_s];
new Float:SpawnProtectionTime;
new bool:g_bProtected[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin("[ReGG] Spawn protection", REGG_VERSION_STR, "Red Legioner");

    bind_pcvar_float(create_cvar(
        "regg_spawn_protection_time", "2.0",
        .has_min = true,
        .min_val = 0.0
    ), SpawnProtectionTime);

    registerHooks();
    toggleHooks(StateEnable);

    DebugMode = bool:(plugin_flags() & AMX_FLAG_DEBUG);
    DebugMode && log_amx("Debug mode is enable!");
}

registerHooks() {
    Hooks[HookPlayerSpawn] = RegisterHookChain(RG_CBasePlayer_Spawn, "CBasePlayer_Spawn_Post", true);
    Hooks[HookPlayerTakeDamage] = RegisterHookChain(RG_CBasePlayer_TakeDamage, "CBasePlayer_TakeDamage");
}

toggleHooks(state_s:_state) {
	for(new i; i < hook_s; i++) {
		if(Hooks[i]) {
			_state == StateEnable ? EnableHookChain(Hooks[i]) : DisableHookChain(Hooks[i]);
		}
	}
}

public CBasePlayer_Spawn_Post(const id) {
	// Устанавливаем защиту игроку
    remove_task(id);
    EnableSpawnProtection(id);
    set_task(SpawnProtectionTime, "DisableSpawnProtection", id);
    return HC_CONTINUE;
}

public CBasePlayer_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits) {
    if (!is_user_connected(attacker) || !is_user_connected(victim)) {
        return HC_CONTINUE;
    }
    
    if (g_bProtected[victim]) {
        SetHookChainReturn(ATYPE_INTEGER, 0);
        return HC_SUPERCEDE;
    }
    
    return HC_CONTINUE;
}

public EnableSpawnProtection(id){
    if (!is_user_connected(id)){
        return;
    }

    g_bProtected[id] = true;

    // Устанавливает glow игроку (цвет R, G, B, сила свечения)
    new Float:color[3];
    switch(get_member(id, m_iTeam)) {
		case TEAM_CT: {
            // Синий
			color[0] = 0.0;
			color[1] = 0.0;
			color[2] = 255.0;
		}
		case TEAM_TERRORIST: {
            // Красный
			color[0] = 255.0;
			color[1] = 0.0;
			color[2] = 0.0;
		}
		default: {
            // Белый
			color[0] = 255.0;
			color[1] = 255.0;
			color[2] = 255.0;
		}
	}
    SetPlayerGlow(id, color, 25);
}

public DisableSpawnProtection(id){
    if (!(g_bProtected[id])){
        return;
    }
    g_bProtected[id] = false;
    RemovePlayerGlow(id);
}

// Устанавливает glow игроку (цвет, сила свечения)
public SetPlayerGlow(id, const Float:color[3], amount) {
    if (!is_user_connected(id))
        return;

    set_entvar(id, var_renderfx, kRenderFxGlowShell);
    set_entvar(id, var_rendercolor, color);
    set_entvar(id, var_renderamt, float(amount));

    // Дополнительные параметры для тонкого эффекта
    set_entvar(id, var_scale, 0.9); // Чуть уменьшенная модель
}

// Убирает glow
public RemovePlayerGlow(id) {
    if (!is_user_connected(id)) 
        return;

    set_entvar(id, var_renderfx, kRenderFxNone);
    set_entvar(id, var_renderamt, 0.0);
}

public client_disconnected(id) {
    g_bProtected[id] = false;
    remove_task(id);
}