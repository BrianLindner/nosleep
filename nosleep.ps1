
# the list of Keys to select from
$keys = '{F13}', '{F14}', '{F15}', '{SCROLLLOCK 2}'

$min_seconds = 45
$max _seconds = 60 * 2.3  # 2.3 minutes

$wsh = New-Object -ComObject WScript.Shell

while (1) {
  $send_key = $keys | Get-Random
  $sleep_seconds = Get-Random -Minimum $min_seconds -Maximum $max_seconds

  $wsh.SendKeys($send_key + $send_key)
  Start-Sleep -seconds ($sleep_seconds)
}
