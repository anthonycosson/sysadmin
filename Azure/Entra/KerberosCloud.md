# Configuration de Keberos Cloud

La configuration se passe en 3 étapes :

* Création du serveur AzureADKerberos
* Configurer les paramètres de stratégie Windows Hello Entreprise
* S’inscrire à Windows Hello Entreprise

Source : https://learn.microsoft.com/fr-fr/windows/security/identity-protection/hello-for-business/deploy/hybrid-cloud-kerberos-trust?tabs=intune#deploy-microsoft-entra-kerberos
## 1) Création du AzureADKerberos serveur sur l'AD

```
# First, ensure TLS 1.2 for PowerShell gallery access.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Install the AzureADHybridAuthenticationManagement PowerShell module.
Install-Module -Name AzureADHybridAuthenticationManagement -AllowClobber

# Specify the on-premises Active Directory domain. A new Microsoft Entra ID. 
# Kerberos Server object will be created in this Active Directory domain.
$domain = $env:USERDNSDOMAIN

# Enter an Azure Active Directory Hybrid Identity Administrator username and password.
$cloudCred = Get-Credential -Message 'An Active Directory user who is a member of the Hybrid Identity Administrators group for Microsoft Entra ID.'

# Enter a Domain Administrator username and password.
$domainCred = Get-Credential -Message 'An Active Directory user who is a member of the Domain Admins group and an Enterprise Admin for the forest.'

# Create the new Microsoft Entra ID Kerberos Server object in Active Directory
# and then publish it to Azure Active Directory.
Set-AzureADKerberosServer -Domain $domain -CloudCredential $cloudCred -DomainCredential $domainCred
```
Pour vérifier si la commande a bien fonctionné, il faut vérifier la présence d'un serveur "AzureADKerberos" dans l'OU des "Domain Controllers".

Source : https://learn.microsoft.com/fr-fr/entra/identity/authentication/howto-authentication-passwordless-security-key-on-premises#install-the-azureadhybridauthenticationmanagement-module


## 2) Configurer les paramètres de stratégie Windows Hello Entreprise

Tout d'abord, il faut activer l'utilisation de Windows Hello Entreprise dans paramètres d'inscriptions sur intune : 

* Configurer Windows Hello Entreprise : Activé
* Utiliser un module de plateforme sécurisé (TPM) : Obligatoire
* Autres options : En fontion des préférences

Ensuite, il faut créer un nouveau profile de configuration :

* Plateforme : Windows 10 et versions ultérieures
* Type de profil : Catalogue de paramètres
    * Nom : Windows Hello - Keberos Cloud
    * Paramètres : Windows Hello Entreprise
        * Autoriser l'utilisation de la biométrie : True
        * Caractères spéciaux (utilisateur) : Permettre l'utilisation
        * Chiffres (utilisateur) : Permettre l'utilisation
        * Exiger un appareil de sécurité (utilisateur) : True
        * Les fonctionnalités de reconnaissance faciale utilisent la détection d'usurpation améliorée : True
        * Lettres majuscules (utilisateur) : Obligatoire
        * Lettres minuscules (utilisateur) : Obligatoire
        * Longueur minimale du code confidentiel (utilisateur) : 8
        * Utiliser l’approbation cloud pour l’authentification locale : True
        * Utiliser Windows Hello For Business (utilisateur) : True


## 3) S’inscrire à Windows Hello Entreprise

Une fois qu’un utilisateur s’est connecté, le processus d’inscription Windows Hello Entreprise commence :

1. Si l’appareil prend en charge l’authentification biométrique, l’utilisateur est invité à configurer un mouvement biométrique. Ce mouvement peut être utilisé pour déverrouiller l’appareil et s’authentifier auprès des ressources qui nécessitent Windows Hello Entreprise. L’utilisateur peut ignorer cette étape s’il ne souhaite pas configurer un mouvement biométrique
1. L’utilisateur est invité à utiliser Windows Hello avec le compte organization. L’utilisateur sélectionne OK
1. Le flux d’approvisionnement passe à la partie d’authentification multifacteur de l’inscription. L’approvisionnement informe l’utilisateur qu’il tente activement de contacter l’utilisateur via sa forme configurée d’authentification multifacteur. Le processus d’approvisionnement ne se poursuit pas tant que l’authentification n’a pas réussi, échoué ou expiré. Un échec ou un délai d’expiration de l’authentification multifacteur entraîne une erreur et demande à l’utilisateur de réessayer
1. Après une authentification multifacteur réussie, le flux d’approvisionnement demande à l’utilisateur à créer et de valider un code confidentiel. Ce code confidentiel doit respecter toutes les stratégies de complexité du code confidentiel configurées sur l’appareil
1. Le reste de l’approvisionnement inclut la demande, par Windows Hello Entreprise, d'une paire de clés asymétriques pour l’utilisateur, de préférence à partir du module TPM (ou requis si définie explicitement via la stratégie). Une fois la paire de clés acquise, Windows communique avec le fournisseur d’identité pour inscrire la clé publique. Une fois l’inscription de clé terminée, Windows Hello Entreprise provisionnement informe l’utilisateur qu’il peut utiliser son code confidentiel pour se connecter. L’utilisateur peut fermer l’application d’approvisionnement et accéder à son bureau


## 4) Vérifier si ça fonctionne correctement 

Vous pouvez déterminer la status de la configuration requise case activée en affichant le journal d’administration De l’inscription des appareils utilisateur sous Journaux > des applications et des servicesMicrosoft > Windows.

Ces informations sont également disponibles à l’aide de la commande `dsregcmd.exe /status`

Le prérequis d’approbation Kerberos cloud case activée détecte si l’utilisateur a un TGT partiel avant d’autoriser le démarrage de l’approvisionnement. L’objectif de cette case activée est de vérifier si Microsoft Entra Kerberos est configuré pour le domaine et le locataire de l’utilisateur. Si Microsoft Entra Kerberos est configuré, l’utilisateur reçoit un TGT partiel lors de la connexion avec l’une de ses autres méthodes de déverrouillage. Cette case activée a trois états : Oui, Non et Non testé. L’état Non testé est signalé si l’approbation Kerberos cloud n’est pas appliquée par la stratégie ou si l’appareil est Microsoft Entra joint.