#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <retakes>

ConVar g_cvSite;

public Plugin myinfo =
{
	name = "Retakes - Site Limiter",
	author = "koen",
	description = "Forces all rounds to be one site (For single bomb site maps)",
	version = "",
	url = "https://github.com/notkoen"
};


public void OnPluginStart()
{
	g_cvSite = CreateConVar("sm_retakes_site", "", "Force retakes to only happen on a bomb site (Use A, B, or leave empty for all)");
	AutoExecConfig(true, "sitelimiter", "sourcemod/retakes");
}

public void Retakes_OnSitePicked(Bombsite& site)
{
	char buffer[8];
	g_cvSite.GetString(buffer, sizeof(buffer));
	if (strlen(buffer) != 0)
	{
		if (StrEqual(buffer, "A", false))
			site = BombsiteA;
		else if (StrEqual(buffer, "B", false))
			site = BombsiteB;
	}
}