# San Andreas Object Image Loader.


###### What is that ? This is the script allows you to load binary objects file which have a dynamic structure.


## Support:
- CreateDynamicObject for all params
- Extra parameter: Streamer_ToggleItemAntiAreas, SetDynamicObjectNoCameraCol
- SetDynamicObjectMaterial for all materialindex
- SetDynamicObjectMaterialText for all materialindex
- Unique compressed file structure (Dynamic moving datagram)
- Encrypted information: Author, Version, Description
- Ability to load, unload the selected files
- Compression performance. Ratio ~33%
- Filtering ip/port server, if anyone needs


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
- /saoicmd - show saoi cmd
- /addobjinfo - adds descriptions of objects
- /delobjinfo - removes descriptions of objects
- /objstatus - show total object status
- /saoicapacity - shows the status of use of slots
- /saoiinfo - show saoi file information
- /saoiload - load saoi file
- /saoiunload - unload saoi file
- /saoireload - reload saoi file
- /saoilist - show loaded saoi files
- /streaminfo - show stream info
- /saoitp - teleport to saoi flag

## SAOI File Manager Video:
https://www.youtube.com/watch?v=bNXAT_MzQUI


## Fragment file:
![alt SAOI](http://i.imgur.com/AcoMhEM.png)


## SAOI Functions:
- SAOI:CreateSAOIFile(const name[],author[],version[],description[] = "");
- SAOI:GetSAOIFileHeader(const name[],author[],version[],description[]);
- SAOI:SaveDynamicObject(objectid,const name[]);
- SAOI:LoadObjectImage(const name[],&object_cnt=0,&material_cnt=0,&material_text_cnt=0,&load_time=0,bool:use_saoi_area=false);
- bool:UnloadObjectImage(&SAOI:index);
- bool:GetSAOILoadData(SAOI:index,name[],&object_cnt=0,&material_cnt=0,&material_text_cnt=0,&load_time=0,&active_tick=0);
- bool:IsSAOIFileLoaded(const name[],&SAOI:index=INVALID_SAOI_FILE);
- CountObjectsForIndex(SAOI:index);
- CountSAOIFileLoaded();
- GetSAOIActiveTime(SAOI:index);
- bool:IsSAOISlotFree(SAOI:index);
- GetSAOIFileSize(SAOI:index);
- bool:GetSAOIPositionFlag(SAOI:index,&Float:x,&Float:y,&Float:z,&Float:angle,&virtualworld,&interior);
- SAOI:SetSAOIPositionFlag(const name[],Float:x,Float:y,Float:z,Float:angle,virtualworld,interior);


## SAOI Extended Functions:
- SAOIToInt(SAOI:variable);
- SAOI:FindFreeSAOIID();
