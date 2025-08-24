# Gestion des partages

## Monter un partage

Pour commencer il faut créer un dossier local qui servira de point de montage

* Créer un dossier local qui servira de point de montage `mkdir -p /mnt/partage`
* Monter sudo mount -t cifs //192.168.X.X/partage /mnt/partage -o username=XXX,password=XXX,uid=XXX,gid=XXX

l'UID et le GUID sont ceux du propriétaire et du groupe propriétaire du partage. Pour trouver l'ID il faut de faire `id nomutilisateur` ou `id nomdugroupe` pour trouver l'ID correspondant.

## FSTAB

Fstab permet de rentre le montage permanent.

* `nano /etc/fstab`
* `//192.168.X.X/partage /mnt/partage  cifs  credentials=/etc/smb-credentials.XXX,iocharset=utf8,uid=XXX,gid=XXX,file_mode=0644,dir_mode=0755,nofail  0  0`
* `systemctl daemon-reload`
* `mount -a`
* `findmnt`

Dans cette exemple les crédential sont stocké dans le fichier "/etc/smb-credentials.XXX" qui est sous ce format : 
>`username=XXX`\
>`password=XXX`
