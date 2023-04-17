#pragma newdecls required
#pragma semicolon 1

#include <cstrike>
#include <sourcemod>

ConVar g_hMessageFormat;

int g_DamageDone[MAXPLAYERS + 1][MAXPLAYERS + 1];
int g_DamageDoneHits[MAXPLAYERS + 1][MAXPLAYERS + 1];
bool g_GotKill[MAXPLAYERS + 1][MAXPLAYERS + 1];

static char _colorNames[][] = {"{NORMAL}", "{DARK_RED}", "{PINK}", "{GREEN}", "{YELLOW}", "{LIGHT_GREEN}", "{LIGHT_RED}", "{GRAY}", "{ORANGE}", "{LIGHT_BLUE}",  "{DARK_BLUE}", "{PURPLE}"};
static char _colorCodes[][] = {"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x0B", "\x0C", "\x0E"};

public Plugin myinfo =
{
	name = "Retakes - Damage Print",
	author = "koen",
	description = "",
	version = "",
	url = "https://github.com/notkoen"
};

public void OnPluginStart()
{
	LoadTranslations("pugsetup.phrases");
	g_hMessageFormat = CreateConVar("sm_retakes_damageprint_format", "--> ({DMG_TO} dmg / {HITS_TO} hits) ⇄ ({DMG_FROM} dmg / {HITS_FROM} hits) from {NAME} ({HEALTH} HP)", "Format of the damage output string");

	AutoExecConfig(true, "retakes_damageprint", "sourcemod/retakes");

	RegConsoleCmd("sm_dmg", Command_Damage, "Displays damage done");

	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_hurt", Event_DamageDealt, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
}

static void GetDamageColor(char color[16], bool damageGiven, int damage, bool gotKill)
{
	if (damage == 0)
	{
		Format(color, sizeof(color), "NORMAL");
	}
	else if (damageGiven)
	{
		if (gotKill)
			Format(color, sizeof(color), "GREEN");
		else
			Format(color, sizeof(color), "LIGHT_GREEN");
	}
	else
	{
		if (gotKill)
			Format(color, sizeof(color), "DARK_RED");
		else
			Format(color, sizeof(color), "LIGHT_RED");
	}
}

static void PrintDamageInfo(int client)
{
	if (!IsValidClient(client))
		return;

	int team = GetClientTeam(client);
	if (team != CS_TEAM_T && team != CS_TEAM_CT)
		return;

	char message[256];

	int otherTeam = (team == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == otherTeam)
		{
			int health = IsPlayerAlive(i) ? GetClientHealth(i) : 0;
			char name[64];
			GetClientName(i, name, sizeof(name));

			g_hMessageFormat.GetString(message, sizeof(message));

			// Strip colors first.
			Colorize(message, sizeof(message), true);
			char color[16];

			GetDamageColor(color, true, g_DamageDone[client][i], g_GotKill[client][i]);
			ReplaceStringWithColoredInt(message, sizeof(message), "{DMG_TO}", g_DamageDone[client][i],
										color);
			ReplaceStringWithColoredInt(message, sizeof(message), "{HITS_TO}",
										g_DamageDoneHits[client][i], color);

			GetDamageColor(color, false, g_DamageDone[i][client], g_GotKill[i][client]);
			ReplaceStringWithColoredInt(message, sizeof(message), "{DMG_FROM}", g_DamageDone[i][client],
										color);
			ReplaceStringWithColoredInt(message, sizeof(message), "{HITS_FROM}",
										g_DamageDoneHits[i][client], color);

			ReplaceString(message, sizeof(message), "{NAME}", name);
			ReplaceStringWithInt(message, sizeof(message), "{HEALTH}", health);
			Colorize(message, sizeof(message));

			PrintToChat(client, message);
		}
	}
}

public Action Command_Damage(int client, int args)
{
	if (IsPlayerAlive(client))
	{
		ReplyToCommand(client, "You cannot use that command when alive.");
		return Plugin_Handled;
	}

	PrintDamageInfo(client);
	return Plugin_Handled;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			PrintDamageInfo(i);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		for (int j = 1; j <= MaxClients; j++)
		{
			g_DamageDone[i][j] = 0;
			g_DamageDoneHits[i][j] = 0;
			g_GotKill[i][j] = false;
		}
	}
}

public void Event_DamageDealt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	bool validAttacker = IsValidClient(attacker);
	bool validVictim = IsValidClient(victim);

	if (validAttacker && validVictim) {
		int preDamageHealth = GetClientHealth(victim);
		int damage = event.GetInt("dmg_health");
		int postDamageHealth = event.GetInt("health");

		// this maxes the damage variables at 100,
		// so doing 50 damage when the player had 2 health
		// only counts as 2 damage.
		if (postDamageHealth == 0)
			damage += preDamageHealth;

		g_DamageDone[attacker][victim] += damage;
		g_DamageDoneHits[attacker][victim]++;
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	bool validAttacker = IsValidClient(attacker);
	bool validVictim = IsValidClient(victim);

	if (validAttacker && validVictim)
		g_GotKill[attacker][victim] = true;
}

stock bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return false;
	return true;
}

stock void ReplaceStringWithColoredInt(char[] buffer, int len, const char[] replace, int value,const char[] color, bool caseSensitive = false)
{
	char intString[48];
	Format(intString, sizeof(intString), "{%s}%d{NORMAL}", color, value);
	ReplaceString(buffer, len, replace, intString, caseSensitive);
}

stock void ReplaceStringWithInt(char[] buffer, int len, const char[] replace, int value, bool caseSensitive = false)
{
	char intString[16];
	IntToString(value, intString, sizeof(intString));
	ReplaceString(buffer, len, replace, intString, caseSensitive);
}

stock void Colorize(char[] msg, int size, bool stripColor = false)
{
	for (int i = 0; i < sizeof(_colorNames); i++)
	{
		if (stripColor)
			ReplaceString(msg, size, _colorNames[i], "\x01");  // replace with white
		else
			ReplaceString(msg, size, _colorNames[i], _colorCodes[i]);
	}
}
