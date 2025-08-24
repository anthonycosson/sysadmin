#Monitorer des pertes de paquets

`ping -t google.com|Foreach{"{0} - {1}" -f (Get-Date),$_} > destination.txt`

##DefaultOptions

* > : Permet de choisir un fichier de sortie
