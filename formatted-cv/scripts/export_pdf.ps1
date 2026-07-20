[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputDocx,

    [Parameter(Mandatory = $true)]
    [string]$OutputPdf,

    [ValidateRange(10, 300)]
    [int]$ComTimeoutSeconds = 60,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$inputPath = (Resolve-Path -LiteralPath $InputDocx).Path
if ([IO.Path]::GetExtension($inputPath) -ne '.docx') {
    throw 'InputDocx must be a .docx file.'
}

$outputPath = [IO.Path]::GetFullPath($OutputPdf)
if ([IO.Path]::GetExtension($outputPath) -ne '.pdf') {
    throw 'OutputPdf must end in .pdf.'
}
if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
    throw "Output already exists: $outputPath"
}
$outputDirectory = Split-Path $outputPath -Parent
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
if (Test-Path -LiteralPath $outputPath) {
    Remove-Item -LiteralPath $outputPath -Force
}

$ensureScript = Join-Path $PSScriptRoot 'ensure_libreoffice.ps1'
$libreOffice = (& $ensureScript | ConvertFrom-Json)

function Invoke-ComExport {
    param(
        [string]$ProgId,
        [string]$EngineName
    )

    $job = Start-Job -ScriptBlock {
        param($JobProgId, $JobInput, $JobOutput, $JobEngine)
        $app = $null
        $document = $null
        try {
            $app = New-Object -ComObject $JobProgId
            $app.Visible = $false
            try { $app.DisplayAlerts = 0 } catch {}
            $document = $app.Documents.Open($JobInput, $false, $true)
            $pages = $document.ComputeStatistics(2)
            $document.ExportAsFixedFormat($JobOutput, 17)
            [pscustomobject]@{ engine = $JobEngine; page_count = $pages }
        } finally {
            if ($document) { $document.Close(0) }
            if ($app) { $app.Quit() }
            if ($document) { [Runtime.InteropServices.Marshal]::FinalReleaseComObject($document) | Out-Null }
            if ($app) { [Runtime.InteropServices.Marshal]::FinalReleaseComObject($app) | Out-Null }
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
        }
    } -ArgumentList $ProgId, $inputPath, $outputPath, $EngineName

    try {
        if (-not (Wait-Job -Job $job -Timeout $ComTimeoutSeconds)) {
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            return $null
        }
        if ($job.State -ne 'Completed') {
            return $null
        }
        return (Receive-Job -Job $job -ErrorAction Stop | Select-Object -Last 1)
    } catch {
        return $null
    } finally {
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    }
}

$result = Invoke-ComExport -ProgId 'KWPS.Application' -EngineName 'WPS'
if (-not $result) {
    if (Test-Path -LiteralPath $outputPath) { Remove-Item -LiteralPath $outputPath -Force }
    $result = Invoke-ComExport -ProgId 'Word.Application' -EngineName 'Microsoft Word'
}

if (-not $result) {
    if (Test-Path -LiteralPath $outputPath) { Remove-Item -LiteralPath $outputPath -Force }
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $tempRoot = Join-Path $tempBase ('formatted-cv-lo-' + [guid]::NewGuid().ToString('N'))
    $profileDirectory = Join-Path $tempRoot 'profile'
    $convertDirectory = Join-Path $tempRoot 'output'
    New-Item -ItemType Directory -Force -Path $profileDirectory, $convertDirectory | Out-Null
    try {
        $profileUri = 'file:///' + ($profileDirectory -replace '\\', '/')
        $nativeOutput = (& $libreOffice.path ('-env:UserInstallation=' + $profileUri) --headless --norestore --convert-to pdf --outdir $convertDirectory $inputPath 2>&1 | Out-String).Trim()
        $producedPdf = Join-Path $convertDirectory ([IO.Path]::GetFileNameWithoutExtension($inputPath) + '.pdf')
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $producedPdf)) {
            throw "LibreOffice PDF export failed: $nativeOutput"
        }
        Move-Item -LiteralPath $producedPdf -Destination $outputPath
        $result = [pscustomobject]@{ engine = 'LibreOffice'; page_count = $null }
    } finally {
        $resolvedTempRoot = [IO.Path]::GetFullPath($tempRoot)
        if ($resolvedTempRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTempRoot)) {
            Remove-Item -LiteralPath $resolvedTempRoot -Recurse -Force
        }
    }
}

if (-not (Test-Path -LiteralPath $outputPath) -or (Get-Item -LiteralPath $outputPath).Length -eq 0) {
    throw 'No PDF export engine produced a usable output file.'
}

[pscustomobject]@{
    output = $outputPath
    engine = $result.engine
    page_count = $result.page_count
    libreoffice_version = $libreOffice.version
} | ConvertTo-Json -Compress
