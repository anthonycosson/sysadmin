# =============================================================================
#  Audit des groupes de messagerie : qui accepte les e-mails de l'extérieur ?
# =============================================================================
#
#  Ce script liste TOUS les groupes qui ont une adresse e-mail :
#
#    - équipes Teams
#    - groupes Microsoft 365
#    - listes de distribution
#    - listes de distribution dynamiques
#    - groupes de sécurité à extension messagerie
#
#  et indique pour chacun s'il accepte les e-mails envoyés par n'importe qui
#  sur Internet (colonne AccepteExterieur).
#
#  Un groupe accepte l'extérieur quand l'option « Exiger que tous les
#  expéditeurs soient authentifiés » est désactivée
#  (RequireSenderAuthenticationEnabled = False).
#
#  Pourquoi c'est un risque : une seule adresse comme tous@contoso.com permet
#  à un attaquant d'envoyer du spam ou de l'hameçonnage à toute l'entreprise.
#
#  Colonnes utiles pour décider :
#    AccepteExterieur      Oui = n'importe qui sur Internet peut écrire au groupe
#    Membres               Plus le groupe est grand, plus le risque est élevé
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


# --- 2. Équipes Teams et groupes Microsoft 365 -------------------------------
# Une équipe Teams est un groupe Microsoft 365 avec l'option « Team »

$groupesM365 = Get-UnifiedGroup -ResultSize Unlimited

foreach ($groupe in $groupesM365) {

    if ($groupe.ResourceProvisioningOptions -contains "Team") {
        $type = "Équipe Teams"
    }
    else {
        $type = "Groupe Microsoft 365"
    }

    if ($groupe.RequireSenderAuthenticationEnabled) { $exterieur = "Non" } else { $exterieur = "Oui" }

    if ($groupe.AcceptMessagesOnlyFromSendersOrMembers.Count -gt 0) { $restreint = "Oui" } else { $restreint = "Non" }

    $liste += [pscustomobject]@{
        Type                  = $type
        Nom                   = $groupe.DisplayName
        Adresse               = $groupe.PrimarySmtpAddress
        AccepteExterieur      = $exterieur
        Membres               = $groupe.GroupMemberCount
        ExpediteursRestreints = $restreint
        Proprietaires         = $groupe.ManagedBy -join ", "
    }
}


# --- 3. Listes de distribution et groupes de sécurité à extension messagerie --

$groupes = Get-DistributionGroup -ResultSize Unlimited

foreach ($groupe in $groupes) {

    if ($groupe.RecipientTypeDetails -eq "MailUniversalSecurityGroup") {
        $type = "Groupe de sécurité"
    }
    elseif ($groupe.RecipientTypeDetails -eq "RoomList") {
        $type = "Liste de salles"
    }
    else {
        $type = "Liste de distribution"
    }

    if ($groupe.RequireSenderAuthenticationEnabled) { $exterieur = "Non" } else { $exterieur = "Oui" }

    if ($groupe.AcceptMessagesOnlyFromSendersOrMembers.Count -gt 0) { $restreint = "Oui" } else { $restreint = "Non" }

    # Nombre de membres (requête par groupe, peut prendre un peu de temps)
    # On utilise l'adresse e-mail, unique, et non le nom qui peut exister en double
    $membres = @(Get-DistributionGroupMember -Identity $groupe.PrimarySmtpAddress -ResultSize Unlimited).Count

    $liste += [pscustomobject]@{
        Type                  = $type
        Nom                   = $groupe.DisplayName
        Adresse               = $groupe.PrimarySmtpAddress
        AccepteExterieur      = $exterieur
        Membres               = $membres
        ExpediteursRestreints = $restreint
        Proprietaires         = $groupe.ManagedBy -join ", "
    }
}


# --- 4. Listes de distribution dynamiques ------------------------------------
# Leurs membres sont calculés à partir d'un filtre (service, site…)

$groupesDynamiques = Get-DynamicDistributionGroup -ResultSize Unlimited

foreach ($groupe in $groupesDynamiques) {

    if ($groupe.RequireSenderAuthenticationEnabled) { $exterieur = "Non" } else { $exterieur = "Oui" }

    if ($groupe.AcceptMessagesOnlyFromSendersOrMembers.Count -gt 0) { $restreint = "Oui" } else { $restreint = "Non" }

    $membres = @(Get-DynamicDistributionGroupMember -Identity $groupe.PrimarySmtpAddress -ResultSize Unlimited).Count

    $liste += [pscustomobject]@{
        Type                  = "Liste de distribution dynamique"
        Nom                   = $groupe.DisplayName
        Adresse               = $groupe.PrimarySmtpAddress
        AccepteExterieur      = $exterieur
        Membres               = $membres
        ExpediteursRestreints = $restreint
        Proprietaires         = $groupe.ManagedBy -join ", "
    }
}


# --- 5. Affichage ------------------------------------------------------------

# Les groupes ouverts à l'extérieur en premier, puis les plus grands
$liste = $liste | Sort-Object AccepteExterieur, Membres -Descending
$liste | Format-Table Type, Nom, Adresse, AccepteExterieur, Membres, ExpediteursRestreints -AutoSize

$ouverts = @($liste | Where-Object { $_.AccepteExterieur -eq "Oui" }).Count
Write-Host "$($liste.Count) groupe(s) au total, dont $ouverts qui acceptent les e-mails de l'extérieur."


# --- 6. Export CSV pour Excel (séparateur ";" et UTF-8 pour les accents) -----

$liste | Export-Csv -Path ".\audit-listes-distribution-externes.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Host "Export : $((Get-Location).Path)\audit-listes-distribution-externes.csv"
