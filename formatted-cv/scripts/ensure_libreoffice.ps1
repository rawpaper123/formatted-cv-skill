[CmdletBinding()]
param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'

function Find-LibreOffice {
    $candidates = @()
    foreach ($commandName in @('soffice.com', 'soffice.exe')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) {
            $candidates += $command.Source
        }
    }
    $candidates += @(
        'C:\Program Files\LibreOffice\program\soffice.com',
        'C:\Program Files\LibreOffice\program\soffice.exe',
        'C:\Program Files (x86)\LibreOffice\program\soffice.com',
        'C:\Program Files (x86)\LibreOffice\program\soffice.exe'
    )

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return $null
}

$soffice = Find-LibreOffice
$installedNow = $false

if (-not $soffice) {
    if ($CheckOnly) {
        throw 'LibreOffice is required but is not installed.'
    }

    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'LibreOffice is required and winget is unavailable. Install LibreOffice, then run this check again.'
    }

    $arguments = @(
        'install',
        '--id', 'TheDocumentFoundation.LibreOffice',
        '--exact',
        '--silent',
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--disable-interactivity'
    )
    $installer = Start-Process -FilePath $winget.Source -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru

    for ($attempt = 0; $attempt -lt 12 -and -not $soffice; $attempt++) {
        Start-Sleep -Seconds 5
        $soffice = Find-LibreOffice
    }
    if (-not $soffice) {
        throw "LibreOffice installation failed (winget exit $($installer.ExitCode))."
    }
    $installedNow = $true
}

$versionText = (& $soffice --version 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or -not $versionText) {
    throw "LibreOffice exists but failed its version check: $soffice"
}

[pscustomobject]@{
    path = $soffice
    version = $versionText
    installed_now = $installedNow
} | ConvertTo-Json -Compress
