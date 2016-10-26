/****************************************************************************************************
 *                                                                                                  *
 *                                        SAOI File Manager                                         *
 *                                                                                                  *
 * Copyright � 2016 Abyss Morgan & Crayder. All rights reserved.                                    *
 *                                                                                                  *
 * Download: https://github.com/AbyssMorgan/SAOI/blob/master/filterscript                           *
 *                                                                                                  *
 * Plugins: Streamer, SScanf                                                                        *
 * Modules: SAOI, 3DTryg, StreamerFunction, IZCMD/ZCMD                                              *
 *                                                                                                  *
 * File Version: 1.1.0                                                                              *
 * SA:MP Version: 0.3.7                                                                             *
 * Streamer Version: 2.8.2                                                                          *
 * SScanf Version: 2.8.2                                                                            *
 * SAOI Version: 1.4.2                                                                              *
 * 3DTryg Version: 3.0.2                                                                            *
 * StreamerFunction Version: 2.5.4                                                                  *
 *                                                                                                  *
 * Notice:                                                                                          *
 * Required directory /scriptfiles/SAOI                                                             *
 *                                                                                                  *
 * Commands:                                                                                        *
 * /saoicmd - show saoi cmd                                                                         *
 * /addobjinfo - adds descriptions of objects                                                       *
 * /delobjinfo - removes descriptions of objects                                                    *
 * /objstatus - show total object status                                                            *
 * /saoicapacity - shows the status of use of slots                                                 *
 * /saoiinfo - show saoi file information                                                           *
 * /saoiload - load saoi file                                                                       *
 * /saoiunload - unload saoi file                                                                   *
 * /saoireload - reload saoi file                                                                   *
 * /saoilist - show loaded saoi files                                                               *
 * /streaminfo - show stream info                                                                   *
 * /saoitp - teleport to saoi flag                                                                  *
 *                                                                                                  *
 ****************************************************************************************************/
 
#define FILTERSCRIPT

#include <a_samp>

#if !defined _actor_included
	#include <a_actor>
#endif

#include <sscanf2>
#include <streamer>
#tryinclude <izcmd>
#if !defined CMD
	#include <zcmd>
#endif
#include <SAM/StreamerFunction>
#include <SAM/3DTryg>
#include <SAOI>

#define SAOI_FILE_LIST				"/SAOI/SaoiFiles.txt"
#define MAX_FIND_OBJ				(2048)
#define MAX_PATH					(70)

#define DIALOG_SAOI_INFO			(1000)
#define DIALOG_SAOI_LIST			(1001)
#define DIALOG_SAOI_ITEM			(1002)
#define DIALOG_SAOI_NUL				(1003)

//Check Version StreamerFunction.inc
#if !defined _streamer_spec
	#error [ADM] You need StreamerFunction.inc v2.5.4
#elseif !defined Streamer_Spec_Version
	#error [ADM] Update you StreamerFunction.inc to v2.5.4
#elseif (Streamer_Spec_Version < 20504)
	#error [ADM] Update you StreamerFunction.inc to v2.5.4
#endif

//Check Version 3DTryg.inc
#if !defined _3D_Tryg
	#error [ADM] You need 3DTryg.inc v3.0.2
#elseif !defined Tryg3D_Version
	#error [ADM] Update you 3DTryg.inc to v3.0.2
#elseif (Tryg3D_Version < 30002)
	#error [ADM] Update you 3DTryg.inc to v3.0.2
#endif

//Check Version SAOI.inc
#if !defined _SAOI_LOADER
	#error You need SAOI.inc v1.4.3
#elseif !defined SAOI_LOADER_VERSION
	#error Update you SAOI.inc to v1.4.3
#elseif (SAOI_LOADER_VERSION < 10403)
	#error Update you SAOI.inc to v1.4.3
#endif

#define SAOI_SecToTimeDay(%0)		((%0) / 86400),(((%0) % 86400) / 3600),((((%0) % 86400) % 3600) / 60),((((%0) % 86400) % 3600) % 60)
#define SAOI_MSToTimeDay(%0)		SAOI_SecToTimeDay((%0)/1000)

new Text3D:FindObjLabel[MAX_FIND_OBJ],
	bool:FindObj = false,
	SAOI:PlayerLastSAOI[MAX_PLAYERS];

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
	}
}

stock FindDynamicObject(playerid, Float:findradius, Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz, areaid, priority, index, fname[MAX_PATH],
		moid, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz, vw, int, Float:sd, Float:dd;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicObjects(i){
		if(cnt >= MAX_FIND_OBJ) break;
		if(IsValidDynamicObject(i)){
			GetDynamicObjectPos(i,x,y,z);
			if(VectorSize(px-x,py-y,pz-z) <= findradius){
				vw = GetDynamicObjectVW(i);
				int = GetDynamicObjectINT(i);
				moid = GetDynamicObjectModel(i);
				GetDynamicObjectRot(i,rx,ry,rz);
				GetDynamicObjectSD(i,sd);
				GetDynamicObjectDD(i,dd);
				areaid = GetDynamicObjectArea(i);
				priority = GetDynamicObjectPriority(i);
				szLIST = "";
				index = Streamer_GetIntData(STREAMER_TYPE_OBJECT,i,E_STREAMER_EXTRA_ID);
				if(index > SAOI_EXTRA_ID_OFFSET && index < SAOI_EXTRA_ID_OFFSET+SAOIToInt(MAX_SAOI_FILE)){
					index -= SAOI_EXTRA_ID_OFFSET;
					GetSAOILoadData(SAOI:index,fname);
					format(buffer,sizeof buffer,"{89C1FA}SAOI Name: {00AAFF}%s.saoi\n",fname[6]);
					strcat(szLIST,buffer);
				}
				format(buffer,sizeof buffer,"{89C1FA}Object: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %.0f %d %d)\n",i,moid,vw,int,sd,dd,areaid,priority);
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f,%.7f,%.7f)",x,y,z,rx,ry,rz);
				strcat(szLIST,buffer);
				FindObjLabel[cnt] = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
				cnt++;
			}
		}
	}
}

stock RemoveFindDynamicObjectLabel(){
	for(new i = 0; i < MAX_FIND_OBJ; i++){
		if(IsValidDynamic3DTextLabel(FindObjLabel[i])) DestroyDynamic3DTextLabel(FindObjLabel[i]);
	}
}

stock fcreate(const name[]){
	if(!fexist(name)){
		new File:cfile = fopen(name,io_readwrite);
		fwrite(cfile,"");
		fclose(cfile);
		return 1;
	}
	return 0;
}

CMD:addobjinfo(playerid,params[]){
	if(!IsPlayerAdmin(playerid)) return 0;
	if(FindObj) return SendClientMessage(playerid,0xB01010FF,"The function is active, usage /delobjinfo");
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /addobjinfo <streamdistance (1-300)> <find radius>");
	new Float:sd, Float:findr;
	sscanf(params,"ff",sd,findr);
	if(findr < 1.0) findr = 20.0;
	if(sd < 1.0 || sd > 300.0) return SendClientMessage(playerid,0xB01010FF,"Stream distance must be within range 1-300");
	new buffer[256];
	format(buffer,sizeof buffer,"The object description was included, coverage %.0fm",sd);
	SendClientMessage(playerid,0xFFFFFFFF,buffer);
	FindDynamicObject(playerid,findr,sd);
	FindObj = true;
	return 1;
}

CMD:delobjinfo(playerid){
	if(!IsPlayerAdmin(playerid)) return 0;
	if(!FindObj) return SendClientMessage(playerid,0xB01010FF,"Function deactivated");
	RemoveFindDynamicObjectLabel();
	FindObj = false;
	SendClientMessage(playerid,0xFFFFFFFF,"Removed all signatures of objects");
	return 1;
}

CMD:objstatus(playerid){
	if(!IsPlayerAdmin(playerid)) return 0;
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

CMD:saoicapacity(playerid){
	if(!IsPlayerAdmin(playerid)) return 0;
	new buffer[256];
	format(buffer,sizeof buffer,"{00AAFF}SAOI File loaded: {00FF00}%d / %d {00AAFF}Next free ID: {00FF00}%d",CountSAOIFileLoaded(),SAOIToInt(MAX_SAOI_FILE),SAOIToInt(FindFreeSAOIID()));
	SendClientMessage(playerid,0xFFFFFFFF,buffer);
	return 1;
}

CMD:saoiinfo(playerid,params[]){
	if(!IsPlayerAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoiinfo <name> (Only the file name, without extension)");
	new buffer[512], path[MAX_PATH], SAOI:index, Float:x, Float:y, Float:z, Float:angle, vw, int;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	if(!IsSAOIFileLoaded(path,index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is not loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
	new szLIST[1024], author[MAX_SAOI_AUTHOR_SIZE], version[MAX_SAOI_VERSION_SIZE], description[MAX_SAOI_DESCRIPTION_SIZE],
		fname[MAX_SAOI_NAME_SIZE], object_cnt, material_cnt, material_text_cnt, load_time, active_tick;
	
	szLIST = "";
	GetSAOIFileHeader(path,author,version,description);
	if(isnull(description)) description = "---";
	GetSAOILoadData(index,fname,object_cnt,material_cnt,material_text_cnt,load_time,active_tick);
	GetSAOIPositionFlag(index,x,y,z,angle,vw,int);
	
	format(buffer,sizeof buffer,"{00AAFF}Index: {00FF00}%d {00AAFF}SAOI Name: {00FF00}%s {00AAFF}Path: {00FF00}%s\n",SAOIToInt(index),params,path);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Author: {00FF00}%s {00AAFF}Version: {00FF00}%s\n",author,version);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Description: {00FF00}%s\n",description);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Objects: {00FF00}%d {00AAFF}Material: {00FF00}%d {00AAFF}Material Text: {00FF00}%d\n",object_cnt,material_cnt,material_text_cnt);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Active time: {00FF00}%d:%02d:%02d:%02d {00AAFF}Load time: {00FF00}%d {00AAFF}ms\n",SAOI_MSToTimeDay(GetTickCount()-active_tick),load_time);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}File Size: {00FF00}%d {00AAFF}B\n",GetSAOIFileSize(index));
	strcat(szLIST,buffer);
	
	if(x == 0.0 && y == 0.0 && z == 0.0 && angle == 0.0 && vw == 0 && int == 0){
		format(buffer,sizeof buffer,"{00AAFF}Position: {00FF00}Not found saved position.\n");
	} else {
		format(buffer,sizeof buffer,"{00AAFF}Position: {00FF00}%.4f %.4f %.4f {00AAFF}Angle: {00FF00}%.1f {00AAFF}World: {00FF00}%d {00AAFF}Interior: {00FF00}%d\n",x,y,z,angle,vw,int);
	}
	strcat(szLIST,buffer);
	
	ShowPlayerDialog(playerid,DIALOG_SAOI_INFO,DIALOG_STYLE_MSGBOX,"SAOI File Information", szLIST, "Exit", "Return");
	return 1;
}

CMD:streaminfo(playerid){
	if(!IsPlayerAdmin(playerid)) return 0;
	new buffer[256], szLIST[3096];
	format(buffer,sizeof buffer,"{00AAFF}Objects: {00FF00}%d / %d\n",CountObjects(),MAX_OBJECTS);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Vehicles: {00FF00}%d / %d\n",CountVehicles(),MAX_VEHICLES);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Players: {00FF00}%d / %d\n",CountPlayers(true,false),GetMaxPlayers()-CountPlayers(false,true));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}NPC: {00FF00}%d / %d\n",CountPlayers(false,true),GetServerVarAsInt("maxnpc"));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Actors: {00FF00}%d / %d\n",CountActors(),MAX_ACTORS);
	strcat(szLIST,buffer);
	strcat(szLIST,"\n");
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
		CountDynamicAreas(),Streamer_CountVisibleItems(playerid,STREAMER_TYPE_AREA)
	);
	strcat(szLIST,buffer);
	
	ShowPlayerDialog(playerid,DIALOG_SAOI_NUL,DIALOG_STYLE_MSGBOX,"{00FF00}Philon info:",szLIST,"Wyjdz","");
	return 1;
}

CMD:saoiload(playerid,params[]){
	if(!IsPlayerAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoiload <name> (Only the file name, without extension)");
	new buffer[256], path[MAX_PATH];
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	if(IsSAOIFileLoaded(path)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is already loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
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
	if(!IsPlayerAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoiunload <name> (Only the file name, without extension)");
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
	if(!IsPlayerAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoireload <name> (Only the file name, without extension)");
	
	new buffer[256], path[MAX_PATH], SAOI:index;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
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

CMD:saoilist(playerid){
	if(!IsPlayerAdmin(playerid)) return 0;
	new buffer[256], szLIST[4096], fname[MAX_PATH];
	
	for(new SAOI:i = SAOI:1; i < MAX_SAOI_FILE; i = SAOI:(SAOIToInt(i)+1)){
		if(!IsSAOISlotFree(i)){
			GetSAOILoadData(i,fname);
			format(buffer,sizeof buffer,"{FFFFFF}%d. {00FF00}%s\n",SAOIToInt(i),fname[6]);
			if(strlen(szLIST)+strlen(buffer) > sizeof(szLIST)) break;
			strcat(szLIST,buffer);
		}
	}
	if(isnull(szLIST)){
		szLIST = "Lack loaded files";
	}
	ShowPlayerDialog(playerid,DIALOG_SAOI_LIST,DIALOG_STYLE_LIST,"SAOI File List", szLIST, "Select", "Exit");
	return 1;
}

CMD:saoitp(playerid,params[]){
	if(!IsPlayerAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoitp <name> (Only the file name, without extension)");
	
	new buffer[256], path[MAX_PATH], SAOI:index;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	
	if(!IsSAOIFileLoaded(path,index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is not loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
	new Float:x, Float:y, Float:z, Float:angle, vw, int;
	GetSAOIPositionFlag(index,x,y,z,angle,vw,int);
	
	if(x == 0.0 && y == 0.0 && z == 0.0 && angle == 0.0 && vw == 0 && int == 0) return SendClientMessage(playerid,0xB01010FF,"Not found saved position!");
	
	SetPlayerPos(playerid,x,y,z);
	SetPlayerFacingAngle(playerid,angle);
	SetPlayerVirtualWorld(playerid,vw);
	SetPlayerInterior(playerid,int);
	return 1;
}

CMD:saoicmd(playerid){
	if(!IsPlayerAdmin(playerid)) return 0;
	new szLIST[1024];
	strcat(szLIST,"{00FF00}/addobjinfo - {00AAFF}adds descriptions of objects\n");
	strcat(szLIST,"{00FF00}/delobjinfo - {00AAFF}removes descriptions of objects\n");
	strcat(szLIST,"{00FF00}/objstatus - {00AAFF}show total object status\n");
	strcat(szLIST,"{00FF00}/saoicapacity - {00AAFF}shows the status of use of slots\n");
	strcat(szLIST,"{00FF00}/saoiinfo - {00AAFF}show saoi file information\n");
	strcat(szLIST,"{00FF00}/saoiload - {00AAFF}load saoi file\n");
	strcat(szLIST,"{00FF00}/saoiunload - {00AAFF}unload saoi file\n");
	strcat(szLIST,"{00FF00}/saoireload - {00AAFF}reload saoi file\n");
	strcat(szLIST,"{00FF00}/saoilist - {00AAFF}show loaded saoi files\n");
	strcat(szLIST,"{00FF00}/saoitp - {00AAFF}teleport to saoi flag\n");
	strcat(szLIST,"{00FF00}/streaminfo - {00AAFF}show stream info\n");
	ShowPlayerDialog(playerid,DIALOG_SAOI_NUL,DIALOG_STYLE_MSGBOX,"SAOI Command", szLIST, "Exit", "");
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]){
	switch(dialogid){
		case DIALOG_SAOI_LIST: {
			if(!response) return 0;
			PlayerLastSAOI[playerid] = SAOI:(listitem+1);
			ShowPlayerDialog(playerid,DIALOG_SAOI_ITEM,DIALOG_STYLE_LIST,"SAOI File Option","File Information\nReload File\nUnload File\nTeleport To Flag","Select","Return");
		}
		case DIALOG_SAOI_ITEM: {
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
			if(!response) return ShowPlayerDialog(playerid,DIALOG_SAOI_ITEM,DIALOG_STYLE_LIST,"SAOI File Option","File Information\nReload File\nUnload File\nTeleport To Flag","Select","Return");
		}
	}
	return 0;
}

public OnFilterScriptInit(){
	printf(" ");
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