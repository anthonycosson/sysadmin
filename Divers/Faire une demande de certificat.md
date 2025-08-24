# Gestion des certificats

## Prérequis 

Tous d'abord il faut installer OpenSSL que ce soit sur Linux, Mac ou Windows

## Générer un CSR

`sudo openssl req -sha256 -nodes -newkey rsa:2048 -keyout domaine.tld.key -out domaine.tld.csr`

Répondre aux questions suivantes :

* **Country name** : FR
* **Locality name** : Paris
* **Organisation Name** : Le nom du client
* **Common name** : le FQDN complet ou le wildcard (exemple : sous-domaine.domaine.tld ou *.domaine.tld)
* **Password** : Définir le mot de passe

Si d'autres questions sont posées, elles peuvent être ignorées en laissant le champs vide et en appuyant sur "Enter".

Attention, en plus du .CSR il est important de garder le fichier .key ainsi que le mot de passe utilisé.

## Transformer le .crt en .PFX

Pour cela il faut récupérer le certificat .crt puis le fichier .key qui a été généré en même temps que le CSR dans le même répertoire ou l'on exécute la commande ci-dessous : 

 `openssl pkcs12 -export -out domain.name.pfx -inkey domain.name.key -in domain.name.crt`


## Transformer un .PFX en .p12

Il est possible de changer l'extension simplement en le renommant mais il est aussi possible d'utiliser la commande suivante :

` openssl pkcs12 -export -in domaine.name.pfx -out domaine.name.p12`

