# Gestion des services et processus

Gérer par :

* GUI : Services.msc
* CLI : Get-Service en powershell

Certains services ne peuvent pas être redémarré. Si il y a une mise à jour ou une modification il faudra nécéssairement redémarrer l'appareil.

## Sysinternals Tools

La suite SysInternals Tools est un ensemble d'applications Windows portables qui peuvent être utilisées pour administrer les systèmes Windows (pour la plupart sans installation). 

Les outils peuvent être téléchargés à partir :

* web : https://learn.microsoft.com/fr-fr/sysinternals/downloads/sysinternals-suite
* Partage de fichier : \\live.sysinternals.com\tools


La suite comprend des outils tels que Process Explorer, une version améliorée de Task Manager, et Process Monitor, qui peuvent être utilisés pour surveiller le système de fichiers, le registre et l'activité du réseau lié à tout processus en cours d'exécution sur le système. 

Certains outils supplémentaires sont TCPView, qui est utilisé pour surveiller l'activité Internet, et PSExec, qui peut être utilisé pour gérer/se connecter aux systèmes via le protocole SMB à distance.


## task Manager 

Windows Task Manager est un outil puissant pour gérer les systèmes Windows. Il fournit des informations sur les processus d'exécution, les performances du système, les services d'exécution, les programmes de démarrage, les utilisateurs connectés/les processus utilisateur connectés et les services.

Gérer par :

* GUI : Depuis CTRL + ALT + SUPPR
* CLI : taskmgr

## Local Security Authority Subsystem Service (LSASS) 

Vérifie leur tentative de connexion et crée des jetons d'accès en fonction des niveaux d'autorisation de l'utilisateur. LSASS est également responsable des modifications du mot de passe du compte utilisateur. Tous les événements associés à ce processus (tentatives de connexion/déconnexion, etc.) sont enregistrés dans le journal de sécurité de Windows. 

LSASS est une cible de valeur extrêmement élevée car plusieurs outils existent pour extraire à la fois du texte clair et des informations d'identification hachées stockées en mémoire par ce processus.

## Service Permissions

Il est fortement recommandé de créer un compte d'utilisateur individuel pour exécuter des services réseau critiques. Ceux-ci sont appelés comptes de service.

Le chemin d'accès à l'exécutable est le chemin d'accès complet au programme et à la commande à exécuter au démarrage du service. Si les autorisations NTFS du répertoire de destination sont configurées avec des autorisations faibles, un attaquant pourrait remplacer l'exécutable d'origine par un exécutable créé à des fins malveillantes.

La plupart des services fonctionnent avec les privilèges LocalSystem par défaut, ce qui est le niveau d'accès le plus élevé autorisé sur un système d'exploitation Windows individuel. 

Toutes les applications n'ont pas besoin d'autorisations au niveau du compte du système local, il est donc bénéfique d'effectuer des recherches au cas par cas lorsque vous envisagez d'installer de nouvelles applications dans un environnement Windows. 

Comptes de service intégrés notables dans Windows : 

* LocalService
* NetworkService
* LocalSystem

L'onglet de récupération permet de configurer les étapes en cas d'échec d'un service. Ce service peut être configuré pour exécuter un programme après la première défaillance. C'est encore un autre vecteur qu'un attaquant pourrait utiliser pour exécuter des programmes malveillants en utilisant un service légitime.

## Examining services using sc

sc est la version en ligne de commande de services.msc.

* sc qc <service> : Permet d'interroger un service pour l'examiner.
* sc <ip> or <hostname> <service> : Permet d'interroger un service pour l'examiner depuis le réseau.
* sc start or stop : permet de démarrer ou d'éteindre un service.
* sc sdshow <service> : permet d'examiner les permissions du service en ligne de commande.

Chaque objet nommé dans Windows est un objet sécurisable, et même certains objets sans nom sont sécurisables. S'il est sécurisé dans un système d'exploitation Windows, il aura un descripteur de sécurité. Les descripteurs de sécurité identifient le propriétaire de l'objet et un groupe primaire contenant une liste de contrôle d'accès discrétionnaire (DACL) et une liste de contrôle d'accès au système (SACL).

## Examine service permissions using PowerShell

À l'aide de l'applet de commande `Get-Acl` PowerShell, nous pouvons examiner les autorisations de service en ciblant le chemin d'accès d'un service spécifique dans le registre.

Cette commande renvoie des autorisations de compte spécifiques dans un format facile à lire et en SDDL. De plus, le SID qui représente chaque principal de sécurité (utilisateur et/ou groupe) est présent dans la SDDL. C'est quelque chose que nous n'ocentons pas lors de l'exécution de sc à partir de l'invite de commande.