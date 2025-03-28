<#
.SYNOPSIS
   Exports SQL Server schemas into a structured folder layout, per object type.

.DESCRIPTION
   - Reads configuration from ExportConfig.json.
   - For each server and database:
         • Retrieves the database using Get-DbaDatabase (via Windows Authentication).
         • Exports each object per type (Tables, Views, StoredProcedures, and UserDefinedFunctions) into a subfolder.
   - All paths are built relative to $PSScriptRoot to ensure portability of the script.

.NOTES
   This script is intended to run **without** elevated privileges, so that Windows Authentication uses your own user context.

.VERSION HISTORY
   1.0   Initial version.
   1.1   Added: Individual export per object type with header in each .sql file.
   1.2   Added: Logging and SSL certificate validation callback.
   1.5   Updated version, improved error handling and logging.
   1.7   [2025-03-14] Added: Display installed dbatools version before starting.
   1.9   [2025-03-14] Replaced -OutputFile with -FilePath, added temporary file output.
   1.11  [2025-03-14] Removed auto-generated header (via regex) and inserted static header instead.
#>

param(
    [string]$ConfigFile = "$PSScriptRoot\ExportConfig.json"
)

Write-Host "ExportData.ps1 Versie 1.11"
Write-Host "---------------------------"

# Controleer of de dbatools-module beschikbaar is en toon het versienummer.
$currentDbatools = Get-Module dbatools -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
if ($currentDbatools) {
    Write-Host "Geregistreerde dbatools versie: $($currentDbatools.Version)"
} else {
    Write-Warning "Geen dbatools-module gevonden."
}

Write-Host "=== Start export van database-objecten ==="

# --- SSL-certificaatvalidatie uitschakelen ---
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {
    param(
        [object]$sender,
        [System.Security.Cryptography.X509Certificates.X509Certificate]$certificate,
        [System.Security.Cryptography.X509Certificates.X509Chain]$chain,
        [System.Net.Security.SslPolicyErrors]$sslPolicyErrors
    )
    if ($sslPolicyErrors -eq [System.Net.Security.SslPolicyErrors]::None) {
        return $true
    }
    if ($sslPolicyErrors -eq [System.Net.Security.SslPolicyErrors]::RemoteCertificateChainErrors) {
        Write-Warning "SSL-certificaatfout: De certificaatketen is verleend door een niet-vertrouwde instantie. We vertrouwen dit certificaat voor deze sessie."
        return $true
    }
    Write-Warning "SSL-certificaatfout: $sslPolicyErrors"
    return $false
}

# --- Lees de configuratie ---
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

$exportRoot = Join-Path $PSScriptRoot $json.ExportRoot  # Bijvoorbeeld .\metadata
if (-not (Test-Path $exportRoot)) {
    New-Item -Path $exportRoot -ItemType Directory | Out-Null
    Write-Host "Aangemaakt: $exportRoot"
}

# --- Definieer de Scripting Options ---
$options = New-DbaScriptingOption
$options.ScriptSchema = $true
$options.IncludeDatabaseContext = $true
$options.IncludeHeaders = $false
$options.NoCommandTerminator = $false
$options.ScriptBatchTerminator = $true
$options.AnsiFile = $true

# Functie voor het exporteren van een collectie objecten
function Export-ObjectCollection {
    param(
        [Parameter(Mandatory = $true)] [string]$FolderName,
        [Parameter(Mandatory = $true)] [System.Collections.IEnumerable]$Objects
    )
    $targetFolder = Join-Path $dbExportPath $FolderName
    if (-not (Test-Path $targetFolder)) {
        New-Item -Path $targetFolder -ItemType Directory | Out-Null
    }
    foreach ($obj in $Objects) {
        try {
            # Schrijf de output van Export-DbaScript naar een tijdelijk bestand met -FilePath
            $tempFile = [System.IO.Path]::GetTempFileName()
            try {
                Export-DbaScript -InputObject $obj -FilePath $tempFile -ScriptingOptionsObject $options
                $scriptContent = Get-Content -Path $tempFile -Raw
                # Verwijder de automatisch gegenereerde header van dbatools
                $scriptContent = $scriptContent -replace '(?s)/\*.*?See https:\/\/dbatools\.io\/Export-DbaScript for more information.*?\*/', ''
            } finally {
                Remove-Item $tempFile -ErrorAction SilentlyContinue
            }
            # Voeg een statische header toe
            $header = "-- Created with https://github.com/eduardwitteveen/sqlserver-export-git`n--`n"
            $combinedContent = $header + $scriptContent
            $targetFile = Join-Path $targetFolder "$($obj.Name).sql"
            $combinedContent | Out-File -FilePath $targetFile -Encoding UTF8
            Write-Host "    -> Export van $($obj.Name) naar $targetFolder geslaagd."
        } catch {
            Write-Warning ("    Fout bij exporteren van $($obj.Name): {0}" -f $_)
        }
    }
}

foreach ($serverDef in $json.Servers) {
    $serverName = $serverDef.Name
    $dbList = $serverDef.Databases
    Write-Host "`nServer: $serverName (WindowsAuth)"
    foreach ($dbName in $dbList) {
        Write-Host " - Database: $dbName"
        $safeServerName = $serverName.Replace('\','_')
        $dbExportPath = Join-Path $exportRoot "$safeServerName\$dbName"
        if (-not (Test-Path $dbExportPath)) {
            New-Item -Path $dbExportPath -ItemType Directory | Out-Null
        }
        try {
            $dbObject = Get-DbaDatabase -SqlInstance $serverName -Database $dbName
        } catch {
            Write-Warning ("      Fout bij ophalen van database $dbName op ${serverName}: {0}" -f $_)
            continue
        }
        Write-Host "  Verbonden via Get-DbaDatabase."
        Write-Host "  Database objecten:" 
        Write-Host "    - Tables: $($dbObject.Tables.Count)"
        Write-Host "    - Views: $($dbObject.Views.Count)"
        Write-Host "    - StoredProcedures: $($dbObject.StoredProcedures.Count)"
        Write-Host "    - UserDefinedFunctions: $($dbObject.UserDefinedFunctions.Count)"
        
        if ($dbObject.Tables.Count -gt 0) {
            Write-Host "   Exporteer Tables..."
            Export-ObjectCollection -FolderName "Tables" -Objects $dbObject.Tables
        } else {
            Write-Host "   Geen Tables gevonden."
        }
        if ($dbObject.Views.Count -gt 0) {
            Write-Host "   Exporteer Views..."
            Export-ObjectCollection -FolderName "Views" -Objects $dbObject.Views
        } else {
            Write-Host "   Geen Views gevonden."
        }
        if ($dbObject.StoredProcedures.Count -gt 0) {
            Write-Host "   Exporteer StoredProcedures..."
            Export-ObjectCollection -FolderName "StoredProcedures" -Objects $dbObject.StoredProcedures
        } else {
            Write-Host "   Geen StoredProcedures gevonden."
        }
        if ($dbObject.UserDefinedFunctions.Count -gt 0) {
            Write-Host "   Exporteer Functions..."
            Export-ObjectCollection -FolderName "Functions" -Objects $dbObject.UserDefinedFunctions
        } else {
            Write-Host "   Geen Functions gevonden."
        }
    }
}

Write-Host "`n=== Klaar met export! ==="
Write-Host "Nu kun je (optioneel) zelf 'git init' in deze map uitvoeren, committen, pushen, etc.:"
Write-Host "  $exportRoot"
Write-Host "`nEinde script."
