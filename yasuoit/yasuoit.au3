#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=yasuo.ico
#AutoIt3Wrapper_Outfile=YasuoIT.exe
#AutoIt3Wrapper_Outfile_x64=YasuoIT_x64.exe
#AutoIt3Wrapper_Res_Description=Who picks Yasuo faster than me?
#AutoIt3Wrapper_Res_Fileversion=0.0.1.0
#AutoIt3Wrapper_Res_ProductName=Yasuo.exe
#AutoIt3Wrapper_Res_ProductVersion=0.0.1
#AutoIt3Wrapper_Res_CompanyName=YasuoIT Corporation
#AutoIt3Wrapper_Res_LegalCopyright=YasuoIT @ 2020
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;============================
; Name............: YasuoIT.au3
; Description.....: A simple script that supports auto queue and
;                   pick-lock your favorite champion quickly in
;                   normal game only (Summoner's Rift) and...
;                   helps you how to use LCU API in AutoIt.
; Repo............: https://github.com/nomi-san/yasuo/
; Contributors....: + meouwu
;===============================================================

#include <WinAPIProc.au3>               ; Get process path
#include "./includes/_HttpRequest.au3"  ; HTTP request (based on WinHTTP)
#include "./includes/Json.au3"          ; JSON parser (JSMN)

; Constants
local $sPort, $sPass;
local const $sHost = "https://127.0.0.1";
local const $sProc = "LeagueClientUx.exe";

; 0 [GET]   Get playable champions in inventory (all owneds and frees)
; 1 [GET]   Check for match found
; 2 [POST]  Accept the match
; 3 [GET]   Get picking session info
; 4 [POST]  Send selection actions
func getAPI($n)
    static $aAPIs[] = [ _
        "/lol-champions/v1/owned-champions-minimal",    _
        "/lol-matchmaking/v1/ready-check",              _
        "/lol-matchmaking/v1/ready-check/accept",       _
        "/lol-champ-select/v1/session",                 _
        "/lol-champ-select/v1/session/actions"          _
    ];
    return ($sHost & ':' & $sPort & $aAPIs[$n])
endFunc

; Check for Administrator permission
if (not IsAdmin()) then
    MsgBox(0, "YasuoIT", "Please reopen program as an Administrator!");
    Exit;
endIf

; Get LCU process ID
local $iPID = ProcessExists($sProc);

; Wait if it is not opended
if ($iPID == 0) then
    $iPID = ProcessWait($sProc);
    Sleep(5000); Wait for loading
endIf

; Get LCU path
local $sDir = StringTrimRight(_WinAPI_GetProcessFileName($iPID), StringLen($sProc));
; Read the lockfile and get port + password
local $sLockfile = FileReadLine($sDir & 'lockfile');
local $sTokens = StringSplit($sLockfile, ':', 2);
$sPort = $sTokens[2];
$sPass = $sTokens[3];

; Set auth
_HttpRequest_SetAuthorization("riot", $sPass);

local $iChampID = -1;
do  ; Ask user to get champion name
    local $sChampName = InputBox("Please enter your champion name", _
        "Note: many popular champions can be..."    & @CRLF & _
        "      j4  -> Jarvan IV"                    & @CRLF & _
        "      yi  -> Master Yi"                    & @CRLF & _
        "      ys  -> Yasuo"                        & @CRLF & _
        "      yum -> Yuumi"                        & @CRLF & _
        "Or press cancel to exit." _
    );
    if (@error) then exit;
    $iChampID = getChampID($sChampName);
    if ($iChampID == -2) then
        MsgBox(0, "YasuoIT", "Couldn't find this champion or you don't own it!");
    endIf
Until ($iChampID >= 0)

Sleep(1000);

; Auto accept when match found and do pick-lock
while (true)
    if (isInProgress()) then
        acceptMatch();
        $bAccepted = true;
    elseIf (isInSelection()) then
        pickLock($iChampID);
        MsgBox(0, "YasuoIT", "Enjoy your favorite champion!");
        ExitLoop
    endIf

    Sleep(250)
wEnd

; Is in match found? (waiting for accept)
func isInProgress()
    local $tmp = _HttpRequest(2, getAPI(1));
    local $json = Json_Decode($tmp);
    return Json_Get($json, '["state"]') == 'InProgress';
endFunc

; Accept match found
func acceptMatch()
    _HttpRequest(1, getAPI(2), '', '', '', '', 'POST');
endFunc

; Is in selection?
func isInSelection()
    return (getID(true) > -1);
endFunc

; Get your 'id' in match (your slot in game)
; Return -1 if not in picking.
func getID($isCell = false)
    local $json, $tmp;
    $tmp = _HttpRequest(2, getAPI(3));
    $json = Json_Decode($tmp);

    local $myCellId = Json_Get($json, '["localPlayerCellId"]');
    if (IsInt($myCellId) and $isCell) then return $myCellId;

    if (IsInt($myCellId) and $myCellId >= 0) then
        for $i = 0 to 9
            if (Json_Get($json, '["actions"][0][' & String($i) & ']["actorCellId"]') _
                == $myCellId) then
                return Json_Get($json, '["actions"][0][' & String($i) & ']["id"]');
            endIf
        next
    endIf

    return -1;
endFunc

; Pick and lock champion
func pickLock($iChampID)
    local $id = getID();
    local $sPickingAPI = (getAPI(4) & '/' & String($id));
    local $sLockingAPI = ($sPickingAPI & '/complete');
    _HttpRequest(1, $sPickingAPI, _
        '{"championId":' & String($iChampID) & '}', '', '',  '', 'PATCH');
    _HttpRequest(1, $sLockingAPI, '', '', '', '', 'POST');
endFunc

; Get champion ID
func getChampID($sChampName)
    local $json, $sRet, $tmp;
    ; Load champion data
    $sRet = _HttpRequest(2, getAPI(0));
    $json = Json_Decode($sRet);

    ; Why don't use a pre-loaded data?
    ; -> Cannot trigger the event: 'onUserBuysNewChamp'

    ; Count number of champion
    StringReplace($sRet, ".j", '.j'); Just '.jpg'
    local $iNChamps = @extended;

    ; Fix name
    $sChampName = StringStripWS($sChampName, 8);
    $sChampName = StringLower($sChampName);
    $sChampName = decodeName($sChampName);

    for $i = 0 to ($iNChamps-1)
        $tmp = Json_Get($json, '[' & String($i) & ']["alias"]');
        $tmp = StringLower($tmp);
        if StringInStr($sChampName, $tmp) then
            $tmp = Json_Get($json, '[' & String($i) & ']["name"]');
            $tmp = MsgBox(4, 'Confirm', 'Did you mean "' & $tmp & '"?');
            if ($tmp == 7) then return -1; Re-enter
            return Int(Json_Get($json, '[' & String($i) & ']["id"]'));
        endIf
    next

    return -2; Don't own it
endFunc

; Decode popular champion names (just a few names)
func decodeName($sName)
    switch ($sName)
        case "aa"
            return "aatrox";
        case "fish"
            return "fizz";
        case "iv", "j4", "jav"
            return "jarvaniv";
        case "kama"
            return "karma";
        case "kenen"
            return "kennen";
        case "ilao"
            return "illaoi";
        case "lee"
            return "leesin";
        case "lx"
            return "lux";
        case "md"
            return "drmundo";
        case "moon"
            return "diana";
        case "moder"
            return "mordekaiser";
        case "neko"
            return "neeko";
        case "pig"
            return "sejuani";
        case "popi", "popy"
            return "poppy";
        case "sun"
            return "leona";
        case "susan", "dog"
            return "nasus";
        case "tam"
            return "tahmkench";
        case "tf"
            return "twistedfate";
        case "tw"
            return "twitch";
        case "vaybu"
            return "vayne";
        case "wk", "wukong"
            return "monkeyking";
        case "xz"
            return "xinzhao";
        case "yi"
            return "masteryi";
        case "ys"
            return "yasuo";
        case "yum", "cat", "meo", "meow"
            ; Why not Rengar or Nida? Is Yuumi cuteeest?
            return "yuumi";
    endSwitch

    return $sName;
endFunc
