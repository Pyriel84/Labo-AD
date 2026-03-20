# VARIABLES DE CONFIGURATION
# ------------------------------------------------------------------------------

$VMPath     = "C:\Hyper-V\VMs"          # Dossier où seront stockées les VMs
$ISOPath    = "C:\Hyper-V\ISO"          # Dossier contenant les fichiers ISO
$SwitchName = "LAB-Switch"              # Nom du switch réseau virtuel

# ISOs à télécharger au préalable :
# Windows Server 2025 : https://www.microsoft.com/fr-fr/evalcenter/evaluate-windows-server-2025
# Windows 11           : https://www.microsoft.com/fr-fr/software-download/windows11
$ISO_Server = "$ISOPath\WS2025.iso"
$ISO_Client = "$ISOPath\Win11.iso"

# ------------------------------------------------------------------------------
# ÉTAPE 1 : Création du switch réseau virtuel
# ------------------------------------------------------------------------------

Write-Host "`n[1/4] Création du switch réseau virtuel '$SwitchName'..." -ForegroundColor Cyan

$SwitchExiste = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
if (-not $SwitchExiste) {
    New-VMSwitch -Name $SwitchName -SwitchType Internal
    Write-Host "   ✓ Switch '$SwitchName' créé (type : Internal)" -ForegroundColor Green
} else {
    Write-Host "   ⚠ Switch '$SwitchName' existe déjà — ignoré" -ForegroundColor Yellow
}

# Configuration NAT
$NatExiste = Get-NetNat -Name "LAB-NAT" -ErrorAction SilentlyContinue
if (-not $NatExiste) {
    # On donne une IP à l'interface virtuelle de l'hôte (passerelle du lab)
    $HostAdapter = Get-NetAdapter | Where-Object { $_.Name -like "*$SwitchName*" }
    New-NetIPAddress -IPAddress "10.0.0.254" -PrefixLength 24 -InterfaceIndex $HostAdapter.InterfaceIndex
    New-NetNat -Name "LAB-NAT" -InternalIPInterfaceAddressPrefix "10.0.0.0/24"
    Write-Host "   ✓ NAT configuré — plage réseau : 10.0.0.0/24" -ForegroundColor Green
}

# Création du dossier de stockage des VMs
New-Item -ItemType Directory -Path $VMPath -Force | Out-Null


# ------------------------------------------------------------------------------
# ÉTAPE 2 : Création de DC01
# ------------------------------------------------------------------------------

Write-Host "`n[2/4] Création de la VM DC01 (Windows Server 2025)..." -ForegroundColor Cyan

$DC01Path = "$VMPath\DC01"
New-Item -ItemType Directory -Path $DC01Path -Force | Out-Null

# Création du disque dur virtuel
$DC01_VHD = "$DC01Path\DC01.vhdx"
New-VHD -Path $DC01_VHD -SizeBytes 60GB -Dynamic    # Dynamic = taille variable

New-VM `
    -Name               "DC01" `
    -MemoryStartupBytes 2GB `
    -VHDPath            $DC01_VHD `
    -SwitchName         $SwitchName `
    -Generation         2           # Génération 2 = UEFI (plus moderne, requis pour WS2025)

Set-VM -Name "DC01" `
    -ProcessorCount         2 `                     # 2 vCPU
    -DynamicMemory          $false `                # Mémoire fixe pour un DC (plus stable)
    -AutomaticStartAction   "StartIfRunning" `      # Démarre auto si la machine hôte redémarre
    -AutomaticStopAction    "ShutDown"              # Arrêt propre du guest OS

# Montage de l'ISO
Add-VMDvdDrive -VMName "DC01" -Path $ISO_Server
Set-VMFirmware -VMName "DC01" -FirstBootDevice (Get-VMDvdDrive -VMName "DC01")

Write-Host "   ✓ VM 'DC01' créée — 2 vCPU | 2 Go RAM | 60 Go disque" -ForegroundColor Green


# ------------------------------------------------------------------------------
# ÉTAPE 3 : Création de CLIENT01
# ------------------------------------------------------------------------------

Write-Host "`n[3/4] Création de la VM CLIENT01 (Windows 11)..." -ForegroundColor Cyan

$C01Path = "$VMPath\CLIENT01"
New-Item -ItemType Directory -Path $C01Path -Force | Out-Null

$C01_VHD = "$C01Path\CLIENT01.vhdx"
New-VHD -Path $C01_VHD -SizeBytes 50GB -Dynamic

New-VM `
    -Name               "CLIENT01" `
    -MemoryStartupBytes 4GB `
    -VHDPath            $C01_VHD `
    -SwitchName         $SwitchName `
    -Generation         2

Set-VM -Name "CLIENT01" -ProcessorCount 2 -DynamicMemory $true -MemoryMaximumBytes 4GB

Add-VMDvdDrive -VMName "CLIENT01" -Path $ISO_Client
Set-VMFirmware -VMName "CLIENT01" -FirstBootDevice (Get-VMDvdDrive -VMName "CLIENT01")

Write-Host "   VM 'CLIENT01' créée — 2 vCPU | 4 Go RAM | 50 Go disque" -ForegroundColor Green


# ------------------------------------------------------------------------------
# ÉTAPE 4 : Création de CLIENT02
# ------------------------------------------------------------------------------

Write-Host "`n[4/4] Création de la VM CLIENT02 (Windows 11)..." -ForegroundColor Cyan

$C02Path = "$VMPath\CLIENT02"
New-Item -ItemType Directory -Path $C02Path -Force | Out-Null

$C02_VHD = "$C02Path\CLIENT02.vhdx"
New-VHD -Path $C02_VHD -SizeBytes 50GB -Dynamic

New-VM `
    -Name               "CLIENT02" `
    -MemoryStartupBytes 4GB `
    -VHDPath            $C02_VHD `
    -SwitchName         $SwitchName `
    -Generation         2

Set-VM -Name "CLIENT02" -ProcessorCount 2 -DynamicMemory $true -MemoryMaximumBytes 4GB

Add-VMDvdDrive -VMName "CLIENT02" -Path $ISO_Client
Set-VMFirmware -VMName "CLIENT02" -FirstBootDevice (Get-VMDvdDrive -VMName "CLIENT02")

Write-Host "   VM 'CLIENT02' créée — 2 vCPU | 4 Go RAM | 50 Go disque" -ForegroundColor Green


# ------------------------------------------------------------------------------
# RÉSUMÉ
# ------------------------------------------------------------------------------

Write-Host "`n=== VMs créées avec succès ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  VM        OS                   RAM    Disque   IP"
Write-Host "  ------    -------------------  -----  -------  ----------"
Write-Host "  DC01      Windows Server 2025  2 Go   60 Go    10.0.0.1 (à configurer)"
Write-Host "  CLIENT01  Windows 11           4 Go   50 Go    10.0.0.100 (DHCP)"
Write-Host "  CLIENT02  Windows 11           4 Go   50 Go    10.0.0.101 (DHCP)"
