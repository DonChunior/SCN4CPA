#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7

#include <FileConstants.au3>
#include <SQLite.au3>
#include "SQLite.dll.au3"
#include <File.au3>
#include <WinAPI.au3>

Opt("MustDeclareVars", 1)

Global $g_hLogfile = 0
Global $g_sSQliteDll = ""
Global $g_hDirectory = 0
Global $g_pBuffer = 0

Main()

Func Main()
;~ 	Local Const $sLogfile = @TempDir & "\XMLcollector_" & @YEAR & @MON & @MDAY & "T" & @HOUR & @MIN & @SEC & ".log"
	Local Const $sLogfile = @TempDir & "\XMLcollector.log"
	Local Const $sSettingsFile = @ScriptDir & "\SCN4CPA.ini"
	Local Const $sSettingsSection = "settings"
	Local Const $sUnprocessedFilesPathKey = "unprocessed_files_path"
	Local $sUnprocessedFilesPath = ""
	Local Const $sXmlFilesDatabaseKey = "xml_files_database"
	Local $sXmlFilesDatabase = ""
	Local Const $iBufferSize = 8388608
	Local $aDirectoryChanges = 0
	Local Const $sXmlFileExtension = ".xml"

	If OnAutoItExitRegister("CleanUp") = 0 Then
		Exit 1
	EndIf
	$g_hLogfile = FileOpen($sLogfile, $FO_OVERWRITE)
	_FileWriteLog($g_hLogfile, "Application was started")
	$sUnprocessedFilesPath = _WinAPI_ExpandEnvironmentStrings(IniRead($sSettingsFile, $sSettingsSection, $sUnprocessedFilesPathKey, ""))
	_FileWriteLog($g_hLogfile, $sUnprocessedFilesPathKey & "=" & $sUnprocessedFilesPath)
	$sXmlFilesDatabase = _WinAPI_ExpandEnvironmentStrings(IniRead($sSettingsFile, $sSettingsSection, $sXmlFilesDatabaseKey, ""))
	_FileWriteLog($g_hLogfile, $sXmlFilesDatabaseKey & "=" & $sXmlFilesDatabase)
	$g_hDirectory = _WinAPI_CreateFileEx($sUnprocessedFilesPath, $OPEN_EXISTING, $FILE_LIST_DIRECTORY, $FILE_SHARE_ANY, $FILE_FLAG_BACKUP_SEMANTICS)
	If @error Then
		_FileWriteLog($g_hLogfile, "_WinAPI_CreateFileEx: " & _WinAPI_GetLastError() & " - " & _WinAPI_GetLastErrorMessage())
		Exit
	EndIf
	$g_pBuffer = _WinAPI_CreateBuffer($iBufferSize)
	If @error Then
		_FileWriteLog($g_hLogfile, "_WinAPI_CreateBuffer: " & _WinAPI_GetLastError() & " - " & _WinAPI_GetLastErrorMessage())
		Exit
	EndIf
	CreateDirStructure($sXmlFilesDatabase)
	$g_sSQliteDll = _SQLite_Startup()
	While 1
		$aDirectoryChanges = _WinAPI_ReadDirectoryChanges($g_hDirectory, $FILE_NOTIFY_CHANGE_FILE_NAME, $g_pBuffer, $iBufferSize)
		If @error Then
			_FileWriteLog($g_hLogfile, "_WinAPI_ReadDirectoryChanges: " & _WinAPI_GetLastError() & " - " & _WinAPI_GetLastErrorMessage())
			Exit
		EndIf
		_SQLite_Open($sXmlFilesDatabase)
		_SQLite_Exec(-1, "CREATE TABLE IF NOT EXISTS xml_files(file_name TEXT PRIMARY KEY ON CONFLICT REPLACE);")
		For $i = 1 To $aDirectoryChanges[0][0]
			If StringRight($aDirectoryChanges[$i][0], StringLen($sXmlFileExtension)) <> $sXmlFileExtension Or $aDirectoryChanges[$i][0] = "temp.xml" Then
				ContinueLoop
			EndIf
			If $aDirectoryChanges[$i][1] <> $FILE_ACTION_ADDED And $aDirectoryChanges[$i][1] <> $FILE_ACTION_MODIFIED And $aDirectoryChanges[$i][1] <> $FILE_ACTION_RENAMED_NEW_NAME Then
				ContinueLoop
			EndIf
			_SQLite_Exec(-1, "INSERT INTO xml_files (file_name) VALUES ('" & $aDirectoryChanges[$i][0] & "');")
		Next
		_SQLite_Close()
	WEnd
EndFunc

Func CleanUp()
	_SQLite_Shutdown()
	_WinAPI_FreeMemory($g_pBuffer)
	_WinAPI_CloseHandle($g_hDirectory)
	_FileWriteLog($g_hLogfile, "Application is closed")
	FileClose($g_hLogfile)
EndFunc

Func CreateDirStructure(Const ByRef $sPath)
	Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
	_PathSplit($sPath, $sDrive, $sDir, $sFileName, $sExtension)
	If Not FileExists($sDrive & $sDir) Then
		DirCreate($sDrive & $sDir)
	EndIf
EndFunc