#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7

#include <SQLite.au3>
#include "SQLite.dll.au3"
#include <WinAPISys.au3>

Opt("MustDeclareVars", 1)

Global $g_hLogfile = 0

Main()

Func Main()
;~ 	Local Const $sLogfile = @TempDir & "\SCN4CPA_" & @YEAR & @MON & @MDAY & "T" & @HOUR & @MIN & @SEC & ".log"
	Local Const $sLogfile = @TempDir & "\SCN4CPA.log"
	Local Const $sSettingsFile = @ScriptDir & "\SCN4CPA.ini"
	Local Const $sSettingsSection = "settings"
	Local Const $sUnprocessedFilesPathKey = "unprocessed_files_path"
	Local $sUnprocessedFilesPath = ""
	Local Const $sXmlFilesDatabaseKey = "xml_files_database"
	Local $sXmlFilesDatabase = ""
	Local Const $sAlternativeScnKey = "alternative_scn"
	Local $sAlternativeScn = ""

	If OnAutoItExitRegister("CleanUp") = 0 Then
		Exit 1
	EndIf
	$g_hLogfile = FileOpen($sLogfile, $FO_OVERWRITE)
	_FileWriteLog($g_hLogfile, "Application was started")
	$sUnprocessedFilesPath = _WinAPI_ExpandEnvironmentStrings(IniRead($sSettingsFile, $sSettingsSection, $sUnprocessedFilesPathKey, ""))
	_FileWriteLog($g_hLogfile, $sUnprocessedFilesPathKey & "=" & $sUnprocessedFilesPath)
	$sXmlFilesDatabase = _WinAPI_ExpandEnvironmentStrings(IniRead($sSettingsFile, $sSettingsSection, $sXmlFilesDatabaseKey, ""))
	_FileWriteLog($g_hLogfile, $sXmlFilesDatabaseKey & "=" & $sXmlFilesDatabase)
	$sAlternativeScn = _WinAPI_ExpandEnvironmentStrings(IniRead($sSettingsFile, $sSettingsSection, $sAlternativeScnKey, ""))
	_FileWriteLog($g_hLogfile, $sAlternativeScnKey & "=" & $sAlternativeScn)
EndFunc

Func CleanUp()
;~ 	_SQLite_Shutdown()
	_FileWriteLog($g_hLogfile, "Application is closed")
	FileClose($g_hLogfile)
EndFunc