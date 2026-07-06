# keepawake.ps1
# Windows keep-awake helper using WScript key press simulation

param(
    [Parameter(ParameterSetName='Now', Mandatory)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$Now,

    [Parameter(ParameterSetName='Today', Mandatory)]
    [switch]$Today,

    [string]$Start = "07:00",
    [string]$End   = "17:30"
)

# F13-F15 and SCROLLLOCK are chosen because most apps do not bind them
$keys        = '{F13}', '{F14}', '{F15}', '{SCROLLLOCK 2}'
$min_seconds = 45
$max_seconds = [int](60 * 2.3)

$wsh = New-Object -ComObject WScript.Shell

function Get-WorkTime([string]$timeStr) {
    $today  = (Get-Date).Date
    $parsed = [datetime]::ParseExact($timeStr, "HH:mm", $null)
    return $today.AddHours($parsed.Hour).AddMinutes($parsed.Minute)
}

if ($Today) {
    $startTime = Get-WorkTime $Start
    $endTime   = Get-WorkTime $End
    $now       = Get-Date

    if ($now -lt $startTime) {
        Write-Host "Current time is before the work window ($Start to $End). Nothing started."
        exit 0
    }
    if ($now -ge $endTime) {
        Write-Host "Current time is after the work window ($Start to $End). Nothing started."
        exit 0
    }

    $remaining = [int]($endTime - $now).TotalMinutes
    Write-Host "Keeping system awake until $End today. Remaining: $remaining minutes."
    $deadline = $endTime
} else {
    Write-Host "Keeping system awake for $Now minutes."
    $deadline = (Get-Date).AddMinutes($Now)
}

while ((Get-Date) -lt $deadline) {
    $send_key      = $keys | Get-Random
    $sleep_seconds = Get-Random -Minimum $min_seconds -Maximum $max_seconds
    $remaining_s   = [int]($deadline - (Get-Date)).TotalSeconds
    if ($remaining_s -le 0) { break }
    $sleep_seconds = [Math]::Min($sleep_seconds, $remaining_s)
    $wsh.SendKeys($send_key + $send_key)
    Start-Sleep -Seconds $sleep_seconds
}

Write-Host "Done."
