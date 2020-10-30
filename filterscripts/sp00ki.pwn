// Sp00ki made by Se8870
// Ofc i didn't own the model

#include <a_samp>
#include <streamer>

#define FILTERSCRIPT

// Config
#define MAX_JUMPSCARE_RADIUS    5.0

#define MAX_GHOST_MOVEABLE_TIME 5 //in seconds
#define MAX_GHOST_REVIVE_TIME   10 //in seconds

// Forward
forward OnGhostHaunting(playerid);
forward OnGhostAttackPlayer(playerid); 

// Enum
enum E_GHOST_DATA {
    ghostId,
    ghostHauntCount,
    bool:ghostCanAttack,
    bool:ghostDied,
    ghostSpawnCount,
    ghostCountTimer
}

// Ghost Spot
stock const Float:arrGhostLocation[] = {
    950.0, -1057.0, 951.0, -1130.0,
    807.0, -1129.0, 806.0, -1073.0, 
    831.0, -1069.0, 865.0, -1071.0, 
    874.0, -1064.0, 877.0, -1056.0, 
    950.0, -1057.0
};

// Global Variables
new 
    GhostArea,
    Text:jumpscareModel,
    PlayerInGhostArea[MAX_PLAYERS],
    GhostInfo[MAX_PLAYERS][E_GHOST_DATA];

public OnFilterScriptInit() {
    print("------------------------------");
    print("    Sp00ki Ghost | Se8870     ");
    print("------------------------------");

    GhostArea = CreateDynamicPolygon(arrGhostLocation);

    // Create Jumpscare Textdraw
    jumpscareModel = TextDrawCreate(-54.999984, -96.792579, "mdl-2001:ghost");
    TextDrawLetterSize(jumpscareModel, 0.000000, 0.000000);
    TextDrawTextSize(jumpscareModel, 776.000000, 596.000000);
    TextDrawAlignment(jumpscareModel, 1);
    TextDrawColor(jumpscareModel, -1);
    TextDrawSetShadow(jumpscareModel, 0);
    TextDrawSetOutline(jumpscareModel, 0);
    TextDrawBackgroundColor(jumpscareModel, 255);
    TextDrawFont(jumpscareModel, 4);
    TextDrawSetProportional(jumpscareModel, 0);
    TextDrawSetShadow(jumpscareModel, 0);
    return 1;
}

public OnFilterScriptExit() {
    TextDrawDestroy(jumpscareModel);

    DestroyAllDynamicAreas();

    for (new i, j = GetPlayerPoolSize(); i < j; i ++) {
        GhostInfo[i][ghostDied] = true;

        DestroyPlayerObject(i, GhostInfo[i][ghostId]);
        KillTimer(GhostInfo[i][ghostCountTimer]);

        new varReset[E_GHOST_DATA];
        GhostInfo[i] = varReset;
    }    
    return 1;
}

public OnPlayerConnect(playerid) {
    new varReset[E_GHOST_DATA];
    GhostInfo[playerid] = varReset;
    return 1;
}

public OnPlayerDisconnect(playerid, reason) {
    PlayerInGhostArea[playerid] = false;
    return 1;
}

public OnPlayerEnterDynamicArea(playerid, areaid) {
    if (areaid == GhostArea) {
        new 
            Float:plrX, Float:plrY, Float:plrZ;
        
        GetPlayerPos(playerid, plrX, plrY, plrZ);
        GetXYFromAngle(plrX, plrY, random(360), 15.0);
        
        PlayerInGhostArea[playerid] = true; 
        GhostInfo[playerid][ghostId] = CreatePlayerObject(playerid, -2000, plrX, plrY, plrZ, 0.0, -90.0, 0.0, 30.0);
        GhostInfo[playerid][ghostCountTimer] = SetTimerEx(#OnGhostHaunting, 1000, true, "i", playerid);
    }
    return 1;
}

public OnPlayerLeaveDynamicArea(playerid, areaid) {
    if (areaid == GhostArea) {
        PlayerInGhostArea[playerid] = false;
    }
    return 1;
}

public OnGhostHaunting(playerid) {
    if (!PlayerInGhostArea[playerid]) {
        DestroyPlayerObject(playerid, GhostInfo[playerid][ghostId]);

        new varReset[E_GHOST_DATA];
        GhostInfo[playerid] = varReset;
        KillTimer(GhostInfo[playerid][ghostCountTimer]);
        return 0;
    }

    if (GhostInfo[playerid][ghostDied]) {
        if (++ GhostInfo[playerid][ghostSpawnCount] >= MAX_GHOST_REVIVE_TIME) {
            GhostInfo[playerid][ghostSpawnCount] = 0;
            GhostInfo[playerid][ghostDied] = false;
        }
        return 0;
    }

    if (GhostInfo[playerid][ghostCanAttack]) {
        TextDrawHideForPlayer(playerid, jumpscareModel);
        SendClientMessage(playerid, -1, "Damn you got scared to death bro!");

        SetPlayerHealth(playerid, 0.0);
        GhostInfo[playerid][ghostCanAttack] = false;
        return 0;
    }

    new 
        Float:plrX, Float:plrY, Float:plrZ,
        Float:plrA, Float:objX, Float:objY,
        Float:objZ;

    GetPlayerPos(playerid, plrX, plrY, plrZ);
    GetPlayerFacingAngle(playerid, plrA);
    GetPlayerObjectPos(playerid, GhostInfo[playerid][ghostId], objX, objY, objZ);

    if (GetDistance3D(plrX, plrY, plrZ, objX, objY, objZ) <= MAX_JUMPSCARE_RADIUS) {
        // Give info so the timer won't update.
        GhostInfo[playerid][ghostCanAttack] = true;
        OnGhostAttackPlayer(playerid);
        return 0;
    }

    // Our ghost routine
    if (++ GhostInfo[playerid][ghostHauntCount] >= MAX_GHOST_MOVEABLE_TIME) { 
        if (IsPlayerFacingPos(playerid, plrA, objX, objY)) {
            GetXYFromAngle(plrX, plrY, float(random(360)), 15.0);

            DestroyPlayerObject(playerid, GhostInfo[playerid][ghostId]);
            GhostInfo[playerid][ghostId] = CreatePlayerObject(playerid, -2000, plrX, plrY, plrZ, 0.0, -90.0, 0.0, 30.0);
        }
        GhostInfo[playerid][ghostHauntCount] = 0;
    }
    return 1;
}

public OnGhostAttackPlayer(playerid) {
    TextDrawShowForPlayer(playerid, jumpscareModel);
    PlayerPlaySound(playerid, 10610, 0.0, 0.0, 0.0);
    return 1;
}

// By Southclaws
// https://github.com/ScavengeSurvive/mathutil/blob/master/mathutil.inc#L32
stock Float:GetDistance3D(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2) {
	return floatsqroot(((x1 - x2) * (x1 - x2)) + ((y1 - y2) * (y1 - y2)) + ((z1 - z2) * (z1 - z2)));
}

// https://github.com/ScavengeSurvive/mathutil/blob/master/mathutil.inc#L65
stock GetXYFromAngle(&Float:x, &Float:y, Float:a, Float:distance) {
	x += (distance*floatsin(-a,degrees));
	y += (distance*floatcos(-a,degrees));
}

// By Nero 3D on sa-mp forums
stock IsPlayerFacingPos(playerid, Float:deg, Float:X, Float:Y) {
    new
        Float: pX,
        Float: pY,
        Float: pZ
    ;
    if(GetPlayerPos(playerid, pX, pY, pZ)) {
        pX = -atan2(pX - X, pY - Y);

        if(pX < 0.0) {
            pX += 360.0;
        }
        GetPlayerFacingAngle(playerid, pY);

        pX -= pY;

        if(pX < -180) {
            pX += 360.0;
        }
        else if(pX > 180.0) {
            pX -= 360.0;
        }
        return (-deg < pX < deg);
    }
    return false;
}
