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
- Le nom d'un script commence par ce qu'il fait (`audit-`, `configurer-`, `desactiver-`, `exporter-`…).

## Ton

- Neutre et impersonnel : pas de « je », « nous », « vous » ni « on ».
- Consignes à l'infinitif (« Lancer le script », « Laisser vide »).
- Articles indéfinis : « sécuriser **une** machine d'attaque », pas « **ma** machine » ni « **la** machine ».
- Même règle pour les commentaires des scripts.

## Données sensibles

Le dépôt est **public**. Aucun nom de client, adresse IP, identifiant, ID de tenant ou mot de passe réel. Les exemples utilisent des valeurs génériques : `192.168.X.X`, `contoso.com`, `fabrikam.com`, `XXX`.
