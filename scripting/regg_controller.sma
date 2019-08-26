#include <amxmodx>
#include <map_manager>
#include "include/regg.inc"

public plugin_init() {
	register_plugin("[ReAPI] GunGame Controller", "0.1.0-alpha", "F@nt0M");
}

public plugin_cfg() {
    ReGG_Start(ReGG_ModeTeam);
}

public ReGG_Finished() {
    mapm_start_vote(VOTE_BY_SCHEDULER);
}
