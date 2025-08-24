# Gestion des partages et des permissions

## Types de permissions

Les fichiers et dossiers héritent des autorisations NTFS de leur dossier parent pour faciliter l'administration, de sorte que les administrateurs n'ont pas besoin de définir explicitement des autorisations pour chaque fichier et dossier, car cela prendrait beaucoup de temps. 

Si les autorisations doivent être définies explicitement, un administrateur peut désactiver l'héritage des autorisations pour les fichiers et dossiers nécessaires, puis définir les autorisations directement sur chacun d'eux.

### Share Permissions

* Full Control : Les utilisateurs sont autorisés à effectuer toutes les actions données par les autorisations de modification et de lecture ainsi qu'à modifier les autorisations pour les fichiers et sous-dossiers NTFS.
* Change : Les utilisateurs sont autorisés à lire, modifier, supprimer et ajouter des fichiers et des sous-dossiers
* Read : Les utilisateurs sont autorisés à afficher le contenu des fichiers et des sous-dossiers

### NTFS 

* Full Control : Permet de lire, d'écrire, de modifier, de supprimer des fichiers/dossiers.
* Modify : Permet de lire, d'écrire et de supprimer des fichiers/dossiers.
* List Folder Contents : Permet de visualiser et de répertorier les dossiers et les sous-dossiers ainsi que l'exécution de fichiers. Les dossiers n'héritent que de cette autorisation.
* Read and Execute : Permet d'afficher et d'énumérer les fichiers et les sous-dossiers ainsi que l'exécution de fichiers. Les fichiers et dossiers héritent de cette autorisation.
* Write : Permet d'ajouter des fichiers à des dossiers et des sous-dossiers et d'écrire dans un fichier.
* Read : Permet de visualiser et de répertorier les dossiers et les sous-dossiers et de visualiser le contenu d'un fichier.
* Traverse Folder : Cela permet ou nie la possibilité de se déplacer dans les dossiers pour atteindre d'autres fichiers ou dossiers.

### Share Permission vs NTFS 

Les autorisations de partage s'appliquent lorsque le dossier est accessible via SMB, généralement à partir d'un autre système sur le réseau. Cela signifie que quelqu'un qui s'est connecté localement à la machine ou via RDP peut accéder au dossier et aux fichiers partagés en naviguant simplement jusqu'à l'emplacement du système de fichiers et qu'il suffit de prendre en compte les autorisations NTFS. Les autorisations au niveau NTFS offrent aux administrateurs un contrôle beaucoup plus granulaire sur ce que les utilisateurs peuvent faire dans un dossier ou un fichier.


### Integrity Control Access Control List (icacls)

Les autorisations NTFS sur les fichiers et dossiers dans Windows peuvent être gérées à l'aide de l'interface graphique de l'Explorateur de fichiers sous l'onglet Sécurité. 

Outre l'interface graphique, nous pouvons également atteindre un niveau de granularité élevé sur les autorisations de fichiers NTFS dans Windows à partir de la ligne de commande à l'aide de l'utilitaire `icacls`. 

Le niveau d'accès aux ressources est répertorié après chaque utilisateur. Les paramètres d'héritage possibles sont :

* (CI): container inherit
* (OI): object inherit
* (IO): inherit only
* (NP): do not propagate inherit
* (I): permission inherited from parent container

![alt text](<Images/permissions.png>)

Les autorisations d'accès de base sont les suivantes : 

* F : full access
* M :  modify access
* RX :  read and execute access
* W :  write-only access
* R :  read-only access
* D :  delete access
* N :  no access


En utilisant la commande `icacls c:\users /grant joe:f`, nous pouvons accorder à l'utilisateur joe un contrôle total sur le répertoire.

Mais étant donné que (oi) et (ci) n'ont pas été inclus dans la commande iln'aura que des droits sur le dossier c:\users, mais pas sur les sous-répertoires de l'utilisateur et les fichiers qu'ils contiennent.

Pour supprimer les droits on utile la commande `icacls c:\users /remove joe`.

## Gestion des partages 

* Net Share : Permet d'affiche tous les dossier partagés

En GUI cela permet aussi de voir les sessions ouvertes ainsi que les fichiers.

![alt text](<Images/partages.png>)