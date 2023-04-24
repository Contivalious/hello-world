#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
    name = "MyJailbreak - Logs",
    author = "YourName",
    description = "Logs various events during a jailbreak round.",
    version = "1.0.0",
    url = "https://github.com/YourGitHubAccount/YourRepository"
};

ArrayList g_logs;

public void OnPluginStart()
{
    // Initialize the logs ArrayList
    g_logs = new ArrayList();

    // Register the chat command
    RegConsoleCmd("sm_logs", Command_Logs, "Show the logs of the current jailbreak round.");

    // Register event hooks
    HookEvent("player_use", Event_PlayerUse, EventHookMode_Pre);
    HookEvent("break_prop", Event_BreakProp, EventHookMode_Pre);
    HookEvent("player_drop_weapon", Event_PlayerDropWeapon, EventHookMode_Pre);
    HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Pre);

    // Register game frame hook using a timer
    Handle timer = CreateTimer(0.1, OnGameFrame, TIMER_REPEAT);
}

public Action Command_Logs(int client, int args)
{
    // Display the logs to the client
    int logCount = g_logs.Length();
    if (logCount == 0)
    {
        PrintToChat(client, "No logs available.");
    }
    else
    {
        PrintToChat(client, "Jailbreak Logs:");
        for (int i = 0; i < logCount; i++)
        {
            char log[256];
            g_logs.GetString(i, log, sizeof(log));
            PrintToChat(client, log);
        }
    }
    return Plugin_Handled;
}

public Action Event_PlayerUse(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    // Log the player pressing a button
    char playerName[64];
    GetClientName(client, playerName, sizeof(playerName));
    AddLog("[%T] %s pressed a button.", playerName);
    return Plugin_Continue;
}

public Action Event_BreakProp(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    // Log the player breaking a vent
    char playerName[64];
    GetClientName(client, playerName, sizeof(playerName));
    AddLog("[%T] %s broke a vent.", playerName);
    return Plugin_Continue;
}

public Action Event_PlayerDropWeapon(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    // Log the player dropping a gun
    char playerName[64];
    GetClientName(client, playerName, sizeof(playerName));
    AddLog("[%T] %s dropped a gun.", playerName);
    return Plugin_Continue;
}

public Action Event_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    // Log the player shooting or knifing a gun
    char playerName[64];
    GetClientName(client, playerName, sizeof(playerName));
    AddLog("[%T] %s fired their weapon.", playerName);
    return Plugin_Continue;
}

public Action OnGameFrame(Handle timer)
{
    // Track and log weapon passing between players
    int clientCount = GetClientCount();
    for (int i = 1; i <= clientCount; i++)
    {
        if (!IsClientInGame(i) || IsClientSourceTV(i) || IsClientReplay(i))
        {
            continue;
        }

        // Check if the player is holding a weapon
        int weaponEntity = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
        if (weaponEntity == -1)
        {
            continue;
        }

        // Check if the weapon is being passed to another player
        int weaponOwner = GetEntProp(weaponEntity, Prop_Send, "m_hOwnerEntity", _, true);
        if (weaponOwner == -1 || weaponOwner == i)
        {
            continue;
        }

        // Verify if the new owner is a valid client
        if (IsClientInGame(weaponOwner) && !IsClientSourceTV(weaponOwner) && !IsClientReplay(weaponOwner))
        {
            // Log the weapon passing event
            char giverName[64], receiverName[64];
            GetClientName(i, giverName, sizeof(giverName));
            GetClientName(weaponOwner, receiverName, sizeof(receiverName));
            AddLog("[%T] %s passed a gun to %s.", giverName, receiverName);
            
            // Set the new owner to the weapon entity
            SetEntProp(weaponEntity, Prop_Send, "m_hOwnerEntity", weaponOwner, true);
        }
    }
    return Plugin_Continue;
}

void AddLog(const char[] format, any ...)
{
    char log[256];
    VFormat(log, sizeof(log), format, 3);

    // Add log to the ArrayList
    g_logs.PushString(log);
}

