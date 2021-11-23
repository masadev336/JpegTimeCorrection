Param (
  [Parameter(mandatory=$true)][String]$inputDir,
  [Parameter(mandatory=$true)][String]$outputDir,
  [Parameter(mandatory=$true)][Int]$CorrectionValue
)
Add-Type -AssemblyName "System.Drawing"

# 既に$idで指定したPropertyItemが存在する場合、そのPropertyItemは削除する。
# $imageオブジェクトより先頭のPropertyItemオブジェクトを返す。
function GetPropertyItem($image, $id)
{
  $item = $image.PropertyItems | Where-Object { $_.Id -eq $id }
  if($item -ne $null) {
    $image.RemovePropertyItem($id)
  }
  return $image.PropertyItems | Select-Object -First 1
}

# $imageオブジェクトにPropertyItemを登録する。
function SetPropertyItem($image, $id, $len, $type, $value)
{
  $item = GetPropertyItem -image $image -id $id
  $item.Id = $id
  $item.Len = $len
  $item.Type = $type
  $item.Value = $value
  $image.SetPropertyItem($item)
}

# $dateTimeで指定した撮影日時よりExif用配列データを取得する。
function getDateTimeValue($dateTime)
{
  $chars = $dateTime.ToString("yyyy:MM:dd HH:mm:ss").ToCharArray()
  $ascii = @()
  foreach($char in $chars)
  {
    $ascii += [Byte][Char]$char
  }
  $ascii += 0
  return $ascii
}

# $imageオブジェクトに撮影日時PropertyItemを登録する。
function SetDateTime($image, $dateTime)
{
  $value = getDateTimeValue -dateTime $dateTime
  SetPropertyItem -image $image -id 0x9003 -len 20 -type 2 -value $value
  SetPropertyItem -image $image -id 0x9004 -len 20 -type 2 -value $value
}

# Exif情報登録
# $inputFileで指定したファイルに$dateTimeで指定したExif撮影日時を付加し$outputDirへ保存する。
# 保存したファイルのフルパスを返す。
function SetExifInfo($inputFile, $outputDir, $dateTime)
{
  $image = New-Object System.Drawing.Bitmap($inputFile)
  # SetExifVersion -image $image
  SetDateTime -image $image -dateTime $dateTime

  $outputFile = Join-Path $outputDir (Split-Path $inputFile -Leaf)
  $image.Save($outputFile)

  $image.Dispose()

  return $outputFile
}


# メイン処理
$files = Get-ChildItem -Path $inputDir\*.* -Include *.jpg,*.jpeg

foreach ($file in $files)
{
  try {
    $fileDate = (Get-ItemProperty -Path $file).LastWriteTime.AddMinutes($CorrectionValue)
    $outputFile = SetExifInfo -inputFile $file.FullName -outputDir $outputDir -dateTime $fileDate
    Set-ItemProperty $outputFile -Name LastWriteTime -Value $fileDate
    Write-Host( "[OK] " + $file.Name + " " + $fileDate)
  } catch {
    Write-Host( "[ER] " + $file.Name + "`r`n" + $_)
  }
}

# ここまで
