# Sécuriser un tenant Microsoft 365

Procédure de renforcement d'un tenant Microsoft 365, classée par domaine. Chaque mesure indique ce qu'elle bloque, la commande pour l'appliquer et celle pour vérifier le résultat.

## 📑 Sommaire

1. [Prérequis](#prérequis)
2. [💳 Abonnements et achats](#-abonnements-et-achats)
   - [Désactiver les achats et les versions d'essai en libre-service](#désactiver-les-achats-et-les-versions-dessai-en-libre-service)
3. [👤 Identités et inscriptions](#-identités-et-inscriptions)
   - [Désactiver le « viral sign-up »](#désactiver-le--viral-sign-up-)

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

**Paramètre concerné :** `allowEmailVerifiedUsersToJoinOrganization` de la stratégie d'autorisation Entra ID.

**Rôle minimum :** Administrateur de la stratégie d'autorisation.

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Import-Module Microsoft.Graph
Connect-MgGraph

$params = @{
    allowEmailVerifiedUsersToJoinOrganization = $false
}
Update-MgPolicyAuthorizationPolicy -BodyParameter $params
```

**Vérification :** la valeur doit être `False`.

```powershell
Get-MgPolicyAuthorizationPolicy |
    Select-Object AllowEmailVerifiedUsersToJoinOrganization
```

Source : https://learn.microsoft.com/fr-fr/entra/identity/users/directory-self-service-signup
