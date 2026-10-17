# Hydra

`hydra -L login.txt -P file.txt -s 80 target service`

## Basique

* -L : Pour définir un ficher contenant une liste d'utilisateurs. -l pour définir l'utilisateur manuellement.
* -P : Pour définir un ficher contenant une liste de mot de passe. -p pour définir le mot de passe manuellement.
* -s : Pour définir le port à utiliser. 

## Autres options

* -o file.txt : Pour exporter le résultat des combos de login / mot de passe découvert dans un fichier texte plutôt qu'en STDOUT.

