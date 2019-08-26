#include <amxmodx>
#include <reapi>

#pragma semicolon 1


#if AMXX_VERSION_NUM < 183
    #define MAX_NAME_LENGTH 32
    #define client_disconnected client_disconnect
#endif


#define CHECK_TIME 30.0    // Frequency (in sec) balance check.
#define SCREEN_FADE        // Screen fade in color of players new team.
#define MSG_CENTER        // Screen center message on player transfer.
#define PLAY_SOUND        // Sound on player transfer. Sound is just like "beep".


new TeamName:g_teamBigger;
new TeamName:g_teamSmaller;

new g_bitsImmunity = ADMIN_IMMUNITY;
new g_iImmunitySteam = 1;
new bool:g_isBalancing = false;

stock const SOUND[] = "misc/mass_teleport_target.wav";


#if defined PLAY_SOUND

public plugin_precache()
{
    precache_sound(SOUND);
}

#endif


public plugin_init()
{
    register_plugin("ReCSDM Team Balance", "1.0.3", "the_hunter");

    register_event("TeamInfo", "event_team_info", "a", "1>0", "2!UNASSIGNED");
    RegisterHookChain(RG_CBasePlayer_Spawn, "fwd_player_spawn_post", true);

#if AMXX_VERSION_NUM < 183

    register_srvcmd("dmb_immunity_steam", "cmd_immunity_steam");
    register_srvcmd("dmb_immunity_flags", "cmd_immunity_flags");

#else

    new pcvImmunitySteam = create_cvar("dmb_immunity_steam", "1");
    new pcvImmunityFlags = create_cvar("dmb_immunity_flags", "a", FCVAR_NOEXTRAWHITEPACE);

    bind_pcvar_num(pcvImmunitySteam, g_iImmunitySteam);
    hook_cvar_change(pcvImmunityFlags, "cvar_change_callback");

#endif

    set_task(CHECK_TIME, "task_check_balance", .flags = "b");
}


/*************** CHECKS ***************/


public task_check_balance()
{
    new iTcount = get_member_game(m_iNumTerrorist);
    new iCTcount = get_member_game(m_iNumCT);
    new iLimitTeams = get_member_game(m_iLimitTeams);

    if (iLimitTeams && abs(iTcount - iCTcount) > iLimitTeams)
    {
        if (iTcount > iCTcount)
        {
            g_teamBigger = TEAM_TERRORIST;
            g_teamSmaller = TEAM_CT;
        }
        else
        {
            g_teamBigger = TEAM_CT;
            g_teamSmaller = TEAM_TERRORIST;
        }

        g_isBalancing = true;
    }
    else
    {
        g_isBalancing = false;
    }
}


bool:check_team(iPlayer)
{
    return
        get_member(iPlayer, m_iTeam) == g_teamBigger;
}


bool:check_immunity(iPlayer)
{
    return
        (get_user_flags(iPlayer) & g_bitsImmunity) ||
        (g_iImmunitySteam && is_user_steam(iPlayer));
}


/*************** FORWARDS ***************/


public event_team_info()
{
    if (g_isBalancing)
    {
        task_check_balance();
    }
}


public fwd_player_spawn_post(iPlayer)
{
    if (g_isBalancing && check_team(iPlayer) && !check_immunity(iPlayer))
    {
        new ModelName:model = get_opposite_player_model(iPlayer);

        if (rg_set_user_team(iPlayer, g_teamSmaller, model, true))
        {
            set_member(iPlayer, m_bTeamChanged, false);

            #if defined MSG_CENTER
            msg_center(iPlayer, g_teamSmaller);
            #endif

            #if defined SCREEN_FADE
            screen_fade(iPlayer, g_teamSmaller);
            #endif

            #if defined PLAY_SOUND
            util_send_audio(iPlayer, SOUND);
            #endif
        }
    }

    return HC_CONTINUE;
}


public client_disconnected()
{
    if (g_isBalancing)
    {
        task_check_balance();
    }

    return PLUGIN_CONTINUE;
}


/*************** BALANCE EFFECTS ***************/


stock msg_center(iPlayer, {_, TeamName}:team)
{
    static const szTitles[][] =
    {
        "#Cstrike_TitlesTXT_Game_join_terrorist_auto",
        "#Cstrike_TitlesTXT_Game_join_ct_auto"
    };

    new szName[MAX_NAME_LENGTH];
    get_user_name(iPlayer, szName, MAX_NAME_LENGTH - 1);

    util_text_msg(0, print_center, szTitles[team - 1], szName);
}


stock screen_fade(iPlayer, {_, TeamName}:team)
{
    static const rgbaTeamColors[][4] =
    {
        { 175, 0, 0, 100 },
        { 0, 0, 175, 100 }
    };

    const Float:flDuration = 1.0;
    const Float:flHoldTime = 1.0;

    util_screen_fade(iPlayer, flDuration, flHoldTime, rgbaTeamColors[team - 1]);
}


/*************** CVARS ***************/


#if AMXX_VERSION_NUM < 183

public cmd_immunity_steam()
{
    if (read_argc() > 1)
    {
        new szArg[18];
        read_argv(1, szArg, charsmax(szArg));

        g_iImmunitySteam = str_to_num(szArg);
    }
    else
    {
        server_print("^"dmb_immunity_steam^" is ^"%i^"", g_iImmunitySteam);
    }

    return PLUGIN_HANDLED;
}


public cmd_immunity_flags()
{
    if (read_argc() > 1)
    {
        new szArg[25];
        read_argv(1, szArg, charsmax(szArg));
        trim(szArg);

        g_bitsImmunity = szArg[0] == '^0'
            ? ADMIN_ALL
            : read_flags(szArg);
    }
    else
    {
        new szFlags[25];
        get_flags(g_bitsImmunity, szFlags, charsmax(szFlags));

        server_print("^"dmb_immunity_flags^" is ^"%s^"", szFlags);
    }

    return PLUGIN_HANDLED;
}

#else

public cvar_change_callback(pCvar, const szOldValue[], const szNewValue[])
{
    g_bitsImmunity = szNewValue[0] == '^0' || equali(szNewValue, "empty")
        ? ADMIN_ALL
        : read_flags(szNewValue);
}

#endif


/*************** UTILS and REUSABLE CODE ***************/


stock ModelName:get_opposite_player_model(iPlayer)
{
    switch (get_member(iPlayer, m_iModelName))
    {
        case MODEL_T_TERROR:    return MODEL_CT_URBAN;
        case MODEL_CT_URBAN:    return MODEL_T_TERROR;
        case MODEL_T_LEET:        return MODEL_CT_GSG9;
        case MODEL_CT_GSG9:        return MODEL_T_LEET;
        case MODEL_T_ARCTIC:    return MODEL_CT_SAS;
        case MODEL_CT_SAS:        return MODEL_T_ARCTIC;
        case MODEL_T_GUERILLA:    return MODEL_CT_GIGN;
        case MODEL_CT_GIGN:        return MODEL_T_GUERILLA;
        case MODEL_T_MILITIA:    return MODEL_CT_SPETSNAZ;
        case MODEL_CT_SPETSNAZ:    return MODEL_T_MILITIA;
        case MODEL_CT_VIP:        return MODEL_AUTO;
    }

    return MODEL_UNASSIGNED;
}


stock util_text_msg(iReceiver, iDest, const szMsg[], szParam1[] = "", szParam2[] = "", szParam3[] = "", szParam4[] = "")
{
    static msgTextMsg;
    msgTextMsg || (msgTextMsg = get_user_msgid("TextMsg"));

    message_begin(iReceiver ? MSG_ONE : MSG_ALL, msgTextMsg, _, iReceiver);
    {
        write_byte(iDest);
        write_string(szMsg);
        szParam1[0] && write_string(szParam1);
        szParam2[0] && write_string(szParam2);
        szParam3[0] && write_string(szParam3);
        szParam4[0] && write_string(szParam4);
    }
    message_end();
}


stock util_send_audio(iReceiver, const szSound[], iSender = 0, iPitch = PITCH_NORM)
{
    static msgSendAudio;
    msgSendAudio || (msgSendAudio = get_user_msgid("SendAudio"));

    message_begin(iReceiver ? MSG_ONE : MSG_ALL, msgSendAudio, _, iReceiver);
    {
        write_byte(iSender);
        write_string(szSound);
        write_short(iPitch);
    }
    message_end();
}


stock util_screen_fade(iReceiver, Float:flDuration, Float:flHoldTime, const rgbaColor[4], bitsFlags = 0)
{
    const iScale = 4096;

    new iDuration = util_fixed_ushort(flDuration, iScale);
    new iHoldTime = util_fixed_ushort(flHoldTime, iScale);

    static msgScreenFade;
    msgScreenFade || (msgScreenFade = get_user_msgid("ScreenFade"));

    message_begin(iReceiver ? MSG_ONE : MSG_ALL, msgScreenFade, _, iReceiver);
    {
        write_short(iDuration);
        write_short(iHoldTime);
        write_short(bitsFlags);
        write_byte(rgbaColor[0]);
        write_byte(rgbaColor[1]);
        write_byte(rgbaColor[2]);
        write_byte(rgbaColor[3]);
    }
    message_end();
}


stock util_fixed_ushort(Float:flValue, iScale)
{
    new iOutput = floatround(flValue * iScale);

    if (iOutput < 0)
        return 0;

    const iUshortMax = 0xFFFF;

    if (iOutput > iUshortMax)
        return iUshortMax;

    return iOutput;
}