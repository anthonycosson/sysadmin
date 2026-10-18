# Installation d'un système linux

## Installation du système

1. Pas de swap au moment du partitionnement des disques. Cela sera fait plus tard pour éviter les problèmes si un jour on veut étendre une partition.
2. Installation de :
    - Serveur SSH
    - utilitaires usuels du système


## Mise à jour du système

```
apt update && apt full-upgrade -y
```

## Permettre le connexion directement depuis le compte root avec mot de passe (Pas forcément recommandé)

```
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config`\
systemctl restart ssh
```
## Installations de quelques outils intéréssants 

```
apt install curl net-tools -y
```

## Création de fichier de swap

```bash
#Créer un fichier de swap de 2 Go
fallocate -l 2G /swapfile 
#Sécuriser les permissions
chmod 600 /swapfile
#Formater en swap
mkswap /swapfile
#Activer immédiatement
swapon /swapfile
#Rendre persistant au reboot (ajoute une ligne à /etc/fstab)
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
# Vérifications
swapon --show
```