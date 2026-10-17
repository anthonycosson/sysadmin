# Hashcat

`hashcat -a 0 -m 0 -w 4 hash.txt wordlist.txt `

## Basique

* -a : Pour le type d'attaque (0 = Dictionnary).
* -m : Pour le type de hash (0 = MD5).
* -w : Permet de définir la charge de travail pour le GPU (4 permet le plus grosse charge de travail et est donc le plus rapide).

## Liste de tous les types de hash

https://hashcat.net/wiki/doku.php?id=example_hashes