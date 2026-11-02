# CLAUDE.md

Consignes pour écrire et ranger les notes de ce dépôt.

## Organisation

- Les dossiers de premier niveau sont **numérotés** pour suivre l'ordre de l'infrastructure, des fondations vers les usages : `01-reseau`, `02-virtualisation`, `03-windows`, `04-linux`, `05-microsoft-365`, `06-pentest`.
- Un nouveau domaine prend le numéro suivant. Renuméroter un dossier oblige à corriger les liens du `README.md` racine.
- Un fichier = un sujet. Chaque dossier a son `README.md` qui liste ce qu'il contient, avec une ligne de description par fichier.
- Toute note ajoutée, déplacée ou renommée est reportée dans le `README.md` de son dossier, et dans le sommaire racine si le contenu du dossier change.
- Un script seul reste à côté des notes de son sujet. Quand un sujet en a plusieurs, ils vont dans un sous-dossier `scripts/`.
- Les images vont dans un sous-dossier `assets/` du dossier concerné.

## Nommage

- Dossiers et fichiers **en français, en minuscules, séparés par des tirets** (ex. `partages-et-permissions.md`, `exporter-boites-aux-lettres.ps1`).
- **Aucun accent ni caractère spécial** dans les noms (`reseau`, pas `réseau`) : macOS et Linux n'encodent pas les accents de la même façon, et ils deviennent illisibles dans les URL. Les accents restent normaux dans le contenu des fichiers.
- Les noms d'outils et de produits gardent leur nom d'origine (`nmap`, `robocopy`, `proxmox`).
- **Notes : le sujet d'abord, l'action ensuite** (`debian-installation.md`, `proxmox-creer-une-vm.md`, `smtp-tester-avec-telnet.md`). Le tri alphabétique regroupe ainsi les notes d'un même sujet.
- **Scripts : le verbe d'abord** (`audit-`, `configurer-`, `desactiver-`, `exporter-`…), comme la convention PowerShell `Verbe-Nom` : un script se cherche par ce qu'il fait.

## Ton

- Neutre et impersonnel : pas de « je », « nous », « vous » ni « on ».
- Consignes à l'infinitif (« Lancer le script », « Laisser vide »).
- Articles indéfinis : « sécuriser **une** machine d'attaque », pas « **ma** machine » ni « **la** machine ».
- Même règle pour les commentaires des scripts.

## Données sensibles

Le dépôt est **public**. Aucun nom de client, adresse IP, identifiant, ID de tenant ou mot de passe réel. Les exemples utilisent des valeurs génériques : `192.168.X.X`, `contoso.com`, `fabrikam.com`, `XXX`.
