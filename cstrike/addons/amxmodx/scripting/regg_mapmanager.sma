#include <amxmodx>
#include <amxmisc>
#include <regg>

new VoteType, gMapNums;
new Array:gMapName;

public plugin_init() {
	register_plugin("[ReGG] Map Manager", REGG_VERSION_STR, "Jumper & d3m37r4");
	
	bind_pcvar_num(create_cvar(
		"regg_mapchange_type", "1",
		.has_min = true, 
		.min_val = 0.0
	), VoteType);

	gMapName = ArrayCreate(MAX_NAME_LENGTH);

	loadMapCfg();
}

public ReGG_FinishPost(const killer, const victim) {
	MapChange();
}

public MapChange() {
	switch(VoteType){
		case 0: {
			new mapname[MAX_NAME_LENGTH];
			ArrayGetString(gMapName, random(gMapNums), mapname, charsmax(mapname));
			message_begin(MSG_ALL, SVC_INTERMISSION);
			message_end();
			engine_changelevel(mapname);
		}
		case 1: {
			server_cmd("mapm_start_vote");
		}
		case 2: {
			server_cmd("map_govote");
		}
		case 3: {
			server_cmd("mapm_startvote");
		}
	}
}

loadMapCfg() {
	new maps_file[PLATFORM_MAX_PATH];
	get_configsdir(maps_file, charsmax(maps_file));
	format(maps_file, charsmax(maps_file), "%s/maps.ini", maps_file);

	if(!file_exists(maps_file)) {
		get_cvar_string("mapcyclefile", maps_file, charsmax(maps_file));
	}	

	if(!file_exists(maps_file)) {
		format(maps_file, charsmax(maps_file), "mapcycle.txt")
	}

	loadMapsFile(maps_file);
}

loadMapsFile(file[]) {
	new iFile = fopen(file, "rt");
	if(!iFile) {
		set_fail_state("File ^"%s^" is not found", file);
	}

	new szBuffer[PLATFORM_MAX_PATH], szMaps[MAX_NAME_LENGTH];
	while(!feof(iFile)) {
		fgets(iFile, szBuffer, charsmax(szBuffer));
		parse(szBuffer, szMaps, charsmax(szMaps));

		if(!szBuffer[0] || szBuffer[0] == ';' || !isValidMap(szMaps)) {
			continue;
		}

		ArrayPushString(gMapName, szMaps);
		gMapNums++;
	}

	fclose(iFile);
}

stock bool:isValidMap(mapname[]) {
	if (is_map_valid(mapname)){
		return true;
	}

	new len = strlen(mapname) - 4;
	if (len < 0) {
		return false;
	}

	if (equali(mapname[len], ".bsp")){
		mapname[len] = '^0';

		if (is_map_valid(mapname)) {
			return true;
		}
	}

	return false;
}
