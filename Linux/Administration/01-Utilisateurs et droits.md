# Gestion des utilisateurs

## Les commandes de base 

* useradd : Permet de créer ou de mettre à jour les informations par défaut d'un utilisateur.
* userdel : Permet de supprimer un utilisateurs ainsi que ses fichiers.
* usermod : Permet de modifier un utilisateur.
* groupadd : Permet d'ajouter un groupe sur le système.
* groupdel : Permet de supprilmer un groupe sur le système.
* passwd : Permet de changer le mot de passe d'un utilisateur.

### Exemples

* Ajouter un utilisateur dans un groupe : `usermod -aG nomdugroup groupe utilisateur`

# Gestion des permissions

## RWX

* R (4) : Permet de lire le contenue d'un fichier.
* W (2) : Permet de créer, supprimer et renommer un dossier ou un fichier.
* X (1) : Permet de traverser et d'accéder au contenu d'un dossier. Cela ne permet pas d'éxécuter un fichier qui se trouve à l'intérieur. Pour ça il faut avoir des droits d'éxécution sur le fichier en question.

## Propriétaires et droits

* chown : Permet de modifier de propriétaire et le groupe propriétaire d'un dossier
* chmod : Permet de changer le droits du dossier

### Exemples

* Changer le propriétaire d'un dossier ou fichier :  `chown newuser:newgroupe file.txt`
* Changer les droits d'accès à un dossier ou fichier `chmod 754 file.txt`


