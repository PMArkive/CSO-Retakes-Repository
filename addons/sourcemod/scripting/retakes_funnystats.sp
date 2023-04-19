// TODO - I want to fucking do code refactoring, the way the printing stats is done...
//			it's utter dogshit lmao. But in all seriousness, I'll redo some logic when I feel like it

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

public Plugin myinfo =
{
	name = "Funny Stats",
	author = "koen",
	description = "record funny stats during retakes",
	version = "",
	url = "https://github.com/notkoen"
};

enum struct PlayerData
{
	int teamflashes;
	int teamkills;
	int teamdamage;
	int noscopes;
	int thrusmoke;
	int blindkills;

	void Reset()
	{
		this.teamflashes = 0;
		this.teamkills = 0;
		this.teamdamage = 0;
		this.noscopes = 0;
		this.thrusmoke = 0;
		this.blindkills = 0;
	}
}

PlayerData g_playerData[MAXPLAYERS+1];

bool g_bRoundStarted;

// Array for storing sorted stats -> [Rank][Value]
int g_iSortedList[MAXPLAYERS+1][2];
int g_iSortedCount = 0;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("cs_win_panel_match", Event_MatchEnd);
	HookEvent("player_blind", Event_PlayerBlind);
}

public void OnMapStart()
{
	// Reset all client stats when the map starts
	for (int client = 1; client <= MaxClients; client++)
		g_playerData[client].Reset();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// When the round starts, enable stat tracking
	g_bRoundStarted = true;
}

public void Event_BombDefused(Event event, const char[] name, bool dontBroadcast)
{
	// After bomb is defused, disable stat tracking as some people like to team kill afterwards
	g_bRoundStarted = false;
}

public void Event_MatchEnd(Event event, const char[] name, bool dontBroadcast)
{
	// Print all stats after the match has ended
	PrintTeamDamage();
	PrintTeamKills();
	PrintTeamFlashes();
	PrintNoscopes();
	PrintThrusmokes();
	PrintBlindKills();
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	// Check if the round has started; If it hasn't, ignore the damage
	if (!g_bRoundStarted)
		return;

	// Obtain player information
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));

	// Check if it was self damage
	if (attacker == victim)
		return;

	// Check if both clients are valid (is this check needed?)
	if (attacker < 1 || attacker > MaxClients || victim < 1 || victim > MaxClients)
		return;

	// Check if both the attacker and the victim are on the same team
	if (GetClientTeam(attacker) == GetClientTeam(victim))
	{
		// Obtain damage done and add it to the total damage dealt
		int damage = event.GetInt("dmg_health");
		g_playerData[attacker].teamdamage += damage;
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// Check if the round started; If it hasn't, ignore the death
	if (!g_bRoundStarted)
		return;

	// Obtain player informations
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));

	// Check if it was a self kill
	if (attacker == victim)
		return;

	// Check if both clients are valid (is this check needed?)
	if (attacker < 1 || attacker > MaxClients || victim < 1 || victim > MaxClients)
		return;

	// Check if both the attacker and the victim are on the same team
	if (GetClientTeam(attacker) == GetClientTeam(victim))
		g_playerData[attacker].teamkills++;

	// Obtain additional information about the kill
	bool noscope = event.GetBool("noscope");
	bool thrusmoke = event.GetBool("thrusmoke");
	bool blind = event.GetBool("attackerblind");

	if (noscope)
		g_playerData[attacker].noscopes++;

	if (thrusmoke)
		g_playerData[attacker].thrusmoke++;

	if (blind)
		g_playerData[attacker].blindkills++;
}

public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
	// Check if the round started; If it hasn't, ignore the flash
	if (!g_bRoundStarted)
		return;

	// Obtain player informations
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));

	// Check if it was a self flash
	if (attacker == victim)
		return;

	// Check if both clients are valid (is this check needed?)
	if (attacker < 1 || attacker > MaxClients || victim < 1 || victim > MaxClients)
		return;

	// Check if both the attacker and the victim are on the same team
	if (GetClientTeam(attacker) == GetClientTeam(victim))
		g_playerData[attacker].teamflashes++;
}

void ResetSortedArray()
{
	// Reset the entire sorted array
	for (int i = 0; i < sizeof(g_iSortedList); i++)
	{
		g_iSortedList[i][0] = -1;
		g_iSortedList[i][1] = 0;
	}
}

void PrintTeamDamage()
{
	// Reset array first
	ResetSortedArray();

	// Begin sorting to find who did the most team damage
	g_iSortedCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		g_iSortedList[g_iSortedCount][0] = client;
		g_iSortedList[g_iSortedCount][1] = g_playerData[client].teamdamage;
		g_iSortedCount++;
	}

	SortCustom2D(g_iSortedList, g_iSortedCount, Sort2DArray);

	// Check if the sorted array's top damage is not 0 then we print the information
	if (g_iSortedList[0][1] != 0)
		PrintToChatAll(" \x0F[Stats] \x04%N \x05did \x04%i \x05to their own teammates!", g_iSortedList[0][0], g_iSortedList[0][1]);
	else
		PrintToChatAll(" \x0F[Stats] \x05Wow! No one damaged their teammates!");
}

void PrintTeamKills()
{
	// Reset array first
	ResetSortedArray();

	// Begin sorting the array to see who killed the most teammates
	g_iSortedCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		g_iSortedList[g_iSortedCount][0] = client;
		g_iSortedList[g_iSortedCount][1] = g_playerData[client].teamkills;
		g_iSortedCount++;
	}

	SortCustom2D(g_iSortedList, g_iSortedCount, Sort2DArray);

	// Check if the sorted array's top teammate killer is not 0 then we print the information
	if (g_iSortedList[0][1] != 0)
		PrintToChatAll(" \x0F[Stats] \x04%N \x05killed \x04%i \x05teammates! What a shame!", g_iSortedList[0][0], g_iSortedList[0][1]);
	else
		PrintToChatAll(" \x0F[Stats] \x05Amazing! No one killed their teammates!");
}

void PrintTeamFlashes()
{
	// Reset array first
	ResetSortedArray();

	// Begin sorting the array to see who flashed the most teammates
	g_iSortedCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		g_iSortedList[g_iSortedCount][0] = client;
		g_iSortedList[g_iSortedCount][1] = g_playerData[client].teamflashes;
		g_iSortedCount++;
	}

	SortCustom2D(g_iSortedList, g_iSortedCount, Sort2DArray);

	// Check if the sorted array's top teammate flasher is not 0 then we print the information
	if (g_iSortedList[0][1] != 0)
		PrintToChatAll(" \x0F[Stats] \x04%N \x05flashed \x04%i \x05teammates! Someone teach this guy how to throw flashes!", g_iSortedList[0][0], g_iSortedList[0][1]);
	else
		PrintToChatAll(" \x0F[Stats] \x05We got some flash masters on the server o_o!!!");
}

void PrintNoscopes()
{
	// Reset array first
	ResetSortedArray();

	// Begin sorting the array to see who got the most noscopes
	g_iSortedCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		g_iSortedList[g_iSortedCount][0] = client;
		g_iSortedList[g_iSortedCount][1] = g_playerData[client].noscopes;
		g_iSortedCount++;
	}

	SortCustom2D(g_iSortedList, g_iSortedCount, Sort2DArray);

	// Check if the sorted array's top noscope amount is not 0 then we print the information
	if (g_iSortedList[0][1] != 0)
		PrintToChatAll(" \x0F[Stats] xXx_\x04%N\x05_xXx is a MLG GOD with \x04%i \x05NOSCOPES!", g_iSortedList[0][0], g_iSortedList[0][1]);
	else
		PrintToChatAll(" \x0F[Stats] \x05Boo... you guys are boring. Go for some fun noscopes please?");
}

void PrintThrusmokes()
{
	// Reset array first
	ResetSortedArray();

	// Begin sorting the array to see who got the most noscopes
	g_iSortedCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		g_iSortedList[g_iSortedCount][0] = client;
		g_iSortedList[g_iSortedCount][1] = g_playerData[client].thrusmoke;
		g_iSortedCount++;
	}

	SortCustom2D(g_iSortedList, g_iSortedCount, Sort2DArray);

	// Check if the sorted array's top thrusmoke kills amount is not 0 then we print the information
	if (g_iSortedList[0][1] != 0)
		PrintToChatAll(" \x0F[Stats] \x05Can an admin check \x04%N\x05's PC? They killed \x04%i \x05enemies through the smoke...", g_iSortedList[0][0], g_iSortedList[0][1]);
	else
		PrintToChatAll(" \x0F[Stats] \x05No one got killed through the smoke! Looks like we have a cheater-free lobby... unless you guys are unlucky");
}

void PrintBlindKills()
{
	// Reset array first
	ResetSortedArray();

	// Begin sorting the array to see who flashed the most teammates
	g_iSortedCount = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		g_iSortedList[g_iSortedCount][0] = client;
		g_iSortedList[g_iSortedCount][1] = g_playerData[client].blindkills;
		g_iSortedCount++;
	}

	SortCustom2D(g_iSortedList, g_iSortedCount, Sort2DArray);

	// Check if the sorted array's top teammate flasher is not 0 then we print the information
	if (g_iSortedList[0][1] != 0)
		PrintToChatAll(" \x0F[Stats] \x04%N \x05managed to kill \x04%i \x05enemies while blind! It was probably luck though...", g_iSortedList[0][0], g_iSortedList[0][1]);
	else
		PrintToChatAll(" \x0F[Stats] \x05Either there were shit flashes or no utility was thrown... because no one killed while blind...");
}

int Sort2DArray(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
	if (elem1[1] > elem2[1])
		return -1;

	if (elem1[1] < elem2[1])
		return 1;

	return 0;
}