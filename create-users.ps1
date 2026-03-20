# ==============================================================================
# create-users.ps1
# ==============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$CsvPath
)

Import-Module ActiveDirectory

# ------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------

$DomainDN  = "DC=DOMAIN,DC=COM"
$DomainUPN = "domain.com"             
$RootOU    = "OU=Entreprise,$DomainDN"

$DefaultPassword = ConvertTo-SecureString "Bienvenue123!" -AsPlainText -Force

# Table de correspondance
$OUMapping = @{
    "Direction"    = "OU=Direction,$RootOU"
    "RH"           = "OU=RH,$RootOU"
    "Informatique" = "OU=Informatique,$RootOU"
    "Comptabilite" = "OU=Comptabilite,$RootOU"
}


# ------------------------------------------------------------------------------
# ÉTAPE 1 : Lecture du CSV
# ------------------------------------------------------------------------------

Write-Host "`n=== Import des utilisateurs depuis '$CsvPath' ===" -ForegroundColor Cyan

if (-not (Test-Path $CsvPath)) {
    Write-Host "Fichier CSV introuvable : $CsvPath" -ForegroundColor Red
    exit 1
}

$Utilisateurs = Import-Csv -Path $CsvPath -Delimiter ","
Write-Host "   $($Utilisateurs.Count) utilisateurs trouvés`n" -ForegroundColor Green


# ------------------------------------------------------------------------------
# ÉTAPE 2 : Création des comptes en boucle
# ------------------------------------------------------------------------------

$Succes = 0
$Echecs = 0

foreach ($User in $Utilisateurs) {

    # Construction du login
    $Login = "$($User.Prenom).$($User.Nom)".ToLower() `
             -replace '[éèêë]','e' `
             -replace '[àâä]','a'  `
             -replace '[ùûü]','u'  `
             -replace '[ôö]','o'   `
             -replace '[îï]','i'   `
             -replace ' ',''

    $UPN        = "$Login@$DomainUPN"
    $NomComplet = "$($User.Prenom) $($User.Nom)"
    $OU         = $OUMapping[$User.Departement]

    if (-not $OU) {
        Write-Host "   Département inconnu '$($User.Departement)' pour $NomComplet — ignoré" -ForegroundColor Yellow
        $Echecs++
        continue
    }

    $ExisteDeja = Get-ADUser -Filter { SamAccountName -eq $Login } -ErrorAction SilentlyContinue
    if ($ExisteDeja) {
        Write-Host "   $NomComplet ($Login) existe déjà — ignoré" -ForegroundColor Yellow
        $Echecs++
        continue
    }

    # Création du compte AD
    try {
        New-ADUser `
            -SamAccountName        $Login `
            -UserPrincipalName     $UPN `
            -GivenName             $User.Prenom `
            -Surname               $User.Nom `
            -Name                  $NomComplet `
            -DisplayName           $NomComplet `
            -Title                 $User.Poste `
            -Department            $User.Departement `
            -Path                  $OU `
            -AccountPassword       $DefaultPassword `
            -Enabled               $true `
            -ChangePasswordAtLogon $true 

        Write-Host "   ✓ $NomComplet → $UPN  [$($User.Departement)]" -ForegroundColor Green
        $Succes++

    } catch {
        Write-Host "  Erreur pour $NomComplet : $_" -ForegroundColor Red
        $Echecs++
    }
}


# ------------------------------------------------------------------------------
# RÉSUMÉ
# ------------------------------------------------------------------------------

Write-Host "`n=== Résumé ===" -ForegroundColor Cyan
Write-Host "  Créés  : $Succes" -ForegroundColor Green
Write-Host "  Ignorés : $Echecs" -ForegroundColor Yellow
Write-Host "  MDP temporaire: $DefaultPassword" -ForegroundColor Yellow
