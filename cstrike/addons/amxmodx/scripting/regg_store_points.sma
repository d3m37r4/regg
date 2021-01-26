#include <amxmodx>
#include <regg>

enum _:store_s {
	StorePoints,
	StoreLevel,
};

new Trie:Store = Invalid_Trie;

new store[store_s];

public plugin_init() {
	register_plugin("[ReGG] Store Points", REGG_VERSION_STR, "F@nt0M");
}

public plugin_end() {
	if(Store != Invalid_Trie) {
		TrieDestroy(Store);
	}
}

public client_disconnected(id) {
	new auth[MAX_AUTHID_LENGTH];
	get_user_authid(id, auth, charsmax(auth));

	store[StorePoints] = ReGG_GetPoints(id);
	store[StoreLevel] = ReGG_GetLevel(id);
	TrieSetArray(Store, auth, store, sizeof store);
}

public ReGG_StartPost(const ReGG_Mode:mode) {
	if(mode == ReGG_ModeSingle || mode == ReGG_ModeFFA) {
		Store = TrieCreate();
		state enabled;
	}
}

public ReGG_PlayerJoinPre(const id) <enabled> {
	new auth[MAX_AUTHID_LENGTH];
	get_user_authid(id, auth, charsmax(auth));
	if(!TrieKeyExists(Store, auth)) {
		return PLUGIN_CONTINUE;
	}

	TrieGetArray(Store, auth, store, sizeof store);
	ReGG_SetPoints(id, store[StorePoints], ReGG_ChangetTypeSet);
	ReGG_SetLevel(id, store[StoreLevel], ReGG_ChangetTypeSet);

	return PLUGIN_HANDLED;
}

public ReGG_PlayerJoinPre(const id) <> {
	return PLUGIN_CONTINUE;
}
