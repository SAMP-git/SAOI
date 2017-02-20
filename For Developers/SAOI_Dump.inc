/*
#include <a_samp>
#include <streamer>
#include <sscanf2>
#include <izcmd>
*/

#define LOCK_SAOI_MEMORY				"Texture Studio"
#include <SAOI>

//Check Version SAOI.inc
#if !defined _SAOI_LOADER
	#error You need SAOI.inc v1.6.1
#elseif !defined SAOI_LOADER_VERSION
	#error Update you SAOI.inc to v1.6.1
#elseif (SAOI_LOADER_VERSION < 10601)
	#error Update you SAOI.inc to v1.6.1
#endif

forward SAOI_Dump(saoi_file_name[]);

CMD:saoidump(playerid,params[]){
	new file_name[MAX_SAOI_NAME_SIZE];
	if(sscanf(params,"s[60]",file_name)) return SendClientMessage(playerid,0xFFFFFFFF,"Usage: /saoidump <file name>");
	
	new saoi_author[MAX_SAOI_AUTHOR_SIZE],
		saoi_version[MAX_SAOI_VERSION_SIZE],
		saoi_description[MAX_SAOI_DESCRIPTION_SIZE],
		SAOI:edi;
	
	//todo: Read author data from DB
	//saoi_author = ?
	//saoi_version = ?
	//saoi_description = ? (null is allowed)
	
	//Create SAOI File, remove if exist
	if(fexist(file_name)) fremove(file_name);
	if((edi = CreateSAOIFile(file_name,saoi_author,saoi_version,saoi_description)) != SAOI_ERROR_SUCCESS){
		new buffer[256];
		format(buffer,sizeof(buffer),"Cannot create SAOI File code: %d",SAOIToInt(edi));
		SendClientMessage(playerid,0xFFFFFFFF,buffer);
	}
	
	//Dump this session
	SAOI_Dump(file_name);
	SendClientMessage(playerid,0xFFFFFFFF,"Done.");
	return 1;
}

public SAOI_Dump(saoi_file_name[]){
	printf("[SAOI DUMP] Conversion Start");
	new saoi_count;
	
	saoi_count = 0;
	for(new i = 1, j = Streamer_GetUpperBound(STREAMER_TYPE_AREA); i <= j; i++){
		if(IsValidDynamicArea(i)){
			SaveDynamicArea(i,saoi_file_name);
			saoi_count++;
		}
	}
	printf("[SAOI DUMP] Areas converted: %d",saoi_count);

	saoi_count = 0;
	for(new i = 1, j = Streamer_GetUpperBound(STREAMER_TYPE_OBJECT); i <= j; i++){
		if(IsValidDynamicObject(i)){
			SaveDynamicObject(i,saoi_file_name);
			saoi_count++;
		}
	}
	printf("[SAOI DUMP] Objects converted: %d",saoi_count);
	
	saoi_count = 0;
	for(new i = 1, j = Streamer_GetUpperBound(STREAMER_TYPE_PICKUP); i <= j; i++){
		if(IsValidDynamicPickup(i)){
			SaveDynamicPickup(i,saoi_file_name);
			saoi_count++;
		}
	}
	printf("[SAOI DUMP] Pickups converted: %d",saoi_count);
	
	saoi_count = 0;
	for(new i = 1, j = Streamer_GetUpperBound(STREAMER_TYPE_MAP_ICON); i <= j; i++){
		if(IsValidDynamicMapIcon(i)){
			SaveDynamicMapIcon(i,saoi_file_name);
			saoi_count++;
		}
	}
	printf("[SAOI DUMP] MapIcons converted: %d",saoi_count);
	
	//todo edit this
	saoi_count = 0;
	for(new i = 1, j = GetVehiclePoolSize(); i <= j; i++){
		if(IsValidVehicle(i)){
			SAOI_SaveVehicle(saoi_file_name,Vehicles[i][Model],Vehicles[i][X],Vehicles[i][Y],Vehicles[i][Z],Vehicles[i][A],Vehicles[i][Color1],Vehicles[i][Color2],Vehicles[i][Respawn],Vehicles[i][Siren],Vehicles[i][VW],Vehicles[i][INT]);
			saoi_count++;
		}
	}
	printf("[SAOI DUMP] Vehicles converted: %d",saoi_count);
	
	printf("[SAOI DUMP] Conversion End");
	return 1;
}