param(
  [string]$sourceFolder = "L:\Acqua Site\Antigo",
  [string]$zipFile      = "L:\Acqua Site\Antigo\backup-acqua-site-php.zip"
)

if (!(Test-Path $sourceFolder)) {
  Write-Error "Pasta de origem não encontrada: $sourceFolder"
  exit 1
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

if (Test-Path $zipFile) {
  Remove-Item $zipFile -Force
}

$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
[System.IO.Compression.ZipFile]::CreateFromDirectory($sourceFolder, $zipFile, $compressionLevel, $false)

Write-Host "Backup concluído: $zipFile" -ForegroundColor Green