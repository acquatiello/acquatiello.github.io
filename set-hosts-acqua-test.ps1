param()

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
Write-Host "Arquivo hosts: $hostsPath"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) {
  Write-Error "Execute este script como Administrador (clique com o botão direito > Run with PowerShell)"
  exit 1
}

if (!(Test-Path $hostsPath)) {
  Write-Error "Arquivo hosts não encontrado em $hostsPath"
  exit 1
}

$content = Get-Content -Raw $hostsPath
$changed = $false

if ($content -notmatch '(?im)^\s*127\.0\.0\.1\s+.*\bacqua\.test\b') {
  Add-Content -Path $hostsPath -Value "`r`n127.0.0.1`tacqua.test"
  $changed = $true
  Write-Host "Adicionado: 127.0.0.1  acqua.test"
}
if ($content -notmatch '(?im)^\s*::1\s+.*\bacqua\.test\b') {
  Add-Content -Path $hostsPath -Value "`r`n::1`tacqua.test"
  $changed = $true
  Write-Host "Adicionado: ::1  acqua.test"
}

if (-not $changed) {
  Write-Host "Hosts já contém acqua.test"
}

Write-Host "Concluído. Você pode rodar: ipconfig /flushdns"
