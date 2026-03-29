param()

$conf = 'C:\xampp\apache\conf\extra\httpd-xampp.conf'
if (!(Test-Path $conf)) {
  Write-Error "Arquivo de config não encontrado: $conf"
  exit 1
}

try {
  $content = Get-Content -Raw $conf
} catch {
  Write-Error ("Falha ao ler {0}: {1}" -f $conf, $_)
  exit 1
}

$block = @"

# Acqua alias (auto)
Alias /acqua "L:/Acqua Site/Antigo"
<Directory "L:/Acqua Site/Antigo">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
"@

if ($content -notmatch 'Alias\s+/acqua') {
  try {
    Add-Content -Path $conf -Value $block
    Write-Host "Alias /acqua adicionado"
  } catch {
    Write-Error ("Falha ao escrever no arquivo de configuração: {0}" -f $_)
    exit 1
  }
} else {
  Write-Host "Alias /acqua já existe"
}

# Testa a configuração
try {
  $testOut = & 'C:\xampp\apache\bin\httpd.exe' -t 2>&1
  Write-Host $testOut
} catch {
  Write-Error ("Falha ao testar configuração do Apache: {0}" -f $_)
}

# Reinicia o Apache
if ((Test-Path 'C:\xampp\apache_stop.bat') -and (Test-Path 'C:\xampp\apache_start.bat')) {
  & 'C:\xampp\apache_stop.bat' | Out-Null
  Start-Sleep -Seconds 2
  & 'C:\xampp\apache_start.bat' | Out-Null
  Write-Host "Apache reiniciado via XAMPP .bat"
} else {
  try {
    & 'C:\xampp\apache\bin\httpd.exe' -k restart | Out-Null
    Write-Host "Apache reiniciado via httpd -k restart"
  } catch {
    Write-Host "Não foi possível reiniciar automaticamente. Reinicie pelo XAMPP Control Panel."
  }
}

# Descobre portas em uso pelo Apache
$ports = Get-NetTCPConnection -State Listen | Where-Object {
  try { (Get-Process -Id $_.OwningProcess -ErrorAction Stop).ProcessName -eq 'httpd' } catch { $false }
} | Select-Object -ExpandProperty LocalPort -Unique

Write-Host ("PORTS=" + ($ports -join ',')) 
