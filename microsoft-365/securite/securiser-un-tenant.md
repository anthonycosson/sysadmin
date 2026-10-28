# Sécuriser un tenant Microsoft 365

Checklist de renforcement d'un tenant. Les scripts sont dans [scripts/](scripts/).

| Domaine | Mesure | Comment |
|---|---|---|
| 💳 Achats | Désactiver les achats et essais en libre-service | [desactiver-achats-libre-service.ps1](scripts/desactiver-achats-libre-service.ps1) |
| 👤 Identités | Désactiver le viral sign-up | [desactiver-viral-signup.ps1](scripts/desactiver-viral-signup.ps1) |
| 🧩 Applications | Auditer les secrets et certificats (2 ans max.) | [audit-secrets-applications.ps1](scripts/audit-secrets-applications.ps1) |
| 💻 Appareils | Windows LAPS, comptes Administrator et Invité désactivés | Portails Entra et Intune |
| 📧 Messagerie | SPF, DKIM, DMARC | DNS + 3 commandes |
| 📧 Messagerie | Quarantaine, anti-hameçonnage, anti-spam, anti-malware, pièces jointes et liens fiables | [configurer-protection-messagerie.ps1](scripts/configurer-protection-messagerie.ps1) |

**Prérequis :** un compte Administrateur global et PowerShell 7. Chaque script installe et importe le module dont il a besoin.

## 💳 Achats en libre-service

Par défaut, un utilisateur peut acheter ou essayer une licence (Power BI, Power Automate, Visio…) sans passer par l'informatique.

➡️ [desactiver-achats-libre-service.ps1](scripts/desactiver-achats-libre-service.ps1) : à relancer de temps en temps, car Microsoft ajoute régulièrement de nouveaux produits activés par défaut.

## 👤 Viral sign-up

Sans ce réglage, n'importe qui avec une adresse de votre domaine peut rejoindre le tenant ou s'inscrire à un abonnement, sans qu'un administrateur ait créé le compte.

➡️ [desactiver-viral-signup.ps1](scripts/desactiver-viral-signup.ps1) : les deux paramètres doivent être à `False`.

## 🧩 Secrets et certificats des applications

Un secret d'application est un mot de passe, souvent avec des droits larges. **Règle : 2 ans de validité maximum.**

➡️ [audit-secrets-applications.ps1](scripts/audit-secrets-applications.ps1) liste toutes les inscriptions d'applications du tenant et exporte un CSV :

| Statut | Action |
|---|---|
| `1 - Expiré` | Supprimer le secret. Supprimer l'application si personne ne la réclame |
| `2 - Plus de 2 ans` | Créer un nouveau secret de 2 ans max., le mettre en place, **puis** supprimer l'ancien |
| `3 - OK` | Rien à faire |
| `4 - Aucun secret` | Normal si l'application ne fait que connecter des utilisateurs |

Renouvellement : Entra ID → Inscriptions d'applications → *application* → Certificats et secrets.

## 💻 Windows LAPS

Un mot de passe administrateur local unique par poste, qui tourne automatiquement et est sauvegardé dans Entra ID.

**Prérequis :** postes joints à Entra ID (ou hybrides), **Windows 11 24H2** pour la gestion automatique du compte.

1. **Entra ID** → Appareils → Paramètres de l'appareil → **Activer Microsoft Entra LAPS** : `Oui`.
2. **Intune** → Sécurité des points de terminaison → Protection du compte → **Windows LAPS** :
   - Backup Directory : `Azure AD only`
   - Password Age Days `30`, Password Length `20`, complexité maximale
   - Post Authentication Actions : `Reset the password and logoff`
   - Automatic Account Management : `Enabled`, Target `new custom administrator account`, nom `lapsadmin`
3. **Intune** → Configuration → Catalogue des paramètres → *Local Policies Security Options* :
   - `Accounts: Enable Administrator Account Status` = `Disable`
   - `Accounts: Enable Guest Account Status` = `Disable`
4. **Intune** → Sécurité des points de terminaison → Protection du compte → **Appartenance au groupe d'utilisateurs locaux** :
   - Groupe `Administrators`, action `Replace`
   - Membres : `AzureAD\Device Administrators` et `lapsadmin`

Les trois stratégies Intune ciblent **uniquement des groupes d'appareils**.

> ⚠️ `Replace` retire du groupe tout membre non listé. Tester sur un groupe pilote.

**Vérification sur un poste :**

```powershell
Invoke-LapsPolicyProcessing
Get-LocalUser | Select-Object Name, Enabled      # Administrator et Invité désactivés, lapsadmin activé
Get-LocalGroupMember -SID "S-1-5-32-544"         # groupe Administrateurs
```

Mot de passe : Intune → Appareils → *poste* → **Mot de passe d'administrateur local**.

## 📧 Messagerie

### SPF, DKIM, DMARC

Pour **chaque domaine** qui envoie des e-mails :

| Type | Nom | Valeur |
|---|---|---|
| TXT | `@` | `v=spf1 include:spf.protection.outlook.com -all` |
| CNAME | `selector1._domainkey` | Donné par `Get-DkimSigningConfig` |
| CNAME | `selector2._domainkey` | Donné par `Get-DkimSigningConfig` |
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc@contoso.com` |

```powershell
Connect-ExchangeOnline
New-DkimSigningConfig -DomainName contoso.com -Enabled $false
Get-DkimSigningConfig -Identity contoso.com | Format-List Selector1CNAME, Selector2CNAME
# Une fois les CNAME créés dans le DNS :
Set-DkimSigningConfig -Identity contoso.com -Enabled $true
```

- **SPF** : un seul enregistrement par domaine. Ajouter les autres services qui envoient avec votre domaine (outil d'e-mailing, CRM…).
- **DMARC** : monter progressivement `p=none` → `p=quarantine` → `p=reject`, en lisant les rapports entre chaque étape.
- **Domaine qui n'envoie rien** : `v=spf1 -all` et `v=DMARC1; p=reject;`.

### Protection de la messagerie

➡️ [configurer-protection-messagerie.ps1](scripts/configurer-protection-messagerie.ps1) : adapter les variables en haut du script (adresse IT, VIP, domaines partenaires), puis le lancer.

**Licence :** pièces jointes fiables, liens fiables et protection des VIP demandent **Defender for Office 365 Plan 1** (inclus dans Business Premium).

**Ce que fait le script :**

| Stratégie | Réglage clé |
|---|---|
| Quarantaine | L'utilisateur **demande** la libération, un administrateur valide |
| Anti-hameçonnage | Protection des **VIP** (direction, compta, paie…) et des **domaines** (les nôtres + partenaires) |
| Anti-spam sortant | **Transfert automatique vers l'extérieur bloqué**, compte bloqué s'il envoie en masse |
| Anti-spam entrant | Voir le tableau ci-dessous |
| Anti-malware | Pièces jointes dangereuses (`exe`, `iso`, `lnk`…) rejetées |
| Pièces jointes fiables | Analyse en bac à sable, aussi dans SharePoint, OneDrive et Teams |
| Liens fiables | Liens vérifiés au moment du clic (e-mails, Teams, Office) |

**Anti-spam entrant : indésirable ou quarantaine ?** Le doute va en courrier indésirable, le danger va en quarantaine.

| Verdict | Action |
|---|---|
| Spam, courrier en nombre | Courrier indésirable |
| Spam à haut niveau de confiance, hameçonnage | Quarantaine, avec demande de libération |
| Hameçonnage à haut niveau de confiance, malware | Quarantaine, administrateur seulement |

**Après le script :**

- Defender → Stratégies de menace → Stratégies d'alerte → *« L'utilisateur a demandé à libérer un message mis en quarantaine »* : ajouter le service informatique comme destinataire.
- Une boîte qui doit vraiment transférer vers l'extérieur : créer une stratégie anti-spam sortante dédiée, limitée à cette boîte.

### Vérification

**Passer l'analyseur de configuration :** Defender → E-mail et collaboration → Stratégies et règles → Stratégies de menace → **Analyseur de configuration**. Il compare les stratégies aux recommandations Microsoft (Standard et Strict). L'objectif est de n'avoir aucun écart au niveau Standard, en dehors des choix assumés. À repasser après chaque modification.
