# Configuration basique pour bien démarrer

## Mise à jour du système

`apt update && apt full-upgrade -y`

## Installations de quelques outils intéréssants 

`apt install curl htop vim cifs-utils net-tools -y`

## Permettre le connexion directement depuis le compte route avec mot de passe (Pas forcément recommandé)

`sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config`\
`systemctl restart ssh`