$content = Get-Content 'C:\Users\Adventnl\orbit-cloud\setup-wizard\setup-wizard.ps1' -Raw
$pattern = '[^\x00-\x7F]'
$matches2 = [regex]::Matches($content, $pattern)
foreach ($m in $matches2) {
    $charVal = [int]$m.Value[0]
    $pos = $m.Index
    $start = [Math]::Max(0, $pos - 15)
    $len = [Math]::Min(40, $content.Length - $start)
    $context = $content.Substring($start, $len) -replace "`r?`n", "\\n"
    Write-Host ("Pos: {0}, Char: U+{1:X4}, Context: {2}" -f $pos, $charVal, $context)
}
Write-Host "Total non-ASCII characters found: $($matches2.Count)"
