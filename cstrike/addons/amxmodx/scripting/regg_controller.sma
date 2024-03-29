#include <amxmodx>
#include <regg>

enum {
	ModeSingle = 0,
	ModeTeam,
	ModeFFA
};

new Mode;

public plugin_init() {
	register_plugin("[ReGG] Controller", REGG_VERSION_STR, "Jumper & d3m37r4");
	bind_pcvar_num(create_cvar(
		"regg_mode", "0",
		.has_min = true, .min_val = 0.0,
		.has_max = true, .max_val = 2.0
	), Mode);
}

public plugin_cfg() {
	ReGG_Start(getMode());
}

ReGG_Mode:getMode() {
	switch(Mode) {
		case ModeTeam: {
			return ReGG_ModeTeam;
		}

		case ModeFFA: {
			return ReGG_ModeFFA;
		}
	}

	return ReGG_ModeSingle;
}
