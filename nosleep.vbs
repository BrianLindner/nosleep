dim objResult
dim min_seconds, max_seconds
dim key_index
dim send_key
dim key_list

' list of keys to select from
set key_list = CreateObject("System.Collections.ArrayList")
set key_list.add "{F13}"
set key_list.add "{F14}"
set key_list.add "{F15}"
set key_list.add "{SCROLLLOCK}"

set min_seconds = 45
set max_seconds = 60 * 2.3 ' 2.3 Minutes


set objShell = WScript.CreateObject("WScript.Shell")

Do While True
  Randomize
  key_index = Int(((key_list.Count)-1+1)*Rnd+1)
  send_key = key_list(key_index)

  Randomize
  sleep_seconds = Int((max_seconds-min_seconds+1)*Rnd+min_seconds)

  objResult = objShell.sendkeys(send_key & send_key)
  Wscript.Sleep (sleep_seconds * 1000)
Loop
