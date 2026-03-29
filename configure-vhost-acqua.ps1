param(
  [string]$DocRoot = "L:/Acqua Site/Antigo",
  [int]$Port = 8080,
  [string]$ServerName = "acqua.local"
)

$httpdConf = 'C:\xampp\apache\conf\httpd.conf'
$vhostsConf = 'C:\xampp\apache\conf\extra\httpd-vhosts.conf'
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"

function Ensure-VHostsIncluded {
  if (!(Test-Path $httpdConf)) { Write-Error "httpd.conf não encontrado: $httpdConf"; return $false }
  $txt = Get-Content -Raw $httpdConf
  $pattern = '^\s*#\s*Include\s+conf/extra/httpd-vhosts\.conf\s*$'
  if ($txt -match $pattern) {
    $new = ($txt -split "`r?`n") | ForEach-Object {
      if ($_ -match $pattern) { 'Include conf/extra/httpd-vhosts.conf' } else { $_ }
    } | Out-String
    Set-Content -Path $httpdConf -Value $new -Encoding Ascii
    Write-Host "Include de vhosts habilitado"
  } elseif ($txt -notmatch 'Include\s+conf/extra/httpd-vhosts\.conf') {
    Add-Content -Path $httpdConf -Value "`r`nInclude conf/extra/httpd-vhosts.conf"
    Write-Host "Include de vhosts adicionado"
  } else {
    Write-Host "Include de vhosts já habilitado"
  }
  return $true
}

function Ensure-VHost {
  if (!(Test-Path $vhostsConf)) { Write-Error "vhosts conf não encontrado: $vhostsConf"; return $false }
  $vtxt = Get-Content -Raw $vhostsConf
  if ($vtxt -notmatch "ServerName\s+$([regex]::Escape($ServerName))") {
    $block = @"

<VirtualHost *:$Port>
    ServerName $ServerName
    DocumentRoot "$DocRoot"
    <Directory "$DocRoot">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    DirectoryIndex index.php index.html
</VirtualHost>
"@
    Add-Content -Path $vhostsConf -Value $block
    Write-Host "VirtualHost $ServerName adicionado na porta $Port"
  } else {
    Write-Host "VirtualHost $ServerName já existe"
  }
  return $true
}

function Ensure-Hosts {
  try {
    $h = Get-Content -Raw $hostsFile -ErrorAction Stop
    if ($h -notmatch "^\s*127\.0\.0\.1\s+$([regex]::Escape($ServerName))\s*$" -and $h -notmatch "^\s*127\.0\.0\.1\s+.*\b$([regex]::Escape($ServerName))\b") {
      Add-Content -Path $hostsFile -Value "`r`n127.0.0.1`t$ServerName"
      Write-Host "Entrada adicionada em hosts: 127.0.0.1 $ServerName"
    } else {
      Write-Host "Hosts já contém $ServerName"
    }
    return $true
  } catch {
    Write-Warning "Não foi possível editar o arquivo hosts (permissões). Adicione manualmente: 127.0.0.1 $ServerName"
    return $false
  }
}

if (!(Ensure-VHostsIncluded)) { exit 1 }
if (!(Ensure-VHost)) { exit 1 }
Ensure-Hosts | Out-Null

# Testa configuração do Apache
try {
  $out = & 'C:\xampp\apache\bin\httpd.exe' -t 2>&1
  Write-Host $out
} catch {
  Write-Error "Falha ao validar Apache: $_"
}

# Reinicia Apache
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

Write-Host ("OK: acesse http://{0}:{1}/" -f $ServerName, $Port)
