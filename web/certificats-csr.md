# Gestion des certificats

## Prérequis 

Tous d'abord il faut installer OpenSSL que ce soit sur Linux, Mac ou Windows

## Rappel sur les extensions de certificat

* .crt → contient un certificat public au format X.509 (Encodage Base64 (PEM) ou Binaire (DER))
* .pem → format texte encodé Base64 pouvant contenir certificat, clé ou chaîne complète
* .pfx → conteneur binaire PKCS#12 qui regroupe certificat + clé + chaîne, souvent protégé par mot de passe

Le standard actuel est .pem ou .pfx du coté de Windows. 

## Générer un CSR

`openssl req -nodes -newkey rsa:2048 -sha256 -keyout domaine.key -out domaine.csr -utf8`

Répondre aux questions suivantes :

* **Country name** : FR
* **State or Province** : Ile-de-france
* **Locality name** : Paris
* **Organization Name** : Le nom du client
* **Organization Unit Name** : IT Department 
* **Common name** : le FQDN complet ou le wildcard (exemple : sous-domaine.domaine.tld ou *.domaine.tld)
* **Email** : On laisse vide
* **Password** : On laisse vide
* **Optional Compagny Name** : On laisse vide


Attention, en plus du .CSR il est important de garder le fichier .key.

## Créer un .PFX en intégrant le .crt, le .key et .pem dedans 

Pour cela il faut récupérer le certificat .crt puis le fichier .key qui a été généré en même temps que le CSR dans le même répertoire ou l'on exécute la commande ci-dessous : 

 `openssl pkcs12 -export -out domain.name.pfx -inkey domain.name.key -in domain.name.crt -certfile domain.name.pem`


## Bonus

### Créer un .crt en intégrant le .crt et le.pem dedans

`cat domain.name.crt domain.name.pem > fullchain.pem`

Aujourd'hui le standard est le .pem mais on peut aussi le mettre en .crt aussi.




### Transformer un .PFX en .p12

Il est possible de changer l'extension simplement en le renommant mais il est aussi possible d'utiliser la commande suivante :

` openssl pkcs12 -in domaine.name.pfx -out domaine.name.p12 -nodes`

