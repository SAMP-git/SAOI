# San Andreas Object Image Loader.


###### What is that ? This is the script allows you to load binary objects file which have a dynamic structure.


## Technical Data:
- Unique compressed file structure (Dynamic moving datagram)
- Encrypted information: Author, Version, Description
- Ability to load, unload the selected files
- Compression performance. Ratio ~33%
- Filtering ip/port server, if anyone needs

## Supported Functions:
- CreateDynamicObject
- SetDynamicObjectMaterial
- SetDynamicObjectMaterialText
- SetDynamicObjectNoCameraCol
- CreateDynamicPickup
- CreateDynamicMapIcon
- CreateDynamicCircle
- CreateDynamicCylinder
- CreateDynamicSphere
- CreateDynamicRectangle
- CreateDynamicCube
- CreateDynamicPolygon
- Streamer_ToggleItemAntiAreas
- RemoveBuildingForPlayer
- CreateVehicle
- LinkVehicleToInterior
- SetVehicleVirtualWorld
- Position Flag
- Creation Date

## How to use SAOI:
- Download and extract SAOI Generator (Windows).zip
- Place the objects in a text file that contains the code of objects in pawn.

##### Example:
```
//do not create callbacks OnFilterScriptInit!
new tmpobj = CreateDynamicObject(10755,-124.5100000,125.7300000,261.8080100,0.0000000,0.0000000,89.9990000,-1,-1,-1,800.0,800.0);
SetDynamicObjectMaterial(tmpobj,0,10817,"airportgnd_sfse","black64",0x00000000);
SetDynamicObjectMaterial(tmpobj,1,10817,"airportgnd_sfse","black64",0x00000000);
SetDynamicObjectMaterial(tmpobj,2,10817,"airportgnd_sfse","black64",0x00000000);
SetDynamicObjectMaterial(tmpobj,3,10817,"airportgnd_sfse","black64",0x00000000);

//additional
SetSAOIPositionFlag(MY_SAOI_FILE,1025.1938,1356.8513,10.8377,183.2121,0,0);

SetSAOIBumperIP(MY_SAOI_FILE,"127.0.0.1");
SetSAOIBumperPort(MY_SAOI_FILE,7777);

//example for RemoveBuildingForPlayer
//LV-LOT Old Gate
RemoveBuildingForPlayer(playerid,8311,1277.0,1206.8,12.9,1.0);
RemoveBuildingForPlayer(playerid,8312,1277.0,1206.8,12.9,1.0);

//example for area
new tmp_area = CreateDynamicCircle(911.87738,-671.97540,150.0);
CreateDynamicObject(869,911.87738,-671.97540,115.60636,-12.96000,-38.52000,0.00000,0,0,.areaid=tmp_area);
```

- Place the file in the folder "pawn_code"
- Run saoi.cmd
- Enter the full name of the file (example: file.txt)
- Enter data: Author (max 32 character), Version (max 32 character), Description (max 128 character)
- Submit and wait until the converter will create a file .saoi
- Use function LoadObjectImage to load the saoi file or use SAOI_FileManager.pwn


## How to install SAOI_FileManager
- Create folder scriptfiles\SAOI
- Create file scriptfiles\SAOI\SaoiFiles.txt
- Place the file name is in the file SaoiFiles.txt

##### Example:
```
text.saoi
myobject.saoi
```


## SAOI_FileManager Commands:
- /saoi - shows statistics saoi 
- /saoicmd - show saoi cmd
- /saoifinder - element finder
- /saoidestroy - destroy element
- /objstatus - show total object status
- /saoiinfo - show saoi file information
- /saoiload - load saoi file
- /saoiboot - load saoi file (Add to SAOIFiles.txt)
- /saoiunload - unload saoi file
- /saoireload - reload saoi file
- /saoilist - show loaded saoi files
- /streaminfo - show stream info
- /saoitp - teleport to saoi flag
- /tptoobj - teleport to object
- /objmaterial - get object materials
- /objmaterialtext - get object material text

## SAOI File Manager Video:
https://www.youtube.com/watch?v=bNXAT_MzQUI


## Fragment file:
![alt SAOI](http://i.imgur.com/AcoMhEM.png)


## SAOI Functions:
- SAOI:CreateSAOIFile(const name[],author[],version[],description[] = "");
- SAOI:GetSAOIFileHeader(const name[],author[],version[],description[]);
- SAOI:LoadObjectImage(const name[],bool:save_logs=true);
- bool:UnloadObjectImage(&SAOI:index);
- bool:IsSAOIFileLoaded(const name[],&SAOI:index=INVALID_SAOI_FILE);
- SAOI:SAOIHeaderCopy(const input[],const output[]);
- SAOI:SaveDynamicObject(objectid,const name[]);
- SAOI:SaveDynamicPickup(pickupid,const name[]);
- SAOI:SaveDynamicMapIcon(iconid,const name[]);
- SAOI:SaveDynamicArea(areaid,const name[]);
- SAOI:SetSAOIBumperIP(const name[],server_ip[]);
- SAOI:SetSAOIBumperPort(const name[],server_port);
- bool:GetSAOIPositionFlag(SAOI:index,&Float:x,&Float:y,&Float:z,&Float:angle,&virtualworld,&interior);
- SAOI:SetSAOIPositionFlag(const name[],Float:x,Float:y,Float:z,Float:angle,virtualworld,interior);
- SAOI:SaveRemoveBuilding(const name[],modelid,Float:x,Float:y,Float:z,Float:radius);
- SAOI:SAOI_SaveVehicle(const name[],vehicletype,Float:x,Float:y,Float:z,Float:rotation,color1,color2,respawn_delay,addsiren=0,worldid=0,interiorid=0);
- bool:SAOI_GetFileCreationDate(SAOI:index,output[],max_dest = sizeof(output));
- SAOI_CountDynamicObject(SAOI:index);
- SAOI_CountDynamicPickup(SAOI:index);
- SAOI_CountDynamicMapIcon(SAOI:index);
- SAOI_CountDynamicArea(SAOI:index);
- SAOI_CountVehicle(SAOI:index);
- SAOI_CountMaterial(SAOI:index);
- SAOI_CountMaterialText(SAOI:index);
- SAOI_CountRemoveBuilding(SAOI:index);
- SAOI_GetFileName(SAOI:index);
- SAOI_GetLoadTime(SAOI:index);
- SAOI_GetActiveTime(SAOI:index);
- SAOI_GetFileSize(SAOI:index);
- SAOI_CountFileLoaded();
- SAOI_CountAllElementsByIndex(SAOI:index);
- SAOI_CountAllElements();

## SAOI Extended Functions:
- SAOIToInt(SAOI:variable);
- SAOI:SAOI_GetFreeID();
- SAOI_IsLoaded(SAOI:index);
- SAOI_GetFreeRemoveBuildingID();
- SAOI_RemoveBuilding(SAOI:index,modelid,Float:x,Float:y,Float:z,Float:radius);
- SAOI_GetRemoveBuilding(remove_id,&SAOI:index,&modelid,&Float:x,&Float:y,&Float:z,&Float:radius);
- SAOI_DropRemoveBuildings(SAOI:index);
- SAOI_CleanupElements(SAOI:index);
- SAOI_RemoveBuildingsForPlayer(playerid);
- SAOI_UpdateBuildingsForPlayer(playerid,SAOI:index);
- SAOI_CountRemovedBuildings();
- SAOI_GetMemoryLoaded();


## SAOI Callbacks:
- SAOI_OnRemovedBuildings(playerid,buildings);
- SAOI_OnVehicleDestroyed(vehicleid);
- SAOI_OnVehicleCreated(vehicleid);