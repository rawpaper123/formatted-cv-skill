param()

$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path $PSScriptRoot -Parent
$ensureScript = Join-Path $PSScriptRoot 'ensure_libreoffice.ps1'
$exportScript = Join-Path $PSScriptRoot 'export_pdf.ps1'
$macEnsureScript = Join-Path $PSScriptRoot 'ensure_libreoffice.sh'
$macExportScript = Join-Path $PSScriptRoot 'export_pdf.sh'
$macSelfTest = Join-Path $PSScriptRoot 'self_test.sh'
$referenceDocx = Join-Path $skillRoot 'assets\reference.docx'
$testPdf = Join-Path ([IO.Path]::GetTempPath()) 'formatted-cv-self-test.pdf'

if (Test-Path -LiteralPath $testPdf) {
    Remove-Item -LiteralPath $testPdf -Force
}

foreach ($required in @($ensureScript, $exportScript, $macEnsureScript, $macExportScript, $macSelfTest, $referenceDocx)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing required implementation: $required"
    }
}

$libreOffice = (& $ensureScript -CheckOnly | ConvertFrom-Json)
if (-not $libreOffice.path -or -not $libreOffice.version) {
    throw 'LibreOffice check did not return a usable path and version.'
}

$missingInputFailed = $false
try {
    & $exportScript -InputDocx (Join-Path $skillRoot 'assets\missing.docx') -OutputPdf $testPdf | Out-Null
} catch {
    $missingInputFailed = $true
}
if (-not $missingInputFailed) {
    throw 'PDF export must reject a missing DOCX input.'
}

$export = (& $exportScript -InputDocx $referenceDocx -OutputPdf $testPdf | ConvertFrom-Json)
if (-not (Test-Path -LiteralPath $testPdf) -or (Get-Item -LiteralPath $testPdf).Length -eq 0) {
    throw 'PDF export did not create a non-empty file.'
}
if ($export.engine -in @('WPS', 'Microsoft Word') -and $export.page_count -ne 4) {
    throw "Expected the retained reference to export as 4 pages, got $($export.page_count)."
}

Remove-Item -LiteralPath $testPdf -Force
[pscustomobject]@{
    libreoffice_version = $libreOffice.version
    export_engine = $export.engine
    reference_pages = $export.page_count
    status = 'pass'
} | ConvertTo-Json -Compress
