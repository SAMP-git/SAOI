/****************************************************************************************************
 *                                                                                                  *
 * Easy SAOI Creator v1.0 made by Abyss Morgan                                                      *
 *                                                                                                  *
 * Download: https://github.com/AbyssMorgan/SA-MP/tree/master/include/core                          *
 *                                                                                                  *
 ****************************************************************************************************/
 
#define MY_SAOI_FILE		"Object.saoi"	//example
#define SAOI_AUTHOR			"Gizmo"			//example
#define SAOI_VERSION		"1.0r1"			//example
#define SAOI_DESCRIPTION	"Bank Interior"	//example

#include <a_samp>
#include <streamer>

#include "SAOI.inc"
#include "ObjectDist.inc"

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


stock PutObjectHere(){
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

