param(
  [string]$xlsxPath,
  [string]$csvPath,
  [string]$output = "L:\Acqua Site\Antigo\java-app\data\products.json",
  [switch]$seedDb
)

$ErrorActionPreference = "Stop"

function Get-Field {
  param($row, [string[]]$names)
  foreach($n in $names){
    if($null -ne $row -and $row.PSObject.Properties.Match($n).Count -gt 0){
      $v = $row.$n
      if($null -ne $v -and ([string]$v).Trim().Length -gt 0){ return $v }
    }
  }
  return $null
}

function Map-Row {
  param($row)
  $idVal = Get-Field -row $row -names @("id","ID","Id")
  $id = 0
  if($idVal){ [int]::TryParse([string]$idVal, [ref]$id) | Out-Null }
  if(-not $id -or $id -le 0){ return $null }
  $sku  = [string](Get-Field -row $row -names @("SKU","sku")) 
  $ean  = [string](Get-Field -row $row -names @("EAN","ean")) 
  $nome = [string](Get-Field -row $row -names @("nome","Nome","Name"))
  $sku = $sku.Trim()
  $ean = $ean.Trim()
  $nome = $nome.Trim()

  $precoRaw = (Get-Field -row $row -names @("preco","Preco","Preço","price"))
  if ($precoRaw -is [string]) {
    $precoStr = ($precoRaw -replace "\.","") -replace ",","."
    [double]$preco = 0
    [void][double]::TryParse($precoStr, [ref]$preco)
  } else {
    $preco = [double]$precoRaw
  }
  $qtdeVal = Get-Field -row $row -names @("qtde","Qtde","estoque")
  [int]$qtde = 0
  if($qtdeVal){ [int]::TryParse([string]$qtdeVal, [ref]$qtde) | Out-Null }
  $unid = [string](Get-Field -row $row -names @("unid","Unid")); $unid=$unid.Trim()
  $cat  = [string](Get-Field -row $row -names @("cat","categoria","Categoria")); $cat=$cat.Trim()
  $marca= [string](Get-Field -row $row -names @("marca","Marca")); $marca=$marca.ToUpper().Trim()
  $desc = [string](Get-Field -row $row -names @("Descrição Anuncio","descricaoAnuncio","descricao","description")); $desc=$desc.Trim()
  $imgs = @()
  for($i=1;$i -le 5;$i++){
    $v = Get-Field -row $row -names @("img $i","img$i")
    if($v){ $u = [string]$v; $u = $u.Replace('`','').Replace("'",'').Replace('"','').Trim(); if($u){ $imgs += $u } }
  }
  if($imgs.Count -eq 0){
    $v = Get-Field -row $row -names @("img","imagem","Imagem")
    if($v){ $u = [string]$v; $u = $u.Replace('`','').Replace("'",'').Replace('"','').Trim(); if($u){ $imgs += $u } }
  }
  $img = $null
  if($imgs.Count -gt 0){ $img = $imgs[0] }
  [pscustomobject]@{
    id=$id; sku=$sku; ean=$ean; nome=$nome; preco=$preco; qtde=$qtde; unid=$unid;
    cat=$cat; marca=$marca; descricao=$desc; img=$img; imgs=$imgs
  }
}

function Save-Json {
  param($items, $path)
  $json = $items | ConvertTo-Json -Depth 6
  $folder = Split-Path -Parent $path
  if(!(Test-Path $folder)){ New-Item -ItemType Directory -Path $folder | Out-Null }
  Set-Content -Path $path -Value $json -Encoding UTF8
  Write-Host "Gerado: $path" -ForegroundColor Green
}

function Save-SQL {
  param($items, $path)
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("CREATE TABLE IF NOT EXISTS products (id BIGINT PRIMARY KEY, sku VARCHAR(64), ean VARCHAR(32), nome VARCHAR(255), preco DOUBLE, qtde INT, unid VARCHAR(16), cat VARCHAR(64), marca VARCHAR(64), descricao CLOB, img VARCHAR(1024), imgs CLOB);")
  foreach($p in $items){
    $f = @{
      id = $p.id
      sku = ($p.sku -replace "'","''")
      ean = ($p.ean -replace "'","''")
      nome = ($p.nome -replace "'","''")
      preco = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0}", $p.preco)
      qtde = $p.qtde
      unid = ($p.unid -replace "'","''")
      cat  = ($p.cat -replace "'","''")
      marca= ($p.marca -replace "'","''")
      desc = ($p.descricao -replace "'","''")
      img  = ($p.img -replace "'","''")
      imgs = ((($p.imgs -join ",") -replace "'","''"))
    }
    $sql = "MERGE INTO products (id,sku,ean,nome,preco,qtde,unid,cat,marca,descricao,img,imgs) KEY(id) VALUES (" +
      "$($f.id), '$($f.sku)', '$($f.ean)', '$($f.nome)', $($f.preco), $($f.qtde), '$($f.unid)', '$($f.cat)', '$($f.marca)', '$($f.desc)', '$($f.img)', '$($f.imgs)');"
    [void]$sb.AppendLine($sql)
  }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $sb.ToString(), $utf8NoBom)
  Write-Host "Gerado SQL: $path" -ForegroundColor Green
}

if(-not $xlsxPath){
  $candidatos = @(
    "L:\Acqua Site\Antigo\produto.xlsx",
    "L:\Acqua Site\Antigo\produto.xls",
    "L:\Acqua Site\Antigo\produto.xlsm",
    "L:\Acqua Site\Antigo\produto.xlsxa",
    "L:\Acqua Site\Antigo\produtos\produtos.xlsx",
    "L:\Acqua Site\Antigo\produtos\produto.xlsx",
    "L:\Acqua Site\Antigo\produtos.xlsx"
  )
  $xlsxPath = $candidatos | Where-Object { Test-Path $_ } | Select-Object -First 1
  if(-not $xlsxPath){
    $lookups = @("L:\Acqua Site\Antigo","L:\Acqua Site\Antigo\produtos")
    foreach($dir in $lookups){
      if(Test-Path $dir){
        $found = Get-ChildItem -Path $dir -File -Filter "produto.*" -ErrorAction SilentlyContinue |
          Where-Object { $_.Extension -in ".xlsx",".xls",".xlsm",".xlsxa" } |
          Select-Object -First 1
        if($found){ $xlsxPath = $found.FullName; break }
      }
    }
  }
  if($xlsxPath -and $xlsxPath.ToLower().EndsWith(".xlsxa")){
    $fixed = [System.IO.Path]::ChangeExtension($xlsxPath, ".xlsx")
    try {
      Copy-Item -Path $xlsxPath -Destination $fixed -Force
      $xlsxPath = $fixed
      Write-Warning "Arquivo com extensão .xlsxa detectado. Usando cópia: $xlsxPath"
    } catch {
      Write-Warning "Falha ao ajustar extensão .xlsxa: $_"
    }
  }
}

if(-not $csvPath){
  $csvCand = @(
    "L:\Acqua Site\Antigo\produtos.csv",
    "L:\Acqua Site\Antigo\produtos\produtos.csv"
  )
  $csvPath = $csvCand | Where-Object { Test-Path $_ } | Select-Object -First 1
}

$items = @()

if($xlsxPath -and (Test-Path $xlsxPath)){
  $hasImportExcel = Get-Module -ListAvailable -Name ImportExcel | Select-Object -First 1
  if($hasImportExcel){
    $rows = Import-Excel -Path $xlsxPath
    foreach($r in $rows){
      $m = Map-Row -row $r
      if($m){ $items += $m }
    }
    Save-Json -items $items -path $output
    if($seedDb){
      $sqlFile = "L:\Acqua Site\Antigo\java-app\data\seed.sql"
      Save-SQL -items $items -path $sqlFile
      $lib = "L:\Acqua Site\Antigo\java-app\lib"
      $h2 = Join-Path $lib "h2.jar"
      if (!(Test-Path $lib)) { New-Item -ItemType Directory -Path $lib | Out-Null }
      if (!(Test-Path $h2)) {
        $url = "https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar"
        Invoke-WebRequest -Uri $url -OutFile $h2 -UseBasicParsing
      }
      $jdbc = "jdbc:h2:file:L:/Acqua Site/Antigo/java-app/data/acqua;AUTO_SERVER=TRUE;MODE=MySQL;DATABASE_TO_UPPER=false"
      & java -cp "$h2" org.h2.tools.RunScript -url "$jdbc" -user sa -password "" -script "$sqlFile"
      Write-Host "Banco de dados atualizado com produtos." -ForegroundColor Green
    }
    exit 0
  }
  try{
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $wb = $excel.Workbooks.Open($xlsxPath)
    $ws = $wb.Worksheets.Item(1)
    $used = $ws.UsedRange
    $rows = $used.Rows.Count
    $cols = $used.Columns.Count
    $headers = @()
    for($c=1;$c -le $cols;$c++){ $headers += [string]$used.Cells.Item(1,$c).Text }
    for($r=2;$r -le $rows;$r++){
      $obj = @{}
      for($c=1;$c -le $cols;$c++){
        $h = $headers[$c-1]
        if([string]::IsNullOrWhiteSpace($h)){ continue }
        $obj[$h] = $used.Cells.Item($r,$c).Text
      }
      $m = Map-Row -row ([pscustomobject]$obj)
      if($m){ $items += $m }
    }
    $wb.Close($false)
    $excel.Quit()
    try{ [System.Runtime.Interopservices.Marshal]::ReleaseComObject($used) | Out-Null } catch {}
    try{ [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ws) | Out-Null } catch {}
    try{ [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) | Out-Null } catch {}
    try{ [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null } catch {}
    Save-Json -items $items -path $output
    if($seedDb){
      $sqlFile = "L:\Acqua Site\Antigo\java-app\data\seed.sql"
      Save-SQL -items $items -path $sqlFile
      $lib = "L:\Acqua Site\Antigo\java-app\lib"
      $h2 = Join-Path $lib "h2.jar"
      if (!(Test-Path $lib)) { New-Item -ItemType Directory -Path $lib | Out-Null }
      if (!(Test-Path $h2)) {
        $url = "https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar"
        Invoke-WebRequest -Uri $url -OutFile $h2 -UseBasicParsing
      }
      $jdbc = "jdbc:h2:file:L:/Acqua Site/Antigo/java-app/data/acqua;AUTO_SERVER=TRUE;MODE=MySQL;DATABASE_TO_UPPER=false"
      & java -cp "$h2" org.h2.tools.RunScript -url "$jdbc" -user sa -password "" -script "$sqlFile"
      Write-Host "Banco de dados atualizado com produtos." -ForegroundColor Green
    }
    exit 0
  } catch {
    Write-Warning "Falha ao usar COM Excel: $_"
  }
}

if($csvPath -and (Test-Path $csvPath)){
  $rows = Import-Csv -Path $csvPath
  foreach($r in $rows){
    $m = Map-Row -row $r
    if($m){ $items += $m }
  }
  Save-Json -items $items -path $output
  if($seedDb){
    $sqlFile = "L:\Acqua Site\Antigo\java-app\data\seed.sql"
    Save-SQL -items $items -path $sqlFile
    $lib = "L:\Acqua Site\Antigo\java-app\lib"
    $h2 = Join-Path $lib "h2.jar"
    if (!(Test-Path $lib)) { New-Item -ItemType Directory -Path $lib | Out-Null }
    if (!(Test-Path $h2)) {
      $url = "https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar"
      Invoke-WebRequest -Uri $url -OutFile $h2 -UseBasicParsing
    }
    $jdbc = "jdbc:h2:file:L:/Acqua Site/Antigo/java-app/data/acqua;AUTO_SERVER=TRUE;MODE=MySQL;DATABASE_TO_UPPER=false"
    & java -cp "$h2" org.h2.tools.RunScript -url "$jdbc" -user sa -password "" -script "$sqlFile"
    Write-Host "Banco de dados atualizado com produtos." -ForegroundColor Green
  }
  exit 0
}

Write-Error "Nenhum arquivo Excel/CSV encontrado. Coloque 'produtos.xlsx' ou 'produtos.csv' na pasta e rode novamente."
