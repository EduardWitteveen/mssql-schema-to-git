<#
.SYNOPSIS
   Installs and configures the required tooling and sets up the environment.

.DESCRIPTION
   - Reads configuration from ExportConfig.json.
   - Verifies the current PowerShell version.
   - Attempts to install or update the latest version of dbatools (optionally into a local "bin" folder) and imports it.
   - Adjusts the execution policy for the current user to allow running downloaded modules.
   - Unblocks module files so they can be imported.
   - Disables SSL certificate validation to avoid issues with self-signed certificates.

.NOTES
   This script should run with elevated privileges (administrator).
   Make sure you have sufficient permissions.

.VERSION HISTORY
  1.0   Initial version.
  1.1   Removed temporary test sections.
  1.2   Added PowerShell version check.
  1.3   Added database object count check.
  1.4   Added SSL configuration check.
  1.5   Corrected version number.
  1.6   Added Update-Module dbatools, extensive logging, execution policy adjustment, and SSL certificate validation disabling.
  1.7   **New:** Displays the currently available dbatools version before continuing.
#>

param(
    [string]$ConfigFile = "$PSScriptRoot\ExportConfig.json"
)

Write-Host "InstallatieTooling.ps1 Versie 1.7"
Write-Host "================================="

# --- Controleer of er een dbatools-module beschikbaar is en toon het versienummer ---
$currentDbatools = Get-Module dbatools -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
if ($currentDbatools) {
    Write-Host "Huidige beschikbare dbatools versie: $($currentDbatools.Version)"
} else {
    Write-Host "Geen dbatools-module gevonden in de modulepaden."
}

# --- Zet de execution policy voor de huidige gebruiker ---
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    Write-Host "Execution policy ingesteld op RemoteSigned voor de huidige gebruiker."
} catch {
    Write-Warning "Kon de execution policy niet aanpassen: $_"
}

# --- Stap 1: Lees de configuratie ---
if (!(Test-Path $ConfigFile)) {
    Write-Error "Configfile niet gevonden: $ConfigFile"
    exit 1
}
try {
    $json = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
} catch {
    Write-Error ("Fout bij inladen/parsen van {0}: {1}" -f $ConfigFile, $_)
    exit 1
}

# --- Stap 2: Controleer PowerShell-versie ---
$minPS = $json.MinPSVersion
if ($PSVersionTable.PSVersion.Major -lt $minPS) {
    Write-Error "Je draait PS-versie $($PSVersionTable.PSVersion.Major), maar minimaal $minPS is vereist. Stop."
    exit 1
}
Write-Host "PowerShell-versie OK (>= $minPS)."

# --- Stap 3: dbatools installeren en importeren ---
Write-Host "`n=== dbatools controleren/installeren ==="
$installInBin = $json.InstallDbatoolsInBin -eq $true
$binFolder = Join-Path $PSScriptRoot $json.BinFolder
if (!(Test-Path $binFolder)) { New-Item -ItemType Directory -Path $binFolder | Out-Null }

try {
    Write-Host "Update-Module dbatools -Force..."
    Update-Module dbatools -Force -ErrorAction Stop
    Write-Host "dbatools is bijgewerkt naar de nieuwste versie."
} catch {
    Write-Host "Update-Module dbatools faalde; we gaan verder met de huidige versie."
}

Write-Host "`nUnblocking dbatools modulebestanden..."
$foundModules = Get-Module -ListAvailable dbatools
foreach ($mod in $foundModules) {
    Write-Host "Unblocking in: $($mod.ModuleBase)"
    Get-ChildItem -Path $mod.ModuleBase -Recurse | Unblock-File -ErrorAction SilentlyContinue
}

function Import-LocalDbatools {
    param([string]$BinDir)
    $dbaDir = Join-Path $BinDir "dbatools"
    if (!(Test-Path $dbaDir)) { return $false }
    $versions = Get-ChildItem -Path $dbaDir -Directory | Sort-Object Name -Descending
    if ($versions.Count -eq 0) { return $false }
    $latest = $versions[0].FullName
    $psd1 = Join-Path $latest "dbatools.psd1"
    if (!(Test-Path $psd1)) { return $false }
    Write-Host "Importeer dbatools uit: $psd1"
    Import-Module $psd1 -Force -DisableNameChecking
    return $true
}

try {
    if (Get-Module dbatools -ListAvailable) {
        Write-Host "dbatools lijkt al geïnstalleerd (globaal of user-scope). Importeer module..."
        Import-Module dbatools -Force -ErrorAction SilentlyContinue
    } else {
        $importOk = Import-LocalDbatools -BinDir $binFolder
        if (-not $importOk) {
            if ($installInBin) {
                Write-Host "dbatools niet lokaal gevonden, installeren in $binFolder ..."
                Install-Module dbatools -Scope CurrentUser -Force -AllowClobber -Repository PSGallery -SkipPublisherCheck -Prefix $binFolder
                $importOk = Import-LocalDbatools -BinDir $binFolder
                if (-not $importOk) {
                    throw "Kon dbatools niet importeren na installatie in $binFolder."
                }
            } else {
                Write-Host "Installeer dbatools in user-scope..."
                Install-Module dbatools -Scope CurrentUser -Force -AllowClobber
                Import-Module dbatools -Force
            }
        }
    }
} catch {
    Write-Error ("Fout bij dbatools-installatie/import: {0}" -f $_)
    exit 1
}

Write-Host "`ndbatools is nu geladen. Versie: $(Get-Module dbatools | Select-Object -ExpandProperty Version)"

# --- Stap 4: Schakel SSL-certificaatvalidatie uit ---
Write-Host "`n=== SSL-certificaatvalidatie uitschakelen ==="
function Disable-CertificateValidation {
    if(-not ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type) {
        Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
    }
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor `
        [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls
    Write-Host "Certificaatvalidatie uitgeschakeld voor deze sessie."
}
Disable-CertificateValidation

Write-Host "`nInstallatieTooling voltooid."
Pause
