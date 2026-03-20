# Labo-AD
Projet de lab personnel simulant un environnement d'entreprise complet avec Active Directory, déployé sur Hyper-V et automatisé via PowerShell.

Objectif
Ce projet reproduit l'infrastructure d'une PME fictive (CORP.LOCAL) avec :

Un contrôleur de domaine Windows Server 2025
Des postes clients Windows 11 joints au domaine
Des utilisateurs et groupes créés automatiquement via PowerShell
Des GPO (Group Policy Objects) appliquées pour la sécurité

Schéma du réseau
Réseau NAT Hyper-V : 192.168.100.0/24
│
├── DC01 (Windows Server 2025)
│   IP : 10.0.0.1
│   Rôles : AD DS, DNS, DHCP
│
├── CLIENT01 (Windows 11)
│   IP : 10.0.0.100 (DHCP)
│   Domaine : DOMAIN.COM
│
└── CLIENT02 (Windows 11)
    IP : 10.0.0.101 (DHCP)
    Domaine : DOMAIN.COM

Installation

Étape 1 — Créer les VMs Hyper-V
Depuis la machine hôte, lancer en tant qu'administrateur :
.\hyperv\setup-vm.ps1
Ce script crée automatiquement les VMs DC01 et CLIENT01 avec la mémoire et le réseau configurés.

Étape 2 — Installer Active Directory sur DC01
Sur DC01, après installation de Windows Server :
.\active-directory\install-ad.ps1
Le serveur va redémarrer automatiquement après la promotion en contrôleur de domaine.

Étape 3 — Créer la structure organisationnelle (OU)
.\active-directory\create-ou.ps1
Crée les Unités d'Organisation : Direction, RH, Informatique, Comptabilité.

Étape 4 — Créer les utilisateurs depuis un CSV
.\active-directory\create-users.ps1 -CsvPath .\active-directory\users.csv
Importe tous les utilisateurs du fichier CSV et les place dans la bonne OU automatiquement.

Étape 5 — Appliquer les GPO de sécurité
.\gpo\gpo-securite.ps1

Ce que j'ai appris

Déploiement d'un contrôleur de domaine Windows Server en ligne de commande
Gestion des objets Active Directory (utilisateurs, groupes, OU) via PowerShell
Création et liaison de GPO pour sécuriser le domaine
Automatisation de tâches répétitives (import CSV, création en masse)
Infrastructure réseau virtuelle avec Hyper-V
