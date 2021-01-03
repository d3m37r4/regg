#include <amxmodx>
#include <map_manager>
#include <regg>

new Float:Timeout;

public plugin_init() {
	register_plugin("[ReAPI] GunGame Map Manager", REGG_VERSION_STR, "F@nt0M");

	bind_pcvar_float(create_cvar(
		"regg_mapchange_timeout", "10.0",
		.has_min = true, .min_val = 0.0
	), Timeout);
}

public ReGG_FinishPost() {
	set_task(Timeout, "TaskMapChange");
}

public TaskMapChange() {
	mapm_start_vote(VOTE_BY_SCHEDULER);
}
