#pragma semicolon 1

#define PLUGIN_NAME "Speak To All"
#define PLUGIN_AUTHOR "Gabriel Hirakawa"
#define PLUGIN_DESCRIPTION "Allows admins to speak to all players on command"
#define PLUGIN_VERSION "1.0.3"
#define PLUGIN_URL "https://gkh.systems"
#define UPDATE_URL "https://gkh.systems/git/SpeakToAll/update.txt"

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGINz
#include <updater>

#pragma newdecls required

bool g_bSpeakingToAll[MAXPLAYERS + 1];
ConVar g_cvRoundEnd;
ConVar g_cvMuteAll;

public Plugin myinfo =
{
  name = PLUGIN_NAME,
  author = PLUGIN_AUTHOR,
  description = PLUGIN_DESCRIPTION,
  version = PLUGIN_VERSION,
  url = PLUGIN_URL
};

public void OnPluginStart()
{
  if (LibraryExists("updater")) {
    Updater_AddPlugin(UPDATE_URL);
  }
  RegAdminCmd("sm_speaktoall", Command_SpeakToAll, ADMFLAG_KICK,
                                          "sm_speaktoall - Allows Admins to speak to all players ");
  g_cvRoundEnd = CreateConVar("sm_speaktoall_roundend", "0",
                                "If enabled, on round end, all players will be set back to normal");
  g_cvMuteAll = CreateConVar("sm_speaktoall_muteall", "1",
                   "If enabled, when an admin activates speaktoall it will mute all other players");
  HookEvent("round_end", Event_RoundEnd);
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater")) {
        Updater_AddPlugin(UPDATE_URL);
    }
}


public Action Command_SpeakToAll(int client, int args)
{
  if (!client || !IsClientInGame(client) || IsFakeClient(client)) {
    PrintToServer("[SM] %T", "STA_NonClientError");
    return Plugin_Continue;
  }

  if (g_bSpeakingToAll[client]) {
    g_bSpeakingToAll[client] = false;
    SetClientListeningFlags(client, (GetClientListeningFlags(client) & ~VOICE_SPEAKALL));
    ReplyToCommand(client, "[SM] %T", "STA_Disable");
    UnMuteAll(client);
  }
  else {
    g_bSpeakingToAll[client] = true;
    SetClientListeningFlags(client, (GetClientListeningFlags(client) | VOICE_SPEAKALL));
    ReplyToCommand(client, "[SM] %T", "STA_Enable");
    if (g_cvMuteAll.IntValue == 1) {
      MuteAll(client);
    }
  }
  return Plugin_Handled;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
  if (g_cvRoundEnd.IntValue == 1) {
    for (int i = 1; i < MaxClients; i++) {
      if (g_bSpeakingToAll[i] == true) {
        g_bSpeakingToAll[i] = false;
        SetClientListeningFlags(i, (GetClientListeningFlags(i) & ~VOICE_SPEAKALL));
        PrintToChat(i, "\x04[SM] %T", "STA_RoundEnd");
      }
    }
  }
}

void MuteAll(int client)
{
  for (int i = 1; i < MaxClients; i++) {
    if (IsClientInGame(i) && i != client) {
      SetClientListeningFlags(i, (GetClientListeningFlags(i) | VOICE_MUTED));
      PrintToChat(i, "[SM] %T", "STA_MuteAll");
      LogAction(i, -1, "%L toggled speak to all", client);
    }
  }
}

void UnMuteAll(int client)
{
  for (int i = 1; i < MaxClients; i++) {
    if (IsClientInGame(i) && i != client) {
      SetClientListeningFlags(i, (GetClientListeningFlags(i) | VOICE_NORMAL));
      PrintToChat(i, "[SM] %T", "STA_UnMuteAll");
      LogAction(i, -1, "%L untoggled speak to all", client);
    }
  }
}
