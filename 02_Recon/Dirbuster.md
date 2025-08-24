# Dirbuster

`dirbuster -e "html,php,asp,aspx,txt" -u "http://target:80" -R -l wordlist `

## Basique

* -e : Pour définir les extensions de fichier à chercher (html,php,asp,aspx,txt...).
* -u : Pour définir l'URL cible.
* -l : Pour définir la Wordlist à utiliser pour l'énumération.

## Autres options

* -r file.txt : Pour exporter le résultat dans un fichier texte.
* -s : Permet de définir à partir de quel niveau de l'URL on veut commencer l'énumération (Défault: /).
* -R : Permet de ne pas faire d'énumération récursive dans le cas ou une page est trouvé. Permet de gagner en rapidité lors du scan initial.
