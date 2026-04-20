param(
    [Parameter(Mandatory)][string]$Path,
    [string]$Axis = 'Z',
    [int]$Slices = 20
)

$bytes = [System.IO.File]::ReadAllBytes($Path)
$triCount = [BitConverter]::ToUInt32($bytes, 80)

$vs = New-Object 'System.Collections.Generic.List[single[]]'
$offset = 84
for ($i = 0; $i -lt $triCount; $i++) {
    $base = $offset + ($i * 50) + 12
    for ($v = 0; $v -lt 3; $v++) {
        $x = [BitConverter]::ToSingle($bytes, $base + $v*12)
        $y = [BitConverter]::ToSingle($bytes, $base + $v*12 + 4)
        $z = [BitConverter]::ToSingle($bytes, $base + $v*12 + 8)
        $vs.Add([single[]]@($x,$y,$z))
    }
}

switch ($Axis.ToUpper()) {
    'X' { $idx = 0; $a = 1; $b = 2; $aN='Y'; $bN='Z' }
    'Y' { $idx = 1; $a = 0; $b = 2; $aN='X'; $bN='Z' }
    'Z' { $idx = 2; $a = 0; $b = 1; $aN='X'; $bN='Y' }
}

$min = ($vs | ForEach-Object { $_[$idx] } | Measure-Object -Minimum).Minimum
$max = ($vs | ForEach-Object { $_[$idx] } | Measure-Object -Maximum).Maximum
$step = ($max - $min) / $Slices

Write-Host ("Slicing along {0} axis: {1:F2} to {2:F2} in {3} slices of {4:F2} mm" -f $Axis, $min, $max, $Slices, $step)
Write-Host ""
Write-Host ("{0,8}  {1,7} {2,7}  {3,7} {4,7}  {5,8} {6,8}  {7,7}" -f "slice $Axis", "$aN-min", "$aN-max", "$bN-min", "$bN-max", "${aN}-span", "${bN}-span", "vcount")

for ($s = 0; $s -lt $Slices; $s++) {
    $lo = $min + $s * $step
    $hi = $lo + $step
    $slice = $vs | Where-Object { $_[$idx] -ge $lo -and $_[$idx] -lt $hi }
    if ($slice.Count -gt 0) {
        $aMin = ($slice | ForEach-Object { $_[$a] } | Measure-Object -Minimum).Minimum
        $aMax = ($slice | ForEach-Object { $_[$a] } | Measure-Object -Maximum).Maximum
        $bMin = ($slice | ForEach-Object { $_[$b] } | Measure-Object -Minimum).Minimum
        $bMax = ($slice | ForEach-Object { $_[$b] } | Measure-Object -Maximum).Maximum
        Write-Host ("{0,8:F1}  {1,7:F1} {2,7:F1}  {3,7:F1} {4,7:F1}  {5,8:F1} {6,8:F1}  {7,7}" -f
            (($lo+$hi)/2), $aMin, $aMax, $bMin, $bMax, ($aMax-$aMin), ($bMax-$bMin), $slice.Count)
    }
}
