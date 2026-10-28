# =============================================================================
#  Configurer la protection de la messagerie (EOP et Defender for Office 365)
# =============================================================================
#
#  1. Stratégie de quarantaine « Demande de libération »
#  2. Anti-hameçonnage (VIP et domaines à protéger)
#  3. Anti-spam sortant (blocage du transfert automatique vers l'extérieur)
#  4. Anti-spam entrant (indésirable ou quarantaine selon le verdict)
#  5. Anti-programme malveillant
#  6. Pièces jointes fiables  (Defender for Office 365 Plan 1)
#  7. Liens fiables           (Defender for Office 365 Plan 1)
#
#  À ADAPTER avant de lancer : la partie « Variables » juste en dessous.
#  À relancer sans risque : les étapes 1, 6 et 7 sont sautées si la stratégie
#  existe déjà, les autres modifient les stratégies par défaut.
# =============================================================================


# --- Variables ---------------------------------------------------------------

# Adresse qui reçoit les alertes (utilisateur bloqué, malware envoyé en interne)
$adresseIT = "it@contoso.com"

# Utilisateurs VIP à protéger contre l'usurpation d'identité : "Nom;adresse"
# Direction, finance, RH et adresses génériques sensibles (350 max.)
$vip = @(
    "Jean Dupont;jean.dupont@contoso.com",
    "Comptabilité;compta@contoso.com"
)

# Domaines externes à protéger (banque, fournisseurs, clients clés)
# Nos propres domaines sont protégés automatiquement
$domainesPartenaires = @("partenaire.com", "banque.fr")

$quarantaine = "Quarantaine - Demande de libération"


# --- Connexion ---------------------------------------------------------------

Install-Module ExchangeOnlineManagement -Scope CurrentUser
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

# Domaines du tenant, utilisés pour appliquer les stratégies à tout le monde
$domaines = (Get-AcceptedDomain).DomainName


# --- 1. Stratégie de quarantaine ---------------------------------------------
# L'utilisateur voit ses messages bloqués et DEMANDE leur libération,
# un administrateur valide. Il reçoit une notification (ESN).

if (-not (Get-QuarantinePolicy -Identity $quarantaine -ErrorAction SilentlyContinue)) {
    $permissions = New-QuarantinePermissions `
        -PermissionToPreview $true `
        -PermissionToRequestRelease $true `
        -PermissionToDelete $true `
        -PermissionToBlockSender $true

    New-QuarantinePolicy -Name $quarantaine -EndUserQuarantinePermissions $permissions -ESNEnabled $true
}


# --- 2. Anti-hameçonnage -----------------------------------------------------
# Attention : -TargetedUsersToProtect et -TargetedDomainsToProtect
# REMPLACENT la liste existante.

Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" `
    -PhishThresholdLevel 3 `
    -EnableTargetedUserProtection $true `
    -TargetedUsersToProtect $vip `
    -TargetedUserProtectionAction Quarantine `
    -TargetedUserQuarantineTag $quarantaine `
    -EnableOrganizationDomainsProtection $true `
    -EnableTargetedDomainsProtection $true `
    -TargetedDomainsToProtect $domainesPartenaires `
    -TargetedDomainProtectionAction Quarantine `
    -TargetedDomainQuarantineTag $quarantaine `
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


# --- 3. Anti-spam sortant ----------------------------------------------------
# Plus de transfert automatique vers l'extérieur, et blocage d'un compte
# qui envoie en masse (signe de compromission).

Set-HostedOutboundSpamFilterPolicy -Identity Default `
    -AutoForwardingMode Off `
    -RecipientLimitExternalPerHour 500 `
    -RecipientLimitInternalPerHour 1000 `
    -RecipientLimitPerDay 1000 `
    -ActionWhenThresholdReached BlockUser `
    -NotifyOutboundSpam $true `
    -NotifyOutboundSpamRecipients $adresseIT


# --- 4. Anti-spam entrant ----------------------------------------------------
# Le doute va en courrier indésirable, le danger va en quarantaine.

Set-HostedContentFilterPolicy -Identity Default `
    -BulkThreshold 6 `
    -SpamAction MoveToJmf `
    -HighConfidenceSpamAction Quarantine `
    -HighConfidenceSpamQuarantineTag $quarantaine `
    -PhishSpamAction Quarantine `
    -PhishQuarantineTag $quarantaine `
    -HighConfidencePhishAction Quarantine `
    -HighConfidencePhishQuarantineTag AdminOnlyAccessPolicy `
    -BulkSpamAction MoveToJmf `
    -QuarantineRetentionPeriod 30 `
    -InlineSafetyTipsEnabled $true `
    -SpamZapEnabled $true `
    -PhishZapEnabled $true


# --- 5. Anti-programme malveillant -------------------------------------------

Set-MalwareFilterPolicy -Identity Default `
    -EnableFileFilter $true `
    -FileTypeAction Reject `
    -ZapEnabled $true `
    -QuarantineTag AdminOnlyAccessPolicy `
    -EnableInternalSenderAdminNotifications $true `
    -InternalSenderAdminAddress $adresseIT


# --- 6. Pièces jointes fiables -----------------------------------------------

# Analyse aussi les fichiers de SharePoint, OneDrive et Teams
Set-AtpPolicyForO365 -EnableATPForSPOTeamsODB $true

if (-not (Get-SafeAttachmentPolicy -Identity "Pièces jointes fiables" -ErrorAction SilentlyContinue)) {
    New-SafeAttachmentPolicy -Name "Pièces jointes fiables" `
        -Enable $true `
        -Action Block `
        -QuarantineTag AdminOnlyAccessPolicy `
        -Redirect $false

    New-SafeAttachmentRule -Name "Pièces jointes fiables" `
        -SafeAttachmentPolicy "Pièces jointes fiables" `
        -RecipientDomainIs $domaines `
        -Priority 0
}


# --- 7. Liens fiables --------------------------------------------------------

if (-not (Get-SafeLinksPolicy -Identity "Liens fiables" -ErrorAction SilentlyContinue)) {
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
        -RecipientDomainIs $domaines `
        -Priority 0
}
