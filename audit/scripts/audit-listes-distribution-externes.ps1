# =============================================================================
#  Audit des listes de distribution qui acceptent les e-mails de l'extérieur
# =============================================================================
#
#  Ce script liste les groupes qui peuvent recevoir des e-mails envoyés par
#  n'importe qui sur Internet :
#
#    - listes de distribution
#    - groupes de sécurité à extension messagerie
#    - groupes Microsoft 365
#
#  Un groupe est ouvert à l'extérieur quand l'option « Exiger que tous les
#  expéditeurs soient authentifiés » est désactivée
#  (RequireSenderAuthenticationEnabled = False).
#
#  Pourquoi c'est un risque : une seule adresse comme tous@contoso.com permet
#  à un attaquant d'envoyer du spam ou de l'hameçonnage à toute l'entreprise.
#
#  Colonnes utiles pour décider :
#    Membres               Plus la liste est grande, plus le risque est élevé
#    ExpediteursRestreints Oui = seuls certains expéditeurs sont autorisés,
#                          le risque est limité
#
#  Le script ne fait que LIRE : il ne modifie rien.
#  Résultat : un tableau à l'écran et un fichier CSV à ouvrir dans Excel.
# =============================================================================


# --- 1. Connexion à Exchange Online ------------------------------------------

Install-Module ExchangeOnlineManagement -Scope CurrentUser
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

$liste = @()


# --- 2. Listes de distribution et groupes de sécurité à extension messagerie --

$groupes = Get-DistributionGroup -ResultSize Unlimited |
    Where-Object { $_.RequireSenderAuthenticationEnabled -eq $false }

foreach ($groupe in $groupes) {

    # Type lisible
    if ($groupe.RecipientTypeDetails -eq "MailUniversalSecurityGroup") {
        $type = "Groupe de sécurité"
    }
    elseif ($groupe.RecipientTypeDetails -eq "RoomList") {
        $type = "Liste de salles"
    }
    else {
        $type = "Liste de distribution"
    }

    # Nombre de membres (requête par groupe, peut prendre un peu de temps)
    # On utilise l'adresse e-mail, unique, et non le nom qui peut exister en double
    $membres = @(Get-DistributionGroupMember -Identity $groupe.PrimarySmtpAddress -ResultSize Unlimited).Count

    # Expéditeurs restreints : seuls certains expéditeurs peuvent écrire au groupe
    if ($groupe.AcceptMessagesOnlyFromSendersOrMembers.Count -gt 0) {
        $restreint = "Oui"
    }
    else {
        $restreint = "Non"
    }

    $liste += [pscustomobject]@{
        Type                  = $type
        Nom                   = $groupe.DisplayName
        Adresse               = $groupe.PrimarySmtpAddress
        Membres               = $membres
        ExpediteursRestreints = $restreint
        Proprietaires         = $groupe.ManagedBy -join ", "
    }
}


# --- 3. Groupes Microsoft 365 ------------------------------------------------

$groupesM365 = Get-UnifiedGroup -ResultSize Unlimited |
    Where-Object { $_.RequireSenderAuthenticationEnabled -eq $false }

foreach ($groupe in $groupesM365) {

    if ($groupe.AcceptMessagesOnlyFromSendersOrMembers.Count -gt 0) {
        $restreint = "Oui"
    }
    else {
        $restreint = "Non"
    }

    $liste += [pscustomobject]@{
        Type                  = "Groupe Microsoft 365"
        Nom                   = $groupe.DisplayName
        Adresse               = $groupe.PrimarySmtpAddress
        Membres               = $groupe.GroupMemberCount
        ExpediteursRestreints = $restreint
        Proprietaires         = $groupe.ManagedBy -join ", "
    }
}


# --- 4. Affichage ------------------------------------------------------------

# Les plus grandes listes en premier : ce sont les plus risquées
$liste = $liste | Sort-Object Membres -Descending
$liste | Format-Table Type, Nom, Adresse, Membres, ExpediteursRestreints -AutoSize

Write-Host "$($liste.Count) groupe(s) acceptent les e-mails de l'extérieur."


# --- 5. Export CSV pour Excel (séparateur ";" et UTF-8 pour les accents) -----

$liste | Export-Csv -Path ".\audit-listes-distribution-externes.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Host "Export : $((Get-Location).Path)\audit-listes-distribution-externes.csv"
