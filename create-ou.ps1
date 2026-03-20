# ==============================================================================
# create-ou.ps1
# ==============================================================================

Import-Module ActiveDirectory

$DomainDN = "DC=DOMAIN,DC=COM" 

Write-Host "`n=== Création de la structure des OU pour DOMAIN.COM ===" -ForegroundColor Cyan


# ------------------------------------------------------------------------------
# ÉTAPE 1 : OU racine "Entreprise"
# ------------------------------------------------------------------------------

Write-Host "`n[1/3] Création de l'OU racine 'Entreprise'..." -ForegroundColor Yellow

New-ADOrganizationalUnit `
    -Name                            "Entreprise" `
    -Path                            $DomainDN `
    -Description                     "Conteneur racine de tous les objets de l'entreprise" `
    -ProtectedFromAccidentalDeletion $true 

$RootOU = "OU=Entreprise,$DomainDN"
Write-Host "   OU 'Entreprise' créée" -ForegroundColor Green


# ------------------------------------------------------------------------------
# ÉTAPE 2 : OUs par département
# ------------------------------------------------------------------------------

Write-Host "`n[2/3] Création des OUs départements..." -ForegroundColor Yellow

$Departements = @(
    @{ Nom = "Direction";    Description = "Directeurs et cadres dirigeants" },
    @{ Nom = "RH";           Description = "Ressources Humaines" },
    @{ Nom = "Informatique"; Description = "Equipe IT et administrateurs systeme" },
    @{ Nom = "Comptabilite"; Description = "Service comptabilite et finance" }
)

foreach ($Dept in $Departements) {
    New-ADOrganizationalUnit `
        -Name                            $Dept.Nom `
        -Path                            $RootOU `
        -Description                     $Dept.Description `
        -ProtectedFromAccidentalDeletion $true
    Write-Host "  OU '$($Dept.Nom)' créée" -ForegroundColor Green
}


# ------------------------------------------------------------------------------
# ÉTAPE 3 : OUs spéciales
# ------------------------------------------------------------------------------

Write-Host "`n[3/3] Création des OUs spéciales..." -ForegroundColor Yellow

$OUsSpeciales = @(
    @{ Nom = "Ordinateurs";     Description = "Postes clients du domaine" },
    @{ Nom = "Groupes";         Description = "Groupes de securite et de distribution" },
    @{ Nom = "ServiceAccounts"; Description = "Comptes de service applicatifs" }
)

foreach ($OU in $OUsSpeciales) {
    New-ADOrganizationalUnit `
        -Name                            $OU.Nom `
        -Path                            $RootOU `
        -Description                     $OU.Description `
        -ProtectedFromAccidentalDeletion $true
    Write-Host "  OU '$($OU.Nom)' créée" -ForegroundColor Green
}


# ------------------------------------------------------------------------------
# RÉSUMÉ visuel de la structure créée
# ------------------------------------------------------------------------------

Write-Host "`n=== Structure créée ===" -ForegroundColor Cyan
Write-Host "DOMAIN.COM"
Write-Host "└── Entreprise"
Write-Host "    ├── Direction"
Write-Host "    ├── RH"
Write-Host "    ├── Informatique"
Write-Host "    ├── Comptabilite"
Write-Host "    ├── Ordinateurs"
Write-Host "    ├── Groupes"
Write-Host "    └── ServiceAccounts"
