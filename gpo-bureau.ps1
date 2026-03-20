# ==============================================================================
# gpo-bureau.ps1
# ==============================================================================

Import-Module GroupPolicy

$DomainName = "DOMAIN.COM"
$DomainDN   = "DC=DOMAIN,DC=COM"
$RootOU     = "OU=Entreprise,$DomainDN"

Write-Host "`n=== Configuration des GPO Bureau ===" -ForegroundColor Cyan


# ==============================================================================
# GPO 1 : CONFIGURATION DU BUREAU (tous les utilisateurs)
# ==============================================================================

Write-Host "`n[1/2] Création de la GPO 'GPO_Bureau_Standard'..." -ForegroundColor Yellow

$GPOExiste = Get-GPO -Name "GPO_Bureau_Standard" -ErrorAction SilentlyContinue
if (-not $GPOExiste) {
    New-GPO -Name "GPO_Bureau_Standard" -Comment "Configuration standard du bureau utilisateur" | Out-Null
}

# --- Fond d'écran d'entreprise ---
Set-GPRegistryValue -Name "GPO_Bureau_Standard" `
    -Key       "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "Wallpaper" `
    -Type      String -Value "\\DC01\SYSVOL\DOMAIN.COM\wallpaper\wallpaper.jpg"

Set-GPRegistryValue -Name "GPO_Bureau_Standard" `
    -Key       "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "WallpaperStyle" `
    -Type      String -Value "4"  

# --- Désactiver l'accès au Panneau de configuration pour les non-IT ---
Set-GPRegistryValue -Name "GPO_Bureau_Standard" `
    -Key       "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoControlPanel" `
    -Type      DWord -Value 1   

# --- Désactiver l'accès à l'invite de commandes ---
Set-GPRegistryValue -Name "GPO_Bureau_Standard" `
    -Key       "HKCU\Software\Policies\Microsoft\Windows\System" `
    -ValueName "DisableCMD" `
    -Type      DWord -Value 1   

# --- Liaison à l'OU racine Entreprise  ---
New-GPLink -Name "GPO_Bureau_Standard" `
    -Target      $RootOU `
    -LinkEnabled Yes `
    -ErrorAction SilentlyContinue

Write-Host "     GPO 'GPO_Bureau_Standard' liée à OU=Entreprise" -ForegroundColor Green
Write-Host "     Fond d'écran forcé | Panneau de config désactivé | CMD désactivé" -ForegroundColor Gray


# ==============================================================================
# GPO 2 : EXCEPTION INFORMATIQUE
# ==============================================================================

Write-Host "`n[2/2] Création de la GPO 'GPO_Bureau_Informatique'..." -ForegroundColor Yellow

$GPOExiste2 = Get-GPO -Name "GPO_Bureau_Informatique" -ErrorAction SilentlyContinue
if (-not $GPOExiste2) {
    New-GPO -Name "GPO_Bureau_Informatique" -Comment "Accès étendu pour l equipe Informatique" | Out-Null
}

# --- Réactiver le Panneau de config pour l'IT ---
Set-GPRegistryValue -Name "GPO_Bureau_Informatique" `
    -Key       "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoControlPanel" `
    -Type      DWord -Value 0 

# --- Réactiver CMD pour l'IT ---
Set-GPRegistryValue -Name "GPO_Bureau_Informatique" `
    -Key       "HKCU\Software\Policies\Microsoft\Windows\System" `
    -ValueName "DisableCMD" `
    -Type      DWord -Value 0  

# --- Liaison à l'OU Informatique uniquement ---
New-GPLink -Name "GPO_Bureau_Informatique" `
    -Target      "OU=Informatique,$RootOU" `
    -LinkEnabled Yes `
    -ErrorAction SilentlyContinue

Write-Host "   GPO 'GPO_Bureau_Informatique' liée à OU=Informatique" -ForegroundColor Green
Write-Host "     Panneau de config autorisé | CMD autorisé" -ForegroundColor Gray


# ==============================================================================
# RÉSUMÉ
# ==============================================================================

Write-Host "`n=== Résumé des GPO Bureau ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  GPO_Bureau_Standard (tous les utilisateurs)"
Write-Host "  ├── Fond d'écran        : Forcé depuis SYSVOL"
Write-Host "  ├── Panneau de config   : Désactivé"
Write-Host "  └── CMD                 : Désactivé"
Write-Host ""
Write-Host "  GPO_Bureau_Informatique (OU=Informatique seulement)"
Write-Host "  ├── Panneau de config   : Autorisé (écrase GPO_Bureau_Standard)"
Write-Host "  └── CMD                 : Autorisé (écrase GPO_Bureau_Standard)"
