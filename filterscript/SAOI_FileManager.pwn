/**********************************************************************************************************************************
 *                                                                                                                                *
 *                                                  )(   SAOI File Manager   )(                                                   *
 *                                                                                                                                *
 * Copyright � 2018 Abyss Morgan. All rights reserved.                                                                            *
 *                                                                                                                                *
 * Download: https://github.com/AbyssMorgan/SAOI/blob/master/filterscript                                                         *
 * Publication: http://forum.sa-mp.com/showthread.php?t=618429                                                                    *
 *                                                                                                                                *
 * Plugins: Streamer, SScanf, MapAndreas/ColAndreas, YSF                                                                          *
 * Modules: SAOI, 3DTryg, StreamerFunction, IZCMD/ZCMD, SWAP                                                                      *
 *                                                                                                                                *
 * File Version: 2.2.0                                                                                                            *
 * SA:MP Version: 0.3.7 (REQUIRE)                                                                                                 *
 * Streamer Version: 2.9.1                                                                                                        *
 * SScanf Version: 2.8.2                                                                                                          *
 * MapAndreas Version: 1.2.1                                                                                                      *
 * ColAndreas Version: 1.4.0                                                                                                      *
 * SAOI Version: 1.6.1                                                                                                            *
 * 3DTryg Version: 4.4.0                                                                                                          *
 * StreamerFunction Version: 2.8.0                                                                                                *
 * YSF Version: R19                                                                                                               *
 *                                                                                                                                *
 * Notice:                                                                                                                        *
 * Required directory /scriptfiles/SAOI                                                                                           *
 *                                                                                                                                *
 * Commands:                                                                                                                      *
 * /saoicmd - show saoi cmd                                                                                                       *
 *                                                                                                                                *
 **********************************************************************************************************************************
 *                                                                                                                                *
 * User Config                                                                                                                    *
 *                                                                                                                                *
 **********************************************************************************************************************************/

#define IsAdmin(%0)					(IsPlayerAdmin(%0) || CallRemoteFunction("SAOI_IsAdmin","d",(%0)))

//#define MAX_SAOI_FILE				(2001)
#define DIALOG_OFFSET				(1000)

/**********************************************************************************************************************************
 *                                                                                                                                *
 * End User Config                                                                                                                *
 *                                                                                                                                *
 **********************************************************************************************************************************/
 
#define FILTERSCRIPT
#define LOCK_SAOI_MEMORY				"SAOI_FileManager"
#define DISABLE_STREAMER_SPEC_FIXES		//Fix SAOI::UnloadObjectImage
#define DISABLE_3D_TRYG_FCNPC

#include <a_samp>

#if !defined _actor_included
	#include <a_actor>
#endif

#include <sscanf2>
#include <streamer>
#tryinclude <YSF>

#tryinclude <izcmd>
#if !defined CMD
	#tryinclude <zcmd>
#endif

#tryinclude <colandreas>
#if !defined COLANDREAS
	#tryinclude <mapandreas>
#endif

#include <SAM/StreamerFunction>
#include <SAM/3DTryg>
#include <SAM/SWAP>
#include <SAM/MD5>
#include <SAOI>

#define SAOI_OLDFILE_LIST			"/SAOI/SaoiFiles.txt"
#define SAOI_OLDFILE_CFG			"/SAOI/SAOI.cfg"
#define SAOI_FILE_BOOT				"/SAOI/boot"
#define SAOI_FILE_STREAMER			"/SAOI/streamer"

#define SAOIFM_EXTRA_ID_OFFSET		(1100000)		//You can never change !!!
#define MAX_SAOI_PATH				(70)

#define SAOI_BOOT_SIZE_HEADER		(0x00001000)
#define SAOI_BOOT_SIZE_CONFIG		(0x00000080)
#define SAOI_BOOT_SIZE_FILE			(MAX_SAOI_PATH)
#define SAOI_BOOT_OFFSET_FILES		(SAOI_BOOT_SIZE_HEADER + SAOI_BOOT_SIZE_CONFIG)
#define SAOI_BOOT_OFFSET_CONFIG		(SAOI_BOOT_SIZE_HEADER)

#if defined _samp_included
	#if (!defined GetPlayerPoolSize || !defined GetSVarInt)
		#error [ADM] This include requires SA:MP version 0.3.7 (github.com/AbyssMorgan/SA-MP/blob/master/samp/include)
	#endif
#elseif defined _rwmp_included
	#error [ADM] This game currently is not supported
#else
	#error [ADM] Not found any general game includes
#endif

//Check Version StreamerFunction.inc
#if !defined _streamer_spec
	#error [ADM] You need StreamerFunction.inc v2.8.0
#elseif !defined Streamer_Spec_Version
	#error [ADM] Update you StreamerFunction.inc to v2.8.0
#elseif (Streamer_Spec_Version < 20800)
	#error [ADM] Update you StreamerFunction.inc to v2.8.0
#endif

//Check Version 3DTryg.inc
#if !defined _3D_Tryg
	#error [ADM] You need 3DTryg.inc v4.3.0
#elseif !defined Tryg3D_Version
	#error [ADM] Update you 3DTryg.inc to v4.3.0
#elseif (Tryg3D_Version < 40300)
	#error [ADM] Update you 3DTryg.inc to v4.3.0
#endif

//Check Version SAOI.inc
#if !defined _SAOI_LOADER
	#error You need SAOI.inc v2.2.0 (github.com/AbyssMorgan/SAOI/releases)
#elseif !defined SAOI_LOADER_VERSION
	#error Update you SAOI.inc to v2.2.0 (github.com/AbyssMorgan/SAOI/releases)
#elseif (SAOI_LOADER_VERSION < 20200)
	#error Update you SAOI.inc to v2.2.0 (github.com/AbyssMorgan/SAOI/releases)
#endif

#if (!defined Tryg3D_MapAndreas && !defined Tryg3D_ColAndreas)
	#error [ADM] You need MapAndreas or ColAndreas
#endif

#if !defined _actor_included
	#error [ADM] You need a_actor.inc
#endif

//Check Version SWAP.inc
#if !defined _SWAP_include
	#error [ADM] You need SWAP.inc v1.2.0 (github.com/AbyssMorgan/SA-MP/blob/master/include/SAM/SWAP.inc)
#elseif !defined SWAP_Version
	#error [ADM] Update you SWAP.inc to v1.2.0 (github.com/AbyssMorgan/SA-MP/blob/master/include/SAM/SWAP.inc)
#elseif (SWAP_Version < 10200)
	#error [ADM] Update you SWAP.inc to v1.2.0 (github.com/AbyssMorgan/SA-MP/blob/master/include/SAM/SWAP.inc)
#endif

#if !defined CMD
	#error [ADM] You need izcmd.inc or zcmd.inc
#endif

//Update Checker
#if !defined HTTP
	#tryinclude <a_http>
#endif

#if !defined HTTP
	#error [ADM] You need a_http.inc
#endif

#define SAOI_GetValueBit(%0,%1)					((%0) >>> (%1) & 0x01)
#define SAOI_SetValueBit(%0,%1,%2)				((%0) = (((%0) & ~(0x01 << (%1))) | ((0x01 << (%1))*(%2))))

//Dynamic Toggle Config Macros
#define SAOI_GetConfigAddress(%0)				(floatround((%0)/32))
#define SAOI_GetConfigBit(%0)					((%0) % 32)
#define SAOI_GetConfigSize(%0)					(((%0) / 32)+1)

#define SAOI_IsToggleConfigInformation(%0,%1)	SAOI_GetValueBit(%0[SAOI_GetConfigAddress(%1)],SAOI_GetConfigBit(%1))
#define SAOI_ToggleConfigInformation(%0,%1,%2)	SAOI_SetValueBit(%0[SAOI_GetConfigAddress(%1)],SAOI_GetConfigBit(%1),((%2) & 0x1))

enum saoi_dialog {
	DIALOG_SAOI_NUL = DIALOG_OFFSET,
	DIALOG_SAOI_INFO,
	DIALOG_SAOI_LIST,
	DIALOG_SAOI_ITEM,
	DIALOG_SAOI_FINDER,
	DIALOG_SAOI_FINDER_DISABLE,
	DIALOG_SAOI_FINDER_PARAMS,
	DIALOG_SAOI_DESTROY,
	DIALOG_SAOI_DESTROY_PARAMS,
	DIALOG_SAOI_CFG
};

enum find_elements {
	e_dynamic_object,
	e_dynamic_pickup,
	e_dynamic_cp,
	e_dynamic_racecp,
	e_dynamic_mapicon,
	e_dynamic_actor,
	e_object,
	e_pickup,
	e_actor,
	e_vehicle,
	e_removebuilding,
	e_gangzone
};

enum find_option {
	bool:o_active,
	o_count
};

enum saoi_config {
	bool:save_log,
	bool:global_msg,
	bool:auto_freeze,
	bool:streamer_optimization,
	bool:streamer_reports,
	bool:streamer_limits,
	bool:saoi_fast_boot,
	bool:auto_clean
};

new elements_name[][] = {
	"DynamicObject",
	"DynamicPickup",
	"DynamicCP",
	"DynamicRaceCP",
	"DynamicMapIcon",
	"DynamicActor",
	"Object",
	"Pickup",
	"Actor",
	"Vehicle",
	"RemoveBuilding",
	"GangZone"
};

new SAOI_CFG_KEY[2][] = {
	{101,225,251,191,58,96,176,35,9,252,40,145,83,113,52,186,15,64,127,27,158,39,90,213,113,98,68,77,124,164,60,131,
	89,212,199,51,61,136,192,174,155,66,227,117,154,109,24,154,55,21,127,215,58,106,63,107,218,243,15,184,47,145,128,158,
	92,59,17,149,120,115,241,140,65,138,146,133,128,153,242,237,58,59,168,188,155,11,177,81,163,225,248,11,141,203,167,167,
	4,205,48,92,5,89,26,184,146,141,140,56,28,47,154,170,174,104,83,67,217,67,135,128,99,229,88,189,174,138,135,150},
	
	{155,31,5,65,198,160,80,221,247,4,216,111,173,143,204,70,241,192,129,229,98,217,166,43,143,158,188,179,132,92,196,125,
	167,44,57,205,195,120,64,82,101,190,29,139,102,147,232,102,201,235,129,41,198,150,193,149,38,13,241,72,209,111,128,98,
	164,197,239,107,136,141,15,116,191,118,110,123,128,103,14,19,198,197,88,68,101,245,79,175,93,31,8,245,115,53,89,89,
	252,51,208,164,251,167,230,72,110,115,116,200,228,209,102,86,82,152,173,189,39,189,121,128,157,27,168,67,82,118,121,106}
};

new SAOI::Finder[find_elements][find_option],
	PlayerLastSAOI[MAX_PLAYERS],
	PlayerLastItem[MAX_PLAYERS],
	PlayerListOffset[MAX_PLAYERS],
	SAOI::Config[saoi_config],
	SAOI::ErrorLevel = 0,
	bool:fm_fast_boot = true;

stock SAOI::CreateBootFile(){
	if(fexist(SAOI_FILE_BOOT)) return 0;
	new size = SAOI_BOOT_SIZE_HEADER + SAOI_BOOT_SIZE_CONFIG + (MAX_SAOI_FILE*SAOI_BOOT_SIZE_FILE),
		orm = 4096 - (size % 4096);
	size += orm;
	SWAP::reserve(SAOI_FILE_BOOT,size);
	SWAP::format_random(SAOI_FILE_BOOT);
	new tmp[128];
	for(new x = 0; x < SAOI_BOOT_SIZE_HEADER; x += 128){
		SWAP::write_block(SAOI_FILE_BOOT,SAOI_CFG_KEY,x,tmp,128);
	}
	for(new x = SAOI_BOOT_OFFSET_CONFIG; x < SAOI_BOOT_OFFSET_CONFIG+SAOI_BOOT_SIZE_CONFIG; x++){
		SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,x,0);
	}
	SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:save_log),1);
	SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:global_msg),1);
	SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:auto_freeze),1);
	SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:streamer_reports),Streamer::IsToggleErrorCallback());
	return size;
}

stock SAOI::CreateStreamerConfig(){
	if(fexist(SAOI_FILE_STREAMER)) return 0;
	SWAP::reserve(SAOI_FILE_STREAMER,512);
	SWAP::format_random(SAOI_FILE_STREAMER);
	SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,0*4,500);	//Objects
	SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,1*4,4096);	//Pickups
	SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,2*4,100);	//Map Icons
	SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,3*4,1024);	//3DText
	SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,5*4,1000);	//Actors
	for(new i = 0; i < STREAMER_MAX_TYPES; i++){
		SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,128+i*4,Streamer::GetMaxItems(i));
	}
	return 1;
}

stock SAOI::LoadStreamerOptimization(){
	if(!fexist(SAOI_FILE_STREAMER)) SAOI::CreateStreamerConfig();
	Streamer::SetVisibleItems(STREAMER_TYPE_OBJECT,			SWAP::read_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,0*4), -1);
	Streamer::SetVisibleItems(STREAMER_TYPE_PICKUP,			SWAP::read_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,1*4), -1);
	Streamer::SetVisibleItems(STREAMER_TYPE_MAP_ICON,		SWAP::read_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,2*4), -1);
	Streamer::SetVisibleItems(STREAMER_TYPE_3D_TEXT_LABEL,	SWAP::read_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,3*4), -1);
	Streamer::SetVisibleItems(STREAMER_TYPE_ACTOR,			SWAP::read_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,4*4), -1);
	return 1;
}

stock SAOI::LoadStreamerLimits(){
	if(!fexist(SAOI_FILE_STREAMER)) SAOI::CreateStreamerConfig();
	for(new i = 0; i < STREAMER_MAX_TYPES; i++){
		Streamer::SetMaxItems(i,SWAP::read_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,128+i*4));
	}
}

stock SAOI::BootResize(max_elements){
	if(!fexist(SAOI_FILE_BOOT)) return 0;
	new size = SAOI_BOOT_SIZE_HEADER + SAOI_BOOT_SIZE_CONFIG + (max_elements*SAOI_BOOT_SIZE_FILE),
		orm = 4096 - (size % 4096);
	size += orm;
	new File:outf = fopen(SAOI_FILE_BOOT,io_readwrite), asize = flength(outf);
	if(asize > size) return 0;
	
	//reserve space
	fseek(outf,size-1,seek_start);
	fputchar(outf,0,false);
	
	//format new space
	fseek(outf,asize,seek_start);
	for(new i = asize; i < size; i++){
		fputchar(outf,random(256),false);
	}
	fclose(outf);
	return size-asize;
}

stock SAOI::FindBootID(const name[]){
	new buffer[256], saoi_boot[SAOI::GetConfigSize(MAX_SAOI_FILE)];
	SWAP::read_array(SAOI_FILE_BOOT,SAOI_CFG_KEY,0,saoi_boot,sizeof(saoi_boot));
	for(new i = 0; i < MAX_SAOI_FILE-1; i++){
		if(SAOI::IsToggleConfigInformation(saoi_boot,i)){
			SWAP::read_string(SAOI_FILE_BOOT,SAOI_CFG_KEY,SAOI_BOOT_OFFSET_FILES+(i*SAOI_BOOT_SIZE_FILE),buffer,SAOI_BOOT_SIZE_FILE);
			if(!strcmp(name,buffer,true)) return i;
		}
	}
	return -1;
}

stock SAOI::FindFreeBootID(){
	new saoi_boot[SAOI::GetConfigSize(MAX_SAOI_FILE)], rand_id = random(MAX_SAOI_FILE-1);
	SWAP::read_array(SAOI_FILE_BOOT,SAOI_CFG_KEY,0,saoi_boot,sizeof(saoi_boot));
	if(!SAOI::IsToggleConfigInformation(saoi_boot,rand_id)) return rand_id;
	for(new i = 0; i < MAX_SAOI_FILE-1; i++){
		if(!SAOI::IsToggleConfigInformation(saoi_boot,i)) return i;
	}
	return -1;
}

stock SAOI::SetBoot(name[],toggle){
	new saoi_boot[SAOI::GetConfigSize(MAX_SAOI_FILE)], id = -1;
	SWAP::read_array(SAOI_FILE_BOOT,SAOI_CFG_KEY,0,saoi_boot,sizeof(saoi_boot));
	if((id = SAOI::FindBootID(name)) == -1){
		if(toggle){
			id = SAOI::FindFreeBootID();
			if(id != -1){
				SAOI::ToggleConfigInformation(saoi_boot,id,1);
				SWAP::write_string(SAOI_FILE_BOOT,SAOI_CFG_KEY,SAOI_BOOT_OFFSET_FILES+(id*SAOI_BOOT_SIZE_FILE),name,strlen(name)+1);
			}
		}
	} else {
		if(!toggle){
			SAOI::ToggleConfigInformation(saoi_boot,id,0);
		}
	}
	SWAP::write_array(SAOI_FILE_BOOT,SAOI_CFG_KEY,0,saoi_boot,sizeof(saoi_boot));
	return id;
}

//Main
stock SAOI::RemoveFinderLabel(find_elements:type){
	new idx = SAOIFM_EXTRA_ID_OFFSET + _:type;
	ForDynamic3DTextLabels(i){
		if(IsValidDynamic3DTextLabel(i)){
			if(Streamer::GetIntData(STREAMER_TYPE_3D_TEXT_LABEL,i,E_STREAMER_EXTRA_ID) == idx){
				DestroyDynamic3DTextLabel(i);
			}
		}
	}
	if(type == e_gangzone){
		ForDynamicMapIcons(i){
			if(IsValidDynamicMapIcon(i)){
				if(Streamer::GetIntData(STREAMER_TYPE_MAP_ICON,i,E_STREAMER_EXTRA_ID) == idx){
					DestroyDynamicMapIcon(i);
				}
			}
		}
	}
}

//FINDER:DynamicObject
stock SAOI::FindDynamicObject(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz, index, fname[MAX_SAOI_PATH],
		Float:sd, Float:dd, Text3D:elementid, targetid,
		Float:x, Float:y, Float:z,
		Float:rx, Float:ry, Float:rz,
		Float:tx, Float:ty, Float:tz,
		Float:trx, Float:try, Float:trz,
		Float:offset_x, Float:offset_y, Float:offset_z,
		Float:offset_rx, Float:offset_ry, Float:offset_rz, bool:attached_flag;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicObjects(i){
		if(IsValidDynamicObject(i)){
			if((targetid = Streamer::GetIntData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACHED_OBJECT)) != INVALID_STREAMER_ID){
				attached_flag = true;
				GetDynamicObjectPos(targetid,tx,ty,tz);
				GetDynamicObjectRot(targetid,trx,try,trz);
			} else if((targetid = Streamer::GetIntData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACHED_PLAYER)) != INVALID_PLAYER_ID){
				attached_flag = true;
				GetPlayerPos(targetid,tx,ty,tz);
				GetPlayerFacingAngle(playerid,trz);
				trx = try = 0.0;
			} else if((targetid = Streamer::GetIntData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACHED_VEHICLE)) != INVALID_VEHICLE_ID){
				attached_flag = true;
				GetVehiclePos(targetid,tx,ty,tz);
				GetVehicleRotation(targetid,trx,try,trz);
			} else {
				attached_flag = false;
			}
			if(attached_flag){
				Streamer::GetFloatData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACH_OFFSET_X,offset_x);
				Streamer::GetFloatData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACH_OFFSET_Y,offset_y);
				Streamer::GetFloatData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACH_OFFSET_Z,offset_z);
				Streamer::GetFloatData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACH_R_X,offset_rx);
				Streamer::GetFloatData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACH_R_Y,offset_ry);
				Streamer::GetFloatData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACH_R_Z,offset_rz);
				ShiftOffsetToPosition(tx,ty,tz,trx,try,trz,offset_x,offset_y,offset_z,x,y,z);
			} else {
				GetDynamicObjectPos(i,x,y,z);
			}
			if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
				targetid = INVALID_STREAMER_ID;
				GetDynamicObjectRot(i,rx,ry,rz);
				GetDynamicObjectSD(i,sd);
				GetDynamicObjectDD(i,dd);
				szLIST = "";
				index = Streamer::GetIntData(STREAMER_TYPE_OBJECT,i,E_STREAMER_EXTRA_ID);
				if(index > SAOI_EXTRA_ID_OFFSET && index < SAOI_EXTRA_ID_OFFSET+MAX_SAOI_FILE){
					index -= SAOI_EXTRA_ID_OFFSET;
					format(fname,sizeof(fname),"%s",SAOI::GetFileName(index));
					format(buffer,sizeof buffer,"{89C1FA}SAOI Name: {00AAFF}%s.saoi\n",fname[6]);
					strcat(szLIST,buffer);
				}
				if((targetid = Streamer::GetIntData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACHED_OBJECT)) != INVALID_STREAMER_ID){
					format(buffer,sizeof buffer,"{89C1FA}AttachedDynamicObject: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %.0f %d %d)\n",i,GetDynamicObjectModel(i),GetDynamicObjectVW(i),GetDynamicObjectINT(i),sd,dd,GetDynamicObjectArea(i),GetDynamicObjectPriority(i));
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Offset: {00AAFF}(%.7f,%.7f,%.7f,%.7f,%.7f,%.7f)\n",offset_x,offset_y,offset_z,offset_rx,offset_ry,offset_rz);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}CurrentPos: {00AAFF}(%.7f,%.7f,%.7f)\n",x,y,z);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}TargetID: {00AAFF}(%d) {89C1FA}TargetType: {00AAFF}Object",targetid);
					strcat(szLIST,buffer);
				} else if((targetid = Streamer::GetIntData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACHED_PLAYER)) != INVALID_PLAYER_ID){
					format(buffer,sizeof buffer,"{89C1FA}AttachedDynamicObject: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %.0f %d %d)\n",i,GetDynamicObjectModel(i),GetDynamicObjectVW(i),GetDynamicObjectINT(i),sd,dd,GetDynamicObjectArea(i),GetDynamicObjectPriority(i));
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Offset: {00AAFF}(%.7f,%.7f,%.7f,%.7f,%.7f,%.7f)\n",offset_x,offset_y,offset_z,offset_rx,offset_ry,offset_rz);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}CurrentPos: {00AAFF}(%.7f,%.7f,%.7f)\n",x,y,z);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}TargetID: {00AAFF}(%d) {89C1FA}TargetType: {00AAFF}Player",targetid);
					strcat(szLIST,buffer);
				} else if((targetid = Streamer::GetIntData(STREAMER_TYPE_OBJECT,i,E_STREAMER_ATTACHED_VEHICLE)) != INVALID_VEHICLE_ID){
					format(buffer,sizeof buffer,"{89C1FA}AttachedDynamicObject: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %.0f %d %d)\n",i,GetDynamicObjectModel(i),GetDynamicObjectVW(i),GetDynamicObjectINT(i),sd,dd,GetDynamicObjectArea(i),GetDynamicObjectPriority(i));
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Offset: {00AAFF}(%.7f,%.7f,%.7f,%.7f,%.7f,%.7f)\n",offset_x,offset_y,offset_z,offset_rx,offset_ry,offset_rz);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}CurrentPos: {00AAFF}(%.7f,%.7f,%.7f)\n",x,y,z);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}TargetID: {00AAFF}(%d) {89C1FA}TargetType: {00AAFF}Vehicle",targetid);
					strcat(szLIST,buffer);
				} else {
					format(buffer,sizeof buffer,"{89C1FA}DynamicObject: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %.0f %d %d)\n",i,GetDynamicObjectModel(i),GetDynamicObjectVW(i),GetDynamicObjectINT(i),sd,dd,GetDynamicObjectArea(i),GetDynamicObjectPriority(i));
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f,%.7f,%.7f)",x,y,z,rx,ry,rz);
					strcat(szLIST,buffer);
				}
				elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,GetDynamicObjectVW(i),GetDynamicObjectINT(i),-1,streamdistance,GetDynamicObjectArea(i));
				Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_dynamic_object));
				cnt++;
			}
		}
	}
	SAOI::Finder[e_dynamic_object][o_count] = cnt;
}

//FINDER:DynamicPickup
stock SAOI::FindDynamicPickup(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz, index, fname[MAX_SAOI_PATH],
		Float:x, Float:y, Float:z, Float:sd,
		Text3D:elementid;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicPickups(i){
		if(IsValidDynamicPickup(i)){
			GetDynamicPickupPos(i,x,y,z);
			if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
				GetDynamicPickupSD(i,sd);
				szLIST = "";
				index = Streamer::GetIntData(STREAMER_TYPE_PICKUP,i,E_STREAMER_EXTRA_ID);
				if(index > SAOI_EXTRA_ID_OFFSET && index < SAOI_EXTRA_ID_OFFSET+MAX_SAOI_FILE){
					index -= SAOI_EXTRA_ID_OFFSET;
					format(fname,sizeof(fname),"%s",SAOI::GetFileName(index));
					format(buffer,sizeof buffer,"{89C1FA}SAOI Name: {00AAFF}%s.saoi\n",fname[6]);
					strcat(szLIST,buffer);
				}
				format(buffer,sizeof buffer,"{89C1FA}DynamicPickup: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %d %d)\n",i,GetDynamicPickupModel(i),GetDynamicPickupVW(i),GetDynamicPickupINT(i),sd,GetDynamicPickupArea(i),GetDynamicPickupPriority(i));
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f) {89C1FA}Type: {00AAFF}(%d)",x,y,z,GetDynamicPickupType(i));
				strcat(szLIST,buffer);
				elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,GetDynamicPickupVW(i),GetDynamicPickupINT(i),-1,streamdistance,GetDynamicPickupArea(i));
				Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_dynamic_pickup));
				cnt++;
			}
		}
	}
	SAOI::Finder[e_dynamic_pickup][o_count] = cnt;
}

//FINDER:DynamicMapIcon
stock SAOI::FindDynamicMapIcon(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz, Float:mz, index, fname[MAX_SAOI_PATH],
		Float:x, Float:y, Float:z, Float:sd,
		Text3D:elementid;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicMapIcons(i){
		if(IsValidDynamicMapIcon(i)){
			GetDynamicMapIconPos(i,x,y,z);
			if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
				if(!(0 <= (Streamer::GetIntData(STREAMER_TYPE_MAP_ICON,i,E_STREAMER_EXTRA_ID)-SAOIFM_EXTRA_ID_OFFSET) < sizeof(SAOI::Finder))){
					GetDynamicMapIconSD(i,sd);
					Tryg3D::MapAndreasFindZ(x,y,mz);
					szLIST = "";
					index = Streamer::GetIntData(STREAMER_TYPE_MAP_ICON,i,E_STREAMER_EXTRA_ID);
					if(index > SAOI_EXTRA_ID_OFFSET && index < SAOI_EXTRA_ID_OFFSET+MAX_SAOI_FILE){
						index -= SAOI_EXTRA_ID_OFFSET;
						format(fname,sizeof(fname),"%s",SAOI::GetFileName(index));
						format(buffer,sizeof buffer,"{89C1FA}SAOI Name: {00AAFF}%s.saoi\n",fname[6]);
						strcat(szLIST,buffer);
					}
					format(buffer,sizeof buffer,"{89C1FA}DynamicMapIcon: {00AAFF}(%d) {89C1FA}Type: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %d %d)\n",i,GetDynamicMapIconType(i),GetDynamicMapIconVW(i),GetDynamicMapIconINT(i),sd,GetDynamicMapIconArea(i),GetDynamicMapIconPriority(i));
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f)\n",x,y,z);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Color: {00AAFF}(0x%08x) {89C1FA}Style: {00AAFF}(%d)",GetDynamicMapIconColor(i),GetDynamicMapIconStyle(i));
					strcat(szLIST,buffer);
					elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,mz+1.0,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,GetDynamicMapIconVW(i),GetDynamicMapIconINT(i),-1,streamdistance,GetDynamicMapIconArea(i));
					Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_dynamic_mapicon));
					cnt++;
				}
			}
		}
	}
	SAOI::Finder[e_dynamic_mapicon][o_count] = cnt;
}

#if defined _YSF_included
	//FINDER:Vehicle
	stock SAOI::FindVehicle(Float:streamdistance = 20.0){
		new buffer[256], szLIST[768], cnt = 0, Float:x, Float:y, Float:z, Float:angle, color1, color2, modelid, fname[MAX_SAOI_PATH],
			v_status[16], Float:tx, Float:ty, Float:tz,
			Text3D:elementid;
		
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
				if(SAOI::Vehicles[i] != INVALID_SAOI_FILE){
					format(fname,sizeof(fname),"%s",SAOI::GetFileName(SAOI::Vehicles[i]));
					format(buffer,sizeof buffer,"{89C1FA}SAOI Name: {00AAFF}%s.saoi\n",fname[6]);
					strcat(szLIST,buffer);
				}
				format(buffer,sizeof buffer,"{89C1FA}Vehicle: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d)\n",i,modelid,GetVehicleVirtualWorld(i),GetVehicleInterior(i));
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Spawn: {00AAFF}(%.7f,%.7f,%.7f,%.7f) {89C1FA}Last Status: {00AAFF}%s\n",x,y,z,angle,v_status);
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Color: {00AAFF}(%d %d) {89C1FA}Model Count: {00AAFF}(%d)",color1,color2,GetVehicleModelCount(modelid));
				strcat(szLIST,buffer);
				elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,GetVehicleVirtualWorld(i),-1,-1,streamdistance);
				Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_vehicle));
				cnt++;
			}
		}
		SAOI::Finder[e_vehicle][o_count] = cnt;
	}
	
	//FINDER:Object
	stock SAOI::FindObject(playerid,Float:findradius,Float:streamdistance = 20.0){
		new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz,
			Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz,
			Text3D:elementid;
		
		GetPlayerPos(playerid,px,py,pz);
		for(new i = 0; i < MAX_OBJECTS; i++){
			if(IsValidObject(i)){
				GetObjectPos(i,x,y,z);
				if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
					GetObjectRot(i,rx,ry,rz);
					szLIST = "";
					format(buffer,sizeof buffer,"{89C1FA}Object: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%.0f)\n",i,GetObjectModel(i),GetObjectDrawDistance(i));
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f,%.7f,%.7f)",x,y,z,rx,ry,rz);
					strcat(szLIST,buffer);
					elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
					Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_object));
					cnt++;
				}
			}
		}
		SAOI::Finder[e_object][o_count] = cnt;
	}
	
	//FINDER:Pickup
	stock SAOI::FindPickup(playerid,Float:findradius,Float:streamdistance = 20.0){
		new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz,
			Float:x, Float:y, Float:z, Text3D:elementid;
		
		GetPlayerPos(playerid,px,py,pz);
		for(new i = 0; i < MAX_PICKUPS; i++){
			if(IsValidPickup(i) && Streamer::GetItemStreamerID(playerid,STREAMER_TYPE_PICKUP,i) == INVALID_STREAMER_ID){
				GetPickupPos(i,x,y,z);
				if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
					szLIST = "";
					format(buffer,sizeof buffer,"{89C1FA}Pickup: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d)\n",i,GetPickupModel(i),GetPickupVirtualWorld(i));
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f) {89C1FA}Type: {00AAFF}(%d)",x,y,z,GetPickupType(i));
					strcat(szLIST,buffer);
					elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,GetPickupVirtualWorld(i),-1,-1,streamdistance);
					Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_pickup));
					cnt++;
				}
			}
		}
		SAOI::Finder[e_pickup][o_count] = cnt;
	}
	
	//FINDER:GangZone
	stock SAOI::FindGangZone(playerid,Float:findradius,Float:streamdistance = 20.0){
		new buffer[256], szLIST[768], cnt = 0, Float:minx, Float:miny, Float:maxx, Float:maxy, color1, color2,
			Float:x, Float:y, Float:z, Float:px, Float:py, Float:pz, elementid;
		
		GetPlayerPos(playerid,px,py,pz);
		for(new i = 0; i < MAX_GANG_ZONES; i++){
			if(IsValidGangZone(i)){
				GangZoneGetPos(i,minx,miny,maxx,maxy);
				GetPointFor2Point2D(minx,miny,maxx,maxy,50.0,x,y);
				if(GetDistanceBetweenPoints2D(x,y,px,py) <= findradius){
					color1 = GangZoneGetColorForPlayer(playerid,i);
					color2 = GangZoneGetFlashColorForPlayer(playerid,i);

					szLIST = "";
					format(buffer,sizeof buffer,"{89C1FA}GangZone: {00AAFF}(%d) {89C1FA}Point: {00AAFF}(center,center)\n",i);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Zone Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f)\n",minx,miny,maxx,maxy);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Color: {00AAFF}(0x%08x) {89C1FA}Flash Color: {00AAFF}(0x%08x)",color1,color2);
					strcat(szLIST,buffer);
					Tryg3D::MapAndreasFindZ(x,y,z);
					elementid = _:CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+1.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
					Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_gangzone));
					elementid = CreateDynamicMapIcon(x,y,z,19,0xFFFFFFFF,-1,-1,-1,300.0,MAPICON_LOCAL);
					Streamer::SetIntData(STREAMER_TYPE_MAP_ICON,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_gangzone));
					
					szLIST = "";
					format(buffer,sizeof buffer,"{89C1FA}GangZone: {00AAFF}(%d) {89C1FA}Point: {00AAFF}(minx,miny)\n",i);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Zone Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f)\n",minx,miny,maxx,maxy);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Color: {00AAFF}(0x%08x) {89C1FA}Flash Color: {00AAFF}(0x%08x)",color1,color2);
					strcat(szLIST,buffer);
					Tryg3D::MapAndreasFindZ(minx,miny,z);
					elementid = _:CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,minx,miny,z+1.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
					Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_gangzone));
					elementid = CreateDynamicMapIcon(minx,miny,z,56,0xFFFFFFFF,-1,-1,-1,300.0,MAPICON_LOCAL);
					Streamer::SetIntData(STREAMER_TYPE_MAP_ICON,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_gangzone));
					
					szLIST = "";
					format(buffer,sizeof buffer,"{89C1FA}GangZone: {00AAFF}(%d) {89C1FA}Point: {00AAFF}(minx,maxy)\n",i);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Zone Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f)\n",minx,miny,maxx,maxy);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Color: {00AAFF}(0x%08x) {89C1FA}Flash Color: {00AAFF}(0x%08x)",color1,color2);
					strcat(szLIST,buffer);
					Tryg3D::MapAndreasFindZ(minx,maxy,z);
					elementid = _:CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,minx,maxy,z+1.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
					Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_gangzone));
					elementid = CreateDynamicMapIcon(minx,maxy,z,56,0xFFFFFFFF,-1,-1,-1,300.0,MAPICON_LOCAL);
					Streamer::SetIntData(STREAMER_TYPE_MAP_ICON,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_gangzone));
					
					szLIST = "";
					format(buffer,sizeof buffer,"{89C1FA}GangZone: {00AAFF}(%d) {89C1FA}Point: {00AAFF}(maxx,miny)\n",i);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Zone Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f)\n",minx,miny,maxx,maxy);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Color: {00AAFF}(0x%08x) {89C1FA}Flash Color: {00AAFF}(0x%08x)",color1,color2);
					strcat(szLIST,buffer);
					Tryg3D::MapAndreasFindZ(maxx,miny,z);
					elementid = _:CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,maxx,miny,z+1.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
					Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_gangzone));
					elementid = CreateDynamicMapIcon(maxx,miny,z,56,0xFFFFFFFF,-1,-1,-1,300.0,MAPICON_LOCAL);
					Streamer::SetIntData(STREAMER_TYPE_MAP_ICON,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_gangzone));
					
					szLIST = "";
					format(buffer,sizeof buffer,"{89C1FA}GangZone: {00AAFF}(%d) {89C1FA}Point: {00AAFF}(maxx,maxy)\n",i);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Zone Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f)\n",minx,miny,maxx,maxy);
					strcat(szLIST,buffer);
					format(buffer,sizeof buffer,"{89C1FA}Color: {00AAFF}(0x%08x) {89C1FA}Flash Color: {00AAFF}(0x%08x)",color1,color2);
					strcat(szLIST,buffer);
					Tryg3D::MapAndreasFindZ(maxx,maxy,z);
					elementid = _:CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,maxx,maxy,z+1.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
					Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_gangzone));
					elementid = CreateDynamicMapIcon(maxx,maxy,z,56,0xFFFFFFFF,-1,-1,-1,300.0,MAPICON_LOCAL);
					Streamer::SetIntData(STREAMER_TYPE_MAP_ICON,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_gangzone));
					
					cnt++;
				}
			}
		}
		SAOI::Finder[e_gangzone][o_count] = cnt;
	}
#endif

//FINDER:RemoveBuilding
stock SAOI::FindRemoveBuilding(Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, modelid, Float:x, Float:y, Float:z, Float:radius, index, fname[MAX_SAOI_PATH],
		Text3D:elementid;
	for(new i = SAOI::RemoveUpperbound; i >= 0; i--){
		if(SAOI::RemoveBuildings[i][SAOI::modelid] != 0){
			SAOI::GetRemoveBuilding(i,index,modelid,x,y,z,radius);
			szLIST = "";
			format(fname,sizeof(fname),"%s",SAOI::GetFileName(index));
			format(buffer,sizeof buffer,"{89C1FA}SAOI Name: {00AAFF}%s.saoi\n",fname[6]);
			strcat(szLIST,buffer);
			format(buffer,sizeof buffer,"{89C1FA}Removed Building: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Radius: {00AAFF}(%f)\n",i,modelid,radius);
			strcat(szLIST,buffer);
			format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f)\n",x,y,z);
			strcat(szLIST,buffer);
			elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,-1,-1,-1,streamdistance);
			Streamer::SetIntData( STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_removebuilding));
			cnt++;
		}
	}
	SAOI::Finder[e_removebuilding][o_count] = cnt;
}

//FINDER:Actor
stock SAOI::FindActor(playerid,Float:streamdistance = 20.0){
	new buffer[256], szLIST[1000], cnt = 0,
		Float:x, Float:y, Float:z, Float:angle, Float:health,
		Text3D:elementid;
	
	for(new i = 0, j = GetActorPoolSize(); i <= j; i++){
		if(IsValidActor(i) && Streamer::GetItemStreamerID(playerid,STREAMER_TYPE_ACTOR,i) == INVALID_STREAMER_ID){
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

			elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,GetActorVirtualWorld(i),-1,-1,streamdistance);
			Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_actor));
			cnt++;
		}
	}
	SAOI::Finder[e_actor][o_count] = cnt;
}

//FINDER:DynamicActor
stock SAOI::FindDynamicActor(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[1000], cnt = 0,
		Float:x, Float:y, Float:z, Float:px, Float:py, Float:pz, Float:angle, Float:health, Float:sd,
		Text3D:elementid;
	
	GetPlayerPos(playerid,px,py,pz);
	
	ForDynamicActors(i){
		if(IsValidDynamicActor(i)){
			GetDynamicActorPos(i,x,y,z);
			if(GetDistanceBetweenPoints3D(x,y,z,px,py,pz) <= findradius){
				GetDynamicActorFacingAngle(i,angle);
				GetDynamicActorHealth(i,health);
				GetDynamicActorSD(i,sd);
				szLIST = "";
				format(buffer,sizeof buffer,"{89C1FA}DynamicActor: {00AAFF}(%d) {89C1FA}Model: {00AAFF}(%d) {89C1FA}Stream: {00AAFF}(%d %d %.0f %d %d)\n",i,GetDynamicActorModel(i),GetDynamicActorVirtualWorld(i),GetDynamicActorInterior(i),sd,GetDynamicActorArea(i),GetDynamicActorPriority(i));
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Pos: {00AAFF}(%.7f,%.7f,%.7f,%.7f)\n",x,y,z,angle);
				strcat(szLIST,buffer);
				format(buffer,sizeof buffer,"{89C1FA}Invulnerable: {00AAFF}%s {89C1FA}Health: {00AAFF}%.0f",IsDynamicActorInvulnerable(i)?("YES"):("NO"),health);
				strcat(szLIST,buffer);
				
				#if defined _YSF_included
					new animlib[64], animname[64], Float:fDelta, loop, lockx, locky, freeze, time, actorid;
					actorid = Streamer::GetItemInternalID(playerid,STREAMER_TYPE_ACTOR,i);
					GetActorAnimation(actorid,animlib,sizeof(animlib),animname,sizeof(animname),fDelta,loop,lockx,locky,freeze,time);
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
				
				elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,GetDynamicActorVirtualWorld(i),GetDynamicActorInterior(i),-1,streamdistance,GetDynamicActorArea(i));
				Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_dynamic_actor));
				cnt++;
			}
		}
	}
	SAOI::Finder[e_dynamic_actor][o_count] = cnt;
}

//FINDER:DynamicCP
stock SAOI::FindDynamicCP(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz,
		Float:x, Float:y, Float:z, Float:sd, Float:size,
		Text3D:elementid;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicCPs(i){
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
				elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,GetDynamicCPVW(i),GetDynamicCPINT(i),-1,streamdistance,GetDynamicCPArea(i));
				Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_dynamic_cp));
				cnt++;
			}
		}
	}
	SAOI::Finder[e_dynamic_cp][o_count] = cnt;
}

//FINDER:DynamicRaceCP
stock SAOI::FindDynamicRaceCP(playerid,Float:findradius,Float:streamdistance = 20.0){
	new buffer[256], szLIST[768], cnt = 0, Float:px, Float:py, Float:pz,
		Float:x, Float:y, Float:z, Float:nextx, Float:nexty, Float:nextz, Float:sd, Float:size,
		Text3D:elementid;
	
	GetPlayerPos(playerid,px,py,pz);
	ForDynamicRaceCPs(i){
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
				elementid = CreateDynamic3DTextLabel(szLIST,0x89C1FAFF,x,y,z+0.2,streamdistance,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,0,GetDynamicRaceCPVW(i),GetDynamicRaceCPINT(i),-1,streamdistance,GetDynamicRaceCPArea(i));
				Streamer::SetIntData(STREAMER_TYPE_3D_TEXT_LABEL,elementid,E_STREAMER_EXTRA_ID,(SAOIFM_EXTRA_ID_OFFSET+_:e_dynamic_racecp));
				cnt++;
			}
		}
	}
	SAOI::Finder[e_dynamic_racecp][o_count] = cnt;
}

stock SAOI::GetStatus(errorlevel){
	new buffer[24];
	switch(errorlevel){
		case 0: buffer = "{00FF00}Good";
		case 1..10: buffer = "{FFFF00}Not bad";
		case 11..100: buffer = "{FF6600}Bad";
		default: buffer = "{FF0000}Very bad";
	}
	return buffer;
}

#tryinclude <SAOI_Developer>

//Commands
CMD:saoi(playerid){
	new szLIST[3096], buffer[256];
	if(!IsAdmin(playerid)){
		format(buffer,sizeof buffer,"{00AAFF}San Andreas Object Image Loader by {FF0000}Abyss Morgan\n\n");
		strcat(szLIST,buffer);
		format(buffer,sizeof buffer,"{00AAFF}SAOI Version: {00FF00}%d.%d.%d {00AAFF}Status: %s\n",(SAOI_LOADER_VERSION / 10000),((SAOI_LOADER_VERSION % 10000) / 100),((SAOI_LOADER_VERSION % 10000) % 100),SAOI::GetStatus(SAOI_ErrorLevel));
		strcat(szLIST,buffer);
		#if defined SAOI_DEVELOPER_VERSION
			strcat(szLIST,SAOI_DEVELOPER_VERSION);
		#endif
		ShowPlayerDialog(playerid,DIALOG_SAOI_NUL,DIALOG_STYLE_MSGBOX,"{00FFFF}SAOI Statistics", szLIST, "{00FF00}Exit", "");
		return 1;
	}
	
	new cnt_object = 0,
		cnt_pickup = 0,
		cnt_3dtext = 0,
		cnt_mapicon = 0,
		cnt_actor = 0,
		cnt_area = 0,
		cnt_vehicle = 0,
		cnt_material = 0,
		cnt_material_text = 0,
		cnt_removebuilding = 0,
		load_time = 0;
		
	#if defined SAOI_ColAndreas
		new cnt_caobject = 0;
	#endif
	
	SAOI::Foreach(i){
		if(SAOI::IsLoaded(i)){
			cnt_object += SAOI::CountDynamicObject(i);
			cnt_pickup += SAOI::CountDynamicPickup(i);
			cnt_3dtext += SAOI::CountDynamic3DTextLabel(i);
			cnt_mapicon += SAOI::CountDynamicMapIcon(i);
			cnt_actor += SAOI::CountDynamicActor(i);
			cnt_area += SAOI::CountDynamicArea(i);
			cnt_vehicle += SAOI::CountVehicle(i);
			cnt_material += SAOI::CountMaterial(i);
			cnt_material_text += SAOI::CountMaterialText(i);
			cnt_removebuilding += SAOI::CountRemoveBuilding(i);
			load_time += SAOI::GetLoadTime(i);
			#if defined SAOI_ColAndreas
				cnt_caobject += SAOI::CountColAndreasObject(i);
			#endif
		}
	}
	
	szLIST = "";
	
	format(buffer,sizeof buffer,"{00AAFF}San Andreas Object Image Loader by {FF0000}Abyss Morgan\n\n");
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}SAOI Version: {00FF00}%d.%d.%d {00AAFF}File Header: {00FF00}%s {00AAFF}Status: %s\n",(SAOI_LOADER_VERSION / 10000),((SAOI_LOADER_VERSION % 10000) / 100),((SAOI_LOADER_VERSION % 10000) % 100),SAOI_HEADER_KEY,SAOI::GetStatus(SAOI_ErrorLevel));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}File loaded: {00FF00}%d / %d {00AAFF}Next free ID: {00FF00}%d\n",SAOI::CountFileLoaded(),MAX_SAOI_FILE-1,SAOI::GetFreeID());
	strcat(szLIST,buffer);
	#if defined SAOI_DEVELOPER_VERSION
		strcat(szLIST,SAOI_DEVELOPER_VERSION);
	#endif
	
	strcat(szLIST,"\n");
	format(buffer,sizeof buffer,"{00AAFF}Objects: {00FF00}%d\n",cnt_object);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Materials: {00FF00}%d\n",cnt_material);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Material Texts: {00FF00}%d\n",cnt_material_text);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Pickups: {00FF00}%d\n",cnt_pickup);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}MapIcons: {00FF00}%d\n",cnt_mapicon);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}3DText: {00FF00}%d\n",cnt_3dtext);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Areas: {00FF00}%d\n",cnt_area);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Actors: {00FF00}%d\n",cnt_actor);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Vehicles: {00FF00}%d\n",cnt_vehicle);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Removed Buildings: {00FF00}%d\n",cnt_removebuilding);
	strcat(szLIST,buffer);
	#if defined SAOI_ColAndreas
		format(buffer,sizeof buffer,"{00AAFF}ColAndreas Objects: {00FF00}%d\n",cnt_caobject);
		strcat(szLIST,buffer);
	#endif
	strcat(szLIST,"\n");
	format(buffer,sizeof buffer,"{00AAFF}Memory Loaded: {00FF00}%d KB {00AAFF}Load Time: {00FF00}%d {00AAFF}ms\n",floatround(SAOI::GetMemoryLoaded()/1024),load_time);
	strcat(szLIST,buffer);

	ShowPlayerDialog(playerid,DIALOG_SAOI_NUL,DIALOG_STYLE_MSGBOX,"{00FFFF}SAOI Statistics", szLIST, "{00FF00}Exit", "");
	return 1;
}

CMD:objstatus(playerid){
	if(!IsAdmin(playerid)) return 0;
	new pVW, pINT, cnt = 0, vis, buffer[200], oVW, oINT, tmp = 0;
	pVW = GetPlayerVirtualWorld(playerid);
	pINT = GetPlayerInterior(playerid);
	vis = Streamer::CountVisibleItems(playerid,STREAMER_TYPE_OBJECT);
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
	new buffer[512], path[MAX_SAOI_PATH], index;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	if(!SAOI::IsFileLoaded(path,index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is not loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
	PlayerLastSAOI[playerid] = index;
	PlayerLastItem[playerid] = index-1;
	new szLIST[2048],
		author[MAX_SAOI_AUTHOR_SIZE],
		version[MAX_SAOI_VERSION_SIZE],
		description[MAX_SAOI_DESCRIPTION_SIZE],
		created_data[32],
		bootid = SAOI::FindBootID(path),
		offset;
	
	szLIST = "";
	SAOI::GetFileAuthor(index,author,version,description);
	if(isnull(description)) description = "---";
	
	format(buffer,sizeof buffer,"{00AAFF}Index: {00FF00}%d {00AAFF}SAOI Name: {00FF00}%s {00AAFF}Path: {00FF00}%s\n",index,params,path);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Author: {00FF00}%s {00AAFF}Version: {00FF00}%s\n",author,version);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Description: {00FF00}%s\n",description);
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}File Type: {00FF00}%s {00AAFF}Permissions: {00FF00}%s %s\n",
		(SAOI::IsStatic(index)?("Static"):("Dynamic")),
		(SAOI::IsReadOnly(index)?("Read-Only"):("Read/Write")),
		(SAOI::IsProtected(index)?("(Protected)"):(""))
	);
	strcat(szLIST,buffer);
	
	if(bootid != -1){
		offset = SAOI_BOOT_OFFSET_FILES+(bootid*SAOI_BOOT_SIZE_FILE);
		format(buffer,sizeof buffer,"{00AAFF}Address: {00FF00}0x%08x - 0x%08x {00AAFF}BootID: {00FF00}%d\n",offset,offset+strlen(path),bootid);
	} else {
		format(buffer,sizeof buffer,"{00AAFF}Address: {00FF00}0x%08x - 0x%08x {00AAFF}BootID: {00FF00}None\n",0,0,bootid);
	}
	strcat(szLIST,buffer);
	
	strcat(szLIST,"\n");
	format(buffer,sizeof buffer,"{00AAFF}Objects: {00FF00}%d\n",SAOI::CountDynamicObject(index));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Materials: {00FF00}%d\n",SAOI::CountMaterial(index));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Material Texts: {00FF00}%d\n",SAOI::CountMaterialText(index));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Pickups: {00FF00}%d\n",SAOI::CountDynamicPickup(index));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}MapIcons: {00FF00}%d\n",SAOI::CountDynamicMapIcon(index));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}3DText: {00FF00}%d\n",SAOI::CountDynamic3DTextLabel(index));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Areas: {00FF00}%d\n",SAOI::CountDynamicArea(index));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Actors: {00FF00}%d\n",SAOI::CountDynamicActor(index));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Vehicles: {00FF00}%d\n",SAOI::CountVehicle(index));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Removed Buildings: {00FF00}%d\n",SAOI::CountRemoveBuilding(index));
	strcat(szLIST,buffer);
	#if defined SAOI_ColAndreas
		format(buffer,sizeof buffer,"{00AAFF}ColAndreas Objects: {00FF00}%d\n",SAOI::CountColAndreasObject(index));
		strcat(szLIST,buffer);
	#endif
	
	strcat(szLIST,"\n");
	format(buffer,sizeof buffer,"{00AAFF}Active time: {00FF00}%d:%02d:%02d:%02d {00AAFF}Load time: {00FF00}%d {00AAFF}ms\n",Tryg3D::MSToTimeDay(SAOI::GetActiveTime(index)),SAOI::GetLoadTime(index));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"{00AAFF}Quota: {00FF00}%.2f %% {00AAFF}File Size: {00FF00}%d {00AAFF}B\n",((SAOI::CountAllElementsByIndex(index)*100.0)/SAOI::CountAllElements()),SAOI::GetFileSize(index));
	strcat(szLIST,buffer);
	
	strcat(szLIST,"\n");
	if(!SAOI::IsPositionFlagSet(index)){
		format(buffer,sizeof buffer,"{00AAFF}Position: {00FF00}Not found saved position.\n");
	} else {
		new Float:x, Float:y, Float:z, Float:angle, vw, int;
		SAOI::GetPositionFlag(index,x,y,z,angle,vw,int);
		format(buffer,sizeof buffer,"{00AAFF}Position: {00FF00}%.4f %.4f %.4f {00AAFF}Angle: {00FF00}%.1f {00AAFF}World: {00FF00}%d {00AAFF}Interior: {00FF00}%d\n",x,y,z,angle,vw,int);
	}
	strcat(szLIST,buffer);
	
	SAOI::GetFileCreationDate(index,created_data);
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
	new buffer[256], szLIST[3096],
		cnt_npc = CountPlayers(false,true),
		cnt_players = CountPlayers(true,false),
		max_npc = GetServerVarAsInt("maxnpc"),
		max_players = GetMaxPlayers();
	
	//Server Elements
	strcat(szLIST,"{00AAFF}Name\t{00AAFF}Amount\t{00AAFF}Limit\t{00AAFF}Visible\n");
	format(buffer,sizeof buffer,"Characters\t%d\t%d\t%d\n",cnt_players+cnt_npc,max_players,CountVisiblePlayers(playerid,true,true));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"Players\t%d\t%d\t%d\n",cnt_players,max_players-cnt_npc,CountVisiblePlayers(playerid,true,false));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"NPC\t%d\t%d\t%d\n",cnt_npc,max_npc,CountVisiblePlayers(playerid,false,true));
	strcat(szLIST,buffer);
	
	//Static Elements
	strcat(szLIST,"\t\t\t\n");
	format(buffer,sizeof buffer,"Objects\t%d\t%d\t---\n",CountObjects(),MAX_OBJECTS);
	strcat(szLIST,buffer);
	
	new pcnt;
	
	#if defined _YSF_included
		new cnt = 0;
		for(new i = 0, j = MAX_PICKUPS; i < j; i++){
			if(IsValidPickup(i)) cnt++;
		}
		pcnt = Streamer::CountVisibleItems(playerid,STREAMER_TYPE_PICKUP,1);
		format(buffer,sizeof buffer,"Pickups\t%d\t%d\t---\n",cnt-pcnt,MAX_PICKUPS-pcnt);
		strcat(szLIST,buffer);
	#endif
	
	pcnt = Streamer::CountVisibleItems(playerid,STREAMER_TYPE_ACTOR,1);
	format(buffer,sizeof buffer,"Actors\t%d\t%d\t%d\n",CountActors(),MAX_ACTORS-pcnt,CountVisibleActors(playerid)-Streamer::CountVisibleItems(playerid,STREAMER_TYPE_ACTOR,0));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"Vehicles\t%d\t%d\t%d\n",CountVehicles(),MAX_VEHICLES,CountVisibleVehicles(playerid));
	strcat(szLIST,buffer);
	#if defined _YSF_included
		format(buffer,sizeof buffer,"Vehicle Models\t%d\t%d\t---\n",GetVehicleModelsUsed(),212);
		strcat(szLIST,buffer);
		strcat(szLIST,"\t\t\t\n");
		format(buffer,sizeof buffer,"GangZone\t%d\t%d\t%d\n",CountGangZone(),MAX_GANG_ZONES,CountVisibleGangZone(playerid));
		strcat(szLIST,buffer);
		format(buffer,sizeof buffer,"PlayerGangZone\t%d\t%d\t%d\n",CountPlayerGangZone(playerid),MAX_GANG_ZONES,CountVisiblePlayerGangZone(playerid));
		strcat(szLIST,buffer);
		format(buffer,sizeof buffer,"TextDraw\t%d\t%d\t%d\n",CountTextDraw(),MAX_TEXT_DRAWS,CountVisibleTextDraw(playerid));
		strcat(szLIST,buffer);
		format(buffer,sizeof buffer,"PlayerTextDraw\t%d\t%d\t%d\n",CountPlayerTextDraw(playerid),MAX_PLAYER_TEXT_DRAWS,CountVisiblePlayerTextDraw(playerid));
		strcat(szLIST,buffer);
	#endif
	
	//Dynamic Elements
	strcat(szLIST,"\t\t\t\n");
	format(buffer,sizeof buffer,"DynamicObjects\t%d\t---\t%d\n",CountDynamicObjects(),Streamer::CountVisibleItems(playerid,STREAMER_TYPE_OBJECT,0));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"DynamicPickup\t%d\t---\t%d\n",CountDynamicPickups(),Streamer::CountVisibleItems(playerid,STREAMER_TYPE_PICKUP,0));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"DynamicCP\t%d\t---\t%d\n",CountDynamicCPs(),Streamer::CountVisibleItems(playerid,STREAMER_TYPE_CP,0));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"DynamicRaceCP\t%d\t---\t%d\n",CountDynamicRaceCPs(),Streamer::CountVisibleItems(playerid,STREAMER_TYPE_RACE_CP,0));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"DynamicMapIcon\t%d\t---\t%d\n",CountDynamicMapIcons(),Streamer::CountVisibleItems(playerid,STREAMER_TYPE_MAP_ICON,0));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"Dynamic3DText\t%d\t---\t%d\n",CountDynamic3DTextLabels(),Streamer::CountVisibleItems(playerid,STREAMER_TYPE_3D_TEXT_LABEL,0));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"DynamicArea\t%d\t---\t%d\n",CountDynamicAreas(),GetPlayerNumberDynamicAreas(playerid));
	strcat(szLIST,buffer);
	format(buffer,sizeof buffer,"DynamicActor\t%d\t---\t%d\n",CountDynamicActors(),Streamer::CountVisibleItems(playerid,STREAMER_TYPE_ACTOR,0));
	strcat(szLIST,buffer);
	
	//SAOI Elements
	strcat(szLIST,"\t\t\t\n");
	format(buffer,sizeof buffer,"Removed Buildings\t%d\t%d\t---\n",SAOI::CountRemovedBuildings(),MAX_OBJECTS);
	strcat(szLIST,buffer);
	
	ShowPlayerDialog(playerid,DIALOG_SAOI_NUL,DIALOG_STYLE_TABLIST_HEADERS,"{00FFFF}SAOI Stream info",szLIST,"{00FF00}Exit","");
	return 1;
}

CMD:saoiload(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoiload <name> (Only file name, without extension)");
	new buffer[256], path[MAX_SAOI_PATH];
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	if(SAOI::IsFileLoaded(path)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is already loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	if(!fexist(path)) return SendClientMessage(playerid,0xB01010FF,"File not exist");
	
	if(SAOI::Config[global_msg]){
		format(buffer,sizeof buffer,"[IMPORTANT] Load Objects: %s",params);
		SendClientMessageToAll(0xFF0000FF,buffer);
	}
	
	new edi = SAOI::LoadObjectImage(path,SAOI::Config[save_log],false);
	if(edi > 0){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}loaded",params);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	} else {
		new error_name[MAX_SAOI_ERROR_NAME];
		SAOI::GetErrorName(edi,error_name);
		printf("[SAOI DEBUG] %s: %s",path,error_name);
		SAOI::ErrorLevel++;
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}not loaded (%s)",path,error_name);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	return 1;
}

CMD:saoiboot(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoiboot <name> (Only file name, without extension)");
	new buffer[256], path[MAX_SAOI_PATH];
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	if(SAOI::IsFileLoaded(path)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is already loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	if(!fexist(path)) return SendClientMessage(playerid,0xB01010FF,"File not exist");
	
	if(SAOI::Config[global_msg]){
		format(buffer,sizeof buffer,"[IMPORTANT] Load Objects: %s",params);
		SendClientMessageToAll(0xFF0000FF,buffer);
	}
	
	new edi = SAOI::LoadObjectImage(path,SAOI::Config[save_log],false);
	if(edi > 0){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}loaded",params);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
		if(SAOI::FindBootID(path) == -1){
			SAOI::SetBoot(path,1);
		}
	} else {
		new error_name[MAX_SAOI_ERROR_NAME];
		SAOI::GetErrorName(edi,error_name);
		printf("[SAOI DEBUG] %s: %s",path,error_name);
		SAOI::ErrorLevel++;
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}not loaded (%s)",path,error_name);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	return 1;
}

CMD:saoiunload(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoiunload <name> (Only file name, without extension)");
	new buffer[256], path[MAX_SAOI_PATH], index;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	if(!SAOI::IsFileLoaded(path,index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is not loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
	if(SAOI::Config[global_msg]){
		format(buffer,sizeof buffer,"[IMPORTANT] Unload Objects: %s",params);
		SendClientMessageToAll(0xFF0000FF,buffer);
	}
	if(SAOI::IsStatic(index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}cannot unload static file",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	if(SAOI::UnloadObjectImage(index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}unloaded",params);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	} else {
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}not unloaded",params);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	return 1;
}

CMD:saoiunboot(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoiunboot <name> (Only file name, without extension)");
	new buffer[256], path[MAX_SAOI_PATH], index, bool:unboot = false;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	
	if(SAOI::FindBootID(path) != -1){
		SAOI::SetBoot(path,0);
		unboot = true;
	}
	
	if(SAOI::IsFileLoaded(path,index)){
		if(SAOI::Config[global_msg]){
			format(buffer,sizeof buffer,"[IMPORTANT] Unload Objects: %s",params);
			SendClientMessageToAll(0xFF0000FF,buffer);
		}
		if(SAOI::UnloadObjectImage(index)){
			format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}unloaded %s",params,(unboot)?("(Removed from boot)"):(""));
			SendClientMessage(playerid,0xFFFFFFFF,buffer);
		} else {
			format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}not unloaded %s",params,(unboot)?("(Removed from boot)"):(""));
			SendClientMessage(playerid,0xFFFFFFFF,buffer);
		}
	} else {
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is not loaded %s",params,(unboot)?("(Removed from boot)"):(""));
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
	return 1;
}

CMD:saoireload(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(isnull(params)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoireload <name> (Only file name, without extension)");
	
	new buffer[256], path[MAX_SAOI_PATH], index;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	
	if(!fexist(path)) return SendClientMessage(playerid,0xB01010FF,"File not exist");
	
	if(SAOI::Config[global_msg]){
		format(buffer,sizeof buffer,"[IMPORTANT] Reload Objects: %s",params);
		SendClientMessageToAll(0xFF0000FF,buffer);
	}
	
	new Float:x, Float:y, Float:z, bool:freezed = false;
	if(SAOI::IsFileLoaded(path,index)){
		if(SAOI::IsStatic(index)){
			format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}cannot unload static file",params);
			return SendClientMessage(playerid,0xFFFFFFFF,buffer);
		}
		if(SAOI::File[index][SAOI::offset_object] != INVALID_STREAMER_ID){
			freezed = true;
			GetDynamicObjectPos(SAOI::File[index][SAOI::offset_object],x,y,z);
			if(SAOI::Config[auto_freeze]){
				Tryg3D::Foreach(i){
					if(IsPlayerInRangeOfPoint(i,300.0,x,y,z)){
						GameTextForPlayer(i,"~g~Freeze: Objects Reload",2500,4);
						TogglePlayerControllable(i,false);
					}
				}
			}
		}
		SAOI::UnloadObjectImage(index);
	}
	new edi = SAOI::LoadObjectImage(path,SAOI::Config[save_log],false);
	if(edi > 0){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}reloaded",params);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	} else {
		new error_name[MAX_SAOI_ERROR_NAME];
		SAOI::GetErrorName(edi,error_name);
		printf("[SAOI DEBUG] %s: %s",path,error_name);
		SAOI::ErrorLevel++;
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}not loaded (%s)",path,error_name);
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	if(SAOI::Config[auto_freeze]){
		if(freezed){
			Tryg3D::Foreach(i){
				if(IsPlayerInRangeOfPoint(i,300.0,x,y,z)){
					TogglePlayerControllable(i,true);
				}
			}
		}
	}
	return 1;
}

CMD:saoifinder(playerid){
	if(!IsAdmin(playerid)) return 0;
	new buffer[256], szLIST[800];
	for(new i = 0, j = sizeof(elements_name); i < j; i++){
		if(SAOI::Finder[find_elements:i][o_active]){
			format(buffer,sizeof buffer,"{00FF00}[YES]\t{00AAFF}%s {00FFFF}(%d)\n",elements_name[i],SAOI::Finder[find_elements:i][o_count]);
		} else {
			format(buffer,sizeof buffer,"{FF0000}[NO]\t{00AAFF}%s\n",elements_name[i]);
		}
		strcat(szLIST,buffer);
	}
	ShowPlayerDialog(playerid,DIALOG_SAOI_FINDER,DIALOG_STYLE_LIST,"{00FFFF}SAOI Element Finder",szLIST,"{00FF00}Select","{FF0000}Exit");
	return 1;
}

CMD:saoidestroy(playerid){
	if(!IsAdmin(playerid)) return 0;
	new buffer[256], szLIST[400];
	for(new i = 0, j = sizeof(elements_name); i < j; i++){
		format(buffer,sizeof buffer,"{00AAFF}%s\n",elements_name[i]);
		strcat(szLIST,buffer);
	}
	ShowPlayerDialog(playerid,DIALOG_SAOI_DESTROY,DIALOG_STYLE_LIST,"{00FFFF}SAOI Element Destroy",szLIST,"{00FF00}Select","{FF0000}Exit");
	return 1;
}

CMD:saoilist(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	new offset;
	if(sscanf(params,"d",offset)) return SendClientMessage(playerid,0xB01010FF,"Usage: /saoilist <listid 1-20>");
	if(offset < 1 || offset*100 >= _:MAX_SAOI_FILE) return SendClientMessage(playerid,0xB01010FF,"List not exist");
	offset--;
	PlayerListOffset[playerid] = offset;
	new buffer[256], szLIST[4096], fname[MAX_SAOI_PATH];
	for(new i = (1+(offset*100)); i < MAX_SAOI_FILE; i++){
		if(i-(offset*100) > 100) break;
		if(SAOI::IsLoaded(i)){
			format(fname,sizeof(fname),"%s",SAOI::GetFileName(i));
			if(SAOI::IsStatic(i)){
				format(buffer,sizeof buffer,"{FFFFFF}%d. {909090}%s\n",i,fname[6]);
			} else {
				format(buffer,sizeof buffer,"{FFFFFF}%d. {00FF00}%s\n",i,fname[6]);
			}
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
	new buffer[256], path[MAX_SAOI_PATH], index;
	format(path,sizeof(path),"/SAOI/%s.saoi",params);
	if(!SAOI::IsFileLoaded(path,index)){
		format(buffer,sizeof buffer,"{00AAFF}SAOI File {00FF00}%s {00AAFF}is not loaded",params);
		return SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	new Float:x, Float:y, Float:z, Float:angle, vw, int;
	if(!SAOI::IsPositionFlagSet(index)){
		if(SAOI::File[index][SAOI::offset_object] != INVALID_STREAMER_ID){
			GetDynamicObjectPos(SAOI::File[index][SAOI::offset_object],x,y,z);
			SetPlayerAbsolutePositionVeh(playerid,x,y,z,0.0,GetDynamicObjectVW(SAOI::File[index][SAOI::offset_object]),GetDynamicObjectINT(SAOI::File[index][SAOI::offset_object]),1000);
			return SendClientMessage(playerid,0xB01010FF,"Not found saved position (Teleported to first object)!");
		}
		return SendClientMessage(playerid,0xB01010FF,"Not found saved position!");
	}
	SAOI::GetPositionFlag(index,x,y,z,angle,vw,int);
	SetPlayerAbsolutePositionVeh(playerid,x,y,z,angle,vw,int,1000);
	return 1;
}

CMD:saoireboot(playerid){
	if(!IsAdmin(playerid)) return 0;
	if(SAOI::Config[global_msg]){
		SendClientMessageToAll(0xFF0000FF,"[IMPORTANT] Reloading objects and vehicles...");
	}
	if(SAOI::Config[auto_freeze]){
		Tryg3D::Foreach(i){
			GameTextForPlayer(i,"~g~Freeze: Objects Reload",2500,4);
			TogglePlayerControllable(i,false);
		}
	}
	SAOI::Foreach(i){
		if(SAOI::IsLoaded(i) && !SAOI::IsStatic(i)){
			SAOI::UnloadObjectImage(i);
		}
	}
	SAOI::LoadManager();
	UpdateAllDynamicObjects();
	if(SAOI::Config[auto_freeze]){
		Tryg3D::Foreach(i){
			TogglePlayerControllable(i,true);
		}
	}
	return 1;
}

CMD:saoicfg(playerid){
	if(!IsAdmin(playerid)) return 0;
	new szLIST[2048], buffer[256];
	
	format(buffer,sizeof(buffer),"%s\t{00AAFF}Save Log\n",SAOI::Config[save_log]?("{00FF00}[YES]"):("{FF0000}[NO]"));
	strcat(szLIST,buffer);
	format(buffer,sizeof(buffer),"%s\t{00AAFF}Global Message\n",SAOI::Config[global_msg]?("{00FF00}[YES]"):("{FF0000}[NO]"));
	strcat(szLIST,buffer);
	format(buffer,sizeof(buffer),"%s\t{00AAFF}Freeze System\n",SAOI::Config[auto_freeze]?("{00FF00}[YES]"):("{FF0000}[NO]"));
	strcat(szLIST,buffer);
	format(buffer,sizeof(buffer),"%s\t{00AAFF}Streamer Optimization\n",SAOI::Config[streamer_optimization]?("{00FF00}[YES]"):("{FF0000}[NO]"));
	strcat(szLIST,buffer);
	format(buffer,sizeof(buffer),"%s\t{00AAFF}Streamer Reports\n",SAOI::Config[streamer_reports]?("{00FF00}[YES]"):("{FF0000}[NO]"));
	strcat(szLIST,buffer);
	format(buffer,sizeof(buffer),"%s\t{00AAFF}Streamer Limits\n",SAOI::Config[streamer_limits]?("{00FF00}[YES]"):("{FF0000}[NO]"));
	strcat(szLIST,buffer);
	#if defined SAOI_DEVELOPER_VERSION
		format(buffer,sizeof(buffer),"%s\t{00AAFF}Fast Boot\n",SAOI::Config[saoi_fast_boot]?("{00FF00}[YES]"):("{FF0000}[NO]"));
	#else
		format(buffer,sizeof(buffer),"%s\t{909090}Fast Boot\n",SAOI::Config[saoi_fast_boot]?("{00FF00}[YES]"):("{FF0000}[NO]"));
	#endif
	strcat(szLIST,buffer);
	format(buffer,sizeof(buffer),"%s\t{00AAFF}Auto Clean Boot\n",SAOI::Config[auto_clean]?("{00FF00}[YES]"):("{FF0000}[NO]"));
	strcat(szLIST,buffer);
	
	ShowPlayerDialog(playerid,DIALOG_SAOI_CFG,DIALOG_STYLE_LIST,"{00FFFF}SAOI Config",szLIST,"{00FF00}Select","{FF0000}Exit");
	return 1;
}

CMD:streamerop(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(!SAOI::Config[streamer_optimization]) return SendClientMessage(playerid,0xB01010FF,"Streamer Optimizations is disabled, check /saoicfg>");
	new o_type[16], o_value;
	if(sscanf(params,"s[16] d",o_type,o_value)) return SendClientMessage(playerid,0xB01010FF,"Usage: /streamerop <object/pickup/mapicon/3dtext/actor> <max_visible_items>");
	if(!strcmp(o_type,"object",true)){
		SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,0*4,o_value);
		Streamer::SetVisibleItems(STREAMER_TYPE_OBJECT,o_value,-1);
	} else if(!strcmp(o_type,"pickup",true)){
		SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,1*4,o_value);
		Streamer::SetVisibleItems(STREAMER_TYPE_PICKUP,o_value,-1);
	} else if(!strcmp(o_type,"mapicon",true)){
		SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,2*4,o_value);
		Streamer::SetVisibleItems(STREAMER_TYPE_MAP_ICON,o_value,-1);
	} else if(!strcmp(o_type,"3dtext",true)){
		SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,3*4,o_value);
		Streamer::SetVisibleItems(STREAMER_TYPE_3D_TEXT_LABEL,o_value,-1);
	} else if(!strcmp(o_type,"actor",true)){
		SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,4*4,o_value);
		Streamer::SetVisibleItems(STREAMER_TYPE_ACTOR,o_value,-1);
	}
	return 1;
}

CMD:streamerlimit(playerid,params[]){
	if(!IsAdmin(playerid)) return 0;
	if(!SAOI::Config[streamer_limits]) return SendClientMessage(playerid,0xB01010FF,"Streamer Limits is disabled, check /saoicfg>");
	new o_type, o_value;
	if(sscanf(params,"dD(-2)",o_type,o_value)) return SendClientMessage(playerid,0xB01010FF,"Usage: /streamerlimit <type> [max_items]");
	if(o_type < 0 || o_type >= STREAMER_MAX_TYPES) return SendClientMessage(playerid,0xB01010FF,"Invalid type.");
	if(o_value == -2){
		new buffer[128];
		format(buffer,sizeof buffer,"{00AAFF}Streamer Type: {00FF00}%d {00AAFF}Max Items: {00FF00}%d",o_type,Streamer::GetMaxItems(o_type));
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	} else {
		SWAP::write_int(SAOI_FILE_STREAMER,SAOI_CFG_KEY,128+o_type*4,o_value);
		Streamer::SetMaxItems(o_type,o_value);
	}
	return 1;
}

CMD:saoicmd(playerid){
	if(!IsAdmin(playerid)) return 0;
	new szLIST[2048];
	strcat(szLIST,"{00FF00}/saoi - {00AAFF}shows statistics saoi\n");
	strcat(szLIST,"{00FF00}/saoicfg - {00AAFF}edit saoi config\n");
	strcat(szLIST,"{00FF00}/saoifinder - {00AAFF}element finder\n");
	strcat(szLIST,"{00FF00}/saoidestroy - {00AAFF}destroy element\n");
	strcat(szLIST,"{00FF00}/objstatus - {00AAFF}show total object status\n");
	strcat(szLIST,"{00FF00}/saoiinfo - {00AAFF}show saoi file information\n");
	strcat(szLIST,"{00FF00}/saoiload - {00AAFF}load saoi file\n");
	strcat(szLIST,"{00FF00}/saoiboot - {00AAFF}load saoi file (Add to SAOI::Files.txt)\n");
	strcat(szLIST,"{00FF00}/saoiunload - {00AAFF}unload saoi file\n");
	strcat(szLIST,"{00FF00}/saoiunboot - {00AAFF}unload saoi file (Remove from SAOI::Files.txt)\n");
	strcat(szLIST,"{00FF00}/saoireload - {00AAFF}reload saoi file\n");
	strcat(szLIST,"{00FF00}/saoireboot - {00AAFF}reload all saoi files\n");
	strcat(szLIST,"{00FF00}/saoilist - {00AAFF}show loaded saoi files\n");
	strcat(szLIST,"{00FF00}/saoitp - {00AAFF}teleport to saoi flag\n");
	strcat(szLIST,"{00FF00}/streaminfo - {00AAFF}show stream info\n");
	strcat(szLIST,"{00FF00}/streamerop - {00AAFF}change streamer config\n");
	strcat(szLIST,"{00FF00}/streamerlimit - {00AAFF}change streamer limits\n");
	strcat(szLIST,"{00FF00}/tptoobj - {00AAFF}teleport to object\n");
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
			new tmp_find, tmp_name[64];
			sscanf(inputtext,"p<.>d s[64]",tmp_find,tmp_name);
			
			PlayerLastSAOI[playerid] = (tmp_find);
			PlayerLastItem[playerid] = listitem;
			
			new path[MAX_SAOI_PATH], buffer[128];
			format(path,sizeof(path),"%s.saoi",SAOI::GetFileName(PlayerLastSAOI[playerid]));
			
			buffer = "{FFFFFF}";
			if(SAOI::IsStatic(PlayerLastSAOI[playerid])){
				format(buffer,sizeof(buffer),"File Information\n{%s}Teleport To Flag{FFFFFF}\n",SAOI::IsPositionFlagSet(PlayerLastSAOI[playerid])?("00FF00"):("FF0000"));
			} else {
				format(buffer,sizeof(buffer),"File Information\nReload File\nUnload File\n{%s}Teleport To Flag{FFFFFF}\n",SAOI::IsPositionFlagSet(PlayerLastSAOI[playerid])?("00FF00"):("FF0000"));
			}
			if(SAOI::FindBootID(path) != -1){
				strcat(buffer,"Boot: {00FF00}Enabled");
			} else {
				strcat(buffer,"Boot: {FF0000}Disabled");
			}
			ShowPlayerDialog(playerid,DIALOG_SAOI_ITEM,DIALOG_STYLE_LIST,"{00FFFF}SAOI File Option",buffer,"{00FF00}Select","{FF0000}Return");
		}
		
		case DIALOG_SAOI_ITEM: {
			if(!IsAdmin(playerid)) return 0;
			if(!response){
				new tmp_params[24];
				format(tmp_params,sizeof(tmp_params),"%d",PlayerListOffset[playerid]+1);
				return cmd_saoilist(playerid,tmp_params);
			}
			new path[MAX_SAOI_PATH], nname[MAX_SAOI_NAME_SIZE];
			format(path,sizeof(path),"%s",SAOI::GetFileName(PlayerLastSAOI[playerid]));
			sscanf(path,"'/SAOI/'s[64]",nname);
			strcat(path,".saoi");
			
			if(SAOI::IsStatic(PlayerLastSAOI[playerid])){
				switch(listitem){
					case 0: return cmd_saoiinfo(playerid,nname);
					case 1: return cmd_saoitp(playerid,nname);
					case 2: {
						if(SAOI::FindBootID(path) != -1){
							SAOI::SetBoot(path,0);
						} else {
							SAOI::SetBoot(path,1);
						}
						new tmp_params[64];
						format(tmp_params,sizeof(tmp_params),"%d. Unknown",_:PlayerLastSAOI[playerid]);
						return OnDialogResponse(playerid,DIALOG_SAOI_LIST,1,PlayerLastItem[playerid],tmp_params);
					}
				}
			} else {
				switch(listitem){
					case 0: return cmd_saoiinfo(playerid,nname);
					case 1: return cmd_saoireload(playerid,nname);
					case 2: return cmd_saoiunload(playerid,nname);
					case 3: return cmd_saoitp(playerid,nname);
					case 4: {
						if(SAOI::FindBootID(path) != -1){
							SAOI::SetBoot(path,0);
						} else {
							SAOI::SetBoot(path,1);
						}
						new tmp_params[64];
						format(tmp_params,sizeof(tmp_params),"%d. Unknown",_:PlayerLastSAOI[playerid]);
						return OnDialogResponse(playerid,DIALOG_SAOI_LIST,1,PlayerLastItem[playerid],tmp_params);
					}
				}
			}
		}
		
		case DIALOG_SAOI_INFO: {
			if(!IsAdmin(playerid)) return 0;
			if(!response){
				new tmp_params[64];
				format(tmp_params,sizeof(tmp_params),"%d. Unknown",_:PlayerLastSAOI[playerid]);
				return OnDialogResponse(playerid,DIALOG_SAOI_LIST,1,PlayerLastItem[playerid],tmp_params);
			}
		}
		
		case DIALOG_SAOI_FINDER: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return 0;
			PlayerLastItem[playerid] = listitem;
			if(SAOI::Finder[find_elements:listitem][o_active]){
				ShowPlayerDialog(playerid,DIALOG_SAOI_FINDER_DISABLE,DIALOG_STYLE_MSGBOX,"{00FFFF}SAOI Finder Option","You are sure for disable this option.","{00FF00}YES","{FF0000}NO");
			} else {
				ShowPlayerDialog(playerid,DIALOG_SAOI_FINDER_PARAMS,DIALOG_STYLE_INPUT,"{00FFFF}SAOI Finder Option","Choose stream distance and find distance. (separate space)","{00FF00}Find","{FF0000}Return");
			}
		}
		
		case DIALOG_SAOI_FINDER_DISABLE: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return cmd_saoifinder(playerid);
			new elementid = PlayerLastItem[playerid];
			if(SAOI::Finder[find_elements:elementid][o_active]){
				SAOI::RemoveFinderLabel(find_elements:elementid);
				new buffer[256];
				format(buffer,sizeof(buffer),"Removed all signatures of %s",elements_name[elementid]);
				SendClientMessage(playerid,0xFFFFFFFF,buffer);
				SAOI::Finder[find_elements:elementid][o_active] = false;
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
			
			if(!SAOI::Finder[find_elements:elementid][o_active]){
				switch(find_elements:elementid){
					case e_dynamic_object: {
						SAOI::FindDynamicObject(playerid,findr,sd);
					}
					case e_dynamic_pickup: {
						SAOI::FindDynamicPickup(playerid,findr,sd);
					}
					case e_dynamic_cp: {
						SAOI::FindDynamicCP(playerid,findr,sd);
					}
					case e_dynamic_racecp: {
						SAOI::FindDynamicRaceCP(playerid,findr,sd);
					}
					case e_dynamic_mapicon: {
						SAOI::FindDynamicMapIcon(playerid,findr,sd);
					}
					case e_dynamic_actor: {
						SAOI::FindDynamicActor(playerid,findr,sd);
					}
					case e_actor: {
						SAOI::FindActor(playerid,sd);
					}
					#if defined _YSF_included
						case e_object: {
							SAOI::FindObject(playerid,findr,sd);
						}
						case e_pickup: {
							SAOI::FindPickup(playerid,findr,sd);
						}
						case e_vehicle: {
							SAOI::FindVehicle(sd);
						}
						case e_gangzone: {
							SAOI::FindGangZone(playerid,findr,sd);
						}
					#endif
					case e_removebuilding: {
						SAOI::FindRemoveBuilding(sd);
					}
					default: {
						SendClientMessage(playerid,0xB01010FF,"This component need YSF Plugin.");
						return cmd_saoifinder(playerid);
					}
				}
				new buffer[256];
				format(buffer,sizeof(buffer),"%s description has been activated, coverage %.0fm",elements_name[elementid],sd);
				SendClientMessage(playerid,0xFFFFFFFF,buffer);
				SAOI::Finder[find_elements:elementid][o_active] = true;
				return cmd_saoifinder(playerid);
			}
		}
		
		case DIALOG_SAOI_DESTROY: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return 0;
			PlayerLastItem[playerid] = listitem;
			ShowPlayerDialog(playerid,DIALOG_SAOI_DESTROY_PARAMS,DIALOG_STYLE_INPUT,"{00FFFF}SAOI Element Destroy","Choose elementid.","{00FF00}Destroy","{FF0000}Return");
		}
		
		case DIALOG_SAOI_DESTROY_PARAMS: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return cmd_saoidestroy(playerid);
			new elementid = PlayerLastItem[playerid],
				itemid = strval(inputtext);
			
			if(itemid != INVALID_STREAMER_ID){
				switch(find_elements:elementid){
					case e_dynamic_object: {
						if(IsValidDynamicObject(itemid)){
							DestroyDynamicObject(itemid);
						} else {
							SendClientMessage(playerid,0xB01010FF,"Invalid itemid.");
							return OnDialogResponse(playerid,DIALOG_SAOI_DESTROY,1,PlayerLastItem[playerid],"");
						}
					}
					case e_dynamic_pickup: {
						if(IsValidDynamicPickup(itemid)){
							DestroyDynamicPickup(itemid);
						} else {
							SendClientMessage(playerid,0xB01010FF,"Invalid itemid.");
							return OnDialogResponse(playerid,DIALOG_SAOI_DESTROY,1,PlayerLastItem[playerid],"");
						}
					}
					case e_dynamic_cp: {
						if(IsValidDynamicCP(itemid)){
							DestroyDynamicCP(itemid);
						} else {
							SendClientMessage(playerid,0xB01010FF,"Invalid itemid.");
							return OnDialogResponse(playerid,DIALOG_SAOI_DESTROY,1,PlayerLastItem[playerid],"");
						}
					}
					case e_dynamic_racecp: {
						if(IsValidDynamicRaceCP(itemid)){
							DestroyDynamicRaceCP(itemid);
						} else {
							SendClientMessage(playerid,0xB01010FF,"Invalid itemid.");
							return OnDialogResponse(playerid,DIALOG_SAOI_DESTROY,1,PlayerLastItem[playerid],"");
						}
					}
					case e_dynamic_mapicon: {
						if(IsValidDynamicMapIcon(itemid)){
							DestroyDynamicMapIcon(itemid);
						} else {
							SendClientMessage(playerid,0xB01010FF,"Invalid itemid.");
							return OnDialogResponse(playerid,DIALOG_SAOI_DESTROY,1,PlayerLastItem[playerid],"");
						}
					}
					case e_dynamic_actor: {
						if(IsValidDynamicActor(itemid)){
							DestroyDynamicActor(itemid);
						} else {
							SendClientMessage(playerid,0xB01010FF,"Invalid itemid.");
							return OnDialogResponse(playerid,DIALOG_SAOI_DESTROY,1,PlayerLastItem[playerid],"");
						}
					}
					case e_actor: {
						if(IsValidActor(itemid)){
							DestroyActor(itemid);
						} else {
							SendClientMessage(playerid,0xB01010FF,"Invalid itemid.");
							return OnDialogResponse(playerid,DIALOG_SAOI_DESTROY,1,PlayerLastItem[playerid],"");
						}
					}
					case e_object: {
						if(IsValidObject(itemid)){
							DestroyObject(itemid);
						} else {
							SendClientMessage(playerid,0xB01010FF,"Invalid itemid.");
							return OnDialogResponse(playerid,DIALOG_SAOI_DESTROY,1,PlayerLastItem[playerid],"");
						}
					}
					case e_pickup: {
						DestroyPickup(itemid);
					}
					case e_vehicle: {
						if(IsValidVehicle(itemid)){
							DestroyVehicle(itemid);
						} else {
							SendClientMessage(playerid,0xB01010FF,"Invalid itemid.");
							return OnDialogResponse(playerid,DIALOG_SAOI_DESTROY,1,PlayerLastItem[playerid],"");
						}
					}
					case e_gangzone: {
						GangZoneDestroy(itemid);
					}
					default: {
						SendClientMessage(playerid,0xB01010FF,"Invalid element type.");
						return cmd_saoidestroy(playerid);
					}
				}
				new buffer[256];
				format(buffer,sizeof(buffer),"%s itemid %d has been destroyed.",elements_name[elementid],itemid);
				SendClientMessage(playerid,0xFFFFFFFF,buffer);
			} else {
				SendClientMessage(playerid,0xB01010FF,"Invalid itemid.");
				return OnDialogResponse(playerid,DIALOG_SAOI_DESTROY,1,PlayerLastItem[playerid],"");
			}
			return cmd_saoidestroy(playerid);
		}
		
		case DIALOG_SAOI_CFG: {
			if(!IsAdmin(playerid)) return 0;
			if(!response) return 0;
			switch(listitem){
				case 0: {
					SAOI::Config[save_log] =		(SAOI::Config[save_log]?false:true);
					SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:save_log),_:SAOI::Config[save_log]);
				}
				case 1: {
					SAOI::Config[global_msg] =		(SAOI::Config[global_msg]?false:true);
					SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:global_msg),_:SAOI::Config[global_msg]);
				}
				case 2: {
					SAOI::Config[auto_freeze] = 	(SAOI::Config[auto_freeze]?false:true);
					SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:auto_freeze),_:SAOI::Config[auto_freeze]);
				}
				case 3: {
					SAOI::Config[streamer_optimization] = (SAOI::Config[streamer_optimization]?false:true);
					SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:streamer_optimization),_:SAOI::Config[streamer_optimization]);
					if(SAOI::Config[streamer_optimization]) SAOI::LoadStreamerOptimization();
				}
				case 4: {
					SAOI::Config[streamer_reports] = (SAOI::Config[streamer_reports]?false:true);
					SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:streamer_reports),_:SAOI::Config[streamer_reports]);
					Streamer::ToggleErrorCallback(_:SAOI::Config[streamer_reports]);
				}
				case 5: {
					SAOI::Config[streamer_limits] = (SAOI::Config[streamer_limits]?false:true);
					SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:streamer_limits),_:SAOI::Config[streamer_limits]);
					if(SAOI::Config[streamer_limits]) SAOI::LoadStreamerLimits();
				}
				case 6: {
					#if defined SAOI_DEVELOPER_VERSION
						SAOI::Config[saoi_fast_boot] = (SAOI::Config[saoi_fast_boot]?false:true);
						SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:saoi_fast_boot),_:SAOI::Config[saoi_fast_boot]);
					#else
						SendClientMessage(playerid,0xB01010FF,"Unable to change this value!");
					#endif
				}
				case 7: {
					SAOI::Config[auto_clean] = (SAOI::Config[auto_clean]?false:true);
					SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:auto_clean),_:SAOI::Config[auto_clean]);
				}
			}
			return cmd_saoicfg(playerid);
		}
	}
	return 0;
}

stock SAOI::LoadManager(){
	printf(" ");
	printf("[SAOI] Load File Manager");
	
	new start_time = GetTickCount();
	
	//Create Boot Loader
	if(!fexist(SAOI_FILE_BOOT)){
		SAOI::CreateBootFile();
		if(!fexist(SAOI_FILE_BOOT)){
			printf("[SAOI DEBUG] Cannot create file: %s",SAOI_FILE_BOOT);
			SAOI::ErrorLevel++;
			return 0;
		} else {
			printf("[SAOI DEBUG] Create boot file: %s",SAOI_FILE_BOOT);
		}
	}
	
	//Copy old records
	if(fexist(SAOI_OLDFILE_LIST)){
		printf("[SAOI DEBUG] Move old records to new boot file.");
		new File:obj_list = fopen(SAOI_OLDFILE_LIST,io_read), line[128];
	
		if(!obj_list){
			printf("[SAOI DEBUG] Cannot open file: %s",SAOI_OLDFILE_LIST);
			SAOI::ErrorLevel++;
			return 0;
		}
		
		new fname[MAX_SAOI_NAME_SIZE], path[MAX_SAOI_PATH];
		while(fread(obj_list,line)){
			if(strlen(line) < 5) continue; //empty line
			sscanf(line,"s[64]",fname);
			format(path,sizeof(path),"/SAOI/%s",fname);
			if(path[strlen(path)-1] == '\n') path[strlen(path)-1] = EOS;
			if(path[strlen(path)-1] == '\r') path[strlen(path)-1] = EOS;
			SAOI::SetBoot(path,1);
		}
		fclose(obj_list);
		printf("[SAOI DEBUG] Remove: %s",SAOI_OLDFILE_LIST);
		fremove(SAOI_OLDFILE_LIST);
	}
	
	//Copy old config
	if(fexist(SAOI_OLDFILE_CFG)){
		printf("[SAOI DEBUG] Move old config to new boot file.");
		new buffer[256];
		new File:inpf = fopen(SAOI_OLDFILE_CFG,io_read);
		fread(inpf,buffer);
		sscanf(buffer,"p<:>D(1)D(1)D(1)",SAOI::Config[global_msg],SAOI::Config[save_log],SAOI::Config[auto_freeze]);
		fclose(inpf);
		
		SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:global_msg),_:SAOI::Config[global_msg]);
		SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:save_log),_:SAOI::Config[save_log]);
		SWAP::write_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:auto_freeze),_:SAOI::Config[auto_freeze]);
		
		printf("[SAOI DEBUG] Remove: %s",SAOI_OLDFILE_CFG);
		fremove(SAOI_OLDFILE_CFG);
	}
	
	//Resize Boot if need
	new boot_size = SAOI_BOOT_SIZE_HEADER + SAOI_BOOT_SIZE_CONFIG + (MAX_SAOI_FILE*SAOI_BOOT_SIZE_FILE),
		orm = 4096 - (boot_size % 4096),
		File:inpf = fopen(SAOI_FILE_BOOT,io_read),
		asize = flength(inpf);
	boot_size += orm;
	fclose(inpf);
	if(asize < boot_size){
		printf("[SAOI DEBUG] Resize Boot File: %s [%d B -> %d B] (+%d Bytes)",SAOI_FILE_BOOT,asize,boot_size,SAOI::BootResize(MAX_SAOI_FILE));
	}

	new saoi_boot[SAOI::GetConfigSize(MAX_SAOI_FILE)],
		path[MAX_SAOI_PATH],
		error_name[MAX_SAOI_ERROR_NAME],
		lcnt_t = 0, lcnt_f = 0, edi, bad_record = 0;
	
	printf("[SAOI] Load Config");
	SAOI::Config[global_msg] =				bool:SWAP::read_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:global_msg));
	SAOI::Config[save_log] =				bool:SWAP::read_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:save_log));
	SAOI::Config[auto_freeze] =				bool:SWAP::read_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:auto_freeze));
	SAOI::Config[streamer_optimization] =	bool:SWAP::read_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:streamer_optimization));
	SAOI::Config[streamer_reports] =		bool:SWAP::read_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:streamer_reports));
	SAOI::Config[streamer_limits] =			bool:SWAP::read_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:streamer_limits));
	SAOI::Config[saoi_fast_boot] =			bool:SWAP::read_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:saoi_fast_boot));
	SAOI::Config[auto_clean] =				bool:SWAP::read_byte(SAOI_FILE_BOOT,SAOI_CFG_KEY,(SAOI_BOOT_OFFSET_CONFIG+_:auto_clean));
	
	Streamer::ToggleErrorCallback(_:SAOI::Config[streamer_reports]);
	
	if(SAOI::Config[streamer_optimization])	SAOI::LoadStreamerOptimization();
	if(SAOI::Config[streamer_limits])		SAOI::LoadStreamerLimits();
	
	printf("[SAOI] Load Boot Manager");
	SWAP::read_array(SAOI_FILE_BOOT,SAOI_CFG_KEY,0,saoi_boot,sizeof(saoi_boot));
	printf(" ");
	for(new i = 0; i < MAX_SAOI_FILE-1; i++){
		if(SAOI::IsToggleConfigInformation(saoi_boot,i)){
			SWAP::read_string(SAOI_FILE_BOOT,SAOI_CFG_KEY,SAOI_BOOT_OFFSET_FILES+(i*SAOI_BOOT_SIZE_FILE),path,SAOI_BOOT_SIZE_FILE);
			if(isnull(path) || !(path[1] == 'S' && path[2] == 'A' && path[3] == 'O' && path[4] == 'I')){
				printf("[SAOI DEBUG] Remove bad boot record: ID:%d",i);
				SAOI::ToggleConfigInformation(saoi_boot,i,0);
				bad_record++;
				SAOI::ErrorLevel++;
			} else {
				edi = SAOI::LoadObjectImage(path,SAOI::Config[save_log],fm_fast_boot);
				if(edi > 0 || edi == SAOI_ERROR_IS_LOADED){
					lcnt_t++;
				} else {
					SAOI::GetErrorName(edi,error_name);
					printf("[SAOI DEBUG] %s: %s",path,error_name);
					lcnt_f++;
					SAOI::ErrorLevel++;
					if(edi == SAOI_ERROR_INPUT_NOT_EXIST && SAOI::Config[auto_clean]){
						SAOI::SetBoot(path,0);
						printf("[SAOI DEBUG] Remove bad boot record: '%s'",path);
					}
				}
			}
		}
	}
	
	if(bad_record){
		printf("[SAOI DEBUG] Fixed %d boot record errors",bad_record);
		SWAP::write_array(SAOI_FILE_BOOT,SAOI_CFG_KEY,0,saoi_boot,sizeof(saoi_boot));
	}
	
	new stop_time = GetTickCount();
	if((lcnt_t+lcnt_f) > 0){
		printf("[SAOI] Total loaded files %d/%d in %d ms",lcnt_t,(lcnt_t+lcnt_f),stop_time-start_time);
		printf("[SAOI] Total loaded items %d",SAOI::CountAllElements());
		if(lcnt_f > 0){
			printf("[SAOI] Failed to load %d files",lcnt_f);
		}
	}
	fm_fast_boot = SAOI::Config[saoi_fast_boot];
	printf(" ");
	return 1;
}

SAOI::Public:: SAOI::OnRequestResponse(index, response_code, data[]){
	if(response_code == 200){
		if(isnull(data)) return 0;
		new saoi_version[16], saoi_ver, saoi_file_ver = SAOI_LOADER_VERSION;
		strmid(saoi_version,data,0,strlen(data));
		saoi_ver = strval(saoi_version);
		if(saoi_ver != saoi_file_ver){
			print(" ");
			printf("[ADM] Info: Please update your SAOI to v%d.%d.%d from here:",(saoi_ver / 10000),((saoi_ver % 10000) / 100),((saoi_ver % 10000) % 100));
			print("https://github.com/AbyssMorgan/SAOI/releases");
			print(" ");
		}
	}
	return 1;
}

public Streamer::OnPluginError(const error[]){
	printf("[STREAMER] %s",error);
	return 1;
}

public OnFilterScriptExit(){
	printf(" ");
	printf("[SAOI] Unload SAOI File Manager");
	printf(" ");
	SAOI::Foreach(i){
		if(SAOI::IsLoaded(i)){
			SAOI::UnloadObjectImage(i);
		}
	}
	return 1;
}

public OnFilterScriptInit(){
	if(GetSVarInt("ADM:SAOI:VERCHECK") == 0){
		SetSVarInt("ADM:SAOI:VERCHECK",1);
		new saoi_send_data[50];
		format(saoi_send_data,sizeof(saoi_send_data),"8.ct8.pl/saoi/check.php?version=%d",SAOI_LOADER_VERSION);
		HTTP(2,HTTP_GET,saoi_send_data,"","SAOI_OnRequestResponse");
	}
	SAOI::LoadManager();
	return 1;
}

#pragma dynamic (64*1024)

//EOF