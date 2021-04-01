#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7

#include <FileConstants.au3>
#include <File.au3>
#include <WinAPI.au3>
#include <XML.au3>

Opt("MustDeclareVars", 1)

Global $g_hLogfile = 0
Global $g_hDirectory = 0
Global $g_pBuffer = 0

Main()

Func Main()
;~ 	Local Const $sLogfile = @LocalAppDataDir & "\SCN4CPA\SCN4CPA_" & @YEAR & @MON & @MDAY & "T" & @HOUR & @MIN & @SEC & ".log"
	Local Const $sLogfile = @LocalAppDataDir & "\SCN4CPA\SCN4CPA.log"
	Local Const $sSettingsFile = @ScriptDir & "\SCN4CPA.ini"
	Local Const $sSettingsSection = "settings"
	Local Const $sUnprocessedFilesPathKey = "unprocessed_files_path"
	Local $sUnprocessedFilesPath = ""
	Local Const $sAlternativeScnKey = "alternative_scn"
	Local $sAlternativeScn = ""
	Local Const $iBufferSize = 8388608
	Local $aDirectoryChanges = 0
	Local $asUniqueFileNames = 0
	Local $oXmlDoc = 0
	Local $aScnValues = 0

	If OnAutoItExitRegister("CleanUp") = 0 Then
		Exit 1
	EndIf
	$g_hLogfile = FileOpen($sLogfile, $FO_OVERWRITE + $FO_CREATEPATH)
	_FileWriteLog($g_hLogfile, "Application was started")
	$sUnprocessedFilesPath = _WinAPI_ExpandEnvironmentStrings(IniRead($sSettingsFile, $sSettingsSection, $sUnprocessedFilesPathKey, ""))
	_FileWriteLog($g_hLogfile, $sUnprocessedFilesPathKey & "=" & $sUnprocessedFilesPath)
	$sAlternativeScn = _WinAPI_ExpandEnvironmentStrings(IniRead($sSettingsFile, $sSettingsSection, $sAlternativeScnKey, ""))
	_FileWriteLog($g_hLogfile, $sAlternativeScnKey & "=" & $sAlternativeScn)
	$g_hDirectory = _WinAPI_CreateFileEx($sUnprocessedFilesPath, $OPEN_EXISTING, $FILE_LIST_DIRECTORY, $FILE_SHARE_ANY, $FILE_FLAG_BACKUP_SEMANTICS)
	If @error Then
		_FileWriteLog($g_hLogfile, "_WinAPI_CreateFileEx: " & _WinAPI_GetLastError() & " - " & _WinAPI_GetLastErrorMessage())
		Exit 1
	EndIf
	$g_pBuffer = _WinAPI_CreateBuffer($iBufferSize)
	If @error Then
		_FileWriteLog($g_hLogfile, "_WinAPI_CreateBuffer: " & _WinAPI_GetLastError() & " - " & _WinAPI_GetLastErrorMessage())
		Exit 1
	EndIf
	While 1
		$aDirectoryChanges = _WinAPI_ReadDirectoryChanges($g_hDirectory, $FILE_NOTIFY_CHANGE_FILE_NAME, $g_pBuffer, $iBufferSize)
		If @error Then
			_FileWriteLog($g_hLogfile, "_WinAPI_ReadDirectoryChanges: " & _WinAPI_GetLastError() & " - " & _WinAPI_GetLastErrorMessage())
			Exit 1
		EndIf
		Sleep(1000)
		FilterDirectoryChanges($aDirectoryChanges)
		If Not $aDirectoryChanges[0][0] Then ContinueLoop
		$asUniqueFileNames = _ArrayUnique($aDirectoryChanges, 0, 1, 0, $ARRAYUNIQUE_NOCOUNT)
		For $sFileName In $asUniqueFileNames
			If Not FileExists($sUnprocessedFilesPath & "\" & $sFileName) Then ContinueLoop
			While _WinAPI_FileInUse($sUnprocessedFilesPath & "\" & $sFileName)
				Sleep(10)
			WEnd
			$oXmlDoc = _XML_CreateDOMDocument()
			_XML_Load($oXmlDoc, $sUnprocessedFilesPath & "\" & $sFileName)
			If @error Then ContinueLoop
			If Not _XML_NodeExists($oXmlDoc, "//SCN") Then ContinueLoop
			$aScnValues = _XML_GetValue($oXmlDoc, "//SCN")
			If $aScnValues[1] = $sAlternativeScn Then ContinueLoop
			_XML_UpdateField2($oXmlDoc, "//SCN", $sAlternativeScn)
			_FileWriteLog($g_hLogfile, _XML_SaveToFile($oXmlDoc, $sUnprocessedFilesPath & "\" & $sFileName) & " " & $sFileName)
;~ 			_FileWriteLog($g_hLogfile, $sFileName & ": " & )
		Next
	WEnd
EndFunc   ;==>Main

Func CleanUp()
	If $g_pBuffer Then _WinAPI_FreeMemory($g_pBuffer)
	If $g_hDirectory Then _WinAPI_CloseHandle($g_hDirectory)
	If $g_hLogfile Then
		_FileWriteLog($g_hLogfile, "Application is closed")
		FileClose($g_hLogfile)
	EndIf
EndFunc   ;==>CleanUp

Func FilterDirectoryChanges(ByRef $aDirectoryChanges)
	Local Const $sXmlFileExtension = ".xml"
	Local $aiIndexesToDelete[1] = [0]

	For $i = 1 To $aDirectoryChanges[0][0]
		If StringRight($aDirectoryChanges[$i][0], StringLen($sXmlFileExtension)) <> $sXmlFileExtension _
				Or $aDirectoryChanges[$i][0] = "temp.xml" _
				Or $aDirectoryChanges[$i][0] = "system_info.xml" Then
			$aiIndexesToDelete[0] = _ArrayAdd($aiIndexesToDelete, $i)
		ElseIf $aDirectoryChanges[$i][1] <> $FILE_ACTION_ADDED _
				And $aDirectoryChanges[$i][1] <> $FILE_ACTION_MODIFIED _
				And $aDirectoryChanges[$i][1] <> $FILE_ACTION_RENAMED_NEW_NAME Then
			$aiIndexesToDelete[0] = _ArrayAdd($aiIndexesToDelete, $i)
		EndIf
	Next
	If $aiIndexesToDelete[0] Then
		$aDirectoryChanges[0][0] = _ArrayDelete($aDirectoryChanges, $aiIndexesToDelete) - 1
	EndIf
EndFunc   ;==>FilterDirectoryChanges
