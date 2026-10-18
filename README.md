# 🛠️ Sysadmin

Mes notes d'administrateur système : procédures, commandes et scripts que j'utilise au quotidien, sur Windows, Linux et Microsoft 365.

Ce sont des notes de terrain, écrites pour être retrouvées vite. Elles ne remplacent pas la documentation officielle.

## 📑 Sommaire

| Dossier | Contenu |
|---|---|
| [🪟 windows](windows/) | PowerShell, sécurité, partages et permissions, services, sessions, outils |
| [🐧 linux](linux/) | Installation Debian, utilisateurs et droits, partages |
| [☁️ microsoft-365](microsoft-365/) | Entra ID, Exchange Online, SharePoint |
| [📦 virtualisation](virtualisation/) | Docker, Proxmox |
| [🌐 reseau](reseau/) | Pare-feu WatchGuard, impression, SMTP |
| [🔒 web](web/) | Certificats, noms de domaine, reverse proxy |
| [🕵️ pentest](pentest/) | Cheatsheet pentest, de la reconnaissance à l'élévation de privilèges |

## 🏷️ Conventions

- Noms de dossiers et de fichiers **en minuscules, séparés par des tirets** (ex. `partages-et-permissions.md`).
- Un fichier = un sujet. Chaque dossier a son `README.md` qui liste ce qu'il contient.
- Les images vont dans un sous-dossier `assets/` du dossier concerné.
- Aucun nom de client, adresse IP, identifiant ou mot de passe réel : les exemples utilisent des valeurs génériques (`192.168.X.X`, `contoso.com`).

## ⚠️ Avertissement

Ces commandes sont données telles quelles. Testez-les sur un environnement de test avant de les lancer en production.

Le dossier [pentest](pentest/) ne doit servir que sur des systèmes que vous possédez ou pour lesquels vous avez une autorisation écrite.
