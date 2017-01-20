/****************************************************************************************************
 *                                                                                                  *
 *                                        SAOI File Manager                                         *
 *                                                                                                  *
 * Copyright © 2017 Abyss Morgan. All rights reserved.                                              *
 *                                                                                                  *
 * Download: https://github.com/AbyssMorgan/SAOI/blob/master/filterscript                           *
 *                                                                                                  *
 * Plugins: Streamer, SScanf, MapAndreas/ColAndreas, YSF                                            *
 * Modules: SAOI, 3DTryg, StreamerFunction, IZCMD/ZCMD                                              *
 *                                                                                                  *
 * File Version: 1.5.0                                                                              *
 * SA:MP Version: 0.3.7                                                                             *
 * Streamer Version: 2.8.2                                                                          *
 * SScanf Version: 2.8.2                                                                            *
 * MapAndreas Version: 1.2.1                                                                        *
 * ColAndreas Version: 1.4.0                                                                        *
 * SAOI Version: 1.5.1                                                                              *
 * 3DTryg Version: 3.2.2                                                                            *
 * StreamerFunction Version: 2.5.8                                                                  *
 * YSF Version: R18                                                                                 *
 *                                                                                                  *
 * Notice:                                                                                          *
 * Required directory /scriptfiles/SAOI                                                             *
 *                                                                                                  *
 * Commands:                                                                                        *
 * /saoicmd - show saoi cmd                                                                         *
 * /saoi - shows statistics saoi                                                                    * 
 * /saoifinder - element finder                                                                     *
 * /objstatus - show total object status                                                            *
 * /saoiinfo - show saoi file information                                                           *
 * /saoiload - load saoi file                                                                       *
 * /saoiunload - unload saoi file                                                                   *
 * /saoireload - reload saoi file                                                                   *
 * /saoilist - show loaded saoi files                                                               *
 * /streaminfo - show stream info                                                                   *
 * /saoitp - teleport to saoi flag                                                                  *
 * /tptoobj - teleport to object                                                                    *
 * /delobject - destroy dynamic object                                                              *
 * /delpickup - destroy dynamic pickup                                                              *
 * /delmapicon - destroy dynamic mapicon                                                            *
 * /objmaterial - get object materials                                                              *
 * /objmaterialtext - get object material text                                                      *
 *                                                                                                  *
 ****************************************************************************************************/
 
#define FILTERSCRIPT
#define LOCK_SAOI_MEMORY	"SAOI_FileManager"

#include <a_samp>

#if !defined _actor_included
	#include <a_actor>
#endif

#include <sscanf2>
#include <streamer>
#tryinclude <YSF>

#tryinclude <izcmd>
#if !defined CMD
	#include <zcmd>
#endif

#tryinclude <colandreas>
#if !defined COLANDREAS
	#include <mapandreas>
#endif

#include <SAM/StreamerFunction>
#include <SAM/3DTryg>
#include <SAOI>

#define SAOI_FILE_LIST				"/SAOI/SaoiFiles.txt"

#define MAX_FIND_DYNAMIC_OBJECT		(2048)
#define MAX_FIND_DYNAMIC_PICKUP		(512)
#define MAX_FIND_DYNAMIC_CP			(512)
#define MAX_FIND_DYNAMIC_RACECP		(512)
#define MAX_FIND_DYNAMIC_MAPICON	(512)
#define MAX_FIND_OBJECT				(512)
#define MAX_FIND_PICKUP				(512)
#define MAX_FIND_ACTOR				(1000)
#define MAX_FIND_VEHICLE			(2000)
#define MAX_FIND_REMOVEBUILDING		(1000)

#define MAX_PATH					(70)

#define IsAdmin(%0)					IsPlayerAdmin(%0)

#define DIALOG_OFFSET				(1000)
#define DIALOG_SAOI_NUL				(DIALOG_OFFSET+(0))
#define DIALOG_SAOI_INFO			(DIALOG_OFFSET+(1))
#define DIALOG_SAOI_LIST			(DIALOG_OFFSET+(2))
#define DIALOG_SAOI_ITEM			(DIALOG_OFFSET+(3))
#define DIALOG_SAOI_FINDER			(DIALOG_OFFSET+(4))
#define DIALOG_SAOI_FINDER_DISABLE	(DIALOG_OFFSET+(5))
#define DIALOG_SAOI_FINDER_PARAMS	(DIALOG_OFFSET+(6))

//Check Version StreamerFunction.inc
#if !defined _streamer_spec
	#error [ADM] You need StreamerFunction.inc v2.5.8
#elseif !defined Streamer_Spec_Version
	#error [ADM] Update you StreamerFunction.inc to v2.5.8
#elseif (Streamer_Spec_Version < 20508)
	#error [ADM] Update you StreamerFunction.inc to v2.5.8
#endif

//Check Version 3DTryg.inc
#if !defined _3D_Tryg
	#error [ADM] You need 3DTryg.inc v3.2.2
#elseif !defined Tryg3D_Version
	#error [ADM] Update you 3DTryg.inc to v3.2.2
#elseif (Tryg3D_Version < 30202)
	#error [ADM] Update you 3DTryg.inc to v3.2.2
#endif

//Check Version SAOI.inc
#if !defined _SAOI_LOADER
	#error You need SAOI.inc v1.5.1
#elseif !defined SAOI_LOADER_VERSION
	#error Update you SAOI.inc to v1.5.1
#elseif (SAOI_LOADER_VERSION < 10501)
	#error Update you SAOI.inc to v1.5.1
#endif

#if (!defined Tryg3D_MapAndreas && !defined Tryg3D_ColAndreas)
	#error [ADM] You need MapAndreas or ColAndreas
#endif

#define SAOI_SecToTimeDay(%0)		((%0) / 86400),(((%0) % 86400) / 3600),((((%0) % 86400) % 3600) / 60),((((%0) % 86400) % 3600) % 60)
#define SAOI_MSToTimeDay(%0)		SAOI_SecToTimeDay((%0)/1000)

enum find_elements {
	e_dynamic_object,
	e_dynamic_pickup,
	e_dynamic_cp,
	e_dynamic_racecp,
	e_dynamic_mapicon,
	e_object,
	e_pickup,
	e_actor,
	e_vehicle,
	e_removebuilding
}

enum find_option {
	bool:o_active,
	o_count,
	o_max
}

new elements_name[][] = {
	"DynamicObject",
	"DynamicPickup",
	"DynamicCP",
	"DynamicRaceCP",
	"DynamicMapIcon",
	"Object",
	"Pickup",
	"Actor",
	"Vehicle",
	"RemoveBuilding"
};

new Text3D:FindDynamicObjectLabel[MAX_FIND_DYNAMIC_OBJECT],
	Text3D:FindDynamicPickupLabel[MAX_FIND_DYNAMIC_PICKUP],
	Text3D:FindDynamicCPLabel[MAX_FIND_DYNAMIC_CP],
	Text3D:FindDynamicRaceCPLabel[MAX_FIND_DYNAMIC_RACECP],
	Text3D:FindDynamicMapIconLabel[MAX_FIND_DYNAMIC_MAPICON],
	Text3D:FindActorLabel[MAX_FIND_ACTOR],
	Text3D:FindRemoveBuildingsLabel[MAX_FIND_REMOVEBUILDING],
	SAOI_Finder[find_elements][find_option],
	SAOI:PlayerLastSAOI[MAX_PLAYERS],
	PlayerLastItem[MAX_PLAYERS];

#if defined _YSF_included
	new	Text3D:FindObjectLabel[MAX_FIND_OBJECT],
		Text3D:FindPickupLabel[MAX_FIND_PICKUP],
		Text3D:FindVehicleLabel[MAX_FIND_VEHICLE];
#endif

stock PrintSAOIErrorName(SAOI:index){
	switch(index){
		case SAOI_ERROR_UNEXEC: 				printf("Error function unexecutable");
		case SAOI_ERROR_SUCCESS:				printf("Success");
		case SAOI_ERROR_INPUT_NOT_EXIST: 		printf("Error input file not exist");
		case SAOI_ERROR_OUTPUT_NOT_EXIST: 		printf("Error output file not exist");
		case SAOI_ERROR_INPUT_EXIST: 			printf("Error input file exist");
		case SAOI_ERROR_OUTPUT_EXIST:		 	printf("Error output file exist");
		case SAOI_ERROR_INPUT_NOT_OPEN: 		printf("Error open input file");
		case SAOI_ERROR_OUTPUT_NOT_OPEN: 		printf("Error open output file");
		case SAOI_ERROR_FILE_SIZE: 				printf("Error invalid file size");
		case SAOI_ERROR_INVALID_OBJECTID:	 	printf("Error invalid objectid");
		case SAOI_ERROR_AUTHOR_SIZE: 			printf("Error invalid author size");
		case SAOI_ERROR_VERSION_SIZE: 			printf("Error invalid version size");
		case SAOI_ERROR_DESCRIPTION_SIZE:	 	printf("Error invalid description size");
		case SAOI_ERROR_INVALID_HEADER: 		printf("Error invalid header");
		case SAOI_ERROR_INPUT_EXTENSION: 		printf("Error invalid input extension");
		case SAOI_ERROR_OUTPUT_EXTENSION: 		printf("Error invalid output extension");
		case SAOI_ERROR_NOT_ENOUGH_CAPACITY: 	printf("Error not enough capacity, to load new file");
		case SAOI_ERROR_INVALID_ARG_COUNT: 		printf("Error number of arguments exceeds the specified arguments");
		case SAOI_ERROR_INVALID_SERVER_IP:		printf("Error invalid server ip");
		case SAOI_ERROR_INVALID_SERVER_PORT:	printf("Error invalid server port");
		case SAOI_ERROR_MEMORY_BLOCKED:			printf("Error memory blocked");
	}
}

//FINDER:DynamicObject
stock SAOI_FindDynamicObject(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz, index, fname[MAX_PATH],
		Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz, Float:sd, Float:dd;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicObjects(i){
		if(cnt >= MAX_FIND_DYNAMIC_OBJECT) break;
		if(IsValidDynamicObject(i)){
			GetDynamicObjectPos(i,x,y,z);
			if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
				GetDynamicObjectRot(i,rx,ry,rz);
				GetDynamicObjectSD(i,sd);
				GetDynamicObjectDD(i,dd);
				szLIST = "";
				index = Streamer_GetIntData(STREAMER_TYPE_OBJECT,i,E_STREAMER_EXTRA_ID);
				if(index > SAOI_EXTRA_ID_OFFSET && index < SAOI_EXTRA_ID_OFFSET+SAOIToInt(MAX_SAOI_FILE)){
					index -= SAOI_EXTRA_ID_OFFSET;
					GetSAOILoadData(SAOI:index,fname);
					format(buffer,sizeof buffer,"{89C1FA}SAOI Name: {00AAFF}%s.saoi\n",fname[6]);
					strcat(szLIST,buffer);
				}
				format(buffer,sizeof buffer,"{89C1FA}DynamicObject: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %.0f %d %d)\n",i,GetDynamicObjectModel(i),GetDynamicObjectVW(i),GetDynamicObjectINT(i),sd,dd,GetDynamicObjectArea(i),GetDynamicObjectPriority(i));
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f,%.7f,%.7f)",x,y,z,rx,ry,rz);
				strcat(szLIST,buffer);
				FindDynamicObjectLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
				cnt++;
			}
		}
		SAOI_Finder[e_dynamic_object][o_count] = cnt;
	}
}

stock SAOI_RemoveFindDynamicObject(){
	for(new i = 0; i < MAX_FIND_DYNAMIC_OBJECT; i++){
		if(IsValidDynamic3DTextLabel(FindDynamicObjectLabel[i])) DestroyDynamic3DTextLabel(FindDynamicObjectLabel[i]);
	}
}

//FINDER:DynamicPickup
stock SAOI_FindDynamicPickup(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz,
		Float:x, Float:y, Float:z, Float:sd;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicPickups(i){
		if(cnt >= MAX_FIND_DYNAMIC_PICKUP) break;
		if(IsValidDynamicPickup(i)){
			GetDynamicPickupPos(i,x,y,z);
			if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
				GetDynamicPickupSD(i,sd);
				szLIST = "";
				format(buffer,sizeof buffer,"{89C1FA}DynamicPickup: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %d %d)\n",i,GetDynamicPickupModel(i),GetDynamicPickupVW(i),GetDynamicPickupINT(i),sd,GetDynamicPickupArea(i),GetDynamicPickupPriority(i));
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f) {89C1FA}Type: {00AAFF}(%d)",x,y,z,GetDynamicPickupType(i));
				strcat(szLIST,buffer);
				FindDynamicPickupLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
				cnt++;
			}
		}
		SAOI_Finder[e_dynamic_pickup][o_count] = cnt;
	}
}

stock SAOI_RemoveFindDynamicPickup(){
	for(new i = 0; i < MAX_FIND_DYNAMIC_PICKUP; i++){
		if(IsValidDynamic3DTextLabel(FindDynamicPickupLabel[i])) DestroyDynamic3DTextLabel(FindDynamicPickupLabel[i]);
	}
}

//FINDER:DynamicMapIcon
stock SAOI_FindDynamicMapIcon(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz, Float:mz,
		Float:x, Float:y, Float:z, Float:sd;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicMapIcons(i){
		if(cnt >= MAX_FIND_DYNAMIC_MAPICON) break;
		if(IsValidDynamicMapIcon(i)){
			GetDynamicMapIconPos(i,x,y,z);
			if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
				GetDynamicMapIconSD(i,sd);
				Tryg3DMapAndreasFindZ(x,y,mz);
				szLIST = "";
				format(buffer,sizeof buffer,"{89C1FA}DynamicMapIcon: {00AAFF}(%d) {89C1FA}Type: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %d %d)\n",i,GetDynamicMapIconType(i),GetDynamicMapIconVW(i),GetDynamicMapIconINT(i),sd,GetDynamicMapIconArea(i),GetDynamicMapIconPriority(i));
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f)\n",x,y,z);
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Color: {00AAFF}(0x%08x) {89C1FA}Style: {00AAFF}(%d)",GetDynamicMapIconColor(i),GetDynamicMapIconStyle(i));
				strcat(szLIST,buffer);
				FindDynamicMapIconLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,mz+1.0,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
				cnt++;
			}
		}
		SAOI_Finder[e_dynamic_mapicon][o_count] = cnt;
	}
}

stock SAOI_RemoveFindDynamicMapIcon(){
	for(new i = 0; i < MAX_FIND_DYNAMIC_MAPICON; i++){
		if(IsValidDynamic3DTextLabel(FindDynamicMapIconLabel[i])) DestroyDynamic3DTextLabel(FindDynamicMapIconLabel[i]);
	}
}

#if defined _YSF_included
	//FINDER:Vehicle
	stock SAOI_FindVehicle(Float:streamdistance = 20.0){
		new buffer[256], szLIST[768], cnt = 0, Float:x, Float:y, Float:z, Float:angle, color1, color2, modelid,
			v_status[16], Float:tx, Float:ty, Float:tz;
		
		for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++){
			if(IsValidVehicle(i)){
				GetVehicleSpawnInfo(i,x,y,z,angle,color1,color2);
				GetVehiclePos(i,tx,ty,tz);
				szLIST = "";
				modelid = GetVehicleModel(i);
				if(IsVehicleOccupied(i)){
					v_status = "Occupied";
				} else if(IsVehicleDead(i)){
					v_status = "Dead";
				} else if(GetDistanceBetweenPoints3D(x,y,z,tx,ty,tz) <= 2.0){
					v_status = "On Spawn";
				} else {
					v_status = "Spawned";
				}
				format(buffer,sizeof buffer,"{89C1FA}Vehicle: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d)\n",i,modelid,GetVehicleVirtualWorld(i),GetVehicleInterior(i));
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Spawn: {00AAFF}(%.7f,%.7f,%.7f,%.7f) {89C1FA}Last Status: {00AAFF}%s\n",x,y,z,angle,v_status);
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Color: {00AAFF}(%d %d) {89C1FA}Model Count: {00AAFF}(%d)",color1,color2,GetVehicleModelCount(modelid));
				strcat(szLIST,buffer);
				FindVehicleLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
				cnt++;
			}
		}
		SAOI_Finder[e_vehicle][o_count] = cnt;
	}

	stock SAOI_RemoveFindVehicle(){
		for(new i = 0; i < MAX_FIND_VEHICLE; i++){
			if(IsValidDynamic3DTextLabel(FindVehicleLabel[i])) DestroyDynamic3DTextLabel(FindVehicleLabel[i]);
		}
	}
	
	//FINDER:Object
	stock SAOI_FindObject(playerid,Float:findradius,Float:streamdistance = 20.0){
		new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz,
			Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz;
		
		GetPlayerPos(playerid,px,py,pz);
		for(new i = 0; i <= MAX_OBJECTS; i++){
			if(cnt >= MAX_FIND_OBJECT) break;
			if(IsValidObject(i)){
				GetObjectPos(i,x,y,z);
				if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
					GetObjectRot(i,rx,ry,rz);
					szLIST = "";
					format(buffer,sizeof buffer,"{89C1FA}Object: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%.0f)\n",i,GetObjectModel(i),GetObjectDrawDistance(i));
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f,%.7f,%.7f)",x,y,z,rx,ry,rz);
					strcat(szLIST,buffer);
					FindObjectLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
					cnt++;
				}
			}
			SAOI_Finder[e_object][o_count] = cnt;
		}
	}
	
	stock SAOI_RemoveFindObject(){
		for(new i = 0; i < MAX_FIND_OBJECT; i++){
			if(IsValidDynamic3DTextLabel(FindObjectLabel[i])) DestroyDynamic3DTextLabel(FindObjectLabel[i]);
		}
	}
	
	//FINDER:Pickup
	stock SAOI_FindPickup(playerid,Float:findradius,Float:streamdistance = 20.0){
		new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz,
			Float:x, Float:y, Float:z;
		
		GetPlayerPos(playerid,px,py,pz);
		for(new i = 0; i <= MAX_PICKUPS; i++){
			if(cnt >= MAX_FIND_PICKUP) break;
			if(IsValidPickup(i)){
				GetPickupPos(i,x,y,z);
				if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
					szLIST = "";
					format(buffer,sizeof buffer,"{89C1FA}Pickup: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d)\n",i,GetPickupModel(i),GetPickupVirtualWorld(i));
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f) {89C1FA}Type: {00AAFF}(%d)",x,y,z,GetPickupType(i));
					strcat(szLIST,buffer);
					FindPickupLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
					cnt++;
				}
			}
			SAOI_Finder[e_pickup][o_count] = cnt;
		}
	}

	stock SAOI_RemoveFindPickup(){
		for(new i = 0; i < MAX_FIND_PICKUP; i++){
			if(IsValidDynamic3DTextLabel(FindPickupLabel[i])) DestroyDynamic3DTextLabel(FindPickupLabel[i]);
		}
	}
#endif

//FINDER:RemoveBuilding
stock SAOI_FindRemoveBuilding(Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, modelid, Float:x, Float:y, Float:z, Float:radius, SAOI:index, fname[MAX_PATH];
	for(new i = SAOIRemoveUpperbound; i >= 0; i--){
		if(SAOIRemoveBuildings[i][saoi_modelid] != 0){
			SAOI_GetRemoveBuilding(i,index,modelid,x,y,z,radius);
			szLIST = "";
			GetSAOILoadData(index,fname);
			format(buffer,sizeof buffer,"{89C1FA}SAOI Name: {00AAFF}%s.saoi\n",fname[6]);
			strcat(szLIST,buffer);
			format(buffer,sizeof buffer,"{89C1FA}Removed Building: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Radius: {00AAFF}(%f)\n",i,modelid,radius);
			strcat(szLIST,buffer);
			format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f)\n",x,y,z);
			strcat(szLIST,buffer);
			FindRemoveBuildingsLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
			cnt++;
		}
	}
	SAOI_Finder[e_removebuilding][o_count] = cnt;
}

stock SAOI_RemoveFindRemoveBuilding(){
	for(new i = 0; i < MAX_FIND_REMOVEBUILDING; i++){
		if(IsValidDynamic3DTextLabel(FindRemoveBuildingsLabel[i])) DestroyDynamic3DTextLabel(FindRemoveBuildingsLabel[i]);
	}
}

//FINDER:Actor
stock SAOI_FindActor(Float:streamdistance = 20.0){
	new buffer[256], szLIST[1000], cnt = 0,
		Float:x, Float:y, Float:z, Float:angle, Float:health;
	
	for(new i = 0, j = GetActorPoolSize(); i <= j; i++){
		if(cnt >= MAX_FIND_ACTOR) break;
		if(IsValidActor(i)){
			GetActorPos(i,x,y,z);
			GetActorFacingAngle(i,angle);
			GetActorHealth(i,health);
			szLIST = "";
			#if defined _YSF_included
				format(buffer,sizeof buffer,"{89C1FA}Actor: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d)\n",i,GetActorSkin(i),GetActorVirtualWorld(i));
			#else
				format(buffer,sizeof buffer,"{89C1FA}Actor: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d)\n",i,GetActorVirtualWorld(i));
			#endif
			strcat(szLIST,buffer);
			format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f)\n",x,y,z,angle);
			strcat(szLIST,buffer);
			format(buffer,sizeof buffer,"{89C1FA}Invulnerable: {00AAFF}%s {89C1FA}Health: {00AAFF}%.0f",IsActorInvulnerable(i)?("YES"):("NO"),health);
			strcat(szLIST,buffer);
			
			#if defined _YSF_included
				new animlib[64], animname[64], Float:fDelta, loop, lockx, locky, freeze, time;
				GetActorAnimation(i,animlib,sizeof(animlib),animname,sizeof(animname),fDelta,loop,lockx,locky,freeze,time);
				if(!isnull(animlib) && !isnull(animname)){
					strcat(szLIST,"\n");
					format(buffer,sizeof buffer,"{89C1FA}Anim Library: {00AAFF}%s {89C1FA}Anim Name: {00AAFF}%s\n",animlib,animname);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Delta: {00AAFF}(%.7f) {89C1FA}Loop: {00AAFF}(%d) {89C1FA}Lock: {00AAFF}(%d,%d)\n",fDelta,loop,lockx,locky);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Freeze: {00AAFF}(%d) {89C1FA}Time: {00AAFF}(%d)",freeze,time);
					strcat(szLIST,buffer);
				}
			#endif

			
			FindActorLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
			cnt++;
		}
		SAOI_Finder[e_actor][o_count] = cnt;
	}
}

stock SAOI_RemoveFindActor(){
	for(new i = 0; i < MAX_FIND_ACTOR; i++){
		if(IsValidDynamic3DTextLabel(FindActorLabel[i])) DestroyDynamic3DTextLabel(FindActorLabel[i]);
	}
}

//FINDER:DynamicCP
stock SAOI_FindDynamicCP(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz,
		Float:x, Float:y, Float:z, Float:sd, Float:size;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicCPs(i){
		if(cnt >= MAX_FIND_DYNAMIC_CP) break;
		if(IsValidDynamicCP(i)){
			GetDynamicCPPos(i,x,y,z);
			if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
				GetDynamicCPSD(i,sd);
				GetDynamicCPSize(i,size);
				szLIST = "";
				format(buffer,sizeof buffer,"{89C1FA}DynamicCP: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %d %d)\n",i,GetDynamicCPVW(i),GetDynamicCPINT(i),sd,GetDynamicCPArea(i),GetDynamicCPPriority(i));
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f) {89C1FA}Size: {00AAFF}(%.2f)",x,y,z,size);
				strcat(szLIST,buffer);
				FindDynamicCPLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
				cnt++;
			}
		}
		SAOI_Finder[e_dynamic_cp][o_count] = cnt;
	}
}

stock SAOI_RemoveFindDynamicCP(){
	for(new i = 0; i < MAX_FIND_DYNAMIC_CP; i++){
		if(IsValidDynamic3DTextLabel(FindDynamicCPLabel[i])) DestroyDynamic3DTextLabel(FindDynamicCPLabel[i]);
	}
}

//FINDER:DynamicRaceCP
stock SAOI_FindDynamicRaceCP(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz,
		Float:x, Float:y, Float:z, Float:nextx, Float:nexty, Float:nextz, Float:sd, Float:size;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicRaceCPs(i){
		if(cnt >= MAX_FIND_DYNAMIC_RACECP) break;
		if(IsValidDynamicRaceCP(i)){
			GetDynamicRaceCPPos(i,x,y,z);
			if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
				GetDynamicRaceCPSD(i,sd);
				GetDynamicRaceCPNext(i,nextx,nexty,nextz);
				GetDynamicRaceCPSize(i,size);
				szLIST = "";
				format(buffer,sizeof buffer,"{89C1FA}DynamicRaceCP: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %d %d)\n",i,GetDynamicRaceCPVW(i),GetDynamicRaceCPINT(i),sd,GetDynamicRaceCPArea(i),GetDynamicRaceCPPriority(i));
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f) {89C1FA}Next: {00AAFF}(%.7f,%.7f,%.7f)\n",x,y,z,nextx,nexty,nextz);
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Type: {00AAFF}(%d) {89C1FA}Size: {00AAFF}(%.2f)",GetDynamicRaceCPType(i),size);
				strcat(szLIST,buffer);
				FindDynamicRaceCPLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
				cnt++;
			}
		}
		SAOI_Finder[e_dynamic_racecp][o_count] = cnt;
	}
}

stock SAOI_RemoveFindDynamicRaceCP(){
	for(new i = 0; i < MAX_FIND_DYNAMIC_RACECP; i++){
		if(IsValidDynamic3DTextLabel(FindDynamicRaceCPLabel[i])) DestroyDynamic3DTextLabel(FindDynamicRaceCPLabel[i]);
	}
}

//Main
stock fcreate(const name[]){
	if(!fexist(name)){
		new File:cfile = fopen(name,io_readwrite);
		fwrite(cfile,"");
		fclose(cfile);
		return 1;
	}
	return 0;
}

//Commands
CMD:saoi(playerid){
	if(!IsAdmin(playerid)) return 0;
	
	new szLIST[3096], buffer[256], fname[MAX_PATH],
		object_cnt, material_cnt, material_text_cnt, load_time, removed_cnt,
		t_object_cnt = 0, t_material_cnt = 0, t_material_text_cnt = 0, t_load_time = 0, t_removed_cnt = 0;
	
	SAOI_Foreach(i){
		if(!SAOI_IsSlotFree(i)){
			GetSAOILoadData(i,fname,object_cnt,material_cnt,material_text_cnt,load_time,_,removed_cnt);
			t_object_cnt += object_cnt;
			t_material_cnt += material_cnt;
			t_material_text_cnt += material_text_cnt;
			t_load_time += load_time;
			t_removed_cnt += removed_cnt;
		}
	}
	
	szLIST = "";
	
	format(buffer,sizeof buffer,"{00AAFF}SAOI File loaded: {00FF00}%d / %d {00AAFF}Next free ID: {00FF00}%d\n",CountSAOIFileLoaded(),SAOIToInt(MAX_SAOI_FILE)-1,SAOIToInt(SAOI_GetFreeID()));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Objects: {00FF00}%d {00AAFF}Materials: {00FF00}%d {00AAFF}Material Text: {00FF00}%d {00AAFF}Removed Buildings: {00FF00}%d\n",t_object_cnt,t_material_cnt,t_material_text_cnt,t_removed_cnt);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Memory Loaded: {00FF00}%d KB {00AAFF}Load Time: {00FF00}%d {00AAFF}ms\n",floatround(SAOI_GetMemoryLoaded()/1024),t_load_time);
	strcat(szLIST,buffer);

	ShowPlayerDialog(playerid,DIALOG_SAOI_NUL,DIALOG_STYLE_MSGBOX,"{00FFFF}SAOI Statistics", szLIST, "{00FF00}Exit", "");
	return 1;
}

CMD:objstatus(playerid){
	if(!IsAdmin(playerid)) return 0;
	new pVW, pINT, cnt = 0, vis, buffer[200], oVW, oINT, tmp = 0;
	pVW = GetPlayerVirtualWorld(playerid);
	pINT = GetPlayerInterior(playerid);
	vis = Streamer_CountVisibleItems(playerid,STREAMER_TYPE_OBJECT);
	ForDynamicObjects(i){
		if(IsValidDynamicObject(i)){
			tmp = 0;
			oVW = GetDynamicObjectVW(i);
			oINT = GetDynamicObjectINT(i);
			if((oVW == -1 || oVW == pVW) && (oINT == -1 || oINT == pINT)) tmp = 1;
			if((oVW == -1 && pINT == oINT) || (oINT == -1 && pVW == pVW)) tmp = 1;
			if(tmp == 1) cnt++;
		}
	}
	format(buffer,sizeof buffer,"[Objects] Visible: %d, World VW %d INT %d: %d, All: %d, UpperBound: %d, Static: %d",vis,pVW,pINT,cnt,CountDynamicObjects(),GetDynamicObjectPoolSize()+1,CountObjects());
	SendClientMessage(playerid,0xFFFFFFFF,buffer);
	return 1;
}

CMD:delobject(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /delobject <objectid>");
	new objectid = strval(params);
	if(!IsValidDynamicObject(objectid)) return SendClientMessage(playerid,0xB01010FF,"This object not exists");
	DestroyDynamicObject(objectid);
	return 1;
}

CMD:delpickup(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /delpickup <pickupid>");
	new pickupid = strval(params);
	if(!IsValidDynamicPickup(pickupid)) return SendClientMessage(playerid,0xB01010FF,"This pickup not exists");
	DestroyDynamicPickup(pickupid);
	return 1;
}

CMD:delmapicon(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /mapicon <iconid>");
	new iconid = strval(params);
	if(!IsValidDynamicMapIcon(iconid)) return SendClientMessage(playerid,0xB01010FF,"This mapicon not exists");
	DestroyDynamicMapIcon(iconid);
	return 1;
}

CMD:tptoobj(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /tptoobj <objectid>");
	new objectid = strval(params);
	if(!IsValidDynamicObject(objectid)) return SendClientMessage(playerid,0xB01010FF,"This object not exists");
	new F4[Float3D];
	GetDynamicObjectPos(objectid,F4[T3D:X],F4[T3D:Y],F4[T3D:Z]);
	F4[T3D:VW] = GetDynamicObjectVW(objectid);
	F4[T3D:INT] = GetDynamicObjectINT(objectid);
	SetPlayerPos(playerid,F4[T3D:X],F4[T3D:Y],F4[T3D:Z]);
	SetPlayerInterior(playerid,F4[T3D:INT]);
	SetPlayerVirtualWorld(playerid,F4[T3D:VW]);
	return 1;
}

CMD:objmaterial(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /objmaterial <objectid>");
	new objectid = strval(params);
	if(!IsValidDynamicObject(objectid)) return SendClientMessage(playerid,0xB01010FF,"This object not exists");
	new szLIST[3096], buffer[256], cnt = 0;
	szLIST = "";
	format(szLIST,sizeof(szLIST),"{00AAFF}Object: {00FF00}%d\n\n",objectid);
	for(new i = 0; i < 16; i++){
		if(IsDynamicObjectMaterialUsed(objectid,i)){
			new mid, txdname[MAX_TXD_NAME], texturename[MAX_TEXTURE_NAME], materialcolor;
			GetDynamicObjectMaterial(objectid,i,mid,txdname,texturename,materialcolor);
			format(buffer,sizeof(buffer),"{00FF00}%d. {00AAFF}Model: {00FF00}%d {00AAFF}TXD: {00FF00}%s {00AAFF}Texture: {00FF00}%s {00AAFF}Color: {00FF00}0x%08x\n",i,mid,txdname,texturename,materialcolor);
			strcat(szLIST,buffer);
			cnt++;
		}
	}
	if(cnt == 0) strcat(szLIST,"This object not use materials.");
	ShowPlayerDialog(playerid,DIALOG_SAOI_NUL,DIALOG_STYLE_MSGBOX,"{00FFFF}SAOI Object Material", szLIST, "{00FF00}Exit", "");
	return 1;
}

CMD:objmaterialtext(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /objmaterialtext <objectid>");
	new objectid = strval(params);
	if(!IsValidDynamicObject(objectid)) return SendClientMessage(playerid,0xB01010FF,"This object not exists");
	new szLIST[4096], buffer[1024], cnt = 0;
	szLIST = "";
	format(szLIST,sizeof(szLIST),"{00AAFF}Object: {00FF00}%d\n\n",objectid);
	for(new i = 0; i < 16; i++){
		if(IsDynamicObjectMaterialTextUsed(objectid,i)){
			new text[MAX_TEXT_NAME], materialsize, fontface[MAX_FONT_NAME], fontsize, bold, fontcolor, backcolor, textalignment;
			GetDynamicObjectMaterialText(objectid,i,text,materialsize,fontface,fontsize,bold,fontcolor,backcolor,textalignment);
			format(buffer,sizeof(buffer),"{00FF00}%d. {00AAFF}Text: {00FF00}'%s'\n",i,text);
			strcat(szLIST,buffer);
			format(buffer,sizeof(buffer),"{00AAFF}Material size: {00FF00}%d {00AAFF}Font Style: {00FF00}%s {00AAFF}Font Size: {00FF00}%d {00AAFF}Bold: {00FF00}%d\n",materialsize,fontface,fontsize,bold);
			strcat(szLIST,buffer);
			format(buffer,sizeof(buffer),"{00AAFF}Font Color: {00FF00}0x%08x {00AAFF}Back Color: {00FF00}0x%08x {00AAFF}Align: {00FF00}%d\n\n",fontcolor,backcolor,textalignment);
			strcat(szLIST,buffer);
			cnt++;
		}
	}
	if(cnt == 0) strcat(szLIST,"This object not use material text.");
	ShowPlayerDialog(playerid,DIALOG_SAOI_NUL,DIALOG_STYLE_MSGBOX,"{00FFFF}SAOI Object Material Text", szLIST, "{00FF00}Exit", "");
	return 1;
}

CMD:saoiinfo(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoiinfo <name> (Only file name, without extension)");
	new buffer[512], path[MAX_PATH], SAOI:index, Float:x, Float:y, Float:z, Float:angle, vw, int;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	if(!IsSAOIFileLoaded(path,index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is not loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
	PlayerLastSAOI[playerid] = index;
	
	new szLIST[1024], author[MAX_SAOI_AUTHOR_SIZE], version[MAX_SAOI_VERSION_SIZE], description[MAX_SAOI_DESCRIPTION_SIZE],
		fname[MAX_SAOI_NAME_SIZE], object_cnt, material_cnt, material_text_cnt, load_time, active_tick, created_data[32], removed_cnt;
	
	szLIST = "";
	GetSAOIFileHeader(path,author,version,description);
	if(isnull(description)) description = "---";
	GetSAOILoadData(index,fname,object_cnt,material_cnt,material_text_cnt,load_time,active_tick,removed_cnt);
	GetSAOIPositionFlag(index,x,y,z,angle,vw,int);
	
	format(buffer,sizeof buffer,"{00AAFF}Index: {00FF00}%d {00AAFF}SAOI Name: {00FF00}%s {00AAFF}Path: {00FF00}%s\n",SAOIToInt(index),params,path);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Author: {00FF00}%s {00AAFF}Version: {00FF00}%s\n",author,version);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Description: {00FF00}%s\n",description);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Objects: {00FF00}%d {00AAFF}Materials: {00FF00}%d {00AAFF}Material Text: {00FF00}%d {00AAFF}Removed Buildings: {00FF00}%d\n",object_cnt,material_cnt,material_text_cnt,removed_cnt);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Active time: {00FF00}%d:%02d:%02d:%02d {00AAFF}Load time: {00FF00}%d {00AAFF}ms\n",SAOI_MSToTimeDay(GetTickCount()-active_tick),load_time);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Quota: {00FF00}%.2f %% {00AAFF}File Size: {00FF00}%d {00AAFF}B\n",((object_cnt*100.0)/CountDynamicObjects()),GetSAOIFileSize(index));
	strcat(szLIST,buffer);
	
	if(x == 0.0 && y == 0.0 && z == 0.0 && angle == 0.0 && vw == 0 && int == 0){
		format(buffer,sizeof buffer,"{00AAFF}Position: {00FF00}Not found saved position.\n");
	} else {
		format(buffer,sizeof buffer,"{00AAFF}Position: {00FF00}%.4f %.4f %.4f {00AAFF}Angle: {00FF00}%.1f {00AAFF}World: {00FF00}%d {00AAFF}Interior: {00FF00}%d\n",x,y,z,angle,vw,int);
	}
	strcat(szLIST,buffer);
	
	GetSAOIFileCreationData(index,created_data);
	if(isnull(created_data)){
		format(buffer,sizeof buffer,"{00AAFF}Created: {00FF00}Not found created data.\n");
	} else {
		format(buffer,sizeof buffer,"{00AAFF}Created: {00FF00}%s\n",created_data);
	}
	strcat(szLIST,buffer);
	
	ShowPlayerDialog(playerid,DIALOG_SAOI_INFO,DIALOG_STYLE_MSGBOX,"{00FFFF}SAOI File Information",szLIST,"{00FF00}Exit","{FF0000}Return");
	return 1;
}

CMD:streaminfo(playerid){
	if(!IsAdmin(playerid)) return 0;
	new buffer[256], szLIST[3096];
	
	
	//Server Elements
	strcat(szLIST,"{00FFFF}Server Elements:\n");
	format(buffer,sizeof buffer,"{00AAFF}Players: {00FF00}%d / %d\n",CountPlayers(true,false),GetMaxPlayers()-CountPlayers(false,true));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}NPC: {00FF00}%d / %d\n",CountPlayers(false,true),GetServerVarAsInt("maxnpc"));
	strcat(szLIST,buffer);
	
	
	//Static Elements
	strcat(szLIST,"\n{00FFFF}Static Elements:\n");
	format(buffer,sizeof buffer,"{00AAFF}Objects: {00FF00}%d / %d\n",CountObjects(),MAX_OBJECTS);
	strcat(szLIST,buffer);
	
	#if defined _YSF_included
		new cnt = 0;
		for(new i = 0, j = MAX_PICKUPS; i < j; i++){
			if(IsValidPickup(i)) cnt++;
		}
		format(buffer,sizeof buffer,"{00AAFF}Pickups: {00FF00}%d / %d\n",cnt,MAX_PICKUPS);
		strcat(szLIST,buffer);
	#endif
	
	format(buffer,sizeof buffer,"{00AAFF}Actors: {00FF00}%d / %d\n",CountActors(),MAX_ACTORS);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Vehicles: {00FF00}%d / %d\n",CountVehicles(),MAX_VEHICLES);
	strcat(szLIST,buffer);
	#if defined _YSF_included
		format(buffer,sizeof buffer,"{00AAFF}Vehicle Models: {00FF00}%d / %d\n",GetVehicleModelsUsed(),212);
		strcat(szLIST,buffer);
	#endif
	
	
	//Dynamic Elements
	strcat(szLIST,"\n{00FFFF}Dynamic Elements:\n");
	format(buffer,sizeof buffer,"{00AAFF}DynamicObjects: {00FF00}%d {00AAFF}Visible: {00FF00}%d / %d\n",
		CountDynamicObjects(),Streamer_CountVisibleItems(playerid,STREAMER_TYPE_OBJECT),Streamer_GetVisibleItems(STREAMER_TYPE_OBJECT,playerid)
	);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}DynamicPickup: {00FF00}%d {00AAFF}Visible: {00FF00}%d / %d\n",
		CountDynamicPickups(),Streamer_CountVisibleItems(playerid,STREAMER_TYPE_PICKUP),Streamer_GetVisibleItems(STREAMER_TYPE_PICKUP,playerid)
	);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}DynamicCP: {00FF00}%d {00AAFF}Visible: {00FF00}%d / -\n",
		CountDynamicCPs(),Streamer_CountVisibleItems(playerid,STREAMER_TYPE_CP)
	);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}DynamicRaceCP: {00FF00}%d {00AAFF}Visible: {00FF00}%d / -\n",
		CountDynamicRaceCPs(),Streamer_CountVisibleItems(playerid,STREAMER_TYPE_RACE_CP)
	);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}DynamicMapIcon: {00FF00}%d {00AAFF}Visible: {00FF00}%d / %d\n",
		CountDynamicMapIcons(),Streamer_CountVisibleItems(playerid,STREAMER_TYPE_MAP_ICON),Streamer_GetVisibleItems(STREAMER_TYPE_MAP_ICON,playerid)
	);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Dynamic3DText: {00FF00}%d {00AAFF}Visible: {00FF00}%d / %d\n",
		CountDynamic3DTextLabels(),Streamer_CountVisibleItems(playerid,STREAMER_TYPE_3D_TEXT_LABEL),Streamer_GetVisibleItems(STREAMER_TYPE_3D_TEXT_LABEL,playerid)
	);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}DynamicArea: {00FF00}%d {00AAFF}Visible: {00FF00}%d / -\n",
		CountDynamicAreas(),GetPlayerNumberDynamicAreas(playerid)
	);
	strcat(szLIST,buffer);
	
	
	//SAOI Elements
	strcat(szLIST,"\n{00FFFF}SAOI Elements:\n");
	format(buffer,sizeof buffer,"{00AAFF}Removed Buildings: {00FF00}%d / %d\n",SAOI_CountRemovedBuildings(),MAX_OBJECTS);
	strcat(szLIST,buffer);
	
	ShowPlayerDialog(playerid,DIALOG_SAOI_NUL,DIALOG_STYLE_MSGBOX,"{00FFFF}SAOI Stream info",szLIST,"{FF0000}Exit","");
	return 1;
}

CMD:saoiload(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoiload <name> (Only file name, without extension)");
	new buffer[256], path[MAX_PATH];
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	if(IsSAOIFileLoaded(path)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is already loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	if(!fexist(path)) return SendClientMessage(playerid,0xB01010FF,"File not exist");
	
	format(buffer,sizeof buffer,"[IMPORTANT] Load Objects: %s",params);
	SendClientMessageToAll(0xFF0000FF,buffer);
	
	new SAOI:edi = LoadObjectImage(path);
	if(SAOIToInt(edi) > 0){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}loaded",params);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	} else {
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}not loaded",path);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
		printf("Cannot load file: %s",path);
		PrintSAOIErrorName(edi);
	}
	return 1;
}

CMD:saoiunload(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoiunload <name> (Only file name, without extension)");
	new buffer[256], path[MAX_PATH], SAOI:index;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	if(!IsSAOIFileLoaded(path,index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is not loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
	format(buffer,sizeof buffer,"[IMPORTANT] Unload Objects: %s",params);
	SendClientMessageToAll(0xFF0000FF,buffer);
	
	if(UnloadObjectImage(index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}unloaded",params);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	} else {
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}not unloaded",params);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
	return 1;
}

CMD:saoireload(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoireload <name> (Only file name, without extension)");
	
	new buffer[256], path[MAX_PATH], SAOI:index;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	
	if(!fexist(path)) return SendClientMessage(playerid,0xB01010FF,"File not exist");
	
	format(buffer,sizeof buffer,"[IMPORTANT] Reload Objects: %s",params);
	SendClientMessageToAll(0xFF0000FF,buffer);
	
	if(IsSAOIFileLoaded(path,index)){
		UnloadObjectImage(index);
	}
	new SAOI:edi = LoadObjectImage(path);
	if(SAOIToInt(edi) > 0){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}reloaded",params);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	} else {
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}not loaded",path);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
		printf("Cannot load file: %s",path);
		PrintSAOIErrorName(edi);
	}
	
	return 1;
}

CMD:saoifinder(playerid){
	if(!IsAdmin(playerid)) return 0;
	new buffer[256], szLIST[400];
	for(new i = 0, j = sizeof(elements_name); i < j; i++){
		if(SAOI_Finder[find_elements:i][o_active]){
			format(buffer,sizeof buffer,"{00FF00}[YES]\t{00AAFF}%s {00FFFF}(%d / %d)\n",elements_name[i],SAOI_Finder[find_elements:i][o_count],SAOI_Finder[find_elements:i][o_max]);
		} else {
			format(buffer,sizeof buffer,"{FF0000}[NO]\t{00AAFF}%s\n",elements_name[i]);
		}
		strcat(szLIST,buffer);
	}
	ShowPlayerDialog(playerid,DIALOG_SAOI_FINDER,DIALOG_STYLE_LIST,"{00FFFF}SAOI Element Finder",szLIST,"{00FF00}Select","{FF0000}Exit");
	return 1;
}

CMD:saoilist(playerid){
	if(!IsAdmin(playerid)) return 0;
	new buffer[256], szLIST[4096], fname[MAX_PATH];
	
	SAOI_Foreach(i){
		if(!SAOI_IsSlotFree(i)){
			GetSAOILoadData(i,fname);
			format(buffer,sizeof buffer,"{FFFFFF}%d. {00FF00}%s\n",SAOIToInt(i),fname[6]);
			if(strlen(szLIST)+strlen(buffer) > sizeof(szLIST)) break;
			strcat(szLIST,buffer);
		}
	}
	if(isnull(szLIST)){
		szLIST = "Lack loaded files";
	}
	ShowPlayerDialog(playerid,DIALOG_SAOI_LIST,DIALOG_STYLE_LIST,"{00FFFF}SAOI File List",szLIST,"{00FF00}Select","{FF0000}Exit");
	return 1;
}

CMD:saoitp(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoitp <name> (Only file name, without extension)");
	
	new buffer[256], path[MAX_PATH], SAOI:index;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	
	if(!IsSAOIFileLoaded(path,index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is not loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
	new Float:x, Float:y, Float:z, Float:angle, vw, int;
	GetSAOIPositionFlag(index,x,y,z,angle,vw,int);
	
	if(x == 0.0 && y == 0.0 && z == 0.0 && angle == 0.0 && vw == 0 && int == 0) return SendClientMessage(playerid,0xB01010FF,"Not found saved position!");
	Streamer_UpdateEx(playerid,x,y,z,vw,int,-1,500);
	SetPlayerPos(playerid,x,y,z);
	SetPlayerFacingAngle(playerid,angle);
	SetPlayerVirtualWorld(playerid,vw);
	SetPlayerInterior(playerid,int);
	SetCameraBehindPlayer(playerid);
	return 1;
}

CMD:saoicmd(playerid){
	if(!IsAdmin(playerid)) return 0;
	new szLIST[2048];
	strcat(szLIST,"{00FF00}/saoi - {00AAFF}shows statistics saoi\n");
	strcat(szLIST,"{00FF00}/saoifinder - {00AAFF}element finder\n");
	strcat(szLIST,"{00FF00}/objstatus - {00AAFF}show total object status\n");
	strcat(szLIST,"{00FF00}/saoiinfo - {00AAFF}show saoi file information\n");
	strcat(szLIST,"{00FF00}/saoiload - {00AAFF}load saoi file\n");
	strcat(szLIST,"{00FF00}/saoiunload - {00AAFF}unload saoi file\n");
	strcat(szLIST,"{00FF00}/saoireload - {00AAFF}reload saoi file\n");
	strcat(szLIST,"{00FF00}/saoilist - {00AAFF}show loaded saoi files\n");
	strcat(szLIST,"{00FF00}/saoitp - {00AAFF}teleport to saoi flag\n");
	strcat(szLIST,"{00FF00}/streaminfo - {00AAFF}show stream info\n");
	strcat(szLIST,"{00FF00}/tptoobj - {00AAFF}teleport to object\n");
	strcat(szLIST,"{00FF00}/delobject - {00AAFF}destroy dynamic object\n");
	strcat(szLIST,"{00FF00}/delpickup - {00AAFF}destroy dynamic pickup\n");
	strcat(szLIST,"{00FF00}/delmapicon - {00AAFF}destroy dynamic mapicon\n");
	strcat(szLIST,"{00FF00}/objmaterial - {00AAFF}get object materials\n");
	strcat(szLIST,"{00FF00}/objmaterialtext - {00AAFF}get object material text\n");
	ShowPlayerDialog(playerid,DIALOG_SAOI_NUL,DIALOG_STYLE_MSGBOX,"{00FFFF}SAOI Commands",szLIST,"{00FF00}Exit","");
	return 1;
}

//Dialogs
public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]){
	switch(dialogid){
		case DIALOG_SAOI_LIST: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return 0;
			PlayerLastSAOI[playerid] = SAOI:(listitem+1);
			ShowPlayerDialog(playerid,DIALOG_SAOI_ITEM,DIALOG_STYLE_LIST,"{00FFFF}SAOI File Option","File Information\nReload File\nUnload File\nTeleport To Flag","{00FF00}Select","{FF0000}Return");
		}
		case DIALOG_SAOI_ITEM: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return cmd_saoilist(playerid);
			new fname[MAX_PATH],nname[MAX_SAOI_NAME_SIZE];
			GetSAOILoadData(PlayerLastSAOI[playerid],fname);
			sscanf(fname,"'/SAOI/'s[64]",nname);
			switch(listitem){
				case 0: return cmd_saoiinfo(playerid,nname);
				case 1: return cmd_saoireload(playerid,nname);
				case 2: return cmd_saoiunload(playerid,nname);
				case 3: return cmd_saoitp(playerid,nname);
			}
		}
		case DIALOG_SAOI_INFO: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return ShowPlayerDialog(playerid,DIALOG_SAOI_ITEM,DIALOG_STYLE_LIST,"{00FFFF}SAOI File Option","File Information\nReload File\nUnload File\nTeleport To Flag","{00FF00}Select","{FF0000}Return");
		}
		case DIALOG_SAOI_FINDER: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return 0;
			PlayerLastItem[playerid] = listitem;
			if(SAOI_Finder[find_elements:listitem][o_active]){
				ShowPlayerDialog(playerid,DIALOG_SAOI_FINDER_DISABLE,DIALOG_STYLE_MSGBOX,"{00FFFF}SAOI Finder Option","You are sure for disable this option.","{00FF00}YES","{FF0000}NO");
			} else {
				ShowPlayerDialog(playerid,DIALOG_SAOI_FINDER_PARAMS,DIALOG_STYLE_INPUT,"{00FFFF}SAOI Finder Option","Choose stream distance and find distance. (separate space)","{00FF00}Find","{FF0000}Return");
			}
		}
		case DIALOG_SAOI_FINDER_DISABLE: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return cmd_saoifinder(playerid);
			new elementid = PlayerLastItem[playerid];
			if(SAOI_Finder[find_elements:elementid][o_active]){
				switch(find_elements:elementid){
					case e_dynamic_object: {
						SAOI_RemoveFindDynamicObject();
					}
					case e_dynamic_pickup: {
						SAOI_RemoveFindDynamicPickup();
					}
					case e_dynamic_cp: {
						SAOI_RemoveFindDynamicCP();
					}
					case e_dynamic_racecp: {
						SAOI_RemoveFindDynamicRaceCP();
					}
					case e_dynamic_mapicon: {
						SAOI_RemoveFindDynamicMapIcon();
					}
					case e_actor: {
						SAOI_RemoveFindActor();
					}
					#if defined _YSF_included
						case e_object: {
							SAOI_RemoveFindObject();
						}
						case e_pickup: {
							SAOI_RemoveFindPickup();
						}
						case e_vehicle: {
							SAOI_RemoveFindVehicle();
						}
					#endif
					case e_removebuilding: {
						SAOI_RemoveFindRemoveBuilding();
					}
					default: {
						return SendClientMessage(playerid,0xB01010FF,"This component need YSF Plugin.");
					}
				}
				
				new buffer[256];
				format(buffer,sizeof(buffer),"Removed all signatures of %s",elements_name[elementid]);
				SendClientMessage(playerid,0xFFFFFFFF,buffer);
				SAOI_Finder[find_elements:elementid][o_active] = false;
				return cmd_saoifinder(playerid);
			}
		}
		case DIALOG_SAOI_FINDER_PARAMS: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return cmd_saoifinder(playerid);
			new elementid = PlayerLastItem[playerid], Float:sd, Float:findr;
			if(sscanf(inputtext,"ff",sd,findr)) return SendClientMessage(playerid,0xB01010FF,"You must enter values <streamdistance (1-300)> <find radius>");
			if(sd < 1.0 || sd > 300.0) return SendClientMessage(playerid,0xB01010FF,"Stream distance must be within range 1-300");
			if(findr < 1.0) findr = 20.0;
			
			if(!SAOI_Finder[find_elements:elementid][o_active]){
				switch(find_elements:elementid){
					case e_dynamic_object: {
						SAOI_FindDynamicObject(playerid,findr,sd);
					}
					case e_dynamic_pickup: {
						SAOI_FindDynamicPickup(playerid,findr,sd);
					}
					case e_dynamic_cp: {
						SAOI_FindDynamicCP(playerid,findr,sd);
					}
					case e_dynamic_racecp: {
						SAOI_FindDynamicRaceCP(playerid,findr,sd);
					}
					case e_dynamic_mapicon: {
						SAOI_FindDynamicMapIcon(playerid,findr,sd);
					}
					case e_actor: {
						SAOI_FindActor(sd);
					}
					#if defined _YSF_included
						case e_object: {
							SAOI_FindObject(playerid,findr,sd);
						}
						case e_pickup: {
							SAOI_FindPickup(playerid,findr,sd);
						}
						case e_vehicle: {
							SAOI_FindVehicle(sd);
						}
					#endif
					case e_removebuilding: {
						SAOI_FindRemoveBuilding(sd);
					}
					default: {
						return SendClientMessage(playerid,0xB01010FF,"This component need YSF Plugin.");
					}
				}
				new buffer[256];
				format(buffer,sizeof(buffer),"%s description has been activated, coverage %.0fm",elements_name[elementid],sd);
				SendClientMessage(playerid,0xFFFFFFFF,buffer);
				SAOI_Finder[find_elements:elementid][o_active] = true;
				return cmd_saoifinder(playerid);
			}
		}
	}
	return 0;
}

public OnFilterScriptInit(){
	printf(" ");
	
	SAOI_Finder[e_dynamic_object][o_max] =	MAX_FIND_DYNAMIC_OBJECT;
	SAOI_Finder[e_dynamic_pickup][o_max] =	MAX_FIND_DYNAMIC_PICKUP;
	SAOI_Finder[e_dynamic_cp][o_max] =		MAX_FIND_DYNAMIC_CP;
	SAOI_Finder[e_dynamic_racecp][o_max] =	MAX_FIND_DYNAMIC_RACECP;
	SAOI_Finder[e_dynamic_mapicon][o_max] =	MAX_FIND_DYNAMIC_MAPICON;
	SAOI_Finder[e_object][o_max] =			MAX_FIND_OBJECT;
	SAOI_Finder[e_pickup][o_max] =			MAX_FIND_PICKUP;
	SAOI_Finder[e_actor][o_max] =			MAX_FIND_ACTOR;
	SAOI_Finder[e_vehicle][o_max] =			MAX_FIND_VEHICLE;
	SAOI_Finder[e_removebuilding][o_max] =	MAX_FIND_REMOVEBUILDING;

	new start_time = GetTickCount();
	if(!fexist(SAOI_FILE_LIST)){
		printf("Create file: %s",SAOI_FILE_LIST);
		fcreate(SAOI_FILE_LIST);
		if(!fexist(SAOI_FILE_LIST)){
			printf("Cannot create file: %s",SAOI_FILE_LIST);
			return 0;
		}
	}
	new File:obj_list = fopen(SAOI_FILE_LIST,io_read), line[128], lcnt_t = 0, lcnt_f = 0;
	
	if(!obj_list){
		printf("Cannot open file: %s",SAOI_FILE_LIST);
		return 0;
	}
	
	while(fread(obj_list,line)){
		new fname[MAX_SAOI_NAME_SIZE], path[MAX_PATH], SAOI:edi;
		sscanf(line,"s[64]",fname);
		format(path,sizeof(path),"/SAOI/%s",fname);
		if(path[strlen(path)-1] == '\n') path[strlen(path)-1] = EOS;
		if(path[strlen(path)-1] == '\r') path[strlen(path)-1] = EOS;
		edi = LoadObjectImage(path);
		if(SAOIToInt(edi) > 0){
			lcnt_t++;
		} else {
			printf("Cannot load file: %s",path);
			PrintSAOIErrorName(edi);
			lcnt_f++;
		}
	}
	new stop_time = GetTickCount();
	if((lcnt_t+lcnt_f) > 0){
		printf("Total loaded files %d/%d in %d ms",lcnt_t,(lcnt_t+lcnt_f),stop_time-start_time);
		if(lcnt_f > 0){
			printf("Failed to load %d files",lcnt_f);
		}
	}
	return 1;
}

#pragma dynamic (64*1024)

//EOF