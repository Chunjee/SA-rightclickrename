;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Adds user-configurable file renaming options to the windows explorer right-click menu
; 
The_ProjectName := "RightClickRename"
The_VersionNumb = 0.0.1

;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
SetBatchLines -1 ;Go as fast as CPU will allow
#NoTrayIcon ;No tray icon
#SingleInstance off ;Do not allow running more then one instance at a time


;Dependencies
#Include %A_ScriptDir%\lib
#Include util_misc.ahk

;For Debug Only
;#Include ahk-unittest.ahk

;Classes
#Include %A_ScriptDir%\lib\logs.ahk\export.ahk

;Modules
#Include %A_ScriptDir%
#Include GUI.ahk


Sb_InstallFiles() ;Install included files and make any directories required

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;; Creat Logging obj
log := new Log_class(The_ProjectName "-" A_YYYY A_MM A_DD, A_ScriptDir "\logfiles")
log.maxSizeMBLogFile_Default := 99 ;Set log Max size to 99 MB
log.application := The_ProjectName
log.preEntryString := "%A_NowUTC% -- "
; log.postEntryString := "`r"
log.initalizeNewLogFile(false, The_ProjectName " v" The_VersionNumb " log begins...`n")
log.add(The_ProjectName " launched from user " A_UserName " on the machine " A_ComputerName ". Version: v" The_VersionNumb)



; Read settings.JSON for global settings
FileRead, The_MemoryFile, % A_ScriptDir "\settings.json"
Settings := JSON.parse(The_MemoryFile)
The_MemoryFile := ""


; Create some god vars
Options_array := []
stringSimilarity := new stringsimilarity()



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

CMD      = %1%

;for each optional ending in the settings file, create a new context menu and remember it for removal if needed
if (!CMD) {
    GUI()
    log.add("GUI was created")
    for key, value in Settings.optional_endings {
        ; CM_AddMenuItem( The_ProjectName, "value", "RENAME ""%1""" value )
        Fn_ConextMenuAdd("change name: ", value)
    }
} else {
    ; recieved command with CLI args
    FullPath := Fn_QuickRegEx(CMD,"(.+)####")
    NewLabel := Fn_QuickRegEx(CMD,"####(.+)")
    OldLabel := Fn_QuickRegEx(CMD,"(-.+)####")

    Loop, Files, %FullPath%
    {
        log.add("Attempting to rename " A_LoopFileName)
        if (OldLabel = "null") { ;no existing -label
            BaseFileName := Fn_QuickRegEx(A_LoopFileName,"(.+?)(\.[^.]*$|$)") "-" NewLabel "." A_LoopFileExt
            FileMove, %A_LoopFileDir%/%A_LoopFileName%, %A_LoopFileDir%/%BaseFileName%, 1
        } else {
            NewFilename := Fn_QuickRegEx(A_LoopFileName,"(.+)-") "-" NewLabel "." A_LoopFileExt
            FileMove, %A_LoopFileDir%/%A_LoopFileName%, %A_LoopFileDir%/%NewFilename%, 1
        }
        if (ErrorLevel = 1) {
            log.add("Renaming failed for some reason, file possibly in use")
        }
    }
    ExitApp
}
Return




;/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/

;Create Directory and install needed file(s)
Sb_InstallFiles()
{
    ; FileCreateDir, %A_ScriptDir%\data\
}





;/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/


Fn_SearchObj(para_obj, para_key)
{
    for l_key, l_value in para_obj {
        ; msgbox, % para_key " - " l_key
        if (para_key = l_key) {
            return l_value
        }
    }
}


Fn_ConextMenuAdd(para_title,para_arg)
{
    RegEntry := A_IsCompiled ? """" A_ScriptFullPath """ ""`%1####""" para_arg : """" A_AhkPath """ """ A_ScriptFullPath """ ""`%1####""" para_arg
    RegRead, ExistingEntry, HKey_Current_User, Software\Classes\*\shell\%para_title%\Command
    if (ExistingEntry = RegEntry) {
        RegDelete, HKey_Current_User, Software\Classes\*\shell\%para_title%%para_arg%
        RegDelete, HKey_Current_User, Software\Classes\Folder\shell\%para_title%%para_arg%
        RegDelete, HKEY_CLASSES_ROOT, lnkfile\%para_title%%para_arg%
        ; MsgBox, 0x40, %para_title%, Explorer context entry removed.
    } else {
        RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Classes\*\shell\%para_title%%para_arg%\Command, , %RegEntry%
        RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Classes\Folder\shell\%para_title%%para_arg%\Command, , %RegEntry%
        RegWrite, REG_SZ, HKEY_CLASSES_ROOT, lnkfile\%para_title%%para_arg%\Command, , %RegEntry%
        if A_IsCompiled {
            RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Classes\*\Shell\%para_title%%para_arg%,icon, %A_ScriptFullPath%
            RegWrite, REG_SZ, HKEY_CURRENT_USER, Software\Classes\Folder\shell\%para_title%%para_arg%,icon, %A_ScriptFullPath%
            RegWrite, REG_SZ, HKEY_CLASSES_ROOT, lnkfile\%para_title%%para_arg%,icon, %A_ScriptFullPath%
            }
        ; MsgBox, 0x40, %Title%, Explorer context entry added.
    }
}


Fn_ContextMenuRemove(para_title,para_arg)
{
    RegDelete, HKey_Current_User, Software\Classes\*\shell\%para_title%%para_arg%
    RegDelete, HKey_Current_User, Software\Classes\Folder\shell\%para_title%%para_arg%
    RegDelete, HKEY_CLASSES_ROOT, lnkfile\%para_title%%para_arg%
}
