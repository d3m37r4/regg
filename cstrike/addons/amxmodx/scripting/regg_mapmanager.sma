#include <amxmodx>
#include <map_manager>
#include <regg>

new VoteType;

public plugin_init() {
	register_plugin("[ReGG] Map Manager", REGG_VERSION_STR, "F@nt0M");
	
	bind_pcvar_num(create_cvar(
		"regg_mapchange_type", "1",
		.has_min = true, 
		.min_val = 1.0
	), VoteType);
}

public ReGG_FinishPost(const killer, const victim) {
	MapChange();
}

public MapChange() {
	switch(VoteType){
		case 1: {
			mapm_start_vote(VOTE_BY_SCHEDULER);
		}
		case 2: {
			server_cmd("map_govote");
		}
		case 3: {
			server_cmd("mapm_startvote");
		}
	}
}
