#include <amxmodx>
#include <map_manager>
#include "include/regg.inc"

public plugin_init() {
	register_plugin("[ReAPI] GunGame Map Manager", "0.1.0-alpha", "F@nt0M");
}

public ReGG_FinishPost() {
	mapm_start_vote(VOTE_BY_SCHEDULER);
}
