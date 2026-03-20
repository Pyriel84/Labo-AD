# ==============================================================================
# audit-comptes.ps1
# ==============================================================================

Import-Module ActiveDirectory

$DomainDN      = "DC=DOMAIN,DC=COM"
$RootOU        = "OU=Entreprise,$DomainDN"
$DateAudit     = Get-Date -Format "yyyy-MM-dd_HH-mm"
$ExportPath    = "C:\Audit_AD_$DateAudit.csv"

# Seuil d'inactivité 
$SeuilInactivite = 90
$DateLimite      = (Get-Date).AddDays(-$SeuilInactivite)

Write-Host "`n=== Audit des comptes Active Directory ===" -ForegroundColor Cyan
Write-Host "   Domaine   : DOMAIN.COM"
Write-Host "   Date      : $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
Write-Host "   Seuil     : $SeuilInactivite jours d'inactivité"
Write-Host "   Export    : $ExportPath`n"

$Resultats = @()  

# ------------------------------------------------------------------------------
# VÉRIFICATION 1 : Comptes inactifs
# ------------------------------------------------------------------------------

Write-Host "[1/4] Recherche des comptes inactifs (> $SeuilInactivite jours)..." -ForegroundColor Yellow

$ComptesInactifs = Get-ADUser -Filter {
    Enabled -eq $true -and LastLogonDate -lt $DateLimite
} -SearchBase $RootOU `
  -Properties LastLogonDate, Department, Title, PasswordLastSet |
  Where-Object { $_.LastLogonDate -ne $null }

foreach ($Compte in $ComptesInactifs) {
    $Resultats += [PSCustomObject]@{
        Nom              = $Compte.Name
        Login            = $Compte.SamAccountName
        Departement      = $Compte.Department
        Poste            = $Compte.Title
        Statut           = "Inactif"
        Detail           = "Derniere connexion : $($Compte.LastLogonDate.ToString('dd/MM/yyyy'))"
        Action_Suggere   = "Desactiver ou supprimer"
    }
}

Write-Host "  $($ComptesInactifs.Count) compte(s) inactif(s) trouvé(s)" -ForegroundColor $(if ($ComptesInactifs.Count -gt 0) { "Red" } else { "Green" })


# ------------------------------------------------------------------------------
# VÉRIFICATION 2 : Comptes expirés
# ------------------------------------------------------------------------------

Write-Host "[2/4] Recherche des comptes expirés..." -ForegroundColor Yellow

$ComptesExpires = Search-ADAccount -AccountExpired -SearchBase $RootOU -UsersOnly

foreach ($Compte in $ComptesExpires) {
    $UserDetail = Get-ADUser $Compte.SamAccountName -Properties Department, Title
    $Resultats += [PSCustomObject]@{
        Nom              = $Compte.Name
        Login            = $Compte.SamAccountName
        Departement      = $UserDetail.Department
        Poste            = $UserDetail.Title
        Statut           = "Expire"
        Detail           = "Date expiration : $($Compte.AccountExpirationDate.ToString('dd/MM/yyyy'))"
        Action_Suggere   = "Verifier et supprimer si depart confirme"
    }
}

Write-Host "   $($ComptesExpires.Count) compte(s) expiré(s) trouvé(s)" -ForegroundColor $(if ($ComptesExpires.Count -gt 0) { "Red" } else { "Green" })


# ------------------------------------------------------------------------------
# VÉRIFICATION 3 : Mots de passe qui n'expirent jamais
# ------------------------------------------------------------------------------

Write-Host "[3/4] Recherche des comptes avec mot de passe sans expiration..." -ForegroundColor Yellow

$MDP_NoExpire = Get-ADUser -Filter {
    PasswordNeverExpires -eq $true -and Enabled -eq $true
} -SearchBase $RootOU `
  -Properties PasswordNeverExpires, Department, Title, PasswordLastSet

foreach ($Compte in $MDP_NoExpire) {
    $Resultats += [PSCustomObject]@{
        Nom              = $Compte.Name
        Login            = $Compte.SamAccountName
        Departement      = $Compte.Department
        Poste            = $Compte.Title
        Statut           = "MDP sans expiration"
        Detail           = "Dernier changement MDP : $($Compte.PasswordLastSet)"
        Action_Suggere   = "Verifier si compte de service, sinon corriger"
    }
}

Write-Host "   $($MDP_NoExpire.Count) compte(s) avec MDP sans expiration" -ForegroundColor $(if ($MDP_NoExpire.Count -gt 0) { "Yellow" } else { "Green" })


# ------------------------------------------------------------------------------
# VÉRIFICATION 4 : Comptes verrouillés 
#-------------------------------------------------------------------------------

Write-Host "[4/4] Recherche des comptes verrouillés..." -ForegroundColor Yellow

$ComptesVerrouilles = Search-ADAccount -LockedOut -SearchBase $RootOU -UsersOnly

foreach ($Compte in $ComptesVerrouilles) {
    $UserDetail = Get-ADUser $Compte.SamAccountName -Properties Department, Title, BadLogonCount
    $Resultats += [PSCustomObject]@{
        Nom              = $Compte.Name
        Login            = $Compte.SamAccountName
        Departement      = $UserDetail.Department
        Poste            = $UserDetail.Title
        Statut           = "Verrouille"
        Detail           = "Tentatives echouees : $($UserDetail.BadLogonCount)"
        Action_Suggere   = "Verifier avec l utilisateur, deverrouiller si legitime"
    }
}

Write-Host "   $($ComptesVerrouilles.Count) compte(s) verrouillé(s)" -ForegroundColor $(if ($ComptesVerrouilles.Count -gt 0) { "Yellow" } else { "Green" })


# ------------------------------------------------------------------------------
# EXPORT CSV ET RÉSUMÉ
# ------------------------------------------------------------------------------

if ($Resultats.Count -gt 0) {
    $Resultats | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
    Write-Host "`n Rapport exporté : $ExportPath" -ForegroundColor Cyan
} else {
    Write-Host "`n Aucun problème détecté — tous les comptes sont en ordre !" -ForegroundColor Green
}

Write-Host "`n=== Résumé de l'audit ===" -ForegroundColor Cyan
Write-Host "   Inactifs            : $($ComptesInactifs.Count)" -ForegroundColor $(if ($ComptesInactifs.Count -gt 0) { "Red" } else { "Green" })
Write-Host "   Expirés             : $($ComptesExpires.Count)" -ForegroundColor $(if ($ComptesExpires.Count -gt 0) { "Red" } else { "Green" })
Write-Host "   MDP sans expiration : $($MDP_NoExpire.Count)" -ForegroundColor $(if ($MDP_NoExpire.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "   Verrouillés         : $($ComptesVerrouilles.Count)" -ForegroundColor $(if ($ComptesVerrouilles.Count -gt 0) { "Yellow" } else { "Green" })
Write-Host "   Total à traiter     : $($Resultats.Count)" -ForegroundColor White
