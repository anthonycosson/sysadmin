# Sécuriser un tenant Microsoft 365

Procédure de renforcement d'un tenant Microsoft 365, classée par domaine. Chaque mesure indique ce qu'elle bloque, la commande pour l'appliquer et celle pour vérifier le résultat.

## 📑 Sommaire

1. [Prérequis](#prérequis)
2. [💳 Abonnements et achats](#-abonnements-et-achats)
   - [Désactiver les achats et les versions d'essai en libre-service](#désactiver-les-achats-et-les-versions-dessai-en-libre-service)
3. [👤 Identités et inscriptions](#-identités-et-inscriptions)
   - [Désactiver le « viral sign-up »](#désactiver-le--viral-sign-up-)
4. [🧩 Applications Entra ID](#-applications-entra-id)
   - [Contrôler les secrets et certificats des applications](#contrôler-les-secrets-et-certificats-des-applications)
5. [💻 Appareils](#-appareils)
   - [Configurer Windows LAPS](#configurer-windows-laps) (et désactiver les comptes Administrator et Invité)
6. [📧 Messagerie et antispam](#-messagerie-et-antispam)
   - [Authentification des e-mails : SPF, DKIM et DMARC](#authentification-des-e-mails--spf-dkim-et-dmarc)
   - [Stratégie de quarantaine](#stratégie-de-quarantaine)
   - [Anti-hameçonnage](#anti-hameçonnage)
   - [Anti-courrier indésirable](#anti-courrier-indésirable)
   - [Anti-programme malveillant](#anti-programme-malveillant)
   - [Pièces jointes fiables (Safe Attachments)](#pièces-jointes-fiables-safe-attachments)
   - [Liens fiables (Safe Links)](#liens-fiables-safe-links)
   - [Vérification de la partie messagerie](#vérification-de-la-partie-messagerie)

## Prérequis

- Un compte **Administrateur global** (ou le rôle le plus restreint indiqué dans chaque section).
- PowerShell 7 recommandé, lancé en administrateur pour l'installation des modules.
- Modules utilisés :

| Module | Usage |
|---|---|
| `MSCommerce` | Stratégies d'achat en libre-service |
| `Microsoft.Graph` | Stratégies d'autorisation Entra ID |
| `ExchangeOnlineManagement` | Stratégies de protection de la messagerie |
| `Microsoft.Online.SharePoint.PowerShell` | Paramètres du tenant SharePoint |

```powershell
Install-Module MSCommerce
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser
```

## 💳 Abonnements et achats

### Désactiver les achats et les versions d'essai en libre-service

**Pourquoi :** par défaut, un utilisateur peut souscrire lui-même à une version d'essai ou acheter une licence (Power BI Pro, Power Automate, Visio…) sans passer par le service informatique. Cela crée du Shadow IT et des abonnements hors de contrôle.

**Stratégie concernée :** `AllowSelfServicePurchase`

```powershell
Import-Module MSCommerce
Connect-MSCommerce

# État actuel de chaque produit
Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase

# Désactiver tous les produits encore autorisés
Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase |
    Where-Object { $_.PolicyValue -eq "Enabled" } |
    ForEach-Object {
        Update-MSCommerceProductPolicy `
            -PolicyId AllowSelfServicePurchase `
            -ProductId $_.ProductId `
            -Enabled $False
    }
```

**Vérification :** aucun produit ne doit rester à `Enabled`.

```powershell
Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase |
    Select-Object ProductName, PolicyValue
```

> ℹ️ Microsoft ajoute régulièrement de nouveaux produits, activés par défaut. Relancez le script de temps en temps.

Source : https://learn.microsoft.com/fr-fr/microsoft-365/commerce/subscriptions/allowselfservicepurchase-powershell

## 👤 Identités et inscriptions

### Désactiver le « viral sign-up »

**Pourquoi :** le « viral sign-up » permet à n'importe qui possédant une adresse e-mail de votre domaine de rejoindre le tenant en vérifiant simplement son adresse, sans qu'un administrateur ait créé le compte. Ces comptes échappent au provisionnement normal (MFA, licences, accès conditionnel).

**Paramètres concernés** (stratégie d'autorisation Entra ID) :

| Paramètre | Ce qu'il bloque |
|---|---|
| `allowEmailVerifiedUsersToJoinOrganization` | Un utilisateur qui vérifie son adresse e-mail rejoint le tenant tout seul |
| `allowedToSignUpEmailBasedSubscriptions` | Un utilisateur s'inscrit à un abonnement en libre-service avec son adresse e-mail |

**Rôle minimum :** Administrateur de la stratégie d'autorisation (scope Graph `Policy.ReadWrite.Authorization`).

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Import-Module Microsoft.Graph
Connect-MgGraph -Scopes "Policy.ReadWrite.Authorization"

$params = @{
    allowEmailVerifiedUsersToJoinOrganization = $false
    allowedToSignUpEmailBasedSubscriptions = $false
}

Update-MgPolicyAuthorizationPolicy -BodyParameter $params
```

**Vérification :** les deux valeurs doivent être à `False`.

```powershell
Get-MgPolicyAuthorizationPolicy | Select AllowEmailVerifiedUsersToJoinOrganization,AllowedToSignUpEmailBasedSubscriptions
```

Source : https://learn.microsoft.com/fr-fr/entra/identity/users/directory-self-service-signup

## 🧩 Applications Entra ID

### Contrôler les secrets et certificats des applications

**Pourquoi :** une application inscrite dans Entra ID s'authentifie avec un **secret client** ou un **certificat**. Ce sont des mots de passe d'applications, souvent dotés de permissions larges (lecture des boîtes, des fichiers, de l'annuaire). Un secret valable 10 ans, oublié dans un script ou un dépôt de code, est une porte d'entrée durable pour un attaquant.

**Règle :** aucun secret ni certificat ne doit avoir une durée de validité **supérieure à 2 ans**.

> ℹ️ Le portail limite les nouveaux secrets à 24 mois. En revanche, un certificat importé ou un secret créé en PowerShell ou par l'API Graph peut durer bien plus longtemps : d'où ce contrôle.

**Rôle minimum :** Lecteur global (scope Graph `Application.Read.All`, lecture seule).

#### Lister les secrets et certificats

Le script liste chaque secret et chaque certificat des **inscriptions d'applications**. Pour chacun, il indique sa durée de validité, sa date d'expiration et s'il dépasse 2 ans.

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Import-Module Microsoft.Graph
Connect-MgGraph -Scopes "Application.Read.All"

$now = Get-Date

$results = foreach ($app in Get-MgApplication -All -Property Id, AppId, DisplayName, PasswordCredentials, KeyCredentials) {

    $creds = @(
        foreach ($s in $app.PasswordCredentials) {
            [pscustomobject]@{ Type = "Secret"; Nom = $s.DisplayName; Debut = $s.StartDateTime; Fin = $s.EndDateTime }
        }
        foreach ($k in $app.KeyCredentials) {
            [pscustomobject]@{ Type = "Certificat"; Nom = $k.DisplayName; Debut = $k.StartDateTime; Fin = $k.EndDateTime }
        }
    )

    foreach ($c in $creds) {
        [pscustomobject]@{
            Application      = $app.DisplayName
            AppId            = $app.AppId
            Type             = $c.Type
            Nom              = $c.Nom
            Creation         = $c.Debut.ToString("yyyy-MM-dd")
            Expiration       = $c.Fin.ToString("yyyy-MM-dd")
            DureeJours       = ($c.Fin - $c.Debut).Days
            JoursRestants    = ($c.Fin - $now).Days
            PlusDe2Ans       = $c.Fin -gt $c.Debut.AddYears(2)
            Statut           = if ($c.Fin -lt $now) { "Expiré" } elseif ($c.Fin -lt $now.AddDays(30)) { "Expire sous 30 j" } else { "OK" }
        }
    }
}

# Vue complète, triée par date d'expiration
$results | Sort-Object Expiration | Format-Table -AutoSize

# Uniquement ceux qui dépassent 2 ans
$results | Where-Object PlusDe2Ans | Format-Table Application, Type, Nom, Creation, Expiration, DureeJours -AutoSize

# Export pour Excel
$results | Export-Csv -Path ".\applications-credentials.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ";"

Disconnect-MgGraph
```

#### Ce que fait le script

1. **Connexion** à Microsoft Graph en lecture seule. `$now` garde la date du jour pour les calculs.
2. **Récupération** de toutes les inscriptions d'applications (`-All`, sinon Graph s'arrête à la première page). Seuls les champs utiles sont demandés : nom, AppId, secrets (`PasswordCredentials`) et certificats (`KeyCredentials`).
3. **Mise en commun** des secrets et des certificats de chaque application dans une seule liste au même format. Une application sans secret ni certificat ne produit aucune ligne.
4. **Une ligne par secret ou certificat**, avec les colonnes suivantes :

| Colonne | Calcul | Signification |
|---|---|---|
| `Application`, `AppId` | Repris de l'application | À quelle application appartient la ligne |
| `Type`, `Nom` | Secret ou Certificat, description saisie à la création | Quel identifiant est concerné |
| `Creation`, `Expiration` | Dates au format `2026-10-28` | Lisibles et triables |
| `DureeJours` | Fin − Début | Durée de validité totale |
| `JoursRestants` | Fin − aujourd'hui | Négatif si déjà expiré |
| `PlusDe2Ans` | Fin > Début + 2 ans | `True` si la règle des 2 ans n'est pas respectée |
| `Statut` | Comparaison avec aujourd'hui | `Expiré`, `Expire sous 30 j` ou `OK` |

5. **Affichage** de deux tableaux, la vue complète puis les seuls dépassements, et **export CSV** dans le dossier courant (séparateur `;` et UTF-8, pour l'ouvrir directement dans un Excel français).

> ℹ️ `PlusDe2Ans` ajoute 2 ans à la date de création plutôt que de compter 730 jours. Un secret de 24 mois qui contient un 29 février fait 731 jours : avec un compte en jours, il serait signalé à tort.

Le script ne modifie, ne supprime et ne renouvelle rien.

#### Que faire des résultats

| Résultat | Action |
|---|---|
| `PlusDe2Ans = True` | Créer un nouveau secret ou certificat de 2 ans maximum, le mettre à jour dans l'application ou le script qui l'utilise, puis supprimer l'ancien |
| `Expiré` | Vérifier si l'application sert encore. Sinon, supprimer le secret, voire l'application |
| `Expire sous 30 j` | Planifier le renouvellement avec le responsable de l'application avant la coupure |

Le renouvellement se fait dans Entra ID → **Inscriptions d'applications** → *application* → **Certificats et secrets**.

> ℹ️ **Limites du contrôle :** le script ne couvre que les **inscriptions d'applications**. Les **applications d'entreprise** (applications tierces ajoutées au tenant) peuvent aussi porter des certificats, par exemple les certificats de signature SAML pour le SSO. Ceux-là se consultent avec `Get-MgServicePrincipal`.

> ℹ️ **Imposer la règle :** pour empêcher la création de secrets de plus de 2 ans au lieu de seulement la contrôler, Entra ID propose les *stratégies de gestion des applications* (`Update-MgPolicyDefaultAppManagementPolicy`). Elles nécessitent une licence Microsoft Entra Workload ID.

Sources :
- https://learn.microsoft.com/fr-fr/graph/api/resources/application
- https://learn.microsoft.com/fr-fr/entra/identity/enterprise-apps/tutorial-enforce-secret-standards

## 💻 Appareils

### Configurer Windows LAPS

**Pourquoi :** sans LAPS, le compte administrateur local a souvent le même mot de passe sur tous les postes. Un attaquant qui le récupère sur un poste peut se déplacer sur tous les autres. Windows LAPS génère un mot de passe unique par appareil, le fait tourner automatiquement et le sauvegarde dans Entra ID.

**Architecture cible :**

- les comptes intégrés `Administrator` et `Guest` (Invité) sont **désactivés** ;
- un compte admin local dédié (ex. `lapsadmin`) est **créé et géré par LAPS** ;
- le groupe local `Administrateurs` ne contient **que** ce compte et le rôle Entra *Administrateurs d'appareils*.

**Prérequis :**

- Appareils joints à Entra ID ou en jonction hybride.
- Windows 10/11 avec la mise à jour d'avril 2023 ou plus récente (Windows LAPS est intégré à l'OS, rien à installer).
- La **gestion automatique du compte** (étape 2) demande **Windows 11 24H2** ou Windows Server 2025. Sur les versions plus anciennes, il faut créer le compte admin local autrement (script, compte existant).
- Rôle : **Administrateur d'appareils cloud** pour l'étape 1, **Administrateur Intune** pour les suivantes.

#### 1. Activer LAPS dans Entra ID

Centre d'administration Entra → **Appareils** → **Paramètres de l'appareil** (*Device settings*) :

- **Activer Microsoft Entra Local Administrator Password Solution (LAPS)** : `Oui`
- Enregistrer.

> ⚠️ Sans cette option, les appareils refusent de sauvegarder leur mot de passe dans Entra ID et la stratégie Intune échoue.

#### 2. Stratégie LAPS avec gestion automatique du compte

Intune → **Sécurité des points de terminaison** → **Protection du compte** → **Créer une stratégie** → Plateforme `Windows`, Profil `Solution de mot de passe d'administrateur local (Windows LAPS)`.

| Paramètre | Valeur conseillée |
|---|---|
| Backup Directory | `Backup the password to Azure AD only` |
| Password Age Days | `30` |
| Password Complexity | `Large letters + small letters + numbers + special characters` |
| Password Length | `20` |
| Post Authentication Actions | `Reset the password and logoff the managed account` |
| Post Authentication Reset Delay | `8` (heures) |
| Automatic Account Management Enabled | `Enabled` |
| Automatic Account Management Target | `Manage a new custom administrator account` |
| Automatic Account Management Name Or Prefix | Nom du compte, ex. `lapsadmin` |
| Automatic Account Management Enable Account | `Enabled` |
| Automatic Account Management Randomize Name | `Disabled` |

**Affectation :** **uniquement des groupes d'appareils**. Les stratégies LAPS ne s'appliquent pas aux groupes d'utilisateurs.

> ℹ️ On cible un **nouveau compte** et non le compte `Administrator` intégré, puisque celui-ci est désactivé à l'étape suivante.

#### 3. Désactiver les comptes Administrator et Invité intégrés

Intune → **Appareils** → **Configuration** → **Créer** → Plateforme `Windows 10 et ultérieur`, Type `Catalogue des paramètres` :

```
Local Policies Security Options
├─ Accounts: Enable Administrator Account Status = Disable
└─ Accounts: Enable Guest Account Status = Disable
```

> ℹ️ Le compte Invité est désactivé par défaut sur Windows. La stratégie garantit qu'il le reste, même si quelqu'un le réactive à la main.

**Affectation :** les mêmes groupes d'appareils que la stratégie LAPS.

#### 4. Définir explicitement les membres du groupe Administrateurs local

Intune → **Sécurité des points de terminaison** → **Protection du compte** → **Créer une stratégie** → Plateforme `Windows`, Profil `Appartenance au groupe d'utilisateurs locaux` (*Local user group membership*) :

| Paramètre | Valeur |
|---|---|
| Groupe local | `Administrators` |
| Action de groupe et d'utilisateur | `Replace` (remplace tous les membres actuels) |
| Type de sélection d'utilisateur | `Manual` |
| Utilisateurs | `AzureAD\Device Administrators` et le compte LAPS (ex. `lapsadmin`) |

**Affectation :** les mêmes groupes d'appareils.

> ⚠️ `Replace` retire du groupe tout membre non listé, y compris les utilisateurs devenus admins à la jonction de l'appareil. C'est le but, mais testez sur un groupe pilote : une erreur de nom peut laisser un poste sans aucun administrateur local.

#### Vérification

**Sur le poste :**

```powershell
# Forcer l'application de la stratégie LAPS et consulter le résultat
Invoke-LapsPolicyProcessing
Get-WinEvent -LogName "Microsoft-Windows-LAPS/Operational" -MaxEvents 10 |
    Select-Object TimeCreated, Id, Message

# Administrator et Invité doivent être désactivés, lapsadmin présent et activé
Get-LocalUser | Select-Object Name, Enabled

# Seuls les membres définis à l'étape 4 doivent apparaître
Get-LocalGroupMember -SID "S-1-5-32-544"   # groupe Administrateurs, quelle que soit la langue
```

Dans le journal, l'événement **10029** indique que le mot de passe a bien été sauvegardé dans Entra ID.

**Récupérer le mot de passe :** Entra ID ou Intune → **Appareils** → *appareil* → **Mot de passe d'administrateur local**, ou en PowerShell :

```powershell
Connect-MgGraph -Scopes "Device.Read.All","DeviceLocalCredential.Read.All"
Get-LapsAADPassword -DeviceIds "NOM-DU-POSTE" -IncludePasswords -AsPlainText
```

Sources :
- https://learn.microsoft.com/fr-fr/entra/identity/devices/howto-manage-local-admin-passwords
- https://learn.microsoft.com/fr-fr/mem/intune/protect/windows-laps-policy
- https://learn.microsoft.com/fr-fr/mem/intune/protect/endpoint-security-account-protection-policy

## 📧 Messagerie et antispam

Cette partie suit l'ordre logique de traitement d'un e-mail : d'abord prouver que nos domaines sont légitimes (SPF, DKIM, DMARC), puis filtrer ce qui arrive (hameçonnage, spam, programmes malveillants) et enfin analyser les pièces jointes et les liens.

**Licences :**

| Fonctionnalité | Licence |
|---|---|
| SPF, DKIM, DMARC, anti-spam, anti-malware, usurpation (spoof) | Exchange Online Protection (inclus dans tout abonnement Exchange Online) |
| Protection contre l'emprunt d'identité (VIP, domaines), pièces jointes fiables, liens fiables | **Microsoft Defender for Office 365 Plan 1** (inclus dans Microsoft 365 Business Premium et E5) |

**Portail :** [security.microsoft.com](https://security.microsoft.com) → **E-mail et collaboration** → **Stratégies et règles** → **Stratégies de menace**.

**Connexion PowerShell :**

```powershell
Install-Module ExchangeOnlineManagement -Scope CurrentUser
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

# Domaines acceptés du tenant, réutilisés dans les règles plus bas
$domains = (Get-AcceptedDomain).DomainName
```

> ℹ️ **Alternative rapide :** les *Stratégies de sécurité prédéfinies* (Standard ou Strict) appliquent d'un coup les réglages recommandés par Microsoft. Elles passent **avant** les stratégies personnalisées. Cette procédure configure les stratégies à la main pour garder la main sur chaque réglage (VIP, quarantaine, exceptions).

### Authentification des e-mails : SPF, DKIM et DMARC

À faire pour **chaque domaine** qui envoie des e-mails. Les trois se complètent :

| Protocole | Ce qu'il prouve |
|---|---|
| SPF | Le serveur qui envoie est autorisé à envoyer pour le domaine |
| DKIM | Le message est signé par le domaine et n'a pas été modifié en route |
| DMARC | Ce que le destinataire doit faire si SPF et DKIM échouent, et à qui envoyer les rapports |

#### SPF

Un **seul** enregistrement TXT à la racine du domaine :

| Type | Nom | Valeur |
|---|---|---|
| TXT | `@` | `v=spf1 include:spf.protection.outlook.com -all` |

- Ajoutez chaque autre service qui envoie avec votre domaine (outil d'e-mailing, CRM, copieurs, site web…) avant le `-all`, par exemple `v=spf1 include:spf.protection.outlook.com include:servers.mcsv.net -all`.
- `-all` rejette tout expéditeur non listé. Utilisez `~all` (échec léger) le temps de recenser tous les services d'envoi, puis passez à `-all`.
- Limite de **10 recherches DNS** (`include`, `a`, `mx`…) : au-delà, SPF échoue pour tout le monde.

#### DKIM

Portail : Stratégies de menace → **Paramètres d'authentification de l'e-mail** → onglet **DKIM** → sélectionner le domaine.

```powershell
# Créer la configuration DKIM (désactivée tant que le DNS n'est pas prêt)
New-DkimSigningConfig -DomainName contoso.com -Enabled $false

# Récupérer les deux CNAME à créer dans le DNS
Get-DkimSigningConfig -Identity contoso.com | Format-List Selector1CNAME, Selector2CNAME
```

Créez les deux enregistrements chez votre hébergeur DNS :

| Type | Nom | Valeur |
|---|---|---|
| CNAME | `selector1._domainkey` | Valeur de `Selector1CNAME` |
| CNAME | `selector2._domainkey` | Valeur de `Selector2CNAME` |

Une fois les CNAME propagés :

```powershell
Set-DkimSigningConfig -Identity contoso.com -Enabled $true
```

> ℹ️ Microsoft fait tourner les clés entre les deux sélecteurs, d'où les deux CNAME. Les clés sont en 2048 bits par défaut ; une ancienne configuration en 1024 bits passe en 2048 avec `Rotate-DkimSigningConfig -Identity contoso.com -KeySize 2048`.

#### DMARC

Enregistrement TXT sur le sous-domaine `_dmarc` :

| Type | Nom | Valeur |
|---|---|---|
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc@contoso.com; fo=1` |

Montez la politique **progressivement**, en lisant les rapports reçus sur l'adresse `rua` à chaque étape :

| Étape | Politique | Durée conseillée |
|---|---|---|
| 1 | `p=none` : on observe seulement | 2 à 4 semaines |
| 2 | `p=quarantine; pct=25` puis `pct=100` : les messages en échec vont en courrier indésirable | 2 à 4 semaines |
| 3 | `p=reject` : les messages en échec sont refusés | Objectif final |

> ℹ️ Les rapports `rua` sont des fichiers XML difficiles à lire tels quels. Un service d'analyse DMARC (gratuit ou payant) les rend exploitables.

#### Domaines qui n'envoient pas d'e-mails

Pour un domaine « parking » ou un domaine secondaire qui n'envoie rien, bloquez toute usurpation :

| Type | Nom | Valeur |
|---|---|---|
| TXT | `@` | `v=spf1 -all` |
| TXT | `_dmarc` | `v=DMARC1; p=reject;` |

Pensez aussi au domaine `contoso.onmicrosoft.com` : son enregistrement DMARC se configure dans le centre d'administration Microsoft 365 → **Paramètres** → **Domaines** → domaine `onmicrosoft.com` → **Enregistrements DNS**.

#### Vérification

```powershell
Resolve-DnsName contoso.com -Type TXT | Where-Object Strings -like "v=spf1*"
Resolve-DnsName selector1._domainkey.contoso.com -Type CNAME
Resolve-DnsName _dmarc.contoso.com -Type TXT

# DKIM doit être Enabled = True et Status = Valid
Get-DkimSigningConfig | Select-Object Domain, Enabled, Status
```

Pour contrôler un message reçu, envoyez un e-mail vers une boîte externe (Gmail par exemple) et vérifiez dans l'en-tête : `spf=pass`, `dkim=pass` et `dmarc=pass`.

Sources :
- https://learn.microsoft.com/fr-fr/defender-office-365/email-authentication-spf-configure
- https://learn.microsoft.com/fr-fr/defender-office-365/email-authentication-dkim-configure
- https://learn.microsoft.com/fr-fr/defender-office-365/email-authentication-dmarc-configure

### Stratégie de quarantaine

À configurer **avant** les stratégies de filtrage : chaque verdict (spam, hameçonnage, malware…) pointe vers une stratégie de quarantaine qui décide de ce que l'utilisateur peut faire avec ses messages bloqués.

**Stratégies intégrées :**

| Stratégie | Ce que l'utilisateur peut faire | Notification |
|---|---|---|
| `AdminOnlyAccessPolicy` | Rien, seul l'administrateur voit et libère | Non |
| `DefaultFullAccessPolicy` | Voir, libérer, supprimer | Non |
| `DefaultFullAccessWithNotificationPolicy` | Voir, libérer, supprimer | Oui |
| `NotificationEnabledPolicy` | Voir, libérer, supprimer | Oui |

**Stratégie conseillée :** l'utilisateur voit ses messages et **demande** leur libération, qu'un administrateur valide. Il ne libère rien lui-même.

Portail : Stratégies de menace → **Stratégies de quarantaine** → **Ajouter une stratégie personnalisée**.

```powershell
$permissions = New-QuarantinePermissions `
    -PermissionToPreview $true `
    -PermissionToRequestRelease $true `
    -PermissionToDelete $true `
    -PermissionToBlockSender $true

New-QuarantinePolicy -Name "Quarantaine - Demande de libération" `
    -EndUserQuarantinePermissions $permissions `
    -ESNEnabled $true
```

`-ESNEnabled` active les **notifications de quarantaine** : l'utilisateur reçoit un e-mail récapitulant ses messages bloqués, avec un bouton pour demander la libération.

**Paramètres globaux** (Stratégies de quarantaine → **Paramètres globaux**) :

- Fréquence des notifications : `Toutes les 4 heures` ou `Tous les jours`.
- Nom d'affichage et langue des notifications, logo de l'organisation.

**Qui valide les demandes :** Stratégies de menace → **Stratégies d'alerte** → alerte *« L'utilisateur a demandé à libérer un message mis en quarantaine »* → ajouter les destinataires (service informatique).

**Utilisation dans la suite :**

| Verdict | Stratégie de quarantaine |
|---|---|
| Spam, spam à haut niveau de confiance, hameçonnage, usurpation d'identité | `Quarantaine - Demande de libération` |
| Hameçonnage à haut niveau de confiance, programme malveillant, pièce jointe malveillante | `AdminOnlyAccessPolicy` |

Source : https://learn.microsoft.com/fr-fr/defender-office-365/quarantine-policies

### Anti-hameçonnage

Portail : Stratégies de menace → **Anti-hameçonnage** → **Office365 AntiPhish Default**. Modifier la stratégie par défaut la fait s'appliquer à tous les destinataires, sans règle à créer.

**Réglages :**

| Section | Paramètre | Valeur |
|---|---|---|
| Seuil | Seuil d'e-mail d'hameçonnage | `3 - Plus agressif` (`4` pour un niveau strict) |
| Emprunt d'identité | Utilisateurs à protéger (**VIP**) | Direction, finance, RH, comptes qui valident des paiements (350 max.) |
| Emprunt d'identité | Domaines à protéger | Inclure **les domaines que je possède** + les domaines des partenaires clés (banque, fournisseurs, clients) |
| Emprunt d'identité | Veille de la boîte aux lettres et protection contre l'emprunt d'identité | Activées |
| Usurpation | Veille contre l'usurpation (spoof intelligence) | Activée |
| Usurpation | Respecter la stratégie DMARC | Activé : `p=quarantine` → Quarantaine, `p=reject` → Rejet |
| Actions | Utilisateur ou domaine emprunté | Mettre en quarantaine |
| Actions | Veille de la boîte aux lettres | Déplacer vers le courrier indésirable |
| Actions | Usurpation détectée | Déplacer vers le courrier indésirable |
| Conseils de sécurité | Premier contact, utilisateur emprunté, domaine emprunté, caractères inhabituels, expéditeur non authentifié (`?`), balise « via » | Tous activés |

> ℹ️ **Comptes VIP :** listez aussi les adresses génériques sensibles (`compta@`, `paie@`, `direction@`). Ce sont les cibles préférées des fraudes au président et au faux RIB.

```powershell
Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" `
    -PhishThresholdLevel 3 `
    -EnableTargetedUserProtection $true `
    -TargetedUsersToProtect @(
        "Jean Dupont;jean.dupont@contoso.com",
        "Comptabilité;compta@contoso.com"
    ) `
    -TargetedUserProtectionAction Quarantine `
    -TargetedUserQuarantineTag "Quarantaine - Demande de libération" `
    -EnableOrganizationDomainsProtection $true `
    -EnableTargetedDomainsProtection $true `
    -TargetedDomainsToProtect @("partenaire.com", "banque.fr") `
    -TargetedDomainProtectionAction Quarantine `
    -TargetedDomainQuarantineTag "Quarantaine - Demande de libération" `
    -EnableMailboxIntelligence $true `
    -EnableMailboxIntelligenceProtection $true `
    -MailboxIntelligenceProtectionAction MoveToJmf `
    -EnableSpoofIntelligence $true `
    -AuthenticationFailAction MoveToJmf `
    -HonorDmarcPolicy $true `
    -DmarcQuarantineAction Quarantine `
    -DmarcRejectAction Reject `
    -EnableFirstContactSafetyTips $true `
    -EnableSimilarUsersSafetyTips $true `
    -EnableSimilarDomainsSafetyTips $true `
    -EnableUnusualCharactersSafetyTips $true `
    -EnableUnauthenticatedSender $true `
    -EnableViaTag $true
```

> ⚠️ `-TargetedUsersToProtect` et `-TargetedDomainsToProtect` **remplacent** la liste existante. Pour ajouter une entrée, reprenez la liste actuelle (`Get-AntiPhishPolicy`) et ajoutez-y la nouvelle.

**Faux positifs :** si un partenaire légitime est bloqué pour emprunt d'identité, ajoutez-le dans **Expéditeurs et domaines approuvés** de la stratégie plutôt que de désactiver la protection.

Source : https://learn.microsoft.com/fr-fr/defender-office-365/anti-phishing-policies-mdo-configure

### Anti-courrier indésirable

#### Sortant : bloquer le transfert automatique vers l'extérieur

**Pourquoi :** un attaquant qui compromet une boîte crée souvent une règle qui transfère tout le courrier vers une adresse externe. Il continue de lire les e-mails même après le changement du mot de passe. C'est aussi une fuite de données classique.

Portail : Stratégies de menace → **Courrier indésirable** → **Stratégie de filtrage du courrier indésirable sortant (par défaut)**.

| Paramètre | Valeur |
|---|---|
| Règles de transfert automatique | `Désactivé - le transfert est désactivé` |
| Limite de destinataires externes par heure | `500` |
| Limite de destinataires internes par heure | `1000` |
| Limite quotidienne | `1000` |
| Action en cas de dépassement | `Empêcher l'utilisateur d'envoyer des messages` |
| Notifier des personnes en cas de blocage | Activé, adresse du service informatique |

```powershell
Set-HostedOutboundSpamFilterPolicy -Identity Default `
    -AutoForwardingMode Off `
    -RecipientLimitExternalPerHour 500 `
    -RecipientLimitInternalPerHour 1000 `
    -RecipientLimitPerDay 1000 `
    -ActionWhenThresholdReached BlockUser `
    -NotifyOutboundSpam $true `
    -NotifyOutboundSpamRecipients "it@contoso.com"
```

**Exception :** si une boîte doit vraiment transférer vers l'extérieur, créez une stratégie sortante dédiée avec `-AutoForwardingMode On`, appliquée **uniquement** à cette boîte, plutôt que de rouvrir le transfert pour tout le monde.

```powershell
New-HostedOutboundSpamFilterPolicy -Name "Transfert autorisé" -AutoForwardingMode On
New-HostedOutboundSpamFilterRule -Name "Transfert autorisé" `
    -HostedOutboundSpamFilterPolicy "Transfert autorisé" `
    -From "boite.autorisee@contoso.com"
```

> ℹ️ Les utilisateurs bloqués pour dépassement de limite apparaissent dans **Utilisateurs restreints** (portail Defender → E-mail et collaboration → Révision). Il faut les débloquer à la main après avoir vérifié que le compte n'est pas compromis.

#### Entrant : quarantaine ou courrier indésirable ?

C'est l'arbitrage principal de la stratégie entrante :

| | Courrier indésirable | Quarantaine |
|---|---|---|
| L'utilisateur voit le message | Oui, dans son dossier Courrier indésirable | Non, il reçoit une notification |
| Risque de clic sur un lien piégé | Plus élevé (les liens sont désactivés, mais le message est là) | Faible |
| Charge pour le support | Faible : l'utilisateur se débrouille | Plus forte : demandes de libération à valider |
| Adapté pour | Spam « classique », faux positifs fréquents | Tout ce qui est dangereux |

**Choix conseillé :** le doute va au courrier indésirable, le danger va en quarantaine.

| Verdict | Action | Stratégie de quarantaine |
|---|---|---|
| Courrier indésirable | Déplacer vers le courrier indésirable | – |
| Courrier indésirable à haut niveau de confiance | Mettre en quarantaine | `Quarantaine - Demande de libération` |
| Hameçonnage | Mettre en quarantaine | `Quarantaine - Demande de libération` |
| Hameçonnage à haut niveau de confiance | Mettre en quarantaine | `AdminOnlyAccessPolicy` |
| Courrier en nombre (bulk) | Déplacer vers le courrier indésirable | – |

Pour un niveau strict, passez aussi **Courrier indésirable** en quarantaine et le seuil bulk à `5`.

**Autres réglages :**

| Paramètre | Valeur |
|---|---|
| Seuil de courrier en nombre (BCL) | `6` |
| Conserver en quarantaine | `30` jours |
| Conseils de sécurité | Activés |
| Purge automatique zéro heure (ZAP) pour le spam et l'hameçonnage | Activée |

Portail : Stratégies de menace → **Courrier indésirable** → **Stratégie de filtrage du courrier indésirable entrant (par défaut)**.

```powershell
Set-HostedContentFilterPolicy -Identity Default `
    -BulkThreshold 6 `
    -SpamAction MoveToJmf `
    -HighConfidenceSpamAction Quarantine `
    -HighConfidenceSpamQuarantineTag "Quarantaine - Demande de libération" `
    -PhishSpamAction Quarantine `
    -PhishQuarantineTag "Quarantaine - Demande de libération" `
    -HighConfidencePhishAction Quarantine `
    -HighConfidencePhishQuarantineTag AdminOnlyAccessPolicy `
    -BulkSpamAction MoveToJmf `
    -QuarantineRetentionPeriod 30 `
    -InlineSafetyTipsEnabled $true `
    -SpamZapEnabled $true `
    -PhishZapEnabled $true
```

> ⚠️ N'ajoutez pas vos propres domaines dans **Domaines autorisés** : un attaquant qui usurpe votre domaine passerait alors tous les filtres. Pour un expéditeur légitime bloqué, utilisez la **Liste d'autorisation/de blocage des locataires**.

Sources :
- https://learn.microsoft.com/fr-fr/defender-office-365/outbound-spam-policies-configure
- https://learn.microsoft.com/fr-fr/defender-office-365/anti-spam-policies-configure

### Anti-programme malveillant

Portail : Stratégies de menace → **Anti-programme malveillant** → **Default (par défaut)**.

| Paramètre | Valeur |
|---|---|
| Activer le filtre des pièces jointes courantes | Activé (liste par défaut : `exe`, `js`, `vbs`, `iso`, `lnk`…) |
| Quand ces types de fichiers sont trouvés | Rejeter le message avec une notification d'échec (NDR) |
| Purge automatique zéro heure (ZAP) | Activée |
| Stratégie de quarantaine | `AdminOnlyAccessPolicy` |
| Notifier un administrateur des messages non remis (expéditeurs internes) | Activé, adresse du service informatique |

```powershell
Set-MalwareFilterPolicy -Identity Default `
    -EnableFileFilter $true `
    -FileTypeAction Reject `
    -ZapEnabled $true `
    -QuarantineTag AdminOnlyAccessPolicy `
    -EnableInternalSenderAdminNotifications $true `
    -InternalSenderAdminAddress "it@contoso.com"
```

> ℹ️ Pour ajouter des extensions à la liste (`one`, `vhd`, `xll`…), passez par le portail : en PowerShell, `-FileTypes` **remplace** toute la liste par défaut.

Source : https://learn.microsoft.com/fr-fr/defender-office-365/anti-malware-policies-configure

### Pièces jointes fiables (Safe Attachments)

**Pourquoi :** l'anti-programme malveillant reconnaît les menaces connues. Les pièces jointes fiables ouvrent en plus chaque pièce jointe dans un bac à sable (*détonation*) pour détecter les menaces inconnues.

**1. Paramètres globaux** (Stratégies de menace → **Pièces jointes fiables** → **Paramètres globaux**) :

- **Activer Defender pour Office 365 pour SharePoint, OneDrive et Microsoft Teams** : Activé. Les fichiers malveillants partagés dans ces services sont bloqués.

**2. Stratégie** (Stratégies de menace → **Pièces jointes fiables** → **Créer**) :

| Paramètre | Valeur |
|---|---|
| Utilisateurs, groupes, domaines | Tous les domaines acceptés |
| Réponse aux programmes malveillants inconnus | `Bloquer` |
| Stratégie de quarantaine | `AdminOnlyAccessPolicy` |
| Redirection | Désactivée |

> ℹ️ **Bloquer** retient le message pendant l'analyse (quelques minutes). **Remise dynamique** livre le message tout de suite sans les pièces jointes, puis les rajoute après l'analyse : utile si les délais gênent les utilisateurs.

```powershell
# Paramètres globaux
Set-AtpPolicyForO365 -EnableATPForSPOTeamsODB $true

# Stratégie et règle appliquées à tous les domaines du tenant
New-SafeAttachmentPolicy -Name "Pièces jointes fiables" `
    -Enable $true `
    -Action Block `
    -QuarantineTag AdminOnlyAccessPolicy `
    -Redirect $false

New-SafeAttachmentRule -Name "Pièces jointes fiables" `
    -SafeAttachmentPolicy "Pièces jointes fiables" `
    -RecipientDomainIs $domains `
    -Priority 0
```

En complément, empêchez le téléchargement des fichiers détectés comme malveillants dans SharePoint et OneDrive (module SharePoint Online) :

```powershell
Connect-SPOService -Url https://contoso-admin.sharepoint.com
Set-SPOTenant -DisallowInfectedFileDownload $true
```

Source : https://learn.microsoft.com/fr-fr/defender-office-365/safe-attachments-policies-configure

### Liens fiables (Safe Links)

**Pourquoi :** un lien peut être sain à la réception puis piégé quelques heures plus tard. Les liens fiables réécrivent les URL et les vérifient **au moment du clic**, dans les e-mails, Teams et les applications Office.

Portail : Stratégies de menace → **Liens fiables** → **Créer**.

| Paramètre | Valeur |
|---|---|
| Utilisateurs, groupes, domaines | Tous les domaines acceptés |
| E-mail : activé | Oui |
| Appliquer l'analyse des URL en temps réel | Oui |
| Attendre la fin de l'analyse avant de remettre le message | Oui |
| Appliquer aux e-mails envoyés en interne | Oui |
| Ne pas réécrire les URL | Non (les URL sont réécrites) |
| Teams : activé | Oui |
| Applications Office : activé | Oui |
| Suivre les clics des utilisateurs | Oui |
| Autoriser les utilisateurs à cliquer jusqu'à l'URL d'origine | **Non** |

```powershell
New-SafeLinksPolicy -Name "Liens fiables" `
    -EnableSafeLinksForEmail $true `
    -ScanUrls $true `
    -DeliverMessageAfterScan $true `
    -EnableForInternalSenders $true `
    -DisableUrlRewrite $false `
    -EnableSafeLinksForTeams $true `
    -EnableSafeLinksForOffice $true `
    -TrackClicks $true `
    -AllowClickThrough $false

New-SafeLinksRule -Name "Liens fiables" `
    -SafeLinksPolicy "Liens fiables" `
    -RecipientDomainIs $domains `
    -Priority 0
```

> ℹ️ Pour une URL interne ou d'un partenaire qui ne supporte pas la réécriture, ajoutez-la dans **Ne pas réécrire les URL suivantes** (`-DoNotRewriteUrls`) plutôt que de désactiver la réécriture.

Source : https://learn.microsoft.com/fr-fr/defender-office-365/safe-links-policies-configure

### Vérification de la partie messagerie

```powershell
Get-QuarantinePolicy | Select-Object Name, ESNEnabled
Get-AntiPhishPolicy | Format-List Name, PhishThresholdLevel, EnableTargetedUserProtection, EnableOrganizationDomainsProtection, HonorDmarcPolicy
Get-HostedOutboundSpamFilterPolicy | Select-Object Name, AutoForwardingMode, ActionWhenThresholdReached
Get-HostedContentFilterPolicy | Format-List Name, SpamAction, HighConfidenceSpamAction, PhishSpamAction, HighConfidencePhishAction, BulkThreshold
Get-MalwareFilterPolicy | Select-Object Name, EnableFileFilter, FileTypeAction, ZapEnabled
Get-AtpPolicyForO365 | Select-Object EnableATPForSPOTeamsODB
Get-SafeAttachmentRule | Select-Object Name, State, RecipientDomainIs
Get-SafeLinksRule | Select-Object Name, State, RecipientDomainIs
```

**Test de bout en bout :**

- Fichier de test **EICAR** (eicar.org) envoyé depuis une boîte externe : le message doit être rejeté ou mis en quarantaine.
- Transfert automatique : créez une règle de boîte de réception qui transfère vers une adresse externe. Le message transféré doit être bloqué, avec une notification d'échec (code `5.7.520`).

**Pour finir, passer l'analyseur de configuration :** portail Defender → E-mail et collaboration → Stratégies et règles → Stratégies de menace → **Analyseur de configuration**.

- Il compare chaque stratégie (anti-hameçonnage, anti-spam, anti-malware, pièces jointes fiables, liens fiables) aux niveaux **Standard** et **Strict** recommandés par Microsoft.
- Il liste chaque paramètre en écart avec la valeur actuelle et la valeur recommandée, et permet d'appliquer la recommandation en un clic.
- Objectif : aucune recommandation restante au niveau **Standard**. Les écarts restants doivent être des choix assumés (par exemple « Courrier indésirable » en indésirable plutôt qu'en quarantaine).
- Repassez-le après chaque modification des stratégies, et de temps en temps : Microsoft fait évoluer ses recommandations.

Source : https://learn.microsoft.com/fr-fr/defender-office-365/configuration-analyzer-for-security-policies
