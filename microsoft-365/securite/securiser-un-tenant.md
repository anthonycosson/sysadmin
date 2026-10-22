# Sécuriser un tenant Microsoft 365

Procédure de renforcement d'un tenant Microsoft 365, classée par domaine. Chaque mesure indique ce qu'elle bloque, la commande pour l'appliquer et celle pour vérifier le résultat.

## 📑 Sommaire

1. [Prérequis](#prérequis)
2. [💳 Abonnements et achats](#-abonnements-et-achats)
   - [Désactiver les achats et les versions d'essai en libre-service](#désactiver-les-achats-et-les-versions-dessai-en-libre-service)
3. [👤 Identités et inscriptions](#-identités-et-inscriptions)
   - [Désactiver le « viral sign-up »](#désactiver-le--viral-sign-up-)
4. [💻 Appareils](#-appareils)
   - [Configurer Windows LAPS](#configurer-windows-laps) (et désactiver les comptes Administrator et Invité)

## Prérequis

- Un compte **Administrateur global** (ou le rôle le plus restreint indiqué dans chaque section).
- PowerShell 7 recommandé, lancé en administrateur pour l'installation des modules.
- Modules utilisés :

| Module | Usage |
|---|---|
| `MSCommerce` | Stratégies d'achat en libre-service |
| `Microsoft.Graph` | Stratégies d'autorisation Entra ID |

```powershell
Install-Module MSCommerce
Install-Module Microsoft.Graph -Scope CurrentUser
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
