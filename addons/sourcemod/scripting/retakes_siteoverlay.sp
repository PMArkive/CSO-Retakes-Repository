#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <retakes>

// Private plugin, use fys.huds by kxnrl (https://github.com/Kxnrl/CSGO-HtmlHud)
#include <UIManager>

ConVar g_cvTime;

public Plugin myinfo =
{
	name = "Retake - Bombsite overlays",
	author = "koen",
	description = "",
	version = "",
	url = "https://github.com/notkoen"
};


public void OnPluginStart()
{
	g_cvTime = CreateConVar("sm_retake_overlays_time", "5.0", "How long show the Bombsite overlays? in seconds", _, true, 1.0);
	AutoExecConfig(true, "overlays", "sourcemod/retakes");
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Bombsite site = Retakes_GetCurrrentBombsite();

	if (site == BombsiteA)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			if (GetClientTeam(i) == CS_TEAM_CT)
				SendHtmlHud(i, g_cvTime.FloatValue, true, "<font class='fontSize-xl'>Retake: <font color='#00FF00'>A</font></font>");
			else if (GetClientTeam(i) == CS_TEAM_T)
				SendHtmlHud(i, g_cvTime.FloatValue, true, "<font class='fontSize-xl'>Defend: <font color='#00FF00'>A</font></font>");
		}
	}
	else if (site == BombsiteB)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			if (GetClientTeam(i) == CS_TEAM_CT)
				SendHtmlHud(i, g_cvTime.FloatValue, true, "<font class='fontSize-xl'>Retake: <font color='#00FF00'>B</font></font>");
			else if (GetClientTeam(i) == CS_TEAM_T)
				SendHtmlHud(i, g_cvTime.FloatValue, true, "<font class='fontSize-xl'>Defend: <font color='#00FF00'>B</font></font>");
		}
	}
}