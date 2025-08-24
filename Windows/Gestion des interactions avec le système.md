# Gestion des interactions avec le système

## les méthodes 

* GUI : Via l'interface Graphique
* RDP : Via l'interface Graphique mais à distance
* CMD : cmd.exe
* Powershell : Via l'utilisation de Cmdlets tel que (Get-Alias)
* Script : PowerShell ISE (Integrated Scripting Environment) permet aux utilisateurs d'écrire des scripts PowerShell à la volée.

## Execution Policy

Parfois, nous constaterons que nous sommes incapables d'exécuter des scripts sur un système. Cela est dû à une fonctionnalité de sécurité appelée politique d'exécution, qui tente d'empêcher l'exécution de scripts malveillants. Les politiques possibles sont :

* AllSigned : Tous les scripts peuvent être exécutés, mais un éditeur de confiance doit signer des scripts et des fichiers de configuration. Cela inclut à la fois des scripts distants et locaux. Nous recevons une invite avant d'exécuter des scripts signés par des éditeurs que nous n'avons pas encore répertoriés comme fiables ou non.
* Bypass : Aucun script ou fichier de configuration n'est bloqué, et l'utilisateur ne reçoit aucun avertissement ou invite.
* Default : Cela définit la politique d'exécution par défaut, Restricted for Windows desktop machines et RemoteSigned for Windows servers.
* RemoteSigned : Les scripts peuvent s'exécuter mais nécessitent une signature numérique sur les scripts qui sont téléchargés à partir d'Internet. Les signatures numériques ne sont pas nécessaires pour les scripts écrits localement.
* Restricted : Cela permet des commandes individuelles, mais ne permet pas l'exécution de scripts. Tous les types de fichiers de script, y compris les fichiers de configuration (.ps1xml), les fichiers de script de module (.psm1) et les profils PowerShell (.ps1) sont bloqués.
* Undefined : Aucune politique d'exécution n'est définie pour la portée actuelle. Si la politique d'exécution pour TOUTES les étendues est définie sur undefined, la politique d'exécution par défaut de Restricted sera utilisée.
* Unrestricted : Il s'agit de la politique d'exécution par défaut pour les ordinateurs non Windows, et elle ne peut pas être modifiée. Cette politique permet d'exécuter des scripts non signés, mais avertit l'utilisateur avant d'exécuter des scripts qui ne proviennent pas de la zone intranet locale.