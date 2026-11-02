# 🛠️ Sysadmin

Notes d'administration système : procédures, commandes et scripts d'usage courant, pour Windows, Linux et Microsoft 365.

Ce sont des notes de terrain, écrites pour être retrouvées vite. Elles ne remplacent pas la documentation officielle.

## 📑 Sommaire

| Dossier | Contenu |
|---|---|
| [🪟 windows](windows/) | PowerShell, sécurité, partages et permissions, services, sessions, outils |
| [🐧 linux](linux/) | Installation Debian, utilisateurs et droits, partages |
| [☁️ microsoft-365](microsoft-365/) | Entra ID, Exchange Online, SharePoint, sécurisation d'un tenant |
| [📦 virtualisation](virtualisation/) | Docker, Proxmox |
| [🌐 reseau](reseau/) | Pare-feu WatchGuard, impression, SMTP, certificats |
| [🕵️ pentest](pentest/) | Cheatsheet pentest, de la reconnaissance à l'élévation de privilèges |

## 🏷️ Conventions

- Noms de dossiers et de fichiers **en minuscules, séparés par des tirets** (ex. `partages-et-permissions.md`).
- Ton neutre et impersonnel : pas de « je », « nous », « vous » ni « on », et des articles indéfinis (« sécuriser **une** machine », pas « **ma** machine »).
- Un fichier = un sujet. Chaque dossier a son `README.md` qui liste ce qu'il contient.
- Les images vont dans un sous-dossier `assets/` du dossier concerné.
- Aucun nom de client, adresse IP, identifiant ou mot de passe réel : les exemples utilisent des valeurs génériques (`192.168.X.X`, `contoso.com`).

## ⚠️ Avertissement

Ces commandes sont données telles quelles. Les tester sur un environnement de test avant de les lancer en production.

Le dossier [pentest](pentest/) ne doit servir que sur des systèmes personnels ou avec une autorisation écrite.
