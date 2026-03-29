param()

$httpdConf = 'C:\xampp\apache\conf\httpd.conf'
$extraDir  = 'C:\xampp\apache\conf\extra'
$vhostFile = Join-Path $extraDir 'httpd-vhosts-acqua.conf'

if (!(Test-Path $httpdConf)) {
  Write-Error "httpd.conf não encontrado: $httpdConf"
  exit 1
}
if (!(Test-Path $extraDir)) {
  Write-Error "Pasta extra não encontrada: $extraDir"
  exit 1
}

try {
  $txt = Get-Content -Raw $httpdConf
} catch {
  Write-Error ("Falha ao ler {0}: {1}" -f $httpdConf, $_)
  exit 1
}

$lines = $txt -split "`r?`n"
$changed = $false
# Garantir módulos de proxy habilitados
for ($i=0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match '^\s*#\s*LoadModule\s+proxy_module\s+modules/mod_proxy\.so\s*$') {
    $lines[$i] = $lines[$i] -replace '^\s*#\s*',''
    $changed = $true
  }
  if ($lines[$i] -match '^\s*#\s*LoadModule\s+proxy_http_module\s+modules/mod_proxy_http\.so\s*$') {
    $lines[$i] = $lines[$i] -replace '^\s*#\s*',''
    $changed = $true
  }
}
for ($i=0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match '^\s*Include\s+conf/extra/httpd-vhosts\.conf\s*$') {
    if ($lines[$i] -notmatch '^\s*#') {
      $lines[$i] = '# ' + $lines[$i]
      $changed = $true
    }
  }
}
if ($lines -notcontains 'Include conf/extra/httpd-vhosts-acqua.conf') {
  $lines += 'Include conf/extra/httpd-vhosts-acqua.conf'
  $changed = $true
}
if ($changed) {
  Set-Content -Path $httpdConf -Value ($lines -join "`r`n") -Encoding Ascii
  Write-Host "httpd.conf atualizado"
} else {
  Write-Host "httpd.conf já estava configurado"
}

$vhost = @"
<VirtualHost *:8080>
    ServerName acqua.test
    DocumentRoot "L:/Acqua Site/Antigo"
    <Directory "L:/Acqua Site/Antigo">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    DirectoryIndex index.php index.html
    ProxyPreserveHost On
    ProxyPass /api http://localhost:8091/api
    ProxyPassReverse /api http://localhost:8091/api
</VirtualHost>
"@

Set-Content -Path $vhostFile -Value $vhost -Encoding Ascii
Write-Host ("VHost escrito em {0}" -f $vhostFile)

& 'C:\xampp\apache\bin\httpd.exe' -t
