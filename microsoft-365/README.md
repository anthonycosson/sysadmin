# ☁️ Microsoft 365

## 🔑 Entra ID

- [Kerberos Cloud](entra/kerberos-cloud.md) : créer l'objet serveur AzureADKerberos dans l'AD (Windows Hello for Business, clés FIDO2)
- [Resynchroniser un compte AD et Entra](entra/resynchroniser-compte-ad-entra.md) : corriger un doublon via l'ImmutableID et `mS-DS-ConsistencyGUID`

## 📧 Exchange Online

- [export-mailbox.ps1](exchange-online/export-mailbox.ps1) : exporter la liste des boîtes utilisateurs et partagées avec leur taille

## 🛡️ Sécurité

- [Sécuriser un tenant Microsoft 365](securite/securiser-un-tenant.md) : checklist de renforcement du tenant (achats, viral sign-up, secrets des applications, Windows LAPS, SPF/DKIM/DMARC, protection de la messagerie)
- [Scripts](securite/scripts/) : désactivation des achats en libre-service et du viral sign-up, audit des secrets des applications, configuration de la protection de la messagerie

## 📁 SharePoint

- [clean-sharepoint.ps1](sharepoint/clean-sharepoint.ps1) : limiter et purger l'historique des versions de fichiers d'un site avec PnP PowerShell
