$configFiles = Get-ChildItem -Path "<ENTER PATH TO CONFIG FILES HERE>" -Filter *.json | Sort-Object Name
Write-Host "Select a configuration: "
for ($i = 0; $i -lt $configFiles.Count; $i++) {
    Write-Host "$($i + 1). $($configFiles[$i].Name)"
}

# Get user selection
$selection = Read-Host "Enter the number of the config to load"
$index = [int]$selection - 1

if ($index -ge 0 -and $index -lt $configFiles.Count) {
    $selectedConfig = $configFiles[$index].FullName
    Write-Host "Loading configuration from: $selectedConfig" -ForegroundColor DarkCyan
    
    # Load the config
    $config = Get-Content -Raw -Path $selectedConfig | ConvertFrom-Json
    $apps = $config.apps
} else {
    Write-Host "Invalid selection. Exiting script."
    exit
}

$registryKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($app in $apps) {
    $appInstalled = $false
    $appName = $app.Name
    $installerPath = $app.Installer
    $silentArgs = $app.Arguments

    Write-Host "Checking for: $appName"
        foreach ($keyPath in $registryKeys) {
            $registryEntries = Get-ItemProperty -Path $keyPath -ErrorAction SilentlyContinue
            foreach ($entry in $registryEntries) {
                if ($entry.DisplayName -and $entry.DisplayName -like "*$appName*") {
                    $appInstalled = $true
                    break
                }
            }
            if ($appInstalled) { break }
        }
if (-not $appInstalled) {
    Write-Host "$appName is not installed. Running installer..."

    $extension = [System.IO.Path]::GetExtension($installerPath).ToLower()

    switch ($extension) {
        ".msi" {
            $msiArgs = "/i `"$installerPath`""
            if ($silentArgs) {
                $msiArgs += " $silentArgs"
            }
            Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait
        }
        ".exe" {
            if ($silentArgs) {
                Start-Process -FilePath $installerPath -ArgumentList $silentArgs -Wait
            } else {
                Start-Process -FilePath $installerPath -Wait
            }
        }
        default {
            Start-Process -FilePath $installerPath -Wait
        }
    }
} else {
    Write-Host "$appName is already installed.`n"
    }
}