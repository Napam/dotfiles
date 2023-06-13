#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

^#!e::Run, notepad %A_ScriptDir%\hotkeys.ahk
^#!r::
    Reload
    TrayTip, AHK, Reloaded hotkeys.ahk
    Return

#!c::Run, chrome
#!Space::Run, "C:\Users\naphata\.usersetup\windows\commands.bat"
^!t::Run, wt -p Ubuntu-20.04
#!p::Run, wt -p "Windows Powershell"
#!j::Run, wt -p Ubuntu-20.04 ssh nam012@janus.uib.no; split-pane --vertical ssh nam012@janus.uib.no

; VERY IMPORTANT WHEN Fn+LeftArrow dont WORK!!! Use CapsLock as Fn+left, right, up down 
; ~*CapsLock::SetCapsLockState, AlwaysOff
; CapsLock & Left::
;     if GetKeyState("Shift","P")
;         SendInput, +{Home}
;     else
;         SendInput, {Home}
;     Return

; CapsLock & Right::
;     if GetKeyState("Shift","P")
;         SendInput, +{End}
;     else
;         SendInput, {End}
;     Return

; CapsLock & Up::  
;     if GetKeyState("Shift","P")
;         SendInput, +{PgUp}
;     else
;         SendInput, {PgUp}
;     Return

; CapsLock & Down::
;     if GetKeyState("Shift","P")
;     SendInput, +{PgDn}
;     else
;         SendInput, {PgDn}
;     Return

#!v::
SendInput, ls
return

; PowerToys overrides Win+Up to maximize window, so remap to Win+Alt+Up
#!Up::WinMaximize, A

:*:,.nam::Naphat Amundsen
:*:,.mvh::Mvh Naphat Amundsen
:*:,.tlf::48424120
:*:,.mail::naphat@live.no

:*:,.time::
SendInput, %A_Year%/%A_Mon%/%A_MDay%T%A_Hour%:%A_Min%:%A_Sec%
return  

:*:,.std::
SendRaw, std::cout <<  << "\n";
Send, {LEFT 9}
return

:*:,.pre::
SendRaw, <pre>{{  }}</pre>
Send, {LEFT 9}
return

:*:,.con::
SendRaw, console.log()
Send, {LEFT 1}
return

:*:,.dcon::
SendRaw, console.log('LOG:\x1b[33mDEBUG\x1b[37m:', )
Send, {LEFT 1}
return

:*:,.icon::
SendRaw, console.log('LOG:INFO:', )
Send, {LEFT 1}
return

:*:,.hcon::
SendRaw, console.log('LOG:\x1b[35mHIGHLIGHT\x1b[37m:', )
Send, {LEFT 1}
return

:*:,.fcon::/(LOG:(INFO|DEBUG|HIGHLIGHT):)|Error/


