; keepawake.ahk
; Windows keep-awake helper — moves the mouse 1px every 60 seconds

#NoEnv
#Warn
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%

SetTimer, KeepAwake, 60000
Return

KeepAwake:
    MouseMove, 0, 0, 0, R
Return
