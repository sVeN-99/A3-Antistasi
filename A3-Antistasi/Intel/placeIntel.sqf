params["_markerX", "_intelType"];

diag_log "Antistasi: Starting placement of intel";

//Catch invalid cases
if(isNil "_markerX") exitWith {diag_log "IntelPlacement: No marker given for intel placement!";};
if(!(_markerX  in airportsX || {_markerX in outposts})) exitWith {diag_log "IntelPlacement: Marker position not suited for intel!";};
if(_intelType != "Medium" && _intelType != "Big") exitWith {diag_log format ["IntelPlacement: Inteltype not accepted, expected 'Medium' or 'Big', got %1", _intelType];};

//Search for building to place intel in
_size = markerSize _markerX;
_maxSize = (_size select 0) max (_size select 1);
_maxSize *= 2;

_allBuildings = nearestObjects [(getMarkerPos _markerX),["House"], _maxSize, true];

if(count _allBuildings == 0) exitWith {diag_log "IntelPlacement: No buildings found around marker!"};

_index = -1;
_index = _allBuildings findIf {(typeOf _x) in (intelBuidings select 0)};
_isTower = true;
if(_index == -1) then
{
  _index = _allBuildings findIf {(typeOf _x) in (intelBuidings select 1)};
  _isTower = false;
};

if(_index == -1) exitWith {diag_log "IntelPlacement: No suitable buildings found to place intel in!"};
_building = _allBuildings select _index;

//Placing the intel
_relValues = nil;
if(_isTower) then
{
    _relValues = (intelDeskOffset select 0);
}
else
{
    _relValues = (intelDeskOffset select 1);
};

_desk = "Land_CampingTable_F" createVehicle (getPos _building);
_desk setDir (getDir _building + (_relValues select 1));
_desk setPosWorld ((getPosWorld _building) vectorAdd (_relValues select 0));

//Desk placed, now place intel on top

_intelName = "";
if(_intelType == "Medium") then {_intelName = "Land_Document_01_F"; _relValues = (intelOffset select 1);};
if(_intelType == "Big") then {_intelName = "Land_Laptop_02_unfolded_F"; _relValues = (intelOffset select 0);};

_intel = _intelName createVehicle (getPos _desk);
_intel enableSimulation false;

//Getting the offset right (or not, there is a bug somewhere)
_offsetVector = _relValues select 0;
_offsetVector = [_offsetVector, (getDir _desk)] call BIS_fnc_rotateVector2D;

_intel setDir (getDir _desk + (_relValues select 1));
_intel setPosWorld ((getPosWorld _desk) vectorAdd _offsetVector);


if(_intelType == "Medium") then
{
  _intel addAction ["Take Intel", {[true, _intelType, false] execVM retrieveIntel.sqf;},nil,4,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4];
};
if(_intelType == "Big") then
{
  _isTrap = (random 100 < (2 * tierWar));
  if(_isTrap) then {diag_log "IntelPlacement: Set up a little surprise for the players!"};
  _intel addAction ["Download Intel", {[!_isTrap, _intelType, _isTrap] execVM retrieveIntel.sqf;},nil,4,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull])",4];
};

[_markerX, _desk, _intel] spawn
{
  waitUntil{sleep 10; (spawner getVariable (_this select 0) == 2)};
  deleteVehicle (_this select 1);
  if(!isNil {_this select 2}) then {deleteVehicle (_this select 2)};
}
