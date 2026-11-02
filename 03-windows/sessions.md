# Gestion des sessions

## Interactive

Une session de connexion interactive ou locale est initiée par un utilisateur qui s'authentifie auprès d'un système local ou de domaine en entrant ses informations d'identification. 

Une connexion interactive peut être initiée en se connectant directement au système, en demandant une session de connexion secondaire à l'aide de la commande `runas` via la ligne de commande ou via une connexion Bureau à distance.

## Non-interactive

Les comptes non interactifs dans Windows diffèrent des comptes d'utilisateur standard car ils ne nécessitent pas d'identifiants de connexion. 

Il existe 3 types de comptes non interactifs : 

* Local System : NT AUTHORITY\SYSTEM
* Local Service : NT AUTHORITY\LocalService
* Network Service : NT AUTHORITY\NetworkService

Les comptes non interactifs sont généralement utilisés par le système d'exploitation Windows pour démarrer automatiquement les services et les applications sans nécessiter d'interaction de l'utilisateur. 

Ces comptes n'ont pas de mot de passe qui leur est associé et sont généralement utilisés pour démarrer les services lorsque le système démarre ou pour exécuter des tâches planifiées.