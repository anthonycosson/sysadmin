# 🛡️ Audit : sécuriser un tenant Microsoft 365

Liste des points à traiter un par un pour renforcer un tenant. Cochez chaque point une fois fait et vérifié. Les scripts sont dans [scripts/](scripts/).

**Prérequis :** un compte Administrateur global et PowerShell 7. Chaque script installe et importe le module dont il a besoin.

## 📑 Sommaire

1. [💳 Achats en libre-service](#-1-achats-en-libre-service)
2. [👤 Identités](#-2-identités)
3. [🧩 Applications Entra ID](#-3-applications-entra-id)
4. [💻 Appareils : Windows LAPS](#-4-appareils--windows-laps)
5. [📧 Messagerie : SPF, DKIM, DMARC](#-5-messagerie--spf-dkim-dmarc)
6. [📧 Messagerie : protection](#-6-messagerie--protection)
7. [📧 Messagerie : listes de distribution](#-7-messagerie--listes-de-distribution)

## 💳 1. Achats en libre-service

- [ ] **Désactiver les achats et les versions d'essai en libre-service**
  - Pourquoi : un utilisateur peut acheter ou essayer une licence (Power BI, Power Automate, Visio…) sans passer par l'informatique.
  - Script : [desactiver-achats-libre-service.ps1](scripts/desactiver-achats-libre-service.ps1)
  - Vérification : aucun produit ne reste à `Enabled`. À relancer de temps en temps, car Microsoft ajoute des produits activés par défaut.

## 👤 2. Identités

- [ ] **Désactiver le viral sign-up**
  - Pourquoi : n'importe qui avec une adresse de votre domaine peut rejoindre le tenant ou s'inscrire à un abonnement, sans qu'un administrateur ait créé le compte.
  - Script : [desactiver-viral-signup.ps1](scripts/desactiver-viral-signup.ps1)
  - Vérification : `AllowEmailVerifiedUsersToJoinOrganization` et `AllowedToSignUpEmailBasedSubscriptions` sont à `False`.

## 🧩 3. Applications Entra ID

- [ ] **Auditer les secrets et certificats des applications (2 ans de validité max.)**
  - Pourquoi : un secret d'application est un mot de passe, souvent avec des droits larges.
  - Script : [audit-secrets-applications.ps1](scripts/audit-secrets-applications.ps1). Il liste toutes les inscriptions d'applications du tenant avec leurs secrets et exporte un CSV. Les applications créées automatiquement par Microsoft (tableau ci-dessous) sont exclues.
- [ ] **Traiter chaque ligne du CSV selon son statut**

  | Statut | Action |
  |---|---|
  | `1 - Expiré` | Supprimer le secret. Supprimer l'application si personne ne la réclame |
  | `2 - Plus de 2 ans` | Créer un nouveau secret de 2 ans max., le mettre en place, **puis** supprimer l'ancien |
  | `3 - OK` | Rien à faire |
  | `4 - Aucun secret` | Normal si l'application ne fait que connecter des utilisateurs. Vérifier qu'elle sert encore (journaux de connexion) et qu'elle a un propriétaire |

  - Avant de supprimer une application, la **désactiver** : Applications d'entreprise → *application* → Propriétés → *Activée pour la connexion des utilisateurs* : `Non`. Attendre 30 à 60 jours que quelqu'un réclame avant de **supprimer** (restaurable pendant 30 jours).

  Renouvellement : Entra ID → Inscriptions d'applications → *application* → Certificats et secrets.

  **⚠️ Applications créées automatiquement par Microsoft : ne pas supprimer ni modifier**, même si leur secret dépasse 2 ans : il est géré par Microsoft. Le script les exclut par leur nom (liste `$applicationsMicrosoft` en haut du script, à compléter au fil des clients).

  | Application | Rôle | Si on la supprime |
  |---|---|---|
  | `P2P Server` | Créée par Windows et Entra ID pour l'authentification entre postes joints à Entra ID, notamment le **Bureau à distance avec un compte Entra** | Le Bureau à distance entre postes joints à Entra ID ne fonctionne plus |
  | `SharePoint Online Client Extensibility Web Application Principal` et `… Helper` | Créées par SharePoint pour que les solutions **SharePoint Framework (SPFx)** appellent des API (Graph, API maison). Leurs autorisations se contrôlent dans SharePoint → Avancé → **Accès aux API** | Les WebParts et extensions SPFx qui appellent une API cessent de fonctionner |

  En cas de doute sur une application au nom de service Microsoft (SharePoint, Teams, Office, Intune…), chercher son nom sur learn.microsoft.com avant d'y toucher.

## 💻 4. Appareils : Windows LAPS

Un mot de passe administrateur local unique par poste, qui tourne automatiquement et est sauvegardé dans Entra ID.

Prérequis : postes joints à Entra ID (ou hybrides), **Windows 11 24H2** pour la gestion automatique du compte. Les stratégies Intune ciblent **uniquement des groupes d'appareils**.

- [ ] **Activer LAPS dans Entra ID**
  - Entra ID → Appareils → Paramètres de l'appareil → **Activer Microsoft Entra LAPS** : `Oui`
- [ ] **Créer la stratégie Windows LAPS**
  - Intune → Sécurité des points de terminaison → Protection du compte → **Windows LAPS**
  - Backup Directory : `Azure AD only`
  - Password Age Days `30`, Password Length `20`, complexité maximale
  - Post Authentication Actions : `Reset the password and logoff`
  - Automatic Account Management : `Enabled`, Target `new custom administrator account`, nom `lapsadmin`
- [ ] **Désactiver les comptes Administrator et Invité intégrés**
  - Intune → Configuration → Catalogue des paramètres → *Local Policies Security Options*
  - `Accounts: Enable Administrator Account Status` = `Disable`
  - `Accounts: Enable Guest Account Status` = `Disable`
- [ ] **Définir les membres du groupe Administrateurs local**
  - Intune → Sécurité des points de terminaison → Protection du compte → **Appartenance au groupe d'utilisateurs locaux**
  - Groupe `Administrators`, action `Replace`
  - Membres : `AzureAD\Device Administrators` et `lapsadmin`
  - ⚠️ `Replace` retire du groupe tout membre non listé : tester sur un groupe pilote.
- [ ] **Vérifier sur un poste**

  ```powershell
  Invoke-LapsPolicyProcessing
  Get-LocalUser | Select-Object Name, Enabled      # Administrator et Invité désactivés, lapsadmin activé
  Get-LocalGroupMember -SID "S-1-5-32-544"         # groupe Administrateurs
  ```

  Mot de passe : Intune → Appareils → *poste* → **Mot de passe d'administrateur local**.

## 📧 5. Messagerie : SPF, DKIM, DMARC

À faire pour **chaque domaine** qui envoie des e-mails.

- [ ] **SPF** : enregistrement TXT `@` = `v=spf1 include:spf.protection.outlook.com -all`
  - Un seul enregistrement par domaine. Ajouter les autres services qui envoient avec votre domaine (outil d'e-mailing, CRM…).
- [ ] **DKIM** : créer la configuration, puis les deux CNAME `selector1._domainkey` et `selector2._domainkey`, puis l'activer

  ```powershell
  Connect-ExchangeOnline
  New-DkimSigningConfig -DomainName contoso.com -Enabled $false
  Get-DkimSigningConfig -Identity contoso.com | Format-List Selector1CNAME, Selector2CNAME
  # Une fois les CNAME créés dans le DNS :
  Set-DkimSigningConfig -Identity contoso.com -Enabled $true
  ```

- [ ] **DMARC** : enregistrement TXT `_dmarc` = `v=DMARC1; p=none; rua=mailto:dmarc@contoso.com`
  - Monter progressivement `p=none` → `p=quarantine` → `p=reject`, en lisant les rapports entre chaque étape.
- [ ] **Domaines qui n'envoient rien** : `v=spf1 -all` et `v=DMARC1; p=reject;`

## 📧 6. Messagerie : protection

Licence : pièces jointes fiables, liens fiables et protection des VIP demandent **Defender for Office 365 Plan 1** (inclus dans Business Premium).

- [ ] **Adapter les variables du script** : adresse IT, VIP (direction, compta, paie…), domaines partenaires
- [ ] **Lancer le script** [configurer-protection-messagerie.ps1](scripts/configurer-protection-messagerie.ps1)

  | Stratégie | Réglage clé |
  |---|---|
  | Quarantaine | L'utilisateur **demande** la libération, un administrateur valide |
  | Anti-hameçonnage | Protection des **VIP** et des **domaines** (les nôtres + partenaires) |
  | Anti-spam sortant | **Transfert automatique vers l'extérieur bloqué**, compte bloqué s'il envoie en masse |
  | Anti-spam entrant | Le doute va en courrier indésirable, le danger va en quarantaine (voir ci-dessous) |
  | Anti-malware | Pièces jointes dangereuses (`exe`, `iso`, `lnk`…) rejetées |
  | Pièces jointes fiables | Analyse en bac à sable, aussi dans SharePoint, OneDrive et Teams |
  | Liens fiables | Liens vérifiés au moment du clic (e-mails, Teams, Office) |

  | Verdict anti-spam entrant | Action |
  |---|---|
  | Spam, courrier en nombre | Courrier indésirable |
  | Spam à haut niveau de confiance, hameçonnage | Quarantaine, avec demande de libération |
  | Hameçonnage à haut niveau de confiance, malware | Quarantaine, administrateur seulement |

- [ ] **Alerte de demande de libération** : Defender → Stratégies de menace → Stratégies d'alerte → *« L'utilisateur a demandé à libérer un message mis en quarantaine »* → ajouter le service informatique comme destinataire
- [ ] **Exceptions de transfert** : une boîte qui doit vraiment transférer vers l'extérieur a sa propre stratégie anti-spam sortante, limitée à cette boîte
- [ ] **Passer l'analyseur de configuration** : Defender → E-mail et collaboration → Stratégies et règles → Stratégies de menace → **Analyseur de configuration**
  - Objectif : aucun écart au niveau Standard, en dehors des choix assumés. À repasser après chaque modification.

## 📧 7. Messagerie : listes de distribution

Une liste ouverte à l'extérieur, comme `tous@contoso.com`, permet à n'importe qui sur Internet d'envoyer du spam ou de l'hameçonnage à toute l'entreprise en un seul e-mail.

- [ ] **Lister les groupes qui acceptent les e-mails de l'extérieur**
  - Script : [audit-listes-distribution-externes.ps1](scripts/audit-listes-distribution-externes.ps1). Il couvre les listes de distribution, les groupes de sécurité à extension messagerie et les groupes Microsoft 365, et exporte un CSV trié par nombre de membres.
  - `ExpediteursRestreints = Oui` : seuls certains expéditeurs peuvent écrire au groupe, le risque est limité.
  - Les groupes Microsoft 365 sont fermés à l'extérieur par défaut : ceux qui apparaissent ont été ouverts volontairement.
- [ ] **Traiter chaque groupe**

  | Situation | Action |
  |---|---|
  | Liste interne (`tous@`, `direction@`, `service-x@`) | Fermer à l'extérieur |
  | Adresse publique légitime (`contact@`, `support@`, `recrutement@`) | Laisser ouverte |
  | Ouverte pour quelques partenaires précis | Fermer, sauf aux partenaires : expéditeurs autorisés uniquement |

  ```powershell
  # Fermer une liste de distribution ou un groupe de sécurité à l'extérieur
  Set-DistributionGroup -Identity "tous@contoso.com" -RequireSenderAuthenticationEnabled $true

  # Fermer un groupe Microsoft 365 à l'extérieur
  Set-UnifiedGroup -Identity "projet@contoso.com" -RequireSenderAuthenticationEnabled $true
  ```

  Toujours utiliser l'**adresse e-mail** du groupe comme `-Identity` : le nom peut exister en double et la commande échoue.
