# Configuration d'un pare-feu Watchguard

## Prérequis

Avant de configurer un pare-feu il faut s'assurer d'avoir suivi les étapes suivantes :

* Activation du produit : https://myproducts.watchguard.com/manage-products
* Affectation de la licence (Si du MSSP) : https://portal.watchguard.com/msspcommand
* Allouer le pare-feu au client : https://deu.cloud.watchguard.com/sp-overview/inventory/firebox-unallocated
* Récupérer la clé de fonctionnalité : https://myproducts.watchguard.com/manage-products

## Configuration 

### Nouveau pare-feu

"Work in progress"

### Remplacement

* Se connecter sur l'ancien pare-feu via WSM puis enregistrer la configuration en local
* Ouvrir le fichier de configuration xml via Policy Manager (Sans se connecter au pare-feu ou au serveur) puis l'enregistrer sur le nouveau pare-feu.
* Importer la clé de fonctionnalité
* Modifier le mot de passe du compte Admin et Status
* Activer la connexion à Watchguard Cloud (A faire une fois le pare-feu sur site)
* Ajouter le nouveau Pare-feu sur le serveur de Management (A faire une fois le pare-feu sur site)