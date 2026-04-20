param([Parameter(Mandatory)][string]$Path)

$bytes = [System.IO.File]::ReadAllBytes($Path)
$triCount = [BitConverter]::ToUInt32($bytes, 80)

$minX = $maxX = $null
$minY = $maxY = $null
$minZ = $maxZ = $null

$xs = New-Object System.Collections.Generic.List[single]
$ys = New-Object System.Collections.Generic.List[single]
$zs = New-Object System.Collections.Generic.List[single]

$offset = 84
for ($i = 0; $i -lt $triCount; $i++) {
    $base = $offset + ($i * 50) + 12  # skip normal vec3
    for ($v = 0; $v -lt 3; $v++) {
        $x = [BitConverter]::ToSingle($bytes, $base + $v*12)
        $y = [BitConverter]::ToSingle($bytes, $base + $v*12 + 4)
        $z = [BitConverter]::ToSingle($bytes, $base + $v*12 + 8)
        $xs.Add($x); $ys.Add($y); $zs.Add($z)
        if ($null -eq $minX -or $x -lt $minX) { $minX = $x }
        if ($null -eq $maxX -or $x -gt $maxX) { $maxX = $x }
        if ($null -eq $minY -or $y -lt $minY) { $minY = $y }
        if ($null -eq $maxY -or $y -gt $maxY) { $maxY = $y }
        if ($null -eq $minZ -or $z -lt $minZ) { $minZ = $z }
        if ($null -eq $maxZ -or $z -gt $maxZ) { $maxZ = $z }
    }
}

Write-Host ("File:       {0}" -f (Split-Path $Path -Leaf))
Write-Host ("Triangles:  {0}" -f $triCount)
Write-Host ("Vertices:   {0} (with duplicates)" -f $xs.Count)
Write-Host ""
Write-Host "Bounding box (mm):"
Write-Host ("  X: {0,8:F2} .. {1,8:F2}   width  = {2,7:F2}" -f $minX, $maxX, ($maxX-$minX))
Write-Host ("  Y: {0,8:F2} .. {1,8:F2}   depth  = {2,7:F2}" -f $minY, $maxY, ($maxY-$minY))
Write-Host ("  Z: {0,8:F2} .. {1,8:F2}   height = {2,7:F2}" -f $minZ, $maxZ, ($maxZ-$minZ))
Write-Host ""

# Histogram of Z values (heights) to find distinct horizontal planes
$zHist = @{}
foreach ($z in $zs) {
    $bucket = [Math]::Round($z, 1)
    if ($zHist.ContainsKey($bucket)) { $zHist[$bucket]++ } else { $zHist[$bucket] = 1 }
}
Write-Host "Top 10 Z-planes by vertex density (candidate shelves/tabs):"
$zHist.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 |
    ForEach-Object { Write-Host ("  Z = {0,7:F1}   count = {1}" -f $_.Key, $_.Value) }
Write-Host ""

# Histogram of Y values
$yHist = @{}
foreach ($y in $ys) {
    $bucket = [Math]::Round($y, 1)
    if ($yHist.ContainsKey($bucket)) { $yHist[$bucket]++ } else { $yHist[$bucket] = 1 }
}
Write-Host "Top 10 Y-planes by vertex density (candidate faces):"
$yHist.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 |
    ForEach-Object { Write-Host ("  Y = {0,7:F1}   count = {1}" -f $_.Key, $_.Value) }
