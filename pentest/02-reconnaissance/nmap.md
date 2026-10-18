# Nmap

`nmap -sS -Pn -p- target -v`

## Basique

* -sS (Sync Scan): C'est la méthode par défaut et la plus silencieuse. Nmap tente d'ouvrir une connexion TCP sans jamais la terminée pour vérifier si la cible est disponible.
* -Pn : Pour ne pas ping (Si on sait que le ping ne répondra pas sur la machine par exemple).
* -p- : Pour scanner tous les ports.
* -v : Active le mode verbose pour plus de détails.

## Autres options

* -p : Permet de choisir une plage ou une liste de port spécifique à scanner (1-65535 ou 80,443).
* -oN fichier.txt : Pour exporter les résultats dans un fichier texte dans un format normal.
