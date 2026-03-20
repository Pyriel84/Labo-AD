# ==============================================================================
# backup-ad.ps1
# ==============================================================================

# ------------------------------------------------------------------------------
# VARIABLES DE CONFIGURATION
# ------------------------------------------------------------------------------

$BackupRoot  = "D:\Backups\AD"       
                                      
$RetentionJours = 30          
$DateSauvegarde = Get-Date -Format "yyyy-MM-dd_HH-mm"
$LogFile        = "$BackupRoot\backup_$DateSauvegarde.log"



# ------------------------------------------------------------------------------
# ÉTAPE 1 : Vérification des prérequis
# ------------------------------------------------------------------------------

Write-Host "`n=== Sauvegarde Active Directory — $DateSauvegarde ===" -ForegroundColor Cyan


if (-not (Test-Path $BackupRoot)) {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    Write-Log "Dossier de sauvegarde créé : $BackupRoot"
}


$WSBInstalle = Get-WindowsFeature -Name "Windows-Server-Backup" | Where-Object { $_.Installed }
if (-not $WSBInstalle) {
    Write-Log "Fonctionnalité 'Windows Server Backup' non installée — installation en cours..."
    Install-WindowsFeature -Name Windows-Server-Backup
    Write-Log "Windows Server Backup installé"
}


# ------------------------------------------------------------------------------
# ÉTAPE 2 : Sauvegarde du System State
# ------------------------------------------------------------------------------

Write-Log "Démarrage de la sauvegarde System State vers $BackupRoot"

try {
    $BackupCmd = "wbadmin start systemstatebackup -backupTarget:$BackupRoot -quiet"

    Write-Log "Exécution : $BackupCmd"
    Invoke-Expression $BackupCmd

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Sauvegarde System State terminée avec succès" 
    } else {
        Write-Log "wbadmin a retourné le code d'erreur : $LASTEXITCODE"
        exit 1
    }

} catch {
    Write-Log "Erreur lors de la sauvegarde : $_"
    exit 1
}


# ------------------------------------------------------------------------------
# ÉTAPE 3 : Nettoyage des anciennes sauvegardes
# ------------------------------------------------------------------------------

Write-Log "Nettoyage des sauvegardes de plus de $RetentionJours jours..."

$DateLimite        = (Get-Date).AddDays(-$RetentionJours)
$AnciennesSauvegardes = Get-ChildItem -Path $BackupRoot -Directory |
                        Where-Object { $_.CreationTime -lt $DateLimite }

foreach ($Dossier in $AnciennesSauvegardes) {
    try {
        Remove-Item -Path $Dossier.FullName -Recurse -Force
        Write-Log "Ancienne sauvegarde supprimée : $($Dossier.Name)" 
    } catch {
        Write-Log "Impossible de supprimer $($Dossier.Name) : $_" 
    }
}

Write-Log "$($AnciennesSauvegardes.Count) ancienne(s) sauvegarde(s) supprimée(s)"


# ------------------------------------------------------------------------------
# RÉSUMÉ FINAL
# ------------------------------------------------------------------------------

$TailleBackup = (Get-ChildItem -Path $BackupRoot -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB

Write-Host "`n=== Résumé de la sauvegarde ===" -ForegroundColor Cyan
Write-Log "Sauvegarde terminée avec succès"
Write-Log "Espace utilisé par les sauvegardes : $([math]::Round($TailleBackup, 2)) Go"
Write-Log "Fichier log : $LogFile"
