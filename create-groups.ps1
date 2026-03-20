# ==============================================================================
# create-groups.ps1
# ==============================================================================

Import-Module ActiveDirectory

$DomainDN  = "DC=DOMAIN,DC=COM"
$RootOU    = "OU=Entreprise,$DomainDN"
$GroupesOU = "OU=Groupes,$RootOU"

Write-Host "`n=== Création des groupes de sécurité ===" -ForegroundColor Cyan


# ------------------------------------------------------------------------------
# ÉTAPE 1 : Création des groupes
# ------------------------------------------------------------------------------

Write-Host "`n[1/2] Création des groupes..." -ForegroundColor Yellow

$Groupes = @(
    # Groupes par département (membres = tous les users du département)
    @{ Nom = "GRP_Direction";    Description = "Membres de la direction" },
    @{ Nom = "GRP_RH";           Description = "Membres des Ressources Humaines" },
    @{ Nom = "GRP_Informatique"; Description = "Membres de l equipe IT" },
    @{ Nom = "GRP_Comptabilite"; Description = "Membres de la comptabilite" },

    # Groupes fonctionnels (accès à des ressources spécifiques)
    @{ Nom = "GRP_Acces_Partage_RH";  Description = "Acces au dossier partage RH" },
    @{ Nom = "GRP_VPN_Users";         Description = "Utilisateurs autorises a se connecter en VPN" },
    @{ Nom = "GRP_Admins_Locaux";     Description = "Admins locaux sur les postes du domaine" }
)

foreach ($Groupe in $Groupes) {
    $Existe = Get-ADGroup -Filter { Name -eq $Groupe.Nom } -ErrorAction SilentlyContinue

    if ($Existe) {
        Write-Host "  '$($Groupe.Nom)' existe déjà — ignoré" -ForegroundColor Yellow
        continue
    }

    New-ADGroup `
        -Name          $Groupe.Nom `
        -GroupScope    "Global" `
        -GroupCategory "Security" `
        -Path          $GroupesOU `
        -Description   $Groupe.Description

    Write-Host "   Groupe '$($Groupe.Nom)' créé" -ForegroundColor Green
}


# ------------------------------------------------------------------------------
# ÉTAPE 2 : Ajout des membres dans les groupes départementaux
#-------------------------------------------------------------------------------

Write-Host "`n[2/2] Ajout des membres dans les groupes..." -ForegroundColor Yellow

$DeptMapping = @{
    "GRP_Direction"    = "OU=Direction,$RootOU"
    "GRP_RH"           = "OU=RH,$RootOU"
    "GRP_Informatique" = "OU=Informatique,$RootOU"
    "GRP_Comptabilite" = "OU=Comptabilite,$RootOU"
}

foreach ($GroupeNom in $DeptMapping.Keys) {
    $OUCible      = $DeptMapping[$GroupeNom]
    $Utilisateurs = Get-ADUser -Filter * -SearchBase $OUCible

    if ($Utilisateurs.Count -eq 0) {
        Write-Host "   Aucun utilisateur dans $OUCible" -ForegroundColor Yellow
        continue
    }

    Add-ADGroupMember -Identity $GroupeNom -Members $Utilisateurs
    Write-Host "   $($Utilisateurs.Count) membre(s) ajouté(s) dans '$GroupeNom'" -ForegroundColor Green
}


Write-Host "`n Groupes créés et membres ajoutés avec succès !" -ForegroundColor Green
Write-Host "   Prochaine étape : exécuter gpo-securite.ps1" -ForegroundColor White
