# Présentation

Docker fonctionne grâce à plusieurs éléments : 

- **Images** : Mise à disposition par les éditeurs de logiciels et disponible sur Docker Hub
- **Les volumes** : Permet de stocker des données de façon persistente
- **Les réseaux** : Bridge, Host ou None pour définir l’exposition du conteneur.
- **Conteneurs :** C’est le cumul des autres élements qui forme l’application.

Les commandes à retenir sont donc celles qui vont permettre de manipuler l’ensemble de ces éléments :

`docker pull XXX`  : Permet de télécharger une image

`docker image`: Permet manipuler une image (`ls, rm,—-prune`)

`docker volume`  : Permet de manipuler un volume (`ls,create,rm`)

`docker network` : Permet de manipuler un réseau (`ls,create,rm`)

`docker container` : Permet de manipuler un conteneur (`ls, start, stop, rm`)

`docker compose` : Permet de manipuler une stack (`up -d, down, down —volumes`) 

`docker ps` : Affiche tout les conteneurs actifs.

Pour lancer une image (un service) dans un conteneur il suffit de faire un `docker run` de celle-ci avec quelques arguments supplémentaires qu’il faudra retaper à chaque fois qu’on voudra démarrer le conteneur. 

Ce n’est pas pratique, on ne peut déployer qu’un seul conteneur en même temps et ça n’est pas possible de standardiser les déploiements. Il faut donc utiliser docker compose

# Docker compose

## Top Level Elements

Docker compose permet de déployer un ou plusieurs services contenant tout les arguments nécéssaire dans un fichier docker-compose.yaml.

Ce fichier contient les éléments suivants  :

- name : Permet de définir le nom du projet / de la stack
- services : Permet de définir les services à lancer
- volumes : Permet de définir ou seront stocker les données persistante
- networks : Permet de définir à quel réseaux appartiennent nos service.

L’ensembles de ces éléments ne sont pas obligatoire à chaque fois mais il est fortement recommandé de les renseigner pour une meilleurs maitrise des déploiements.

- name : Si définit cela servira a identifier la Stack de service. Aussi, ce nom sera utilisé en préfixe lors de la création des volumes. (ex: name_volume)
- services: Permet de définir les services qui composes la stack ainsi que les paramètres pour chaque services.
- volumes : Sans arguments, il permet de créer le volume automatique au format “nomduprojet_nomduconteneur”
- networks : permet définir le réseau par défaut pour la stack en définissant un nom et un type de driver spécifique (Bridge, Host, None)

## Attributs

Chaque Top Level Elements contient des attributs que nous allons détailler ici :

### Name

Il y a juste le nom, rien de plus.

### Services

Image : l’image à lancer

Container_name : le nom du conteneur

user : permet de définir un autre utilisateur que root pour exécuter le conteneur (ex: 1000:1000)

environnement : quelques variables d’environnement particulière

volumes : volumelocal:/dossierduconteneur (Pas besoin de définir le prefix de la stack, il sera ajouté automatiquement grace au “name”). On peut aussi faire un mount bind qui permet de monter un partage un volume complétement indépendant de docker.

networks : définit a quel réseau doit appartenir le conteneur. Il faut choisir parmit les réseau déclarer à la fin du fichier.

port : C’est le port de la machine local à mapper vers le port de l’application. Valable uniquement lors d’un conteneur en Bridge. En host le port est directement exposé sur l’hote.

restart : permet de définir les options au moment du redémarrage de l’hote.

### Volumes :

Permet de déclarer les volumes à créer ou utiliser pour la stack.

Si on peut que le volume se crée automatiquement il suffit de mettre “nomduvolumelocal:” et celui sera créé automatiquement au format “nomdelastack_nomduconteneur”.

name : Permet de définir un nom manuellement

external : Permet de dire qu’on ne doit pas créer le volume car il existe déjà. un message d’erreur apparaitra si ça n’est pas le cas.

### Networks :

Permet déclarer les réseaux à créer ou utiliser pour la stack.

default : permet de définir le réseau par défaut si on ne configure rien mais on peut aussi le configurer. On peut aussi mettre le nom d’un autre réseau si on veut partager des réseaux entre conteneurs.

name : permet de définir le nom qui sera afficher dans docker.

driver : permet de définir si on veut que ce soit un réseau Bridge, host, none.

enable_ipv4/6 : true or false pour activer ou pas l’ipv4 ou 6.

# Installation de Docker

```
apt install ca-certificates
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
 apt update
 apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
 ```