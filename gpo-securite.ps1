# ==============================================================================
# gpo-securite.ps1
# ==============================================================================

Import-Module GroupPolicy
Import-Module ActiveDirectory

$DomainName = "DOMAIN.COM"
$DomainDN   = "DC=DOMAIN,DC=COM"
$RootOU     = "OU=Entreprise,$DomainDN"

Write-Host "`n=== Application des GPO de sécurité sur $DomainName ===" -ForegroundColor Cyan


# ==============================================================================
# GPO 1 : POLITIQUE DE MOT DE PASSE
# ==============================================================================

Write-Host "`n[1/3] Configuration de la politique de mot de passe du domaine..." -ForegroundColor Yellow

Set-ADDefaultDomainPasswordPolicy -Identity $DomainName `
    -MinPasswordLength           12 `            
    -PasswordHistoryCount        10 `            
    -MaxPasswordAge              "90.00:00:00" `    
    -MinPasswordAge              "1.00:00:00" `    
    -ComplexityEnabled           $true `          
    -ReversibleEncryptionEnabled $false        

Write-Host "   Politique MDP : 12 cars min | 90j expiration | complexité activée" -ForegroundColor Green


# ==============================================================================
# GPO 2 : VERROUILLAGE DE COMPTE
# ==============================================================================

Write-Host "`n[2/3] Configuration du verrouillage de compte..." -ForegroundColor Yellow

Set-ADDefaultDomainPasswordPolicy -Identity $DomainName `
    -LockoutThreshold          5 `            
    -LockoutDuration           "0.00:30:00" `  
    -LockoutObservationWindow  "0.00:30:00"    

Write-Host "   Verrouillage : 5 tentatives max | durée : 30 min" -ForegroundColor Green


# ==============================================================================
# GPO 3 : SÉCURITÉ DES POSTES CLIENTS
# ==============================================================================

Write-Host "`n[3/3] Création de la GPO 'GPO_Securite_Workstations'..." -ForegroundColor Yellow

$GPOExiste = Get-GPO -Name "GPO_Securite_Workstations" -ErrorAction SilentlyContinue
if (-not $GPOExiste) {
    New-GPO -Name "GPO_Securite_Workstations" -Comment "Parametres de securite des postes clients" | Out-Null
}

# --- Forcer CTRL+ALT+SUPPR avant la connexion ---
Set-GPRegistryValue -Name "GPO_Securite_Workstations" `
    -Key       "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" `
    -ValueName "DisableCAD" `
    -Type      DWord -Value 0 

# --- Activer le pare-feu Windows ---
Set-GPRegistryValue -Name "GPO_Securite_Workstations" `
    -Key       "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile" `
    -ValueName "EnableFirewall" `
    -Type      DWord -Value 1

Set-GPRegistryValue -Name "GPO_Securite_Workstations" `
    -Key       "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\PublicProfile" `
    -ValueName "EnableFirewall" `
    -Type      DWord -Value 1

# --- Verrouillage de l'écran après 10 minutes d'inactivité ---
Set-GPRegistryValue -Name "GPO_Securite_Workstations" `
    -Key       "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
    -ValueName "ScreenSaveTimeOut" `
    -Type      String -Value "600" 

Set-GPRegistryValue -Name "GPO_Securite_Workstations" `
    -Key       "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
    -ValueName "ScreenSaverIsSecure" `
    -Type      String -Value "1"   

# --- Liaison de la GPO à l'OU Ordinateurs ---
$GPOLien = Get-GPInheritance -Target "OU=Ordinateurs,$RootOU" -ErrorAction SilentlyContinue
if ($GPOLien) {
    New-GPLink -Name "GPO_Securite_Workstations" `
        -Target      "OU=Ordinateurs,$RootOU" `
        -LinkEnabled Yes `
        -ErrorAction SilentlyContinue
}

Write-Host "   GPO liée à OU=Ordinateurs" -ForegroundColor Green
Write-Host "     → CTRL+ALT+SUPPR forcé | Pare-feu activé | Écran verrouillé après 10 min" -ForegroundColor Gray


# ==============================================================================
# RÉSUMÉ
# ==============================================================================

Write-Host "`n=== Résumé des politiques de sécurité ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Mot de passe"
Write-Host "  ├── Longueur minimale     : 12 caractères"
Write-Host "  ├── Complexité            : Activée"
Write-Host "  ├── Expiration            : 90 jours"
Write-Host "  └── Historique            : 10 derniers mots de passe"
Write-Host ""
Write-Host "  Verrouillage de compte"
Write-Host "  ├── Seuil                 : 5 tentatives échouées"
Write-Host "  └── Durée                 : 30 minutes"
Write-Host ""
Write-Host "  Postes clients (OU=Ordinateurs)"
Write-Host "  ├── CTRL+ALT+SUPPR        : Obligatoire"
Write-Host "  ├── Pare-feu              : Activé (domaine + public)"
Write-Host "  └── Verrouillage écran    : 10 min d'inactivité"
