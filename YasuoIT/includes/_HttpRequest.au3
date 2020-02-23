;Thanks [@ProAndy, Trancexx, Firefox - WinHttp UDF] autoitscript.com

#pragma compile(AutoItExecuteAllowed, True)
#Au3Stripper_Ignore_Funcs=_JS_Execute, _HttpRequest_BypassCloudflare, _HTMLEncode, __HTML_RegexpReplace, __IE_Init_GoogleBox, _Data2SendEncode

#include-once
#include <Array.au3>
#include <Crypt.au3>
#include <GDIPlus.au3>
#include <WinAPI.au3>

DllCall('kernel32.dll', 'dword', 'SetThreadExecutionState', 'dword', 0x80000043) ; $ES_AWAYMODE_REQUIRED + $ES_CONTINUOUS + $ES_DISPLAY_REQUIRED + $ES_SYSTEM_REQUIRED

Opt("TrayAutoPause", 0)
Global $g___ConsoleForceUTF8 = False
Global $g___ConsoleForceANSI = False
;-----------------------------------------------------------------------------------
Global $dll_WinHttp = DllOpen('winhttp.dll')
Global $dll_User32 = DllOpen('user32.dll')
Global $dll_Kernel32 = DllOpen('kernel32.dll')
Global $dll_Gdi32, $dll_WinInet
;-----------------------------------------------------------------------------------
Global $g___oError = ObjEvent("AutoIt.Error", "__ObjectErrDetect"), $g___oErrorStop = 0
;-----------------------------------------------------------------------------------
Global $g___ChromeVersion = FileGetVersion(@ProgramFilesDir & ' (x86)\Google\Chrome\Application\chrome.exe')
If @error Then $g___ChromeVersion = FileGetVersion(@ProgramFilesDir & '\Google\Chrome\Application\chrome.exe')
If @error Then $g___ChromeVersion = FileGetVersion(@UserProfileDir & '\AppData\Local\Google\Chrome\Application\chrome.exe')
If @error Or $g___ChromeVersion = '' Or $g___ChromeVersion = '0.0.0.0' Then $g___ChromeVersion = '70.0.3538.102'
;------------------------------------------------------------------------------------
Global Const $g___HRVersion = 1406
Global Const $g___UAHeader = 'Mozilla/5.0 (Windows NT ' & StringRegExpReplace(FileGetVersion('kernel32.dll'), '^(\d+\.\d+)(.*)$', '$1', 1) & ((StringInStr(@OSArch, '64') And Not @AutoItX64) ? '; WOW64' : ((StringInStr(@OSArch, '64') And @AutoItX64) ? '; Win64; x64' : '')) & ') '
Global Const $g___defUserAgent = $g___UAHeader & '_HttpRequest/' & $g___HRVersion & ' (WinHTTP/5.1) like Gecko'
Global Const $g___defUserAgentW = $g___UAHeader & 'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/' & $g___ChromeVersion & ' Safari/537.36'
Global Const $g___defUserAgentA = 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5 Build/MRA58N) AppleWebKit/537.36(KHTML, like Gecko) Chrome/61.0.3116.0 Mobile Safari/537.36'
Global Const $g___defUserAgentAO = 'Mozilla/5.0 (Linux; U; Android 4.2.2; en-us; SM-T217S Build/JDQ39) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Safari/534.30' ;Samsung Galaxy Tab3 7.0
Global Const $g___defUserAgentGB = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
Global Const $g___defUserAgentIP = 'Mozilla/5.0 (iPhone; CPU iPhone OS 12_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1'
Global Const $g___defUserAgentGG = 'Lynx/2.9.8dev.3 libwww-FM/2.14 SSL-MM/1.5.1'
;-----------------------------------------------------------------------------------------
Global $g___oJSON_Init, $g___oJSON_Obj
;-----------------------------------------------------------------------------------------
Global $g___MaxSession_TT = 110, $g___MaxSession_USE = 106, $g___LastSession = 0
Global $g___sBaseURL[$g___MaxSession_TT], $g___UserAgent[$g___MaxSession_TT]
Global $g___retData[$g___MaxSession_TT][2]
Global $g___ftpOpen[$g___MaxSession_TT], $g___ftpConnect[$g___MaxSession_TT]
Global $g___hOpen[$g___MaxSession_TT], $g___hConnect[$g___MaxSession_TT], $g___hRequest[$g___MaxSession_TT], $g___hWebSocket[$g___MaxSession_TT]
Global $g___oWinHTTP[$g___MaxSession_TT]
Global $g___hProxy[$g___MaxSession_TT][5] ;Proxy|ProxyBk|ProxyBypass|ProxyUserName|ProxyPassword
Global $g___hCredential[$g___MaxSession_TT][2] ;Username|Password
;------------------------------------------------------------------------------------
Global $g___hCookie[$g___MaxSession_TT], $g___hCookieLast = '', $g___hCookieDomain = '', $g___hCookieRemember = False
;------------------------------------------------------------------------------------
Global $g___CookieJarPath = ''
Global $g___CookieJarINI = ObjCreate("Scripting.Dictionary")
$g___CookieJarINI.CompareMode = 1
;------------------------------------------------------------------------------------
Global Const $def___sChr64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
Global Const $def___aChr64 = StringSplit($def___sChr64, "", 2)
Global Const $def___sPadding = '='
Global $g___sChr64 = $def___sChr64
Global $g___aChr64 = $def___aChr64
Global $g___sPadding = $def___sPadding
;------------------------------------------------------------------------------------
Global $g___hWinHttp_StatusCallback, $g___pWinHttp_StatusCallback, $g___hWinInet_StatusCallback, $g___pWinInet_StatusCallback
;-----------------------------------------------------------------------------------------
Global $g___JsLibGunzip = '', $g___jQueryLib = '', $g___aMemJsonParse[4]
;-----------------------------------------------------------------------------------------
Global $g___hSciTEOutput = ControlGetHandle('[CLASS:SciTEWindow]', '', '[CLASS:Scintilla; INSTANCE:2]')
Global $g___aReadWriteData = [['char', 'byte'], [StringMid, BinaryMid], [StringLen, BinaryLen]]
Global $g___HttpRequestReg = 'HKCU\Software\AutoIt v3\HttpRequest\'
Global $g___oDicEntity, $g___oDicHiddenSearch
Global $g___OnlineCompilerTimer = TimerInit()
Global $g___swCancelReadWrite = True
Global $g___swModeObject = False
Global $g___BytesPerLoop = 8192
Global $g___ErrorNotify = True
Global $g___LocationRedirect = ''
Global $g___CheckConnect = ''
Global $g___aVietPattern = ''
Global $g___sData2Send = ''
Global $g___OldConsole = ''
Global $g___iReadMode = 0
Global $g___HotkeySet = ''
Global $g___Boundary = ''
Global $g___ServerIP = ''
Global $g___TimeOut = ''
Global $g___aChrEnt = ''
Global $g___revURL = ''
Global $g___iAsync = 0
Global $g___oIDM
;-----------------------------------------------------------------------------------------
OnAutoItExitRegister('_HttpRequest_CloseAll')
__HttpRequest_CheckUpdate($g___HRVersion)
__HttpRequest_CancelReadWrite()
;__SciTE_ConsoleWrite_FixFont()
;__SciTE_ConsoleClear()
ConsoleWrite(@CRLF)


Func _HttpRequest_SwitchModeObj($iMode)
	Local $bkMode = $g___swModeObject
	$g___swModeObject = $iMode
	Return $bkMode
EndFunc

Func _HttpRequest_ConsoleOption($UTF8_or_ANSI = 1, $ConsoleForceUTF8 = False) ;0=UTF8, 1 = ANSI
	$g___ConsoleForceANSI = $UTF8_or_ANSI
	$g___ConsoleForceUTF8 = $ConsoleForceUTF8
EndFunc


Func HttpRequest($sURL, $sData2Send = '', $sAdditional_Headers = '', $sCookie = '')
	Local $aURL = StringRegExp($sURL, '(?im)^\h*?' & _
			'(?:-?(H|T|B)\h+)?\h*?' & _
			'(?:-?(GET|POST|PUT|OPTIONS|HEAD|DELETE|CONNECT|TRACE|PATCH)\h+)?\h*?' & _
			'(http.+)$', 3)
	If @error Then Return SetError(1, __HttpRequest_ErrNotify('HttpRequest', 'Không parse được $sURL', -1), '')
	Local $vRet = _HttpRequest($aURL[0] ? ($aURL[0] = 'T' ? 2 : 3) : 0, $aURL[2], $sData2Send, $sCookie, '', $sAdditional_Headers, $aURL[1])
	Return SetError(@error, @extended, $vRet)
EndFunc


Func _HttpRequest($iReturn, $sURL = '', $sData2Send = '', $sCookie = '', $sReferer = '', $sAdditional_Headers = '', $sMethod = '', $CallBackFunc_Progress = '')
	If StringRegExp($iReturn, '(?i)^\h*?curl\h+') Then
		Local $vData = _HttpRequest_ParseCURL($iReturn)
		Return SetError(@error, @extended, $vData)
	ElseIf $g___swModeObject Then
		Local $vRet = _oHttpRequest($iReturn, $sURL, $sData2Send, $sCookie, $sReferer, $sAdditional_Headers, $sMethod)
		Return SetError(@error, @extended, $vRet)
	EndIf
	;-------------------------------------------------
	Local $aRetMode = __HttpRequest_iReturnSplit($iReturn)
	If @error Then Return SetError(2, -1, '')
	$g___LastSession = $aRetMode[8]
	;-------------------------------------------------
	If StringRegExp($sURL, '^\h*?/\w?') And $g___sBaseURL[$g___LastSession] Then $sURL = $g___sBaseURL[$g___LastSession] & $sURL
	;-------------------------------------------------
	Local $aURL = __HttpRequest_URLSplit($sURL)
	If @error Then Return SetError(1, -1, '')
	;-------------------------------------------------
	Local $vContentType = '', $vAcceptType = '', $vUserAgent = '', $vBoundary = '', $vConnectReset = 0, $vUpload = 0, $vWebsocket = 0
	Local $sServerUserName = '', $sServerPassword = '', $sProxyUserName = '', $sProxyPassword = ''
	$g___LocationRedirect = ''
	$g___sData2Send = ''
	$g___retData[$g___LastSession][0] = ''
	$g___retData[$g___LastSession][1] = Binary('')
	;-------------------------------------------------
	If $aURL[0] = 3 Then
		Local $vRet = _FtpRequest($aRetMode, $aURL, $sData2Send, $CallBackFunc_Progress)
		Return SetError(@error, @extended, $vRet)
	EndIf
	;-------------------------------------------------
	If $g___hRequest[$g___LastSession] Then $g___hRequest[$g___LastSession] = _WinHttpCloseHandle2($g___hRequest[$g___LastSession])
	If $g___hWebSocket[$g___LastSession] Then $g___hWebSocket[$g___LastSession] = _WinHttpWebSocketClose2($g___hWebSocket[$g___LastSession])
	;-------------------------------------------------
	If Not $g___hOpen[$g___LastSession] Then
		If $g___hConnect[$g___LastSession] Then $g___hConnect[$g___LastSession] = _WinHttpCloseHandle2($g___hConnect[$g___LastSession])
		$g___hOpen[$g___LastSession] = _WinHttpOpen2()
		_WinHttpSetOption2($g___hOpen[$g___LastSession], 84, 0xA80)     ;OPTION_SECURE_PROTOCOLS = 0xA80 (TSL), 0xA8 (SSL + TSL1.0), 0xA00 (TSL1_1 + TSL1_2)
		_WinHttpSetOption2($g___hOpen[$g___LastSession], 88, 2)     ;OPTION_REDIRECT_POLICY = REDIRECT_POLICY_ALWAYS
		_WinHttpSetOption2($g___hOpen[$g___LastSession], 111, 1)  ;OPTION_ASSURED_NON_BLOCKING_CALLBACKS
		If $aRetMode[17] Then _WinHttpSetOption2($g___hOpen[$g___LastSession], 118, 3)  ;OPTION_DECOMPRESSION = DECOMPRESSION_FLAG_ALL
		;_WinHttpSetOption2($g___hOpen[$g___LastSession], 4, 20) ;OPTION_CONNECT_RETRIES
		;_WinHttpSetOption2($g___hOpen[$g___LastSession], 89, 20) ;OPTION_MAX_HTTP_AUTOMATIC_REDIRECTS
		;_WinHttpSetOption2($g___hOpen[$g___LastSession], 91, 128 * 1024) ;OPTION_MAX_RESPONSE_HEADER_SIZE. Default: 64Kb
		;_WinHttpSetOption2($g___hOpen[$g___LastSession], 92, 2 * 1024^2) ;OPTION_MAX_RESPONSE_DRAIN_SIZE. Default = 1Mb
		;_WinHttpSetOption2($g___hOpen[$g___LastSession], 79, 2) ;OPTION_ENABLE_FEATURE = ENABLE_SSL_REVERT_IMPERSONATION
		;_WinHttpSetOption2($g___hOpen[$g___LastSession], 133, 1) ;OPTION_ENABLE_HTTP_PROTOCOL = FLAG_HTTP2 (Supported on Windows10 version 1607 and newer)
		$vConnectReset = 1
	EndIf
	;----------------------------------------------------
	If $vConnectReset = 1 Or $g___CheckConnect <> $g___LastSession & $aURL[2] & $aURL[1] Then
		$vConnectReset = 0
		$g___CheckConnect = $g___LastSession & $aURL[2] & $aURL[1]
		If $g___hConnect[$g___LastSession] Then $g___hConnect[$g___LastSession] = _WinHttpCloseHandle2($g___hConnect[$g___LastSession])
		$g___hConnect[$g___LastSession] = _WinHttpConnect2($g___hOpen[$g___LastSession], $aURL[2], $aURL[1])
	EndIf
	;-------------------------------------------------
	If IsArray($sData2Send) Then $sData2Send = _HttpRequest_DataFormCreate($sData2Send)
	;-------------------------------------------------
	If $aURL[8] Or $aRetMode[13] Then $vWebsocket = 1
	;-------------------------------------------------
	$sMethod = ($vWebsocket ? 'GET' : ($sMethod ? $sMethod : ($sData2Send ? 'POST' : 'GET')))
	;-------------------------------------------------
	$g___hRequest[$g___LastSession] = _WinHttpOpenRequest2($g___hConnect[$g___LastSession], $sMethod, $aURL[3], ($aURL[0] - 1) * 0x800000)
	_WinHttpSetOption2($g___hRequest[$g___LastSession], 31, 0x3300)     ;OPTION_SECURITY_FLAGS = SECURITY_FLAG_IGNORE_ALL
	_WinHttpSetOption2($g___hRequest[$g___LastSession], 110, 1)     ;OPTION_UNSAFE_HEADER_PARSING
	;_WinHttpSetOption2($g___hRequest[$g___LastSession], 47, 0)     ;OPTION_CLIENT_CERT_CONTEXT= NO_CERT
	;_WinHttpSetOption2($g___hRequest[$g___LastSession], 79, 1) ;OPTION_ENABLE_FEATURE = ENABLE_SSL_REVOCATION
	;-----------------------------------------------------------
	If $g___TimeOut Then _WinHttpSetTimeouts2($g___hRequest[$g___LastSession], $g___TimeOut, $g___TimeOut, $g___TimeOut)
	;------------------------------------------------------------
	If $vWebsocket And _WinHttpSetOptionEx2($g___hRequest[$g___LastSession], 114, 0, True) = 0 Then     ;OPTION_UPGRADE_TO_WEB_SOCKET
		Return SetError(113, __HttpRequest_ErrNotify('_HttpRequest', 'WebSocket đã upgrade thất bại', -1), '')
	EndIf
	;------------------------------------------------------------
	If $aRetMode[3] Then _WinHttpSetOption2($g___hRequest[$g___LastSession], 63, 2)     ;WINHTTP_DISABLE_REDIRECTS
	;-------------------------------------------------------------------------------------------------------------------------------
	If $aRetMode[5] Then     ; Proxy cục bộ
		_WinHttpSetProxy2($g___hRequest[$g___LastSession], $aRetMode[5])
		$sProxyUserName = $aRetMode[6]
		$sProxyPassword = $aRetMode[7]
	ElseIf $g___hProxy[$g___LastSession][0] Then     ;  Proxy toàn cục
		_WinHttpSetProxy2($g___hRequest[$g___LastSession], $g___hProxy[$g___LastSession][0], $g___hProxy[$g___LastSession][2])
		$sProxyUserName = $g___hProxy[$g___LastSession][3]
		$sProxyPassword = $g___hProxy[$g___LastSession][4]
	EndIf
	If $sProxyUserName Then _WinHttpSetCredentials2($g___hRequest[$g___LastSession], $sProxyUserName, $sProxyPassword, 1, 1)
	;------------------------------------------------------------------------------------------------------------------------------
	If $aURL[4] Then     ;Set cục bộ - $aURL[4], $aURL[5] nghĩa là URL có kèm user/pass
		$sServerUserName = $aURL[4]
		$sServerPassword = $aURL[5]
	ElseIf $g___hCredential[$g___LastSession][0] Then     ;Set toàn cục
		$sServerUserName = $g___hCredential[$g___LastSession][0]
		$sServerPassword = $g___hCredential[$g___LastSession][1]
	EndIf
	If $sServerUserName Then _WinHttpSetCredentials2($g___hRequest[$g___LastSession], $sServerUserName, $sServerPassword, 0, 1)
	;----------------------------------------------------------------------------------------------------------------------------------------
	#cs
		- A typical WinHTTP application completes the following steps In order To handle authentication.
		• Request a resource With WinHttpOpenRequest And WinHttpSendRequest.
		• Check the response headers With WinHttpQueryHeaders.
		• If a 401 Or 407 status code is returned indicating that authentication is required, call WinHttpQueryAuthSchemes To find an acceptable scheme.
		• Set the authentication scheme, username, And password With WinHttpSetCredentials.
		• Resend the request With the same request handle by calling WinHttpSendRequest.
	
		- The credentials set by WinHttpSetCredentials are only used For one request.
		• WinHTTP does Not cache the credentials to use. In other requests, which means that applications must be written that can respond to multiple requests.
		• If an authenticated connection is re - used, other requests may Not be challenged, but your code should be able to respond to a request at any time.
	#ce
	;----------------------------------------------------------------------------------------------------------------------------------------
	If $sAdditional_Headers Then
		Local $aAddition = StringRegExp($sAdditional_Headers, '(?i)\h*?([\w\-]+)\h*:\h*(.*?)(?:\||$)', 3)
		$sAdditional_Headers = ''
		For $i = 0 To UBound($aAddition) - 1 Step 2
			Switch $aAddition[$i]
				Case 'Accept'
					$vAcceptType = $aAddition[$i + 1]
				Case 'Content-Type'
					$vContentType = $aAddition[$i] & ': ' & $aAddition[$i + 1]
				Case 'Referer'
					If Not $sReferer Then $sReferer = $aAddition[$i + 1]
				Case 'Cookie'
					If Not $sCookie Then $sCookie = $aAddition[$i + 1]
				Case 'User-Agent'
					$vUserAgent = $aAddition[$i + 1]
				Case Else
					$sAdditional_Headers &= $aAddition[$i] & ': ' & $aAddition[$i + 1] & @CRLF
			EndSwitch
		Next
	EndIf
	;-------------------------------------------------
	$sAdditional_Headers &= 'User-Agent: ' & ($vUserAgent ? $vUserAgent : ($g___UserAgent[$g___LastSession] ? $g___UserAgent[$g___LastSession] : $g___defUserAgent)) & @CRLF
	$sAdditional_Headers &= 'Accept: ' & ($vAcceptType ? $vAcceptType : '*/*') & @CRLF
	$sAdditional_Headers &= 'DNT: 1' & @CRLF
	;-------------------------------------------------
	If $aRetMode[15] And Not StringRegExp($sAdditional_Headers, '(?im)^\h*?X-Forwarded-For\h*?:') Then $sAdditional_Headers &= 'X-Forwarded-For: ' & _HttpRequest_GenarateIP() & @CRLF
;~ 		$sAdditional_Headers &= 'X-ProxyUser-Ip: ' & $sRandomIP
;~ 		$sAdditional_Headers &= 'X-Forwarded-IP: ' & $sRandomIP
;~ 		$sAdditional_Headers &= 'X-Originating-Ip: ' & $sRandomIP
;~ 		$sAdditional_Headers &= 'X-Remote-IP: ' & $sRandomIP
;~ 		$sAdditional_Headers &= 'X-Remote-Addr: ' & $sRandomIP
;~ 		$sAdditional_Headers &= 'X-Client-IP: ' & $sRandomIP
	;-------------------------------------------------
	If $sReferer Then $sAdditional_Headers &= 'Referer: ' & StringRegExpReplace($sReferer, '(?i)^\h*?Referer\h*?:\h*', '', 1) & @CRLF
	;-------------------------------------------------
	If $sCookie Then
		If $sMethod = 'POST' And StringInStr($aURL[3], 'login', 0, 1) Then __HttpRequest_ErrNotify('_HttpRequest', 'Nạp Cookie vào request liên quan đến Login có thể khiến request thất bại', '', 'Warning')
		If $sCookie == -1 Or $sCookie = 'CookieJar' Then
			If Not $g___CookieJarPath Then Return SetError(9, __HttpRequest_ErrNotify('_HttpRequest', 'CookieJar chưa được active. Vui lòng khởi tạo _HttpRequest_CookieJarSet', -1), '')
			$sCookie = _HttpRequest_CookieJarSearch($sURL)
		Else
			$sCookie = StringRegExpReplace($sCookie, '(?i)^\h*?Cookie\h*?:\h*', '', 1)
		EndIf
		If $g___hCookieRemember And($g___hCookieLast <> $sCookie Or $g___hCookieDomain <> $aURL[9]) Then
			__CookieGlobal_Insert($aURL[9], $sCookie)
			$g___hCookieDomain = $aURL[9]
			$g___hCookieLast = $sCookie
		EndIf
	EndIf
	If $g___hCookieRemember And $g___hCookie[$g___LastSession] Then $sCookie = __CookieGlobal_Search($sURL)
	If $sCookie Then $sAdditional_Headers &= 'Cookie: ' & $sCookie & @CRLF
	;----------------------------------------------------------------------------------------------------------------------------------------
	If $sData2Send Then
		If Not $g___Boundary Then
			If StringInStr($vContentType, 'multipart', 0, 1) Then
				$vBoundary = StringRegExp($vContentType, '(?i);\h*?boundary\h*?=\h*?([\w\-]+)', 1)
				If Not @error Then
					$g___Boundary = '--' & $vBoundary[0]
					If Not StringRegExp($sData2Send, '(?im)^' & $g___Boundary) Then
						Return SetError(22, __HttpRequest_ErrNotify('_HttpRequest', '$sData2Send có Boundary không khớp với khai báo ở header Content-Type', -1), '')
					ElseIf Not StringRegExp($sData2Send, '(?is)' & $g___Boundary & '--\R*?$') Then
						Return SetError(23, __HttpRequest_ErrNotify('_HttpRequest', 'Chuỗi Boundary ở cuối $sData2Send phải có -- ở cuối', -1), '')
					EndIf
				EndIf
			ElseIf StringRegExp($sData2Send, '(?m)^(-*?----WebKitFormBoundary\w+|-{20,}\d{10,})$') Then
				$g___Boundary = StringRegExp($sData2Send, '(?m)^(-*?----WebKitFormBoundary\w+|-{20,}\d{10,})$', 1)[0]
			EndIf
		EndIf
		;----------------------------------------------
		If $g___Boundary Then
			$vContentType = 'Content-Type: multipart/form-data; boundary=' & StringTrimLeft($g___Boundary, 2)
			$g___Boundary = ''
			$vUpload = 1
		Else
			If Not $vContentType Then
				If StringRegExp($sData2Send, '^\h*?[\{\[]') Then
					$vContentType = 'Content-Type: application/json'
				Else
					$vContentType = 'Content-Type: application/x-www-form-urlencoded'
					__Data2Send_CheckEncode($sData2Send)
				EndIf
			EndIf
			;If Not IsBinary($sData2Send) Then $sData2Send = StringToBinary($sData2Send, $aRetMode[11])
		EndIf
	EndIf
	;----------------------------------------------------------------------------------------------------------------------------------------
	$g___hWinHttp_StatusCallback = DllCallbackRegister("__HttpRequest_StatusCallback", "none", "handle;dword_ptr;dword;ptr;dword")
	_WinHttpSetStatusCallback2($g___hRequest[$g___LastSession], DllCallbackGetPtr($g___hWinHttp_StatusCallback), 0x00014002)
	;----------------------------------------------------------------------------------------------------------------------------------------
	If Not _WinHttpSendRequest2($g___hRequest[$g___LastSession], $sAdditional_Headers & $vContentType, $vWebsocket ? '' : $sData2Send, $vUpload, $CallBackFunc_Progress) Then
		If @error = 999 Then Return SetError(999, -1, '')
		Return SetError(4, __HttpRequest_ErrNotify('_HttpRequest', 'Gửi request thất bại', -1), '')
	EndIf
	;----------------------------------------------------------------------------------------------------------------------------------------
	If $aRetMode[14] Then Return True
	;----------------------------------------------------------------------------------------------------------------------------------------
	If Not _WinHttpReceiveResponse2($g___hRequest[$g___LastSession]) Then
		Local $ErrorCode = DllCall($dll_Kernel32, "dword", "GetLastError")[0]
		If $ErrorCode = 0 Then $ErrorCode = 12003
		Local $ErrorString = _WinHttpGetResponseErrorCode2($ErrorCode)
		Return SetError(5, __HttpRequest_ErrNotify('_HttpRequest', 'Không nhận được response từ Server. Mã lỗi: ' & $ErrorCode & ' (' & $ErrorString & ')', -1), '')
	EndIf
	;----------------------------------------------------------------------------------------------------------------------------------------
	$g___sData2Send = $sData2Send
	Local $vResponse_StatusCode = _WinHttpQueryHeaders2($g___hRequest[$g___LastSession], 19)
	Switch $vResponse_StatusCode
		Case 0     ;Nếu không nhận được Status Code
			Return SetError(6, -1, '')
			;--------------------------
		Case 403
			If $g___revURL And Not StringRegExp($sAdditional_Headers, '(?m)^Referr?er\h*?:') Then
				_HttpRequest_ConsoleWrite('!> Request thất bại với status 403' & @CRLF & '> Request sẽ tự động gởi lại với Referer là URL của request trước đó...' & @CRLF)
				If Not _WinHttpSendRequest2($g___hRequest[$g___LastSession], $sAdditional_Headers & 'Referer: ' & $g___revURL & @CRLF, $vWebsocket ? '' : $sData2Send, $vUpload, $CallBackFunc_Progress) Then Return SetError(4, __HttpRequest_ErrNotify('_HttpRequest', 'Gửi request thất bại #2', -1), '')
				_WinHttpReceiveResponse2($g___hRequest[$g___LastSession])
				$vResponse_StatusCode = _WinHttpQueryHeaders2($g___hRequest[$g___LastSession], 19)
				_HttpRequest_ConsoleWrite('> Quá trình request ' & ($vResponse_StatusCode > 400 ? 'vẫn thất bại sau khi tự động thực hiện lại' : 'đã thành công sau khi tự động gửi Referer') & @CRLF & @CRLF)
			EndIf
			;--------------------------
		Case 404     ; Nếu báo lỗi URL không tồn tại (HTTP_STATUS_NOT_FOUND)
			Local $aURLwithHashTag = StringRegExp($sURL, '(?m)(.*)(\#[\w\.\-]+)$', 3)
			If Not @error Then     ;Nếu tồn tại chỉ định mục con trong URL
				__HttpRequest_ErrNotify('_HttpRequest', 'Vui lòng bỏ chỉ định mục con (HashTag) ở đuôi URL ( ' & $aURLwithHashTag[1] & ' ) để tránh lãng phí thời gian Redirect', '', 'Warning')
				Local $sHeader = _WinHttpQueryHeaders2($g___hRequest[$g___LastSession], 22)
				Local $vReturn = _HttpRequest($iReturn, $aURLwithHashTag[0], $sData2Send, $sCookie, $sReferer, $sAdditional_Headers, $sMethod, $CallBackFunc_Progress)
				Local $aExtraInfo = [@error, @extended]
				$g___retData[$g___LastSession][0] = $sHeader & @CRLF & 'Redirect → [' & $aURLwithHashTag[0] & ']' & @CRLF & $g___retData[$g___LastSession][0]
				If $iReturn = 1 Then
					$vReturn = $g___retData[$g___LastSession][0]
				ElseIf $iReturn = 4 Or $iReturn = 5 Then
					$vReturn[0] = $g___retData[$g___LastSession][0]
				EndIf
				Return SetError($aExtraInfo[0], $aExtraInfo[1], $vReturn)
			EndIf
			;--------------------------
		Case 401, 407     ;Nếu request yêu cầu Auth (HTTP_STATUS_DENIED hoặc HTTP_STATUS_PROXY_AUTH_REQ)
			If ($vResponse_StatusCode = 401 And $sServerUserName = '') Then
				__HttpRequest_ErrNotify('_HttpRequest', $aURL[2] & ' yêu cầu phải có quyền truy cập')
			ElseIf ($vResponse_StatusCode = 407 And $sProxyUserName = '') Then
				__HttpRequest_ErrNotify('_HttpRequest', 'Proxy này yêu cầu quyền phải có truy cập')
			Else
				For $i = 1 To 3
					_HttpRequest_ConsoleWrite('> Đang tiến hành Authentication ... (' & $i & ')' & @CRLF)
					Local $aSchemes = _WinHttpQueryAuthSchemes2($g___hRequest[$g___LastSession])     ;Return AuthScheme, AuthTarget, SupportedSchemes
					If @error Then ContinueLoop (1 + 0 * __HttpRequest_ErrNotify('_WinHttpQueryAuthSchemes2', 'Không lấy được Authorization Schemes'))
					If $aSchemes[1] = 0 Then     ;AUTH_TARGET_SERVER
						_WinHttpSetCredentials2($g___hRequest[$g___LastSession], $sServerUserName, $sServerPassword, 0, $aSchemes[0])     ;https://airbrake.io/blog/http-errors/401-unauthorized-error
					Else     ;AUTH_TARGET_PROXY
						_WinHttpSetCredentials2($g___hRequest[$g___LastSession], $sProxyUserName, $sProxyPassword, 1, $aSchemes[0])     ;https://airbrake.io/blog/http-errors/407-proxy-authentication-required
					EndIf
					If @error Then ContinueLoop (1 + 0 * __HttpRequest_ErrNotify('_WinHttpSetCredentials2', 'Cài đặt Credentials thất bại'))
					_WinHttpSendRequest2($g___hRequest[$g___LastSession])
					_WinHttpReceiveResponse2($g___hRequest[$g___LastSession])
					$vResponse_StatusCode = _WinHttpQueryHeaders2($g___hRequest[$g___LastSession], 19)
					If $vResponse_StatusCode <> 401 And $vResponse_StatusCode <> 407 Then ExitLoop
				Next
				If $i = 4 Then __HttpRequest_ErrNotify('_HttpRequest', 'Quá trình Authentication thất bại')
			EndIf
		Case 445     ;REQUEST_CONFLICT
			Local $iTimerInit = TimerInit()
			Do
				If TimerDiff($iTimerInit) > 20000 Then ExitLoop
				Sleep(Random(100, 300, 1))
				_WinHttpSendRequest2($g___hRequest[$g___LastSession])
				_WinHttpReceiveResponse2($g___hRequest[$g___LastSession])
				$vResponse_StatusCode = _WinHttpQueryHeaders2($g___hRequest[$g___LastSession], 19)
			Until $vResponse_StatusCode <> 445
		Case 429     ;TOO_MANY_REQUEST
			Local $aTimeLimit = StringRegExp(_WinHttpQueryHeaders2($g___hRequest[$g___LastSession], 22), '(?i)Retry-After: (\d+)', 1)
			If Not @error Then __HttpRequest_ErrNotify('_HttpRequest', 'Thực hiện quá nhiều request. Vui lòng chờ ' & $aTimeLimit[0] & 's mới thực hiện request tiếp hoặc thay đổi Proxy')
	EndSwitch
	;--------------------------------------------------------
	$g___retData[$g___LastSession][0] &= __CookieJar_Insert($aURL[2], _WinHttpQueryHeaders2($g___hRequest[$g___LastSession], 22))
	;--------------------------------------------------------
	If $vWebsocket Then
		_WinHttpWebSocketRequest($sData2Send)
		If @error Then Return SetError(@error, $vResponse_StatusCode, $aRetMode[0] = 1 ? $g___retData[$g___LastSession][0] : False)
		Return SetError(0, $vResponse_StatusCode, $aRetMode[0] = 1 ? $g___retData[$g___LastSession][0] : True)
	EndIf
	;--------------------------------------------------------
	If $g___hWinHttp_StatusCallback Then $g___hWinHttp_StatusCallback = DllCallbackFree($g___hWinHttp_StatusCallback)
	$g___revURL = $sURL
	;--------------------------------------------------------
	Switch $aRetMode[0]
		Case 0, 1
			If $aRetMode[2] Then
				$sCookie = _GetCookie($g___retData[$g___LastSession][0])
				Return SetError(@error ? 7 : 0, $vResponse_StatusCode, $sCookie)
			Else
				Return SetError(0, $vResponse_StatusCode, $g___retData[$g___LastSession][0])
			EndIf
			;------------------------------------------
		Case 2 To 5
;~ 			_WinHttpQueryDataAvailable2($g___hRequest[$g___LastSession], $g___iAsync)
			;------------------------------------------
;~ 			If $aRetMode[0] = 2 Or $aRetMode[0] = 4 Then
;~ 				$vContentType = StringRegExp($g___retData[$g___LastSession][0], '(?im)^Content-Type: .+$', 3)
;~ 				If Not @error And StringRegExp($vContentType[UBound($vContentType) - 1], 'application|image|audio|video|octet-stream') Then $aRetMode[0] += 1
;~ 			EndIf
			;------------------------------------------
			If $aRetMode[9] Then     ;Ghi file: iReturn có dạng FilePath:Encoding. Khi $aRetMode[9] được set thì kiểu Data trả về sẽ tự động set về 3 (Binary) bất chấp đã điền kiểu Data trả về là gì
				_WinHttpReadData_Ex($g___hRequest[$g___LastSession], $CallBackFunc_Progress, $aRetMode[9], $aRetMode[10])
				Return SetError(@error, $vResponse_StatusCode, $g___retData[$g___LastSession][0])
			EndIf
			$g___retData[$g___LastSession][1] = _WinHttpReadData_Ex($g___hRequest[$g___LastSession], $CallBackFunc_Progress)
			If @error Then Return SetError(@error, $vResponse_StatusCode, '')
			;------------------------------------------
			If StringRegExp(BinaryMid($g___retData[$g___LastSession][1], 1, 1), '(?i)0x(1F|08|8B)') Then $g___retData[$g___LastSession][1] = __Gzip_Uncompress($g___retData[$g___LastSession][1])
			;------------------------------------------
			If $aRetMode[2] = 1 Or $aRetMode[0] = 3 Or $aRetMode[0] = 5 Then     ;$aRetMode[2] = 1: force Binary
				If $aRetMode[0] < 4 Then
					Return SetError(0, $vResponse_StatusCode, $g___retData[$g___LastSession][1])
				Else
					Local $aRet = [$g___retData[$g___LastSession][0], $g___retData[$g___LastSession][1]]
					Return SetError(0, $vResponse_StatusCode, $aRet)
				EndIf
			Else
				Local $sRet = $g___retData[$g___LastSession][1]
				$sRet = BinaryToString($sRet, $aRetMode[11])     ; $aRetMode[11] = 1: force ANSI, = 0 (Default): UTF8
				If $aRetMode[12] Then     ;force return Raw Text
					$sRet = _HTML_Execute($sRet)
				ElseIf $aRetMode[4] Then     ;trả về dạng đầy đủ của link relative trong HTML source
					$sRet = _HTML_AbsoluteURL($sRet, $aURL[7] & '://' & $aURL[2] & $aURL[3], '', $aURL[7])
				ElseIf $aRetMode[16] Then
					$sRet = _HTMLDecode($sRet)
				EndIf
				If $aRetMode[0] < 4 Then
					Return SetError(0, $vResponse_StatusCode, $sRet)
				Else
					Local $aRet = [$g___retData[$g___LastSession][0], $sRet]
					Return SetError(0, $vResponse_StatusCode, $aRet)
				EndIf
			EndIf
			;------------------------------------------
		Case 6
			Local $aIPAndGeo = _GetIPAndGeoInfo()
			Return SetError(@error ? 8 : 0, $vResponse_StatusCode, $aIPAndGeo)
			;------------------------------------------
		Case 7, 8, 9
			Exit MsgBox(4096, 'Thông báo', '$iReturn 7, 8, 9 đã bị loại bỏ, xin vui lòng sửa lại code')
	EndSwitch
EndFunc



#Region <Quản lý các Session của _HttpRequest>
	Func _HttpRequest_SessionSet($nSessionNumber)
		If $nSessionNumber = Default Then $nSessionNumber = 0
		If $nSessionNumber < 0 Or $nSessionNumber > $g___MaxSession_USE - 1 Then Exit MsgBox(4096, 'Lỗi', '$nSessionNumber chỉ có thể từ số từ 0 đến ' & $g___MaxSession_USE - 1)
		Local $nPreviousSession = $g___LastSession
		$g___LastSession = $nSessionNumber
		Return $nPreviousSession
	EndFunc

	Func _HttpRequest_SessionList()
		Local $aListSession[0], $iCounter = 0
		For $i = 0 To $g___MaxSession_USE - 1
			If $g___hOpen[$i] Then
				ReDim $aListSession[$iCounter + 1]
				$aListSession[$iCounter] = $i
				$iCounter += 1
			EndIf
		Next
		Return $aListSession
	EndFunc

	Func _HttpRequest_SessionClear($nSessionNumber = 0, $vClearProxy = False)
		If $nSessionNumber = Default Then $nSessionNumber = 0
		If $nSessionNumber < 0 Or $nSessionNumber > $g___MaxSession_USE - 1 Then Exit MsgBox(4096, 'Lỗi', '$nSessionNumber chỉ có thể từ số từ 0 đến ' & $g___MaxSession_USE - 1)
		$g___hCookieLast = ''
		$g___retData[$nSessionNumber][0] = ''
		$g___retData[$nSessionNumber][1] = Binary('')
		$g___hCookie[$nSessionNumber] = ''
		If $g___hOpen[$nSessionNumber] Then $g___hOpen[$nSessionNumber] = 0 * _WinHttpCloseHandle2($g___hOpen[$nSessionNumber])
		If $g___ftpOpen[$nSessionNumber] Then $g___ftpOpen[$nSessionNumber] = 0 * _FTP_CloseHandle2($g___ftpOpen[$nSessionNumber])
		If $vClearProxy Then _HttpRequest_SetProxy()
		If $g___CookieJarPath Then _HttpRequest_CookieJarUpdateToFile()
	EndFunc
#EndRegion




Func _HttpRequest_Test($sData, $FilePath = Default, $iEncoding = Default, $iShellExecute = True)
	If Not $sData Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_Test', 'Không thể ghi dữ liệu vì $sData là rỗng'), '')
	If Not $FilePath Or IsKeyword($FilePath) Then $FilePath = @TempDir & '\Test.html'
	If StringRegExp($FilePath, '(?i)\.html$') Then $sData = StringRegExpReplace($sData, "(?i)<script>\h*?if \(document\.location\.protocol \!=\h*?[""']https:?[""']\h*?\).*?</script>", '', 1)
	If $iEncoding = Default Then $iEncoding = 128
	If IsBinary($sData) Or (StringRegExp($sData, '(?i)^0x[[:xdigit:]]+$') And Mod(StringLen($sData), 2) = 0) Then
		$iEncoding = 16
	ElseIf StringRegExp(_HttpRequest_DetectMIME($FilePath), '(?i)^(audio|image|video)\/') Then
		Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_Test', 'Vui lòng dùng _HttpRequest ở mode $iReturn = -2 hoặc $iReturn = 3 để lấy dữ liệu dạng Binary mới ghi được loại tập tin này'))
	EndIf
	Local $l___hOpen = FileOpen($FilePath, 2 + 8 + $iEncoding)
	FileWrite($l___hOpen, $sData)
	FileClose($l___hOpen)
	If $iShellExecute Or $iShellExecute = Default Then ShellExecute($FilePath)
EndFunc


Func _HttpRequest_DataFormCreate($a_FormItems, $sFilenameDefault = Default)     ;thêm dấu $ để nhận biết đó là 1 file, thêm dấu ~ để chuyển Unicode sang Ansi
	$g___Boundary = _BoundaryGenerator()
	Local $sData2Send = $g___Boundary & @CRLF, $vValue, $PatternError = 0, $isFilePathDeclare = 0
	;------------------------------------------------------------------------------------------
	If Not IsArray($a_FormItems) Then
		$PatternError = 1
	ElseIf UBound($a_FormItems, 0) < 1 And UBound($a_FormItems, 0) > 2 Then
		$PatternError = 1
	ElseIf UBound($a_FormItems, 0) = 1 Then
		For $i = 0 To UBound($a_FormItems) - 1
			If Not StringRegExp($a_FormItems[$i], '^([^=]+=|[^:]+: )') Then
				$PatternError = 1
				ExitLoop
			EndIf
		Next
	ElseIf UBound($a_FormItems, 0) = 2 And UBound($a_FormItems, 2) <> 2 Then
		$PatternError = 1
	EndIf
	;---------------------------
	If $PatternError = 1 Then
		Exit MsgBox(4096, 'Lỗi', 'Tham số của _HttpRequest_DataFormCreate phải là mảng có dạng như sau: [["key1", "value1"], ["key2", "value2"], ...] hoặc ["key1=value1", "key2=value2"], ...')
	EndIf
	;------------------------------------------------------------------------------------------
	If UBound($a_FormItems, 0) = 1 Then
		Local $ArrayTemp = $a_FormItems, $uBound = UBound($ArrayTemp), $aRegExp
		ReDim $a_FormItems[$uBound][2]
		For $i = 0 To $uBound - 1
			$ArrayTemp[$i] = StringRegExp($ArrayTemp[$i], '(?s)^([^\:\=]+)(?:\=|\:\s)(.*$)', 3)
			If @error Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_DataFormCreate', 'Lỗi không xác định'), '')
			$a_FormItems[$i][0] = ($ArrayTemp[$i])[0]
			$a_FormItems[$i][1] = ($ArrayTemp[$i])[1]
		Next
	EndIf
	;------------------------------------------------------------------------------------------
	If UBound($a_FormItems, 0) = 2 Then
		Local $l__uBound = UBound($a_FormItems) - 1
		For $i = 0 To $l__uBound
			$isFilePathDeclare = StringRegExp($a_FormItems[$i][1], '^\@[^\r\n]{1,200}\.\w+$')
			Select
				Case StringLeft($a_FormItems[$i][0], 1) == '$' Or $isFilePathDeclare = 1
					If $isFilePathDeclare Then $a_FormItems[$i][1] = StringTrimLeft($a_FormItems[$i][1], 1)
					If StringLeft($a_FormItems[$i][0], 1) == '$' Then $a_FormItems[$i][0] = StringTrimLeft($a_FormItems[$i][0], 1)
					;-----------------------------------------------------
					If FileExists($a_FormItems[$i][1]) Then
						If StringRegExp($a_FormItems[$i][1], '^[^\\]+\.?\w+?$') Then $a_FormItems[$i][1] = @ScriptDir & '\' & $a_FormItems[$i][1]
						$vValue = _GetFileInfo($a_FormItems[$i][1])
						If @error Then Return SetError(3, __HttpRequest_ErrNotify('_HttpRequest_DataFormCreate', 'Không xác định được tập tin đầu vào'), '')
					Else
						Local $vValue[3] = ['unknown_name', 'application/octet-stream', (StringLeft($a_FormItems[$i][1], 2) = '0x' ? BinaryToString($a_FormItems[$i][1]) : $a_FormItems[$i][1])]
					EndIf
					;-------------------------------------------------------
					If $sFilenameDefault And $sFilenameDefault <> Default Then
						$vValue[0] = $sFilenameDefault
						$vValue[1] = _HttpRequest_DetectMIME($vValue[0])
					EndIf
					;-------------------------------------------------------
					If StringInStr($a_FormItems[$i][0], '/', 1, 1) Then
						Local $a_FormItems_Split = StringRegExp($a_FormItems[$i][0], '^([^\/]+)\/(.+)$', 3)
						If @error Then Return SetError(4, __HttpRequest_ErrNotify('_HttpRequest_DataFormCreate', 'Mẫu Key sai'), '')
						$a_FormItems[$i][0] = $a_FormItems_Split[0]
						$vValue[0] = $a_FormItems_Split[1]
						$vValue[1] = _HttpRequest_DetectMIME($vValue[0])
					EndIf
					;-------------------------------------------------------
					If $vValue[0] == 'unknown_name' Then __HttpRequest_ErrNotify('_HttpRequest_DataFormCreate', 'Dữ liệu cần upload không xác định được kiểu tập tin', '', 'Warning')
					
				Case StringLeft($a_FormItems[$i][0], 1) == '~'
					$a_FormItems[$i][0] = StringTrimLeft($a_FormItems[$i][0], 1)
					$vValue = _Utf8ToAnsi($a_FormItems[$i][1])
					
				Case Else
					$vValue = $a_FormItems[$i][1]
			EndSelect
			;------------------------------------------------------------------------------------------
			$sData2Send &= 'Content-Disposition: form-data; name="' & $a_FormItems[$i][0] & '"'
			If UBound($vValue) > 2 Then
				$sData2Send &= '; filename="' & _Utf8ToAnsi($vValue[0]) & '"' & @CRLF & 'Content-Type: ' & $vValue[1] & @CRLF & @CRLF & $vValue[2]
			Else
				$sData2Send &= @CRLF & @CRLF & $vValue
			EndIf
			;------------------------------------------------------------------------------------------
			$sData2Send &= @CRLF & $g___Boundary & @CRLF
		Next
	Else
		Return SetError(6, __HttpRequest_ErrNotify('_HttpRequest_DataFormCreate', '$a_FormItems phải là mảng 1D hoặc 2D Array'), '')
	EndIf
	;------------------------------------------------------------------------------------------
	;$sData2Send = StringRegExpReplace($sData2Send, '(?im)^(Content-Disposition: form-data; name=")"(.*?"\s*?;\s*?filename=)', '${1}${2}')
	;$sData2Send = StringRegExpReplace($sData2Send, '(?im)(Content-Type\s*?:\s*?.*)"$', '${1}')
	;------------------------------------------------------------------------------------------
	Return StringTrimRight($sData2Send, 2) & '--'
EndFunc


Func _HttpRequest_ErrorNotify($___ErrorNotify = True)
	If $___ErrorNotify = Default Then $___ErrorNotify = True
	$g___ErrorNotify = $___ErrorNotify
EndFunc


Func _HttpRequest_SetTimeout($__TimeOut = Default)
	If StringIsDigit($__TimeOut) Then $__TimeOut = Number($__TimeOut)
	If Not IsNumber($__TimeOut) Or $__TimeOut = Default Or $__TimeOut < 0 Then $__TimeOut = 30000
	$g___TimeOut = $__TimeOut
EndFunc


Func _HttpRequest_SetReadMode($___iReadMode)     ;Khi download và có tập tin cùng tên trong thư mục chọn tải về
	$g___iReadMode = $___iReadMode
EndFunc


Func _HttpRequest_SetHotkeyStopRequest($__sHotKeyCancelReadWrite = '')
	If Not $__sHotKeyCancelReadWrite Or $__sHotKeyCancelReadWrite = Default Then $__sHotKeyCancelReadWrite = ''
	If $__sHotKeyCancelReadWrite Then
		If $g___HotkeySet Then HotKeySet($g___HotkeySet)
		HotKeySet($__sHotKeyCancelReadWrite, '__HttpRequest_CancelReadWrite')
		$g___HotkeySet = $__sHotKeyCancelReadWrite
	Else
		HotKeySet($__sHotKeyCancelReadWrite)
	EndIf
EndFunc


Func _HttpRequest_SetProxy($__Proxy = '', $___ProxyUserName = '', $___ProxyPassword = '', $___ProxyBypass = '', $iSession = Default)
	If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
	$__Proxy = StringStripWS($__Proxy, 8)
	Local $BkProxy = [$g___hProxy[$iSession][0], $g___hProxy[$iSession][2], $g___hProxy[$iSession][3]]
	If $__Proxy Then
		If Not StringRegExp($__Proxy, '^(https?://)?[\d\.]+:\d+$') Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_SetProxy', 'Proxy sai định dạng. Ví dụ mẫu Proxy đúng: 127.0.0.1:80'), '')
		$g___hProxy[$iSession][3] = (($___ProxyUserName And Not IsKeyword($___ProxyUserName)) ? $___ProxyUserName : '')
		$g___hProxy[$iSession][4] = (($___ProxyPassword And Not IsKeyword($___ProxyPassword)) ? $___ProxyPassword : '')
		$g___hProxy[$iSession][2] = (($___ProxyBypass And Not IsKeyword($___ProxyBypass)) ? $___ProxyBypass : '')
		$g___hProxy[$iSession][0] = (($__Proxy And Not IsKeyword($__Proxy)) ? $__Proxy : '')
	Else
		$g___hProxy[$iSession][0] = ''
	EndIf
	Return $BkProxy
EndFunc


Func _HttpRequest_SetProxyPreConfig($__Proxy = '', $___ProxyBypass = '')
	Switch @OSVersion
		Case "WIN_XP", "WIN_XPe", "WIN_2003"
			Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_SetProxyPreConfig', 'Hàm chỉ chạy từ Win Vista trở lên', -1), False)
	EndSwitch
	If $__Proxy And Not StringRegExp($__Proxy, '^(\d{1,3}\.){3}\d{1,3}:\d+$') Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_SetProxyPreConfig', '$__Proxy sai định dạng', -1), False)
	Local $iPID, $sStd
	$iPID = Run('netsh winhttp ' & ($__Proxy ? 'set proxy proxy-server="' & $__Proxy & '" bypass-list="' & $___ProxyBypass & '"' : 'reset proxy'), '', @SW_HIDE, 8)
	Do
		$sStd &= StdoutRead($iPID)
	Until @error
	ConsoleWrite(@CRLF & '.......................................................................' & @CRLF & StringStripWS($sStd, 7) & @CRLF & '.......................................................................' & @CRLF)
	If $__Proxy And Not StringInStr($sStd, $__Proxy, 1, 1) Then Return SetError(3, __HttpRequest_ErrNotify('_HttpRequest_SetProxyPreConfig', 'Cài đặt Proxy thất bại', -1), False)
	If $__Proxy = '' And Not StringInStr($sStd, 'Direct access', 0, 1) Then Return SetError(4, __HttpRequest_ErrNotify('_HttpRequest_SetProxyPreConfig', 'Reset Proxy thất bại', -1), False)
	Return True
EndFunc


Func _HttpRequest_CheckProxyLive($__sProxy)
	Local $__RQ = _HttpRequest('2|%' & $__sProxy, 'http://httpbin.org/get')
	If Not @error And $__RQ And StringRegExp($__RQ, '"origin"\h*?:\h*?".*?' & StringRegExpReplace($__sProxy, ':\d+$', '') & '.*?"') Then Return True
	Return SetError(1, '', False)
EndFunc


Func _HttpRequest_SetUserAgent($___sUserAgent = Default, $iSession = Default)
	$___sUserAgent = StringRegExpReplace($___sUserAgent, '(?i)^\h*?user-agent\h*?:\h*', '', 1)
	If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
	Local $BkUserAgent = $g___UserAgent[$iSession]
	If $___sUserAgent And Not IsKeyword($___sUserAgent) Then
		$g___UserAgent[$iSession] = $___sUserAgent
	Else
		$g___UserAgent[$iSession] = $g___defUserAgent
	EndIf
	Return $BkUserAgent
EndFunc


Func _HttpRequest_SetAuthorization($___sUserName = '', $___sPassword = '', $iSession = Default)
	If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
	Local $___sbkUP = $g___hCredential[$iSession][0] & ':' & $g___hCredential[$iSession][1]
	If IsKeyword($___sUserName) Then $___sUserName = ''
	If IsKeyword($___sPassword) Then $___sPassword = ''
	If $___sPassword == '' And StringInStr($___sUserName, ':', 1, 1) Then
		Local $aSplitUP = StringSplit($___sUserName, ':')
		$___sUserName = $aSplitUP[1]
		$___sPassword = $aSplitUP[2]
	EndIf
	$g___hCredential[$iSession][0] = $___sUserName
	$g___hCredential[$iSession][1] = $___sPassword
	Return $___sbkUP
EndFunc


Func _HttpRequest_QueryHeaders($iQueryFlag = Default, $iIndex = 0, $iSession = Default)
	If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
	If Not $g___hRequest[$iSession] Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_QueryHeaders', 'Handle của request đã hết hạn'), '')
	Select
		Case $iQueryFlag = Default Or $iQueryFlag = ''
			If $iSession = Default Then
				Return $g___retData[$g___LastSession][0]
			Else
				$iQueryFlag = 22
				ContinueCase
			EndIf
		Case StringIsDigit($iQueryFlag) Or IsNumber($iQueryFlag)
			Static $sQueryFlags = StringSplit('MIME_VERSION|CONTENT_TYPE|CONTENT_TRANSFER_ENCODING|CONTENT_ID|CONTENT_DESCRIPTION|CONTENT_LENGTH|CONTENT_LANGUAGE|ALLOW|PUBLIC|DATE|EXPIRES|LAST_MODIFIED|MESSAGE_ID|URI|DERIVED_FROM|COST|LINK|PRAGMA|VERSION|STATUS_CODE|STATUS_TEXT|RAW_HEADERS|RAW_HEADERS_CRLF|CONNECTION|ACCEPT|ACCEPT_CHARSET|ACCEPT_ENCODING|ACCEPT_LANGUAGE|AUTHORIZATION|CONTENT_ENCODING|FORWARDED|FROM|IF_MODIFIED_SINCE|LOCATION|ORIG_URI|REFERER|RETRY_AFTER|SERVER|TITLE|USER_AGENT|WWW_AUTHENTICATE|PROXY_AUTHENTICATE|ACCEPT_RANGES|SET_COOKIE|COOKIE|REQUEST_METHOD|REFRESH|CONTENT_DISPOSITION|AGE|CACHE_CONTROL|CONTENT_BASE|CONTENT_LOCATION|CONTENT_MD5|CONTENT_RANGE|ETAG|HOST|IF_MATCH|IF_NONE_MATCH|IF_RANGE|IF_UNMODIFIED_SINCE|MAX_FORWARDS|PROXY_AUTHORIZATION|RANGE|TRANSFER_ENCODING|UPGRADE|VARY|VIA|WARNING|EXPECT|PROXY_CONNECTION|UNLESS_MODIFIED_SINCE', '|', 2)
			;-------------------------------------------------------------------------------------------------------
			Local $vRet = _WinHttpQueryHeaders2($g___hRequest[$iSession], $iQueryFlag = -1 ? 0x80000000 + 22 : $iQueryFlag, $iIndex)
			If @error Then
				Local $vQueryFlag = ''
				If $iQueryFlag > -1 And $iQueryFlag < 71 Then $vQueryFlag = $sQueryFlags[$iQueryFlag]
				Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_QueryHeaders', 'Truy vấn Response Header' & ($vQueryFlag ? ' WINHTTP_QUERY_' & $vQueryFlag : 's') & ' thất bại'), '')
			EndIf
			Return $vRet & ($iQueryFlag = -1 ? '   ' & $g___sData2Send : '')
		Case Else
			If $iQueryFlag = 'Cookie' Or $iQueryFlag = 'Set-Cookie' Then
				Local $sCookie = _GetCookie($g___retData[$g___LastSession][0])
				If @error Then Return SetError(3, __HttpRequest_ErrNotify('_HttpRequest_QueryHeaders', 'Không truy vấn được Cookies từ Response Headers'), '')
				Return $sCookie
			Else
				Local $aResponseHeaders = StringRegExp($g___retData[$g___LastSession][0], '(?m)^\h*?\Q' & $iQueryFlag & '\E\h*?:\h*(.+)$', 1)
				If @error Then Return SetError(4, __HttpRequest_ErrNotify('_HttpRequest_QueryHeaders', 'Truy vấn ' & $iQueryFlag & ' từ Response Headers thất bại'), '')
				Return $aResponseHeaders[0]
			EndIf
	EndSelect
EndFunc


Func _HttpRequest_QueryData($iReadingMode = Default, $iSession = Default, $CallBackFunc_Progress = '')     ; 0 ANSI, 1 UTF8, 2 Binary
	If $iReadingMode = Default Then $iReadingMode = 1
	If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
	If Not $g___hRequest[$iSession] Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_QueryData', 'Handle của request này đã hết hạn'), '')
	Local $outData = _WinHttpReadData_Ex($g___hRequest[$iSession], $CallBackFunc_Progress)
	If $outData == '' Then
		If $iReadingMode = 2 Then Return $g___retData[$g___LastSession][1]
		Return BinaryToString($g___retData[$g___LastSession][1], $iReadingMode = 1 ? 4 : 1)
	Else
		If StringRegExp(BinaryMid($outData, 1, 1), '(?i)0x(1F|08|8B)') Then $outData = __Gzip_Uncompress($outData)
		If $iReadingMode = 2 Then Return $outData
		Return BinaryToString($outData, $iReadingMode = 0 ? 1 : 4)
	EndIf
EndFunc


Func _HttpRequest_GetSize($iURL)
	Local $sHeader = _HttpRequest(1, $iURL, '', '', '', 'Range: bytes=0-0|Pragma: no-cache|Cache-Control: no-cache, no-store|If-Modified-Since: Sat, 1 Jan 2000 00:00:00 GMT')
	If @error Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_GetSize', 'Gửi request với header Range thất bại'), Null)
	;-----------------------------------------------------------------------------------------------------------------------
	Local $aSize = StringRegExp($sHeader, '(?im)^\h*?Content-Range\h*?:\h*?bytes\h+\d+\-\d+\/(\d+)', 1)
	If @error Then
		$aSize = StringRegExp($sHeader, '(?im)^\h*?Content-Length\h*?:\h*?(\d+)', 1)
		If @error Then
			Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_GetSize', 'Không tìm thấy thông tin kích cỡ tập tin từ  Response Headers'), Null)
		Else
			Return SetExtended(0, Number($aSize[0]))
		EndIf
	Else
		Return SetExtended(1, Number($aSize[0]))
	EndIf
EndFunc


Func _HttpRequest_FileSplitSize($iSize_or_URL, $iPart = Default, $iOffset = Default)
	If Not $iPart Or $iPart = Default Then $iPart = 8
	If Not $iOffset Or $iOffset = Default Then $iOffset = 0
	If Not StringIsDigit($iSize_or_URL) Then
		$iSize_or_URL = _HttpRequest_GetSize($iSize_or_URL)
		If $iSize_or_URL = 0 Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_FileSplitSize', 'Request lấy độ lớn của tập tin thất bại'), 0)
	EndIf
	;--------------------------------------------------------------------------------------------------------------------------------------
	If $iOffset And $iOffset * $iPart > $iSize_or_URL Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_FileSplitSize', '$iOffset đã nạp khiến phần chia nhỏ bị sai'), 0)
	;--------------------------------------------------------------------------------------------------------------------------------------
	Local $asPart[$iPart][2]
	Local $nPart = Floor($iSize_or_URL / $iPart)
	For $i = 0 To $iPart - 1
		$asPart[$i][0] = $i * $nPart + $iOffset
		$asPart[$i][1] = ($i + 1) * $nPart - 1 + $iOffset
	Next
	Local $nMod = Mod($iSize_or_URL, $iPart)
	If $nMod Then
		Local $nCount = 0
		For $i = 0 To $iPart - 1
			$asPart[$i][0] += $nCount
			If $nCount < $nMod Then $nCount += 1
		Next
		$nCount = 1
		For $i = 0 To $iPart - 1
			$asPart[$i][1] += $nCount
			If $nCount < $nMod Then $nCount += 1
		Next
	EndIf
	Local $aRange[$iPart]
	For $i = 0 To $iPart - 1
		If $iOffset > 0 And $i = $iPart - 1 Then $asPart[$i][1] -= $iOffset
		$aRange[$i] = 'Range: bytes=' & $asPart[$i][0] & '-' & $asPart[$i][1]
	Next
	Return SetError(0, $iSize_or_URL, $aRange)
EndFunc


Func _HttpRequest_SearchHiddenValues($iSourceHtml_or_URL, $iKeySearch = '', $iURIEncodeValue = True, $iType = Default)
	;$iKeySearch tách các KeyName bằng dấu |
	; $iType: hidden, text, hidden|text. default: hidden
	If $iType = Default Then $iType = 'hidden'
	If Not $iKeySearch Or IsKeyword($iKeySearch) Then $iKeySearch = ''
	If $iKeySearch Then $iKeySearch = StringSplit($iKeySearch, '|')
	;--------------------------------------------------------------------------------------------------------------------------------------
	If StringRegExp($iSourceHtml_or_URL, '(?i)^https?://') And Not StringRegExp($iSourceHtml_or_URL, '[\r\n]') Then
		$iSourceHtml_or_URL = _HttpRequest(2, $iSourceHtml_or_URL)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_SearchHiddenValues', 'Request lấy source thất bại'), '')
	EndIf
	;--------------------------------------------------------------------------------------------------------------------------------------
	Local $aInput = StringRegExp($iSourceHtml_or_URL, '(?i)<input (.*?type=\\?["''](?:' & $iType & ')\\?[''"] [\S\s]*?)\/?>', 3)
	If @error Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_SearchHiddenValues', 'Không tìm thấy Hidden Values'), '')
	$aInput = __ArrayDuplicate($aInput)
	;--------------------------------------------------------------------------------------------------------------------------------------
	Local $vName, $vValue, $_vName, $_vValue, $sRet, $isKeyExists, $aRet[0][2], $aCounter = 0
	If IsObj($g___oDicHiddenSearch) Then
		$g___oDicHiddenSearch.RemoveAll
	Else
		$g___oDicHiddenSearch = ObjCreate("Scripting.Dictionary")
		$g___oDicHiddenSearch.CompareMode = 1
	EndIf
	If @error Then Return SetError(3, __HttpRequest_ErrNotify('_HttpRequest_SearchHiddenValues', 'Không thể tạo Dictionary Object'), '')
	With $g___oDicHiddenSearch
		For $i = 0 To UBound($aInput) - 1
			$isKeyExists = 0
			$vName = StringRegExp($aInput[$i], '(?i)name\h*?=\h*?\\?[''"](.+?)\\?[''"]', 1)
			If @error Then ContinueLoop
			If ($iURIEncodeValue = True And .Exists(_URIEncode($vName[0]))) Or ($iURIEncodeValue = False And .Exists($vName[0])) Then
				$isKeyExists = 1
				For $k = 1 To 99
					If ($iURIEncodeValue = True And Not .Exists(_URIEncode($vName[0]) & '.' & $k)) Or ($iURIEncodeValue = False And Not .Exists($vName[0] & '.' & $k)) Then
						$vName[0] &= '.' & $k
						ExitLoop
					EndIf
				Next
			EndIf
			;-----------------------------------------
			If IsArray($iKeySearch) Then
				For $k = 1 To $iKeySearch[0]
					If StringRegExp($vName[0], '(?i)^\Q' & $iKeySearch[$k] & '\E\.?\d*?$') Then ExitLoop
				Next
				If $k > $iKeySearch[0] Then ContinueLoop
			EndIf
			;-----------------------------------------
			$vValue = StringRegExp($aInput[$i], '(?i)value\h*?=\h*?\\?[''"](.*?)\\?[''"]', 1)
			If @error Then ContinueLoop
			;-----------------------------------------
			$_vName = ($iURIEncodeValue ? _URIEncode($vName[0]) : $vName[0])
			$_vValue = ($iURIEncodeValue ? _URIEncode($vValue[0]) : $vValue[0])
			If $isKeyExists = 0 Then
				$sRet &= $_vName & '=' & $_vValue & '&'
				.Add($_vName & '.0', $_vValue)
				If $_vName <> $vName[0] Then .Add($vName[0] & '.0', $_vValue)
			EndIf
			.Add($_vName, $_vValue)
			If $_vName <> $vName[0] Then .Add($vName[0], $_vValue)
		Next
		;-----------------------------------------
		Local $aRet[.Count][2], $aCounter = 0
		For $oKey In $g___oDicHiddenSearch
			$aRet[$aCounter][0] = $oKey
			$aRet[$aCounter][1] = .Item($oKey)
			$aCounter += 1
		Next
		.Add('all_array', $aRet)
		;-------------
		.Add('all_string', StringTrimRight($sRet, 1))
		;-----------------------------------------
	EndWith
	Return $g___oDicHiddenSearch
EndFunc


Func _HttpRequest_FindSimiliarWords($sWords)
	Local $aRet = StringRegExp(_HttpRequest(2, 'https://www.google.com/search?q=' & StringReplace($sWords, '*', 'a')), 'href="/search\?q=([^>]*?)&amp;spell=1', 1)
	If @error Then Return SetError(1, '', $sWords)
	Return $aRet[0]
EndFunc


Func _HttpRequest_OnlineCompiler($iCode, $iLanguage)
	;http://rextester.com/main
	;$iLanguage: 39 = Ada, 15 = Assembly, 38 = Bash, 1 = C#, 7 = C++ (gcc), 27 = C++ (clang), 28 = C++ (vc++), 6 = C (gcc), 26 = C (clang), 29 = C (vc), 36 = Client Side, 18 = Common Lisp, 30 = D, 41 = Elixir, 40 = Erlang, 3 = F#, 45 = Fortran, 20 = Go, 11 = Haskell, 4 = Java, 17 = Javascript, 43 = Kotlin, 14 = Lua, 33 = MySql, 23 = Node.js, 42 = Ocaml, 25 = Octave, 10 = Objective-C, 35 = Oracle, 9 = Pascal, 13 = Perl, 8 = Php, 34 = PostgreSQL, 19 = Prolog, 5 = Python, 24 = Python 3, 31 = R, 12 = Ruby, 21 = Scala, 22 = Scheme, 16 = Sql Server, 37 = Swift, 32 = Tcl, 2 = Visual Basic
	If TimerDiff($g___OnlineCompilerTimer) < 1500 Then
		Sleep(1500)
	Else
		$g___OnlineCompilerTimer = TimerInit()
	EndIf
	Local $jsonResult = _HttpRequest(2, 'https://rextester.com/rundotnet/api', 'LanguageChoice=' & $iLanguage & '&Program=' & _URIEncode($iCode))
	Local $aResult = StringRegExp($jsonResult, '(?i)^\{"Warnings":(null|".*?"),"Errors":(null|".*?"),"Result":"(.*?)(?:\\[rn]){0,}","Stats"', 3)
	If @error Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_OnlineCompiler', 'Compile Online thất bại'), '')
	If $aResult[0] <> 'null' Or $aResult[1] <> 'null' Then Return SetError(2, '', $jsonResult)
	Return $aResult[2]
EndFunc


Func _HttpRequest_DnsDump($sDomain, $vExportXLSX = False, $FolderSaveXLSX = Default)
	Local $csrfmiddlewaretoken = StringRegExp(_HttpRequest(1, 'https://dnsdumpster.com/'), 'csrftoken=(.*?);', 1)
	If @error Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_DnsDump', 'Không kết nối được với dnsdumpster.com'), '')
	Local $rq = _HttpRequest(2, 'https://dnsdumpster.com/', 'csrfmiddlewaretoken=' & $csrfmiddlewaretoken[0] & '&targetip=' & $sDomain, '', 'https://dnsdumpster.com/')
	If $vExportXLSX Then
		Local $sFilePath = ($FolderSaveXLSX ? $FolderSaveXLSX & '\' : '') & $sDomain & '-' & TimerInit() & '.xlsx'
		Local $linkXLSX = StringRegExp($rq, '"([^"]+\.xlsx)"', 1)
		If @error Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_DnsDump', 'Không tìm thấy link tải trang thống kê xlsx'), '')
		If IsKeyword($FolderSaveXLSX) Then $FolderSaveXLSX = ''
		_HttpRequest_Test(_HttpRequest(3, $linkXLSX[0]), $sFilePath, Default, False)
		If @error Or Not FileExists($sFilePath) Then Return SetError(3, __HttpRequest_ErrNotify('_HttpRequest_DnsDump', 'Tải tập tin xlsx về thất bại'), False)
		Return True
	Else
		Local $aList = StringRegExp($rq, '<td class="col-md-3">(.*?)</span></td></tr>', 3)
		If @error Then Return SetError(4, __HttpRequest_ErrNotify('_HttpRequest_DnsDump', 'Không tìm thấy các IP ứng với Domain'), '')
		$aList = StringSplit(StringReplace(StringReplace(StringRegExpReplace(_ArrayToString($aList), '(<[^>]+>)', '|'), '||', '|'), '||', '|'), '|')
		If Not IsInt($aList[0] / 4) Then Return SetError(5, __HttpRequest_ErrNotify('_HttpRequest_DnsDump', 'Dữ liệu tìm được không hợp lệ'), '')
		Local $aRet[$aList[0] / 4][4], $iCounter = 0
		For $i = 1 To $aList[0] Step 4
			For $j = 0 To 3
				$aRet[$iCounter][$j] = $aList[$i + $j]
			Next
			$iCounter += 1
		Next
		Return SetError(0, UBound($aRet), $aRet)
	EndIf
EndFunc


Func _HttpRequest_URLChangeToRealIP($sURL, $iUseServiceOnline = False, $vGetFullURL = True)
	Local $aURL = __HttpRequest_URLSplit($sURL)
	If @error Then Return SetError(1, 0 * __HttpRequest_ErrNotify('_HttpRequest_URLChangeToRealIP', 'Không tách được các thành phần của URL nạp vào'), '')
	If $vGetFullURL = Default Or $vGetFullURL == '' Then $vGetFullURL = True
	If $iUseServiceOnline = Default Or $iUseServiceOnline == '' Then $iUseServiceOnline = False
	Local $aRet[0], $iCounter = 0
	;-------------------------------------------------------
	If $iUseServiceOnline Then
		Local $aIP = StringRegExp(_HttpRequest(2, 'https://shadowcrypt.club/cloudflare/', 'user=' & _URIEncode($sURL) & '&sub=Submit'), '(?im)(?:^\h*?|>).*?\h+=>\h+((?:\d{1,3}\.){3}\d{1,3})\h+(.*?)<', 3)
		If @error Then Return SetError(2, 0 * __HttpRequest_ErrNotify('_HttpRequest_URLChangeToRealIP', 'Không tìm thấy các IP ứng với Domain'), '')
		For $i = 0 To UBound($aIP) - 1 Step 2
			If StringInStr($aIP[$i + 1], 'CloudFlare', 0, 1) Then ContinueLoop
			ReDim $aRet[$iCounter + 1]
			$aRet[$iCounter] = ($vGetFullURL ? $aURL[7] & '://' & $aURL[10] & $aIP[$i] & $aURL[3] : $aIP[$i])
			$iCounter += 1
		Next
		
	Else     ;-------------------------------------------------------
		
		If $aURL[10] Then $aURL[2] = StringTrimLeft($aURL[2], 4)
		Local $aRet[0], $iCounter = 0
		$g___ErrorNotify = False
		For $sSub In StringSplit('ftp|cpanel|webmail|blog|forum|driect-connect|vb|forums|home|shop|blogs|direct|mail|test|cdn|dev|images', '|', 2)
			_HttpRequest(1, $aURL[7] & '://' & $aURL[10] & $sSub & '.' & $aURL[2] & (($aURL[1] <> 80 And $aURL[1] <> 443) ? ':' & $aURL[1] : ''))
			If @error Or $g___ServerIP = '' Or @extended = 503 Then ContinueLoop
			ReDim $aRet[$iCounter + 1]
			$aRet[$iCounter] = ($vGetFullURL ? $aURL[7] & '://' & $aURL[10] & $g___ServerIP & $aURL[3] : $g___ServerIP)
			$iCounter += 1
		Next
		$g___ErrorNotify = True
	EndIf
	;-------------------------------------------------------
	If $iCounter = 0 Then Return SetError(3, 0 * __HttpRequest_ErrNotify('_HttpRequest_URLChangeToRealIP', 'Không tìm thấy IP thực của URL này'), '')
	$aRet = __ArrayDuplicate($aRet)
	If UBound($aRet) > 1 Then
		Return SetError(0, UBound($aRet), $aRet)
	Else
		Return $aRet[0]
	EndIf
EndFunc


Func _HttpRequest_BypassCloudflare($URL_in, $iTimeout = Default, $iUselessParam = 0)
	If $iUselessParam Then Return Asc(StringMid($URL_in, $iTimeout, 1))
	If $iTimeout < 10000 Or $iTimeout = Default Or Not $iTimeout Then $iTimeout = 10000
	If StringRight($URL_in, 1) <> '/' Then $URL_in &= '/'
	Local $aURL_in = StringRegExp($URL_in, '(?i)^(https?://)([^\/]+)', 3)
	If @error Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_BypassCloudflare', 'URL đầu vào không chính xác'), '')
	;-------------------------------------------------------------------------------------------------------------------
	Local $sourceHtml = _HttpRequest(2, $URL_in, '', '', $URL_in, 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8|Accept-Language: en-GB,en;q=0.9')
	If @error Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_BypassCloudflare', 'Request lấy Html thất bại'), '')
	;-------------------------------------------------------------------------------------------------------------------
	Local $tHidden = _HttpRequest_SearchHiddenValues($sourceHtml)
	If @error Then Return SetError(3, __HttpRequest_ErrNotify('_HttpRequest_BypassCloudflare', 'Không tìm được các tham số hidden từ Html'), '')
	;-------------------------------------------------------------------------------------------------------------------
	Local $URL_out = '', $Bypass_CF, $jschl_answer, $rq
	If StringInStr($sourceHtml, 'src="/cdn-cgi/scripts/cf.challenge.js"', 1, 1) Then     ; Loại Recaptcha
		Local $id_data_ray = StringRegExp($sourceHtml, '(?i)data-ray="(.+?)"', 1)
		If @error Then Return SetError(4, __HttpRequest_ErrNotify('_HttpRequest_BypassCloudflare', 'Không tìm thấy data-ray từ Html'), '')
		Local $g_recaptcha_response = _IE_RecaptchaBox($URL_in, Default, Default, Default, Default, StringRegExp($sourceHtml, 'sitekey\h*?=\h*?["''](.*?)["'']', 1)[0])
		If @error Then Return SetError(5, __HttpRequest_ErrNotify('_HttpRequest_BypassCloudflare', 'Giải ReCaptcha thất bại'), '')
		_HttpRequest_ConsoleWrite('> [CloudFlare] Đã nhận được g-recaptcha-response: ' & $g_recaptcha_response & @CRLF & @CRLF)
		$URL_out = $aURL_in[0] & $aURL_in[1] & '/cdn-cgi/l/chk_captcha?' & $tHidden('all_string') & '&id=' & $id_data_ray[0] & '&g-recaptcha-response=' & $g_recaptcha_response
	Else     ; Loại giải JS
		Local $cfDN = StringRegExp($sourceHtml, 'id="cf-dn-\w+">(.*?)</', 1), $isNewCF = Not @error
		If $isNewCF Then
			$sourceHtml = StringRegExpReplace($sourceHtml, 'function\((\w+)\)\{var \1\h*?=.*?;\h*?return \W\(\1\)\}\(\)', $cfDN[0])
			$sourceHtml = StringRegExpReplace($sourceHtml, 'function\(\w+\)\{return\h+[^\}]+\}\(', '__StringCharCodeAt("' & $aURL_in[1] & '",')
		EndIf
		$sourceHtml = StringReplace(StringReplace($sourceHtml, '={"', '.', 1, 1), '":', '+=', 1, 1)
		Local $number_jschl_math = StringRegExp($sourceHtml, '\.\w+([\+\-\*\/])=((?:[\!\+\-\*\/\[\]\(\)]|\Q__StringCharCodeAt("' & $aURL_in[1] & '",\E)+)', 3)
		If @error Then Return SetError(6, __HttpRequest_ErrNotify('_HttpRequest_BypassCloudflare', 'Không tìm được number_jschl_math từ Html'), '')
		For $i = 1 To UBound($number_jschl_math) - 1 Step 2
			$jschl_answer = '(' & $jschl_answer & $number_jschl_math[$i - 1] & $number_jschl_math[$i] & ')'
		Next
		$jschl_answer = Call('Execute', StringReplace(StringReplace(StringReplace(StringReplace($jschl_answer, '+!![]', '+1'), '!+[]', '+1'), '+[]', '+0'), '+(+', '+0&('))
		$jschl_answer = Round(StringFormat('%.10f', $jschl_answer), 10)                    ; Fixed Number
		$jschl_answer = $jschl_answer + ($isNewCF ? 0 : StringLen($aURL_in[1]))        ; Nếu là code js kiểu cũ thì + len Domain
		;-------------------------------------------------------------------------------------------------------------------
		Local $tHidden = _HttpRequest_SearchHiddenValues($sourceHtml)
		If @error Then Return SetError(7, __HttpRequest_ErrNotify('_HttpRequest_BypassCloudflare', 'Không tìm được các tham số hidden từ Html'), '')
		;-------------------------------------------------------------------------------------------------------------------
		Local $challenge_form = StringRegExp($sourceHtml, '(?i)"challenge-form" action\h?=\h?"\/?([^"]+)"', 1)
		If @error Then Return SetError(8, __HttpRequest_ErrNotify('_HttpRequest_BypassCloudflare', 'Không tìm được challenge-form từ Html'), '')
		;-------------------------------------------------------------------------------------------------------------------
		$URL_out = $aURL_in[0] & $aURL_in[1] & '/' & $challenge_form[0] & '?' & $tHidden('all_string') & '&jschl_answer=' & $jschl_answer
		;-------------------------------------------------------------------------------------------------------------------
		_HttpRequest_ConsoleWrite('> [CloudFlare] Hãy chờ 5 giây ...')
		For $i = 1 To 50
			Sleep(100)
			ConsoleWrite('.')
		Next
		ConsoleWrite(@CRLF & @CRLF)
	EndIf
	;-------------------------------------------------------------------------------------------------------------------
	Local $sTimer = TimerInit()
	Do
		Sleep(200)
		If TimerDiff($sTimer) > $iTimeout Then Return SetError(9, __HttpRequest_ErrNotify('_HttpRequest_BypassCloudflare', 'Timeout - Vượt CloudFlare thất bại'), '')
		$rq = _HttpRequest(1, $URL_out, '', '', $URL_in, 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8|Accept-Language: en-GB,en;q=0.9')
		$Bypass_CF = StringRegExp($rq, '(?i)(cf_clearance=[^;]+)', 1)
	Until Not @error
	ConsoleWrite('> [CloudFlare] Bypass Cookie : ' & $Bypass_CF[0] & @CRLF & @CRLF)
	Return $Bypass_CF[0]
EndFunc

Func __StringCharCodeAt($sString, $iPos)
	Return Asc(StringMid($sString, $iPos + 1, 1))
EndFunc

#cs Code cũ
			If Not StringRegExp($sourceHtml, 'id="cf-dn-\w+"') Then ;-------------------------------------CF cũ------------------------------------------------------------------------
				$sourceHtml = StringReplace(StringReplace($sourceHtml, '={"', '.', 1, 1), '":', '+=', 1, 1)
				Local $number_jschl_math = StringRegExp($sourceHtml, '\.\w+([\+\-\*\/])=((?:[\!\+\-\*\/\[\]\(\)])+)', 3)
				If @error Then Return SetError(6, __HttpRequest_ErrNotify('_HttpRequest_BypassCloudflare', 'Không tìm được number_jschl_math từ Html'), '')
				For $i = 1 To UBound($number_jschl_math) - 1 Step 2
					$jschl_answer = '(' & $jschl_answer & $number_jschl_math[$i - 1] & $number_jschl_math[$i] & ')'
				Next
				$jschl_answer = Call('Execute', StringReplace(StringReplace(StringReplace(StringReplace($jschl_answer, '+!![]', '+1'), '!+[]', '+1'), '+[]', '+0'), '+(+', '&('))
				$jschl_answer = Round(StringFormat('%.10f', $jschl_answer), 10) ; Fixed Number
				$jschl_answer = $jschl_answer + StringLen($aURL_in[1]) ; + len Domain
			Else ;-------------------------------------CF mới-----------------------------------------------------------------------
				$sourceHtml = StringRegExpReplace($sourceHtml, 'function\((\w+)\)\{var \1\h*?=.*?;\h*?return \W\(\1\)\}\(\)', StringRegExp($sourceHtml, 'id="cf-dn-\w+">(.*?)</', 1)[0])
				$sourceHtml = StringRegExpReplace($sourceHtml, 'function\(\w+\)\{return\h+[^\}]+\}', 't.charCodeAt')
				$sourceHtml = StringRegExpReplace($sourceHtml, 'a\.value\h*?=\h*?(.*?);', 'document.write(${1});#EndJS#', 1)
				$sourceHtml = StringRegExpReplace($sourceHtml, '(?i)t = document.createElement[\s\S]*?t.innerHTML=.+', '', 1)
				$sourceHtml = StringRegExpReplace($sourceHtml, '[af] = document.getElementById.+', '')
				$sourceHtml = StringReplace($sourceHtml, 't = t.firstChild.href', 't="' & $URL_in & '"', 1)
				$sourceHtml = StringReplace($sourceHtml, 'g = String.fromCharCode;', '', 1)
				$sourceHtml = StringReplace($sourceHtml, '4000', 0)
				Local $jsCode = StringRegExp($sourceHtml, '(?is)(var s,t,o,p,b,r,e,a,k,i,n,g,f,.*?)\Q#EndJS#\E', 1)
				$jschl_answer = _JS_Execute('', $jsCode[0], '')
			EndIf
#ce Code cũ


Func _HttpRequest_SetCookieRemeber($iRemember = True)
	$g___hCookieRemember = $iRemember
EndFunc


Func _HttpRequest_ConsoleWrite($sString, $iNormalMode = 0)
	If @Compiled Then Return
	If $iNormalMode Then
		ConsoleWrite($g___ConsoleForceANSI ? __RemoveVietMarktical($sString) : _Utf8ToAnsi($sString))
	Else
		DllCall($dll_User32, "none", "SendNotifyMessageW", "hwnd", $g___hSciTEOutput, "uint", 0x0100, "uint", 0, "uint", 0)     ;Ổn định vị trí
		For $sASCIIString In StringToASCIIArray($sString)
			DllCall($dll_User32, "none", "SendNotifyMessageW", "hwnd", $g___hSciTEOutput, "uint", 0x0109, "uint", $sASCIIString, "uint", 0)
		Next
	EndIf
EndFunc


Func _HttpRequest_MsgBox($iFlag, $iTitle, $iText, $iTimeout = 0)
	$iTitle = StringToBinary($iTitle, 4)
	$iText = StringToBinary($iText, 4)
	If StringLen($iText) > 4000 Then
		Local $fOpen = FileOpen(@TempDir & '\_HttpRequest_MsgBox.tmp', 2 + 8 + 32)
		FileWrite($fOpen, BinaryToString($iText, 4))
		FileClose($fOpen)
		Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(' & $iFlag & ', BinaryToString(""' & $iTitle & '"",4), FileRead(@TempDir & ""\_HttpRequest_MsgBox.tmp""), ' & $iTimeout & ')"')
	Else
		Run(@AutoItExe & ' /AutoIt3ExecuteLine "MsgBox(' & $iFlag & ', BinaryToString(""' & $iTitle & '"",4), BinaryToString(""' & $iText & '"",4), ' & $iTimeout & ')"')
	EndIf
EndFunc


Func _HttpRequest_ReduceMem()
	Local $ahProc = DllCall($dll_Kernel32, 'int', 'OpenProcess', 'int', 0x1F0FFF, 'int', False, 'int', @AutoItPID)
	If @error Or Not IsArray($ahProc) Then Return SetError(1)
	DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', $ahProc[0])
	DllCall($dll_Kernel32, 'int', 'CloseHandle', 'int', $ahProc[0])
EndFunc


Func _HttpRequest_SetRoot($___BaseURL, $iSession = Default)
	If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
	Local $___bkBaseURL = $g___sBaseURL[$iSession]
	If StringRight($___BaseURL, 1) == '/' Then $___BaseURL = StringTrimRight($___BaseURL, 1)
	$g___sBaseURL[$iSession] = $___BaseURL
	Return $___bkBaseURL
EndFunc


Func _HttpRequest_GenarateIP()
	Return Random(1, 255, 1) & '.' & Random(1, 255, 1) & '.' & Random(1, 255, 1) & '.' & Random(1, 255, 1)
EndFunc


Func _Data2SendJSON($_Key1, $_Value1 = '', $_Key2 = '', $_Value2 = '', $_Key3 = '', $_Value3 = '', $_Key4 = '', $_Value4 = '', $_Key5 = '', $_Value5 = '', $_Key6 = '', $_Value6 = '', $_Key7 = '', $_Value7 = '', $_Key8 = '', $_Value8 = '', $_Key9 = '', $_Value9 = '', $_Key10 = '', $_Value10 = '', $_Key11 = '', $_Value11 = '', $_Key12 = '', $_Value12 = '', $_Key13 = '', $_Value13 = '', $_Key14 = '', $_Value14 = '', $_Key15 = '', $_Value15 = '', $_Key16 = '', $_Value16 = '', $_Key17 = '', $_Value17 = '', $_Key18 = '', $_Value18 = '', $_Key19 = '', $_Value19 = '', $_Key20 = '', $_Value20 = '')
	Local $aParam = [$_Key1, $_Value1, $_Key2, $_Value2, $_Key3, $_Value3, $_Key4, $_Value4, $_Key5, $_Value5, $_Key6, $_Value6, $_Key7, $_Value7, $_Key8, $_Value8, $_Key9, $_Value9, $_Key10, $_Value10, $_Key11, $_Value11, $_Key12, $_Value12, $_Key13, $_Value13, $_Key14, $_Value14, $_Key15, $_Value15, $_Key16, $_Value16, $_Key17, $_Value17, $_Key18, $_Value18, $_Key19, $_Value19, $_Key20, $_Value20], $sResult = ''
	For $i = 0 To UBound($aParam) - 1 Step 2
		If $aParam[$i] == '' Then ExitLoop
		If Not IsNumber($aParam[$i + 1]) And Not IsKeyword($aParam[$i + 1]) Then $aParam[$i + 1] = '"' & StringReplace($aParam[$i + 1], '"', '\"') & '"'
		$sResult &= '"' & $aParam[$i] & '":' & $aParam[$i + 1] & ','
	Next
	Return '{' & StringTrimRight($sResult, 1) & '}'
EndFunc


Func _Data2SendEncode($_Key1, $_Value1 = '', $_Key2 = '', $_Value2 = '', $_Key3 = '', $_Value3 = '', $_Key4 = '', $_Value4 = '', $_Key5 = '', $_Value5 = '', $_Key6 = '', $_Value6 = '', $_Key7 = '', $_Value7 = '', $_Key8 = '', $_Value8 = '', $_Key9 = '', $_Value9 = '', $_Key10 = '', $_Value10 = '', $_Key11 = '', $_Value11 = '', $_Key12 = '', $_Value12 = '', $_Key13 = '', $_Value13 = '', $_Key14 = '', $_Value14 = '', $_Key15 = '', $_Value15 = '', $_Key16 = '', $_Value16 = '', $_Key17 = '', $_Value17 = '', $_Key18 = '', $_Value18 = '', $_Key19 = '', $_Value19 = '', $_Key20 = '', $_Value20 = '')
	Local $sResult = '', $sKey
	If @NumParams = 1 Then
		Local $sData2Send = $_Key1
		Local $aData2Send = StringRegExp($sData2Send, '(?:^|\&)([^\=]+=?=?)(?:=)([^\&]*)', 3), $uBound = UBound($aData2Send)
		If Mod($uBound, 2) Then Return $sData2Send
		For $i = 0 To $uBound - 1 Step 2
			If Not StringRegExp($aData2Send[$i], '\%\w\w?') Then $aData2Send[$i] = _URIEncode($aData2Send[$i])
			If Not StringRegExp($aData2Send[$i + 1], '\%\w\w?') Then $aData2Send[$i + 1] = _URIEncode($aData2Send[$i + 1])
			$sResult &= $aData2Send[$i] & '=' & $aData2Send[$i + 1] & '&'
		Next
	Else
		Local $aParam = [$_Key1, $_Value1, $_Key2, $_Value2, $_Key3, $_Value3, $_Key4, $_Value4, $_Key5, $_Value5, $_Key6, $_Value6, $_Key7, $_Value7, $_Key8, $_Value8, $_Key9, $_Value9, $_Key10, $_Value10, $_Key11, $_Value11, $_Key12, $_Value12, $_Key13, $_Value13, $_Key14, $_Value14, $_Key15, $_Value15, $_Key16, $_Value16, $_Key17, $_Value17, $_Key18, $_Value18, $_Key19, $_Value19, $_Key20, $_Value20]
		For $i = 0 To UBound($aParam) - 1 Step 2
			If $aParam[$i] == '' Then ExitLoop
			$sResult &= _URIEncode($aParam[$i]) & '=' & _URIEncode($aParam[$i + 1]) & '&'
		Next
	EndIf
	Return StringTrimRight($sResult, 1)
EndFunc
;===========================================================



Func _BoundaryGenerator($isChrome = False)
	Local $sData = ""
	If $isChrome Then
		For $i = 1 To 16
			$sData &= $def___aChr64[Random(0, 62, 1)]
		Next
		Return ('------WebKitFormBoundary' & $sData)
	Else
		For $i = 1 To 12
			$sData &= Random(1, 9, 1)
		Next
		Return ('-----------------------------' & $sData)
	EndIf
EndFunc


Func _Utf8ToAnsi($sData)
	Return BinaryToString(StringToBinary($sData, 4), 1)
EndFunc


Func _AnsiToUtf8($sData)
	Return BinaryToString(StringToBinary($sData, 1), 4)
EndFunc


Func _URIEncode($sData, $vUTF8 = True, $iPassSpace = True)
	If $sData == '' Then Return ''
	If $vUTF8 = True Then $sData = _Utf8ToAnsi($sData)
	$sData = _HTMLEncode($sData, '%', '', False, 2, False)
	Return $iPassSpace ? StringReplace($sData, '%20', '+', 0, 1) : $sData
EndFunc


Func _URIDecode($sData, $vUTF8 = True, $iEntities = 0)
	If $sData == '' Then Return ''
	$sData = _HTMLDecode(StringReplace($sData, '+', ' ', 0, 1), '%', '', False, 2, True, $iEntities)
	If $vUTF8 Then $sData = _AnsiToUtf8($sData)
	Return $sData
EndFunc


Func _HTMLEncode($sData, $Escape_Character_Head = '\u', $Escape_Character_Tail = Default, $AnsiEncode = False, $iHexLength = Default, $iPassSpace = True)
	If $sData == '' Then Return ''
	If $iHexLength = Default Then $iHexLength = 4
	If $Escape_Character_Tail = Default Then $Escape_Character_Tail = ''
	Local $Asc_or_AscW = ($iHexLength = 2 ? 'Asc' : 'AscW')
	If $AnsiEncode Then
		$sData = _Utf8ToAnsi($sData)
		$Asc_or_AscW = 'Asc'
	EndIf
	Local $sResult = Call('Execute', '"' & StringReplace(StringRegExpReplace($sData, '([^\w\-\.\~' & ($iPassSpace ? '\h' : '') & '])', '" & "\' & $Escape_Character_Head & '" & Hex(' & $Asc_or_AscW & '("${1}"), ' & $iHexLength & ') & "' & $Escape_Character_Tail), $Asc_or_AscW & '(""")', $Asc_or_AscW & '("""")', 0, 1) & '"')
	If $sResult == '' Then Return SetError(1, __HttpRequest_ErrNotify('_HTMLEncode', 'Encode thất bại'), $sData)
	Return $sResult
EndFunc


Func _HTMLDecode($sData, $Escape_Character_Head = '\u', $Escape_Character_Tail = Default, $AnsiDecode = False, $iHexLength = Default, $isHexNumber = True, $iEntities = 1)
	If $sData == '' Then Return ''
	Switch $iEntities
		Case 1
			$sData = __HTML_Entities_Decode($sData, False)
		Case 2
			$sData = __HTML_Entities_Decode($sData, True)
	EndSwitch
	If StringRegExp($sData, '&#[[:xdigit:]]{2};') Then $sData = __HTML_RegexpReplace($sData, '&#', ';', '2', False)
	If StringRegExp($sData, '&#[[:xdigit:]]{3,4};') Then $sData = __HTML_RegexpReplace($sData, '&#', ';', '3,4', False)
	If $iHexLength = Default Then
		If StringRegExp($sData, '\Q' & $Escape_Character_Head & '\E\w{2}(\Q' & $Escape_Character_Head & '\E|$)') Then
			$iHexLength = 2
;~ 		ElseIf StringRegExp($sData, '\Q' & $Escape_Character_Head & '\E\w{4}(\Q' & $Escape_Character_Head & '\E|$)') Then
;~ 			$iHexLength = 4
		ElseIf $Escape_Character_Tail And $Escape_Character_Tail <> Default Then
			$iHexLength = '2,4'
		Else
			$iHexLength = '3,4'
		EndIf
	EndIf
	If $Escape_Character_Tail = Default Then $Escape_Character_Tail = ';?'
	Return __HTML_RegexpReplace($sData, $Escape_Character_Head, $Escape_Character_Tail, $AnsiDecode, $iHexLength, $isHexNumber)
EndFunc


;===============================================================

Func _Cookie_JSON2SemicolonFormat($jsonCookie)     ;Hàm chưa hoàn chỉnh
	Local $aCookie = StringRegExp($jsonCookie, '(?i)"name":"([^"]+)".*?"value":"(.*?)"', 3), $sCookie = ''
	If @error Then Return SetError(1, __HttpRequest_ErrNotify('_Cookie_JSON2SemicolonFormat', 'Không phân tích được cấu trúc $jsonCookie'), '')
	For $i = 0 To UBound($aCookie) - 1 Step 2
		$sCookie &= $aCookie[$i] & '=' & $aCookie[$i + 1] & ';'
	Next
	Return $sCookie
EndFunc


Func _Cookie_Semicolon2JSONFormat($sDomain, $semicolonCookie)
	$sDomain = StringRegExpReplace($sDomain, 'www|https?://', '')
	If StringLeft($sDomain, 1) <> '.' Then $sDomain = '.' & $sDomain
	Local $aCookie = StringSplit($semicolonCookie, ';')
	Local $jsonCookie, $aRegEx
	For $i = 1 To $aCookie[0]
		If StringIsSpace($aCookie[$i]) Then ContinueLoop
		$aRegEx = StringRegExp(StringStripWS($aCookie[$i], 3), '^([^\=]+)=(.*)$', 3)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_Cookie_Semicolon2JSONFormat', 'Không phân tích được cấu trúc $semicolonCookie'), '')
		$jsonCookie &= '{"domain": "' & $sDomain & '","name": "' & $aRegEx[0] & '","value": "' & $aRegEx[1] & '"},'
	Next
	Return '[' & StringTrimRight($jsonCookie, 1) & ']'
EndFunc


Func _HttpRequest_DataFormConvertFromClipboard($iType = 0)
	Local $str_form = @TAB & @TAB & '   ', $sFormData = ClipGet(), $nStringTrimRight = 7, $vHaveFile = 0, $vError = 0
	;---------------------------------------------------------------
	Local $arr_form = StringRegExp($sFormData, '(?im)Content-Disposition: form-data; name="([^"]*?)"\h*?\R\R^(.*?)$', 3)
	If Not @error Then
		For $i = 0 To UBound($arr_form) - 1 Step 2
			If $iType = 0 Then
				$str_form &= '["' & $arr_form[$i] & '", "' & $arr_form[$i + 1] & '"], _' & @CRLF & @TAB & @TAB & '   '
			Else
				$str_form &= '"' & $arr_form[$i] & '=' & $arr_form[$i + 1] & '", _' & @CRLF & @TAB & @TAB & '   '
			EndIf
		Next
	Else
		$vError += 1
	EndIf
	;---------------------------------------------------------------
	$arr_form = StringRegExp($sFormData, '(?im)Content-Disposition: form-data; name="([^"]*?)"\h*?;.*?filename="([^"]*?)"', 3)
	If Not @error Then
		$nStringTrimRight = 0
		$vHaveFile = ($arr_form[1] ? 1 : 0)
		If $iType = 0 Then
			$str_form &= '["$' & $arr_form[0] & '", ' & ($arr_form[1] ? '$FilePath]' : '""]')
		Else
			$str_form &= '"$' & $arr_form[0] & '="' & ($arr_form[1] ? ' & $FilePath' : '')
		EndIf
	Else
		$vError += 1
	EndIf
	;---------------------------------------------------------------
	If $vError = 2 Then
		MsgBox(4096, 'Thông báo', 'Clipboard hiện đang chứa thông tin không liên quan Form Data')
	Else
		ClipPut(($vHaveFile ? @CRLF & 'Local $FilePath = "Đường dẫn tập tin muốn upload" ;Hoặc FileOpenDialog("Tiêu đề", "", "File Extension (*.*)")' & @CRLF & @CRLF : '') & 'Local $FormData = [ _' & @CRLF & StringTrimRight($str_form, $nStringTrimRight) & ' _' & @CRLF & @TAB & @TAB & ']' & @CRLF)
		MsgBox(4096, 'Thông báo', 'Đã lưu kết quả vào Clipboard')
	EndIf
EndFunc


Func _HttpRequest_DetectMIME_Ex($sFilePath)
	Local $aMimeFromData = DllCall("urlmon.dll", "long", "FindMimeFromData", "ptr", 0, 'wstr', $sFilePath, "ptr", 0, 'dword', 0, "ptr", 0, 'dword', 1, "ptr*", 0, 'dword', 0)
	If @error Then
		Return SetError(1, 0, 'application/octet-stream')
	Else
		Local $aStrlenW = DllCall($dll_Kernel32, "int", "lstrlenW", "struct*", $aMimeFromData[7])
		If @error Then Return SetError(2, 0, 'application/octet-stream')
		$aMimeFromData = DllStructGetData(DllStructCreate("wchar[" & $aStrlenW[0] & "]", $aMimeFromData[7]), 1)
		If $aMimeFromData = 0 Then
			Return SetError(3, 0, 'application/octet-stream')
		EndIf
		Return $aMimeFromData
	EndIf
EndFunc

Func _HttpRequest_DetectMIME($sFileName_Or_FilePath)
	Static $sMIMEData = ';ai|application/postscript;aif|audio/x-aiff;aifc|audio/x-aiff;aiff|audio/x-aiff;asc|text/plain;atom|application/atom+xml;au|audio/basic;avi|video/x-msvideo;bcpio|image/bmp;cdf|application/x-netcdf;cgm|image/cgm;class|application/octet-stream/;cpio|application/x-bcpio;bin|application/octet-stream/;bmp|video/x-dv;dir|application/x-director;djv|image/vnd.djvu;djvu|application/x-cpio;cpt|application/mac-compactpro;csh|application/x-csh;css|text/css;dcr|application/x-director;dif|image/vnd.djvu;dll|application/octet-stream/;dmg|application/octet-stream;dms|application/octet-stream;doc|application/msword;dtd|text/x-setext;exe|application/octet-stream/;ez|application/andrew-inset' & _
			';gif|image/gif;gram|audio/midi;latex|application/x-latex;lha|application/octet-stream/;lzh|application/octet-stream/;m3u|audio/mp4a-latm;m4b|text/calendar;ief|image/ief;ifb|text/calendar;iges|model/iges;igs|model/iges;jnlp|application/x-java-jnlp-file;jp2|application/x-sv4cpio;sv4crc|application/x-sv4crc;svg|text/vnd.wap.wmlscript;wmlsc|application/vnd.wap.wmlscriptc;wrl|model/vrml;xbm|image/svg+xml;swf|application/x-shockwave-flash;t|application/x-koan;skt|image/pict;pict|image/pict;png|image/png;pnm|image/x-portable-anymap;pnt|image/x-macpaint;pntg|audio/x-pn-realaudio;ras|image/x-cmu-raster;rdf|image/x-macpaint;ppm|image/x-portable-pixmap;ppt|application/vnd.ms-powerpoint' & _
			';ps|application/postscript;qt|application/rdf+xml;rgb|application/x-futuresplash;src|video/quicktime;qti|image/x-quicktime;qtif|image/x-quicktime;ra|audio/x-pn-realaudio;ram|application/vnd.rn-realmedia;roff|application/x-troff;rtf|text/rtf;rtx|text/sgml;sh|application/x-sh;shar|application/x-shar;silo|model/mesh;sit|application/x-stuffit;skd|application/x-tcl;tex|application/x-tex;texi|application/x-texinfo;texinfo|application/x-texinfo;tif|image/tiff;tiff|image/tiff;tr|application/x-troff;tsv|text/tab-separated-values;txt|text/plain;ustar|application/smil;snd|audio/basic;so|application/x-ustar;vcd|model/vrml;vxml|image/vnd.wap.wbmp;wbmxl|application/vnd.wap.wbxml;wml|text/vnd.wap.wml;wmlc|application/vnd.wap.wmlc' & _
			';wmls|application/octet-stream/;spl|application/x-cdlink;vrml|image/x-xbitmap;xht|application/xhtml+xml;xhtml|application/xhtml+xml;xls|application/vnd.ms-excel;xml|application/voicexml+xml;wav|audio/wav;skm|application/xml;xpm|application/xml-dtd;dv|video/x-dv;dvi|application/x-dvi;dxr|application/x-director;eps|application/postscript;etx|application/octet-stream/;dms|application/octet-stream/;doc|application/x-gtar;hdf|application/x-hdf;hqx|application/mac-binhex40;htm|text/html;html|text/html;ice|x-conference/x-cooltalk;ico|image/x-icon;ics|application/srgs;grxml|application/srgs+xml;gtar|image/jp2;jpe|image/jpeg;jpeg|image/jpeg;jpg|image/jpeg;js|application/x-javascript;kar|application/x-wais-source' & _
			';sv4cpio|text/richtext;sgm|text/sgml;sgml|audio/x-mpegurl;m4a|audio/mp4a-latm;m4p|audio/mp4a-latm;m4u|video/vnd.mpegurl;m4v|application/x-troff;tar|application/x-tar;tcl|audio/x-wav;wbmp|video/x-m4v;mac|image/x-macpaint;man|application/x-troff-man;mathml|application/mathml+xml;me|application/xslt+xml;xul|application/vnd.mozilla.xul+xml;xwd|application/x-troff-me;mesh|model/mesh;mid|audio/midi;midi|audio/midi;mif|application/vnd.mif;mov|image/x-portable-graymap;pgn|application/x-chess-pgn;pic|video/quicktime;movie|video/x-sgi-movie;mp2|audio/mpeg;mp3|audio/mpeg;mp4|video/mp4;mpe|video/mpeg;mpeg|image/x-xwindowdump;xyz|video/mpeg;mpg|video/mpeg;mpga|audio/mpeg' & _
			';ms|application/x-troff-ms;msh|model/mesh;mxu|video/vnd.mpegurl;nc|application/x-koan;smi|application/smil;smil|application/x-netcdf;oda|application/oda;ogg|application/ogg;pbm|image/x-portable-bitmap;pct|image/pict;pdb|chemical/x-pdb;pdf|application/pdf;pgm|image/x-rgb;rm|application/x-koan;skp|image/x-xpixmap;xsl|application/xml;xslt|chemical/x-xyz;zip|application/zip;xlsx|application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;doc|application/msword;dot|application/msword;docx|application/vnd.openxmlformats-officedocument.wordprocessingml.document;dotx|application/vnd.openxmlformats-officedocument.wordprocessingml.template;docm|application/vnd.ms-word.document.macroEnabled.12' & _
			';dotm|application/vnd.ms-word.template.macroEnabled.12;xls|application/vnd.ms-excel;xlt|application/vnd.ms-excel;xla|application/vnd.ms-excel;xltx|application/vnd.openxmlformats-officedocument.spreadsheetml.template;xlsm|application/vnd.ms-excel.sheet.macroEnabled.12;xltm|application/vnd.ms-excel.template.macroEnabled.12;xlam|application/vnd.ms-excel.addin.macroEnabled.12;xlsb|application/vnd.ms-excel.sheet.binary.macroEnabled.12;ppt|application/vnd.ms-powerpoint;pot|application/vnd.ms-powerpoint;pps|application/vnd.ms-powerpoint;ppa|application/vnd.ms-powerpoint;pptx|application/vnd.openxmlformats-officedocument.presentationml.presentation;potx|application/vnd.openxmlformats-officedocument.presentationml.template;ppsx|application/vnd.openxmlformats-officedocument.presentationml.slideshow;ppam|application/vnd.ms-powerpoint.addin.macroEnabled.12;pptm|application/vnd.ms-powerpoint.presentation.macroEnabled.12;potm|application/vnd.ms-powerpoint.template.macroEnabled.12;ppsm|application/vnd.ms-powerpoint.slideshow.macroEnabled.12;flac|audio/flac;'
	;-----------------------------------------------------------------------------------------------------
	Local $aArray = StringRegExp($sMIMEData, "(?i)\Q;" & StringRegExpReplace($sFileName_Or_FilePath, "(.*?)\.(\w+)$", "$2") & "\E\|(.*?);", 1)
	If @error Then
		If FileExists($sFileName_Or_FilePath) Then
			Local $fOpen = FileOpen($sFileName_Or_FilePath, 512)
			Switch FileRead($fOpen, 4)
				Case 'ÿØÿà'
					Return 'image/jpg'
				Case '‰PNG'
					Return 'image/png'
				Case 'BMN'
					Return 'image/bmp'
			EndSwitch
			FileClose($fOpen)
		EndIf
		Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_DetectMIME', 'Không thể tra MIME của loại tập tin này. MIME sẽ được trả về mặc định là: application/octet-stream'), 'application/octet-stream')
	Else
		Return $aArray[0]
	EndIf
EndFunc


Func _GetFreeProxy($sFilePathToExport = '', $iGetFastProxyList = False, $vIncludeDateInHeader = False)
	Local $aLink = StringRegExp(_HttpRequest(2, 'http://www.proxyserverlist24.top/'), "(?i)href='(http://www.proxyserverlist24.top/.*?([\d\-]+)-" & ($iGetFastProxyList ? 'fast' : 'free') & "-proxy-server-list.*?\.html)'", 1)
	If @error Then Return SetError(1, __HttpRequest_ErrNotify('_GetFreeProxy', 'Không tìm thấy đường dẫn lấy Proxy List'), '')
	Local $asProxy = StringRegExp(_HttpRequest(2, $aLink[0]), '(?ms)^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d+\R.+\R^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\:\d+', 1)
	If @error Then Return SetError(2, __HttpRequest_ErrNotify('_GetFreeProxy', 'Không tách được danh sách Proxy'), '')
	If $sFilePathToExport Then
		Local $hFileOpen = FileOpen($sFilePathToExport, 2 + 8)
		FileWrite($hFileOpen, ($vIncludeDateInHeader ? StringReplace($aLink[1], '-', '', 0, 1) & @CRLF : '') & $asProxy[0])
		FileClose($hFileOpen)
	EndIf
	Return SetExtended(StringReplace($aLink[1], '-', '', 0, 1), StringSplit(StringStripCR($asProxy[0]), @LF))
EndFunc


Func _GetCertificateInfo($iSession = Default)
	If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
	If Not $g___hRequest[$iSession] Then Return SetError(1, __HttpRequest_ErrNotify('_GetCertificateInfo', 'Phải thực hiện request đến trang đích trước'), '')
	Local $tBuffer = _WinHttpQueryOptionEx2($g___hRequest[$iSession], 32)
	If @error Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_CertificateInfo', 'Yêu cầu phải là https mới lấy được thông tin Certificate'), '')
	Local $tCertInfo = DllStructCreate("dword ExpiryTime[2]; dword StartTime[2]; ptr SubjectInfo; ptr IssuerInfo; ptr ProtocolName; ptr SignatureAlgName; ptr EncryptionAlgName; dword KeySize", DllStructGetPtr($tBuffer))
	Return DllStructGetData(DllStructCreate("wchar[256]", DllStructGetData($tCertInfo, "IssuerInfo")), 1)
EndFunc


Func _GetNameDNS($iSession = Default)
	If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
	If Not $g___hRequest[$iSession] Then Return SetError(1, __HttpRequest_ErrNotify('_GetNameDNS', 'Phải thực hiện request đến trang đích trước'), '')
	Local $tBuffer, $pCert_Context, $tCert_Info, $tCert_Encoding, $tCert_Ext, $aCall
	$tBuffer = DllStructCreate("ptr")
	DllCall($dll_WinHttp, "bool", 'WinHttpQueryOption', "handle", $g___hRequest[$iSession], "dword", 78, "struct*", $tBuffer, "dword*", DllStructGetSize($tBuffer))
	If @error Then Return SetError(2, __HttpRequest_ErrNotify('_GetNameDNS', 'Cài đặt option lấy DNS thất bại. Yêu cầu phải là https mới lấy được DNS'), '')
	$pCert_Context = DllStructGetData($tBuffer, 1)
	$tCert_Encoding = DllStructCreate("dword dwCertEncodingType; ptr pbCertEncoded; dword cbCertEncoded; ptr pCertInfo; handle hCertStore", $pCert_Context)
	Static $sCertInfo = StringReplace(StringReplace(StringReplace(StringReplace('«dw dwVersion; «dw SerialNumber_cbData; p SerialNumber_pbData»; «p SignatureAlgorithm_pszObjId; «dw SignatureAlgorithm_Parameters_cbData; p SignatureAlgorithm_Parameters_pbData»»; «dw Issuer_cbData; p Issuer_pbData»; «dw NotBefore_dwLowDateTime; dw NotBefore_dwHighDateTime»; «dw NotAfter_dwLowDateTime; dw NotAfter_dwHighDateTime»; «dw Subject_cbData; p Subject_pbData»; ««p SubjectPublicKeyInfo_Algorithm_pszObjId; «dw SubjectPublicKeyInfo_Parameters_cbData; p SubjectPublicKeyInfo_Parameters_pbData»»; «dw SubjectPublicKeyInfo_PublicKey_cbData; p ParametersSubjectPublicKeyInfo_pbData; dw SubjectPublicKeyInfo_PublicKey_cUnusedBits»»; «dw IssuerUniqueId_cbData; p IssuerUniqueId_pbData; dw IssuerUniqueId_cUnusedBits»; «dw dwSubjectUniqueId_cbData; p SubjectUniqueId_pbData; dw SubjectUniqueId_cUnusedBits»; dw cExtension; p rgExtension»;', 'dw ', 'dword '), 'p ', 'ptr '), '«', 'struct;'), '»', ';endstruct')
	$tCert_Info = DllStructCreate($sCertInfo, DllStructGetData($tCert_Encoding, 'pCertInfo'))
	$aCall = DllCall("Crypt32.dll", "ptr", "CertFindExtension", "str", "2.5.29.17", "dword", DllStructGetData($tCert_Info, 'cExtension'), "ptr", DllStructGetData($tCert_Info, 'rgExtension'))
	If @error Then Return SetError(3, __HttpRequest_ErrNotify('_GetNameDNS', 'Không tìm thấy Chứng nhận của DNS'), '')
	$tCert_Ext = DllStructCreate("struct;ptr pszObjId;bool fCritical;struct;dword Value_cbData;ptr Value_pbData;endstruct;endstruct;", $aCall[0])
	$aCall = DllCall("Crypt32.dll", "int", "CryptFormatObject", "dword", 1, "dword", 0, "dword", 1, "ptr", 0, "ptr", DllStructGetData($tCert_Ext, 'pszObjId'), "ptr", DllStructGetData($tCert_Ext, 'Value_pbData'), "dword", DllStructGetData($tCert_Ext, 'Value_cbData'), 'wstr', "", "dword*", 65536)
	If @error Then Return SetError(4, __HttpRequest_ErrNotify('_GetNameDNS', 'Không định dạng được Chứng nhận của DNS'), '')
	DllCall("Crypt32.dll", "dword", "CertFreeCertificateContext", "ptr", $pCert_Context)
	Return StringReplace($aCall[8], 'DNS Name=', '')
EndFunc


Func _GetCookie($sHeader = '', $iSession = Default, $iTrimCookie = True, $Excluded_Values = '')
	If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
	If $sHeader == '' Or $sHeader = Default Or ($sHeader And StringLeft($sHeader, 5) <> 'HTTP/') Then
		If $g___retData[$g___LastSession][0] Then
			$sHeader = $g___retData[$g___LastSession][0]
		ElseIf IsPtr($g___hRequest[$iSession]) Then
			$sHeader = _WinHttpQueryHeaders2($g___hRequest[$iSession], 22)
			If @error Or $sHeader == '' Then Return SetError(1, __HttpRequest_ErrNotify('_GetCookie', 'Không truy vấn được Response Headers'), '')
		EndIf
	EndIf
	Local $__aRH = StringRegExp($sHeader, '(?im)^Set-Cookie:\h*?([^=]+)=(?!deleted;)(.*)$', 3)
	If @error Or Not IsArray($__aRH) Then Return SetError(2, __HttpRequest_ErrNotify('_GetCookie', 'Không tìm thấy header Set-Cookie từ Response'), '')
	;----------------------------------------------------------------------------------
	Local $__sRH = '', $__uBound = UBound($__aRH)
	For $i = $__uBound - 2 To 0 Step -2
		If $__aRH[$i] == '' Or ($Excluded_Values And StringInStr('|' & $Excluded_Values & '|', '|' & StringStripWS($__aRH[$i], 3) & '|')) Then ContinueLoop
		$__sRH = $__aRH[$i] & '=' & $__aRH[$i + 1] & '; ' & $__sRH
		For $k = 0 To $i Step 2
			If $__aRH[$k] == $__aRH[$i] Then $__aRH[$k] = ''
		Next
	Next
	;----------------------------------------------------------------------------------
	If $iTrimCookie Then
		Local $aOptionalFilter = 'priority\h*?=\h*?(?:high|low)|Expires\h*?=\h*?|Path\h*?=\h*?|Domain\h*?=\h*?|Max-age\h*?=\h*?|SameSite\h*?=\h*?|HttpOnly|Secure'
		$__sRH = StringRegExpReplace(StringRegExpReplace($__sRH, '(?i);\h*?(' & $aOptionalFilter & ')([^;]*)', ';'), '(?:;\h?){2,}', ';')
	EndIf
	;----------------------------------------------------------------------------------
	Return StringStripWS($__sRH, 3) & ' '
EndFunc


Func _GetLocationRedirect($sHeader = '', $iIndex = -1, $iSession = Default)
	If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
	If Not $sHeader Or $sHeader = Default Or ($sHeader And StringLeft($sHeader, 5) <> 'HTTP/') Then
		If $g___retData[$iSession][0] Then
			$sHeader = $g___retData[$iSession][0]
		ElseIf $g___LocationRedirect Then
			Return $g___LocationRedirect
		ElseIf IsPtr($g___hRequest[$iSession]) Then
			$sHeader = _WinHttpQueryHeaders2($g___hRequest[$iSession], 22)
			If @error Or $sHeader == '' Then Return SetError(1, __HttpRequest_ErrNotify('_GetLocationRedirect', 'Không truy vấn được Response Headers'), '')
		Else
			Return SetError(2, __HttpRequest_ErrNotify('_GetLocationRedirect', 'Lỗi không xác định'), '')
		EndIf
	EndIf
	Local $__aRH = StringRegExp($sHeader, '(?im)^Location:\h?(.+)$', 3)
	If @error Or Not IsArray($__aRH) Then Return SetError(3, __HttpRequest_ErrNotify('_GetLocationRedirect', 'Không tìm thấy header Location từ Response', '', 'Warning'), '')
	Local $uBoundRH = UBound($__aRH) - 1
	For $i = 0 To $uBoundRH
		If $g___LocationRedirect And StringLen($__aRH[$i]) > 4 And StringRegExp($g___LocationRedirect, '\Q' & $__aRH[$i] & '\E$') Then $__aRH[$i] = $g___LocationRedirect
	Next
	If $iIndex < 0 Or $iIndex > $uBoundRH Or $iIndex = Default Or $iIndex == '' Then $iIndex = $uBoundRH
	Return StringStripWS($__aRH[$iIndex], 3)
EndFunc


Func _GetIPAndGeoInfo($iIP = Default)
	If $iIP = Default Then $iIP = $g___ServerIP
	If $iIP = '' Then Return SetError(1, __HttpRequest_ErrNotify('_GetIPAndGeoInfo', 'Không tìm thấy IP - Phải request đến trang đích trước khi sử dụng hàm này hoặc nhập 1 IP bạn biết vào'), '')
	Local $sHTML = _HttpRequest(2, 'https://gfx.robtex.com/ipinfo.js?ip=' & $iIP)
	Local $aInfo = [$iIP, 'country', 'city', 'asname', 'net', 'netdescr', 'as'], $regSource
	For $i = 1 To 6
		$regSource = StringRegExp($sHTML, '(?i)\(m\h*?==?\h*?"' & $aInfo[$i] & '"\)\h*?a.innerHTML\h*?=\h*?"\,?\h?(.*?)"', 1)
		If @error Then Return SetError(2, __HttpRequest_ErrNotify('_GetIPAndGeoInfo', 'Không tìm được thông tin từ IP'), $iIP)
		$aInfo[$i] = $regSource[0]
	Next
	Return $aInfo
EndFunc


Func _GetFileInfo($sFilePath, $vDataTypeReturn = 1)     ; 2: Base64, 1: String, 0: Binary
	If Not FileExists($sFilePath) Then Return SetError(1, __HttpRequest_ErrNotify('_GetFileInfo', 'Đường dẫn tập tin không tồn tại'), '')
	If $vDataTypeReturn = Default Or $vDataTypeReturn == '' Then $vDataTypeReturn = 1
	Local $sFileName = StringRegExp($sFilePath, '[\\\/]([^\\\/]+\.\w+)$', 1)
	If @error Then
		$sFileName = StringRegExp($sFilePath, '^([^\\\/]+\.\w+)$', 1)
		If @error Then Return SetError(2, __HttpRequest_ErrNotify('_GetFileInfo', 'Không tách được tên tập tin từ đường dẫn'), '')
		$sFilePath = @ScriptDir & '\' & $sFileName[0]
	EndIf
	$sFileName = $sFileName[0]
	Local $hFileOpen = FileOpen($sFilePath, 16)
	If @error Then Return SetError(3, __HttpRequest_ErrNotify('_GetFileInfo', 'Không thể mở tập tin'), '')
	Local $sFileData = FileRead($hFileOpen)
	FileClose($hFileOpen)
	Local $sFileType = _HttpRequest_DetectMIME($sFileName)
	Switch $vDataTypeReturn
		Case 2
			$sFileData = _B64Encode($sFileData, 0, True, True)
			$sFileType &= ';base64'
		Case 1
			$sFileData = BinaryToString($sFileData)
	EndSwitch
	Local $aReturn[4] = [$sFileName, $sFileType, $sFileData, FileGetSize($sFilePath)]
	Return $aReturn
EndFunc


Func _GetHttpTime($sHttpTime = '')
	Local $tSystemTime = DllStructCreate('word Year;word Month;word DayOfWeek;word Day;word Hour;word Minute;word Second;word Milliseconds')
	Local $tTime = DllStructCreate("wchar[62]")
	If $sHttpTime Then
		DllStructSetData($tTime, 1, $sHttpTime)
		Local $aCall = DllCall($dll_WinHttp, "bool", 'WinHttpTimeToSystemTime', "struct*", $tTime, "struct*", $tSystemTime)
		If @error Or Not $aCall[0] Then Return SetError(3, __HttpRequest_ErrNotify('_GetHttpTime', 'Không thể gọi chức năng WinHttpTimeToSystemTime của WinHttp'), "")
		Local $aRet[6]
		For $i = 0 To 5
			$aRet[$i] = DllStructGetData($tSystemTime, $i + ($i < 2 ? 1 : 2))
		Next
		Return SetError(0, 0, $aRet)
	Else
		DllCall($dll_Kernel32, "none", "GetSystemTime", "struct*", $tSystemTime)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_GetHttpTime', 'Không thế truy vấn Time hệ thống'), "")
		Local $aCall = DllCall($dll_WinHttp, "bool", 'WinHttpTimeFromSystemTime', "struct*", $tSystemTime, "struct*", $tTime)
		If @error Or Not $aCall[0] Then Return SetError(2, __HttpRequest_ErrNotify('_GetHttpTime', 'Không thể gọi chức năng WinHttpTimeFromSystemTime của WinHttp'), "")
		Return DllStructGetData($tTime, 1)
	EndIf
EndFunc


Func _GetTimeStamp($Include_MSec = False, $sDateTime = Default)     ;D/M/YYYY h:m:s
	If $sDateTime = Default Or $sDateTime = '' Then
		Local $tSystemTime = DllStructCreate('struct;word Year;word Month;word Dow;word Day;word Hour;word Minute;word Second;word MSeconds;endstruct')
		DllCall($dll_Kernel32, "none", "GetSystemTime", "struct*", $tSystemTime)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_GetTimeStamp', 'GetSystemTime thất bại'), '')
		Local $aInfo[7] = [DllStructGetData($tSystemTime, "Day"), DllStructGetData($tSystemTime, "Month"), DllStructGetData($tSystemTime, "Year"), DllStructGetData($tSystemTime, "Hour"), DllStructGetData($tSystemTime, "Minute"), DllStructGetData($tSystemTime, "Second"), DllStructGetData($tSystemTime, "MSeconds")]
	Else
		Local $aInfo = StringRegExp($sDateTime, '\d+', 3)
		If @error Or (UBound($aInfo) <> 6 And UBound($aInfo) <> 7) Then
			Return SetError(2, __HttpRequest_ErrNotify('_GetTimeStamp', '$sDateTime không đúng định dạng (phải là: D/M/YYYY h:m:s hoặc D/M/YYYY h:m:s:ms hoặc D/M/YYYY h:m:s.ms)'), '')
		EndIf
		ReDim $aInfo[7]
	EndIf
	;----------------------------------------------
	If $Include_MSec Then
		If $aInfo[6] = '' Then $aInfo[6] = @MSEC
	Else
		$aInfo[6] = 0
	EndIf
	$aInfo[2] -= ($aInfo[1] < 3 ? 1 : 0)
	;----------------------------------------------
	Return ((Int(Int($aInfo[2] / 100) / 4) - Int($aInfo[2] / 100) + $aInfo[0] + Int(365.25 * ($aInfo[2] + 4716)) + Int(30.6 * (($aInfo[1] < 3 ? $aInfo[1] + 12 : $aInfo[1]) + 1)) - 2442110) * 86400 + ($aInfo[3] * 3600 + $aInfo[4] * 60 + $aInfo[5])) * ($Include_MSec ? 1000 : 1) + $aInfo[6]
EndFunc


Func _GetTimeStampOnline($IncludeMSEC = False, $DecodeToDate = False, $UseLocalTime = False)
	Local $TimeStamp = StringRegExp(_HttpRequest(2, 'https://time-ak.alicdn.com/t/gettime'), '\d{10}', 1)
	If @error Then
		Local $TimeStamp = StringRegExp(_HttpRequest(2, 'https://72xbor.tdum.alibaba.com/dss.js'), '\d{10}', 1)
		If @error Then
			$TimeStamp = StringRegExp(_HttpRequest(2, 'https://www.timeanddate.com/scripts/ts.php'), '(\d{10})\.(\d{3})', 3)
			If @error Then Return SetError(1, __HttpRequest_ErrNotify('_GetTimeStampOnline', 'Không get được timestamp từ các server'), '')
		EndIf
	EndIf
	$TimeStamp = $TimeStamp[0] & ($IncludeMSEC ? (UBound($TimeStamp) = 2 ? $TimeStamp[1] : @MSEC) : '')
	If $DecodeToDate Then $TimeStamp = _GetDateFromTimeStamp($TimeStamp, $UseLocalTime)
	Return $TimeStamp
EndFunc


Func _GetDateFromTimeStamp($iTimeStamp, $vLocalTime = False)
	Local $Msec = 0
	If StringLen($iTimeStamp) = 13 Then
		$Msec = Mod($iTimeStamp, 1000)
		$iTimeStamp = Floor($iTimeStamp / 1000)
	EndIf
	Local $iDayToAdd = Int($iTimeStamp / 86400), $iTimeVal = Mod($iTimeStamp, 86400)
	If $iTimeVal < 0 Then
		$iDayToAdd -= 1
		$iTimeVal += 86400
	EndIf
	Local $i_wFactor = Int((573371.75 + $iDayToAdd) / 36524.25), $i_bFactor = 2442113 + $iDayToAdd + $i_wFactor - Int($i_wFactor / 4), $i_cFactor = Int(($i_bFactor - 122.1) / 365.25), $i_dFactor = Int(365.25 * $i_cFactor), $i_eFactor = Int(($i_bFactor - $i_dFactor) / 30.6001), $aDatePart[3], $aTimePart[3]
	$aDatePart[2] = $i_bFactor - $i_dFactor - Int(30.6001 * $i_eFactor)
	$aDatePart[1] = $i_eFactor - 1 - 12 * ($i_eFactor - 2 > 11)
	$aDatePart[0] = $i_cFactor - 4716 + ($aDatePart[1] < 3)
	$aTimePart[0] = Int($iTimeVal / 3600)
	$iTimeVal = Mod($iTimeVal, 3600)
	$aTimePart[1] = Int($iTimeVal / 60)
	$aTimePart[2] = Mod($iTimeVal, 60)
	If $vLocalTime Then
		Local $tUTC = DllStructCreate('struct;word Year;word Month;word Dow;word Day;word Hour;word Minute;word Second;word MSeconds;endstruct')
		DllStructSetData($tUTC, "Month", $aDatePart[1])
		DllStructSetData($tUTC, "Day", $aDatePart[2])
		DllStructSetData($tUTC, "Year", $aDatePart[0])
		DllStructSetData($tUTC, "Hour", $aTimePart[0])
		DllStructSetData($tUTC, "Minute", $aTimePart[1])
		DllStructSetData($tUTC, "Second", $aTimePart[2])
		Local $tLocal = DllStructCreate('struct;word Year;word Month;word Dow;word Day;word Hour;word Minute;word Second;word MSeconds;endstruct')
		DllCall($dll_Kernel32, "bool", "SystemTimeToTzSpecificLocalTime", "struct*", 0, "struct*", DllStructGetPtr($tUTC), "struct*", $tLocal)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_GetDateFromTimeStamp', 'Chuyển SystemTime sang LocalTime thất bại'), '')
		$aDatePart[2] = DllStructGetData($tLocal, "Day")
		$aDatePart[1] = DllStructGetData($tLocal, "Month")
		$aDatePart[0] = DllStructGetData($tLocal, "Year")
		$aTimePart[0] = DllStructGetData($tLocal, "Hour")
		$aTimePart[1] = DllStructGetData($tLocal, "Minute")
		$aTimePart[2] = DllStructGetData($tLocal, "Second")
	EndIf
	Return StringFormat("%02d/%02d/%04d %02d:%02d:%02d", $aDatePart[2], $aDatePart[1], $aDatePart[0], $aTimePart[0], $aTimePart[1], $aTimePart[2]) & ($Msec > 0 ? ':' & $Msec : '')
EndFunc


Func _B64Encode($binaryData, $iLinebreak = 0, $safeB64 = False, $iRunByMachineCode = True, $iCompressData = False)
	If $binaryData == '' Then Return SetError(1, __HttpRequest_ErrNotify('_B64Encode', '$binaryData rỗng'), '')
	$iLinebreak = Number($iLinebreak)
	If $iLinebreak = Default Then $iLinebreak = 0
	If $safeB64 = Default Then $safeB64 = False
	If $iRunByMachineCode = Default Then $iRunByMachineCode = False
	;----------------------------------------------------------------------------------------
	If $iCompressData Then $binaryData = __LZNT_Compress($binaryData)
	If Not $iRunByMachineCode Then
		Local $lenData = StringLen($binaryData) - 2, $iOdd = Mod($lenData, 3), $spDec = '', $base64Data = ''
		For $i = 3 To $lenData - $iOdd Step 3
			$spDec = Dec(StringMid($binaryData, $i, 3))
			$base64Data &= $g___aChr64[$spDec / 64] & $g___aChr64[Mod($spDec, 64)]
		Next
		If $iOdd Then
			$spDec = BitShift(Dec(StringMid($binaryData, $i, 3)), -8 / $iOdd)
			$base64Data &= $g___aChr64[$spDec / 64] & ($iOdd = 2 ? $g___aChr64[Mod($spDec, 64)] & $g___sPadding & $g___sPadding : $g___sPadding)
		EndIf
	Else
		Local $tStruct = DllStructCreate("byte[" & BinaryLen($binaryData) & "]")
		DllStructSetData($tStruct, 1, $binaryData)
		Local $tsInt = DllStructCreate("int")
		Local $a_Call = DllCall("Crypt32.dll", "int", "CryptBinaryToString", "ptr", DllStructGetPtr($tStruct), "int", DllStructGetSize($tStruct), "int", 1, "ptr", 0, "ptr", DllStructGetPtr($tsInt))
		If @error Or Not $a_Call[0] Then Return SetError(2, __HttpRequest_ErrNotify('_B64Encode', 'Gọi chức năng CryptBinaryToString từ Crypt32.dll thất bại #1'), $binaryData)
		Local $tsChr = DllStructCreate("char[" & DllStructGetData($tsInt, 1) & "]")
		$a_Call = DllCall("Crypt32.dll", "int", "CryptBinaryToString", "ptr", DllStructGetPtr($tStruct), "int", DllStructGetSize($tStruct), "int", 1, "ptr", DllStructGetPtr($tsChr), "ptr", DllStructGetPtr($tsInt))
		If @error Or Not $a_Call[0] Then Return SetError(3, __HttpRequest_ErrNotify('_B64Encode', 'Gọi chức năng CryptBinaryToString từ Crypt32.dll thất bại #2'), $binaryData)
		Local $base64Data = StringStripWS(DllStructGetData($tsChr, 1), 8)
	EndIf
	If $iLinebreak Then
		$base64Data = StringRegExpReplace($base64Data, '(.{' & $iLinebreak & '})', '${1}' & @LF)
		If StringRight($base64Data, 1) == @LF Then $base64Data = StringTrimRight($base64Data, 1)
	EndIf
	If $safeB64 Then $base64Data = StringReplace(StringReplace($base64Data, '+', '-', 0, 1), '/', '_', 0, 1)
	Return $base64Data
EndFunc


Func _B64Decode($base64Data, $iRunByMachineCode = True, $iUnCompressData = False)
	If $base64Data == '' Then Return SetError(1, __HttpRequest_ErrNotify('_B64Decode', '$base64Data rỗng'), '')
	If $iRunByMachineCode = Default Then $iRunByMachineCode = False
	$base64Data = StringStripWS($base64Data, 8)
	$base64Data = StringRegExpReplace(StringReplace($base64Data, '\/', '/', 0, 1), '(\\r\\n|\%0D\%0A)', '')
	If StringRight($base64Data, 3) = '%3D' Then $base64Data = _URIDecode($base64Data)
	;----------------------------------------------------------------------------------------
	If Not $iRunByMachineCode Then
		If Mod(StringLen($base64Data), 2) Then Return SetError(2, __HttpRequest_ErrNotify('_B64Decode', '$base64Data không phải là dữ liệu kiểu B64'), $base64Data)
		Local $aData = StringSplit($base64Data, ''), $binaryData = '0x', $iOdd = UBound(StringRegExp($base64Data, $g___sPadding, 3))
		For $i = 1 To $aData[0] - $iOdd * 2 Step 2
			$binaryData &= Hex((StringInStr($g___sChr64, $aData[$i], 1, 1) - 1) * 64 + StringInStr($g___sChr64, $aData[$i + 1], 1, 1) - 1, 3)
		Next
		If $iOdd Then $binaryData &= Hex(BitShift((StringInStr($g___sChr64, $aData[$i], 1, 1) - 1) * 64 + ($iOdd - 1) * (StringInStr($g___sChr64, $aData[$i + 1], 1, 1) - 1), 8 / $iOdd), $iOdd)
	Else
		Local $tStruct = DllStructCreate("int")
		Local $a_Call = DllCall("Crypt32.dll", "int", "CryptStringToBinary", "str", $base64Data, "int", 0, "int", 1, "ptr", 0, "ptr", DllStructGetPtr($tStruct, 1), "ptr", 0, "ptr", 0)
		If @error Or Not $a_Call[0] Then Return SetError(3, __HttpRequest_ErrNotify('_B64Decode', 'Gọi chức năng CryptStringToBinary từ Crypt32.dll thất bại #1'), $base64Data)
		Local $tsByte = DllStructCreate("byte[" & DllStructGetData($tStruct, 1) & "]")
		$a_Call = DllCall("Crypt32.dll", "int", "CryptStringToBinary", "str", $base64Data, "int", 0, "int", 1, "ptr", DllStructGetPtr($tsByte), "ptr", DllStructGetPtr($tStruct, 1), "ptr", 0, "ptr", 0)
		If @error Or Not $a_Call[0] Then Return SetError(4, __HttpRequest_ErrNotify('_B64Decode', 'Gọi chức năng CryptStringToBinary từ Crypt32.dll thất bại #2'), $base64Data)
		Local $binaryData = DllStructGetData($tsByte, 1)
	EndIf
	If $iUnCompressData Then $binaryData = __LZNT_Decompress($binaryData)
	Return $binaryData
EndFunc


Func _B64SetupDatabase($___sChr64, $___sPadding = '=')
	If StringInStr($___sChr64, $___sPadding, 1, 1) Then Return SetError(1, __HttpRequest_ErrNotify('_B64SetupDatabase', 'Tham số $___sChr64 không được bao gồm dấu ='), False)
	Local $___aChr64 = StringSplit($___sChr64, "", 2)
	Local $___iCounter = 0, $___uBound = UBound($___aChr64) - 1
	If $___uBound <> 63 Then Return SetError(2, __HttpRequest_ErrNotify('_B64SetupDatabase', 'Tham số $___sChr64 phải là chuỗi dài 64 ký tự'), False)
	For $i = 0 To $___uBound
		For $k = 0 To $___uBound
			If $___aChr64[$i] == $___aChr64[$k] Then $___iCounter += 1
		Next
		If $___iCounter = 2 Then Return SetError(3, __HttpRequest_ErrNotify('_B64SetupDatabase', 'Cài đặt Database thất bại'), False)
		$___iCounter = 0
	Next
	$g___sChr64 = $___sChr64
	$g___aChr64 = $___aChr64
	$g___sPadding = $___sPadding
	Return True
EndFunc



#Region Crypt
	Func __LZNT_Decompress($bBinary)
		$bBinary = Binary($bBinary)
		Local $tInput = DllStructCreate("byte[" & BinaryLen($bBinary) & "]")
		DllStructSetData($tInput, 1, $bBinary)
		Local $tBuffer = DllStructCreate("byte[" & 16 * DllStructGetSize($tInput) & "]")
		Local $a_Call = DllCall("ntdll.dll", "int", "RtlDecompressBuffer", "ushort", 2, "ptr", DllStructGetPtr($tBuffer), "dword", DllStructGetSize($tBuffer), "ptr", DllStructGetPtr($tInput), "dword", DllStructGetSize($tInput), "dword*", 0)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('__LZNT_Decompress', ' Decompress Buffer thất bại'), '')
		Local $tOutput = DllStructCreate("byte[" & $a_Call[6] & "]", DllStructGetPtr($tBuffer))
		Return SetError(0, 0, DllStructGetData($tOutput, 1))
	EndFunc

	Func __LZNT_Compress($bBinary)
		$bBinary = Binary($bBinary)
		Local $tInput = DllStructCreate("byte[" & BinaryLen($bBinary) & "]")
		DllStructSetData($tInput, 1, $bBinary)
		Local $a_Call = DllCall("ntdll.dll", "int", "RtlGetCompressionWorkSpaceSize", "ushort", 2, "dword*", 0, "dword*", 0)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('__LZNT_Compress', 'Tạo WorkSpace thất bại'), "")
		Local $tWorkSpace = DllStructCreate("byte[" & $a_Call[2] & "]")
		Local $tBuffer = DllStructCreate("byte[" & 16 * DllStructGetSize($tInput) & "]")
		Local $a_Call = DllCall("ntdll.dll", "int", "RtlCompressBuffer", "ushort", 2, "ptr", DllStructGetPtr($tInput), "dword", DllStructGetSize($tInput), "ptr", DllStructGetPtr($tBuffer), "dword", DllStructGetSize($tBuffer), "dword", 4096, "dword*", 0, "ptr", DllStructGetPtr($tWorkSpace))
		If @error Then Return SetError(2, __HttpRequest_ErrNotify('__LZNT_Compress', 'Compress Buffer thất bại'), '')
		Local $tOutput = DllStructCreate("byte[" & $a_Call[7] & "]", DllStructGetPtr($tBuffer))
		Return SetError(0, 0, DllStructGetData($tOutput, 1))
	EndFunc

	Func _GetMD5($sFilePath_or_Data)
		Return _GetHash($sFilePath_or_Data, 0x00008003)
	EndFunc

	Func _GetSHA256($sFilePath_or_Data)
		Return _GetHash($sFilePath_or_Data, 0x0000800c)
	EndFunc

	Func _GetSHA1($sFilePath_or_Data)
		Return _GetHash($sFilePath_or_Data, 0x00008004)
	EndFunc

	Func _GetHash($sFilePath_or_Data, $iAlgID)
		If StringRegExp($sFilePath_or_Data, '(?i)^[A-Z]:\') And FileExists($sFilePath_or_Data) Then
			Return StringLower(Hex(_Crypt_HashFile($sFilePath_or_Data, $iAlgID)))
		Else
			$sFilePath_or_Data = StringToBinary($sFilePath_or_Data, 4)
			Return StringLower(Hex(_Crypt_HashData($sFilePath_or_Data, $iAlgID)))
		EndIf
	EndFunc

	Func _GetHMAC_Ex($bData, $bKey, $sAlgorithm = 'SHA256', $bRaw_Output = False)     ;$sAlgorithm = SHA512, SHA256, SHA1, SHA384, MD5, RIPEMD160  - Author: DannyFire
		Local $oHashHMACErrorHandler = ObjEvent("AutoIt.Error", "_HashHMACErrorHandler")
		Local $oHMAC = ObjCreate("System.Security.Cryptography.HMAC" & $sAlgorithm)
		If @error Then SetError(1, 0, "")
		$oHMAC.key = Binary($bKey)
		Local $bHash = $oHMAC.ComputeHash_2(Binary($bData))
		Return SetError(0, 0, $bRaw_Output ? $bHash : StringLower(StringMid($bHash, 3)))
	EndFunc

	Func _GetHMAC($sString, $iKey, $iAlgID = 0x0000800c, $iBlockSize = 64)     ;$CALG_SHA_256
		_Crypt_Startup()
		Local $a_oPadding[$iBlockSize], $a_iPadding[$iBlockSize]
		Local $oPadding = Binary(''), $iPadding = Binary('')
		$iKey = Binary($iKey)
		If BinaryLen($iKey) > $iBlockSize Then
			$iKey = _Crypt_HashData($iKey, $iAlgID)
			If @error Then Return SetError(1, __HttpRequest_ErrNotify('_GetHMAC', '_Crypt_HashData thất bại #1'), -1)
		EndIf
		For $i = 1 To BinaryLen($iKey)
			$a_iPadding[$i - 1] = Number(BinaryMid($iKey, $i, 1))
			$a_oPadding[$i - 1] = Number(BinaryMid($iKey, $i, 1))
		Next
		For $i = 0 To $iBlockSize - 1
			$a_oPadding[$i] = BitXOR($a_oPadding[$i], 0x5C)
			$a_iPadding[$i] = BitXOR($a_iPadding[$i], 0x36)
		Next
		For $i = 0 To $iBlockSize - 1
			$iPadding &= Binary('0x' & Hex($a_iPadding[$i], 2))
			$oPadding &= Binary('0x' & Hex($a_oPadding[$i], 2))
		Next
		Local $HashS1 = _Crypt_HashData($iPadding & Binary($sString), $iAlgID)
		If @error Then Return SetError(2, __HttpRequest_ErrNotify('_GetHMAC', '_Crypt_HashData thất bại #2'), -1)
		Local $HashS2 = _Crypt_HashData($oPadding & $HashS1, $iAlgID)
		If @error Then Return SetError(3, __HttpRequest_ErrNotify('_GetHMAC', '_Crypt_HashData thất bại #3'), -1)
		_Crypt_Shutdown()
		Return StringLower(Hex($HashS2))
	EndFunc
	
	Func _GetMD5Decrypt($sMD5Encrypt)
		Local $aDecrypt
		$aDecrypt = StringRegExp(_HttpRequest(2, 'http://md5.my-addr.com/md5_decrypt-md5_cracker_online/md5_decoder_tool.php', 'md5=' & $sMD5Encrypt), '(?i)Hashed string</span>: (.*?)</div>', 1)
		If @error Then
			_HttpRequest_ConsoleWrite('<Warrning> Thử lại với service md5.gromweb' & @CRLF)
			$aDecrypt = StringRegExp(_HttpRequest(2, 'https://md5.gromweb.com/?md5=' & $sMD5Encrypt), '<em class="long-content string">(.*?)</em>', 1)
			If @error Then
				_HttpRequest_ConsoleWrite('<Warrning> Thử lại với service md5online.org' & @CRLF)
				Local $_a = StringRegExp(_HttpRequest(2, 'https://www.md5online.org/'), '(?i)name="a" value="(.*?)"', 1)
				If @error Then SetError(1, __HttpRequest_ErrNotify('_GetMD5Decrypt', 'Mở trang md5online.org thất bại'), '')
				Local $g_captcha = _IE_RecaptchaBox('https://www.md5online.org/')
				If @error Then Return SetError(2, __HttpRequest_ErrNotify('_GetMD5Decrypt', 'Chạy ReCaptcha thất bại'), '')
				$aDecrypt = StringRegExp(_HttpRequest(2, _
						'https://www.md5online.org/', _
						'md5=' & $sMD5Encrypt & '&g-recaptcha-response=' & $g_captcha & '&action=decrypt&a=' & $_a), _
						'(?i)<span class="result".*?>Found :\h*?<b>(.*?)</b></span>', 1)
				If @error Then Return SetError(3, __HttpRequest_ErrNotify('_GetMD5Decrypt', 'Không tìm thấy chuỗi MD5 này trên Database'), '')
			EndIf
		EndIf
		Return $aDecrypt[0]
	EndFunc

	Func _GetSHA1Decrypt($sHash)
		Local $reHash = StringRegExp(_HttpRequest(2, 'https://sha1.gromweb.com/?hash=' & $sHash), '<em class="long-content string">(.*?)</em>', 1)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_GetSHA1Decrypt', 'Không tìm thấy chuỗi SHA1 này trên Database'), '')
		Return $reHash[0]
	EndFunc
#EndRegion



#Region <FUNC đã đổi tên và sẽ bị loại bỏ ở phiên bản sau>
	#cs
		« - - - - - - - - - - -Huân Hoàng - - - - - - - - -»
		« - - - - - - - - - - -Rainy Pham - - - - - - - - -»
	#ce

	Func _HttpRequest_SetSession($nSessionNumber)
		__ConsoleOldFuncWarning('_HttpRequest_SetSession', '_HttpRequest_SessionSet', False, True)
		Return _HttpRequest_SessionSet($nSessionNumber)
	EndFunc

	Func _HttpRequest_ClearSession($nSessionNumber = 0, $vClearProxy = False)
		__ConsoleOldFuncWarning('_HttpRequest_ClearSession', '_HttpRequest_SessionClear', False, True)
		Return _HttpRequest_SessionClear($nSessionNumber, $vClearProxy)
	EndFunc

	Func _TimeStampUNIX($iMSec = @MSEC, $iSec = @SEC, $iMin = @MIN, $iHour = @HOUR, $iDay = @MDAY, $iMonth = @MON, $iYear = @YEAR)
		__ConsoleOldFuncWarning('_TimeStampUNIX', '_GetTimeStamp')
	EndFunc

	Func _URLDecode($iParam1 = '', $iParam2 = '', $iParam3 = '', $iParam4 = '', $iParam5 = '', $iParam6 = '')
		__ConsoleOldFuncWarning('_URLDecode', '_HTMLDecode')
	EndFunc

	Func _WinHttpBoundaryGenerator()
		__ConsoleOldFuncWarning('_WinHttpBoundaryGenerator', '_BoundaryGenerator')
	EndFunc

	Func _HttpRequest_CreateDataFormSimple($a_FormItems)
		__ConsoleOldFuncWarning('_HttpRequest_CreateDataFormSimple', '_HttpRequest_DataFormCreate')
	EndFunc

	Func _HttpRequest_ClearCookies($nSessionNumber = 0)
		__ConsoleOldFuncWarning('_HttpRequest_ClearCookies', '_HttpRequest_SessionClear')
	EndFunc

	Func _HttpRequest_NewSession($nSessionNumber = 0)
		__ConsoleOldFuncWarning('_HttpRequest_NewSession', '_HttpRequest_SessionClear')
	EndFunc

	Func _GetFileInfos($sFilePath, $vDataTypeReturn = 1)
		__ConsoleOldFuncWarning('_GetFileInfos', '_GetFileInfo')
	EndFunc

	Func _GetLocation_Redirect($__sHeader = '', $iIndex = -1)
		__ConsoleOldFuncWarning('_GetLocation_Redirect', '_GetLocationRedirect')
	EndFunc

	Func _FileWrite_Test($sData, $FilePath = Default, $iMode = 0)
		__ConsoleOldFuncWarning('_FileWrite_Test', '_HttpRequest_Test')
	EndFunc

	Func _GetHiddenValues($iSourceHtml_or_URL, $iKeySearch = '', $iReturnArray = False, $iInputType = 0)
		__ConsoleOldFuncWarning('_GetHiddenValues', '_HttpRequest_SearchHiddenValues')
	EndFunc

	Func _LiveHttpHeaders_Form2Array($iSourceHtml_or_URL, $iKeySearch = '', $iReturnArray = False, $iInputType = 0)
		__ConsoleOldFuncWarning('_LiveHttpHeaders_Form2Array', '_HttpRequest_DataFormConvertFromClipboard')
	EndFunc

	Func _TimeStamp2Date($iTimeStamp, $vLocalTime = False)
		__ConsoleOldFuncWarning('_TimeStamp2Date', '_GetDateFromTimeStamp')
	EndFunc

	Func _HttpRequest_CreateDataForm($a_FormItems)
		__ConsoleOldFuncWarning('_HttpRequest_CreateDataForm', '_HttpRequest_DataFormCreate', False, True)
		Local $vValue = _HttpRequest_DataFormCreate($a_FormItems)
		Return SetError(@error, @extended, $vValue)
	EndFunc
	
	Func _HttpRequest_GetImageBinaryDimension($sBinaryData_Or_FilePath, $Release_hBitmap = True, $isFilePath = False)
		__ConsoleOldFuncWarning('_HttpRequest_GetImageBinaryDimension', '_Image_GetDimension', False)
		Local $vValue = _Image_GetDimension($sBinaryData_Or_FilePath, $Release_hBitmap, $isFilePath)
		Return SetError(@error, @extended, $vValue)
	EndFunc

	Func _HttpRequest_SetImageBinaryToGUI($sBinaryData_Or_FilePath_Or_URL_Or_arrayHBitmap, $idCtrl_Or_hWnd, $width_Image = Default, $height_Image = Default)
		__ConsoleOldFuncWarning('_HttpRequest_SetImageBinaryToGUI', '_Image_SetGUI', False)
		Local $vValue = _Image_SetGUI($sBinaryData_Or_FilePath_Or_URL_Or_arrayHBitmap, $idCtrl_Or_hWnd, $width_Image, $height_Image)
		Return SetError(@error, @extended, $vValue)
	EndFunc

	Func _HttpRequest_SimpleCaptchaGUI($BinaryCaptcha, $___x = -1, $___y = -1, $___hParent = Default)
		__ConsoleOldFuncWarning('_HttpRequest_SimpleCaptchaGUI', '_Image_SetSimpleCaptchaGUI', False)
		Local $vValue = _Image_SetSimpleCaptchaGUI($BinaryCaptcha, $___x, $___y, $___hParent)
		Return SetError(@error, @extended, $vValue)
	EndFunc
#EndRegion



#Region <Một số hàm phụ trợ Console>
	Func __ConsoleOldFuncWarning($oldName, $newName, $vExit = True, $iShowInConsole = False)
		If $iShowInConsole Then
			_HttpRequest_ConsoleWrite('<Warning> Hàm "' & $oldName & '" đã đổi tên thành "' & $newName & '". Vui lòng sử dụng tên hàm mới bởi ' & $oldName & ' sẽ bị loại bỏ ở các phiên bản sau.' & @CRLF)
		Else
			MsgBox(4096, 'Lưu ý', 'Hàm "' & $oldName & '" đã đổi tên thành "' & $newName & '". Vui lòng sử dụng tên hàm mới bởi ' & $oldName & ' sẽ bị loại bỏ ở các phiên bản sau.')
		EndIf
		If $vExit Then Exit
	EndFunc

	Func __SciTE_TextSplit($nameVar, $nCharPerLine = 101)
		Local $sStr = ClipGet(), $sRet = ''
		Do
			$sRet &= $nameVar & " &= '" & StringReplace(StringLeft($sStr, $nCharPerLine), "'", "''", 0, 1) & "'" & @CRLF
			$sStr = StringTrimLeft($sStr, $nCharPerLine)
		Until StringLen($sStr) = 0
		ClipPut($sRet)
	EndFunc

	Func __SciTE_RunOnDetach()
		If Not @Compiled And $CmdLine[0] = 0 Then
			_HttpRequest_ConsoleWrite('> __SciTE_RunOnDetach được khởi tạo : Chương trình và SciTE đã được phân cách.' & @CRLF)
			Exit Run(FileGetShortName(@AutoItExe) & ' "' & @ScriptFullPath & '" --detach-scite', @WorkingDir, @SW_HIDE, 1)
		EndIf
	EndFunc

	Func __SciTE_ConsoleWrite_FixFont()
		If @Compiled Or ($CmdLine[0] > 0 And $CmdLine[1] = '--hh-multi-process') Or StringInStr(@AutoItExe, 'AutoItX', 0, 1) Then Return
		;----------------------------------------------------------------------------------------------------------------------------
		Local $SciTE_Link_A = StringRegExpReplace(@AutoItExe, '(?i)\w+\.exe$', '') & 'SciTE\'
		Local $SciTE_Link_B = StringRegExpReplace(__WinAPI_GetProcessFileName(ProcessExists('SciTE.exe')), '(?i)\w+\.exe$', '')
		If $SciTE_Link_B = '' Then $SciTE_Link_B = $SciTE_Link_A
		If $SciTE_Link_A = $SciTE_Link_B Then
			Local $SciTEProp_Link = [@LocalAppDataDir & '\AutoIt v3\SciTE\SciTEUser.properties', $SciTE_Link_A & 'SciTEUser.properties', $SciTE_Link_A & 'SciTEGlobal.properties']
		Else
			Local $SciTEProp_Link = [@LocalAppDataDir & '\AutoIt v3\SciTE\SciTEUser.properties', $SciTE_Link_A & 'SciTEUser.properties', $SciTE_Link_A & 'SciTEGlobal.properties', $SciTE_Link_B & 'SciTEUser.properties', $SciTE_Link_B & 'SciTEGlobal.properties']
		EndIf
		For $i = 0 To UBound($SciTEProp_Link) - 1
			Local $SciTEUserProp_Change = 0
			If FileExists($SciTEProp_Link[$i]) Then
				Local $SciTEUserProp_Data = FileRead($SciTEProp_Link[$i])
				If Not StringRegExp($SciTEUserProp_Data, '(?im)^\h*?\Qoutput.code.page\E\h*?=\h*?65001') Or StringRegExp($SciTEUserProp_Data, '(?im)^\h*?\Qoutput.code.page\E\h*?=\h*?0') Then
					$SciTEUserProp_Data = StringRegExpReplace($SciTEUserProp_Data, '(?im)^\h*?\Qoutput.code.page\E.*$\R', '')
					$SciTEUserProp_Data &= @CRLF & 'output.code.page=65001'
					$SciTEUserProp_Change = 1
				EndIf
				If Not StringRegExp($SciTEUserProp_Data, '(?im)^\h*?\Qcode.page\E\h*?=\h*?65001') Or StringRegExp($SciTEUserProp_Data, '(?im)^\h*?\Qoutput.code.page\E\h*?=\h*?0') Then
					$SciTEUserProp_Data = StringRegExpReplace($SciTEUserProp_Data, '(?im)^\h*?\Qcode.page\E.*$\R', '')
					$SciTEUserProp_Data &= @CRLF & 'code.page=65001'
					$SciTEUserProp_Change = 1
				EndIf
			Else
				$SciTEUserProp_Change = 1
				$SciTEUserProp_Data = 'output.code.page=65001' & @CRLF & 'code.page=65001' & @CRLF
			EndIf
			If $SciTEUserProp_Change = 1 Then
				Local $hOpen = FileOpen($SciTEProp_Link[$i], 2 + 8)
				FileWrite($hOpen, $SciTEUserProp_Data)
				FileClose($hOpen)
			EndIf
		Next
		;----------------------------------------------------------------------------------------------------------------------------
		If $g___ConsoleForceUTF8 = True Then
			Local $SciTEProp_Link = @ScriptDir & '\SciTE.properties'
			If Not FileExists($SciTEProp_Link) Then
				Local $hOpen = FileOpen($SciTEProp_Link, 2 + 8)
				FileWrite($hOpen, 'output.code.page=65001' & @CRLF & 'code.page=65001' & @CRLF)
				FileClose($hOpen)
			EndIf
		EndIf
	EndFunc

	Func __SciTE_ConsoleClear()
		__SciTE_Command("menucommand:420")
	EndFunc

	Func __SciTE_Command($sCmd)
		If @Compiled Then Return
		Local $CmdStruct = DllStructCreate('Char[' & StringLen($sCmd) + 1 & ']')
		DllStructSetData($CmdStruct, 1, $sCmd)
		Local $COPYDATA = DllStructCreate('Ptr;DWord;Ptr')
		DllStructSetData($COPYDATA, 1, 1)
		DllStructSetData($COPYDATA, 2, StringLen($sCmd) + 1)
		DllStructSetData($COPYDATA, 3, DllStructGetPtr($CmdStruct))
		DllCall($dll_User32, 'None', 'SendMessage', 'HWnd', WinGetHandle("DirectorExtension"), 'Int', 74, 'HWnd', 0, 'Ptr', DllStructGetPtr($COPYDATA))
	EndFunc

	Func __SciTE_SplitLongLine($sText, $nMaxCharPerLine = 1000)
		Return 'Local $sString = ' & StringTrimRight(StringRegExpReplace($sText, '(.{' & $nMaxCharPerLine & '}|.+)', '"${1}" & _' & @LF & @TAB & @TAB), 7)
	EndFunc

	Func __WinAPI_GetProcessFileName($iPID)
		If $iPID = 0 Then Return SetError(1, __HttpRequest_ErrNotify('__WinAPI_GetProcessFileName', 'PID không tồn tại (PID = 0)'), '')
		;-----------------------------------------------------
		Local $__tOSVI__ = DllStructCreate('struct;dword OSVersionInfoSize;dword MajorVersion;dword MinorVersion;dword BuildNumber;dword PlatformId;wchar CSDVersion[128];endstruct')
		DllStructSetData($__tOSVI__, 1, DllStructGetSize($__tOSVI__))
		Local $aRet = DllCall($dll_Kernel32, 'bool', 'GetVersionExW', 'struct*', $__tOSVI__)
		If @error Or Not $aRet[0] Then Return SetError(2, 0, '')
		Local $__WINVER__ = BitOR(BitShift(DllStructGetData($__tOSVI__, 2), -8), DllStructGetData($__tOSVI__, 3))
		;-----------------------------------------------------
		Local $hProcess = DllCall($dll_Kernel32, 'handle', 'OpenProcess', 'dword', $__WINVER__ < 0x0600 ? 0x00000410 : 0x00001010, 'bool', 0, 'dword', $iPID)
		If @error Or Not $hProcess[0] Then Return SetError(3, 0, '')
		;-----------------------------------------------------
		Local $aFileNameExW = DllCall('psapi.dll', 'dword', 'GetModuleFileNameExW', 'handle', $hProcess[0], 'handle', 0, 'wstr', '', 'int', 4096)
		If @error Or Not $aFileNameExW[0] Then Return SetError(4, 0, '')
		;-----------------------------------------------------
		DllCall($dll_Kernel32, "bool", "CloseHandle", "handle", $hProcess[0])
		;-----------------------------------------------------
		Return $aFileNameExW[3]
	EndFunc

	Func __RemoveVietMarktical($sText)
		If $g___aVietPattern = '' Then Global $g___aVietPattern = [['áàảãạăắằẳẵặâấầẩẫậ', 'a'], ['đ', 'd'], ['éèẻẽẹêếềểễệ', 'e'], ['íìỉĩị', 'i'], ['óòỏõọôốồổỗộơớờởỡợ', 'o'], ['úùủũụưứừửữự', 'u'], ['ýỳỷỹỵ', 'y']]
		For $i = 0 To 6
			$sText = StringRegExpReplace($sText, '[' & $g___aVietPattern[$i][0] & ']', $g___aVietPattern[$i][1])
			$sText = StringRegExpReplace($sText, '[' & StringUpper($g___aVietPattern[$i][0]) & ']', StringUpper($g___aVietPattern[$i][1]))
		Next
		Return $sText
	EndFunc
#EndRegion



#Region <Google Request>
	Func _HttpRequest_GoogleLogin($sUser, $sPass, $sRedirectURL = Default, $iReturn = Default, $iUserAgent = Default, $iSetPrevUAAfterLogin = True, $___x = -1, $___y = -1, $___hParent = Default, $vUselessParam = 0)
		If $iReturn = Default Then $iReturn = 2
		If $sRedirectURL = Default Then $sRedirectURL = ''
		If $iUserAgent = Default Then $iUserAgent = $g___defUserAgentGG     ;có thể thế bằng Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727)
		$sUser = _URIEncode(StringRegExpReplace($sUser, '(?i)@gmail.com[\.\w]*?$', '', 1))
		$sPass = _URIEncode($sPass)
		Local $BkUserAgent = _HttpRequest_SetUserAgent($iUserAgent)
		Local $sHeader = ''
		;---------------------------------------------------------------------------------------
		Local $rq1 = _HttpRequest('☺2', 'https://accounts.google.com/signin/v1/lookup', 'Email=' & $sUser)
		If StringInStr($rq1, '"errormsg_0_Email"', 0, 1) Then
			Return SetError(1 * _HttpRequest_SetUserAgent($BkUserAgent), __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Google không nhận dạng được email này'), $rq1)
		EndIf
		$sHeader &= $g___retData[$g___LastSession][0] & @CRLF & @CRLF
		Local $aHiddenValue = StringRegExp($rq1, '(?i)name="(gxf|GALX|ProfileInformation|SessionState)".*?value="(.*?)"', 3)
		If @error Or UBound($aHiddenValue) <> 8 Then
			Return SetError(2 * _HttpRequest_SetUserAgent($BkUserAgent), __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Không tìm thấy tham số đăng nhập tài khoản từ Html #2'), $rq1)
		EndIf
		;---------------------------------------------------------------------------------------
		Local $rq2 = _HttpRequest('☺2', 'https://accounts.google.com/signin/challenge/sl/password', $aHiddenValue[0] & '=' & _URIEncode($aHiddenValue[1]) & '&' & $aHiddenValue[2] & '=' & _URIEncode($aHiddenValue[3]) & '&' & $aHiddenValue[4] & '=' & _URIEncode($aHiddenValue[5]) & '&' & $aHiddenValue[6] & '=' & _URIEncode($aHiddenValue[7]) & '&Email=' & $sUser & '&Passwd=' & $sPass & '&signIn=Sign+in&PersistentCookie=yes&Page=PasswordSeparationSignIn&flowName=GlifWebSignIn&_utf8=%E2%98%83&bgresponse=0123456789&continue=' & _URIEncode($sRedirectURL), '', 'https://accounts.google.com/signin/v1/lookup')
		If @extended = 400 Then Return SetError(-1 * _HttpRequest_SetUserAgent($BkUserAgent), __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Lỗi không xác định khi thực hiện nạp password'), $rq2)
		Local $CaptchaCheck = StringInStr($rq2, '<div class="captcha-container">', 1, 1)
		If StringInStr($rq2, '"errormsg_0_Passwd"', 0, 1) And Not $CaptchaCheck Then
			Return SetError(3 * _HttpRequest_SetUserAgent($BkUserAgent), __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Mật khẩu không chính xác #1'), $rq2)
		EndIf
		If $CaptchaCheck Then
			For $i = 0 To 2
				$aHiddenValue = StringRegExp($rq2, '(?i)name="(gxf|ProfileInformation|SessionState)".*?value="(.*?)"', 3)
				If @error Or UBound($aHiddenValue) <> 6 Then
					Return SetError(4 * _HttpRequest_SetUserAgent($BkUserAgent), __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Không tìm thấy tham số đăng nhập tài khoản từ Html #3'), $rq2)
				EndIf
				Local $TokenLogin = StringRegExp($rq2, '(?i)name="logintoken".*?value="(.*?)"', 1)
				If @error Then
					Return SetError(5 * _HttpRequest_SetUserAgent($BkUserAgent), __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Không tìm thấy tham số đăng nhập tài khoản từ Html #4'), $rq2)
				EndIf
				Local $CaptchaLink = 'https://accounts.google.com/Captcha?v=2&ctoken=' & $TokenLogin[0]
				TrayTip('Google Captcha', 'Nhập Captcha để tiếp tục', 30, 2)
				Local $CaptchaValue = _Image_SetSimpleCaptchaGUI(_HttpRequest('☺3', $CaptchaLink), $___x, $___y, $___hParent)
				TrayTip('', '', 0)
				$rq2 = _HttpRequest('☺2', 'https://accounts.google.com/signin/challenge/sl/password', 'Page=PasswordSeparationSignIn&continue=' & _URIEncode($sRedirectURL) & '&flowName=GlifWebSignIn&_utf8=%E2%98%83&bgresponse=0123456789&Email=' & $sUser & '&Passwd=' & $sPass & '&' & $aHiddenValue[0] & '=' & _URIEncode($aHiddenValue[1]) & '&' & $aHiddenValue[2] & '=' & _URIEncode($aHiddenValue[3]) & '&' & $aHiddenValue[4] & '=' & _URIEncode($aHiddenValue[5]) & '&logintoken=' & $TokenLogin[0] & '&url=' & _URIEncode($CaptchaLink) & '&logintoken_audio=' & $TokenLogin[0] & '&url_audio=' & _URIEncode($CaptchaLink & '&kind=audio') & '&logincaptcha=' & $CaptchaValue & '&signIn=Sign+in&PersistentCookie=yes', '', 'https://accounts.google.com/signin/v1/lookup')
				If Not StringInStr($rq2, '<div class="captcha-container">', 1, 1) Then ExitLoop
				MsgBox(4096, 'Lỗi', 'Bạn đã nhập sai Captcha. Vui lòng thử lại.')
			Next
			If $i = 3 Then Exit MsgBox(4096, 'Lỗi', 'Bạn đã nhập sai Captcha liên tiếp 3 lần. Code sẽ tắt để đảm bảo tài khoản không bị khoá.')
		EndIf
		If StringInStr($rq2, '"errormsg_0_Passwd"', 0, 1) Then
			Return SetError(3 * _HttpRequest_SetUserAgent($BkUserAgent), __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Mật khẩu không chính xác #2'), $rq2)
		EndIf
		$sHeader &= $g___retData[$g___LastSession][0] & @CRLF & @CRLF
		;---------------------------------------------------------------------------------------
		If StringInStr($rq2, 'data-phone-step-skip-link', 1, 1) Then
			_HttpRequest_ConsoleWrite('<Account bị kiểm tra Recovery phone number Or Recovery email>' & @CRLF)
			If $vUselessParam = 0 Then
				Return _HttpRequest_GoogleLogin($sUser, $sPass, $sRedirectURL, $iReturn, $iSetPrevUAAfterLogin, $___x, $___y, $___hParent, 1)
			Else
				Return SetError(6 * _HttpRequest_SetUserAgent($BkUserAgent), __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Tài khoản yêu cầu cập nhật thông tin. Hãy đăng nhập trên trình duyệt kiểm tra lại'), $rq2)
			EndIf

		ElseIf StringInStr($rq2, 'https://accounts.google.com/signin/newfeatures/options', 1, 1) Then
			_HttpRequest_ConsoleWrite('<Account bị kiểm tra New Features>' & @CRLF)
			Local $aParam = StringRegExp(StringReplace($rq2, '&amp;', '&', 0, 1), '(?i)<input type="hidden" name="(.*?)" value="(.*?)"', 3)
			Local $sParam = ''
			For $i = 0 To UBound($aParam) - 1 Step 2
				$sParam &= $aParam[$i] & '=' & _URIEncode($aParam[$i + 1]) & '&'
			Next
			_HttpRequest('☺0', 'https://accounts.google.com/signin/newfeatures/save', StringTrimRight($sParam, 1))
			If $vUselessParam < 2 Then
				Return _HttpRequest_GoogleLogin($sUser, $sPass, $sRedirectURL, $iReturn, $iSetPrevUAAfterLogin, $___x, $___y, $___hParent, 2)
			Else
				Return SetError(5 * _HttpRequest_SetUserAgent($BkUserAgent), __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Tài khoản yêu cầu cập nhật thông tin. Hãy đăng nhập trên trình duyệt kiểm tra lại'), $rq2)
			EndIf

		ElseIf StringInStr($rq2, 'action="/signin/challenge/az', 1, 1) Then
			Exit MsgBox(4096 + 48, 'Thông báo', 'Tài khoản này bị bắt buộc phải được Xác Nhận Danh Tính trên trình duyệt' & @CRLF & 'Vui lòng mở tài khoản trên trình duyệt để xác nhận.')
			#Region <Đang test>
				Local $sURL_Verify = StringRegExp($g___LocationRedirect, '/signin/challenge/az/.*?\?(continue=.*?&TL=.+)$', 1)
				If @error Then
					Exit MsgBox(4096 + 48, 'Thông báo', 'Tài khoản này bị bắt buộc phải được Xác Nhận Danh Tính trên trình duyệt' & @CRLF & 'Vui lòng mở tài khoản trên trình duyệt để xác nhận.')
				Else
					Local $gfx = StringRegExp($rq2, 'name="gxf" .*?value="(.*?)"', 1)
					If Not @error Then
						Local $rq3 = _HttpRequest('☺2', 'https://accounts.google.com/signin/challenge/az/2', 'challengeId=2&challengeType=4&' & $sURL_Verify[0] & '&gxf=' & _URIEncode($gfx[0]) & '&action=SEND')
						MsgBox(4096 + 48, 'Thông báo', 'Đã gửi Xác Nhận Danh Tính đến số điện thoại của Tài khoản này.')
					EndIf
				EndIf
			#EndRegion
			
		ElseIf StringInStr($g___LocationRedirect, 'signin/challenge/ipp', 1, 1) Then
			Exit MsgBox(4096 + 48, 'Thông báo', 'Tài khoản này bị bắt buộc phải được Xác Nhận Danh Tính trên trình duyệt' & @CRLF & 'Vui lòng mở tài khoản trên trình duyệt để xác nhận.')
			#Region <Đang test>
				Local $sURL_Verify = StringRegExp($g___LocationRedirect, '/signin/challenge/ipp/.*?\?(continue=.*?&TL=.+)$', 1)
				If @error Then
					Exit MsgBox(4096 + 48, 'Thông báo', 'Tài khoản này bị bắt buộc phải được Xác Nhận Danh Tính trên trình duyệt' & @CRLF & 'Vui lòng mở tài khoản trên trình duyệt để xác nhận.')
				Else
					Local $gfx = StringRegExp($rq2, 'name="gxf" .*?value="(.*?)"', 1)
					If Not @error Then
						$sURL_Verify = 'challengeId=3&challengeType=9&' & $sURL_Verify[0] & '&gxf='
						Local $rq3 = _HttpRequest('☺2', 'https://accounts.google.com/signin/challenge/ipp/3', $sURL_Verify & _URIEncode($gfx[0]) & '&SendMethod=SMS')
						$gfx = StringRegExp($rq3, 'name="gxf" .*?value="(.*?)"', 1)
						If Not @error Then
							Local $PIN = InputBox('Google Xác nhận danh tính bằng tin nhắn', 'Nhập mã PIN đã đượ gửi tới sms:')
							If Not @error Then
								$rq3 = _HttpRequest('☺2', 'https://accounts.google.com/signin/challenge/ipp/3', $sURL_Verify & _URIEncode($gfx[0]) & '&Pin=' & $PIN)
							Else
								MsgBox(4096 + 48, 'Thông báo', 'Bạn đã huỷ Xác nhận danh tính')
							EndIf
						EndIf
					EndIf
				EndIf
			#EndRegion
		EndIf
		;---------------------------------------------------------------------------------------
		If StringRegExp($rq2, 'action="\/signin\/challenge\/kpp\/[45]"') Then
			_HttpRequest_SetUserAgent($BkUserAgent)
			Return SetError(7, __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Tài khoản cần được xác thực - Vui lòng mở Gmail trên trình duyệt và báo cáo an toàn nếu nhận được thông báo Activity'), $rq2)
			
		ElseIf Not StringInStr($sHeader, 'SAPISID', 0, 1) Then
			_HttpRequest_SetUserAgent($BkUserAgent)
			Return SetError(8, __HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Đăng nhập thất bại không rõ nguyên do. Vui lòng LogOut (nếu đã đăng nhập) và LogIn lại tài khoản trên trình duyệt'), $rq2)
		EndIf
		;---------------------------------------------------------------------------------------
		If $iSetPrevUAAfterLogin Then _HttpRequest_SetUserAgent($BkUserAgent)
		Local $vRet
		Switch $iReturn
			Case -1
				$vRet = _GetCookie($sHeader)
			Case 0
				$vRet = ''
			Case 1
				$vRet = $sHeader
			Case 2
				$vRet = $rq2
			Case 4
				Local $aRet = [$sHeader, $rq2]
				$vRet = $aRet
			Case Else
				__HttpRequest_ErrNotify('_HttpRequest_GoogleLogin', 'Chỉ chấp nhận $iReturn = -1 hoặc 0 hoặc 1 hoặc 2 hoặc 4')
				$vRet = $rq2
		EndSwitch
		Return $vRet
	EndFunc

	Func _HttpRequest_Google_SAPISIDHASH($SAPISID, $xOrigin)     ;https://stackoverflow.com/questions/16907352/reverse-engineering-javascript-behind-google-button
		Local $sTimeStamp = _GetTimeStamp()
		Return 'SAPISIDHASH ' & $sTimeStamp & '_' & _GetSHA1($sTimeStamp & ' ' & $SAPISID & ' ' & $xOrigin)
	EndFunc

	Func _HttpRequest_Google_CheckNewDevice()
		Local $sHTML = _HttpRequest(2, 'https://accounts.google.com/b/0/DisplayUnlockCaptcha')
		Local $aHiddenValue = StringRegExp($sHTML, '(?i)id="(timeStmp|secTok)"[\s\S]*?value=[''"](.+?)[''"]', 3)
		If Not @error And UBound($aHiddenValue) = 4 Then _HttpRequest(0, 'https://accounts.google.com/b/0/DisplayUnlockCaptcha', $aHiddenValue[0] & '=' & _URIEncode($aHiddenValue[1]) & '&' & $aHiddenValue[2] & '=' & _URIEncode($aHiddenValue[3]) & '&submitChallenge=Continue')
		$sHTML = _HttpRequest(2, 'https://myaccount.google.com/security-checkup?continue=https://myaccount.google.com/')
		Local $aDeviceID = StringRegExp($sHTML, '(?i)data-event-id=("-?\d+")', 3)
		If @error Then Return SetError(1, '', False)
		$aDeviceID = __ArrayDuplicate($aDeviceID)
		For $i = 0 To UBound($aDeviceID) - 1
			__Google_SettingsOnOff($sHTML, 161362964, $aDeviceID[$i], 2)
			If @error > 0 And @error < 3 Then Return SetError(2, '', False)
		Next
		Return True
	EndFunc

	Func _HttpRequest_Google_AllowLessSecureApps($iState)
		Local $sHTML = _HttpRequest(2, 'https://myaccount.google.com/security')
		__Google_SettingsOnOff($sHTML, 139777153, $iState)
		$sHTML = _HttpRequest(2, 'https://myaccount.google.com/security-checkup?continue=https://myaccount.google.com/')
		Local $aEventID = StringRegExp($sHTML, '(?i)true,("-?\d+"),\[4,1,5\]', 3)
		If @error Then Return SetError(1, '', False)
		For $i = 0 To UBound($aEventID) - 1
			__Google_SettingsOnOff($sHTML, 161362964, $aEventID[$i], 2)
			If @error > 0 And @error < 3 Then Return SetError(2, '', False)
		Next
		Return True
	EndFunc

	Func __HttpRequest_GoogleBotguard($sSourceHTML)
		_IE_CheckCompatible(True)
		Local $scriptAntiSpam = StringRegExp($sSourceHTML, '<script type="text/javascript".*?>/\* Anti-spam.*?\*/(Function\(.*?)</script>', 1)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('__HttpRequest_GoogleBotguard', 'Source html không chứa đoạn mã javascript cần dùng để lấy bgresponse #1'), '')
		Local $scriptBotguard = StringRegExp($sSourceHTML, '(document\.bg = new botguard\.bg.*?)[\r\n\s]*?</script>', 1)
		If @error Then Return SetError(2, __HttpRequest_ErrNotify('__HttpRequest_GoogleBotguard', 'Source html không chứa đoạn mã javascript cần dùng để lấy bgresponse #2'), '')
		Local $bgresponse = _JS_Execute('', $scriptAntiSpam[0] & $scriptBotguard[0] & 'document.bg.invoke(function(response){document.write(response);});', '', False)
		If @error Then Return SetError(3, __HttpRequest_ErrNotify('__HttpRequest_GoogleBotguard', 'Không thể giải js để lấy bgresponse'), '')
		Return $bgresponse
	EndFunc

	Func __Google_SettingsOnOff($sHTML, $iExtension, $iState, $iAddtionalData = '')
		Local $at = StringRegExp($sHTML, "(?i)\Q'https:\/\/www.google.com\/settings',\E'(.*?)'", 1)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('__Google_SettingsOnOff', 'Chưa đăng nhập Google hoặc Đăng nhập thất bại'))
		Local $boq = StringRegExp($sHTML, '(?i)"(boq_identity.*?)"', 1)
		If @error Then Return SetError(2, __HttpRequest_ErrNotify('__Google_SettingsOnOff', 'Chưa đăng nhập Google hoặc Đăng nhập thất bại'))
		If Not IsNumber($iAddtionalData) Then $iAddtionalData = '"' & StringReplace($iAddtionalData, '\u003d', '=') & '"'
		_HttpRequest(0, 'https://myaccount.google.com/_/AccountSettingsUi/mutate?ds.extension=' & $iExtension & '&f.sid=&bl=' & $boq[0] & '&hl=en&_reqid=&rt=c', 'f.req=' & _URIEncode('["af.maf",[["af.add",' & $iExtension & ',[{"' & $iExtension & '":[' & $iState & ($iAddtionalData ? ',' & $iAddtionalData : '') & ']}]]]]') & '&at=' & _URIEncode($at[0]) & '&')
		If @error Then Return SetError(3)
	EndFunc
#EndRegion




#Region <UDF WinHttp by Trancexx, ProAndy>
	Func _WinHttpGetResponseErrorCode2($iErrorCode)
		Static $sAllErrorCode = 'OUT_OF_HANDLES12001,TIMEOUT12002,UNKNOWN12003,INTERNAL_ERROR12004,INVALID_URL12005,UNRECOGNIZED_SCHEME12006,NAME_NOT_RESOLVED12007,INVALID_OPTION12009,OPTION_NOT_SETTABLE12011,SHUTDOWN12012,LOGIN_FAILURE12015,OPERATION_CANCELLED12017,INCORRECT_HANDLE_TYPE12018,INCORRECT_HANDLE_STATE12019,CANNOT_CONNECT12029,CONNECTION_ERROR12030,RESEND_REQUEST12032,SECURE_CERT_DATE_INVALID12037,SECURE_CERT_CN_INVALID12038,CLIENT_AUTH_CERT_NEEDED12044,SECURE_INVALID_CA12045,SECURE_CERT_REV_FAILED12057,CANNOT_CALL_BEFORE_OPEN12100,CANNOT_CALL_BEFORE_SEND12101,CANNOT_CALL_AFTER_SEND12102,CANNOT_CALL_AFTER_OPEN12103,HEADER_NOT_FOUND12150,INVALID_SERVER_RESPONSE12152,INVALID_HEADER12153,INVALID_QUERY_REQUEST12154,HEADER_ALREADY_EXISTS12155,REDIRECT_FAILED12156,SECURE_CHANNEL_ERROR12157,BAD_AUTO_PROXY_SCRIPT12166,UNABLE_TO_DOWNLOAD_SCRIPT12167,SECURE_INVALID_CERT12169,SECURE_CERT_REVOKED12170,NOT_INITIALIZED12172,SECURE_FAILURE12175,AUTO_PROXY_SERVICE_ERROR12178,SECURE_CERT_WRONG_USAGE12179,AUTODETECTION_FAILED12180,HEADER_COUNT_EXCEEDED12181,HEADER_SIZE_OVERFLOW12182,CHUNKED_ENCODING_HEADER_SIZE_OVERFLOW12183,RESPONSE_DRAIN_OVERFLOW12184,CLIENT_CERT_NO_PRIVATE_KEY12185,CLIENT_CERT_NO_ACCESS_PRIVATE_KEY12186'
		$iErrorCode = StringRegExp($sAllErrorCode, '(?:^|\,)([A-Z_]+)' & $iErrorCode, 1)
		If @error Then Return 'ERROR_WINHTTP_UNKNOWN'
		Return 'ERROR_WINHTTP_' & $iErrorCode[0]
	EndFunc

	Func _WinHttpQueryHeaders2($hRequest, $iLevel_Or_sNameHeader = 22, $iIndex = 0, $vBuffer = 8192)
		Local $sNameHeader = ''
		If $iLevel_Or_sNameHeader = 19 Then $vBuffer = 8
		If IsString($iLevel_Or_sNameHeader) Then
			$sNameHeader = $iLevel_Or_sNameHeader
			If $iLevel_Or_sNameHeader = 'DNS' Then
				$iLevel_Or_sNameHeader = 81
			ElseIf $iLevel_Or_sNameHeader = 'CERT' Then
				$iLevel_Or_sNameHeader = 80
			Else
				$iLevel_Or_sNameHeader = 65535
			EndIf
		EndIf
		Switch $iLevel_Or_sNameHeader
			Case 80
				Local $vCert = _GetCertificateInfo()
				Return SetError(@error, 0, $vCert)
			Case 81
				Local $vDS = _GetNameDNS()
				Return SetError(@error, 0, $vDS)
			Case Else
				Local $aCall = DllCall($dll_WinHttp, "bool", 'WinHttpQueryHeaders', "handle", $hRequest, "dword", $iLevel_Or_sNameHeader, 'wstr', $sNameHeader, 'wstr', "", "dword*", $vBuffer, "dword*", $iIndex)
				If @error Or Not $aCall[0] Then
					If $aCall[5] And $vBuffer < $aCall[5] Then
						$aCall = DllCall($dll_WinHttp, "bool", 'WinHttpQueryHeaders', "handle", $hRequest, "dword", $iLevel_Or_sNameHeader, 'wstr', $sNameHeader, 'wstr', "", "dword*", $aCall[5], "dword*", $iIndex)
						If @error Or Not $aCall[0] Then Return SetError(2, 0, 0)
						Return $aCall[4]
					Else
						Return SetError(1, 0, 0)
					EndIf
				EndIf
				Return $aCall[4]
		EndSwitch
	EndFunc

	Func _WinHttpAddRequestHeaders2($hRequest, $sHeader, $iModifier = Default)
		;WINHTTP_ADDREQ_FLAG_ADD = 0x20000000
		;WINHTTP_ADDREQ_FLAG_REPLACE = 0x80000000
		;WINHTTP_ADDREQ_FLAG_ADD_IF_NEW = 0x10000000
		;WINHTTP_ADDREQ_FLAG_COALESCE_WITH_COMMA = 0x40000000
		;WINHTTP_ADDREQ_FLAG_COALESCE_WITH_SEMICOLON = 0x01000000
		If $iModifier = Default Then $iModifier = 0x10000000
		DllCall($dll_WinHttp, "bool", 'WinHttpAddRequestHeaders', "handle", $hRequest, 'wstr', $sHeader, "dword", -1, "dword", $iModifier)
	EndFunc

	Func _WinHttpOpen2($iAsync = 0, $iProxy = '', $iProxyBypass = '')
		Local $aCall = DllCall($dll_WinHttp, "handle", "WinHttpOpen", 'wstr', '', "dword", $iProxy ? 3 : 0, 'wstr', $iProxy, 'wstr', $iProxyBypass, "dword", $iAsync * 0x10000000)
		If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
		If $iAsync Then _WinHttpSetOption2($aCall[0], 45, 0x10000000)
		Return $aCall[0]
	EndFunc

	Func _WinHttpSendRequest2($hRequest, $sHeaders = '', $sData2Send = '', $iUpload = 0, $CallBackFunc_Progress = '')
		Local $pData2Send = 0, $lData2Send = 0
		If $sData2Send Then
			$lData2Send = BinaryLen($sData2Send)
			If $iUpload = 0 Then
				Local $tData2Send = DllStructCreate('byte[' & $lData2Send & ']')
				DllStructSetData($tData2Send, 1, $sData2Send)
				$pData2Send = DllStructGetPtr($tData2Send)
			EndIf
		EndIf
		Local $aCall = DllCall($dll_WinHttp, "bool", 'WinHttpSendRequest', "handle", $hRequest, 'wstr', $sHeaders, "dword", 0, "ptr", $pData2Send, "dword", $lData2Send, "dword", $lData2Send, "dword_ptr", 0)
		If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
		If $iUpload Then
			_WinHttpWriteData_Ex($hRequest, $sData2Send, $lData2Send, $CallBackFunc_Progress)
			If @error Then Return SetError(@error, 0, 0)
		EndIf
		Return 1
	EndFunc

	Func _WinHttpWriteData_Ex($hRequest, $sData2Send, $lData2Send, $CallBackFunc_Progress = '', $iBytesPerLoop = $g___BytesPerLoop)
		Local $tBuffer, $iDataMid, $iDataMidLen, $iCheckCallbackFunc = 0, $vNowSizeBytes = 0, $vTotalSizeBytes = -1, $aCall, $isBinData2Send = IsBinary($sData2Send)
		If $CallBackFunc_Progress <> '' Then
			$iCheckCallbackFunc = 1
			$vTotalSizeBytes = $lData2Send
			If $vTotalSizeBytes > 2147483647 Then Return SetError(101, __HttpRequest_ErrNotify('_WinHttpWriteData_Ex', 'Tập tin quá lớn', 101), 0)
		EndIf
		;----------------------------------
		Do
			$iDataMid = $g___aReadWriteData[1][$isBinData2Send]($sData2Send, $vNowSizeBytes + 1, $iBytesPerLoop)
			$iDataMidLen = $g___aReadWriteData[2][$isBinData2Send]($iDataMid)
			$tBuffer = DllStructCreate($g___aReadWriteData[0][$isBinData2Send] & "[" & ($iDataMidLen + 1) & "]")
			DllStructSetData($tBuffer, 1, $iDataMid)
			$aCall = DllCall($dll_WinHttp, "bool", 'WinHttpWriteData', "handle", $hRequest, "struct*", $tBuffer, "dword", $iDataMidLen, "dword*", 0)
			If @error Or Not $aCall[0] Then ExitLoop
			$vNowSizeBytes += $iDataMidLen
			$tBuffer = ''
			;--------------------------------------------------------------------------------
			If $g___swCancelReadWrite Then
				$g___swCancelReadWrite = False
				Return SetError(999, __HttpRequest_ErrNotify('_WinHttpWriteData_Ex', 'Đã huỷ request', 999), 0)
			ElseIf $iCheckCallbackFunc Then
				$CallBackFunc_Progress($vNowSizeBytes, $vTotalSizeBytes)
			EndIf
		Until $aCall[4] < $iBytesPerLoop
		Return 1
	EndFunc

	Func _WinHttpReadData_Ex($hRequest, $CallBackFunc_Progress = '', $iFileSavePath = '', $iEncodingOfFileSave = 0, $iBytesPerLoop = $g___BytesPerLoop)
		Local $vBinaryData = Binary(''), $aCall, $iCheckCallbackFunc = 0, $vNowSizeBytes = 1, $vTotalSizeBytes = -1
		Local $tBuffer = DllStructCreate("byte[" & $iBytesPerLoop & "]")
		;----------------------------------
		If $CallBackFunc_Progress <> '' Then
			$iCheckCallbackFunc = 1
			$vTotalSizeBytes = Number(_WinHttpQueryHeaders2($hRequest, 5))     ;QUERY_CONTENT_LENGTH
			If $vTotalSizeBytes > 2147483647 Then Return SetError(102, __HttpRequest_ErrNotify('_WinHttpReadData_Ex', 'Tập tin quá lớn', -1), 0)
		EndIf
		;-----------------------------------------------------------------------------------------------------------------------------------------------------------
		If $iFileSavePath Then
			If FileExists($iFileSavePath) Then
				Switch $g___iReadMode
					Case 0
						__HttpRequest_ErrNotify('_WinHttpReadData_Ex', 'Đã ghi đè lên tập tin cũ tồn tại: "' & $iFileSavePath & '"', '', 'Warning')
					Case 1
						$iFileSavePath = StringRegExpReplace($iFileSavePath, '^(.+?)(\.\w+)$', '${1}' & TimerInit() & '${2}')
						__HttpRequest_ErrNotify('_WinHttpReadData_Ex', 'Đã đổi tên $iFileSavePath vì tồn tại tập tin cùng tên trong thư mục muốn ghi', '', 'Warning')
					Case 2
						Switch MsgBox(4096 + 48 + 2, 'Chú ý', _
								'Đã tồn tại tập tin cùng tên tại thư mục muốn ghi.' & @CRLF & _
								'- Nhấn Abort để huỷ tải xuống' & @CRLF & _
								'- Nhấn Retry để đổi tên đường dẫn lưu tập tin trước khi tải' & @CRLF & _
								'- Nhấn Ignore để tiếp tục tải và ghi đè')
							Case 3
								Return SetError(995, __HttpRequest_ErrNotify('_WinHttpReadData_Ex', 'Đã huỷ request #3', -1), 0)
							Case 4
								$iFileSavePath = StringRegExpReplace($iFileSavePath, '^(.+?)(\.\w+)$', '${1}' & TimerInit() & '${2}')
								__HttpRequest_ErrNotify('_WinHttpReadData_Ex', 'Đã đổi tên $iFileSavePath vì tồn tại tập tin cùng tên trong thư mục muốn ghi', '', 'Warning')
							Case 5
								__HttpRequest_ErrNotify('_WinHttpReadData_Ex', 'Đã ghi đè lên tập tin cũ tồn tại: "' & $iFileSavePath & '"', '', 'Warning')
						EndSwitch
				EndSwitch
			EndIf
			FileOpen($iFileSavePath, 2 + 8)
			If $iEncodingOfFileSave = 0 Then $iEncodingOfFileSave = 16
			Local $hFileOpen = FileOpen($iFileSavePath, 1 + $iEncodingOfFileSave)
			While 1
				$aCall = DllCall($dll_WinHttp, "bool", 'WinHttpReadData', "handle", $hRequest, "struct*", $tBuffer, "dword", $iBytesPerLoop, 'dword*', 0)
				If @error Or Not $aCall[0] Or Not $aCall[4] Then ExitLoop
				$vNowSizeBytes += $aCall[4]
				If $aCall[4] < $iBytesPerLoop Then
					FileWrite($hFileOpen, BinaryMid(DllStructGetData($tBuffer, 1), 1, $aCall[4]))
					If $iCheckCallbackFunc Then $CallBackFunc_Progress($vNowSizeBytes, $vTotalSizeBytes)
					ExitLoop
				Else
					FileWrite($hFileOpen, DllStructGetData($tBuffer, 1))
				EndIf
				;--------------------------------------------------------------------------------
				If $g___swCancelReadWrite Then
					$g___swCancelReadWrite = False
					If $iFileSavePath Then FileClose($hFileOpen)
					$tBuffer = ''
					Return SetError(998, __HttpRequest_ErrNotify('_WinHttpReadData_Ex', 'Đã huỷ request #1', -1), 0)
				ElseIf $iCheckCallbackFunc Then
					$CallBackFunc_Progress($vNowSizeBytes, $vTotalSizeBytes)
				EndIf
			WEnd
			$tBuffer = ''
			FileClose($hFileOpen)

		Else     ;---------------------------------------------------------------------

			While 1
				$aCall = DllCall($dll_WinHttp, "bool", 'WinHttpReadData', "handle", $hRequest, "struct*", $tBuffer, "dword", $iBytesPerLoop, 'dword*', 0)
				If @error Or Not $aCall[0] Or Not $aCall[4] Then ExitLoop
				$vNowSizeBytes += $aCall[4]
				If $aCall[4] < $iBytesPerLoop Then
					$vBinaryData &= BinaryMid(DllStructGetData($tBuffer, 1), 1, $aCall[4])
					If $iCheckCallbackFunc Then $CallBackFunc_Progress($vNowSizeBytes, $vTotalSizeBytes)
					ExitLoop
				Else
					$vBinaryData &= DllStructGetData($tBuffer, 1)
				EndIf
				;--------------------------------------------------------------------------------
				If $g___swCancelReadWrite Then
					$g___swCancelReadWrite = False
					If $iFileSavePath Then FileClose($hFileOpen)
					$tBuffer = ''
					Return SetError(998, __HttpRequest_ErrNotify('_WinHttpReadData_Ex', 'Đã huỷ request #2', -1), 0)
				ElseIf $iCheckCallbackFunc Then
					$CallBackFunc_Progress($vNowSizeBytes, $vTotalSizeBytes)
				EndIf
			WEnd
			$tBuffer = ''
			Return $vBinaryData
		EndIf
	EndFunc

	Func _WinHttpConnect2($hSession, $sServerName, $iServerPort)
		Local $aCall = DllCall($dll_WinHttp, "handle", 'WinHttpConnect', "handle", $hSession, 'wstr', $sServerName, "dword", $iServerPort, "dword", 0)
		If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
		Return $aCall[0]
	EndFunc

	Func _WinHttpSetTimeouts2($hInternet, $iConnectTimeout = 30000, $iSendTimeout = 30000, $iReceiveTimeout = 30000)
		DllCall($dll_WinHttp, "bool", 'WinHttpSetTimeouts', "handle", $hInternet, "int", 0, "int", $iConnectTimeout, "int", $iSendTimeout, "int", $iReceiveTimeout)
	EndFunc

	Func _WinHttpCloseHandle2($hInternet)
		DllCall($dll_WinHttp, "bool", 'WinHttpCloseHandle', "handle", $hInternet)
	EndFunc

	Func _WinHttpOpenRequest2($hConnect, $sVerb, $sObjectName = '', $iFlags = 0x40, $sVersion = 'HTTP/1.1')
		Local $aCall = DllCall($dll_WinHttp, "handle", 'WinHttpOpenRequest', "handle", $hConnect, 'wstr', StringUpper($sVerb), 'wstr', $sObjectName, 'wstr', StringUpper($sVersion), 'wstr', '', "ptr", 0, "dword", $iFlags)
		If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
		Return $aCall[0]
	EndFunc

	Func _WinHttpReceiveResponse2($hRequest)
		Local $aCall = DllCall($dll_WinHttp, 'bool', 'WinHttpReceiveResponse', 'handle', $hRequest, 'ptr', 0)
		If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
		Return 1
	EndFunc

	Func _WinHttpQueryDataAvailable2($hRequest, $isAsync)
		Local $aCall = DllCall($dll_WinHttp, "bool", "WinHttpQueryDataAvailable", "handle", $hRequest, $isAsync ? 'ptr' : 'dword*', 0)
		If @error Then Return SetError(1, 0, 0)
		Return SetExtended($aCall[2], $aCall[0])
	EndFunc

	Func _WinHttpSetOptionEx2($hInternet, $iOption, $vBuffer = 0, $iNoParam = False)
		Local $tBuffer, $iBuffer
		If $iNoParam Then
			Local $aCall = DllCall($dll_WinHttp, "bool", "WinHttpSetOption", "handle", $hInternet, "dword", $iOption, "ptr", 0, "dword", 0)
			If @error Or Not $aCall[0] Then Return SetError(1, 0, False)
			Return True
		ElseIf IsBinary($vBuffer) Or IsNumber($vBuffer) Then
			$iBuffer = BinaryLen($vBuffer)
			$tBuffer = DllStructCreate("byte[" & $iBuffer & "]")
			DllStructSetData($tBuffer, 1, $vBuffer)
		ElseIf IsDllStruct($vBuffer) Then
			$tBuffer = $vBuffer
			$iBuffer = DllStructGetSize($tBuffer)
		Else
			$tBuffer = DllStructCreate("wchar[" & (StringLen($vBuffer) + 1) & "]")
			$iBuffer = DllStructGetSize($tBuffer)
			DllStructSetData($tBuffer, 1, $vBuffer)
		EndIf
		Local $avResult = DllCall($dll_WinHttp, "bool", 'WinHttpSetOption', "handle", $hInternet, "dword", $iOption, "ptr", DllStructGetPtr($tBuffer), "dword", $iBuffer)
		If @error Or Not $avResult[0] Then Return SetError(2, 0, False)
		Return True
	EndFunc

	Func _WinHttpSetOption2($hInternet, $iOption, $vSetting, $iSize = -1)
		Local $sType
		If IsBinary($vSetting) Then
			$iSize = DllStructCreate("byte[" & BinaryLen($vSetting) & "]")
			DllStructSetData($iSize, 1, $vSetting)
			$vSetting = $iSize
			$iSize = DllStructGetSize($vSetting)
		EndIf
		Switch $iOption
			Case 2 To 7, 12, 13, 31, 36, 58, 63, 68, 73, 74, 77, 79, 80, 83 To 85, 88 To 92, 96, 100, 101, 110, 118
				$sType = "dword*"
				$iSize = 4
			Case 1, 86
				$sType = "ptr*"
				$iSize = 4
				If @AutoItX64 Then $iSize = 8
				If Not IsPtr($vSetting) Then Return SetError(1, 0, 0)
			Case 45
				$sType = "dword_ptr*"
				$iSize = 4
				If @AutoItX64 Then $iSize = 8
			Case 41, 0x1000 To 0x1003
				$sType = "wstr"
				If (IsDllStruct($vSetting) Or IsPtr($vSetting)) Then Return SetError(2, 0, 0)
				If $iSize < 1 Then $iSize = StringLen($vSetting)
			Case 38, 47, 59, 97, 98
				$sType = "ptr"
				If Not (IsDllStruct($vSetting) Or IsPtr($vSetting)) Then Return SetError(3, 0, 0)
			Case Else
				Return SetError(4, 0, 0)
		EndSwitch
		If $iSize < 1 Then
			If IsDllStruct($vSetting) Then
				$iSize = DllStructGetSize($vSetting)
			Else
				Return SetError(5, 0, 0)
			EndIf
		EndIf
		Local $aCall = DllCall($dll_WinHttp, "bool", 'WinHttpSetOption', "handle", $hInternet, "dword", $iOption, $sType, IsDllStruct($vSetting) ? DllStructGetPtr($vSetting) : $vSetting, "dword", $iSize)
		If @error Or Not $aCall[0] Then Return SetError(6, 0, 0)
		Return 1
	EndFunc

	Func _WinHttpQueryOptionEx2($hInternet, $iOption, $iBufferSize = 2048)
		Local $tBufferLength = DllStructCreate("dword")
		DllStructSetData($tBufferLength, 1, $iBufferSize)
		Local $tBuffer = DllStructCreate("byte[" & $iBufferSize & "]")
		Local $avResult = DllCall($dll_WinHttp, "bool", 'WinHttpQueryOption', "handle", $hInternet, "dword", $iOption, "ptr", DllStructGetPtr($tBuffer), "ptr", DllStructGetPtr($tBufferLength))
		If @error Or Not $avResult[0] Then Return SetError(1, 0, "")
		Return $tBuffer
	EndFunc

	Func _WinHttpQueryOption2($hRequest, $iOption)
		Local $aCall = DllCall($dll_WinHttp, "bool", 'WinHttpQueryOption', "handle", $hRequest, "dword", $iOption, "ptr", 0, "dword*", 0)
		If @error Or $aCall[0] Then Return SetError(1, 0, "")
		Local $iSize = $aCall[4], $tBuffer
		Switch $iOption
			Case 34, 41, 81, 82, 93, 0x1000 To 0x1003
				$tBuffer = DllStructCreate("wchar[" & $iSize + 1 & "]")
			Case 1, 21, 78
				$tBuffer = DllStructCreate("ptr")
			Case 0 To 7, 9, 24, 31, 36, 73, 74, 83, 89
				$tBuffer = DllStructCreate("int")
			Case 45
				$tBuffer = DllStructCreate("dword_ptr")
			Case Else
				$tBuffer = DllStructCreate("byte[" & $iSize & "]")
		EndSwitch
		$aCall = DllCall($dll_WinHttp, "bool", 'WinHttpQueryOption', "handle", $hRequest, "dword", $iOption, "struct*", $tBuffer, "dword*", $iSize)
		If @error Or Not $aCall[0] Then Return SetError(2, 0, "")
		Return DllStructGetData($tBuffer, 1)
	EndFunc

	Func _WinHttpSetProxy2($hInternet, $sProxy = "", $sProxyBypass = "")
		Local $tProxy = DllStructCreate("wchar sProxy[" & StringLen($sProxy) + 1 & "];wchar sProxyBypass[" & StringLen($sProxyBypass) + 1 & "]")
		$tProxy.sProxy = $sProxy
		$tProxy.sProxyBypass = $sProxyBypass
		;------------------------------------------------------------
		Local $tProxyInfo = DllStructCreate("dword AccessType;ptr Proxy;ptr ProxyBypass")
		$tProxyInfo.AccessType = 3
		$tProxyInfo.Proxy = DllStructGetPtr($tProxy, 1)
		$tProxyInfo.ProxyBypass = DllStructGetPtr($tProxy, 2)
		;------------------------------------------------------------
		_WinHttpSetOptionEx2($hInternet, 38, $tProxyInfo)
		If @error Then Return SetError(1, 0, 0)
		Return 1
	EndFunc

	Func _WinHttpSetStatusCallback2($hInternet, $pCallback, $nStatusRev)
		DllCall($dll_WinHttp, "ptr", 'WinHttpSetStatusCallback', "handle", $hInternet, "ptr", $pCallback, "dword", $nStatusRev, "ptr", 0)
	EndFunc

	Func _WinHttpSetCredentials2($hRequest, $sUserName, $sPassword, $iAuthTargets, $iAuthScheme)
		;$iAuthTargets: Server = 0x0 ;Proxy = 0x1
		;$iAuthScheme: BASIC = 0x1 ;NTLM = 0x2 ;PASSPORT = 0x4 ;DIGEST = 0x8 ;NEGOTIATE = 0x10
		If $iAuthScheme = 0x4 Then
			_WinHttpSetOption2($hRequest, 83, 0x10000000)     ;OPTION_CONFIGURE_PASSPORT_AUTH = ENABLE_PASSPORT_AUTH
			If $iAuthTargets = 0x0 Then
				_WinHttpSetOption2($hRequest, 0x1000, $sUserName)     ;OPTION_USERNAME
				_WinHttpSetOption2($hRequest, 0x1001, $sPassword)     ;OPTION_PASSWORD
			Else
				_WinHttpSetOption2($hRequest, 0x1002, $sUserName)     ;OPTION_PROXY_USERNAME
				_WinHttpSetOption2($hRequest, 0x1003, $sPassword)     ;OPTION_PROXY_PASSWORD
			EndIf
		EndIf
		Local $aCall = DllCall($dll_WinHttp, "bool", 'WinHttpSetCredentials', "handle", $hRequest, "dword", $iAuthTargets, "dword", $iAuthScheme, 'wstr', $sUserName, 'wstr', $sPassword, "ptr", 0)
		If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
		Return 1
	EndFunc

	Func _WinHttpQueryAuthSchemes2($hRequest)     ;Return AuthScheme, AuthTarget, SupportedSchemes
		Local $aCall = DllCall($dll_WinHttp, "bool", "WinHttpQueryAuthSchemes", "handle", $hRequest, "dword*", 0, "dword*", 0, "dword*", 0)
		If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
		Local $aRet = [$aCall[3], $aCall[4], $aCall[2]]
		Return $aRet
	EndFunc
	
	Func _WinHttpCrackURL2($sURL)
		Local $tURL_COMPONENTS = DllStructCreate("dword StructSize;ptr SchemeName;dword SchemeNameLength;int Scheme;ptr HostName;dword HostNameLength;word Port;ptr UserName;dword UserNameLength;ptr Password;dword PasswordLength;ptr UrlPath;dword UrlPathLength;ptr ExtraInfo;dword ExtraInfoLength")
		$tURL_COMPONENTS.StructSize = DllStructGetSize($tURL_COMPONENTS)
		Local $tBuffers[6], $iURLLen = StringLen($sURL)
		For $i = 0 To 5
			$tBuffers[$i] = DllStructCreate("wchar[" & $iURLLen + 1 & "]")
		Next
		$tURL_COMPONENTS.SchemeNameLength = $iURLLen
		$tURL_COMPONENTS.SchemeName = DllStructGetPtr($tBuffers[0])
		$tURL_COMPONENTS.HostNameLength = $iURLLen
		$tURL_COMPONENTS.HostName = DllStructGetPtr($tBuffers[1])
		$tURL_COMPONENTS.UserNameLength = $iURLLen
		$tURL_COMPONENTS.UserName = DllStructGetPtr($tBuffers[2])
		$tURL_COMPONENTS.PasswordLength = $iURLLen
		$tURL_COMPONENTS.Password = DllStructGetPtr($tBuffers[3])
		$tURL_COMPONENTS.UrlPathLength = $iURLLen
		$tURL_COMPONENTS.UrlPath = DllStructGetPtr($tBuffers[4])
		$tURL_COMPONENTS.ExtraInfoLength = $iURLLen
		$tURL_COMPONENTS.ExtraInfo = DllStructGetPtr($tBuffers[5])
		Local $aCall = DllCall($dll_WinHttp, "bool", "WinHttpCrackUrl", "wstr", $sURL, "dword", $iURLLen, "dword", 0x10000000, "struct*", $tURL_COMPONENTS)
		If @error Or Not $aCall[0] Then Return SetError(1, 0, 0)
		Local $aRet[8] = [DllStructGetData($tBuffers[0], 1), DllStructGetData($tURL_COMPONENTS, "Scheme"), DllStructGetData($tBuffers[1], 1), DllStructGetData($tURL_COMPONENTS, "Port"), DllStructGetData($tBuffers[2], 1), DllStructGetData($tBuffers[3], 1), DllStructGetData($tBuffers[4], 1), DllStructGetData($tBuffers[5], 1)]
		Return $aRet
	EndFunc
	
	Func _WinHttpCreateURL2($aURLArray)
		If UBound($aURLArray) <> 8 Then Return SetError(1, 0, "")
		Local $tURL_COMPONENTS = DllStructCreate("dword StructSize;ptr SchemeName;dword SchemeNameLength;int Scheme;ptr HostName;dword HostNameLength;word Port;ptr UserName;dword UserNameLength;ptr Password;dword PasswordLength;ptr UrlPath;dword UrlPathLength;ptr ExtraInfo;dword ExtraInfoLength;")
		$tURL_COMPONENTS.StructSize = DllStructGetSize($tURL_COMPONENTS)
		Local $tBuffers[6][2], $aURLArrayOrder = [0, 2, 4, 5, 6, 7]
		For $i = 0 To 5
			$tBuffers[$i][1] = StringLen($aURLArray[($aURLArrayOrder[$i])])
			If $tBuffers[$i][1] Then
				$tBuffers[$i][0] = DllStructCreate("wchar[" & $tBuffers[$i][1] + 1 & "]")
				DllStructSetData($tBuffers[$i][0], 1, $aURLArray[($aURLArrayOrder[$i])])
			EndIf
		Next
		$tURL_COMPONENTS.SchemeNameLength = $tBuffers[0][1]
		$tURL_COMPONENTS.SchemeName = DllStructGetPtr($tBuffers[0][0])
		$tURL_COMPONENTS.HostNameLength = $tBuffers[1][1]
		$tURL_COMPONENTS.HostName = DllStructGetPtr($tBuffers[1][0])
		$tURL_COMPONENTS.UserNameLength = $tBuffers[2][1]
		$tURL_COMPONENTS.UserName = DllStructGetPtr($tBuffers[2][0])
		$tURL_COMPONENTS.PasswordLength = $tBuffers[3][1]
		$tURL_COMPONENTS.Password = DllStructGetPtr($tBuffers[3][0])
		$tURL_COMPONENTS.UrlPathLength = $tBuffers[4][1]
		$tURL_COMPONENTS.UrlPath = DllStructGetPtr($tBuffers[4][0])
		$tURL_COMPONENTS.ExtraInfoLength = $tBuffers[5][1]
		$tURL_COMPONENTS.ExtraInfo = DllStructGetPtr($tBuffers[5][0])
		$tURL_COMPONENTS.Scheme = $aURLArray[1]
		$tURL_COMPONENTS.Port = $aURLArray[3]
		Local $aCall = DllCall($dll_WinHttp, "bool", "WinHttpCreateUrl", "struct*", $tURL_COMPONENTS, "dword", 0x80000000, "ptr", 0, "dword*", 0)
		If @error Then Return SetError(2, 0, "")
		Local $iURLLen = $aCall[4]
		Local $URLBuffer = DllStructCreate("wchar[" & ($iURLLen + 1) & "]")
		$aCall = DllCall($dll_WinHttp, "bool", "WinHttpCreateUrl", "struct*", $tURL_COMPONENTS, "dword", 0x80000000, "struct*", $URLBuffer, "dword*", $iURLLen)
		If @error Or Not $aCall[0] Then Return SetError(3, 0, "")
		Return DllStructGetData($URLBuffer, 1)
	EndFunc
#EndRegion



#Region <Chạy code javascript, php>
	Func _JS_Beautify($jsCode)
		$jsCode = StringRegExp(_HttpRequest(2, 'https://javascriptbeautifier.com/compress', 'js_code=' & _URIEncode($jsCode) & '&js_code_result=&beautify=true'), '(?is)"mini":"(.+?)"\}$', 1)
		If @error Or StringInStr($jsCode[0], 'undefined","error"', 0, 1, 1, 30) Then Return SetError(1, __HttpRequest_ErrNotify('_JS_Beautify', 'Làm đẹp Js thất bại'), '')
		Return StringRegExpReplace(StringReplace($jsCode[0], '\n', @CRLF), '\\([''"])', '$1')
	EndFunc

	Func _JS_Compress($jsCode)
		$jsCode = _HttpRequest(2, 'https://javascript-minifier.com/raw', 'input=' & _URIEncode($jsCode))
		If @error Or $jsCode = '' Or StringInStr($jsCode, '// Error:', 0, 1, 1, 10) Then Return SetError(1, __HttpRequest_ErrNotify('_JS_Compress', 'Làm gọn Js thất bại'), $jsCode)
		Return $jsCode
	EndFunc

	Func _JS_ToStringAu3($jsMode = 0)     ;0: Chỉ chuyển sang string, 1: Compress trước khi chuyển, 2: beautify trước khi chuyển
		Local $jsCode = ClipGet()
		If Not $jsCode Then Return SetError(1, MsgBox(4096, 'Lỗi', 'Hãy copy đoạn js cần chuyển thành string Au3 trước khi chạy hàm này'), '')
		;-----------------------------------------------------------------------------------------------------------
		Switch $jsMode
			Case 1
				$jsCode = _JS_Compress($jsCode)
			Case 2
				$jsCode = _JS_Beautify($jsCode)
		EndSwitch
		If @error Or Not $jsCode Then Return SetError(2, __HttpRequest_ErrNotify('_JS_ToStringAu3', 'Làm đẹp/Làm gọn Js thất bại'), '')
		;-----------------------------------------------------------------------------------------------------------
		$jsCode = StringStripCR(StringRegExpReplace($jsCode, '(?m)^\h*$[\r\n]+', ''))
		$jsCode = StringRegExpReplace(StringReplace($jsCode, "'", "''", 0, 1), '(?m)^', "'")
		$jsCode = StringTrimRight(StringRegExpReplace($jsCode, '(?m)($)', "' & @CRLF & _"), 3)
		ClipPut($jsCode)
		MsgBox(4096, 'Thông báo', 'Đã lưu kết quả chuyển đổi vào Clipboard')
	EndFunc

;~ 	Func _JS_Execute_Ex($iURL, $sHTML_by_HR_iURL, $sJSCode, $vRet_oIE = False, $vTester = False)
;~ 		If $sJSCode And Not StringInStr($sJSCode, 'document.write(') And $sHTML_by_HR_iURL <> '' Then $sJSCode = 'document.write(' & $sJSCode & ')'
;~ 		If $iURL = '' Then $iURL = 'about:blank'
;~ 		;-------------------------------------------------------------------------------------------------------------------
;~ 		Local $__oIE, $__oScript, $__oScriptText, $sRet, $vError = 0
;~ 		$__oIE = ObjCreate("Shell.Explorer.2")
;~ 		GUICreate("JS Execute", $vTester * 400, $vTester * 400)
;~ 		GUICtrlCreateObj($__oIE, 0, 0, $vTester * 400, $vTester * 400)
;~ 		If $vTester Then GUISetState()
;~ 		$g___oErrorStop = 1
;~ 		With $__oIE
;~ 			.navigate($iURL)
;~ 			While .busy()
;~ 				Sleep(50)
;~ 			WEnd
;~ 			If $sHTML_by_HR_iURL <> '' Then
;~ 				.document.write($sHTML_by_HR_iURL)
;~ 				.document.close()
;~ 			EndIf
;~ 			If $vTester Then MsgBox(4096, 'Waiting....', 'Click OK to continue')
;~ 			If $sJSCode Then
;~ 				$__oScript = .document.createElement("script")
;~ 				$vError = @error
;~ 				$__oScriptText = .document.createTextNode($sJSCode)
;~ 				$vError = @error
;~ 				$__oScript.appendChild($__oScriptText)
;~ 				$vError = @error
;~ 				.document.body.appendChild($__oScript)
;~ 				$vError = @error
;~ 			EndIf
;~ 			Sleep(10)
;~ 			$sRet = .document.body.innerText
;~ 			$vError = @error
;~ 		EndWith
;~ 		$g___oErrorStop = 0
;~ 		Return SetError($vError, '', $vRet_oIE ? $__oIE : $sRet)
;~ 	EndFunc


	Func _JS_Execute_Ex($iURL_Or_oIE, $sHTML_by_HR_iURL, $sJSCode, $vRet_Include_oIE = False, $iFuncCallback = '', $vTester = False)
		Local $__oIE, $sRet, $vError = 0
		If IsObj($iURL_Or_oIE) Then
			$__oIE = $iURL_Or_oIE
		Else
			If $iURL_Or_oIE == '' Or IsKeyword($iURL_Or_oIE) Then $iURL_Or_oIE = 'about:blank'
			$__oIE = ObjCreate("Shell.Explorer.2")
			Local $hIE = GUICreate("JS Execute", $vTester * 400, $vTester * 400)
			GUICtrlCreateObj($__oIE, 0, 0, $vTester * 400, $vTester * 400)
			If $vTester Then GUISetState()
			$g___oErrorStop = 1
			$__oIE.navigate($iURL_Or_oIE)
			While $__oIE.busy()
				Sleep(50)
			WEnd
		EndIf
		If $sHTML_by_HR_iURL <> '' Then
			$__oIE.document.write($sHTML_by_HR_iURL)
			$__oIE.document.close()
		EndIf
		;-------------------------------------------------------
		If IsArray($iFuncCallback) Then
			Local $FuncCallbackName = $iFuncCallback[0]
			$iFuncCallback[0] = 'CallArgArray'
			Call($FuncCallbackName, $iFuncCallback)
		ElseIf $iFuncCallback Then
			Call($iFuncCallback)
		EndIf
		;-------------------------------------------------------
		If $vTester Then MsgBox(4096, 'Waiting....', 'Click OK to continue')
		$sRet = $__oIE.document.parentwindow.eval($sJSCode)
		$vError = @error
		$g___oErrorStop = 0
		If $vRet_Include_oIE Then
			Local $aRet[3] = [$sRet, $__oIE, _IE_GetCookie($iURL_Or_oIE)]
			Return SetError($vError, '', $aRet)
		Else
			$__oIE = 0 * GUIDelete($hIE)
			Return SetError($vError, '', $sRet)
		EndIf
	EndFunc


	Func _JS_Execute($LibraryJS, $sCodeJS, $Name_Var_Return_Val, $ModeIE = False, $PathTempLibJS = Default)
		If FileExists($PathTempLibJS) Then
			If StringRight($PathTempLibJS, 1) <> '\' Then $PathTempLibJS &= '\'
		Else
			$PathTempLibJS = @TempDir & '\'
		EndIf
		Local $TempPath, $hOpen, $iError = 0, $sLibraryJS = ''
		;--------------------------------------------------------------------------------------------------
		If FileExists($sCodeJS) Then $sCodeJS = FileRead($sCodeJS)
		If StringInStr($Name_Var_Return_Val, '.', 1, 1) Then
			Local $Name_Var_Return_Val_tmp = $Name_Var_Return_Val
			$Name_Var_Return_Val = StringReplace($Name_Var_Return_Val, '.', '', 1, 1)
			$sCodeJS = StringReplace($sCodeJS, $Name_Var_Return_Val_tmp, $Name_Var_Return_Val, 1, 1)
		EndIf
		$sCodeJS = StringRegExpReplace($sCodeJS, '(?i)(location.href=)(".*?"|''.*?'')', '')
		;--------------------------------------------------------------------------------------------------
		If $LibraryJS Or IsArray($LibraryJS) Then
			If Not IsArray($LibraryJS) Then $LibraryJS = StringSplit($LibraryJS, '|', 2)
			For $i = 0 To UBound($LibraryJS) - 1
				If StringRegExp($LibraryJS[$i], '(?i)^https?://') Then
					$TempPath = $PathTempLibJS & StringRight(StringRegExpReplace($LibraryJS[$i], '(?i)(\.js|\W+)', '-'), 200) & '.js'
					If FileExists($TempPath) And FileGetSize($TempPath) > 2 Then
						$LibraryJS[$i] = FileRead($TempPath)
					Else
						$LibraryJS[$i] = _HttpRequest(2, $LibraryJS[$i])
						If @error Or Not $LibraryJS[$i] Then $iError = 301
						$hOpen = FileOpen($TempPath, 2 + 32 + 8)
						FileWrite($hOpen, $LibraryJS[$i])
						FileClose($hOpen)
					EndIf
				Else
					$LibraryJS[$i] = FileRead($LibraryJS[$i])
				EndIf
				$sLibraryJS &= $LibraryJS[$i] & ';' & @CRLF
			Next
		EndIf
		;-----------------------------------------------------------------------------------------------------------------------------------------------
		Static $sJsLibJSON = _
				'if(typeof JSON!=="object"){JSON={}}(function(){"use strict";var rx_one=/^[\],:{}\s]*$/;var rx_two=/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g;var rx_three=/' & _
				'"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g;var rx_four=/(?:^|:|,)(?:\s*\[)+/g;var rx_escapable=/[\\"\u0000-\u001f\u007f-\u009f\' & _
				'u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;var rx_dangerous=/[\u0000\u00ad\u0600-\u0604\u070f\u' & _
				'17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g;function f(n){return(n<10)?"0"+n:n}function this_value(){return this.valueOf()' & _
				'}if(typeof Date.prototype.toJSON!=="function"){Date.prototype.toJSON=function(){return isFinite(this.valueOf())?(this.getUTCFullYear()+"-"+f(this.getU' & _
				'TCMonth()+1)+"-"+f(this.getUTCDate())+"T"+f(this.getUTCHours())+":"+f(this.getUTCMinutes())+":"+f(this.getUTCSeconds())+"Z"):null};Boolean.prototype.t' & _
				'oJSON=this_value;Number.prototype.toJSON=this_value;String.prototype.toJSON=this_value}var gap;var indent;var meta;var rep;function quote(string){rx_e' & _
				'scapable.lastIndex=0;return rx_escapable.test(string)?"\""+string.replace(rx_escapable,function(a){var c=meta[a];return typeof c==="string"?c:"\\u"+("' & _
				'0000"+a.charCodeAt(0).toString(16)).slice(-4)})+"\"":"\""+string+"\""}function str(key,holder){var i;var k;var v;var length;var mind=gap;var partial;v' & _
				'ar value=holder[key];if(value&&typeof value==="object"&&typeof value.toJSON==="function"){value=value.toJSON(key)}if(typeof rep==="function"){value=re' & _
				'p.call(holder,key,value)}switch(typeof value){case"string":return quote(value);case"number":return(isFinite(value))?String(value):"null";case"boolean"' & _
				':case"null":return String(value);case"object":if(!value){return"null"}gap+=indent;partial=[];if(Object.prototype.toString.apply(value)==="[object Arra' & _
				'y]"){length=value.length;for(i=0;i<length;i+=1){partial[i]=str(i,value)||"null"}v=partial.length===0?"[]":gap?("[\n"+gap+partial.join(",\n"+gap)+"\n"+' & _
				'mind+"]"):"["+partial.join(",")+"]";gap=mind;return v}if(rep&&typeof rep==="object"){length=rep.length;for(i=0;i<length;i+=1){if(typeof rep[i]==="stri' & _
				'ng"){k=rep[i];v=str(k,value);if(v){partial.push(quote(k)+((gap)?": ":":")+v)}}}}else{for(k in value){if(Object.prototype.hasOwnProperty.call(value,k))' & _
				'{v=str(k,value);if(v){partial.push(quote(k)+((gap)?": ":":")+v)}}}}v=partial.length===0?"{}":gap?"{\n"+gap+partial.join(",\n"+gap)+"\n"+mind+"}":"{"+p' & _
				'artial.join(",")+"}";gap=mind;return v}}if(typeof JSON.stringify!=="function"){meta={"\b":"\\b","\t":"\\t","\n":"\\n","\f":"\\f","\r":"\\r","\"":"\\\"' & _
				'","\\":"\\\\"};JSON.stringify=function(value,replacer,space){var i;gap="";indent="";if(typeof space==="number"){for(i=0;i<space;i+=1){indent+=" "}}els' & _
				'e if(typeof space==="string"){indent=space}rep=replacer;if(replacer&&typeof replacer!=="function"&&(typeof replacer!=="object"||typeof replacer.length' & _
				'!=="number")){throw new Error("JSON.stringify");}return str("",{"":value})}}if(typeof JSON.parse!=="function"){JSON.parse=function(text,reviver){var j' & _
				';function walk(holder,key){var k;var v;var value=holder[key];if(value&&typeof value==="object"){for(k in value){if(Object.prototype.hasOwnProperty.cal' & _
				'l(value,k)){v=walk(value,k);if(v!==undefined){value[k]=v}else{delete value[k]}}}}return reviver.call(holder,key,value)}text=String(text);rx_dangerous.' & _
				'lastIndex=0;if(rx_dangerous.test(text)){text=text.replace(rx_dangerous,function(a){return("\\u"+("0000"+a.charCodeAt(0).toString(16)).slice(-4))})}if(' & _
				'rx_one.test(text.replace(rx_two,"@").replace(rx_three,"]").replace(rx_four,""))){j=eval("("+text+")");return(typeof reviver==="function")?walk({"":j},' & _
				'""):j}throw new SyntaxError("JSON.parse");}}}())'
		;-----------------------------------------------------------------------------------------------------------
		$sCodeJS = @CRLF & $sLibraryJS & ';' & @CRLF & $sJsLibJSON & ';' & @CRLF & StringReplace($sCodeJS, 'document.write();', '', 1, 1) & '; document.write(' & $Name_Var_Return_Val & ');'
		;-----------------------------------------------------------------------------------------------------------
		If $ModeIE Then
			Local $oIE = ObjCreate("InternetExplorer.Application")
			With $oIE
				.navigate('about:blank')
				.document.write('<script>' & $sCodeJS & '</script>')
				.document.close()
				While .busy()
					Sleep(10)
				WEnd
				$sCodeJS = .document.body.innerText
				If StringRight($sCodeJS, 1) == ' ' Then $sCodeJS = StringTrimRight($sCodeJS, 1)
				.quit()
				ProcessClose('ielowutil.exe')
			EndWith
		Else
			$sCodeJS = _HTML_Execute($sCodeJS)
			If @error Then $iError = 302
		EndIf
		;-----------------------------------------------------------------------------------------------------------
		Return SetError($iError, '', $sCodeJS)
	EndFunc


	;Method: compressToBase64, decompressFromBase64, compressToUTF16, decompressFromUTF16, compressToEncodedURIComponent, decompressFromEncodedURIComponent, compress, decompress
	Func _Js_LZString()
		Static $sJsLibLZString = _
				'var LZString=function(){function o(o,r){if(!t[o]){t[o]={};for(var n=0;n<o.length;n++)t[o][o.charAt(n)]=n}return t[o][r]}var r=String.fromCha' & _
				'rCode,n="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",e="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz' & _
				'0123456789+-$",t={},i={compressToBase64:function(o){if(null==o)return"";var r=i._compress(o,6,function(o){return n.charAt(o)});switch(r.length%4){def' & _
				'ault:case 0:return r;case 1:return r+"===";case 2:return r+"==";case 3:return r+"="}},decompressFromBase64:function(r){return null==r?"":""=' & _
				'=r?null:i._decompress(r.length,32,function(e){return o(n,r.charAt(e))})},compressToUTF16:function(o){return null==o?"":i._compress(o,15,func' & _
				'tion(o){return r(o+32)})+" "},decompressFromUTF16:function(o){return null==o?"":""==o?null:i._decompress(o.length,16384,function(r){return o' & _
				'.charCodeAt(r)-32})},compressToUint8Array:function(o){for(var r=i.compress(o),n=new Uint8Array(2*r.length),e=0,t=r.length;t>e;e++){var s=r.c' & _
				'harCodeAt(e);n[2*e]=s>>>8,n[2*e+1]=s%256}return n},decompressFromUint8Array:function(o){if(null===o||void 0===o)return i.decompress(o);for(v' & _
				'ar n=new Array(o.length/2),e=0,t=n.length;t>e;e++)n[e]=256*o[2*e]+o[2*e+1];var s=[];return n.forEach(function(o){s.push(r(o))}),i.decompress' & _
				'(s.join(""))},compressToEncodedURIComponent:function(o){return null==o?"":i._compress(o,6,function(o){return e.charAt(o)})},decompressFromEn' & _
				'codedURIComponent:function(r){return null==r?"":""==r?null:(r=r.replace(/ /g,"+"),i._decompress(r.length,32,function(n){return o(e,r.charAt(' & _
				'n))}))},compress:function(o){return i._compress(o,16,function(o){return r(o)})},_compress:function(o,r,n){if(null==o)return"";var e,t,i,s={}' & _
				',p={},u="",c="",a="",l=2,f=3,h=2,d=[],m=0,v=0;for(i=0;i<o.length;i+=1)if(u=o.charAt(i),Object.prototype.hasOwnProperty.call(s,u)||(s[u]=f++,' & _
				'p[u]=!0),c=a+u,Object.prototype.hasOwnProperty.call(s,c))a=c;else{if(Object.prototype.hasOwnProperty.call(p,a)){if(a.charCodeAt(0)<256){for(e=0;h>e' & _
				';e++)m<<=1,v==r-1?(v=0,d.push(n(m)),m=0):v++;for(t=a.charCodeAt(0),e=0;8>e;e++)m=m<<1|1&t,v==r-1?(v=0,d.push(n(m)),m=0):v++,t>>=1}els' & _
				'e{for(t=1,e=0;h>e;e++)m=m<<1|t,v==r-1?(v=0,d.push(n(m)),m=0):v++,t=0;for(t=a.charCodeAt(0),e=0;16>e;e++)m=m<<1|1&t,v==r-1?(v=0,d.push(n(m)),' & _
				'm=0):v++,t>>=1}l--,0==l&&(l=Math.pow(2,h),h++),delete p[a]}else for(t=s[a],e=0;h>e;e++)m=m<<1|1&t,v==r-1?(v=0,d.push(n(m)),m=0):v++,t>>=1;l-' & _
				'-,0==l&&(l=Math.pow(2,h),h++),s[c]=f++,a=String(u)}if(""!==a){if(Object.prototype.hasOwnProperty.call(p,a)){if(a.charCodeAt(0)<256){for(e=0;' & _
				'h>e;e++)m<<=1,v==r-1?(v=0,d.push(n(m)),m=0):v++;for(t=a.charCodeAt(0),e=0;8>e;e++)m=m<<1|1&t,v==r-1?(v=0,d.push(n(m)),m=0):v++,t>>=1}else{fo' & _
				'r(t=1,e=0;h>e;e++)m=m<<1|t,v==r-1?(v=0,d.push(n(m)),m=0):v++,t=0;for(t=a.charCodeAt(0),e=0;16>e;e++)m=m<<1|1&t,v==r-1?(v=0,d.push(n(m)),m=0)' & _
				':v++,t>>=1}l--,0==l&&(l=Math.pow(2,h),h++),delete p[a]}else for(t=s[a],e=0;h>e;e++)m=m<<1|1&t,v==r-1?(v=0,d.push(n(m)),m=0):v++,t>>=1;l--,0=' & _
				'=l&&(l=Math.pow(2,h),h++)}for(t=2,e=0;h>e;e++)m=m<<1|1&t,v==r-1?(v=0,d.push(n(m)),m=0):v++,t>>=1;for(;;){if(m<<=1,v==r-1){d.push(n(m));break' & _
				'}v++}return d.join("")},decompress:function(o){return null==o?"":""==o?null:i._decompress(o.length,32768,function(r){return o.charCodeAt(r)}' & _
				')},_decompress:function(o,n,e){var t,i,s,p,u,c,a,l,f=[],h=4,d=4,m=3,v="",w=[],A={val:e(0),position:n,index:1};for(i=0;3>i;i+=1)f[i]=i;for(p=' & _
				'0,c=Math.pow(2,2),a=1;a!=c;)u=A.val&A.position,A.position>>=1,0==A.position&&(A.position=n,A.val=e(A.index++)),p|=(u>0?1:0)*a,a<<=1;switch(t' & _
				'=p){case 0:for(p=0,c=Math.pow(2,8),a=1;a!=c;)u=A.val&A.position,A.position>>=1,0==A.position&&(A.position=n,A.val=e(A.index++)),p|=(u>0?1:0)' & _
				'*a,a<<=1;l=r(p);break;case 1:for(p=0,c=Math.pow(2,16),a=1;a!=c;)u=A.val&A.position,A.position>>=1,0==A.position&&(A.position=n,A.val=e(A.ind' & _
				'ex++)),p|=(u>0?1:0)*a,a<<=1;l=r(p);break;case 2:return""}for(f[3]=l,s=l,w.push(l);;){if(A.index>o)return"";for(p=0,c=Math.pow(2,m),a=1;a!=c;' & _
				')u=A.val&A.position,A.position>>=1,0==A.position&&(A.position=n,A.val=e(A.index++)),p|=(u>0?1:0)*a,a<<=1;switch(l=p){case 0:for(p=0,c=Math.p' & _
				'ow(2,8),a=1;a!=c;)u=A.val&A.position,A.position>>=1,0==A.position&&(A.position=n,A.val=e(A.index++)),p|=(u>0?1:0)*a,a<<=1;f[d++]=r(p),l=d-1,' & _
				'h--;break;case 1:for(p=0,c=Math.pow(2,16),a=1;a!=c;)u=A.val&A.position,A.position>>=1,0==A.position&&(A.position=n,A.val=e(A.index++)),p|=(u' & _
				'>0?1:0)*a,a<<=1;f[d++]=r(p),l=d-1,h--;break;case 2:return w.join("")}if(0==h&&(h=Math.pow(2,m),m++),f[l])v=f[l];else{if(l!==d)return null;v=' & _
				's+s.charAt(0)}w.push(v),f[d++]=s+v.charAt(0),h--,s=v,0==h&&(h=Math.pow(2,m),m++)}}};return i}();"function"==typeof define&&define.amd?define' & _
				'(function(){return LZString}):"undefined"!=typeof module&&null!=module&&(module.exports=LZString);'
		Global $oHTML_CreateLZStringObj = ObjCreate("HTMLFILE")
		If @error Or Not IsObj($oHTML_CreateLZStringObj) Then Return SetError(1, __HttpRequest_ErrNotify('_Js_LZString', 'Tạo HTMLFile Object thất bại'), '')
		$oHTML_CreateLZStringObj.parentwindow.execScript($sJsLibLZString)
		If @error Then Return SetError(2, __HttpRequest_ErrNotify('_Js_LZString', 'Không thể nạp thư viện LZString cho HTMLFile Object'), '')
		$oLZString = $oHTML_CreateLZStringObj.parentwindow.eval('LZString')
		If @error Or Not IsObj($oLZString) Then Return SetError(3, __HttpRequest_ErrNotify('_Js_LZString', 'Khởi tạo thư viện LZString thất bại'), '')
		Return $oLZString
	EndFunc


	Func _PHP_Execute($phpData, $Name_Var_Return_Val, $BinaryMode = False, $phpVersion = Default)
		If Not $phpVersion Or $phpVersion = Default Then $phpVersion = '7.2.4'
		If StringLeft($Name_Var_Return_Val, 1) <> '$' Then $Name_Var_Return_Val = '$' & $Name_Var_Return_Val
		If Not StringInStr($phpData, '<?php') Then $phpData = '<?php' & @CRLF & $phpData
		If StringRegExp($phpData, '(?is)\?>\h*?$') Then $phpData = StringRegExpReplace($phpData, '(?is)\?>\h*?$', '')
		Local $rq = _HttpRequest($BinaryMode ? 3 : 2, 'http://sandbox.onlinephpfunctions.com/', 'code=' & _URIEncode($phpData & ';' & @CRLF & 'echo ' & $Name_Var_Return_Val & ';') & '&phpVersion=' & StringReplace($phpVersion, '.', '_', 0, 1) & '&output=Textbox&ajaxResult=1')
		$phpData = StringRegExp($rq, '(?i)' & ($BinaryMode ? '3C746578746172656120(?:..)+3E(.*?)3C2F74657874617265613E' : '<textarea [^>]+>(.*?)</textarea>'), 1)
		If @error Then Return SetError(1, '', '')
		Return $BinaryMode ? Binary('0x' & $phpData[0]) : _HTMLDecode($phpData[0])
	EndFunc
#EndRegion


#Region <HTML Entities>
	Func __HTML_Entities_Decode($sHTML, $iModeIE = False)
		If $iModeIE = Default Then $iModeIE = False
		If $iModeIE Then
			$sHTML = _HTML_Execute(StringReplace($sHTML, '&#xD;', '<hr>'))
		Else
			If Not IsObj($g___oDicEntity) Then
				$g___oDicEntity = __HTML_Entities_Init()
				If @error Then Return SetError(2, __HttpRequest_ErrNotify('__HTML_Entities_Decode', 'Khởi tạo __HTML_Entities_Init thất bại'), $sHTML)
			EndIf
			;---------------------------------------------------------------------
			Local $aText = StringRegExp($sHTML, '\&\#(\d+)\;', 3)
			If Not @error Then
				For $i = 0 To UBound($aText) - 1
					$sHTML = StringReplace($sHTML, '&#' & $aText[$i] & ';', ChrW($aText[$i]), 0, 1)
				Next
			EndIf
			;---------------------------------------------------------------------
			$aText = StringRegExp($sHTML, '\&([a-zA-Z]{2,10})\;', 3)
			If Not @error Then
				For $i = 0 To UBound($aText) - 1
					$sHTML = StringReplace($sHTML, '&' & $aText[$i] & ';', $g___oDicEntity.item($aText[$i]), 0, 1)
				Next
			EndIf
		EndIf
		Return $sHTML
	EndFunc

	Func __HTML_Entities_Init()
		If $g___aChrEnt == '' Then
			Local $aisEntities[246][2] = [[34, 'quot'], [38, 'amp'], [39, 'apos'], [60, 'lt'], [62, 'gt'], [160, 'nbsp'], [161, 'iexcl'], [162, 'cent'], [163, 'pound'], [164, 'curren'], [165, 'yen'], [166, 'brvbar'], [167, 'sect'], [168, 'uml'], [169, 'copy'], [170, 'ordf'], [171, 'laquo'], [172, 'not'], [173, 'shy'], [174, 'reg'], [175, 'macr'], [176, 'deg'], [177, 'plusmn'], [180, 'acute'], [181, 'micro'], [182, 'para'], [183, 'middot'], [184, 'cedil'], [186, 'ordm'], [187, 'raquo'], [191, 'iquest'], [192, 'Agrave'], [193, 'Aacute'], [194, 'Acirc'], [195, 'Atilde'], [196, 'Auml'], [197, 'Aring'], [198, 'AElig'], [199, 'Ccedil'], [200, 'Egrave'], [201, 'Eacute'], [202, 'Ecirc'], [203, 'Euml'], [204, 'Igrave'], [205, 'Iacute'], [206, 'Icirc'], [207, 'Iuml'], [208, 'ETH'], [209, 'Ntilde'], [210, 'Ograve'], [211, 'Oacute'], [212, 'Ocirc'], [213, 'Otilde'], [214, 'Ouml'], [215, 'times'], [216, 'Oslash'], [217, 'Ugrave'], [218, 'Uacute'], [219, 'Ucirc'], [220, 'Uuml'], _
					[221, 'Yacute'], [222, 'THORN'], [223, 'szlig'], [224, 'agrave'], [225, 'aacute'], [226, 'acirc'], [227, 'atilde'], [228, 'auml'], [229, 'aring'], [230, 'aelig'], [231, 'ccedil'], [232, 'egrave'], [233, 'eacute'], [234, 'ecirc'], [235, 'euml'], [236, 'igrave'], [237, 'iacute'], [238, 'icirc'], [239, 'iuml'], [240, 'eth'], [241, 'ntilde'], [242, 'ograve'], [243, 'oacute'], [244, 'ocirc'], [245, 'otilde'], [246, 'ouml'], [247, 'divide'], [248, 'oslash'], [249, 'ugrave'], [250, 'uacute'], [251, 'ucirc'], [252, 'uuml'], [253, 'yacute'], [254, 'thorn'], [255, 'yuml'], [338, 'OElig'], [339, 'oelig'], [352, 'Scaron'], [353, 'scaron'], [376, 'Yuml'], [402, 'fnof'], [710, 'circ'], [732, 'tilde'], [913, 'Alpha'], [914, 'Beta'], [915, 'Gamma'], [916, 'Delta'], [917, 'Epsilon'], [918, 'Zeta'], [919, 'Eta'], [920, 'Theta'], [921, 'Iota'], [922, 'Kappa'], [923, 'Lambda'], [924, 'Mu'], [925, 'Nu'], [926, 'Xi'], [927, 'Omicron'], [928, 'Pi'], [929, 'Rho'], _
					[931, 'Sigma'], [932, 'Tau'], [933, 'Upsilon'], [934, 'Phi'], [935, 'Chi'], [936, 'Psi'], [937, 'Omega'], [945, 'alpha'], [946, 'beta'], [947, 'gamma'], [948, 'delta'], [949, 'epsilon'], [950, 'zeta'], [951, 'eta'], [952, 'theta'], [953, 'iota'], [954, 'kappa'], [955, 'lambda'], [956, 'mu'], [957, 'nu'], [958, 'xi'], [959, 'omicron'], [960, 'pi'], [961, 'rho'], [962, 'sigmaf'], [963, 'sigma'], [964, 'tau'], [965, 'upsilon'], [966, 'phi'], [967, 'chi'], [968, 'psi'], [969, 'omega'], [977, 'thetasym'], [978, 'upsih'], [982, 'piv'], [8194, 'ensp'], [8195, 'emsp'], [8201, 'thinsp'], [8204, 'zwnj'], [8205, 'zwj'], [8206, 'lrm'], [8207, 'rlm'], [8211, 'ndash'], [8212, 'mdash'], [8216, 'lsquo'], [8217, 'rsquo'], [8218, 'sbquo'], [8220, 'ldquo'], [8221, 'rdquo'], [8222, 'bdquo'], [8224, 'dagger'], [8225, 'Dagger'], [8226, 'bull'], [8230, 'hellip'], [8240, 'permil'], [8242, 'prime'], [8243, 'Prime'], [8249, 'lsaquo'], [8250, 'rsaquo'], _
					[8254, 'oline'], [8260, 'frasl'], [8364, 'euro'], [8465, 'image'], [8472, 'weierp'], [8476, 'real'], [8482, 'trade'], [8501, 'alefsym'], [8592, 'larr'], [8593, 'uarr'], [8594, 'rarr'], [8595, 'darr'], [8596, 'harr'], [8629, 'crarr'], [8656, 'lArr'], [8657, 'uArr'], [8658, 'rArr'], [8659, 'dArr'], [8660, 'hArr'], [8704, 'forall'], [8706, 'part'], [8707, 'exist'], [8709, 'empty'], [8711, 'nabla'], [8712, 'isin'], [8713, 'notin'], [8715, 'ni'], [8719, 'prod'], [8721, 'sum'], [8722, 'minus'], [8727, 'lowast'], [8730, 'radic'], [8733, 'prop'], [8734, 'infin'], [8736, 'ang'], [8743, 'and'], [8744, 'or'], [8745, 'cap'], [8746, 'cup'], [8747, 'int'], [8764, 'sim'], [8773, 'cong'], [8776, 'asymp'], [8800, 'ne'], [8801, 'equiv'], [8804, 'le'], [8805, 'ge'], [8834, 'sub'], [8835, 'sup'], [8836, 'nsub'], [8838, 'sube'], [8839, 'supe'], [8853, 'oplus'], [8855, 'otimes'], [8869, 'perp'], [8901, 'sdot'], [8968, 'lceil'], [8969, 'rceil'], [8970, 'lfloor'], [8971, 'rfloor'], [9001, 'lang'], [9002, 'rang'], [9674, 'loz'], [9824, 'spades'], [9827, 'clubs'], [9829, 'hearts'], [9830, 'diams']]
			$g___aChrEnt = $aisEntities
		EndIf
		$g___oDicEntity = ObjCreate("Scripting.Dictionary")
		If @error Or Not IsObj($g___oDicEntity) Then Return SetError(1)
		For $i = 0 To UBound($g___aChrEnt) - 1
			$g___oDicEntity.Add($g___aChrEnt[$i][1], ChrW($g___aChrEnt[$i][0]))
		Next
		Return $g___oDicEntity
	EndFunc

	Func __HTML_RegexpReplace($sData, $Escape_Character_Head, $Escape_Character_Tail, $iForceANSI, $iHexLength, $isHexNumber = True)
		Local $Chr_or_WChar = ($iHexLength = 2 ? 'Chr' : 'ChrW')
		If $Escape_Character_Tail And $Escape_Character_Tail <> Default Then $Chr_or_WChar = 'ChrW'
		If $iForceANSI Then $Chr_or_WChar = 'Chr'
		Local $sResult = Call('Execute', '"' & StringRegExpReplace(StringReplace($sData, '"', '""', 0, 1), '(?i)' & StringReplace($Escape_Character_Head, '\', '\\', 0, 1) & '([[:xdigit:]]{' & $iHexLength & '})' & $Escape_Character_Tail, '" & ' & $Chr_or_WChar & '(' & ($isHexNumber ? '0x' : '') & '${1}) & "') & '"')
		If $sResult == '' Then Return SetError(1, '', $sData)
		Return StringRegExpReplace($sResult, '\\([\\/"''\?:])', '\1')
	EndFunc

	Func _HTML_AbsoluteURL($sSource, $sURL, $sAdditional_Pattern = '', $sProtocol = '')
		If Not StringRegExp($sSource, '(?i)<\h*?base .*?href\h*?=') Then
			$sSource = '<base href="' & $sURL & '"/><script>var _b = document.getElementsByTagName("base")[0], _bH = "' & $sURL & '";if (_b && _b.href != _bH) _b.href = _bH;</script>' & @CRLF & $sSource
		EndIf
		;-------------------------------------------------------------------------------------------------------
		If $sAdditional_Pattern Then $sAdditional_Pattern &= '|'
		Local $basePattern = '(?i)(' & $sAdditional_Pattern & '(?:window\.location|\W(?:src|href)|v-bind:src|param name\h*?=\h*?["'']movie["'']\h+value)\h*?=\h*?["'']*?|attr\([''"]src[''"]\h*?,\h*?[''"])(?!https?:|javascript:|\&|\#)'
		;-------------------------------------------------------------------------------------------------------
		$sURL = StringRegExpReplace($sURL, '(?i)^(.*?)/[^/]+\.(?:php|html|aspx).*$', '$1')
		$sURL = StringRegExpReplace($sURL, '/$', '')
		;-------------------------------------------------------------------------------------------------------
		Local $aURL = StringRegExp($sURL, '(?i)^(https?://[^/]+)(/?)(.*)/?$', 3)
		If @error Then Return SetError(1, '', $sSource)
		;href='//' ----------------------------------------------------------
		$sSource = StringRegExpReplace($sSource, $basePattern & '//', '$1' & $sProtocol & '://')
		;href='/' ----------------------------------------------------------
		$sSource = StringRegExpReplace($sSource, $basePattern & '/', '$1' & $aURL[0] & '/')
		;href='./' ----------------------------------------------------------
		$sSource = StringRegExpReplace($sSource, $basePattern & '\./', '$1' & $sURL & '/')
		;href='' ----------------------------------------------------------
;~ 		$sSource = StringRegExpReplace($sSource, $basePattern & '([^/\."''])', '$1' & $sURL & '/$2')
		;href='../' -------------------------------------------------------------------
		Local $regSource = StringRegExp($sSource, $basePattern & '((?:\.\./)+)', 3), $memReg = '|', $sRegAttach
		If Not @error Then
			Local $baseURL = ''
			For $i = 0 To UBound($regSource) - 1 Step 2
				$sRegAttach = $regSource[$i] & $regSource[$i + 1]
				If StringInStr($memReg, '|' & $sRegAttach & '|', 0, 1) Then ContinueLoop
				$baseURL = $aURL[2]
				For $j = 1 To (StringLen($regSource[$i + 1]) / 3) + 1     ;số lần Back
					$baseURL = StringRegExpReplace($baseURL, '(?:/|^)[^/]+$', '')
				Next
				$sSource = StringRegExpReplace($sSource, '\Q' & $sRegAttach & '\E', $regSource[$i] & $aURL[0] & '/' & ($baseURL ? $baseURL & '/' : ''))
				$memReg &= $sRegAttach & '|'
			Next
		EndIf
		Return $sSource
	EndFunc

	Func _HTML_Rel2AbsURL($sBaseURL, $sReplaceURL)     ;Ex: _HTML_Rel2AbsURL( 'http://www.autoitvn.com/abc/xyz/123.php', '../qwe/tyu/456.php')
		Local $countReplace = 0, $countModify = 0, $aBaseURL, $aBaseURL_Replace, $aReplaceURL
		$sReplaceURL = StringStripWS($sReplaceURL, 8)
		If $sReplaceURL = './' Or $sReplaceURL = '../' Then
			$sReplaceURL &= '$@'
		ElseIf $sReplaceURL = '.' Or $sReplaceURL = '..' Then
			$sReplaceURL &= '/$@'
		EndIf
		$aBaseURL = _WinHttpCrackURL2(StringStripWS(StringReplace(StringStripCR($sBaseURL), @LF, ''), 3))
		If $aBaseURL[7] == '' And StringInStr($aBaseURL[6], '.') == 0 And StringRight($aBaseURL[6], 1) <> '/' Then $aBaseURL[6] = $aBaseURL[6] & '/'
		If StringInStr($sReplaceURL, '/') > 0 And StringLen($sReplaceURL) == 1 Then
			$aBaseURL[6] = ''
			$sBaseURL = _WinHttpCreateURL2($aBaseURL)
			Return $sBaseURL
		EndIf
		If $sReplaceURL == '' Then Return $sBaseURL
		If StringLower(StringLeft($sReplaceURL, 7)) == 'http://' Or StringLower(StringLeft($sReplaceURL, 8)) == 'https://' Then Return $sReplaceURL
		If StringLeft($sReplaceURL, 2) <> './' Or StringLeft($sReplaceURL, 2) <> '..' Then $sReplaceURL = ((StringLeft($sReplaceURL, 1) == '/' And StringLen($sReplaceURL) > 1) ? '.' : './') & $sReplaceURL
		$aBaseURL_Replace = StringSplit($aBaseURL[6], '/', 3)
		$aReplaceURL = StringSplit($sReplaceURL, './', 3)
		While $countReplace < UBound($aReplaceURL)
			If StringLeft($aReplaceURL[$countReplace], 1) == '.' And StringLen($aReplaceURL[$countReplace]) == 1 Then
				If UBound($aBaseURL_Replace) > 1 And($countReplace + 1) < UBound($aReplaceURL) Then
					_ArrayDelete($aBaseURL_Replace, UBound($aBaseURL_Replace) - 1)
					$aBaseURL_Replace[UBound($aBaseURL_Replace) - 1] = $aReplaceURL[$countReplace + 1]
				EndIf
				$countModify += 1
			ElseIf StringLeft($aReplaceURL[$countReplace], 1) == '' And StringLen($aReplaceURL[$countReplace]) == 0 Then
				If UBound($aBaseURL_Replace) > 1 And($countReplace + 1) < UBound($aReplaceURL) Then
					$aBaseURL_Replace[UBound($aBaseURL_Replace) - 1] = $aReplaceURL[$countReplace + 1]
				EndIf
				$countModify += 1
			EndIf
			$countReplace += 1
		WEnd
		$aBaseURL[6] = _ArrayToString($aBaseURL_Replace, '/')
		If $countModify == 0 Then $aBaseURL[6] = $aBaseURL[6] & (StringLeft($sReplaceURL, 1) == '/' ? StringTrimLeft($sReplaceURL, 1) : $sReplaceURL)
		Return StringReplace(_WinHttpCreateURL2($aBaseURL), '$@', '')
	EndFunc


	Func _HTML_Execute($sHTML, $iElement = '', $iAttribute = '', $iSpecifiedValue = '', $iReturnHTML = False)
		If $sHTML == '' Then Return SetError(1, __HttpRequest_ErrNotify('_HTML_Execute', 'Tham số $sHTML đưa vào rỗng'), '')
		Local $sResult = '', $oFind = 0, $l___iError = 0
		Local $oHTML = ObjCreate("HTMLFILE")
		If @error Or Not IsObj($oHTML) Then Return SetError(2, __HttpRequest_ErrNotify('_HTML_Execute', 'Tạo HTMLFile Object thất bại'), $sHTML)
		If $iElement = Default Then $iElement = ''
		If $iAttribute = Default Then $iAttribute = ''
		If $iReturnHTML = Default Then $iReturnHTML = False
		With $oHTML
			;.open()
			;.write($sHTML)
			.parentwindow.execScript($sHTML)
			If @error Then Return SetError(3, __HttpRequest_ErrNotify('_HTML_Execute', 'HTMLFile Object không thể truy vấn dữ liệu HTML đưa vào'), $sHTML)
			Select
				Case Not $iElement And Not $iAttribute
					Local $oBody = .body
					If @error Or Not IsObj($oBody) Then Return SetError(4, __HttpRequest_ErrNotify('_HTML_Execute', 'Không thể xử lý dữ liệu HTML đã nạp vào'), $sHTML)
					$sResult = ($iReturnHTML ? $oBody.innerHTML : $oBody.innerText)
				Case $iElement And Not $iAttribute
					__HttpRequest_ErrNotify('_HTML_Execute', 'Phải điền giá trị cho tham số $iAttribute')
					$l___iError = 5
				Case $iAttribute And Not $iSpecifiedValue
					__HttpRequest_ErrNotify('_HTML_Execute', 'Phải điền giá trị cho tham số $iSpecifiedValue')
					$l___iError = 6
				Case Else
					Local $oElements = ($iElement ? .getElementsByTagName($iElement) : .All)
					If Not @error And IsObj($oElements) Then
						For $oElement In $oElements
							Switch $iAttribute
								Case 'class'
									If $oElement.className = $iSpecifiedValue Then $oFind = 1
								Case 'id'
									If $oElement.id = $iSpecifiedValue Then $oFind = 1
								Case 'name'
									If $oElement.name = $iSpecifiedValue Then $oFind = 1
								Case 'type'
									If $oElement.type = $iSpecifiedValue Then $oFind = 1
								Case 'href'
									If $oElement.href = $iSpecifiedValue Then $oFind = 1
							EndSwitch
							If $oFind = 1 Then
								$sResult = ($iReturnHTML ? $oElement.innerHTML : $oElement.innerText)
								ExitLoop
							EndIf
						Next
					Else
						$l___iError = 7
					EndIf
			EndSelect
			.close()
		EndWith
		$oHTML = ''
		If $l___iError Then Return SetError($l___iError, '', $sHTML)
		Return StringStripWS($sResult, 2)
	EndFunc
#EndRegion



#Region <JSON Object>
	Func _HttpRequest_JsonInit($jsonDefault = "{}")
		; Được sửa đổi và cải tiến từ UDF JSON Object của tác giả [ozmike] (https://www.autoitscript.com/forum/topic/156794-oo_jsonudf-jsonpath-oo-using-javascript-in-auto-it)
		; ALL methods CASE SENSITIVE!
		; Eg: you can't go $jsObj.array[0] in AutoIt, this frameworks lets you go $jsObj.array.item(0)
		
		Static $sOJsonLibrary = _
				'function xml2json(e){return xml2jsonRecurse(e=cleanXML(e),0)}function xml2jsonRecurse(e){for(var r,n,t,a,s,l={};e.match(/<[^\/][^>]*>/);)r=(s=e.match(' & _
				'/<[^\/][^>]*>/)[0]).substring(1,s.length-1),-1==(n=e.indexOf(s.replace("<","</")))&&(r=s.match(/[^<][\w+$]*/)[0],-1==(n=e.indexOf("</"+r))&&(n=e.index' & _
				'Of("<\\/"+r))),a=(t=e.substring(s.length,n)).match(/<[^\/][^>]*>/)?xml2json(t):t,void 0===l[r]?l[r]=a:Array.isArray(l[r])?l[r].push(a):l[r]=[l[r],a],e' & _
				'=e.substring(2*s.length+1+t.length);return l}function cleanXML(e){return e=replaceAttributes(e=replaceAloneValues(e=replaceSelfClosingTags(e=(e=(e=(e=' & _
				'(e=e.replace(/<!--[\s\S]*?-->/g,"")).replace(/\n|\t|\r/g,"")).replace(/ {1,}<|\t{1,}</g,"<")).replace(/> {1,}|>\t{1,}/g,">")).replace(/<\?[^>]*\?>/g,"' & _
				'"))))}function replaceSelfClosingTags(e){var r=e.match(/<[^/][^>]*\/>/g);if(r)for(var n=0;n<r.length;n++){var t=r[n],a=t.substring(0,t.length-2);a+=">' & _
				'";var s=t.match(/[^<][\w+$]*/)[0],l="</"+s+">",i="<"+s+">",c=a.match(/(\S+)=["'']?((?:.(?!["'']?\s+(?:\S+)=|[>"'']))+.)["'']?/g);if(c)for(var g=0;g<c.leng' & _
				'th;g++){var u=c[g],f=u.substring(0,u.indexOf("="));i+="<"+f+">"+u.substring(u.indexOf(''"'')+1,u.lastIndexOf(''"''))+"</"+f+">"}i+=l,e=e.replace(t,i)}retu' & _
				'rn e}function replaceAloneValues(e){var r=e.match(/<[^\/][^>][^<]+\s+.[^<]+[=][^<]+>{1}([^<]+)/g);if(r)for(var n=0;n<r.length;n++){var t=r[n],a=t.subs' & _
				'tring(0,t.indexOf(">")+1)+"<_@ttribute>"+t.substring(t.indexOf(">")+1)+"</_@ttribute>";e=e.replace(t,a)}return e}function replaceAttributes(e){var r=e' & _
				'.match(/<[^\/][^>][^<]+\s+.[^<]+[=][^<]+>/g);if(r)for(var n=0;n<r.length;n++){var t=r[n],a="<"+t.match(/[^<][\w+$]*/)[0]+">",s=t.match(/(\S+)=["'']?((?' & _
				':.(?!["'']?\s+(?:\S+)=|[>"'']))+.)["'']?/g);if(s)for(var l=0;l<s.length;l++){var i=s[l],c=i.substring(0,i.indexOf("="));a+="<"+c+">"+i.substring(i.indexO' & _
				'f(''"'')+1,i.lastIndexOf(''"''))+"</"+c+">"}e=e.replace(t,a)}return e};function buildParamlist(t){var e=" p0";t=t||1;for(var r=1;r<t;r++)e=e+" , p"+r;retu' & _
				'rn e}Object.prototype.propAdd=function(prop,val){eval("this."+prop+"="+val)},Object.prototype.methAdd=function(meth,def){eval("this."+meth+"= new "+de' & _
				'f)},Object.prototype.jsFunAdd=function(funname,numParams,objectTypeName){var x=buildParamlist(numParams);return objectTypeName=objectTypeName||"Object' & _
				'",eval(objectTypeName+".prototype."+funname+" = function("+x+") { return "+funname+"("+x+"); }")},Object.prototype.protoAdd=function(methName,jsFuncti' & _
				'on,objectTypeName){objectTypeName=objectTypeName||"Object",eval(objectTypeName+".prototype."+methName+"="+jsFunction)},Object.keys||(Object.keys=funct' & _
				'ion(){"use strict";var o=Object.prototype.hasOwnProperty,a=!{toString:null}.propertyIsEnumerable("toString"),u=["toString","toLocaleString","valueOf",' & _
				'"hasOwnProperty","isPrototypeOf","propertyIsEnumerable","constructor"],i=u.length;return function(t){if("object"!=typeof t&&("function"!=typeof t||nul' & _
				'l===t))throw new TypeError("Object.keys called on non-object");var e,r,n=[];for(e in t)o.call(t,e)&&n.push(e);if(a)for(r=0;r<i;r++)o.call(t,u[r])&&n.p' & _
				'ush(u[r]);return n}}()),Object.prototype.objGet=function(s){return eval(s)},Array.prototype.index=function(t){return this[t]},Object.prototype.index=f' & _
				'unction(t){return this[t]},Array.prototype.item=function(t){return this[t]},Object.prototype.item=function(t){return this[t]},Object.prototype.keys=fu' & _
				'nction(){if("object"==typeof this)return Object.keys(this)},Object.prototype.keys=function(t){return (typeof t=="object"?Object.keys(t):Object.keys(th' & _
				'is))},Object.prototype.arrayAdd=function(t,e){this[t]=e},Object.prototype.arrayDel=function(t){this.splice(t,1)},Object.prototype.isArray=function(){r' & _
				'eturn this.constructor==Array},Object.prototype.type=function(){return typeof this},Object.prototype.type=function(t){if("undefined"==typeof t){return' & _
				' typeof this}else{return typeof t}};var JSON=new Object;function jsonPath(obj,expr,arg,basename){var P={resultType:arg&&arg.resultType||"VALUE",result' & _
				':[],normalize:function(t){var r=[];return t.replace(/[\[''](\??\(.*?\))[\]'']/g,function(t,e){return"[#"+(r.push(e)-1)+"]"}).replace(/''?\.''?|\[''?/g,";")' & _
				'.replace(/;;;|;;/g,";..;").replace(/;$|''?\]|''$/g,"").replace(/#([0-9]+)/g,function(t,e){return r[e]})},asPath:function(t){for(var e=t.split(";"),r=("u' & _
				'ndefined"==typeof basename?"$":basename),n=1,o=e.length;n<o;n++)r+=/^[0-9*]+$/.test(e[n])?"["+e[n]+"]":"."+e[n];return r},store:function(t,e){return t' & _
				'&&(P.result[P.result.length]="PATH"==P.resultType?P.asPath(t):e),!!t},trace:function(t,e,r){if(t){var n=t.split(";"),o=n.shift();if(n=n.join(";"),e&&e' & _
				'.hasOwnProperty(o))P.trace(n,e[o],r+";"+o);else if("*"===o)P.walk(o,n,e,r,function(t,e,r,n,o){P.trace(t+";"+r,n,o)});else if(".."===o)P.trace(n,e,r),P' & _
				'.walk(o,n,e,r,function(t,e,r,n,o){"object"==typeof n[t]&&P.trace("..;"+r,n[t],o+";"+t)});else if(/,/.test(o))for(var a=o.split(/''?,''?/),u=0,i=a.length' & _
				';u<i;u++)P.trace(a[u]+";"+n,e,r);else/^\(.*?\)$/.test(o)?P.trace(P.eval(o,e,r.substr(r.lastIndexOf(";")+1))+";"+n,e,r):/^\?\(.*?\)$/.test(o)?P.walk(o,' & _
				'n,e,r,function(t,e,r,n,o){P.eval(e.replace(/^\?\((.*?)\)$/,"$1"),n[t],t)&&P.trace(t+";"+r,n,o)}):/^(-?[0-9]*):(-?[0-9]*):?([0-9]*)$/.test(o)&&P.slice(' & _
				'o,n,e,r)}else P.store(r,e)},walk:function(t,e,r,n,o){if(r instanceof Array)for(var a=0,u=r.length;a<u;a++)a in r&&o(a,t,e,r,n);else if("object"==typeo' & _
				'f r)for(var i in r)r.hasOwnProperty(i)&&o(i,t,e,r,n)},slice:function(t,e,r,n){if(r instanceof Array){var o=r.length,a=0,u=o,i=1;t.replace(/^(-?[0-9]*)' & _
				':(-?[0-9]*):?(-?[0-9]*)$/g,function(t,e,r,n){a=parseInt(e||a),u=parseInt(r||u),i=parseInt(n||i)}),a=a<0?Math.max(0,a+o):Math.min(o,a),u=u<0?Math.max(0' & _
				',u+o):Math.min(o,u);for(var p=a;p<u;p+=i)P.trace(p+";"+e,r,n)}},eval:function(x,_v,_vname){try{return $&&_v&&eval(x.replace(/@/g,"_v"))}catch(t){throw' & _
				' new SyntaxError("jsonPath: "+t.message+": "+x.replace(/@/g,"_v").replace(/\^/g,"_a"))}}},$=obj;if(expr&&obj&&("VALUE"==P.resultType||"PATH"==P.result' & _
				'Type))return P.trace(P.normalize(expr).replace(/^\$;/,""),obj,"$"),!!P.result.length&&P.result}function oLiteral(t){this.literal=t}function protectDou' & _
				'bleQuotes(t){return t.replace(/\\/g,"\\\\").replace(/"/g,''\\"'')}JSON.jsonPath=function(t,e,r,basename){return jsonPath(t,e,r,basename)},"object"!=type' & _
				'of JSON&&(JSON={}),function(){"use strict";function f(t){return t<10?"0"+t:t}var cx,escapable,gap,indent,meta,rep;function quote(t){return escapable.l' & _
				'astIndex=0,escapable.test(t)?''"''+t.replace(escapable,function(t){var e=meta[t];return"string"==typeof e?e:"\\u"+("0000"+t.charCodeAt(0).toString(16)).' & _
				'slice(-4)})+''"'':''"''+t+''"''}function str(t,e){var r,n,o,a,u,i=gap,p=e[t];switch(p&&"object"==typeof p&&"function"==typeof p.toJSON&&(p=p.toJSON(t)),"fun' & _
				'ction"==typeof rep&&(p=rep.call(e,t,p)),typeof p){case"string":return quote(p);case"number":return isFinite(p)?String(p):"null";case"boolean":case"nul' & _
				'l":return String(p);case"object":if(!p)return"null";if(gap+=indent,u=[],"[object Array]"===Object.prototype.toString.apply(p)){for(a=p.length,r=0;r<a;' & _
				'r+=1)u[r]=str(r,p)||"null";return o=0===u.length?"[]":gap?"[\n"+gap+u.join(",\n"+gap)+"\n"+i+"]":"["+u.join(",")+"]",gap=i,o}if(rep&&"object"==typeof ' & _
				'rep)for(a=rep.length,r=0;r<a;r+=1)"string"==typeof rep[r]&&(o=str(n=rep[r],p))&&u.push(quote(n)+(gap?": ":":")+o);else for(n in p)Object.prototype.has' & _
				'OwnProperty.call(p,n)&&(o=str(n,p))&&u.push(quote(n)+(gap?": ":":")+o);return o=0===u.length?"{}":gap?"{\n"+gap+u.join(",\n"+gap)+"\n"+i+"}":"{"+u.joi' & _
				'n(",")+"}",gap=i,o}}"function"!=typeof Date.prototype.toJSON&&(Date.prototype.toJSON=function(){return isFinite(this.valueOf())?this.getUTCFullYear()+' & _
				'"-"+f(this.getUTCMonth()+1)+"-"+f(this.getUTCDate())+"T"+f(this.getUTCHours())+":"+f(this.getUTCMinutes())+":"+f(this.getUTCSeconds())+"Z":null},Strin' & _
				'g.prototype.toJSON=Number.prototype.toJSON=Boolean.prototype.toJSON=function(){return this.valueOf()}),"function"!=typeof JSON.stringify&&(escapable=/' & _
				'[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,meta={"\b":"\\b","\t":"\\t",' & _
				'"\n":"\\n","\f":"\\f","\r":"\\r",''"'':''\\"'',"\\":"\\\\"},JSON.stringify=function(t,e,r){var n;if(indent=gap="","number"==typeof r)for(n=0;n<r;n+=1)inde' & _
				'nt+=" ";else"string"==typeof r&&(indent=r);if((rep=e)&&"function"!=typeof e&&("object"!=typeof e||"number"!=typeof e.length))throw new Error("JSON.str' & _
				'ingify");return str("",{"":t})}),"function"!=typeof JSON.parse&&(cx=/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u20' & _
				'6f\ufeff\ufff0-\uffff]/g,JSON.parse=function(text,reviver){var j;function walk(t,e){var r,n,o=t[e];if(o&&"object"==typeof o)for(r in o)Object.prototyp' & _
				'e.hasOwnProperty.call(o,r)&&(void 0!==(n=walk(o,r))?o[r]=n:delete o[r]);return reviver.call(t,e,o)}if(text=String(text),cx.lastIndex=0,cx.test(text)&&' & _
				'(text=text.replace(cx,function(t){return"\\u"+("0000"+t.charCodeAt(0).toString(16)).slice(-4)})),/^[\],:{}\s]*$/.test(text.replace(/\\(?:["\\\/bfnrt]|' & _
				'u[0-9a-fA-F]{4})/g,"@").replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,"]").replace(/(?:^|:|,)(?:\s*\[)+/g,"")))return j=e' & _
				'val("("+text+")"),"function"==typeof reviver?walk({"":j},""):j;throw new SyntaxError("JSON.parse")})}(),Object.prototype.stringify=function(){return J' & _
				'SON.stringify(this)},Object.prototype.parse=function(t){return JSON.parse(t)},Object.prototype.jsonPath=function(t,e,basename){return JSON.jsonPath(th' & _
				'is,t,(e==true?{resultType:"PATH"}:e),basename)},Object.prototype.objToString=function(){return JSON.stringify(this)},Object.prototype.strToObject=func' & _
				'tion(t){return JSON.parse(t)},Object.prototype.dot=function(str,jsStrFun){return"string"==typeof str?eval(''"''+protectDoubleQuotes(str)+''".''+jsStrFun):' & _
				'eval(str+"."+jsStrFun)},Object.prototype.toObj=function(literal){return"string"==typeof literal?eval(''new oLiteral("''+protectDoubleQuotes(literal)+''")' & _
				'''):eval("new oLiteral("+literal+")")},Object.prototype.jsMethAdd=function(funname,numParams){var x=buildParamlist(numParams);return eval("oLiteral.pro' & _
				'totype."+funname+" = function("+x+"){return this.literal."+funname+"("+x+"); }")};Object.prototype.beautify=function(r){return JSON.stringify(this,nul' & _
				'l,typeof r==''undefined''?4:r)},Object.prototype.prettify=Object.prototype.beautify,Object.prototype.toStr=function(r){if(r<0){return JSON.stringify(thi' & _
				's.stringify())}else{return JSON.stringify(this,null,typeof r==''undefined''?null:r)}},Object.prototype.sort=function(){},Object.prototype.reverse=functi' & _
				'on(){},Object.prototype.min=function(){return Math.min.apply(null,this)},Object.prototype.max=function(){return Math.max.apply(null,this)},JSON.filter' & _
				'=JSON.jsonPath,Object.prototype.filter=Object.prototype.jsonPath,Object.prototype.parseXML=function(t){return JSON.parse(xml2json(t).toStr())},Object.' & _
				'prototype.get=function(jsonPath,obj2str){var val=eval("this"+checkkey(jsonPath).replace(/\.(\d+)\b/g,"[$1]"' & _
				'));if(typeof val=="object"&&"undefined"!=typeof obj2str){val=val.toStr(obj2str)};return val},Object.prototype.set=function(key_name,val){' & _
				'eval("this"+checkkey(key_name).replace(/\.(?:item|index)\((\d+)\)/g,"[$1]").replace(/\.(\d+)\b/g,"[$1]")+"="+val)},Objec' & _
				't.prototype.remove=function(key_name){eval("delete this."+key_name)},Object.prototype.values=function(){var oValues=[];for(var key in this){if(this.ha' & _
				'sOwnProperty(key)){oValues.push(eval("this."+key))}};return oValues};function search(path,obj,target,regexMode){var aPath=[];var val;function json_sea' & _
				'rch(path,obj,target,regexMode){for(var keyname in obj){if(obj.hasOwnProperty(keyname)){val=obj[keyname];if(regexMode==true&&"string"==typeof val&&val.' & _
				'match(target)){aPath.push(path+(isNaN(keyname)?"."+keyname:''[''+keyname+'']''))}else if(val===target){aPath.push(path+(isNaN(keyname)?"."+keyname:''[''+key' & _
				'name+'']''))}else if(typeof val==="object"){json_search(path+(isNaN(keyname)?"."+keyname:''[''+keyname+'']''),val,target,regexMode)}}}};json_search(path,obj' & _
				',target,regexMode);return aPath};Object.prototype.findPath=function(node,regexMode){return search("this",this,node,regexMode)};' & _
				'function checkkey(keyname){if(!isNaN(keyname)){keyname="[''"+keyname+"'']"}if(keyname.substr(0,1)!=="["){keyname="."+keyname}return keyname}'     ;||keyname.search(/\s\@\#\$/g)	EndIf
		Local $iError = 0, $oRet
		If Not IsObj($g___oJSON_Init) Then
			$g___oJSON_Obj = ObjCreate("HTMLFILE")
			If @error Then
				$iError = 1 + 0 * __HttpRequest_ErrNotify('_HttpRequest_JsonInit', 'Không thể tạo HTMLFILE Object')
			Else
				With $g___oJSON_Obj
					.parentwindow.execScript($sOJsonLibrary)
					If @error Then
						$iError = 2 + 0 * __HttpRequest_ErrNotify('_HttpRequest_JsonInit', 'Không thể khởi tạo JSON Object')
					Else
						$oRet = .parentwindow.eval('JSON')
						If @error Or Not IsObj($oRet) Then
							$iError = 3 + 0 * __HttpRequest_ErrNotify('_HttpRequest_JsonInit', 'Không thể parse JSON')
						Else
							$g___oJSON_Init = $oRet
						EndIf
					EndIf
				EndWith
			EndIf
		Else
			Return $g___oJSON_Init
		EndIf
		If $iError Then $g___oJSON_Init = Null
		Return SetError($iError, '', $oRet)
	EndFunc

	Func _HttpRequest_ParseJSON($sJSON_or_oArrJSON_or_URL, $sData2Send = '', $sCookie = '', $sReferer = '', $sAdditional_Headers = '', $sMethod = '')
		If IsObj($sJSON_or_oArrJSON_or_URL) And $sJSON_or_oArrJSON_or_URL.isArray() Then
			Local $uArr = $sJSON_or_oArrJSON_or_URL.length, $aRet[$uArr]
			For $i = 0 To $uArr - 1
				$aRet[$i] = $sJSON_or_oArrJSON_or_URL.item($i)
			Next
			Return $aRet
		EndIf
		;-----------------------------------------------------------------------------------------------------
		If StringRegExp($sJSON_or_oArrJSON_or_URL, '^https?://') Then
			$sJSON_or_oArrJSON_or_URL = _HttpRequest(2, $sJSON_or_oArrJSON_or_URL, $sData2Send, $sCookie, $sReferer, $sAdditional_Headers, $sMethod)
			If @error Or $sJSON_or_oArrJSON_or_URL = '' Then Return SetError(-1, __HttpRequest_ErrNotify('_HttpRequest_ParseJSON', 'Lấy dữ liệu request trả về từ URL đã nạp thất bại'), '')
		EndIf
		_HttpRequest_JsonInit()
		If @error Or Not IsObj($g___oJSON_Init) Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_ParseJSON', 'Không thể khởi tạo thư viện JSON2'), '')
		If StringRegExp($sJSON_or_oArrJSON_or_URL, "(?s)^\h*?[\{\[]\h*?'") Then $sJSON_or_oArrJSON_or_URL = StringReplace(StringRegExpReplace($sJSON_or_oArrJSON_or_URL, "([^\\])'", '$1"'), "\'", "'", 0, 1)
		Local $oJSONParse = $g___oJSON_Init.parse($sJSON_or_oArrJSON_or_URL)
		If @error Or Not IsObj($oJSONParse) Then
			If $oJSONParse And VarGetType($oJSONParse) = 'string' Then
				$oJSONParse = $g___oJSON_Init.parse($oJSONParse)
				If @error Or Not IsObj($oJSONParse) Then Return SetError(3, __HttpRequest_ErrNotify('_HttpRequest_ParseJSON', 'Không thể parse JSON #2'), '')
			Else
				Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_ParseJSON', 'Không thể parse JSON #1'), '')
			EndIf
		EndIf
		Return $oJSONParse
	EndFunc
#EndRegion



#Region <INTERNAL FUNCTIONS>
	Func __Gzip_Uncompress($sBinaryData)
		If Not StringRegExp(BinaryMid($sBinaryData, 1, 1), '(?i)0x(1F|08|8B)') Then Return SetError(1, __HttpRequest_ErrNotify('__Gzip_Uncompress', 'Chuỗi binary này không phải định dạng của nén Gzip'), $sBinaryData)
		If Not $g___JsLibGunzip Then
			;Compact zlib, deflate, inflate, zip library in JavaScript: https://github.com/imaya/zlib.js/ - Thanks imaya
			$g___JsLibGunzip &= 'G7wAKGZ1bmN0aW8AbigpeyJ1c2UAIHN0cmljdCICOwW4IGsodCl7AHRocm93IHR9AHZhciBVPXZvAGlkIDAscz10CGhpcwdSdCh0LAhyKXsBRmUsaT0AdC5zcGxpdCgAIi4iKSxuPXMAOyEoaVswXWkAbiBuKSYmbi4AZXhlY1NjcmkkcHQLDSgiAUEiKwEBLCk7Zm9yKDsAaS5sZW5ndGgAJiYoZT1pLnMAaGlmdCgpKTsCKQUYfHxyPT09AFU/bj1uW2Vdij8BBDoBBD17fQMHAnICunIsRT0idQBuZGVmaW5lZAAiIT10eXBlbwBmIFVpbnQ4QUBycmF5JiaVDzESNhwQMzIYEERhdCBhVmlld4JnbmVQdyhFPwc6OgIcKQAoMjU2KSxyPRAwO3I8AAU7KysscikBfwKoPYB8cikAPj4+MTtlO2WhgAM9MSkwh713gb0ULGWDvmkAtyJudUBtYmVyIj2FcXI4P3I6gC2A2g4NZT8YZTp0hFgCKGk9LQIxwBA3JnM7bi0iLQIiaT1pAB04XgBhWzI1NSYoaYBedFtyXSldwzMgPXM+PjOCCnIrwD04KWk9KJEAEhCzgTRLFSsxwBWQBTKTBaozkwU0kwU1kwU2kwUCN4AFO3JldHVyAG4oNDI5NDk2QDcyOTVeaUEnMAFClGk9WzAsMTkAOTY5NTk4OTQALDM5OTM5MTkQNzg4LIBwNzUyBDQ3QAUxMjQ2MwA0MTM3LDE4OIA2MDU3NjE1gAoAMTU2MjE2ODUALDI2NTczOTIEMDOAAjQ5MjY4ADI3NCwyMDQ0IDUwODMyQBU3N4AyMTE1MjMwQBUANDcxNzc4NjS4LDE2gCTAHgANMQBlADYxMDIxLDM4ADg3NjA3MDQ3ACwyNDI4NDQ0ADA0OSw0OTg1ADM2NTQ4LDE3ADg5OTI3NjY2ACw0MDg5MDE2AjagAjIyMjcwNmAxMjE0LGAO4AQ4hDYxYBU0MzI14BUAMyw0MTA3NTgRYAAzLDIgETY3N9A2MzksoQM4IB4gIEA2ODQ3NzdAFCxANDI1MTEygBcyICwyMzIxoBk2MwA2LDMzNTYzM0Q0OCAgNjYxQRE2AjWgCjk1MzAyNwo1IBgzwAIxNTMxADcsOTk3MDczADA5NiwxMjgxQyAEQCYsMzU3QBg1lDMzoAo3oCk4OKAbACwxMDA2ODg4mDE0NWAFIRU3NiAMijOgLjEAGzI5LAAdQaAyMjQ0MyxAHTACOeAoMiwxMTE5BjAhBwArNjg2NTEANzIwNiwyODnEODDgMDI4LGAlYC+sNDVAIGADMiATMAArADcwNTAxNTc1u6AKoA82ACdAGKEHNkAToUAgMzczNSA4NIEdIcBBNTQzMAAMMjEQODEwNIBDLDU2ADU1MDcyNTMsJeAVNCA/NzOgCjQ4FcAlMWALLEAeOTQzADYzMDMsNjcxBaAOOYBAMTU5NDF7ABOBQDOANIAEgUBAJDMANDc4MTIsNzlANTgzNTUyACs0u2BFwCkyQEshHmBVN0ABwDA2MDE0OYAPwVSQN'
			$g___JsLibGunzip &= 'DE0NkAyLDOgSaegHIBMwDI5MEA3MsBBtDIzQEs54AvgIzdgFmY0ABxgOTYzoE9ANDb2OOAfYD4zQFfgIyBGYSG6MMBaNyBRQVOhJTCgPUtAQEEGMwAYMzcARzMYMDA04AMgBTY1NqdARyAgYQE4McBJNABfV0FHwElgMTIgHzlgGTjJYFk5NaBXLDRgOkBUQeBVMjIzODDADTaSOGAVNjZgYzg3AFqhoCAzNzA5wB40oEmHYFvAKqEuNjI1MIECX8A9QDmAB2BfgCE4gF4ybwAg4GIgGCAgM8BsQCswSSAgMjTgCzc1gEwxejbASTXgcEA0YGWgbDcBAGozNjI2NzAzgjIAYjIyNDk5gGsDIE8gNjUzNTk2MIgsOThAhDE0OKBJUDc0NzDAcDlADTXwNjkwM6AKYBVggmA9ijigXDFAAjYwNAAxKYFUNTIAbDMAKzU1QDQwNzk5OcAKMYYzgFigcTYsODcAj0uAAsAKOQAdNDOgRywjAGZgKzE4NeBkMTQhwDQ0NDY3QFc1OEY04ESAFTg1MgA2NhmBTDcw4IVAADksMeIz4HMzMzlgfsCBYDxqM6AvM1BJM/ALQAEza1AsUB4xoSc0oEGwCDB0OSyAGDEwCOBJ8Aow7XBIOZAbUQg1gD6gTFAqgjEwKzA1NCw3gBvEMzjwQSwyOfADIA5UNTDRPzKQBDTwKjGGNfBI8AYwNyw3gSsIMTg3YA8wODI27wAZYDrAFQAZMsBUUCZwNpY5QB9hKjngHDQ2wDVcNjJAQmA/4Cw1EDAwe+AOkAIzoBegMlEqcTE2vUAfLHBBcCHRJHA1OKA5RXAbM0ABOTE4QS4y3DQ4QFtALeAFMgA0QELhMCowNTM34RpQPDAJ3DE3AD9ABaAQOYE0sDvSNkAHNjeQCjLgROA/v0AYoTNATLBSAASwXDQABPcwINBA4Vc3EEcAMtBDsAePME8AEHAyIEsyMTUQEdY50DtAUzagFDLgKgAd3XArNyAfQAFAIzHQTHAf/DMxYQ8gYnBKAFOBKOAs2bAcNTVwHlAFOCBB8AUbADXBHTdQZ7A/OTc5rbBiNlELYFs4wEU3cCN5UCc5MGBTgCexKmBJONYsYFagbTeRLzNAMPBhOjIQEDXQGaAvEWo3OXA3MzYwQChAVzBXMsY4kBRAVzE5NhBncECxEAk0NzTQCyAQObApbDc1sAVAVzYgAeEqMV4wMAdgaiAgYEE3wEkwGYBOMjjwUJAlNjks4DgyOTMycCWRL4BB2DM1MSBoQHMy0W6RVFQxNsBwNOEeNoAtOHuAMgA1M0AaIBvQQYAtMzgzNjlwBsA9gEI3OLXxMDWQVTawPyAQNCEmrDA4kXcQJDMQPjTAZIw5OQAokA04LDfAZXPAbDAsMTUAVXBSoDUze8B4ERo5cEAQHIACcCgsj3F90CYADCEcMzIw0BUbQHzwPjfQVfAuOTY1lfASMKJUNvB2MjlQIPmQPTM1kHiQAlB4QFXgHt/AGqBtgHOwZsAPMBBNgEYzQHWwDjcx0H5wHzQxR8CDgH0QQzQwNhBFMtWAeDIgPTLwCzEQCsAuQ5AAIIYyNzI2QAkzgDg1NTk5MDJxG34woD4xRfEF8C5gH1AFMtY2IAsAcTKQKzUxA7CDjeAkNZAOEB4yLDUgOLUwRTmwHDGgGiEcMTAm/jMSGvE+MBPQJMBSUAFhQntQXYCBOEBRoDUwhNA+MqPwHZBaMTcxII40cE3PkCsQSbAK4Cw0MNCEUDD+N/ADoCDAQyF8YA4wGxBtPCwzADMwE2B38Bc1MH8wN+CAURowVTAQYEywizE9QIoykCuATJAJAJc4MHGADzUxMJAvEG+AcTJXoS+AMxCIM7AEMVCRNE9AX3BMwiZQeTE4ADE17bBaM/AMoC04MEkgZKBcabEkOGXwNDiQjbAsOWMAaiAwODM3kCqQLzAqMkCEOAAGOHAMMzM7'
			$g___JsLibGunzip &= '8DdwJzgwjqBcQAU0MLmQGzcxESCSZvFBLGCfDjjwgBFRgVgwNzQ548BPYGs0MjHQn2Bx0E54NTc0EJtRe5BC0Vsw9DA5UAc2sJkAMtCf4IQfMF8gFzFkEFEQFjkyOP9QkSCEkIyhmNAqsCDhciF8HyARcQlgD1AIgVoxN10ALGE9RT9uZXeDss+kyyhpKTppN8VqQTDhfXbgenHgochyAizQ3SxuLHMsYQAsaCxvLHUsZgwsY9DeI9osbD0wICxwPU510ccuUABPU0lUSVZFXwBJTkZJTklUWUXywm8gzm88Y3DFb4ApdFtvXT5sgN0kbD2hACksUQA8cA0AAXADARIDcj0xPOA8bCxlPRALpNM0Czm103IpIOdBy3HpMjuAaTw9bDspe+HTsdkGaWYo8QWw4mnDAYBoPW4sdT1hAAkIdTxpAAl1KWE9AGE8PDF8MSZoQCxoPj49MfIHZiQ9aUABNnzQDj1hADt1PHI7dSs9AHMpZVt1XT1mIWADbn0rK1DXPDxQPTEsc1EAfVPDWwBlLGwscF19QUAucHJvdG/h5i4AZ2V0TmFtZT2XlRVQFsMCIOH0Lm6wAbx9LAwD4eMPAwMDZKDljQsDR68CowJIfTsRHCBuLGg9W6Pbr7gAbj0wO248MjgAODtuKyspc3cAaXRjaCghMCkAe2Nhc2UgbjwAPTE0MzpoLnAAdXNoKFtuKzQAOCw4XSk7YnIQZWFrOwWIMjU1AQdELTE0NCs0MEgwLDkPTjc5CE4yQDU2KzAsNw8lOAI3CSU4MCsxOTIBCHVkZWZhdWx0ADprKCJpbnZhAGxpZCBsaXRlAHJhbDogIituACl9dmFyIG89AGZ1bmN0aW9uCCgpewUKIHQodAQpew3jMz09PXQAOnJldHVyblsAMjU3LHQtMyxUMF2DbjQLDjgADjRVBg41Cw45AA41Bg42qQoONjAADjYGDjcLDqoxAA43Bg44Cw4yAA6qOAYOOQsOMwAOOQYOlDEwiw40gA4xMAYPSnSA5jKGdDY1gQ4xrCwxhDpBBzRHBzZBB5ozSgc2RwdBSTE1SgemOEcHgUkxN0kHMsgdocFJMTksMscdMkcWkjcBSjIzSQczMEYWsjdBSjI3SgfHLDeBSlQzMUkHNMcdN8FKM2g1LDPHHTVIFsFKNJYzSgdHNDfBSjUxSQemNsgswUo1OUkHOMgdocFKNjcsNMcdOUgWycFKODNJBzExiDQBS6w5OYoHyEM4QUsxAGKpCBcxNsceOMFLMYBEUjUHHzE5hxc4QUwxaDYzLOgDMqgxABN0kC0xOTXqAzU35jGaOKEmMgAy5QcyNatXHjgBJ4ACYVARd2VuZ0R0aOF2dCl9AndyACxlLGk9W107AGZvcihyPTM7SHI8PeAHO3Kgk2UAPXQociksaVsAcl09ZVsyXTyAPDI0fGVbMQABRDE2AAEwXTvDeCAgaX0oKTvGfm0oCHQscgZ/dGhpcwouQQwsIgFqPTMyTDc2oDDBAmQ9YgJmHcMAY8MAQKRDBWlucAB1dD1FP25ldwAgVWludDhBckhyYXlgijp0AwRvjD0'
			$g___JsLibGunzip &= 'hAC4BCWs9U0MCQndBAihyfHyAGXsAfSwwKSkmJiiAci5pbmRleCABCcINYz0EAiksci4AYnVmZmVyU2l0emXFA2rAA6cCZwRUdHlwZgRrZgShAmEEcjRlc2gId+ADIwIpKaUDE2tEvE46YhBhySBEYj1AHChFP4ccOilCHSkoYiUrIgZqK/vgMkrBU0UJoFKBINcIAwhXJBHAOqEFROMScYMuQTWjAWyjAUMkzkdIRXIGcgBEJsBpbmZsYQB0ZSBtb2RlIiIpYElFJibFNDMyEeM0byk7QcNOPTAALFM9MTttLnAgcm90b3SgKC5nE8rFAAs7IUIUbzspQnthBnQ9VCgBAiyIMyk75McxJnQFNAXAPjBgGT4+Pj0xaaQqMDrBBnKjF+JGLI3EHGPAW2ILYixuwwMoYSxzoDNsQmEsYYA9VSxoPWkuxAE4bz1VBQ6CBgZUMCwAczw9ZSsxJiaMayhsIQDfb21woD0Ac2VkIGJsb2MAayBoZWFkZXJgOiBMRU6gI4AMckBbZSsrXXzDADy8PDjfBLV13wTWBE7mBHA9PX4oLQWALq8Jbg5jrwmjCQMPIHZlcghpZnlBCmUrYT4ucnQQWg5AOCDzMCBpAHMgYnJva2Vu1wEDAhJnLWZhHG5ABMUUAbAcaWYoYS09bwA9aC1uLEUpaQguc2UQRS5zdWICYZI8ZSxlK28pRCxuIAArPW/AAD0wbztlbHCQsgRvLRAtOylpQJArXT1Fww47IgdhPW41HWWWKKADVB19SJJTOt8IBClpgwJlKHt0OvwyfZU0Ly5Eji0usAwvDBooIQxhQAggACs9YTUhDGEoDGEvDCIMYz2OZfM2sQwSAWI9aVmegjGjPWwoTSxqOj8CMoIudSxmLGMsSGwscHUyNSnQQTdELHn4ADEsYtUANGApKzQsZ09GREZHUVQfKSxk0DB2MAB3tTAAQTAAbeAwkRRtUKsAbTxiOysrbSmAZ1tHW21dXbUFoxA6kBEhRSlzAmJQBypn9AQ7LQMwUmZ1PTh6KGexBk9PUSEpKCBwK3kpLCAHLGwmPaAAUARsO5Wydj1CcYNBdSksdrQ/MUI20h5BPTMrVEMyiCk7QZEXZFttUDd0PXeaFTfdAhAM2QIwTDt30A7IJDE4FAMxOjEFBjcLBikD9SR3PRHUB3Z9ZgAPRT9kQXcvMCxwKTrwAGwQaWNlKMEAKSxjyz0CGAJwNWRsKGAfjysB9Eh1bmtub3duwCBCVFlQRTN+gFnDFHpCJnEoKX0yWfIjYD1bMTYsYaPQrixAOCw3LDks8AAwAixgpjEsNCwxMiYs4KiQoSwxwAAsMSA1XSxHPcd4MTaRU15jKTqQKD1bIJW1kAM2YAQ4gARQsDGgrp8ABNAEkKngp5AENyygkf8goXCfwJ0QnGCaII/wljGVvjHAAbGR8Y8xjuBuLDQAhl2QLq8HbCk6bCAvWlsQtyw5AIAHLDEAMl4sEwBQpqAMAQo0cA0072AKAJZQADIDXQArpwUkhtB5KTp5ADNbsK2QA/sRA9ERMeAMsLAgrbAEwBIINSw5oA0yOSwxVjnADZDMM+CXNVACN5I2MAEwMqAPNTMAA5QwNLCqMPCwNDAAA0A2MTQ1LDghAzEoMjI4gAI2YQMyNDA1NzddADhvDmcp4DpnLHY9Zg6lDWEN6wENwQw2oBs3shfRF9EHNiwkGNACMrEcwQszXQwsQygcxA52KTp2DCx430HUQTI4OClBdDswLGY9eMU9dQQ8ZvBAdSl4W3WIXT11gus/ODqAAAng6T85ggA3OT83BDo4EidELEksTWEwLngpLFqvBqQGM4owkwZEIINJPVqVBghEPEmQBkQpWltQRF09NeIEaqAEWvfAAtByQecggD8hpzFIgYCRMa10LmYRfy5k4H6OdACgYGyAeHQuY/B+AnOl'
			$g___JsLibGunzip &= 'BW48cjspaHA8PWEmeX0fbxNvaSB8PXNbYSBFPDxAbixuKz049a9lAD1pJigxPDxyBCktAKkuZj1pPgA+PnIsdC5kPVRuLXEAY7FhfRCyVLgAY3Rpb24gcSgAdCxyKXtmb3IAKHZhciBlLGkALG49dC5mLHMRAChkLGEAFGlucBB1dCxoACRjLG8APWEubGVuZ3QAaCx1PXJbMF0ELGYADDFdO3M8AGYmJiEobzw9AGgpOylufD1hAFtoKytdPDxzACxzKz04O3JlAHR1cm4gczwoAGk9KGU9dVtuACYoMTw8ZiktADFdKT4+PjE2ACkmJmsoRXJyAQCJImludmFsaYBkIGNvZGUgA28AOiAiK2kpKSxBAJs9bj4+aQAIZAg9cy0BB2M9aCwANjU1MzUmZX0IZnVuA9hCKHQpQHt0aGlzLgK/PUR0LAIMYz0wAwhtCD1bXYMEcz0hMQB9bS5wcm90b4B0eXBlLmw9hSKLA44CjD0CH2IsaQMEhGE7ggdyPXQ7hZ2AbixzLGEsaICRAwAhgpEtMjU4OzIANTYhPT0obj0jALUARyx0KQCQaWYoKG48gAwpAJhpJgQmKAImYT1pLGURAy9lKCmGNCksZQBbaSsrXT1uOyBlbHNlIIE3aD0gcFtzPW4AMDddgCwwPGJbc12AItBoKz1UAiUsAQgAlokGOnIpAOVkW24BFvZDAAMAFmEGCwEEAAuhIkA7aC0tOynAI10iPQIlLWFdwj87OCI8Ay5kOynCMmQtND04g1djQAyFN30s3clZQ/9Zw4bjWG8BnkIibUBXKYSxP1dzwM8hV2m8K2hAXRMhv1WIr2WHVRwpe8GuQPjAlW5ldwAoRT9VaW50OEBBcnJheTqiACmBRE8tMzI3NjiHTifjAWGBQWhiOwBWRSkAZS5zZXQobi5Qc3ViYUEIKIIGLJfFXQBbBlR04GxyPSUDADt0PHI7Kyt0RSBHdOBYW3QrIgddA8EKIjJpLnB1c2hMKGXge+ENbitGByyMRSkADssOaSxpAwiXLA7ADOIKO0ENbltCDTBpK3RdpY9CDWE9aWIELG6LUUSIUcMmcmwsZaOhIRJpgaBkRi/B4ghjKzF8MMGkxgMboEAiA2LmDQA+Im51gG1iZXIiPT1hi8BvZiB0LnTAAoGsqHQpLLADeqEDK6CtgnoBeDwyP2U9YaYqc4QPLYMPKYMQclsgMl0vMirgjHwwFCk8ZbM/BQEraTpBRQE8PDE6Zaa3KoBuLEU/KHI9gEIWIEdC4C8pQjxhKTqIcj1h43diPXIrJe5x8ktBJaAhMIYgIcZCI1MAonpPbitrUCmhQjBQPT09aEQeKYTHRT4/wyvtT6ICQBalA2xpXGNlRFNEA2KUckBSZSGGCjtyPGXgRHIpBcGpaUADbj0odD0QaFtyXUWDO2k8Am4gBGkpb1t'
			$g___JsLibGunzip &= 'zK9HAr3RbaYOdciRIZLW2YUYJBAVhgAhKTmlmzQBidWZmZXI9b30rKkEwKsOpYAsD52Qfd+Y/gBSMNnIpgzbFH4VzojAAkyk6dAMJYocmleECOkMuYhQWPnJAJ3v0AyNVPRBjpQNEObQLdOh9LELYRka5C4QakgRIc3x8cgBnKPQDbdQuc5IZKQsEZwkEwRgPIktTC1k3A3djPHQ7q+g5AixBYEpVsCdVsCeqVWAnVRAnVfCJVcCJSFUsY6gELGzDAGMAO3N3aXRjaCiAaS51PWNbbOAdECxpLnalACgzMYMge7ABfHwxMzmiAAJ274lkIGZpbGVAIHNpZ25hwI1lgjoAii51KyIscQAOdsA7QE3HBXApe2MAYXNlIDg6YnIAZWFrO2RlZmEQdWx0OjaPdW5rEG5vd24wj21wcghlc3PRmW1ldGgEb2Sijy5wKSl9UVBYaS5oRQVlhAB8kRMMPDw4lgAxNqYAFDI0oA1IghJEYXRAZSgxZTMqcFZpRC5OdQRpLk2lADBwPCg0JiAG0A6wEUkDZAG2BDgsbCs9acguSSkwhyg4ggKzo8J1ES5vPTA7AAT1CRFgjnVbb5EzU3RyAGluZy5mcm9toENoYXJDUJ0oYKIgaS5uYW2woC5qwG9pbigiIvINAAQ8MTafBZ8FnwWZBUo9NnVnBTAFMiIFUC5pLgRCPcOidyhjLDCkLGwwby5CMB4oUxQDtw4fH2QgaGVhZABlciBjcmMxNiwiKQFaIBJjVDQtNHZd0APWADPQrxEZBgEydwABghkWATEQAfAZ9gBsAC00LTQ8NTEyhCpuoAphPW4pYC0F4T5tsAp7aW5kZRB4OmwsgzhTaXoQZTphfeELZGF0QGE9cj1zLrE2bIVwAGMgH0s9Zj0+DQfWDQoiAbgwLHcocuAsVSxVKbAQsLx2KRG1uENSQ0CBIGNoAGVja3N1bTogEDB4Iis1Ay50b4VDHiiAvCsiIC/SAeZmagESMUw9cFadFl8JEDw8MjRTCSg0MgA5NDk2NzI5NfwmcoQWIQoAEi4K4kIAOUeAEdDCnwN0aCmyCSKsK27ACNJJbYOHaTRKMGM9bH1yAUDBMDsBkUhwLHksYixn0XNDbSxkkGJ2cC6BSiJwsAB5PWdECTtwBDx54GJwKXYrPeBnW3BdLlEZtQGAOxpFkmZigjgod3YpLB9wBMYDcFqwjvYDLGQp3Cxk/wSCwELbYoE3CgRjoAf3BztiPWKeCFtjAG9uY2F0LmFwAHBseShbXSxiBCl9ZFtifSx0KAAiWmxpYi5HdYBuemlwIixCcBHDKgGIBGRlY2+jSnACDXgBZz8DptVnZXRNamXxkHM7A0Y9A1MCIhwsQY8B4QPpBmV0Tr9gRKACTwHPA88DQFFhzgMHQQHPA88DTXRpbWUB2wNHKX0pLmNhVGxsInYpQiRn4hQgLD0gsTwIFigVFGVkc4MCNxVlZIIbMAPDAy5tpwEovwJgAiLwOHGOIMOC/BCNOyBpPP4EBSkAIGlOsAArKykge2RlYwBvbXByZXNzZUBkICs9ICgJgEEAcnJheVtpXSAAPCAxNiA/ICIAMCIgOiAiIikIICsgEZwudG9TAHRyaW5nKDE2ACk7fTs='
			$g___JsLibGunzip = _B64Decode($g___JsLibGunzip, True, True)
			If @error Then Return SetError(2, __HttpRequest_ErrNotify('__Gzip_Uncompress', 'Khởi tạo thư viện Gzip thất bại'), $sBinaryData)
			$g___JsLibGunzip = BinaryToString($g___JsLibGunzip)
		EndIf
		Local $sRet = _JS_Execute('', 'var compressed=[' & StringTrimLeft(StringRegExpReplace($sBinaryData, '(\w{2})', ',0x$1'), 6) & '];' & $g___JsLibGunzip, 'decompressed')
		If @error Or $sRet = '' Then Return SetError(3, __HttpRequest_ErrNotify('__Gzip_Uncompress', 'Giải mã Gzip thất bại'), $sBinaryData)
		Return StringStripWS($sRet, 3)
	EndFunc

	Func __ArrayDuplicate($aArray, $iCase = True, $iCount = False, $iCheckDulplicateNumber = False, $iBase = 0)
		If Not IsArray($aArray) Or UBound($aArray) < $iBase Then Return SetError(1, 0, $aArray)
		Local $oDictionary = ObjCreate("Scripting.Dictionary")
		With $oDictionary
			.CompareMode = Number(Not $iCase)
			If $iCheckDulplicateNumber = False Then
				For $i = $iBase To UBound($aArray) - 1
					.Item($aArray[$i])
				Next
				$aArray = .Keys
				If $iCount Then _ArrayInsert($aArray, 0, $oDictionary.Count)
				$oDictionary = Null
				Return $aArray
			Else
				For $i = $iBase To UBound($aArray) - 1
					If .Exists($aArray[$i]) Then
						.Item($aArray[$i]) = .Item($aArray[$i]) + 1
					Else
						.Add($aArray[$i], 1)
					EndIf
				Next
				Local $aArray2 = [.Keys, .Items]
				If $iCount Then
					_ArrayInsert($aArray2[0], 0, $oDictionary.Count)
					_ArrayInsert($aArray2[1], 0, $oDictionary.Count)
				EndIf
				$oDictionary = Null
				Return $aArray2
			EndIf
		EndWith
	EndFunc

	Func __ObjectErrDetect()
		If $g___oErrorStop = 0 Then
			With $g___oError
				Local $sErrDescription = .windescription & ' ' & .description
				Local $sReport = StringReplace('<Error> COM [Error ' & Hex(.number) & '] (Line ' & .scriptline & ') ' & .source & (StringIsSpace($sErrDescription) ? '' : ' : ' & $sErrDescription), @CRLF, ' ')
			EndWith
			_HttpRequest_ConsoleWrite(@CRLF & $sReport & @CRLF)
		EndIf
		$g___oErrorStop = 0
		Return SetError($g___oError.scriptline)
	EndFunc

	Func __HttpRequest_CancelReadWrite()
		$g___swCancelReadWrite = Not $g___swCancelReadWrite
	EndFunc


	Func __HttpRequest_SetLastError($iErrCode)
		DllCall($dll_Kernel32, 'ptr', 'SetLastError', 'int', $iErrCode)
	EndFunc


	Func __HttpRequest_GetLastError()
		Return DllCall($dll_Kernel32, 'int', 'GetLastError')[0]
	EndFunc


	Func __Data2Send_CheckEncode($sData2Send)
		Local $aPartData = StringRegExp($sData2Send, '(?:^|\&)(\w+)\h*?=\h*?([^\&]+)', 3)
		For $i = 1 To UBound($aPartData) - 1 Step 2
			If Not StringRegExp($aPartData[$i], '\%[0-9A-Z]') And StringRegExp($aPartData[$i], '[^\w\-\+\.\~\!]') Then
				;$sData2Send = StringReplace($sData2Send, $aPartData[$i - 1] & $aPartData[$i], $aPartData[$i - 1] & _URIEncode($aPartData[$i]), 1, 1)
				__HttpRequest_ErrNotify('__Data2Send_CheckEncode', 'Giá trị của Key "' & $aPartData[$i - 1] & '" trong POST data của _HttpRequest chưa Encode, điều đó có thể khiến request thất bại' & @CRLF, '', 'Warning')
			EndIf
		Next
	EndFunc

	Func _HttpRequest_CloseAll()
		ConsoleWrite(@CRLF)
		Local $aListSession = _HttpRequest_SessionList()
		If Not @error Then
			For $i = 0 To UBound($aListSession) - 1
				If $g___hRequest[$i] Then $g___hRequest[$i] = _WinHttpCloseHandle2($g___hRequest[$i])
				If $g___hWebSocket[$i] Then $g___hWebSocket[$i] = _WinHttpWebSocketClose2($g___hWebSocket[$i])
				If $g___hConnect[$i] Then $g___hConnect[$i] = _WinHttpCloseHandle2($g___hConnect[$i])
				_HttpRequest_SessionClear($aListSession[$i])
			Next
		EndIf
		;---------------------------------------------------------------------------
		If $g___hWinHttp_StatusCallback Then $g___hWinHttp_StatusCallback = DllCallbackFree($g___hWinHttp_StatusCallback)
		If $dll_WinInet Then $dll_WinInet = DllClose($dll_WinInet)
		If $dll_Gdi32 Then $dll_Gdi32 = DllClose($dll_Gdi32)
		$dll_WinHttp = DllClose($dll_WinHttp)
		$dll_User32 = DllClose($dll_User32)
		$dll_Kernel32 = DllClose($dll_Kernel32)
		$g___oDicEntity = Null
		$g___retData = Null
		$g___oError = Null
		;---------------------------------------------------------------------------
		If $g___CookieJarPath Then _HttpRequest_CookieJarUpdateToFile()
	EndFunc

	Func __HttpRequest_ErrNotify($__TrueValue = '', $__ErrorNote = '', $__FalseValue = '', $iTypeWarning = Default)
		If @Compiled Or $g___OldConsole = $__ErrorNote Then Return
		$g___OldConsole = $__ErrorNote
		If $g___ErrorNotify = True And $__ErrorNote Then
			If $iTypeWarning = Default Then $iTypeWarning = 'Error'
			If $iTypeWarning Then $iTypeWarning = '<' & $iTypeWarning
			_HttpRequest_ConsoleWrite($iTypeWarning & '> [#' & $g___LastSession & '] ' & $__TrueValue & ' : ' & $__ErrorNote & @CRLF)
		EndIf
		Return $__FalseValue
	EndFunc
	
	Func __HttpRequest_CheckUpdate($iCurrentVersion)
		;http://jsoneditoronline.org/?id
		If $CmdLine[0] > 0 And $CmdLine[1] = '--httprequest-update' Then
			TraySetState(2)
			Local $UpdateInfo = BinaryToString(InetRead('http://api.jsoneditoronline.org/v1/docs/39cf9a61c45c466880a2e4899bc293be'))
			Local $sVersionHR = StringRegExp($UpdateInfo, 'version=(\d+)', 1)
			If Not @error And Number($sVersionHR[0]) > $iCurrentVersion Then
				If MsgBox(64 + 4096 + 4, 'Thông báo', '_HttpRequest có bản cập nhật mới (ver.' & $sVersionHR[0] & '). Bạn có muốn tải về ngay ?') = 6 Then
					Local $LinkDownload = StringRegExp($UpdateInfo, '(?i)linkdownload=\[([^\]]*?)\]', 1)
					If @error Then MsgBox(16 + 4096, 'Thông báo', 'Có lỗi trong khi thực hiện Update')
					If $LinkDownload[0] = '' Then Exit
					ShellExecute($LinkDownload[0])
					MsgBox(16 + 4096, 'Thông báo', 'Vui lòng xem ChangeLog phiên bản ' & $sVersionHR[0] & ' trong tập tin Help để xem thông tin thay đổi cụ thể.')
				Else
					MsgBox(64 + 4096, 'Thông báo', 'Thông báo cập nhật sẽ hiển thị lại sau nửa tiếng')
				EndIf
			EndIf
			Exit
		Else
			If @Compiled Or ($CmdLine[0] > 0 And $CmdLine[1] = '--hh-multi-process') Then Return
			Local $TimeInit = Number(RegRead('HKCU\Software\AutoIt v3\HttpRequest\AutoUpdate', 'Timer'))
			If Not $TimeInit Or TimerDiff($TimeInit) > 30 * 60 * 1000 Then
				RegWrite('HKCU\Software\AutoIt v3\HttpRequest\AutoUpdate', 'Timer', 'REG_SZ', TimerInit())
				Run(FileGetShortName(@AutoItExe) & ' "' & @ScriptFullPath & '" --httprequest-update', @WorkingDir, @SW_HIDE)
			EndIf
		EndIf
	EndFunc

	Func __HttpRequest_StatusGetDataFromPointer($pInfo, $lInfo, $iReturnType = 'wchar')
		Return DllStructGetData(DllStructCreate($iReturnType & '[' & $lInfo & ']', $pInfo), 1)
	EndFunc

	Volatile Func __HttpRequest_StatusCallback($hInternet, $iContext, $iInternetStatus, $pStatusInfo, $iStatusInfoLen)
		#forceref $hInternet, $iContext, $iInternetStatus, $pStatusInfo, $iStatusInfoLen
		Switch $iInternetStatus
			Case 0x00000002     ;CALLBACK_STATUS_NAME_RESOLVED
				$g___ServerIP = __HttpRequest_StatusGetDataFromPointer($pStatusInfo, $iStatusInfoLen)
				Return
				;----------------------------------------------------------------------------------------------------
			Case 0x00004000     ;CALLBACK_STATUS_REDIRECT
				$g___LocationRedirect = DllStructGetData(DllStructCreate("wchar[" & $iStatusInfoLen & "]", $pStatusInfo), 1)
				$g___retData[$g___LastSession][0] &= __CookieJar_Insert(StringRegExpReplace($g___LocationRedirect, '(?i)^https?://([^/]+).+', '${1}', 1), _WinHttpQueryHeaders2($g___hRequest[$g___LastSession], 22)) & @CRLF & 'Redirect → [' & $g___LocationRedirect & ']' & @CRLF
				__HttpRequest_ErrNotify('Request đã redirect tới', $g___LocationRedirect, '', '')
				Return
				;----------------------------------------------------------------------------------------------------
			Case 0x00010000     ;CALLBACK_STATUS_SECURE_FAILURE
				Local $sStatus = ''
				Local $aSSLError = [ _
						[__HttpRequest_StatusGetDataFromPointer($pStatusInfo, $iStatusInfoLen, 'dword')], _
						[0x00000001, 'CERT_REV_FAILED'], _
						[0x00000002, 'INVALID_CERT'], _
						[0x00000004, 'CERT_REVOKED'], _
						[0x00000008, 'INVALID_CA'], _
						[0x00000010, 'CERT_CN_INVALID'], _
						[0x00000020, 'CERT_DATE_INVALID'], _
						[0x00000040, 'CERT_WRONG_USAGE'], _
						[0x80000000, 'SECURITY_CHANNEL_ERROR']]
				For $i = 1 To 8
					If BitAND($aSSLError[0][0], $aSSLError[$i][0]) = $aSSLError[$i][0] Then $sStatus &= ' ' & $aSSLError[$i][1]
				Next
				_HttpRequest_ConsoleWrite('<Error> [#' & $g___LastSession & '] SLL Certificate:' & $sStatus & ' - Kiểm tra lại URL là http hay https' & @CRLF)
				Return
		EndSwitch
	EndFunc

	Func __HttpRequest_iReturnSplit($iReturn)
		Local $aRetMode[30]
		$aRetMode[11] = 4
		$aRetMode[8] = $g___LastSession
		;-------------------------------------------------
		For $iReturn In StringSplit($iReturn, '|', 2)
			If $iReturn == '' Then ContinueLoop
			Local $iLocalMode = StringRegExp($iReturn, '^\h*?([\&\!\+\-\*\.\_\~\^\☺]*?)(\d+):?(\d{0,2})', 3)
			If Not @error Then
				$aRetMode[0] = Number($iLocalMode[1])     ;Number Return Mode
				If $iLocalMode[2] Then     ;Query Header Mode
					$aRetMode[0] = 1
					$aRetMode[1] = Number($iLocalMode[2])
				EndIf
				If $iLocalMode[0] Then
					For $iLocalMode In StringSplit($iLocalMode[0], '', 2)
						Switch $iLocalMode
							Case '-'     ;$iReturn = 1 => Return Cookies, $iReturn > 1 => Return Binary Data
								$aRetMode[2] = 1
							Case '*'     ;force Disable Redirect
								$aRetMode[3] = 1
							Case '+'     ;Complete URL for relative URL
								$aRetMode[4] = 1
							Case '~'     ;force return ANSI
								$aRetMode[11] = 1
							Case '_'     ; force return Raw Text
								$aRetMode[12] = 1
							Case '^'     ; force WebSocket
								$aRetMode[13] = 1
							Case '.'     ; chỉ gửi request đi và không làm gì tiếp cả
								$aRetMode[14] = 1
							Case '!'     ; thêm header X-Forwarded-For cho request
								$aRetMode[15] = 1
							Case '&'        ; html decode result
								$aRetMode[16] = 1
							Case '☺'     ;Atl+1 ;mode ẩn 1
								$aRetMode[17] = 1
							Case Else
								Return SetError(1, __HttpRequest_ErrNotify('__HttpRequest_iReturnSplit', 'Không nhận ra dấu hiệu đã cài đặt'), '')
						EndSwitch
					Next
				EndIf
			Else
				;--------------------------------------------------------------------------------------------------------------------------------
				Local $iLocalOption = StringRegExp($iReturn, '^\h*?([\$\#\%])(.+)', 3)
				If @error Then Return SetError(2, __HttpRequest_ErrNotify('__HttpRequest_iReturnSplit', 'Sai pattern của Proxy'), '')
				For $i = 0 To UBound($iLocalOption) - 1 Step 2
					Switch $iLocalOption[$i]
						Case '%'         ;proxy ; $aRetMode[5][6][7]
							Local $aProxy = StringRegExp($iLocalOption[$i + 1], '(?i)(https?://)?(?:(\w*):)?(?:(\w*)@)?((?:\d{1,3}\.){3}\d{1,3}:\d+)$', 3)
							If @error Then Return SetError(3, __HttpRequest_ErrNotify('__HttpRequest_iReturnSplit', 'Sai pattern của Proxy'), '')
							$aRetMode[5] = $aProxy[0] & $aProxy[3]
							$aRetMode[6] = $aProxy[1]
							$aRetMode[7] = $aProxy[2]
						Case '#'         ;session ; $aRetMode[8]
							$g___hCookieLast = ''
							If Not StringIsDigit($iLocalOption[$i + 1]) Then Return SetError(4, __HttpRequest_ErrNotify('__HttpRequest_iReturnSplit', 'Sai pattern của Session'), '')
							If $iLocalOption[$i + 1] > $g___MaxSession_USE Then Return SetError(5, __HttpRequest_ErrNotify('__HttpRequest_iReturnSplit', 'Session vượt quá giới hạn. Max=' & $g___MaxSession_USE), '')
							$aRetMode[8] = Number($iLocalOption[$i + 1])
						Case '$'         ;file path ; $aRetMode[9][10]
							Local $aPath = StringRegExp($iLocalOption[$i + 1], '(?i)^(?:([A-Z]:[\\\/].*?)|([^\Q\/*?"<>|\E]+\.\w+))(?:\:(\d+))?($)', 3)
							If @error Then Return SetError(6, __HttpRequest_ErrNotify('__HttpRequest_iReturnSplit', 'Sai pattern của FilePath #1'), '')
							$aRetMode[0] = 3
							If $aPath[0] Then
								$aRetMode[9] = $aPath[0]
							ElseIf $aPath[1] Then
								$aRetMode[9] = @ScriptDir & '\' & $aPath[1]
							Else
								Return SetError(7, __HttpRequest_ErrNotify('__HttpRequest_iReturnSplit', 'Sai pattern của FilePath #2'), '')
							EndIf
							$aRetMode[10] = Number($aPath[2])
					EndSwitch
				Next
			EndIf
		Next
		Return $aRetMode
	EndFunc

	Func __HttpRequest_URLSplit($sURL)
		Local $aResult[11] = [1, 80, '', '', '', '', '', 'http', '', '', '']
		;---------------------------------------------------
		Local $aURL1 = StringRegExp($sURL, '(?i)^\h*(?:(?:(https?)|(ftp)|(wss?)):/{2,})?(www\.)?(.*?)\h*$', 3)
		If @error Or Not $aURL1[4] Then Return SetError(1, __HttpRequest_ErrNotify('__HttpRequest_URLSplit', '$sURL sai định dạng chuẩn #1'), '')
		If $aURL1[1] Then     ; Check ftp
			$aResult[0] = 3
			$aResult[1] = 0
		ElseIf $aURL1[2] Then
			If Not StringRegExp(@OSVersion, '^WIN_(10|81|8)$') Then Return SetError(2, __HttpRequest_ErrNotify('__HttpRequest_URLSplit', 'Websock chỉ áp dụng cho Win8 and Win10'), '')
			$aResult[8] = 1
			If $aURL1[2] = 'wss' Then
				$aResult[0] = 2
				$aResult[1] = 443
				$aResult[7] = 'https'
			EndIf
		ElseIf $aURL1[0] = 'https' Then     ;Check https
			$aResult[0] = 2
			$aResult[1] = 443
			$aResult[7] = 'https'
		EndIf
		; Chưa xác định được protocol thì sẽ check $aURL3[0] bên dưới
		;---------------------------------------------------
		Local $aURL2 = StringRegExp($aURL1[4], '^(?:([^\:\/]*?):([^\@\/]*?)@)?(.+)$', 3)     ;Tách user, pass, cred, URL
		If @error Then Return SetError(4, __HttpRequest_ErrNotify('__HttpRequest_URLSplit', '$sURL sai định dạng User/Pass trong URL'), '')
		$aResult[4] = $aURL2[0]     ;User
		$aResult[5] = $aURL2[1]     ;Pass
		If StringRegExp($aURL2[2], '(?i)^.*?\@ftp\.') Then
			$aResult[5] &= '@' & StringRegExp($aURL2[2], '(?i)^(.*?)\@ftp\.', 1)[0]
			$aURL2[2] = StringRegExpReplace($aURL2[2], '(?i)^.*?\@ftp\.', 'ftp.', 1)
		EndIf
		;---------------------------------------------------
		Local $aURL3 = StringRegExp($aURL2[2], '^([^\/\:]+)(?::(\d+))?(/.*)?($)', 3)     ;Tách Host, (Port) và URI
		If @error Then Return SetError(5, __HttpRequest_ErrNotify('__HttpRequest_URLSplit', '$sURL sai định dạng Host/Port trong URL'), '')
		If $aURL1[0] == '' And Not (StringRegExp($aURL3[0], '\.\w+$') Or $aURL3[0] = 'localhost') Then Return SetError(3, __HttpRequest_ErrNotify('__HttpRequest_URLSplit', '$sURL sai định dạng chuẩn #2'), '')
		$aResult[2] = StringRegExpReplace($aURL1[3] & $aURL3[0], '(\#[\w\-]+)$', '', 1)     ;Host
		$aResult[3] = $aURL3[2]     ;URI
		If $aURL3[1] Then $aResult[1] = Number($aURL3[1])     ; Check Port
		;---------------------------------------------------
		$aResult[9] = StringRegExpReplace($aResult[2], '.*?([\w\-]*?\.?[\w\-]*?\.?[\w\-]+\.[\w\-]+)$', '$1')     ;Domain
		$aResult[10] = (StringLeft($aResult[2], 3) = 'www' ? 'www.' : '')
		;---------------------------------------------------
		Return $aResult
	EndFunc

	Func _HttpRequest_ParseCURL($sCURL)
		Local $iURL = '', $iHeaders = '', $iData, $iProxy = '', $iAuth = '', $iAuthBK = '', $iMethod = 'GET', $iSavePath = '', $iReferer = '', $iCookie = ''
		Local $aURL, $aMethod, $aUserAgent, $aAuth, $aProxy, $aHeaders, $aData, $aSavePath, $aReferer, $aCookie, $iReturn = 2
		;---------------------------------------------------------
		$aURL = StringRegExp($sCURL, '\h+--url\h+([''"])?(.+?(?!\\))\1?(?:\h|$)', 1)
		If Not @error Then
			$iURL = $aURL[1]
		Else
			$aURL = StringRegExp($sCURL, '(?i)(?![''"])\h+(?![''"])((?:https?|ftp)://[^\s]+|localhost:?\d+?)(?:\h|$)', 1)
			If @error Then
				$aURL = StringRegExp($sCURL, '(?i)\h+["'']((?:https?|ftp)://[^\s]+|localhost:?\d+?)["''](?:\h+|$)', 1)
				If @error Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_ParseCURL', 'Không thể parse URL từ chuỗi CURL đã nạp vào'), '')
			EndIf
			$iURL = $aURL[0]
		EndIf
		;---------------------------------------------------------
		$aHeaders = StringRegExp($sCURL, '(?:--header|-H)\h+([''"])(.+?(?!\\))\1', 3)
		If Not @error Then
			For $i = 1 To UBound($aHeaders) - 1 Step 2
				$iHeaders &= $aHeaders[$i] & ($i < UBound($aHeaders) - 1 ? '|' : '')
			Next
		EndIf
		;---------------------------------------------------------
		If StringRegExp($sCURL, '\h+-k(\h+|$)') Then $iHeaders &= '|Upgrade-Insecure-Requests: 1'
		;---------------------------------------------------------
		If StringRegExp($sCURL, '\h+(-I|--head)(\h+|$)') Then
			$iMethod = 'HEAD'
		ElseIf StringRegExp($sCURL, '\h+-T(\h+|$)') Then
			$iMethod = 'PUT'
		EndIf
		;---------------------------------------------------------
		If StringRegExp($sCURL, '\h+-i(\h+|$)') Then $iReturn = 1
		;---------------------------------------------------------
		$aData = StringRegExp($sCURL, '(?:--data(?:-urlencode|-ascii|-binary)?|-d)\h+([''"])(.+?(?!\\))\1(?:\h|$)', 3)
		If Not @error Then
			For $i = 1 To UBound($aData) - 1 Step 2
				$iData &= $aData[$i] & ($i < UBound($aData) - 1 ? '&' : '')
			Next
			$iMethod = 'POST'
		Else
			$aData = StringRegExp($sCURL, '(?:--form|-F)\h+([''"])(.+?(?!\\))\1(?:\h|$)', 3)
			If Not @error Then
				Local $iData[UBound($aData) / 2], $iCount = 0
				For $i = 1 To UBound($aData) - 1 Step 2
					$iData[$iCount] = $aData[$i]
					$iCount += 1
				Next
				$iMethod = 'POST'
			EndIf
		EndIf
		;---------------------------------------------------------
		$aMethod = StringRegExp($sCURL, '\h+(?:--request|-X)\h+(GET|POST|PUT|HEAD|DELETE|CONNECT|OPTIONS|TRACE|PATCH)(?:\h|$)', 1)
		If Not @error Then $iMethod = $aMethod[0]
		;---------------------------------------------------------
		$aUserAgent = StringRegExp($sCURL, '\h+(?:--user-agent|-A)\h+([''"])?(.+?(?!\\))\1?(?:\h|$)', 1)
		If Not @error Then $iHeaders = ($iHeaders ? '|' : '') & 'User-Agent: ' & $aUserAgent[1]
		;---------------------------------------------------------
		$aReferer = StringRegExp($sCURL, '\h+(?:--referer|-e)\h+([''"])?(.+?(?!\\))\1?(?:\h|$)', 1)
		If Not @error Then $iReferer = $aReferer[1]
		;---------------------------------------------------------
		$aAuth = StringRegExp($sCURL, '\h+(?:--user|-u)\h+([''"])?(.+?(?!\\))\1?(?:\h|$)', 1)
		If Not @error Then $iAuth = $aAuth[1]
		;----------------------------------------------------------------------------------------------------------------------------------------------
		$aProxy = StringRegExp($sCURL, '\h+(?:--proxy|-x)\h+([''"])?(.+?(?!\\))\1?(?:\h|$)', 1)
		If Not @error Then $iProxy = $aProxy[1]
		;----------------------------------------------------------------------------------------------------------------------------------------------
		$aCookie = StringRegExp($sCURL, '\h+(?:--cookie|-b)\h+([''"])?(.+?(?!\\))\1?(?:\h|$)', 1)
		If Not @error Then $iCookie = $aCookie[1]
		If Not StringInStr($iCookie, '=', 1, 1) And FileExists($iCookie) Then $iCookie = FileRead($iCookie)
		;----------------------------------------------------------------------------------------------------------------------------------------------
		$aSavePath = StringRegExp($sCURL, '\h+(?:--remote-name|-o)\h+([''"])?(.+?(?!\\))\1?(?:\h|$)', 1)
		If Not @error Then $iSavePath = $aSavePath[1]
		;----------------------------------------------------------------------------------------------------------------------------------------------
		If $iAuth Then $iAuthBK = _HttpRequest_SetAuthorization($iAuth)
		Local $vData = _HttpRequest($iReturn & ($iProxy ? '|%' & $iProxy : '') & ($iSavePath ? '|$' & $iSavePath : ''), $iURL, $iData, $iCookie, $iReferer, $iHeaders, $iMethod)
		Local $vError = @error, $vExtended = @extended
		If $iAuth Then _HttpRequest_SetAuthorization($iAuthBK)
		Return SetError($vError, $vExtended, $vData)
	EndFunc
#EndRegion



#Region < FTP UDF>
	Func __FTP_MakeQWord($iLoDWORD, $iHiDWORD)
		Local $tInt64 = DllStructCreate("uint64")
		Local $tDwords = DllStructCreate("dword;dword", DllStructGetPtr($tInt64))
		DllStructSetData($tDwords, 1, $iLoDWORD)
		DllStructSetData($tDwords, 2, $iHiDWORD)
		Return DllStructGetData($tInt64, 1)
	EndFunc

	Func _FTP_Open2($sAgent, $iAccessType, $sProxyName = '', $sProxyBypass = '', $iFlags = 0)     ;$iAccessType = 1: No Proxy; 3: Proxy
		Local $ai_InternetOpen = DllCall($dll_WinInet, 'handle', 'InternetOpenW', 'wstr', $sAgent, 'dword', $iAccessType, 'wstr', $sProxyName, 'wstr', $sProxyBypass, 'dword', $iFlags)
		If @error Or $ai_InternetOpen[0] = 0 Then Return SetError(1)
		Return $ai_InternetOpen[0]
	EndFunc

	Func _FTP_Connect2($hInternetSession, $sServerName, $sUserName, $sPassword, $iServerPort = 0)
		Local $ai_InternetConnect = DllCall($dll_WinInet, 'hwnd', 'InternetConnectW', 'handle', $hInternetSession, 'wstr', $sServerName, 'ushort', $iServerPort, 'wstr', $sUserName, 'wstr', $sPassword, 'dword', 1, 'dword', 2, 'dword_ptr', 0)
		If @error Or $ai_InternetConnect[0] = 0 Then Return SetError(1)
		Return $ai_InternetConnect[0]
	EndFunc

	Func _FTP_CloseHandle2($hSession)
		DllCall($dll_WinInet, 'bool', 'InternetCloseHandle', 'handle', $hSession)
	EndFunc

	Func _FTP_FileReadEx($hFTPConnect, $sRemoteFile, $CallBackFunc_Progress = '', $iBytesPerLoop = $g___BytesPerLoop)
		Local $ai_FtpOpenfile = DllCall($dll_WinInet, 'handle', 'FtpOpenFileW', 'handle', $hFTPConnect, 'wstr', $sRemoteFile, 'dword', 0x80000000, 'dword', 2, 'dword_ptr', 0)     ;2 = Binarry, 1 = ascii
		If @error Or $ai_FtpOpenfile[0] == 0 Then Return SetError(1, '', '')
		Local $tBuffer = DllStructCreate("byte[" & $iBytesPerLoop & "]")
		Local $vBinaryData = Binary(''), $vNowSizeBytes = 1, $vTotalSizeBytes = -1, $iCheckCallbackFunc = 0, $aCall
		;----------------------------------
		If $CallBackFunc_Progress <> '' Then
			$iCheckCallbackFunc = 1
			Local $ai_hSize = DllCall($dll_WinInet, 'dword', 'FtpGetFileSize', 'handle', $ai_FtpOpenfile[0], 'dword*', 0)
			If @error Or $ai_hSize[0] = 0 Then Return SetError(103, __HttpRequest_ErrNotify('_FTP_FileReadEx', 'Không thể lấy được kích cỡ tập tin'), 0)
			$vTotalSizeBytes = __FTP_MakeQWord($ai_hSize[0], $ai_hSize[2])
			If $vTotalSizeBytes > 2147483647 Then Return SetError(102, __HttpRequest_ErrNotify('_FTP_FileReadEx', 'Tập tin quá lớn'), 0)
		EndIf
		;----------------------------------
		For $i = 1 To 2147483647
			If $g___swCancelReadWrite Then
				$g___swCancelReadWrite = False
				Return SetError(997, __HttpRequest_ErrNotify('_FTP_FileReadEx', 'Đã huỷ request'), 0)
			EndIf
			$aCall = DllCall($dll_WinInet, 'bool', 'InternetReadFile', 'handle', $ai_FtpOpenfile[0], 'struct*', $tBuffer, 'dword', $iBytesPerLoop, 'dword*', 0)
			If @error Or $aCall[0] = 0 Or ($aCall[0] = 1 And $aCall[4] = 0) Then ExitLoop
			If $aCall[4] < $iBytesPerLoop Then
				$vBinaryData &= BinaryMid(DllStructGetData($tBuffer, 1), 1, $aCall[4])
			Else
				$vBinaryData &= DllStructGetData($tBuffer, 1)
			EndIf
			$vNowSizeBytes += $aCall[4]
			If $iCheckCallbackFunc Then $CallBackFunc_Progress($vNowSizeBytes, $vTotalSizeBytes)
		Next
		DllCall($dll_WinInet, 'bool', 'InternetCloseHandle', 'handle', $ai_FtpOpenfile[0])
		Return $vBinaryData
	EndFunc

	Func _FTP_FileWriteEx($hFTPConnect, $sRemoteFile, $iData, $CallBackFunc_Progress = '', $iBytesPerLoop = $g___BytesPerLoop)
		Local $ai_FtpOpenfile = DllCall($dll_WinInet, 'handle', 'FtpOpenFileW', 'handle', $hFTPConnect, 'wstr', $sRemoteFile, 'dword', 0x40000000, 'dword', 2, 'dword_ptr', 0)     ;2 = Binarry, 1 = ascii
		If @error Or $ai_FtpOpenfile[0] = 0 Then Return SetError(1, '', '')
		If Not IsBinary($iData) Then $iData = StringToBinary($iData, 4)
		Local $vNowSizeBytes = 1, $vTotalSizeBytes = -1, $iCheckCallbackFunc = 0
		Local $iDataMid, $iDataMidLen, $tBuffer, $aCall
		;----------------------------------
		If $CallBackFunc_Progress <> '' Then
			$iCheckCallbackFunc = 1
			$vTotalSizeBytes = BinaryLen($iData)
			If $vTotalSizeBytes > 2147483647 Then Return SetError(101, __HttpRequest_ErrNotify('_FTP_FileWriteEx', 'Tập tin quá lớn'), 0)
		EndIf
		;----------------------------------
		For $i = 1 To 2147483647
			If $g___swCancelReadWrite Then
				$g___swCancelReadWrite = False
				Return SetError(996, __HttpRequest_ErrNotify('_FTP_FileWriteEx', 'Đã huỷ request'), 0)
			EndIf
			$iDataMid = BinaryMid($iData, $vNowSizeBytes, $iBytesPerLoop)
			$iDataMidLen = BinaryLen($iDataMid)
			If Not $iDataMidLen Then ExitLoop
			$tBuffer = DllStructCreate("byte[" & ($iDataMidLen + 1) & "]")
			DllStructSetData($tBuffer, 1, $iDataMid)
			$aCall = DllCall($dll_WinInet, 'bool', 'InternetWriteFile', 'handle', $ai_FtpOpenfile[0], 'struct*', $tBuffer, 'dword', $iDataMidLen, 'dword*', 0)
			If @error Or $aCall[0] = 0 Then ExitLoop
			$vNowSizeBytes += $iDataMidLen
			If $iCheckCallbackFunc Then $CallBackFunc_Progress($vNowSizeBytes, $vTotalSizeBytes)
		Next
		DllCall($dll_WinInet, 'bool', 'InternetCloseHandle', 'handle', $ai_FtpOpenfile[0])
		Return 1
	EndFunc

	Func _FTP_DirDelete2($hFTPConnect, $sRemoteDirPath)
		Local $ai_FTPDelDir = DllCall($dll_WinInet, 'bool', 'FtpRemoveDirectoryW', 'handle', $hFTPConnect, 'wstr', $sRemoteDirPath)
		If @error Or $ai_FTPDelDir[0] = 0 Then Return SetError(1, 0, 0)
		Return 1
	EndFunc

	Func _FTP_DirCreate2($hFTPConnect, $sRemoteDirPath)
		Local $ai_FTPMakeDir = DllCall($dll_WinInet, 'bool', 'FtpCreateDirectoryW', 'handle', $hFTPConnect, 'wstr', $sRemoteDirPath)
		If @error Or $ai_FTPMakeDir[0] = 0 Then Return SetError(1, 0, 0)
		Return 1
	EndFunc

	Func _FTP_DirSetCurrent2($hFTPConnect, $sRemoteDirPath)
		Local $ai_FTPSetCurrentDir = DllCall($dll_WinInet, 'bool', 'FtpSetCurrentDirectoryW', 'handle', $hFTPConnect, 'wstr', $sRemoteDirPath)
		If @error Or $ai_FTPSetCurrentDir[0] = 0 Then Return SetError(1, 0, 0)
		Return 1
	EndFunc

	Func _FTP_DirGetCurrent2($hFTPConnect)
		Local $ai_FTPGetCurrentDir = DllCall($dll_WinInet, 'bool', 'FtpGetCurrentDirectoryW', 'handle', $hFTPConnect, 'wstr', "", 'dword*', 260)
		If @error Or $ai_FTPGetCurrentDir[0] = 0 Then Return SetError(1, 0, 0)
		Return $ai_FTPGetCurrentDir[2]
	EndFunc

	Func _FTP_ListToArray2($hFTPConnect, $iReturnType = 0)
		Local $asFileArray[1][3], $aDirectoryArray[1][3] = [[0, 'Size', 'Type']]
		If $iReturnType < 0 Or $iReturnType > 2 Then Return SetError(1, 0, $asFileArray)
		Local $tWIN32_FIND_DATA = DllStructCreate("DWORD dwFileAttributes; dword ftCreationTime[2]; dword ftLastAccessTime[2]; dword ftLastWriteTime[2]; DWORD nFileSizeHigh; DWORD nFileSizeLow; dword dwReserved0; dword dwReserved1; WCHAR cFileName[260]; WCHAR cAlternateFileName[14];")
		Local $iLasterror
		Local $aCallFindFirst = DllCall($dll_WinInet, 'handle', 'FtpFindFirstFileW', 'handle', $hFTPConnect, 'wstr', "", 'struct*', $tWIN32_FIND_DATA, 'dword', 0x04000000, 'dword_ptr', 0)
		If @error Or Not $aCallFindFirst[0] Then Return SetError(2, 0, '')
		Local $iDirectoryIndex = 0, $sFileIndex = 0, $bIsDir, $aCallFindNext
		Do
			$bIsDir = BitAND(DllStructGetData($tWIN32_FIND_DATA, "dwFileAttributes"), $FILE_ATTRIBUTE_DIRECTORY) = $FILE_ATTRIBUTE_DIRECTORY
			If $bIsDir And($iReturnType <> 2) Then
				$iDirectoryIndex += 1
				If UBound($aDirectoryArray) < $iDirectoryIndex + 1 Then ReDim $aDirectoryArray[$iDirectoryIndex * 2][3]
				$aDirectoryArray[$iDirectoryIndex][0] = DllStructGetData($tWIN32_FIND_DATA, "cFileName")
				$aDirectoryArray[$iDirectoryIndex][1] = __FTP_MakeQWord(DllStructGetData($tWIN32_FIND_DATA, "nFileSizeLow"), DllStructGetData($tWIN32_FIND_DATA, "nFileSizeHigh"))
				$aDirectoryArray[$iDirectoryIndex][2] = 'Folder'
			ElseIf Not $bIsDir And $iReturnType <> 1 Then
				$sFileIndex += 1
				If UBound($asFileArray) < $sFileIndex + 1 Then ReDim $asFileArray[$sFileIndex * 2][3]
				$asFileArray[$sFileIndex][0] = DllStructGetData($tWIN32_FIND_DATA, "cFileName")
				$asFileArray[$sFileIndex][1] = __FTP_MakeQWord(DllStructGetData($tWIN32_FIND_DATA, "nFileSizeLow"), DllStructGetData($tWIN32_FIND_DATA, "nFileSizeHigh"))
				$asFileArray[$sFileIndex][2] = 'File'
			EndIf
			$aCallFindNext = DllCall($dll_WinInet, 'bool', 'InternetFindNextFileW', 'handle', $aCallFindFirst[0], 'struct*', $tWIN32_FIND_DATA)
			If @error Then Return SetError(3, DllCall($dll_WinInet, 'bool', 'InternetCloseHandle', 'handle', $aCallFindFirst[0]), '')
		Until Not $aCallFindNext[0]
		DllCall($dll_WinInet, 'bool', 'InternetCloseHandle', 'handle', $aCallFindFirst[0])
		$aDirectoryArray[0][0] = $iDirectoryIndex
		$asFileArray[0][0] = $sFileIndex
		Switch $iReturnType
			Case 0
				ReDim $aDirectoryArray[$aDirectoryArray[0][0] + $asFileArray[0][0] + 1][3]
				For $i = 1 To $sFileIndex
					For $j = 0 To 2
						$aDirectoryArray[$aDirectoryArray[0][0] + $i][$j] = $asFileArray[$i][$j]
					Next
				Next
				$aDirectoryArray[0][0] += $asFileArray[0][0]
				Return $aDirectoryArray
			Case 1
				ReDim $aDirectoryArray[$iDirectoryIndex + 1][3]
				Return $aDirectoryArray
			Case 2
				ReDim $asFileArray[$sFileIndex + 1][3]
				Return $asFileArray
		EndSwitch
	EndFunc

	Func _FtpRequest($aRetMode, $aURL, $sData2Send, $CallBackFunc_Progress)
		If Not $dll_WinInet Then
			$dll_WinInet = DllOpen('wininet.dll')
			If @error Then Return SetError(1, __HttpRequest_ErrNotify('_FtpRequest', 'Gọi wininet.dll thất bại'), '')
		EndIf
		;------------------------------------------
		If Not IsArray($aRetMode) Then
			$aRetMode = __HttpRequest_iReturnSplit($aRetMode)
			If @error Then Return SetError(2, 0, '')
			$g___LastSession = $aRetMode[8]
		EndIf
		;-------------------------------------------------
		If Not IsArray($aURL) Then
			$aURL = __HttpRequest_URLSplit($aURL)
			If @error Then Return SetError(3, 0, '')
		EndIf
		;-------------------------------------------------
		Local $iError = 0, $ReData, $iProxy = '', $iAccessType = 1, $iProxyBypass = ''
		If $aRetMode[5] Then
			$iProxy = $aRetMode[5]
			$iAccessType = 3
		ElseIf $g___hProxy[$g___LastSession][0] Then
			$iProxy = $g___hProxy[$g___LastSession][0]
			$iProxyBypass = $g___hProxy[$g___LastSession][2]
			$iAccessType = 3
		EndIf
		;------------------------------------------
		If Not $g___ftpOpen[$g___LastSession] Then $g___ftpOpen[$g___LastSession] = _FTP_Open2($g___UserAgent[$g___LastSession], $iAccessType, $iProxy, $iProxyBypass)
		$g___ftpConnect[$g___LastSession] = _FTP_Connect2($g___ftpOpen[$g___LastSession], $aURL[2], $aURL[4], $aURL[5], $aURL[1])
		;------------------------------------------
		Local $sFileName = '', $sDirPath = ''
		Switch $aURL[3]
			Case '/', ''
				$aRetMode[0] = 1
			Case Else
				Local $aRemotePath = StringSplit($aURL[3], '/')
				If StringRegExp($aRemotePath[$aRemotePath[0]], '^[^\.]+\.\w+$') Then
					$sFileName = $aRemotePath[$aRemotePath[0]]
				EndIf
				If $aRemotePath[0] > 1 Then
					If _FTP_DirSetCurrent2($g___ftpConnect[$g___LastSession], '/') = 1 Then
						For $i = 1 To $aRemotePath[0] - ($sFileName ? 1 : 0)
							If $aRemotePath[$i] == '' Then
								If $i = 1 Then
									ContinueLoop
								Else
									$iError = 4
									ExitLoop
								EndIf
							EndIf
							If _FTP_DirSetCurrent2($g___ftpConnect[$g___LastSession], $aRemotePath[$i]) = 0 Then
								If _FTP_DirCreate2($g___ftpConnect[$g___LastSession], $aRemotePath[$i]) = 0 Then
									$iError = 5
									ExitLoop
								Else
									If _FTP_DirSetCurrent2($g___ftpConnect[$g___LastSession], $aRemotePath[$i]) = 0 Then
										$iError = 6
										ExitLoop
									EndIf
								EndIf
							EndIf
						Next
					Else
						$iError = 7
					EndIf
				EndIf
		EndSwitch
		;------------------------------------------
		If $iError = 0 Then
			Select
				Case $aRetMode[0] = 0 And $sData2Send == ''
					;Null
				Case $aRetMode[0] = 1 And $sData2Send == ''
					$ReData = _FTP_ListToArray2($g___ftpConnect[$g___LastSession])
					If @error Then $iError = 8
				Case Else
					If $sFileName Then
						If $sData2Send Then
							If StringRegExp($sData2Send, '(?i)^[A-Z]:\\') And FileExists($sData2Send) Then
								$sData2Send = _GetFileInfo($sData2Send, 0)
								If @error Then
									$iError = 9
								Else
									$sData2Send = $sData2Send[2]
								EndIf
							EndIf
							If $iError = 0 Then
								_FTP_FileWriteEx($g___ftpConnect[$g___LastSession], $sFileName, $sData2Send, $CallBackFunc_Progress)
								If @error Then $iError = 10
								If $aRetMode[0] = 1 Then
									$ReData = _FTP_ListToArray2($g___ftpConnect[$g___LastSession])
									If @error Then $iError = 12
								EndIf
							EndIf
						Else
							$ReData = _FTP_FileReadEx($g___ftpConnect[$g___LastSession], $sFileName, $CallBackFunc_Progress)
							If @error Then
								$iError = 11
							Else
								If $aRetMode[0] = 2 Then $ReData = BinaryToString($ReData, 4)
							EndIf
						EndIf
					EndIf
			EndSelect
		EndIf
		Return SetError($iError, $iError ? __HttpRequest_ErrNotify('_FtpRequest', 'FTP request thất bại với $iError=' & $iError) : 0, $ReData)
	EndFunc
#EndRegion



#Region <WinHttp Websock>
	Func _HexArrayToString($sHexString, $iFilter = True, $sSpecialCharFilter = '.')
		If $sHexString == '' Then Return SetError(1, '', '')
		If StringLeft($sHexString, 2) = '0x' Then $sHexString = StringTrimLeft($sHexString, 2)
		Local $sString = '', $aHexString = StringRegExp($sHexString, '\w{2}', 3)
		If @error Then Return SetError(2, '', '')
		For $i = 0 To UBound($aHexString) - 1
			$aHexString[$i] = Dec($aHexString[$i])
			If $iFilter Then
				$sString &= (($aHexString[$i] < 32 Or $aHexString[$i] > 127) ? $sSpecialCharFilter : Chr($aHexString[$i]))
			Else
				$sString &= Chr($aHexString[$i])
			EndIf
		Next
		Return $sString
	EndFunc

	Func _StringToHexArray($sString)
		If $sString == '' Then Return SetError(1, '', '')
		Return Hex(StringToBinary($sString, 4))
	EndFunc

	Func _HttpRequest_WebSocketReceive($iReturnType = Default, $iSession = Default)     ;$iReturnType = 0: ANSI, 1: UTF8, 2: Binary, 3: HexArray
		If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
		If $iReturnType = Default Then $iReturnType = 1
		If $g___hWebSocket[$iSession] = 0 Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_WebSocketReceive', 'WebSocket handle rỗng (Chưa được khởi tạo ?)'), '')
		Switch $iReturnType
			Case 0
				Return BinaryToString(_WinHttpWebSocketRead2($g___hWebSocket[$iSession]))
			Case 1
				Return BinaryToString(_WinHttpWebSocketRead2($g___hWebSocket[$iSession]), 4)
			Case 2
				Return _WinHttpWebSocketRead2($g___hWebSocket[$iSession])
			Case 3
				Return _HexArrayToString(_WinHttpWebSocketRead2($g___hWebSocket[$iSession]))
		EndSwitch
	EndFunc

	Func _HttpRequest_WebSocketSend($sData2Send, $iSession = Default)
		If IsKeyword($iSession) Or $iSession == '' Then $iSession = $g___LastSession
		If $g___hWebSocket[$iSession] = 0 Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_WebSocketSend', 'WebSocket handle rỗng'), False)
		Local $iError = _WinHttpWebSocketSend2($g___hWebSocket[$iSession], $sData2Send)
		If @error Or $iError <> 0 Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_WebSocketSend', 'WebSocket gửi dữ liệu thất bại'), False)
		Return True
	EndFunc

	Func _WinHttpWebSocketRequest($sData2Send)
		$g___hWebSocket[$g___LastSession] = _WinHttpWebSocketCompleteUpgrade2($g___hRequest[$g___LastSession])
		If Not $g___hWebSocket[$g___LastSession] Then Return SetError(114, __HttpRequest_ErrNotify('_WinHttpWebSocketRequest', 'WebSocket mở thất bại', -1), '')
		_HttpRequest_ConsoleWrite('> [#' & $g___LastSession & '] WebSocket mở thành công' & @CRLF)
		;------------------------------------------------------------------------------------------------
		If $sData2Send Then
			Local $iError = _WinHttpWebSocketSend2($g___hWebSocket[$g___LastSession], $sData2Send)
			If @error Or $iError <> 0 Then Return SetError(115, __HttpRequest_ErrNotify('_WinHttpWebSocketRequest', 'WebSocket gửi dữ liệu thất bại', 101, 'Warning'), '')
			_HttpRequest_ConsoleWrite('> [#' & $g___LastSession & '] WebSocket gửi dữ liệu thành công' & @CRLF)
		EndIf
	EndFunc

	Func _WinHttpWebSocketRead2($hWebSocket, $iBufferLen = Default)
		If $iBufferLen = Default Then $iBufferLen = $g___BytesPerLoop
		Local $tBuffer = 0, $bRecv = Binary(""), $iError, $iBytesRead = 0, $iBufferType = 0
		Do
			_HttpRequest_ConsoleWrite('> [#' & $g___LastSession & '] WebSocket đang chờ dữ liệu gửi về...')
			$tBuffer = DllStructCreate("byte[" & $iBufferLen & "]")
			$iError = _WinHttpWebSocketReceive2($hWebSocket, $tBuffer, $iBytesRead, $iBufferType)
			If @error Or $iError <> 0 Then Return SetError(1, 0 * ConsoleWrite(@CRLF) + __HttpRequest_ErrNotify('_WinHttpWebSocketRead2', @CRLF & 'WebSocket không nhận được phản hồi'), '')
			$bRecv &= BinaryMid(DllStructGetData($tBuffer, 1), 1, $iBytesRead)
			$iBufferLen -= $iBytesRead
			$tBuffer = 0
			ConsoleWrite('...')
		Until $iBufferType <> 1     ;WEBSOCKET_BINARYFRAGMENT_BUFFERTYPE
		ConsoleWrite('OK' & @CRLF)
		Return $bRecv
	EndFunc

	Func _WinHttpWebSocketCompleteUpgrade2($hRequest, $pContext = 0)
		Local $aCall = DllCall($dll_WinHttp, "handle", "WinHttpWebSocketCompleteUpgrade", "handle", $hRequest, "dword_ptr", $pContext)
		If @error Then Return SetError(@error, @extended, -1)
		Return $aCall[0]
	EndFunc

	Func _WinHttpWebSocketSend2($hWebSocket, $vData, $iBufferType = 0)     ;$iBufferType = WEBSOCKET_BINARYMESSAGE_BUFFERTYPE
		Local $tBuffer = 0, $iBufferLen = 0
		If Not IsBinary($vData) Then $vData = StringToBinary($vData, 4)
		$iBufferLen = BinaryLen($vData)
		If $iBufferLen > 0 Then
			$tBuffer = DllStructCreate("byte[" & $iBufferLen & "]")
			DllStructSetData($tBuffer, 1, $vData)
		EndIf
		Local $aCall = DllCall($dll_WinHttp, 'dword', "WinHttpWebSocketSend", "handle", $hWebSocket, "int", $iBufferType, "ptr", DllStructGetPtr($tBuffer), 'dword', $iBufferLen)
		If @error Then Return SetError(@error, @extended, -1)
		Return $aCall[0]
	EndFunc

	Func _WinHttpWebSocketReceive2($hWebSocket, $tBuffer, ByRef $iBytesRead, ByRef $iBufferType)
		Local $aCall = DllCall($dll_WinHttp, "handle", "WinHttpWebSocketReceive", "handle", $hWebSocket, "ptr", DllStructGetPtr($tBuffer), 'dword', DllStructGetSize($tBuffer), "dword*", $iBytesRead, "int*", $iBufferType)
		If @error Then Return SetError(@error, @extended, -1)
		$iBytesRead = $aCall[4]
		$iBufferType = $aCall[5]
		Return $aCall[0]
	EndFunc

	Func _WinHttpWebSocketClose2($hWebSocket, $iStatus = Default, $tReason = 0)
		If $iStatus = Default Then $iStatus = 1000     ;WEBSOCKER_SUCCESS_CLOSESTATUS
		Local $aCall = DllCall($dll_WinHttp, "handle", "WinHttpWebSocketClose", "handle", $hWebSocket, "ushort", $iStatus, "ptr", DllStructGetPtr($tReason), 'dword', DllStructGetSize($tReason))
		;If @error Then Return SetError(@error, @extended, 0)
		;Return $aCall[0]
	EndFunc

	Func _WinHttpWebSocketQueryCloseStatus2($hWebSocket, ByRef $iStatus, ByRef $iReasonLengthConsumed, $tCloseReasonBuffer = 0)
		Local $aCall = DllCall($dll_WinHttp, "handle", "WinHttpWebSocketQueryCloseStatus", "handle", $hWebSocket, "ushort*", $iStatus, "ptr", DllStructGetPtr($tCloseReasonBuffer), 'dword', DllStructGetSize($tCloseReasonBuffer), "DWORD*", $iReasonLengthConsumed)
		If @error Then Return SetError(@error, @extended, -1)
		$iStatus = $aCall[2]
		$iReasonLengthConsumed = $aCall[5]
		Return $aCall[0]
	EndFunc
#EndRegion



#Region <Set Binary Image To Ctrl + Simple Captcha GUI>
	Func _Image_GetDimension($sBinaryData_Or_FilePath, $Release_hBitmap = True, $isFilePath = False)
		_GDIPlus_Startup()
		If $isFilePath Or FileExists($sBinaryData_Or_FilePath) Then
			Local $___hBitmap = _GDIPlus_BitmapCreateFromFile($sBinaryData_Or_FilePath)
		Else
			Local $___hBitmap = _GDIPlus_BitmapCreateFromMemory(Binary($sBinaryData_Or_FilePath))
		EndIf
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_Image_GetDimension', 'Tạo Bitmap thất bại'))
		Local $___w = _GDIPlus_ImageGetWidth($___hBitmap)
		Local $___h = _GDIPlus_ImageGetHeight($___hBitmap)
		If $Release_hBitmap Then
			_GDIPlus_BitmapDispose($___hBitmap)
			_GDIPlus_Shutdown()
			Local $aRet = [$___w, $___h]
		Else
			Local $aRet = [$___hBitmap, $___w, $___h]
		EndIf
		Return $aRet
	EndFunc

	Func _Image_SetGUI($sBinaryData_Or_FilePath_Or_URL_Or_arrayHBitmap, $idCtrl_Or_hWnd, $width_Image = Default, $height_Image = Default)
		_GDIPlus_Startup()
		If Not IsHWnd($idCtrl_Or_hWnd) Then
			$idCtrl_Or_hWnd = GUICtrlGetHandle($idCtrl_Or_hWnd)
			If @error Or $idCtrl_Or_hWnd = 0 Then Return SetError(1, __HttpRequest_ErrNotify('_Image_SetGUI', 'Không tìm thấy Handle của Control hoặc Cửa sổ đã gọi'))
		EndIf
		If BitAND(WinGetState($idCtrl_Or_hWnd), 2) = 0 Then Return SetError(2, __HttpRequest_ErrNotify('_Image_SetGUI', 'Hàm này phải đặt bên dưới hàm GUISetState(@SW_SHOW)'), '')
		If UBound($sBinaryData_Or_FilePath_Or_URL_Or_arrayHBitmap) <> 3 Then
			If StringRegExp($sBinaryData_Or_FilePath_Or_URL_Or_arrayHBitmap, '(?i)^https?://') Then
				$sBinaryData_Or_FilePath_Or_URL_Or_arrayHBitmap = _HttpRequest(3, $sBinaryData_Or_FilePath_Or_URL_Or_arrayHBitmap)
				If @error Then Return SetError(3, __HttpRequest_ErrNotify('_Image_SetGUI', 'Lấy dữ liệu ảnh từ URL thất bại'))
			EndIf
			Local $aHBitmap = _Image_GetDimension($sBinaryData_Or_FilePath_Or_URL_Or_arrayHBitmap, False, FileExists($sBinaryData_Or_FilePath_Or_URL_Or_arrayHBitmap))
			If @error Then Return SetError(4, __HttpRequest_ErrNotify('_Image_SetGUI', 'Tạo dữ liệu Bitmap thất bại'))
		Else
			Local $aHBitmap = $sBinaryData_Or_FilePath_Or_URL_Or_arrayHBitmap
		EndIf
		If $width_Image = Default Or $width_Image = 0 Then $width_Image = $aHBitmap[1]
		If $height_Image = Default Or $height_Image = 0 Then $height_Image = $aHBitmap[2]
		Local $___hGraphics = _GDIPlus_GraphicsCreateFromHWND($idCtrl_Or_hWnd)
		_GDIPlus_GraphicsDrawImageRectRect($___hGraphics, $aHBitmap[0], 0, 0, $aHBitmap[1], $aHBitmap[2], 0, 0, $width_Image, $height_Image)
		_GDIPlus_BitmapDispose($aHBitmap[0])
		_GDIPlus_GraphicsDispose($___hGraphics)
		_GDIPlus_Shutdown()
		Local $aRet = [$aHBitmap[1], $aHBitmap[2]]
		Return $aRet
	EndFunc

	Func _Image_SetSimpleCaptchaGUI($BinaryCaptcha_Or_FilePath_Or_URL, $___x = -1, $___y = -1, $___hParent = Default)
		If StringRegExp($BinaryCaptcha_Or_FilePath_Or_URL, '(?i)^https?://') Or (StringRegExp($BinaryCaptcha_Or_FilePath_Or_URL, '^/') And Not FileExists($BinaryCaptcha_Or_FilePath_Or_URL) And $g___sBaseURL[$g___LastSession]) Then
			$BinaryCaptcha_Or_FilePath_Or_URL = _HttpRequest(3, $BinaryCaptcha_Or_FilePath_Or_URL)
			If @error Then Return SetError(1, __HttpRequest_ErrNotify('_Image_SetSimpleCaptchaGUI', 'Lấy dữ liệu ảnh từ URL thất bại'), '')
		EndIf
		Local $aHBitmap = _Image_GetDimension($BinaryCaptcha_Or_FilePath_Or_URL, False)
		If @error Then Return SetError(2, __HttpRequest_ErrNotify('_Image_SetSimpleCaptchaGUI', 'Tạo dữ liệu Bitmap thất bại'), '')
		If $___hParent = Default Then $___hParent = 0
		Local $___w = $aHBitmap[1]
		Local $___h = $aHBitmap[2]
		Local $width_Image = Default
		Local $height_Image = Default
		If $___w < 50 Then
			$___w *= 2
			$___h *= 2
			$width_Image = $___w
			$height_Image = $___h
		EndIf
		Local $___hGUI_Captcha = GUICreate("Captcha Display", $___w + 4, $___h + 25, $___x, $___y, 0x80800000, 0x8 + IsHWnd($___hParent) * 0x40, $___hParent)
		Local $PicCtrl = GUICtrlCreateLabel('', 2, 2, $___w, $___h, 0x800000, 0x100000)
		Local $InputCtrl = GUICtrlCreateInput('', 2, $___h + 3, $___w - 30, 20)
		Local $OKCtrl = GUICtrlCreateButton('OK', $___w - 27, $___h + 3, 30, 20, 0x1)
		GUISetState(@SW_SHOW, $___hGUI_Captcha)
		_Image_SetGUI($aHBitmap, $PicCtrl, $width_Image, $height_Image)
		If @error Then Return SetError(3, __HttpRequest_ErrNotify('_Image_SetSimpleCaptchaGUI', 'Set dữ liệu ảnh lên GUI thất bại'), '')
		Local $CaptchaRs = '', $vErr = 0
		While Sleep(30)
			Switch GUIGetMsg()
				Case $OKCtrl
					$CaptchaRs = GUICtrlRead($InputCtrl)
					ExitLoop
				Case -3
					$vErr = 1
					ExitLoop
			EndSwitch
		WEnd
		GUIDelete($___hGUI_Captcha)
		Return SetError($vErr, '', $CaptchaRs)
	EndFunc
	
	Func _Image_ResizeInMemory($inBinaryImage, $vScale = 2, $vBorder = 0, $iARGB_BackgroundColor = 0xFFFFFFFF, $vSaveExt = 'png')
		_GDIPlus_Startup()
		Local $hBmp_Foreground = _GDIPlus_BitmapCreateFromMemory($inBinaryImage)     ;load a transparent png image
		Local $iWidth = _GDIPlus_ImageGetWidth($hBmp_Foreground)
		Local $iHeight = _GDIPlus_ImageGetHeight($hBmp_Foreground)
		Local $hBmp_Background = _GDIPlus_BitmapCreateFromScan0($iWidth * $vScale + $vBorder * 2, $iHeight * $vScale + $vBorder * 2, $GDIP_PXF32ARGB)
		Local $hContext_Background = _GDIPlus_ImageGetGraphicsContext($hBmp_Background)     ;create a context to the bitmap handle to do some GDI+ operations
		_GDIPlus_GraphicsClear($hContext_Background, $iARGB_BackgroundColor)     ;clear empty bitmap with new color
		Local $hGfxContext = _GDIPlus_ImageGetGraphicsContext($hBmp_Background)     ;get graphic context
		_GDIPlus_GraphicsDrawImageRect($hGfxContext, $hBmp_Foreground, $vBorder, $vBorder, $iWidth * $vScale, $iHeight * $vScale)
		;--------------------------------------------------------------------------------------------------------------------------------------
		Local $sCLSID = _GDIPlus_EncodersGetCLSID($vSaveExt)
		Local $tEncoderStruct = _WinAPI_GUIDFromString($sCLSID)
		Local $tParams = _GDIPlus_ParamInit(1)
		Local $tData = DllStructCreate("int Quality")
		$tData.Quality = 100
		_GDIPlus_ParamAdd($tParams, $GDIP_EPGQUALITY, 1, $GDIP_EPTLONG, DllStructGetPtr($tData))
		Local $hStream = _WinAPI_CreateStreamOnHGlobal()
		_GDIPlus_ImageSaveToStream($hBmp_Background, $hStream, DllStructGetPtr($tEncoderStruct), $tParams)
		Local $hMemory = _WinAPI_GetHGlobalFromStream($hStream)
		Local $iMemSize = DllCall($dll_Kernel32, "ulong_ptr", "GlobalSize", "handle", $hMemory)
		Local $pMem = DllCall($dll_Kernel32, "ptr", "GlobalLock", "handle", $hMemory)
		Local $tData = DllStructCreate("byte[" & $iMemSize[0] & "]", $pMem[0])
		Local $outBinaryImage = DllStructGetData($tData, 1)
		_WinAPI_ReleaseStream($hStream)
		DllCall($dll_Kernel32, "ptr", "GlobalFree", "handle", $hMemory)
		;--------------------------------------------------------------------------------------------------------------------------------------
		_GDIPlus_GraphicsDispose($hGfxContext)
		_GDIPlus_GraphicsDispose($hContext_Background)
		_GDIPlus_BitmapDispose($hBmp_Background)
		_GDIPlus_BitmapDispose($hBmp_Foreground)
		_GDIPlus_Shutdown()
		Return $outBinaryImage
	EndFunc
#EndRegion



#Region IE External
	Func __IE_Init_GoogleBox($sUser, $sPassword, $sURL = Default, $vFuncCallback = '', $vDebug = False, $vTimeOut = Default)
		;	Local Const $mUserAgent = 'User-Agent: Mozilla/5.0 (Linux; U; Android 4.4.2; en-us; SCH-I535 Build/KOT49H) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30'
		$sUser = StringRegExpReplace($sUser, '(?i)@gmail.com[\.\w]*?$', '', 1)
		If $sURL = Default Then $sURL = ''
		;------------------------------------------------------------------------------------------------------
		Local $sHTML = _HttpRequest(2, 'https://accounts.google.com/ServiceLogin?hl=en&passive=true&continue=' & _URIEncode($sURL), '', '', '', 'User-Agent: ' & $g___defUserAgent)
		If @error Or $sHTML = '' Then Return SetError(-1, __HttpRequest_ErrNotify('_GoogleBox', 'Request đến trang đăng nhập thất bại'), '')
		$sHTML = StringRegExpReplace($sHTML, '(?i)(<input.*?\h+?id="Email".*?\h+?value=")(")', '$1' & $sUser & '$2', 1)
		$sHTML = StringReplace($sHTML, '<body', '<body onLoad="document.getElementById(''next'').click();"', 1, 1)
		;------------------------------------------------------------------------------------------------------
		Local $oIE = ObjCreate("Shell.Explorer.2")
		If Not IsObj($oIE) Then Return SetError(-2, __HttpRequest_ErrNotify('_GoogleBox', 'Không thể tạo IE Object'), '')
		;------------------------------------------------------------------------------------------------------
		If $vTimeOut = Default Then $vTimeOut = 20000
		If $vTimeOut < 10000 Then $vTimeOut = 10000
		Local $vReturn = '', $vError = 0, $_oid_Pass, $_old_Locate
		;------------------------------------------------------------------------------------------------------
		Local $GUI_EmbededGG = GUICreate("Google Box", 800, 600)
		GUICtrlCreateObj($oIE, 0, 0, 800, 600)
		If $vDebug Then GUISetState()
		;------------------------------------------------------------------------------------------------------
		With $oIE
			.navigate('about:blank')
			Local $sTimer = TimerInit()
			While .busy()
				If TimerDiff($sTimer) > $vTimeOut Then Return SetError(GUIDelete($GUI_EmbededGG) * -3, __HttpRequest_ErrNotify('_GoogleBox', 'TimeOut #1'), '')
				Sleep(40)
			WEnd
			;------------------------------------------------------------------------------------------------------
			.document.write($sHTML)
			.document.close()
			;------------------------------------------------------------------------------------------------------
			_HttpRequest_ConsoleWrite('> [Google Login] Đang cài đặt Tài khoản ...')
			For $i = 1 To 2
				$sTimer = TimerInit()
				Do
					If TimerDiff($sTimer) > $vTimeOut Then Return SetError(GUIDelete($GUI_EmbededGG) * -4, 0 * ConsoleWrite(@CRLF) + __HttpRequest_ErrNotify('_GoogleBox', 'TimeOut #2'), '')
					$_oid_Pass = .document.getElementById('Passwd')
					Sleep(40)
					If $i = 1 Then ConsoleWrite('..')
				Until IsObj($_oid_Pass)
				$_oid_Pass.value = $sPassword
				$_old_Locate = .locationName()
				If $i = 1 Then
					ConsoleWrite(' (' & Int(TimerDiff($sTimer)) & 'ms)' & @CRLF)
					.document.getElementById('signIn').click()
				EndIf
				;------------------------------------------------------------------------------------------------------
				_HttpRequest_ConsoleWrite('> [Google Login] ' & ($i = 1 ? 'Đang chuyển hướng tới địa chỉ đích ...' : 'Đang chờ giải Captcha'))
				$sTimer = TimerInit()
				Do
					If TimerDiff($sTimer) > $vTimeOut * $i Then
						ConsoleWrite(@CRLF)
						Return SetError(GUIDelete($GUI_EmbededGG) * -5, 0 * ConsoleWrite(@CRLF) + __HttpRequest_ErrNotify('_GoogleBox', 'TimeOut #3'), '')
					EndIf
					Sleep(40)
					ConsoleWrite('..')
				Until .locationName() <> $_old_Locate
				ConsoleWrite(' (' & Int(TimerDiff($sTimer)) & 'ms)' & @CRLF & @CRLF)
				;------------------------------------------------------------------------------------------------------
				If Not StringRegExp(.document.body.innerHtml, '(?i)<div class="?captcha-box"?>') Then ExitLoop
				_HttpRequest_ConsoleWrite('> [Google Login] Phát hiện Captcha' & @CRLF)
				GUISetState()
			Next
			;--------------------------------------------------------------
			If $vFuncCallback Then
				Local $aFuncCallback = StringSplit($vFuncCallback, '|')
				Local $sFuncCallbackName = $aFuncCallback[1]
				$aFuncCallback[0] = 'CallArgArray'
				$aFuncCallback[1] = $oIE
				$vReturn = Call($sFuncCallbackName, $aFuncCallback)
				$vError = @error
			EndIf
		EndWith
		;------------------------------------------------------------------------------------------------------
		If $vDebug Then
			While GUIGetMsg() <> -3
				Sleep(35)
			WEnd
		EndIf
		Return SetError($vError * GUIDelete($GUI_EmbededGG), '', $vReturn)
	EndFunc

	Func __IE_Init_RecaptchaBox($sURL, $vAdvancedMode, $hGUI, $___GUI_Offset, $Custom_RegExp_GetDataSiteKey, $vTimeOut)
		Local $oIE = ObjCreate("Shell.Explorer.2")
		If Not IsObj($oIE) Then Return SetError(1, __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'Không thể tạo IE Object'), '')
		Local $sReCaptchaResponse = '', $iError = 0, $sDataSiteKey = '', $isInvisible = 0
		;------------------------------------------------------------------------------------------------------
		GUICtrlSetDefBkColor(0x222222, $hGUI)
		GUICtrlSetDefColor(0xFFFFFF, $hGUI)
		GUISetFont(10, 600)
		GUICtrlCreateLabel('ReCaptcha Box', 2, 2, 400 - 22, 22, 0x201, 0x100000)
		Local $__idCloseButton = GUICtrlCreateLabel('X', 380, 2, 22, 22, 0x201)
		GUICtrlSetBkColor(-1, 0xFF0011)
		;------------------------------------------------------------------------------------------------------
		Local $__idGGLoginButton = GUICtrlCreateLabel('Google Login', 2, 606, 100, 22, 0x201)
		GUICtrlSetBkColor(-1, 0x0099FF)
		Local $__idAudioButton = GUICtrlCreateLabel('Audio', 104, 606, 49, 22, 0x201)
		GUICtrlSetBkColor(-1, 0x0099FF)
		Local $__idRefreshButton = GUICtrlCreateLabel('Refresh', 343, 606, 59, 22, 0x201)
		GUICtrlSetBkColor(-1, 0x0099FF)
		;------------------------------------------------------------------------------------------------------
		GUICtrlCreateObj($oIE, 2, 25, 400, 580)
		;------------------------------------------------------------------------------------------------------
		With $oIE
			.navigate($sURL)
			TrayTip('ReCaptcha', 'Đang tải thông tin Recaptcha...', 0)
			_HttpRequest_ConsoleWrite('> [reCAPTCHA] Đang tải trang ...')
			Local $sTimer = TimerInit()
			While .busy()
				If TimerDiff($sTimer) > $vTimeOut Then Return SetError(2, 0 * ConsoleWrite(@CRLF) + __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'TimeOut #1'), '')
				Sleep(100)
				ConsoleWrite('..')
			WEnd
			ConsoleWrite(' (' & Int(TimerDiff($sTimer)) & 'ms)' & @CRLF)
			;------------------------------------------------------------------------------------------------------
			$sTimer = TimerInit()
			;------------------------------------------------
			Local $sPageTitle = .document.title
			Local $sourceHtml = .document.body.innerHTML
			;------------------------------------------------
			If $Custom_RegExp_GetDataSiteKey Then
				If StringRegExp($Custom_RegExp_GetDataSiteKey, '^[\w\-]+$') Then
					$sDataSiteKey = $Custom_RegExp_GetDataSiteKey
				Else
					$sDataSiteKey = StringRegExp($Custom_RegExp_GetDataSiteKey, '(?i)["'']?siteKey[''"]?\s*?:\s*?[''"](.*?)[''"]', 1)
					If Not @error And $sDataSiteKey[0] Then
						$sDataSiteKey = $sDataSiteKey[0]
						$isInvisible = (StringInStr($Custom_RegExp_GetDataSiteKey, 'invisible', 0, 1) > 0)
					Else
						$sDataSiteKey = ''
					EndIf
				EndIf
			EndIf
			;------------------------------------------------
			If $sDataSiteKey == '' Then
				Local $oiFrames = .document.GetElementsByTagName("iframe")
				If @error Then
					$iError = 1
				Else
					For $oiFrame In $oiFrames
						$sDataSiteKey = StringRegExp($oiFrame.src, '(?i)^https://www.google.com/recaptcha/api2/.*?\&?k=([^\&]+)', 1)
						If Not @error And $sDataSiteKey[0] Then
							$sDataSiteKey = $sDataSiteKey[0]
							$isInvisible = (StringInStr($oiFrame.src, 'size=invisible', 0, 1) > 0)
							ExitLoop
						Else
							$sDataSiteKey = ''
						EndIf
					Next
				EndIf
				If $iError = 1 Or $sDataSiteKey == '' Then
					If $sourceHtml = '' Then Return SetError(3, __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'Đọc html thất bại'), '')
					If $Custom_RegExp_GetDataSiteKey And $Custom_RegExp_GetDataSiteKey <> Default Then
						Local $sDataSiteKey = StringRegExp($sourceHtml, $Custom_RegExp_GetDataSiteKey, 1)
						If @error Then Return SetError(4, __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'Không thể lấy data-sitekey #1'), '')
					Else
						Local $sDataSiteKey = StringRegExp($sourceHtml, '(?im)data-sitekey\h*?=\h*?["'']([\w\-]{20,})["'']', 1)
						If @error Then $sDataSiteKey = StringRegExp($sourceHtml, '(?i)(?:\?|&amp;|&|;)k=([\w\-]{20,})(?:"|&amp;|&|;|''|$)', 1)
						If @error Then $sDataSiteKey = StringRegExp($sourceHtml, '(?i)reCAPTCHA[^=]+=\h*?[''"]([\w\-]{20,})[''"]', 1)
						If @error Then $sDataSiteKey = StringRegExp($sourceHtml, '(?i)["'']reCAPTCHA_?site_?key["'']\h*?:\h*?["'']([\w\-]{20,})["'']', 1)
						If @error Then Return SetError(5, __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'Không thể lấy data-sitekey #2 (Có thể sitekey nằm trong code js hoặc trang không chứa reCAPTCHA)'), '')
					EndIf
					$sDataSiteKey = $sDataSiteKey[0]
					$isInvisible = (StringRegExp($sourceHtml, '(?i)data-sitekey="[^"]+" .*?data-size="invisible"|data-size="invisible" .*?data-sitekey="[^"]+"') > 0)
				EndIf
			EndIf
			;------------------------------------------------------------------------------------------------------
			ConsoleWrite('> [reCAPTCHA] Data-SiteKey : ' & $sDataSiteKey & @CRLF)
			;------------------------------------------------------------------------------------------------------
			Local $hIE = ControlGetHandle($hGUI, '', '[Classnn:Internet Explorer_Server1]')
			ConsoleWrite('> [reCAPTCHA] Hwnd IE : ' & $hIE & @CRLF)
			;-----------------------------------------------------
			Local $sHTML = _
					'<!DOCTYPE html>' & _
					'<html>' & _
					'<head>' & _
					'	<title>' & ($sPageTitle ? $sPageTitle : 'Google Recpatcha') & '</title>' & @CRLF & _
					'	<base href="' & $sURL & '" />' & @CRLF & _
					'	<meta http-equiv="X-UA-Compatible" content="IE=Edge,chrome=1" />' & @CRLF & _
					'	<script src="https://www.google.com/recaptcha/api.js?hl=vi&onload=onloadRecaptchaCallback&render=explicit" async defer></script>' & @CRLF & _
					'</head>' & @CRLF & _
					'<body bgcolor="#222222">#body#</body>' & @CRLF & _
					'</html>'
			If $isInvisible Then
				Local $sBody = _
						'<script src="https://www.google.com/recaptcha/api.js?hl=vi&onload=onloadCallback" async defer></script>' & @CRLF & _
						'<script>var onloadCallback = function(){grecaptcha.execute()}</script>' & @CRLF & _
						'<div style="padding: 50% 0" align="center" class="g-recaptcha" ' & ($isInvisible ? 'data-size="invisible"' : '') & ' data-theme="dark" data-sitekey="' & $sDataSiteKey & '"></div>'
			Else
				Local $sBody = _
						'<script src="https://www.google.com/recaptcha/api.js?hl=vi&onload=onloadCallback&render=explicit" async defer></script>' & @CRLF & _
						'<script>var onloadCallback=function(){grecaptcha.render("gcaptcha",{sitekey:"' & $sDataSiteKey & '", theme:"dark", callback:function(t){$("#link-view .btn-captcha").removeAttr("disabled")}});}</script>' & @CRLF & _
						'<div id="gcaptcha" style="padding: 50% 0" align="center"></div>'
			EndIf
			.document.write(StringReplace($sHTML, '#body#', @CRLF & $sBody & @CRLF, 1, 1))
			.document.close()
			_HttpRequest_ConsoleWrite('> [reCAPTCHA] Đang khởi tạo ReCaptcha ...')
			While .busy()
				If TimerDiff($sTimer) > $vTimeOut Then Return SetError(6, 0 * ConsoleWrite(@CRLF) + __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'TimeOut #2'), '')
				Sleep(100)
				ConsoleWrite('..')
			WEnd
			ConsoleWrite(' (' & Int(TimerDiff($sTimer)) & 'ms)' & @CRLF)
			;------------------------------------------------------------------------------------------------------
			$sTimer = TimerInit()
			Local $oReCaptchaResponse
			Do
				If TimerDiff($sTimer) > $vTimeOut Then Return SetError(7 + 0 * TrayTip('', '', 1), __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'TimeOut #3'), '')
				Sleep(Random(500, 1500, 1))
				$oReCaptchaResponse = .document.getElementById("g-recaptcha-response")
			Until IsObj($oReCaptchaResponse)
			;------------------------------------------------------------------------------------------------------
			If $isInvisible And $oReCaptchaResponse.value Then
				$sReCaptchaResponse = $oReCaptchaResponse.value
				GUISetState(@SW_HIDE, $hGUI)
			Else
				GUISetState(@SW_SHOW, $hGUI)
				TrayTip('', '', 1)
				;------------------------------------------------------------------------------------------------------
				If Not $isInvisible Then
					If $hIE Then
						__IE_MouseClick($hIE, 80, 260 - 25)
					Else
						Local $aPosMouse = MouseGetPos()
						MouseClick('left', 80, 260, 1, 0)
						MouseMove($aPosMouse[0], $aPosMouse[1], 0)
						Sleep(Random(1000, 2000, 1))
					EndIf
				EndIf
				;------------------------------------------------------------------------------------------------------
				_GDIPlus_Startup()
				Local $vGDI_Startup_Error = @error
				Local $___aMouseInfo, $___aMouseInfo_Old, $___aPosCurMem, $vClickDrag = False, $iTimerClickDrag
				If Not $dll_Gdi32 Then
					$dll_Gdi32 = DllOpen('gdi32.dll')
					If @error Then $vGDI_Startup_Error = 1
				EndIf
				;------------------------------------------------------------------------------------------------------
				Do
					Sleep(10)
					Switch GUIGetMsg()
						Case $__idGGLoginButton
							GUICtrlSetData($__idGGLoginButton, 'Hoàn tất')
							GUICtrlSetBkColor($__idGGLoginButton, 0xFF0011)
							$sTimer = TimerInit()
							Local $lSuccess = 1
							_HttpRequest_ConsoleWrite('> [reCAPTCHA] Đang chuyển trang đăng nhập Google ...')
							.navigate('https://accounts.google.com/ServiceLogin?hl=en&passive=true&continue=')
							While .busy()
								If TimerDiff($sTimer) > $vTimeOut Then
									$lSuccess = 0
									GUICtrlSetData($__idGGLoginButton, 'Google Login')
									GUICtrlSetBkColor($__idGGLoginButton, 0x0099FF)
									ExitLoop (1 + 0 * ConsoleWrite(@CRLF) * __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'Không thể truy cập trang đăng nhập Google'))
								EndIf
								Sleep(100)
								ConsoleWrite('..')
							WEnd
							If $lSuccess Then
								While Sleep(20)
									Switch GUIGetMsg()
										Case $__idCloseButton
											Return SetError(8, __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'Đã huỷ việc giải Captcha'), '')
										Case $__idGGLoginButton
											ExitLoop
									EndSwitch
								WEnd
							EndIf
							GUICtrlSetData($__idGGLoginButton, 'Google Login')
							GUICtrlSetBkColor($__idGGLoginButton, 0x0099FF)
							.document.write(StringReplace($sHTML, '#body#', @CRLF & $sBody & @CRLF, 1, 1))
							.document.close()
							$sTimer = TimerInit()
							Do
								If TimerDiff($sTimer) > $vTimeOut Then Return SetError(9 + 0 * TrayTip('', '', 1), __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'TimeOut #4'), '')
								Sleep(Random(500, 1500, 1))
								$oReCaptchaResponse = .document.getElementById("g-recaptcha-response")
							Until IsObj($oReCaptchaResponse)
							GUICtrlSetBkColor($__idRefreshButton, 0x0099FF)
							__IE_MouseClick($hIE, 80, 260 - 25)
							
						Case $__idCloseButton
							Return SetError(6, __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'Đã huỷ việc giải Captcha'), '')

						Case $__idAudioButton
							GUICtrlSetBkColor($__idAudioButton, 0xFF0011)
							Local $aCacheIE = _WinINet_CacheEntryInfoFind()
							If @error Then ContinueLoop MsgBox(4096 + 16, 'Lỗi', 'Không thể kết nối IE Cache') * GUICtrlSetBkColor($__idAudioButton, 0x0099FF)
							For $i = 0 To @extended - 1
								If StringInStr(($aCacheIE[$i])[0], 'mms://www.google.com:443/recaptcha/api2/payload') Then ExitLoop
							Next
							If $i = UBound($aCacheIE) Then ContinueLoop MsgBox(4096 + 16, 'Lỗi', 'Không tìm thấy Recaptcha Audio trong IE Cache') * GUICtrlSetBkColor($__idAudioButton, 0x0099FF)
							;--------------------------------------------------------------------------
							Local $sText = _HttpRequest_Speech2Text(StringReplace(($aCacheIE[$i])[0], 'mms://www.google.com:443', 'https://www.google.com', 1, 1))
							If Not @error And $sText Then
								Local $hDC = _WinAPI_GetWindowDC($hGUI)
								Local $iTAB = Int(__IE_MemoryReadPixel(86, 126, $hDC) <> '0xFFFFFF')
								_WinAPI_ReleaseDC($hGUI, $hDC)
								ClipPut($sText)
								ControlSend($hGUI, '', '', '{TAB ' & (1 + $iTAB) & '}')
								Local $aASCII = StringToASCIIArray($sText)
								For $i = 0 To UBound($aASCII) - 1
									ControlSend($hGUI, '', '', '{ASC ' & $aASCII[$i] & '}')
									Sleep(Random(25, 75, 1))
								Next
								Sleep(100)
								ControlSend($hGUI, '', '', '{TAB 5}')
								ControlSend($hGUI, '', '', '{ENTER}')
							Else
								MsgBox(4096, 'Giải Audio thất bại', 'Vui lòng bấm nút Refesh và tải về Audio mới')
							EndIf
							GUICtrlSetBkColor($__idAudioButton, 0x0099FF)
							For $i = 0 To UBound($aCacheIE) - 1
								If StringInStr(($aCacheIE[$i])[0], 'mms://www.google.com:443/recaptcha/api2/payload') Then _WinINet_CacheEntryInfoDelete(($aCacheIE[$i])[1])
							Next
							
						Case $__idRefreshButton
							GUICtrlSetBkColor($__idRefreshButton, 0xFF0011)
							.document.execCommand("Refresh")
							$sTimer = TimerInit()
							Do
								If TimerDiff($sTimer) > $vTimeOut Then Return SetError(10 + 0 * TrayTip('', '', 1), __HttpRequest_ErrNotify('__IE_Init_RecaptchaBox', 'TimeOut #5'), '')
								Sleep(Random(500, 1500, 1))
								$oReCaptchaResponse = .document.getElementById("g-recaptcha-response")
							Until IsObj($oReCaptchaResponse)
							GUICtrlSetBkColor($__idRefreshButton, 0x0099FF)
							__IE_MouseClick($hIE, 80, 260 - 25)
							
						Case -7, -9         ;$GUI_EVENT_PRIMARYDOWN
							$___aMouseInfo_Old = GUIGetCursorInfo($hGUI)
							If @error Then ContinueLoop
							$vClickDrag = True
							$iTimerClickDrag = TimerInit()
							While __IE_IsMousePressed(1)         ;Or __IE_IsMousePressed(2)
								If TimerDiff($iTimerClickDrag) > 120 Then
									$iTimerClickDrag = TimerInit()
									ContinueCase
								EndIf
							WEnd

						Case -11         ; $GUI_EVENT_MOUSEMOVE
							If $vClickDrag And $vGDI_Startup_Error = 0 Then
								$___aPosCurMem = $___aMouseInfo_Old[0] & '|' & $___aMouseInfo_Old[1]
								Select
									Case __IE_IsMousePressed(1)
										__IE_RecaptchaBox_GuiOnDrawLine($hGUI, $___GUI_Offset, 2, $___aPosCurMem, $___aMouseInfo, $___aMouseInfo_Old, 25, True)
										__IE_RecaptchaBox_CalculateRectClick($hGUI, $hIE, $___aPosCurMem)
										;	Case __IE_IsMousePressed(2)
										;		__IE_RecaptchaBox_GuiOnDrawRect($hGUI, $___GUI_Offset, 3, $___aPosCurMem, $___aMouseInfo, $___aMouseInfo_Old)
										;		__IE_RecaptchaBox_CalculateRectClick($hGUI, $hIE, $___aPosCurMem)
									Case Else
										$vClickDrag = False
								EndSelect
							EndIf
					EndSwitch
					;------------------------------------------------------------------------------------------------------
					$sReCaptchaResponse = $oReCaptchaResponse.value
				Until $sReCaptchaResponse
			EndIf
		EndWith
		;------------------------------------------------------------------------------------------------------
		If $vAdvancedMode Then
			Local $aResponse = [$sReCaptchaResponse, _IE_GetCookie($sURL), $sourceHtml, $oIE.document.body.innerHTML]
			Return $aResponse
		Else
			Return $sReCaptchaResponse
		EndIf
	EndFunc

	Func __IE_IsMousePressed($sHexKey)
		Local $aReturn = DllCall($dll_User32, "short", "GetAsyncKeyState", "int", $sHexKey)
		If @error Then Return False
		Return BitAND($aReturn[0], 0x8000) <> 0
	EndFunc

	Func __IE_MouseClick($hWnd, $x, $y, $speed = 0, $left_or_right = 'left')
		$left_or_right = ($left_or_right = 'left' ? 0x201 : 0x204)
		Local $lParam = $y * 65536 + $x
		DllCall($dll_User32, "bool", "PostMessage", "hwnd", $hWnd, "uint", $left_or_right, "wparam", $left_or_right = 0x201 ? 0x1 : 0x2, "lparam", $lParam)
		DllCall($dll_User32, "bool", "PostMessage", "hwnd", $hWnd, "uint", $left_or_right + 1, "wparam", 0x0, "lparam", $lParam)
		Sleep($speed)
	EndFunc

	Func __IE_RecaptchaBox_GuiOnDrawRect($hGUI, $___GUI_Offset, $iMouseEvent, ByRef $___aPosCurMem, $___aMouseInfo, $___aMouseInfo_Old)
		Local $aAbsPos = $___aMouseInfo_Old
		Local $posGUI = WinGetPos($hGUI)
		;-----------------------------------------------------------------------------------
		Local $___GDI_DrawGUI = GUICreate("HH Draw GUI", $posGUI[2], $posGUI[3], $___GUI_Offset, $___GUI_Offset, 0x80000000, 0x40 + 0x8, $hGUI)
		WinSetTrans($___GDI_DrawGUI, '', 80)
		Local $___GDI_Rect = GUICtrlCreateLabel('', $aAbsPos[0], $aAbsPos[1], 0, 0, 0x800000)
		GUICtrlSetBkColor(-1, 0xff0011)
		GUISetState(@SW_SHOW, $___GDI_DrawGUI)
		GUISetCursor(0, 1, $___GDI_DrawGUI)
		;-----------------------------------------------------------------------------------
		Do
			$___aMouseInfo = GUIGetCursorInfo($hGUI)
			If @error Or Not IsArray($___aMouseInfo) Then ExitLoop
			;-----------------------------------------------------
			If $___aMouseInfo[0] <> $___aMouseInfo_Old[0] Or $___aMouseInfo[1] <> $___aMouseInfo_Old[1] Then
				If $___aMouseInfo[1] > $aAbsPos[1] Then
					If $___aMouseInfo[0] > $aAbsPos[0] Then
						GUICtrlSetPos($___GDI_Rect, $aAbsPos[0], $aAbsPos[1], $___aMouseInfo[0] - $aAbsPos[0], $___aMouseInfo[1] - $aAbsPos[1])
					Else         ;-------------------------------------------
						GUICtrlSetPos($___GDI_Rect, $___aMouseInfo[0], $aAbsPos[1], $aAbsPos[0] - $___aMouseInfo[0], $___aMouseInfo[1] - $aAbsPos[1])
					EndIf
				Else         ;---------------------------------------------------------------------------------------------------------------------------------------
					If $___aMouseInfo[0] > $aAbsPos[0] Then
						GUICtrlSetPos($___GDI_Rect, $aAbsPos[0], $___aMouseInfo[1], $___aMouseInfo[0] - $aAbsPos[0], $aAbsPos[1] - $___aMouseInfo[1])
					Else         ;-------------------------------------------
						GUICtrlSetPos($___GDI_Rect, $___aMouseInfo[0], $___aMouseInfo[1], $aAbsPos[0] - $___aMouseInfo[0], $aAbsPos[1] - $___aMouseInfo[1])
					EndIf
				EndIf
				;-----------------------------------------------------------------------------------
				$___aMouseInfo_Old = $___aMouseInfo
			EndIf
		Until $___aMouseInfo[$iMouseEvent] = 0
		;-----------------------------------------------------------------------------------
		Local $x0 = $aAbsPos[0], $y0 = $aAbsPos[1], $x1 = $___aMouseInfo[0], $y1 = $___aMouseInfo[1], $wSelect = Abs($x1 - $x0), $hSelect = Abs($y1 - $y0)
		Select
			Case $x1 < $x0 And $y1 > $y0
				$x0 = $x1
			Case $x1 < $x0 And $y1 < $y0
				$x0 = $x1
				$y0 = $y1
			Case $x1 > $x0 And $y1 < $y0
				$y0 = $y1
		EndSelect
		;-----------------------------------------------------------------------------------
		Local $xPart = 4, $yPart = 4
		If Mod($wSelect, $xPart) Then $wSelect += ($xPart - Mod($wSelect, $xPart))
		If Mod($hSelect, $yPart) Then $hSelect += ($yPart - Mod($hSelect, $yPart))
		;-----------------------------------------------------------------------------------
		For $x = 0 To $wSelect Step $wSelect / $xPart
			For $y = 0 To $hSelect Step $hSelect / $yPart
				$___aPosCurMem &= '|' & ($x + $x0) & '|' & ($y + $y0)
			Next
		Next
		$___aPosCurMem &= '|' & $x1 & '|' & $y1
		;-------------------------------------------------------------------------------------------------------------------------------------------
		GUICtrlDelete($___GDI_Rect)
		GUIDelete($___GDI_DrawGUI)
	EndFunc

	Func __IE_RecaptchaBox_GuiOnDrawLine($hGUI, $___GUI_Offset, $iMouseEvent, ByRef $___aPosCurMem, $___aMouseInfo, $___aMouseInfo_Old, $iSizePen, $iEasyModeGUI = True)
		Local $posGUI = WinGetPos($hGUI)
		;------------------------------------------------------------------------------------------------------
		If $iEasyModeGUI Then
			Local $___GDI_DrawGUI = GUICreate("HH Draw GUI", $posGUI[2], $posGUI[3], $___GUI_Offset, $___GUI_Offset, 0x80000000, 0x80000 + 0x40 + 0x8, $hGUI)
			GUISetBkColor(0x123456, $___GDI_DrawGUI)
			DllCall($dll_User32, "bool", "SetLayeredWindowAttributes", "hwnd", $___GDI_DrawGUI, "INT", 0x563412, "byte", 255, "dword", 0x3)
			GUISetState(@SW_SHOW, $___GDI_DrawGUI)
		Else         ;-----------------------------------------------------------
			Local $___WinAPI_hDDC = _WinAPI_GetDC($hGUI)
			Local $___WinAPI_hCDC = _WinAPI_CreateCompatibleDC($___WinAPI_hDDC)
			Local $___GDI_hCloneGUI = _WinAPI_CreateCompatibleBitmap($___WinAPI_hDDC, $posGUI[2], $posGUI[3])
			_WinAPI_SelectObject($___WinAPI_hCDC, $___GDI_hCloneGUI)
			_WinAPI_BitBlt($___WinAPI_hCDC, 0, 0, $posGUI[2], $posGUI[3], $___WinAPI_hDDC, 0, 0, 0x00CC0020)         ;$__SCREENCAPTURECONSTANT_SRCCOPY
			_WinAPI_ReleaseDC($hGUI, $___WinAPI_hDDC)
			_WinAPI_DeleteDC($___WinAPI_hCDC)
			;----------------------------------------------------
			Local $___GDI_DrawGUI = GUICreate("HH Draw GUI", $posGUI[2], $posGUI[3], $___GUI_Offset, $___GUI_Offset, 0x80000000, 0x40 + 0x8, $hGUI)
			GUISetState(@SW_SHOW, $___GDI_DrawGUI)
			;----------------------------------------------------
			Local $___GDI_hGraphic = _GDIPlus_GraphicsCreateFromHWND($___GDI_DrawGUI)
			Local $___GDI_hBitmap = _GDIPlus_BitmapCreateFromHBITMAP($___GDI_hCloneGUI)
			_GDIPlus_GraphicsDrawImage($___GDI_hGraphic, $___GDI_hBitmap, 0, 0)
			_GDIPlus_BitmapDispose($___GDI_hBitmap)
			_WinAPI_DeleteObject($___GDI_hCloneGUI)
			_GDIPlus_GraphicsDispose($___GDI_hGraphic)
		EndIf
		GUISetCursor(0, 1, $___GDI_DrawGUI)
		;-----------------------------------------------------------------------------------------------------
		Local $___WinAPI_hWDC = _WinAPI_GetWindowDC($___GDI_DrawGUI)
		Local $___WinAPI_hPen = _WinAPI_CreatePen(0, $iSizePen, 0x1100FF)
		Local $___WinAPI_oSelect = _WinAPI_SelectObject($___WinAPI_hWDC, $___WinAPI_hPen)
		;-----------------------------------------------------------------------------------------------------
		Local $___WinAPI_hPen2 = _WinAPI_CreatePen(0, $iSizePen * 2, 0)
		Local $___WinAPI_oSelect2 = _WinAPI_SelectObject($___WinAPI_hWDC, $___WinAPI_hPen2)
		_WinAPI_DrawLine($___WinAPI_hWDC, $___aMouseInfo_Old[0], $___aMouseInfo_Old[1], $___aMouseInfo_Old[0], $___aMouseInfo_Old[1])
		_WinAPI_SelectObject($___WinAPI_hWDC, $___WinAPI_oSelect2)
		_WinAPI_DeleteObject($___WinAPI_hPen2)
		;------------------------------------------------------------------------------------------------------
		Local $VectorX, $VectorY, $a, $B
		Do
			$___aMouseInfo = GUIGetCursorInfo($___GDI_DrawGUI)
			If @error Or Not IsArray($___aMouseInfo) Then ExitLoop
			;-----------------------------------------------------
			$VectorX = $___aMouseInfo[0] - $___aMouseInfo_Old[0]
			$VectorY = $___aMouseInfo[1] - $___aMouseInfo_Old[1]
			If Abs($VectorX) > 5 Or Abs($VectorY) > 5 Then
				$a = $VectorY / $VectorX
				$B = $___aMouseInfo[1] - $___aMouseInfo[0] * $a
				If Abs($VectorY) > 50 Then
					For $k = $___aMouseInfo_Old[1] To $___aMouseInfo[1] Step 10 * ($___aMouseInfo_Old[1] > $___aMouseInfo[1] ? -1 : 1)
						If $VectorX = 0 Then
							$___aPosCurMem &= '|' & $___aMouseInfo[0] & '|' & $k
						Else
							$___aPosCurMem &= '|' & ($k - $B) / $a & '|' & $k
						EndIf
					Next
				ElseIf Abs($VectorX) > 50 Then
					For $k = $___aMouseInfo_Old[0] To $___aMouseInfo[0] Step 10 * ($___aMouseInfo_Old[0] > $___aMouseInfo[0] ? -1 : 1)
						If $VectorY = 0 Then
							$___aPosCurMem &= '|' & $k & '|' & $___aMouseInfo[1]
						Else
							$___aPosCurMem &= '|' & $k & '|' & $a * $k + $B
						EndIf
					Next
				Else
					$___aPosCurMem &= '|' & $___aMouseInfo[0] & '|' & $___aMouseInfo[1]
				EndIf
				_WinAPI_DrawLine($___WinAPI_hWDC, $___aMouseInfo[0], $___aMouseInfo[1], $___aMouseInfo_Old[0], $___aMouseInfo_Old[1])
				$___aMouseInfo_Old = $___aMouseInfo
			EndIf
		Until $___aMouseInfo[$iMouseEvent] = 0
		;-----------------------------------------------------------------------------------------------------
		_WinAPI_SelectObject($___WinAPI_hWDC, $___WinAPI_oSelect)
		_WinAPI_DeleteObject($___WinAPI_hPen)
		_WinAPI_ReleaseDC(0, $___WinAPI_hWDC)
		GUIDelete($___GDI_DrawGUI)
	EndFunc

	Func __IE_RecaptchaBox_CalculateRectClick($hGUI, $hIE, $___asPosCurMem, $iDefaultReCaptDimensions = 4, $___offsetClick = 7, $___speedClick = 30)
		Local $aCaptcha_Measure = __IE_ReCaptchaBox_Measure($hGUI)
		If @error Or Not IsArray($aCaptcha_Measure) Then
			$aCaptcha_Measure = StringSplit($iDefaultReCaptDimensions = 3 ? '17,163,118,118,4,3,3,367' : '19,163,88,88,2,4,4,363', ',', 2)
		EndIf
		;-----------------------------------------------------------------------------------------------------
		Local $___aClickCurMem[8][8], $eCoordX, $eCoordY
		Local $__X_offsetClick = $aCaptcha_Measure[0] + $aCaptcha_Measure[2] / 2 - $___offsetClick
		Local $__Y_offsetClick = $aCaptcha_Measure[1] + $aCaptcha_Measure[3] / 2 - $___offsetClick
		$___asPosCurMem = StringSplit($___asPosCurMem, '|')
		If $___asPosCurMem[0] < 2 Then Return SetError(1)
		For $i = 1 To $___asPosCurMem[0] Step 2
			$eCoordX = Floor(($___asPosCurMem[$i + 0] - $aCaptcha_Measure[0]) / $aCaptcha_Measure[2])
			$eCoordY = Floor(($___asPosCurMem[$i + 1] - $aCaptcha_Measure[1]) / $aCaptcha_Measure[3])
			If $eCoordX < 0 Or $eCoordX >= $aCaptcha_Measure[5] Or $eCoordY < 0 Or $eCoordY >= $aCaptcha_Measure[6] Or $___aClickCurMem[$eCoordX][$eCoordY] Then ContinueLoop
			If $hIE Then
				__IE_MouseClick($hIE, $__X_offsetClick + $aCaptcha_Measure[2] * $eCoordX, $__Y_offsetClick + $aCaptcha_Measure[3] * $eCoordY - 25, $___speedClick)         ;-25 là do vị trí IE Obj so với GUI
			Else
				MouseClick('left', $__X_offsetClick + $aCaptcha_Measure[2] * $eCoordX, $__Y_offsetClick + $aCaptcha_Measure[3] * $eCoordY, 1, $___speedClick)
			EndIf
			$___aClickCurMem[$eCoordX][$eCoordY] = 1
		Next
	EndFunc

	Func __IE_ReCaptchaBox_Measure($hGUI)
		Local $hDC = _WinAPI_GetWindowDC($hGUI)
		If @error Then Return SetError(1, _WinAPI_ReleaseDC($hGUI, $hDC), 0)
		Local $iW = 404, $x = 10, $y = 200, $iStep = 0
		Local $iXCaptchaPiece = 0, $iYCaptchaPiece = 0, $iWCaptchaPiece = 0, $iHCaptchaPiece = 0, $iWCaptchaPic = 0, $iNumCaptchaPieceW = 0, $iNumCaptchaPieceH = 0, $iDistCaptchaPiece = 0
		For $x = 0 To $iW Step 2
			Select
				Case $iStep = 0
					If $x > 30 Then
						Return SetError(2, 0, 0)
					ElseIf __IE_MemoryReadPixel($x, $y, $hDC) <> '0xFFFFFF' Then
						$iStep = 1
					EndIf
				Case $iStep = 1 And __IE_MemoryReadPixel($x, $y, $hDC) == '0xFFFFFF'
					$iStep = 2
				Case $iStep = 2 And __IE_MemoryReadPixel($x, $y, $hDC) <> '0xFFFFFF'
					$iStep = 3
					$iXCaptchaPiece = $x
					$x += 50
				Case $iStep = 3
					If __IE_MemoryReadPixel($x, $y, $hDC) == '0xFFFFFF' Then
						For $vertY = 180 To 220 Step 2
							If __IE_MemoryReadPixel($x, $vertY, $hDC) <> '0xFFFFFF' Then ExitLoop
						Next
						If $vertY = 222 Then
							$iWCaptchaPiece = $x - $iXCaptchaPiece
							$iStep = 4
						EndIf
					EndIf
				Case $iStep = 4
					For $y = 180 To 0 Step -2
						If __IE_MemoryReadPixel($x, $y, $hDC) == '0x4A90E2' Then
							$iYCaptchaPiece = $y + 7
							ExitLoop 2
						EndIf
					Next
			EndSelect
		Next
		_WinAPI_ReleaseDC($hGUI, $hDC)
		$iWCaptchaPic = $iW - ($iXCaptchaPiece - 1) * 2
		$iNumCaptchaPieceW = Floor($iWCaptchaPic / $iWCaptchaPiece)
		$iNumCaptchaPieceH = ($iNumCaptchaPieceW = 2 ? 4 : $iNumCaptchaPieceW)
		$iDistCaptchaPiece = Floor(($iWCaptchaPic - $iNumCaptchaPieceW * $iWCaptchaPiece) / $iNumCaptchaPieceW)
		$iHCaptchaPiece = Floor($iWCaptchaPic / $iNumCaptchaPieceH) - $iDistCaptchaPiece
		Local $aRet = [$iXCaptchaPiece, $iYCaptchaPiece, $iWCaptchaPiece, $iHCaptchaPiece, $iDistCaptchaPiece, $iNumCaptchaPieceW, $iNumCaptchaPieceH, $iWCaptchaPic]
		Return $aRet
	EndFunc

	Func __IE_MemoryReadPixel($__x, $__y, $hDC)
		Return BinaryMid(Binary(DllCall($dll_Gdi32, "int", "GetPixel", "int", $hDC, "int", $__x, "int", $__y)[0]), 1, 3)
	EndFunc

	Func _WinINet_CacheEntryInfoFind($iCacheEntryType = 0)
		If Not $dll_WinInet Then
			$dll_WinInet = DllOpen('wininet.dll')
			If @error Then Return SetError(-1)
		EndIf
		Local $sUrlSearchPattern = ($iCacheEntryType = 1 ? 'cookie:' : ($iCacheEntryType = 2 ? 'visited:' : '*.*'))
		Local $tCacheEntryInfo, $tCacheEntryInfoSize, $hUrlCacheEntry = 0, $aCall, $iFirst = 1, $aRet[0], $iCounter = 0
		Do
			$tCacheEntryInfoSize = DllStructCreate("dword")
			If $iFirst Then
				DllCall($dll_WinInet, "ptr", "FindFirstUrlCacheEntryW", 'wstr', $sUrlSearchPattern, "ptr", 0, "ptr", DllStructGetPtr($tCacheEntryInfoSize))
			Else
				DllCall($dll_WinInet, "int", "FindNextUrlCacheEntryW", "ptr", $hUrlCacheEntry, "ptr", 0, "ptr", DllStructGetPtr($tCacheEntryInfoSize))
			EndIf
			If @error Then ExitLoop
			$tCacheEntryInfo = DllStructCreate('dword StructSize; ptr SourceUrlName; ptr LocalFileName; dword CacheEntryType; dword UseCount; dword HitRate; dword Size[2]; dword LastModifiedTime[2]; dword ExpireTime[2]; dword LastAccessTime[2]; dword LastSyncTime[2]; ptr HeaderInfo; dword HeaderInfoSize; ptr FileExtension; dword ReservedExemptDelta;byte[' & (DllStructGetData($tCacheEntryInfoSize, 1) + 1) & ']')
			If $iFirst Then
				$aCall = DllCall($dll_WinInet, "ptr", "FindFirstUrlCacheEntryW", 'wstr', $sUrlSearchPattern, "ptr", DllStructGetPtr($tCacheEntryInfo), "ptr", DllStructGetPtr($tCacheEntryInfoSize))
			Else
				$aCall = DllCall($dll_WinInet, "int", "FindNextUrlCacheEntryW", "ptr", $hUrlCacheEntry, "ptr", DllStructGetPtr($tCacheEntryInfo), "ptr", DllStructGetPtr($tCacheEntryInfoSize))
			EndIf
			If @error Or Not $aCall[0] Then ExitLoop
			If $iFirst Then
				$hUrlCacheEntry = $aCall[0]
				$iFirst = 0
			EndIf
			ReDim $aRet[$iCounter + 1]
			$aRet[$iCounter] = _WinINet_CacheEntryInfoStructToArray($tCacheEntryInfo)
			$iCounter += 1
		Until 0
		DllCall($dll_WinInet, "int", "FindCloseUrlCache", "ptr", $hUrlCacheEntry)
		Return SetError(Int(Not ($iCounter > 0)), $iCounter, $aRet)
	EndFunc
	
	Func _WinINet_CacheEntryInfoDelete($sUrlName)
		If Not $dll_WinInet Then
			$dll_WinInet = DllOpen('wininet.dll')
			If @error Then Return SetError(-1)
		EndIf
		Local $avResult = DllCall($dll_WinInet, "int", "DeleteUrlCacheEntryW", 'wstr', $sUrlName)
		If @error Or $avResult[0] <> 0 Then Return SetError(1, 0, False)
		Return True
	EndFunc
	
	Func _WinINet_CacheEntryInfoStructToArray($tCacheEntryInfo)
		Local $avReturn[7] = ['SourceUrlName', 'LocalFileName', 'HeaderInfo'], $iPtr, $iStructEnd = Number(DllStructGetPtr($tCacheEntryInfo)) + DllStructGetSize($tCacheEntryInfo)
		For $i = 0 To 2
			$iPtr = DllStructGetData($tCacheEntryInfo, $avReturn[$i])
			$avReturn[$i] = DllStructGetData(DllStructCreate("wchar[" & _WinINet_StringLenFromPtr($iPtr) & "]", $iPtr), 1)
		Next
		$avReturn[3] = DllStructGetData(DllStructCreate("int64", DllStructGetPtr($tCacheEntryInfo, "Size")), 1)
		$avReturn[4] = DllStructGetData(DllStructCreate("int64", DllStructGetPtr($tCacheEntryInfo, "ExpireTime")), 1)
		$avReturn[5] = DllStructGetData(DllStructCreate("int64", DllStructGetPtr($tCacheEntryInfo, "LastSyncTime")), 1)
		$avReturn[6] = DllStructGetData($tCacheEntryInfo, "HitRate")
		Return $avReturn
	EndFunc
	
	Func _WinINet_StringLenFromPtr($pString, $bUnicode = True)
		Local $aRet = DllCall($dll_Kernel32, 'int', 'lstrlen' & ($bUnicode ? 'W' : ''), 'struct*', $pString)
		If @error Then Return SetError(1, 0, 0)
		Return $aRet[0]
	EndFunc
	;------------------------------------------------------------------------------------------------------

	; $ClearID = 1: History Only ; 2: Cookies Only ; 8: Temporary Internet Files Only ; 16: Form Data Only ; 32: Password History Only ; 255: Everything
	Func _IE_ClearMyTracks($vClearID = Default)
		If $vClearID = Default Then $vClearID = 2 + 8
		RunWait(@ComSpec & " /C " & "RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess " & $vClearID, "", @SW_HIDE)
	EndFunc

	Func _IE_CheckCompatible($vCheckMode = True)
		;https://blogs.msdn.microsoft.com/patricka/2015/01/12/controlling-webbrowser-control-compatibility/
		Local $_Reg_BROWSER_EMULATION = '\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION'
		Local $_Reg_HKCU_BROWSER_EMULATION = 'HKCU\SOFTWARE' & $_Reg_BROWSER_EMULATION
		Local $_Reg_HKLM_BROWSER_EMULATION = 'HKLM\SOFTWARE' & $_Reg_BROWSER_EMULATION
		Local $_Reg_HKLMx64_BROWSER_EMULATION = 'HKLM\SOFTWARE\WOW6432Node' & $_Reg_BROWSER_EMULATION
		Local $_IE_Mode, $_AutoItExe = StringRegExp(@AutoItExe, '(?i)\\([^\\]+.exe)$', 1)[0]
		Local $_IE_Version = StringRegExp(FileGetVersion(@ProgramFilesDir & "\Internet Explorer\iexplore.exe"), '^\d+', 1)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_IE_CheckCompatible', 'Không lấy được version của IE'), False)
		$_IE_Version = Number($_IE_Version[0])
		Switch $_IE_Version
			Case 7, 8, 9
				$_IE_Mode = $_IE_Version * 1111
				_HttpRequest_ConsoleWrite('! IE' & $_IE_Version & ' có thể không tương thích với HTML mới sau này gây ra không thể tải trang bình hường (blank page)' & @CRLF)
			Case 10, 11
				$_IE_Mode = $_IE_Version * 1000 + 1
			Case Else
				_HttpRequest_ConsoleWrite( _
						'!!! Phiên bản Internet Explorer hiện tại trên máy bạn đã quá cũ (IE' & $_IE_Version & ').' & @CRLF & _
						'!!! Điều này có thể khiến một số trang có ReCaptcha không thể hiển thị được.' & @CRLF & _
						'!!! Nếu không nhúng ReCaptcha được, máy cần cài Win7 trở lên và IE version 10 hoặc 11.' & @CRLF)
				Return SetError(2, '', False)
		EndSwitch
		If $vCheckMode Then
			If RegRead($_Reg_HKCU_BROWSER_EMULATION, $_AutoItExe) <> $_IE_Mode Then RegWrite($_Reg_HKCU_BROWSER_EMULATION, $_AutoItExe, 'REG_DWORD', $_IE_Mode)
			If RegRead($_Reg_HKLM_BROWSER_EMULATION, $_AutoItExe) <> $_IE_Mode Then RegWrite($_Reg_HKLM_BROWSER_EMULATION, $_AutoItExe, 'REG_DWORD', $_IE_Mode)
			If @AutoItX64 And RegRead($_Reg_HKLMx64_BROWSER_EMULATION, $_AutoItExe) <> $_IE_Mode Then RegWrite($_Reg_HKLMx64_BROWSER_EMULATION, $_AutoItExe, 'REG_DWORD', $_IE_Mode)
		Else
			If RegRead($_Reg_HKCU_BROWSER_EMULATION, $_AutoItExe) <> $_IE_Mode Then RegDelete($_Reg_HKCU_BROWSER_EMULATION, $_AutoItExe)
			If RegRead($_Reg_HKLM_BROWSER_EMULATION, $_AutoItExe) <> $_IE_Mode Then RegDelete($_Reg_HKLM_BROWSER_EMULATION, $_AutoItExe)
			If @AutoItX64 And RegRead($_Reg_HKLMx64_BROWSER_EMULATION, $_AutoItExe) <> $_IE_Mode Then RegDelete($_Reg_HKLMx64_BROWSER_EMULATION, $_AutoItExe)
		EndIf
		Return True
	EndFunc

	;$vFuncCallback support hàm có tối đa 4 tham số
	Func _IE_GoogleBox($sUser, $sPassword, $sURL = Default, $vFuncCallback = '', $vDebug = False, $vTimeOut = Default, $vCheckCompatible = True)
		If $vCheckCompatible Then
			_IE_CheckCompatible(True)
			If @error Then Return SetError(-1, '', '')
		EndIf
		Local $sRet = __IE_Init_GoogleBox($sUser, $sPassword, $sURL, $vFuncCallback, $vDebug, $vTimeOut)
		Local $vErr = @error
		If $vCheckCompatible Then _IE_CheckCompatible(False)
		Return SetError($vErr, '', $sRet)
	EndFunc

	Func _IE_RecaptchaBox($sURL, $vAdvancedMode = Default, $iX_GUI = Default, $iY_GUI = Default, $vTimeOut = Default, $Custom_RegExp_GetDataSiteKey = Default, $vCheckCompatible = True)
		If $vTimeOut = Default Or $vTimeOut < 30000 Then $vTimeOut = 30000
		If $vAdvancedMode = Default Then $vAdvancedMode = False
		If $iX_GUI = Default Then $iX_GUI = (@DesktopWidth - 404) / 2
		If $iY_GUI = Default Then $iY_GUI = (@DesktopHeight - 607) / 2 - 50
		;------------------------------------------------------------------------------------------------------
		If $vCheckCompatible Then
			_IE_CheckCompatible(True)
			If @error Then Return SetError(-1, '', '')
		EndIf
		;------------------------------------------------------------------------------------------------------
		Local $___oldCursorMode = [Opt('MouseCoordMode', 0), Opt('MouseClickDelay', 0), Opt('MouseClickDownDelay', 0)]
		;------------------------------------------------------------------------------------------------------
		Local $ie_GUI_EmbededCaptcha = GUICreate("Recaptcha Box", 404, 630, $iX_GUI, $iY_GUI, 0x80000000, 0x8)
		Local $ie_GUI_SampleGetOffset = GUICreate("Recaptcha Box Sample", 0, 0, 0, 0, 0x80000000, 0x8 + 0x40, $ie_GUI_EmbededCaptcha)
		Local $___GUI_Offset = WinGetPos($ie_GUI_EmbededCaptcha)[0] - WinGetPos($ie_GUI_SampleGetOffset)[0]
		GUIDelete($ie_GUI_SampleGetOffset)
		GUISetBkColor(0x222222, $ie_GUI_EmbededCaptcha)
		;------------------------------------------------------------------------------------------------------
		Local $sRet = __IE_Init_RecaptchaBox($sURL, $vAdvancedMode, $ie_GUI_EmbededCaptcha, $___GUI_Offset, $Custom_RegExp_GetDataSiteKey, $vTimeOut)
		Local $vErr = @error
		;------------------------------------------------------------------------------------------------------
		$ie_GUI_EmbededCaptcha = GUIDelete($ie_GUI_EmbededCaptcha)
		ConsoleWrite(@CRLF)
		;------------------------------------------------------------------------------------------------------
		Opt('MouseCoordMode', $___oldCursorMode[0])
		Opt('MouseClickDelay', $___oldCursorMode[1])
		Opt('MouseClickDownDelay', $___oldCursorMode[2])
		_GDIPlus_Shutdown()
		If $vCheckCompatible Then _IE_CheckCompatible(False)
		Return SetError($vErr, '', $sRet)
	EndFunc

	Func _IE_NavigateEx($oIE, $sURL, $sCookie = '', $sUserAgent = '', $sProxy = '', $sProxyBypass = '', $iIEFlags = Default, $sIEPostData = '', $iIEHeaders = '', $iTimeout = 30000)
		If Not IsObj($oIE) Then Return SetError(1, __HttpRequest_ErrNotify('_IE_NavigateEx', 'IE Object rỗng'), False)
		;--------------------------------------------
		If $sCookie Then
			_IE_SetCookie($sURL, $sCookie)
			If @error Then Return SetError(2, False)
		EndIf
		;--------------------------------------------
		If $sProxy Then
			_IE_SetProxy($sProxy, $sProxyBypass)
			If @error Then Return SetError(3, False)
		EndIf
		;--------------------------------------------
		If $sUserAgent Then
			_IE_SetUserAgent($sUserAgent)
			If @error Then Return SetError(4, False)
		EndIf
		;--------------------------------------------
		__Data2Send_CheckEncode($sIEPostData)
		$oIE.navigate2($sURL, $iIEFlags, Default, StringToBinary($sIEPostData), $iIEHeaders)
		If $iTimeout > -1 Then
			ConsoleWrite(@CRLF & '> _IE_NavigateEx' & @CRLF)
			_IE_LoadWait($oIE, $iTimeout)
		EndIf
		Return True
	EndFunc

	Func _IE_LoadWait($__oIE, $__iTimeout = 0)
		Local $__iTimerInit1 = TimerInit()
		ConsoleWrite('> _IE_WaitLoad ...')
		With $__oIE
			While .busy()
				If $__iTimeout And TimerDiff($__iTimerInit1) > $__iTimeout Then Return SetError(1, 0 * ConsoleWrite(@CRLF) + __HttpRequest_ErrNotify('_IE_LoadWait', 'LoadWait TimeOut #1'), False)
				ConsoleWrite('.')
				Sleep(50)
			WEnd
			$__iTimerInit1 = TimerDiff($__iTimerInit1)
			;--------------------------------------------------------------------------------
			Local $__iTimerInit2 = TimerInit()
			If IsObj(.document) Then
				While Not (String(.document.readyState) = "complete" Or .document.readyState = 4)
					If $__iTimeout And TimerDiff($__iTimerInit2) > $__iTimeout Then Return SetError(2, 0 * ConsoleWrite(@CRLF) + __HttpRequest_ErrNotify('_IE_LoadWait', 'LoadWait TimeOut #2'), False)
					ConsoleWrite('.')
					Sleep(50)
				WEnd
			Else
				While Not (String(.readyState) = "complete" Or .readyState = 4)
					If $__iTimeout And TimerDiff($__iTimerInit2) > $__iTimeout Then Return SetError(3, 0 * ConsoleWrite(@CRLF) + __HttpRequest_ErrNotify('_IE_LoadWait', 'LoadWait TimeOut #3'), False)
					ConsoleWrite('.')
					Sleep(50)
				WEnd
			EndIf
		EndWith
		$__iTimerInit2 = TimerDiff($__iTimerInit2)
		;--------------------------------------------------------------------------------
		ConsoleWrite(' (' & Round(($__iTimerInit1 + $__iTimerInit2) / 1000, 2) & 's)' & @CRLF)
	EndFunc

	Func _IE_CheckObjType($__oIE, $sType)
		If Not IsObj($__oIE) Then Return False
		Local $sName = String(ObjName($__oIE))
		Switch $sType
			Case "browserdom"
				If _IE_CheckObjType($__oIE, "documentcontainer") Then
					Return True
				ElseIf _IE_CheckObjType($__oIE, "document") Then
					Return True
				Else
					If _IE_CheckObjType($__oIE.document, "document") Then Return True
				EndIf
			Case "browser"
				If $sName = "IWebBrowser2" Or $sName = "IWebBrowser" Or $sName = "WebBrowser" Then Return True
			Case "window"
				If $sName = "HTMLWindow2" Then Return True
			Case "documentContainer"
				If _IE_CheckObjType($__oIE, "window") Or _IE_CheckObjType($__oIE, "browser") Then Return True
			Case "document"
				If $sName = "HTMLDocument" Then Return True
			Case "table"
				If $sName = "HTMLTable" Then Return True
			Case "form"
				If $sName = "HTMLFormElement" Then Return True
			Case "forminputelement"
				If ($sName = "HTMLInputElement") Or ($sName = "HTMLSelectElement") Or ($sName = "HTMLTextAreaElement") Then Return True
			Case "elementcollection"
				If ($sName = "HTMLElementCollection") Then Return True
			Case "formselectelement"
				If $sName = "HTMLSelectElement" Then Return True
			Case Else
				Return False
		EndSwitch
		Return False
	EndFunc

	Func _IE_GetCookie($sURL, $iBufferSize = 2048)
		If Not $dll_WinInet Then
			$dll_WinInet = DllOpen('wininet.dll')
			If @error Then Return SetError(2, __HttpRequest_ErrNotify('_IE_GetCookieEx', 'Không thể mở wininet.dll'), '')
			DllOpen('wininet.dll')
		EndIf
		Local $tSize = DllStructCreate("dword")
		DllStructSetData($tSize, 1, $iBufferSize)
		Local $tCookieData = DllStructCreate("wchar[" & $iBufferSize & "]")
		Local $avResult = DllCall($dll_WinInet, "int", "InternetGetCookieExW", 'wstr', $sURL, 'wstr', Null, "ptr", DllStructGetPtr($tCookieData), "ptr", DllStructGetPtr($tSize), "dword", 0x2000, "ptr", 0)
		If @error Then Return SetError(1, 0, "")
		If Not $avResult[0] Then Return SetError(1, DllStructGetData($tSize, 1), "")
		Return DllStructGetData($tCookieData, 1)
	EndFunc

	Func _IE_SetCookie($sURL, $iCookieData)
		;https://blogs.msdn.microsoft.com/ieinternals/2009/08/20/internet-explorer-cookie-internals-faq/
		If $iCookieData = '' Then Return SetError(1, __HttpRequest_ErrNotify('_IE_SetCookie', 'Không thể set Cookie vì tham số CookieData là rỗng'), '')
		If Not $dll_WinInet Then
			$dll_WinInet = DllOpen('wininet.dll')
			If @error Then Return SetError(2, __HttpRequest_ErrNotify('_IE_SetCookie', 'Không thể mở wininet.dll'), '')
			DllOpen('wininet.dll')
		EndIf
		Local $avResult, $cError = 0
		$iCookieData = StringSplit($iCookieData, ';')
		For $i = 1 To $iCookieData[0]
			If StringIsSpace($iCookieData[$i]) Then ContinueLoop
			If Not StringRegExp($iCookieData[$i], '^\h*?[^=]+\h*?=\h*?') Then ContinueLoop
			$avResult = DllCall($dll_WinInet, "int", "InternetSetCookieW", 'wstr', $sURL, "ptr", 0, 'wstr', $iCookieData[$i])
			If @error Then
				__HttpRequest_ErrNotify('_IE_SetCookie', 'Không thể nạp Cookie "' & $iCookieData[$i] & '" vào IE')
				$cError += 1
			EndIf
		Next
		If $cError Then Return SetError(1, '', False)
		Return True
	EndFunc

	Func _IE_SetProxy($sProxy, $sProxyBypass = "")
		Local $tBuff = DllStructCreate("dword;ptr;ptr")
		DllStructSetData($tBuff, 1, 3)
		Local $tProxy = DllStructCreate("char[" & (StringLen($sProxy) + 1) & "]")
		DllStructSetData($tProxy, 1, $sProxy)
		DllStructSetData($tBuff, 2, DllStructGetPtr($tProxy))
		Local $tProxyBypass = DllStructCreate("char[" & (StringLen($sProxyBypass) + 1) & "]")
		DllStructSetData($tProxyBypass, 1, $sProxyBypass)
		DllStructSetData($tBuff, 3, DllStructGetPtr($tProxyBypass))
		Local $avResult = DllCall("urlmon.dll", "long", "UrlMkSetSessionOption", "dword", 38, "ptr", DllStructGetPtr($tBuff), "dword", DllStructGetSize($tBuff), "dword", 0)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_IE_SetProxy', 'Set Proxy cho IE thất bại'), False)
		Return True
	EndFunc

	Func _IE_SetUserAgent($sUserAgent)
		If Not StringRegExp($sUserAgent, '(?im)^User-Agent\s*?:') Then $sUserAgent = 'User-Agent: ' & $sUserAgent
		Local $sUserAgentLen = StringLen($sUserAgent)
		Local $tBuff = DllStructCreate("char[" & $sUserAgentLen & "]")
		DllStructSetData($tBuff, 1, $sUserAgent)
		Local $avResult = DllCall("urlmon.dll", "long", "UrlMkSetSessionOption", "dword", 0x10000001, "ptr", DllStructGetPtr($tBuff), "dword", $sUserAgentLen, "dword", 0)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_IE_SetUserAgent', 'Set User-Agent cho IE thất bại'), False)
		Return True
	EndFunc
#EndRegion



#Region <CookieJar + CookieGlobal>
	Func _HttpRequest_CookieJarSet($sCookieJarFilePath)
		If $sCookieJarFilePath = '' Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_CookieJarSet', 'Đường dẫn tập tin lưu Cookie không tồn tại'), False)
		If Not StringRegExp($sCookieJarFilePath, '^\h*?\w{1,2}:\\') Then $sCookieJarFilePath = @ScriptDir & (StringLeft($sCookieJarFilePath, 1) = '\' ? '' : '\') & $sCookieJarFilePath
		If $sCookieJarFilePath <> $g___CookieJarPath Then
			$g___CookieJarPath = $sCookieJarFilePath
			_HttpRequest_CookieJarUpdateToFile()
		EndIf
		;-------------------------------------------------------------------------------------------
		If Not FileExists($g___CookieJarPath) Then FileOpen($g___CookieJarPath, 2 + 8 + 32)
		$g___CookieJarINI($g___CookieJarPath) = FileRead($g___CookieJarPath)
		If @error Or Not $g___CookieJarINI($g___CookieJarPath) Then $g___CookieJarINI($g___CookieJarPath) = ''
		Return True
	EndFunc

	Func _HttpRequest_CookieJarSearch($sURL)
		If $g___CookieJarPath = '' Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_CookieJarSearch', 'Vui lòng cài đặt _HttpRequest_CookieJarSet trước khi sử dụng hàm này'), '')
		If Not $sURL Or IsKeyword($sURL) Or $sURL == -1 Then Return $g___CookieJarINI($g___CookieJarPath)
		Local $aDomain = StringRegExp($g___CookieJarINI($g___CookieJarPath), '(?m)^\[([^\]]+)\]$', 3)
		If @error Then Return SetError(1, 0, '')
		Local $sCookie = ''
		For $i = 0 To UBound($aDomain) - 1
			If StringRegExp($sURL, '(?i)^(?:https?:\/.*?' & $aDomain[$i] & '|' & $aDomain[$i] & ')(?:\/|$)') Then
				$sCookie &= __CookieJar_Read($aDomain[$i])
			EndIf
		Next
		Return StringReplace($sCookie, @CRLF, '; ', 0, 1)
	EndFunc

	Func _HttpRequest_CookieJarDelete($iSection = '', $iKey = '')
		If $g___CookieJarPath == '' Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_CookieJarDelete', 'Vui lòng cài đặt _HttpRequest_CookieJarSet trước khi sử dụng hàm này'), '')
		__CookieJar_Delete($iSection, $iKey)
	EndFunc

	Func _HttpRequest_CookieJarUpdateToFile()
		If $g___CookieJarPath = '' Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_CookieJarUpdateToFile', 'Vui lòng cài đặt _HttpRequest_CookieJarSet trước khi sử dụng hàm này'), False)
		If Not $g___CookieJarINI($g___CookieJarPath) Then Return False
		Local $hFileOpen = FileOpen($g___CookieJarPath, 2 + 8 + 32)
		FileWrite($hFileOpen, $g___CookieJarINI($g___CookieJarPath))
		$hFileOpen = FileClose($hFileOpen)
		Return True
	EndFunc

	;-------------------------------------------------------------------------------------

	Func __CookieJar_Insert($sDomain, $iHeaders)
		If Not $g___CookieJarPath Or Not $iHeaders Then Return $iHeaders
		Local $aCookie = StringRegExp($iHeaders, '(?im)^Set-Cookie\h*:\h*([^=]+)=(?!deleted;)([^;]+)(?:.*?;\h*?domain=([^;\r\n]+))?()', 3)
		If @error Or Mod(UBound($aCookie), 4) Then Return SetError(1, '', $iHeaders)
		For $i = 0 To UBound($aCookie) - 1 Step 4
			If $aCookie[$i + 2] == '' Then $aCookie[$i + 2] = $sDomain
			__CookieJar_Write($aCookie[$i + 2], $aCookie[$i], $aCookie[$i + 1])         ;$aCookie[$i + 2] nhớ thêm proxy vào
		Next
		Return $iHeaders
	EndFunc

	Func __CookieJar_Read($iSection, $iKey = '', $vDefault = '')
		Local $sRegion = StringRegExp($g___CookieJarINI($g___CookieJarPath), '(?ims)^\Q[' & $iSection & ']\E$\R?(.*?)(?:\R?^\[[^\]]+\]$|\R?\z)', 1)
		If @error Then Return SetError(1, '', $vDefault)
		If $iKey == '' Then Return $sRegion[0]
		Local $sKeyValue = StringRegExp($sRegion[0], '(?im)^\Q' & $iKey & '\E=(.*)$', 1)
		If @error Then Return SetError(2, '', $vDefault)
		Return $sKeyValue[0]
	EndFunc

	Func __CookieJar_Write($iSection, $iKey, $iValue)
		If $iKey == '' Then Return SetError(1, '', False)
		Local $vKeyValueOld = __CookieJar_Read($iSection, $iKey, False)
		Switch @error
			Case 0         ;Đã có Section lẫn Key
				$g___CookieJarINI($g___CookieJarPath) = StringRegExpReplace($g___CookieJarINI($g___CookieJarPath), '(?ims)^(\Q[' & $iSection & ']\E$.*?\R^\Q' & $iKey & '=\E)\Q' & $vKeyValueOld & '\E$', '${1}' & $iValue, 1)
			Case 1         ;Section chưa được tạo
				$g___CookieJarINI($g___CookieJarPath) = '[' & $iSection & ']' & @CRLF & $iKey & '=' & $iValue & @CRLF & @CRLF & $g___CookieJarINI($g___CookieJarPath)
			Case 2         ;Có Section và không có Key
				$g___CookieJarINI($g___CookieJarPath) = StringRegExpReplace($g___CookieJarINI($g___CookieJarPath), '(?im)^(\Q[' & $iSection & ']\E)$', '${1}' & @CRLF & $iKey & '=' & $iValue)
		EndSwitch
		If @error Then Return SetError(2, '', False)
		Return True
	EndFunc

	Func __CookieJar_Delete($iSection, $iKey = '')
		If $iKey == '' Then
			$g___CookieJarINI($g___CookieJarPath) = StringRegExpReplace($g___CookieJarINI($g___CookieJarPath), '(?ims)^\Q[' & $iSection & ']\E$.*?\R(^\[[^\]]+\]$|\R?\z)', '${1}', 1)
		Else
			$g___CookieJarINI($g___CookieJarPath) = StringRegExpReplace($g___CookieJarINI($g___CookieJarPath), '(?ims)^(\Q[' & $iSection & ']\E$.*?)\R^\Q' & $iKey & '=\E.*?$', '${1}', 1)
		EndIf
		If @error Then Return SetError(1, '', False)
		Return True
	EndFunc

	;------------------------------------------------------------------------

	Func __CookieGlobal_Insert($sDomain, $sCookie)
		If Not $sCookie Then Return
		Local $aCookie = StringRegExp($sCookie, '(?<=^|;)\h*([^=]+)=\h*([^;]+)(?:;|$)', 3)
		If @error Or Mod(UBound($aCookie), 2) Then Return SetError(1, '', '')
		For $i = 0 To UBound($aCookie) - 1 Step 2
			If $aCookie[$i + 1] = 'deleted' Then
				__CookieGlobal_Delete($sDomain, $aCookie[$i])
			Else
				__CookieGlobal_Write($sDomain, $aCookie[$i], $aCookie[$i + 1])
			EndIf
		Next
	EndFunc

	Func __CookieGlobal_Search($sURL)
		Local $aDomain = StringRegExp($g___hCookie[$g___LastSession], '(?m)^\[([^\]]+)\]$', 3)
		If @error Then Return SetError(1, 0, '')
		Local $sCookie = ''
		For $i = 0 To UBound($aDomain) - 1
			If StringRegExp($sURL, '(?i)^https?:\/.*?' & $aDomain[$i] & '[^\/]*?(?:\/|$)') Then
				$sCookie &= __CookieGlobal_Read($aDomain[$i])
			EndIf
		Next
		Return StringReplace($sCookie, @CRLF, '; ', 0, 1)
	EndFunc

	Func __CookieGlobal_Read($iSection, $iKey = '', $vDefault = '')
		Local $sRegion = StringRegExp($g___hCookie[$g___LastSession], '(?ims)^\Q[' & $iSection & ']\E$\R?(.*?)(?:\R?^\[[^\]]+\]$|\R?\z)', 1)
		If @error Then Return SetError(1, '', $vDefault)
		If $iKey == '' Then Return $sRegion[0]
		Local $sKeyValue = StringRegExp($sRegion[0], '(?im)^\Q' & $iKey & '\E=(.*)$', 1)
		If @error Then Return SetError(2, '', $vDefault)
		Return $sKeyValue[0]
	EndFunc

	Func __CookieGlobal_Write($iSection, $iKey, $iValue)
		If $iKey == '' Then Return SetError(1, '', False)
		Local $vKeyValueOld = __CookieGlobal_Read($iSection, $iKey, False)
		Switch @error
			Case 0         ;Đã có Section lẫn Key
				$g___hCookie[$g___LastSession] = StringRegExpReplace($g___hCookie[$g___LastSession], '(?ims)^(\Q[' & $iSection & ']\E$.*?\R^\Q' & $iKey & '=\E)\Q' & $vKeyValueOld & '\E$', '${1}' & $iValue, 1)
			Case 1         ;Section chưa được tạo
				$g___hCookie[$g___LastSession] = '[' & $iSection & ']' & @CRLF & $iKey & '=' & $iValue & @CRLF & @CRLF & $g___hCookie[$g___LastSession]
			Case 2         ;Có Section và không có Key
				$g___hCookie[$g___LastSession] = StringRegExpReplace($g___hCookie[$g___LastSession], '(?im)^(\Q[' & $iSection & ']\E)$', '${1}' & @CRLF & $iKey & '=' & $iValue)
		EndSwitch
		If @error Then Return SetError(2, '', False)
		Return True
	EndFunc

	Func __CookieGlobal_Delete($iSection, $iKey = '')
		If $iKey == '' Then
			$g___hCookie[$g___LastSession] = StringRegExpReplace($g___hCookie[$g___LastSession], '(?ims)^\Q[' & $iSection & ']\E$.*?\R(^\[[^\]]+\]$|\R?\z)', '${1}', 1)
		Else
			$g___hCookie[$g___LastSession] = StringRegExpReplace($g___hCookie[$g___LastSession], '(?ims)^(\Q[' & $iSection & ']\E$.*?)\R^\Q' & $iKey & '=\E.*?$', '${1}', 1)
		EndIf
		If @error Then Return SetError(1, '', False)
		Return True
	EndFunc
#EndRegion



#Region Đang test
	Func StringRegExpMulti($sText, $sPattern1, $sPattern2 = '', $sPattern3 = '', $sPattern4 = '', $sPattern5 = '', $sPattern6 = '', $sPattern7 = '', $sPattern8 = '', $sPattern9 = '')
		Local $aInput = [$sPattern1, $sPattern2, $sPattern3, $sPattern4, $sPattern5, $sPattern6, $sPattern7, $sPattern8, $sPattern9]
		Local $aRegEx, $aRet[0], $nSize = 0
		For $i = 0 To UBound($aInput) - 1
			If $aInput[$i] == '' Then ExitLoop
			$aRegEx = StringRegExp($sText, $aInput[$i], 3)
			If @error Then Return SetError($i, __HttpRequest_ErrNotify('StringRegExpMulti', 'Không tìm thấy giá trị ứng với $sPattern' & ($i + 1)), '')
			For $j = 0 To UBound($aRegEx) - 1
				ReDim $aRet[$nSize + 1]
				$aRet[$nSize] = $aRegEx[$j]
				$nSize += 1
			Next
		Next
		Return $aRet
	EndFunc

	Func _IE_FillDataForm($sURL, $sElement1, $sValue1, $sElement2 = '', $sValue2 = '', $sElement3 = '', $sValue3 = '', $sElement4 = '', $sValue4 = '', $sElement5 = '', $sValue5 = '', $sElement6 = '', $sValue6 = '', $sElement7 = '', $sValue7 = '', $sElement8 = '', $sValue8 = '', $sElement9 = '', $sValue9 = '', $sElement10 = '', $sValue10 = '', $sElement11 = '', $sValue11 = '', $sElement12 = '', $sValue12 = '')
		Local $sHTML = _HttpRequest('+2', $sURL)
		If @error Or $sHTML == '' Then Return SetError(1, '', $sHTML)
		Local $sCookie = _GetCookie()
		Local $aInput = StringRegExp($sHTML, '(?i)<\h*?(?:input|button) [^>]+>', 3)
		If @error Then Return SetError(2, '', $sHTML)
		Local $iTypeInput, $InputRep
		Local $aElement = [$sElement1, $sValue1, $sElement2, $sValue2, $sElement3, $sValue3, $sElement4, $sValue4, $sElement5, $sValue5, $sElement6, $sValue6, $sElement7, $sValue7, $sElement8, $sValue8, $sElement9, $sValue9, $sElement10, $sValue10, $sElement11, $sValue11, $sElement12, $sValue12]
		For $j = 0 To UBound($aElement) - 1 Step 2
			If $aElement[$j] == '' Then ContinueLoop
			For $i = 0 To UBound($aInput) - 1
				If StringInStr($aInput[$i], $aElement[$j], 0, 1) Then
					$iTypeInput = StringRegExp($aInput[$i], '(?i)type\h*?=\h*?["''](checkbox|button|submit)["'']', 1)
					If @error Then
						$iTypeInput = 'value'
					ElseIf $iTypeInput[0] = 'checkbox' Then
						$iTypeInput = 'checked'
					ElseIf $iTypeInput[0] = 'button' Or $iTypeInput[0] = 'submit' Then
						Local $eID = StringRegExp($aInput[$i], ' id\h*?=([''"])([^''"]+)\1', 1)
						If @error Then
							$eID = 'btn' & Random(111111, 999999, 1)
							$InputRep = StringRegExpReplace($aInput[$i], '<\h*?input ', '<input id="' & $eID & '" ', 1)
							$sHTML = StringReplace($sHTML, $aInput[$i], $InputRep, 1, 1)
						Else
							$eID = $eID[1]
						EndIf
						$sHTML &= @CRLF & '<script>document.getElementById("' & $eID & '").click()</script>'
					Else
						$iTypeInput = 'value'
					EndIf
					$sHTML = StringReplace($sHTML, $aInput[$i], StringRegExpReplace($aInput[$i], '(?i)<\h*?(input|button) ', '<\1 ' & $iTypeInput & '="' & $aElement[$j + 1] & '" ', 1), 1, 1)
				EndIf
			Next
		Next
		Local $aRet = [$sHTML, $sCookie]
		Return $aRet
	EndFunc

	Func _HttpRequest_ConnectIDM($sURL, $sFileSavePath, $iFlagDownloadMode = 0, $sReferer = '', $sCookie = '', $sPostData = '', $sUser = '', $sPassword = '')
		#cs
		; COM API: http://www.internetdownloadmanager.com/support/idm_api.html
		; Source: http://www.internetdownloadmanager.com/support/download/IDMCOMAPI.zip
		; $iFlagDownloadMode: 1 - do not show any confirmations dialogs.	2 - add to queue only, do not start downloading.
		#ce
		If Not IsObj($g___oIDM) Then
			$g___oIDM = ObjCreateInterface( _
					"{AC746233-E9D3-49CD-862F-068F7B7CCCA4}", _         ;CLSID_MLinkTransmitter
					"{4BD46AAE-C51F-4BF7-8BC0-2E86E33D1873}", _         ;IID_MLinkTransmitter
					"SendLinkToIDM hresult(bstr;bstr;bstr;bstr;bstr;bstr;bstr;bstr;long);")         ;tagCIDMLinkTransmitter
			If @error Or Not IsObj($g___oIDM) Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_ConnectIDM', 'Không thể kết nối COM với IDM'), False)
		EndIf
		If $sURL = '' Or $sFileSavePath = '' Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_ConnectIDM', '$sURL hoặc $sFileSavePath không thể là rỗng'), False)
		Local $aFileSavePath = StringRegExp($sFileSavePath, '^(.*?\\?)([^\\]+)$', 3)
		If @error Or UBound($aFileSavePath) <> 2 Then Return SetError(3, __HttpRequest_ErrNotify('_HttpRequest_ConnectIDM', 'Không tách được đường dẫn lưu tập tin'), False)
		If StringIsSpace($aFileSavePath[0]) Then
			__HttpRequest_ErrNotify('_HttpRequest_ConnectIDM', 'Tập tin sẽ được lưu đến Desktop do $sFileSavePath không có đường dẫn', '', 'Warning')
			$aFileSavePath[0] = @DesktopDir
		EndIf
		$g___oIDM.SendLinkToIDM($sURL, $sReferer, $sCookie, $sPostData, $sUser, $sPassword, $aFileSavePath[0], $aFileSavePath[1], $iFlagDownloadMode)
		If @error Then Return SetError(4, __HttpRequest_ErrNotify('_HttpRequest_ConnectIDM', 'Tương tác SendLinkToIDM thất bại'), False)
		Return True
	EndFunc
	
	Func _HttpRequest_Speech2Text($sFilePath_or_URL, $iAccessToken = Default, $vHomoPhones = False, $vHomoPhonesComplex = False)
		;https://github.com/ecthros/uncaptcha
		;https://github.com/debasishm89/hack_audio_captcha/blob/master/download-recaptcha.py
		Local $aToken = ['5VJA67YGXNCSMNJ7CYNNVWZGYTS7F2SC', 'C4GAT5X7ADGEKZA5L2UJF3RUFNHO4RSK', '23NDEC2ABK5VMXYXW2HE2E6GSPSGHGGF']
		Local $sTypeAudio = 'audio/wav'
		;----------------------------------------------------------------------------------------------------------------------------------
		If StringInStr($sFilePath_or_URL, 'http', 0, 1, 1, 4) Then
			Local $bData = _HttpRequest(5, $sFilePath_or_URL)
			If @error Or @extended > 300 Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_Speech2Text', 'Không thể tải về dữ liệu audio từ URL đã nạp'), '')
			If StringInStr($bData[0], 'Content-Type: audio/mp3') Then $sTypeAudio = 'audio/mpeg'
			$bData = $bData[1]
		Else
			Local $bData = _GetFileInfo($sFilePath_or_URL, 0)
			If @error Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_Speech2Text', 'Không thể lấy dữ liệu audio từ File Path'), '')
			$sTypeAudio = $bData[1]
			$bData = $bData[2]
			If $sTypeAudio <> 'audio/wav' And $sTypeAudio <> 'audio/mpeg' Then $sTypeAudio = 'audio/mpeg'
		EndIf
		;----------------------------------------------------------------------------------------------------------------------------------
		If $iAccessToken = Default Or $iAccessToken = '' Then $iAccessToken = $aToken[Random(0, UBound($aToken) - 1)]
		;----------------------------------------------------------------------------------------------------------------------------------
		Local $rq = _HttpRequest(2, 'https://api.wit.ai/speech', $bData, '', '', 'Content-Type: ' & $sTypeAudio & '|Authorization: Bearer ' & $iAccessToken)
		Local $sText = StringRegExp($rq, '"_text"\s?:\s?"(.*?)"', 1)
		If @error Or $sText[0] == '' Then Return SetError(3, __HttpRequest_ErrNotify('_HttpRequest_Speech2Text', 'Chuyển đổi âm thanh thành text thất bại:' & @CRLF & @CRLF & $rq), '')
		$sText = $sText[0]
		;----------------------------------------------------------------------------------------------------------------------------------
		If $vHomoPhones Then
			If $vHomoPhonesComplex Then
				Local $Str2Num = ['zero|a hero|the euro|the hero|Europe|yeah well|the o\.?|hey oh|hero|yeahhere|well|yeah well|euro|yo|hello|arrow|Arrow|they don''t|girl|bill|you know|\w*?ero', 'one|who won|won|juan|Warren|fun', 'two|too|to|who|true|so|you|hello|lou|\w*?do|\w*+?ew', 'three|during|tree|free|siri|very|be|wes|we|really|hurry|\w*?ee\w*?', 'four|for|fore|fourth|oar|or|more|porn|\w*?oor\w*?', 'five|hive|fight|fifth|why|find|\w*?ive\w*?', 'six|sex|big|sic|set|dicks|it|thank|\w*?icks?', 'seven|heaven|Frozen|Allen|send|weather|that in|ten|\w*?ven\w*?', 'eight|o\.\s?k\.?|eight|hate|fate|hey|\w*?ate', 'nine|yeah I|i''m|mine|brian|no i''m|no I|now I|night|eyes|none|non|bind|nice|\w*?ine']
			Else
				Local $Str2Num = ['zero', 'one|won', 'two|to|too', 'three', 'four|fourth|for|fore', 'five', 'six', 'seven', 'eight|ate', 'nine']
			EndIf
			For $i = 0 To 9
				$sText = StringRegExpReplace($sText, '(?i)(^|\W)(' & $Str2Num[$i] & ')(\W|$)', '${1}' & $i & '${3}')
			Next
			$sText = StringRegExpReplace($sText, '\D', '')
		EndIf
		;----------------------------------------------------------------------------------------------------------------------------------
		Return $sText
	EndFunc
	
	Func _HttpRequest_BypassADFLY($linkADFLY)
		_HttpRequest_SessionSet(105)
		_HttpRequest_SessionClear(105)
		Local $rq1 = _HttpRequest(2, $linkADFLY)
		Local $newHost = StringRegExp($g___LocationRedirect, '(\w+\.\w+)/ad/locked', 1)
		If Not @error Then $rq1 = _HttpRequest(2, StringReplace($linkADFLY, '/adf.ly/', '/' & $newHost[0] & '/-1/', 1))
		Local $ysmm = StringRegExp($rq1, '(?is)var ysmm\h+=.*?[''"](.*?)[''"]', 1)
		If @error Then Return SetError(1, __HttpRequest_ErrNotify('_HttpRequest_BypassADFLY', 'Không tìm thấy tham số ysmm trong dữ liệu trả về'), '')
		#Region <Giải mã ysmm>
			$ysmm = StringRegExpReplace($ysmm[0], '(.).', '\1') & StringReverse(StringRegExpReplace($ysmm[0], '.(.)', '\1'))
			Local $a_ymss = StringSplit($ysmm, ''), $S, $R
			For $m = 1 To $a_ymss[0]
				If Not StringIsDigit($a_ymss[$m]) Then ContinueLoop
				For $R = $m + 1 To $a_ymss[0]
					If Not StringIsDigit($a_ymss[$R]) Then ContinueLoop
					$S = BitXOR($a_ymss[$m], $a_ymss[$R])
					If $S < 10 Then $a_ymss[$m] = $S
					$m = $R
					ExitLoop
				Next
			Next
			Local $linkYMSS = StringTrimRight(StringTrimLeft(BinaryToString(_B64Decode(_ArrayToString($a_ymss, '', 1))), 16), 16)
		#EndRegion
		If StringInStr($linkYMSS, '/redirecting/', 0, 1) Then
			Local $rq2 = _HttpRequest(2, $linkYMSS)
			Local $linkBypass = StringRegExp($rq2, '<a href="(.*?)">click this link</a>', 1)
			If @error Then Return SetError(2, __HttpRequest_ErrNotify('_HttpRequest_BypassADFLY', 'Không tìm thấy địa chỉ redirect sau khi bypass'), '')
			Return $linkBypass[0]
		Else
			Return $linkYMSS
		EndIf
	EndFunc
#EndRegion



#Region <_HttpRequest Object Base>
	Func _oHttpRequest_SessionGet()
		Return $g___oWinHTTP[$g___LastSession]
	EndFunc
	
	Func _oHttpRequest_SessionSet($oSession)
		$g___oWinHTTP[$g___LastSession] = $oSession
	EndFunc
	
	Func _oHttpRequest($iReturn, $sURL, $sData2Send = '', $sCookie = '', $sReferer = '', $sAdditional_Headers = '', $sMethod = '')
		Local $vContentType = '', $vBoundary = '', $vUpload = 0
		Local $sServerUserName = '', $sServerPassword = '', $sProxyUserName = '', $sProxyPassword = ''
		;----------------------------------------------------------------------------------
		If StringRegExp($sURL, '^\h*?/\w?') And $g___sBaseURL[$g___LastSession] Then $sURL = $g___sBaseURL[$g___LastSession] & $sURL
		;----------------------------------------------------------------------------------
		Local $aRetMode = __HttpRequest_iReturnSplit($iReturn)
		If @error Then Return SetError(1, -1, '')
		Local $aURL = __HttpRequest_URLSplit($sURL)
		If @error Then Return SetError(2, -1, '')
		;----------------------------------------------------------------------------------
		If Not IsObj($g___oWinHTTP[$g___LastSession]) Then $g___oWinHTTP[$g___LastSession] = ObjCreate("WinHttp.WinHttpRequest.5.1")
		If @error Then Return SetError(3, __HttpRequest_ErrNotify('_oHttpRequest', 'oWinHTTP Create Object Fail', -1), '')
		With $g___oWinHTTP[$g___LastSession]
			;-------------------------------------------------
			If IsArray($sData2Send) Then $sData2Send = _HttpRequest_DataFormCreate($sData2Send)
			;-------------------------------------------------
			.Open(($sMethod ? $sMethod : ($sData2Send ? "POST" : "GET")), $sURL, False)
			If @error Then Return SetError(4, __HttpRequest_ErrNotify('_oHttpRequest', 'Xảy ra lỗi không thể thực hiện oHTTP.Open ', -1), '')
			;-------------------------------------------------
			If $aRetMode[3] Then .Option(6) = False         ;Disable Redirects
			;-------------------------------------------------
			.Option(4) = 0x3300         ;SslErrorIgnoreFlags
			;-------------------------------------------------
			If $g___TimeOut Then .SetTimeouts(0, $g___TimeOut, $g___TimeOut, $g___TimeOut)
			;------------------------------------------------------------------------------------------------------------------------------
			If $aRetMode[5] Then         ;Proxy cục bộ
				$sProxyUserName = $aRetMode[6]
				$sProxyPassword = $aRetMode[7]
				.SetProxy(2, $aRetMode[5])
			ElseIf $g___hProxy[$g___LastSession][0] Then         ;Proxy toàn cục
				$sProxyUserName = $g___hProxy[$g___LastSession][3]
				$sProxyPassword = $g___hProxy[$g___LastSession][4]
				.SetProxy(2, $g___hProxy[$g___LastSession][0], $g___hProxy[$g___LastSession][2])
			EndIf
			If $sProxyUserName Then .SetCredentials($sProxyUserName, $sProxyPassword, 1)
			;------------------------------------------------------------------------------------------------------------------------------
			If $aURL[4] Then         ;Set cục bộ - $aURL[4], $aURL[5] nghĩa là URL có kèm user/pass
				$sServerUserName = $aURL[4]
				$sServerPassword = $aURL[5]
			ElseIf $g___hCredential[$g___LastSession][0] Then         ;Set toàn cục
				$sServerUserName = $g___hCredential[$g___LastSession][0]
				$sServerPassword = $g___hCredential[$g___LastSession][1]
			EndIf
			If $sServerUserName Then .SetCredentials($sServerUserName, $sServerPassword, 0)
			;-------------------------------------------------
			If $sData2Send Then
				If Not $g___Boundary Then
					If StringInStr($vContentType, 'multipart', 0, 1) Then
						$vBoundary = StringRegExp($vContentType, '(?i);\h*?boundary\h*?=\h*?([\w\-]+)', 1)
						If Not @error Then
							$g___Boundary = '--' & $vBoundary[0]
							If Not StringRegExp($sData2Send, '(?is)^' & $g___Boundary) Then
								Return SetError(5, __HttpRequest_ErrNotify('_oHttpRequest', '$sData2Send có Boundary không khớp với khai báo ở header Content-Type', -1), '')
							ElseIf Not StringRegExp($sData2Send, '(?is)' & $g___Boundary & '--\R*?$') Then
								Return SetError(6, __HttpRequest_ErrNotify('_oHttpRequest', 'Chuỗi Boundary ở cuối $sData2Send phải có -- ở cuối', -1), '')
							EndIf
						EndIf
					ElseIf StringRegExp($sData2Send, '(?m)^(-*?----WebKitFormBoundary\w+|-{20,}\d{10,})$') Then
						$g___Boundary = StringRegExp($sData2Send, '(?m)^(-*?----WebKitFormBoundary\w+|-{20,}\d{10,})$', 1)[0]
					EndIf
				EndIf
				;----------------------------------------------
				If $g___Boundary Then
					$vContentType = 'multipart/form-data; boundary=' & StringTrimLeft($g___Boundary, 2)
					$g___Boundary = ''
					$vUpload = 1
					$sData2Send = StringToBinary($sData2Send)
				Else
					If Not $vContentType Then
						If StringRegExp($sData2Send, '^\h*?[\{\[]') Then
							$vContentType = 'application/json'
						Else
							$vContentType = 'application/x-www-form-urlencoded'
							__Data2Send_CheckEncode($sData2Send)
						EndIf
						If Not IsBinary($sData2Send) Then $sData2Send = StringToBinary($sData2Send, $aRetMode[11])
					EndIf
				EndIf
			EndIf
			;----------------------------------------------------------------------------------
			Local $oAdditional_Headers = ObjCreate("Scripting.Dictionary")
			With $oAdditional_Headers
				.CompareMode = 1
				.Item('Accept') = '*/*'
				.Item('DNT') = '1'
				.Item('User-Agent') = ($g___UserAgent[$g___LastSession] ? $g___UserAgent[$g___LastSession] : $g___defUserAgent)
				If $vContentType Then .Item('Content-Type') = $vContentType
				If $sReferer Then .Item('Referer') = StringRegExpReplace($sReferer, '(?i)^\h*?Referer\h*?:\h*', '', 1)
				If $sCookie Then .Item('Cookie') = StringRegExpReplace($sCookie, '(?i)^\h*?Cookie\h*?:\h*', '', 1)
				If $sAdditional_Headers Then
					Local $aAddition = StringRegExp($sAdditional_Headers, '(?i)\h*?([\w\-]+)\h*:\h*(.*?)(?:\||$)', 3)
					For $i = 0 To UBound($aAddition) - 1 Step 2
						.Item($aAddition[$i]) = $aAddition[$i + 1]
					Next
				EndIf
				If $aRetMode[15] And Not StringRegExp($sAdditional_Headers, '(?im)(^|\|)\h*?X-Forwarded-For\h*?:') Then .Item('X-Forwarded-For') = _HttpRequest_GenarateIP()
				Local $aHeaderName = .Keys
				Local $aHeaderValue = .Items
				For $i = 0 To UBound($aHeaderName) - 1
					$g___oWinHTTP[$g___LastSession].SetRequestHeader($aHeaderName[$i], $aHeaderValue[$i])
				Next
				If $vUpload And Not $oAdditional_Headers.Exists('Content-Length') Then $g___oWinHTTP[$g___LastSession].SetRequestHeader('Content-Length', BinaryLen($sData2Send))
			EndWith
			;----------------------------------------------------------------------------------
			$oAdditional_Headers = Null
			.Send($sData2Send)
			.WaitForResponse()
			;----------------------------------------------------------------------------------
			Local $vResponse_StatusCode = .Status
			$g___retData[$g___LastSession][0] = .GetAllResponseHeaders()
			;----------------------------------------------------------------------------------
			Switch $aRetMode[0]
				Case 0, 1
					If $aRetMode[2] Then
						$sCookie = _GetCookie($g___retData[$g___LastSession][0])
						Return SetError(@error ? 7 : 0, $vResponse_StatusCode, $sCookie)
					Else
						Return SetError(0, $vResponse_StatusCode, $g___retData[$g___LastSession][0])
					EndIf
					
				Case 2 To 5
					If Not $aRetMode[12] Then $g___retData[$g___LastSession][1] = .ResponseBody
					If @error Then Return SetError(8, $vResponse_StatusCode, '')
					;------------------------------------------
					If StringRegExp(BinaryMid($g___retData[$g___LastSession][1], 1, 1), '(?i)0x(1F|08|8B)') Then $g___retData[$g___LastSession][1] = __Gzip_Uncompress($g___retData[$g___LastSession][1])
					;------------------------------------------
					If $aRetMode[2] = 1 Or $aRetMode[0] = 3 Or $aRetMode[0] = 5 Then         ;$aRetMode[2] = 1: force Binary
						If $aRetMode[9] Then         ;Ghi file: iReturn có dạng FilePath:Encoding. Khi $aRetMode[9] được set thì kiểu Data trả về sẽ tự động set về 3 (Binary) bất chấp đã điền kiểu Data trả về là gì
							_HttpRequest_Test($g___retData[$g___LastSession][1], $aRetMode[9], $aRetMode[10])
							Return SetError(9 + @error, $vResponse_StatusCode, @error = 0)
						ElseIf $aRetMode[0] < 4 Then
							Return SetError(0, $vResponse_StatusCode, $g___retData[$g___LastSession][1])
						Else
							Local $aRet = [$g___retData[$g___LastSession][0], $g___retData[$g___LastSession][1]]
							Return SetError(0, $vResponse_StatusCode, $aRet)
						EndIf
					Else
						Local $sRet = $g___retData[$g___LastSession][1]
						$sRet = BinaryToString($sRet, $aRetMode[11])         ; $aRetMode[11] = 1: force ANSI, = 0 (Default): UTF8
						If $aRetMode[12] Then         ;force return Raw Text
							$sRet = .ResponseText
						ElseIf $aRetMode[4] Then         ;trả về dạng đầy đủ của link relative trong HTML source
							Local $aURL = __HttpRequest_URLSplit($sURL)
							If Not @error Then $sRet = _HTML_AbsoluteURL($sRet, $aURL[7] & '://' & $aURL[2] & $aURL[3], '', $aURL[7])
						ElseIf $aRetMode[16] Then
							$sRet = _HTMLDecode($sRet)
						EndIf
						If $aRetMode[0] < 4 Then
							Return SetError(0, $vResponse_StatusCode, $sRet)
						Else
							Local $aRet = [$g___retData[$g___LastSession][0], $sRet]
							Return SetError(0, $vResponse_StatusCode, $aRet)
						EndIf
					EndIf
				Case Else
					Exit MsgBox(4096, 'Thông báo', 'Không có $iReturn này, xin vui lòng sửa lại code')
			EndSwitch
		EndWith
	EndFunc
#EndRegion



