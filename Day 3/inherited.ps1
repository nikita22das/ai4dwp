$c = Get-CimInstance Win32_ComputerSystem
$d = Get-PSDrive C | Select-Object -ExpandProperty Free
$p = Get-Process | Sort-Object WS -Descending | Select-Object -First 5
$e = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object {$_.Level -eq 2}
$u = Get-CimInstance Win32_UserProfile | Where-Object {
     -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)}
Write-Host $c.Name $c.TotalPhysicalMemory
Write-Host ([math]::Round($d/1GB,2)) 'GB free'
$p | ForEach-Object { Write-Host $_.Name $_.WS }
$e | ForEach-Object { Write-Host $_.TimeCreated $_.Message }
if ($u.Count -gt 0) { Write-Host 'Stale profiles:' $u.Count }
