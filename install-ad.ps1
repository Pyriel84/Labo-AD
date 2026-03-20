# ==============================================================================
# install-ad.ps1
# ==============================================================================

# ------------------------------------------------------------------------------
# VARIABLES DE CONFIGURATION
# ------------------------------------------------------------------------------

$DomainName    = "DOMAIN.COM"        # Nom complet du domaine (FQDN)
$DomainNetbios = "DOMAIN"            # Nom NetBIOS (ex: DOMAIN\utilisateur)
$ServerName    = "DC01"              # Nom du serveur
$ServerIP      = "10.0.0.1"         # IP statique du contrôleur de domaine
$GatewayIP     = "10.0.0.254"       # Passerelle (interface NAT de l'hôte Hyper-V)
$DNSServer     = "127.0.0.1"        # Le DC sera son propre serveur DNS

# Mot de passe DSRM
$DSRMPassword  = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force


# ------------------------------------------------------------------------------
# ÉTAPE 1 : Configuration de l'IP statique
# ------------------------------------------------------------------------------

Write-Host "`n[1/4] Configuration de l'adresse IP statique ($ServerIP)..." -ForegroundColor Cyan

$Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1

# Supprime la config DHCP existante
Remove-NetIPAddress -InterfaceIndex $Adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceIndex $Adapter.InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue

New-NetIPAddress `
    -InterfaceIndex  $Adapter.InterfaceIndex `
    -IPAddress       $ServerIP `
    -PrefixLength    24 `
    -DefaultGateway  $GatewayIP

# Le DC pointe vers lui-même pour le DNS
Set-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -ServerAddresses $DNSServer

Write-Host "   IP statique configurée : $ServerIP | DNS : $DNSServer" -ForegroundColor Green


# ------------------------------------------------------------------------------
# ÉTAPE 2 : Renommage du serveur
# ------------------------------------------------------------------------------

Write-Host "`n[2/4] Renommage du serveur en '$ServerName'..." -ForegroundColor Cyan

Rename-Computer -NewName $ServerName -Force
Write-Host "  Renommage effectué (actif après redémarrage)" -ForegroundColor Green


# ------------------------------------------------------------------------------
# ÉTAPE 3 : Installation du rôle AD DS
# ------------------------------------------------------------------------------

Write-Host "`n[3/4] Installation du rôle AD DS..." -ForegroundColor Cyan

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-Host "  Rôle AD DS installé" -ForegroundColor Green


# ------------------------------------------------------------------------------
# ÉTAPE 4 : Promotion en contrôleur de domaine
# ------------------------------------------------------------------------------

Write-Host "`n[4/4] Promotion en contrôleur de domaine pour '$DomainName'..." -ForegroundColor Cyan
Write-Host "  Le serveur va redémarrer automatiquement." -ForegroundColor Yellow

Import-Module ADDSDeployment

Install-ADDSForest `
    -DomainName                    $DomainName `
    -DomainNetbiosName             $DomainNetbios `
    -SafeModeAdministratorPassword $DSRMPassword `
    -InstallDns                    $true `
    -DatabasePath                  "C:\Windows\NTDS" `
    -LogPath                       "C:\Windows\NTDS" `
    -SysvolPath                    "C:\Windows\SYSVOL" `
    -ForestMode                    "WinThreshold" `   
    -DomainMode                    "WinThreshold" `
    -Force                         $true `
    -NoRebootOnCompletion          $false            
