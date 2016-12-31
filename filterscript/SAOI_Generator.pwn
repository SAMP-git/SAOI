/****************************************************************************************************
 *                                                                                                  *
 *                                        Easy SAOI Creator                                         *
 *                                                                                                  *
 * Copyright � 2017 Abyss Morgan. All rights reserved.                                              *
 *                                                                                                  *
 * Download: https://github.com/AbyssMorgan/SAOI/blob/master/filterscript                           *
 *                                                                                                  *
 * Plugins: Streamer, SScanf                                                                        *
 * Modules: SAOI, ObjectDist                                                                        *
 *                                                                                                  *
 * File Version: 1.0.1                                                                              *
 * SA:MP Version: 0.3.7                                                                             *
 * Streamer Version: 2.8.2                                                                          *
 * SScanf Version: 2.8.2                                                                            *
 * SAOI Version: 1.4.0                                                                              *
 *                                                                                                  *
 ****************************************************************************************************/
 
//Example meta:
#define MY_SAOI_FILE		"Object.saoi"
#define SAOI_AUTHOR			"Gizmo"
#define SAOI_VERSION		"1.0r1"
#define SAOI_DESCRIPTION	"Bank Interior"

#include <a_samp>
#include <sscanf2>
#include <streamer>

#include <SAOI>
#include <ObjectDist>

//Check Version SAOI.inc
#if !defined _SAOI_LOADER
	#error You need SAOI.inc v1.5.0
#elseif !defined SAOI_LOADER_VERSION
	#error Update you SAOI.inc to v1.5.0
#elseif (SAOI_LOADER_VERSION < 10500)
	#error Update you SAOI.inc to v1.5.0
#endif

//Hook: CreateDynamicObject
stock STREAMER_TAG_OBJECT AC_CreateDynamicObject(modelid,Float:x,Float:y,Float:z,Float:rx,Float:ry,Float:rz,worldid = -1,interiorid = -1,playerid = -1,Float:streamdistance = STREAMER_OBJECT_SD,Float:drawdistance = STREAMER_OBJECT_DD,STREAMER_TAG_AREA areaid = STREAMER_TAG_AREA -1,priority = 0){
	if(streamdistance == -1) streamdistance = CalculateObjectDistance(modelid);
	new STREAMER_TAG_OBJECT objectid = CreateDynamicObject(modelid,x,y,z,rx,ry,rz,worldid,interiorid,playerid,streamdistance,drawdistance,areaid,priority);
	Streamer_SetIntData(STREAMER_TYPE_OBJECT,objectid,E_STREAMER_EXTRA_ID,SAOI_EXTRA_ID_OFFSET);
	return objectid;
}

#if defined _ALS_CreateDynamicObject
	#undef CreateDynamicObject
#else
	#define _ALS_CreateDynamicObject
#endif
#define CreateDynamicObject AC_CreateDynamicObject

//Hook: RemoveBuildingForPlayer
stock AC_RemoveBuildingForPlayer(playerid,modelid,Float:x,Float:y,Float:z,Float:radius){
	#pragma unused playerid
	SaveRemoveBuilding(MY_SAOI_FILE,modelid,x,y,z,radius);
}

#if defined _ALS_RemoveBuildingForPlayer
	#undef RemoveBuildingForPlayer
#else
	#define _ALS_RemoveBuildingForPlayer
#endif
#define RemoveBuildingForPlayer AC_RemoveBuildingForPlayer

stock PutObjectHere(){
	new playerid;
	//Put Object Here
	

	//Put Object Here
}

public OnFilterScriptInit(){
	
	if(fexist(MY_SAOI_FILE)) fremove(MY_SAOI_FILE);
	CreateSAOIFile(MY_SAOI_FILE,SAOI_AUTHOR,SAOI_VERSION,SAOI_DESCRIPTION);
	PutObjectHere();
	
	for(new i = 1, j = Streamer_GetUpperBound(STREAMER_TYPE_OBJECT); i <= j; i++){
		if(IsValidDynamicObject(i)){
			if(Streamer_GetIntData(STREAMER_TYPE_OBJECT,i,E_STREAMER_EXTRA_ID) == SAOI_EXTRA_ID_OFFSET){
				SaveDynamicObject(i,MY_SAOI_FILE);
				DestroyDynamicObject(i);
			}
		}
	}
	
	return 1;
}

