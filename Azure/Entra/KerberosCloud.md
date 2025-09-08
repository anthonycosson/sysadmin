# Configuration de Keberos Cloud

La configuration se passe en 3 étapes :

* Création du serveur AzureADKerberos
* Configurer les paramètres de stratégie Windows Hello Entreprise
* S’inscrire à Windows Hello Entreprise

Source : https://learn.microsoft.com/fr-fr/windows/security/identity-protection/hello-for-business/deploy/hybrid-cloud-kerberos-trust?tabs=intune#deploy-microsoft-entra-kerberos
## 1. Création du AzureADKerberos serveur sur l'AD

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


## 1. Configurer les paramètres de stratégie Windows Hello Entreprise

Pour cela, il faut créer une stratégie 


## 1. S’inscrire à Windows Hello Entreprise