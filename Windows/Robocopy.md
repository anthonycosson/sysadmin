#Robocopy

`ROBOCOPY "Source" "Destination" /E /XO /ETA /w:1 /R:1`

## Default options

* /E : Copie les sous-répertoires. Cette option inclut automatiquement les répertoires vides.
* /XO : Les fichiers du répertoire source plus anciens que la destination sont exclus de la copie.
* /ETA : Affiche l’heure d’arrivée estimée (ETA) des fichiers copiés.
* /W : 	Spécifie le délai d’attente entre les tentatives, en secondes. La valeur par défaut de n est 30 (temps d’attente de 30 secondes).
* /R : Spécifie le nombre de nouvelles tentatives en cas d’échec de la copie. La valeur par défaut de n est 1000000 (un million de tentatives).


## Source

https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy
