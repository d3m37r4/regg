# GunGame Mod for Counter-Strike 1.6

## What is this?
GunGame is one of most dynamic modifications in terms of gameplay. In this it is similar to CSDM mod, which uses a similar game mechanic: <br>
– purchase menu is not available; <br>
– money is not given out; <br>
– weapon cannot be thrown away and it disappears after death of the owner. <br>
In the GunGame modification, players are respawned with a weapon corresponding to their level and a knife. For killing enemy, player is awarded a new level, and with it a weapon. By default, knife - is last weapon you can get. Winner will be player who is the first to commit murders with a knife (in team mode, team that was this player in wins).

## Composition of the modification
`regg_core` - basis of modification <br>
`regg_balancer` - plugin allows you to control the balance of teams <br>
`regg_controller` - control of game modes (single, team, FFA) <br>
`regg_vote` - plugin is responsible for launching voting for mode selection of game $\textcolor{red}{(need testing!)}$ <br>
`regg_informer` - displays the current level of player or team, as well as weapons and number of points <br>
`regg_leader` - displays current leader of game <br>
`regg_map_cleaner` - clearing maps from unnecessary entities <br>
`regg_mapmanager` - wrapper for working with changing maps on server <br>
`regg_notify` - notification plugin <br>
`regg_warmup` - warmup mode before starting main mode <br>
`regg_show_winner` - shows winner at end of game <br>
`regg_block_send_wpn_anim` - blocks animation of changing weapons

Requirements
=============
- [ReHLDS](https://github.com/dreamstalker/rehlds/) 3.13.0.788 or higher
- [ReGameDLL_CS](https://github.com/s1lentq/ReGameDLL_CS/) 5.22.0.593 or higher
- [Metamod-r](https://github.com/theAsmodai/metamod-r)  1.3.0.128 or higher (or Metamod-P)
- [AMX Mod X](https://github.com/alliedmodders/amxmodx/) 1.9.0 or higher
- [ReAPI](https://github.com/s1lentq/reapi) 5.22.0.254 or higher

**Tip: Recommend using the latest versions.**

Installation
=============

- Compile `*.sma` files
- Move compiled files `*.amxx` to `amxmodx/plugins/`
- Move `plugins-regg.ini` file to `amxmodx/configs/` directory
- Move `configs/*.*` files to `amxmodx/configs/` directory
- Move `regg.txt` file to `amxmodx/data/lang/` directory
- Move folder `cstrike/sound/regg` with resources from archive to directory on server `/cstrike/sound`
