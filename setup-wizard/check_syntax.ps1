$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    'C:\Users\Adventnl\orbit-cloud\setup-wizard\setup-wizard.ps1',
    [ref]$tokens,
    [ref]$errors
)
if ($errors.Count -eq 0) {
    Write-Host "PARSE OK - no syntax errors found"
} else {
    Write-Host "PARSE ERRORS:"
    foreach ($err in $errors) {
        Write-Host ("  Line {0}: {1}" -f $err.Extent.StartLineNumber, $err.Message)
    }
}
