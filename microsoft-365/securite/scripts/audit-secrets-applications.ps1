# =============================================================================
#  Audit des secrets et certificats des applications inscrites dans Entra ID
# =============================================================================
#
#  Ce script liste TOUTES les applications créées dans notre tenant
#  (Entra ID > Inscriptions d'applications) avec leurs secrets et certificats.
#  Les applications Microsoft et les applications tierces ne sont pas listées.
#
#  Chaque secret ou certificat reçoit un statut :
#
#    1 - Expiré         La date d'expiration est dépassée
#    2 - Plus de 2 ans  Valide, mais créé avec une durée de plus de 2 ans
#    3 - OK             Valide, durée de 2 ans maximum
#    4 - Aucun secret   L'application n'a ni secret ni certificat
#
#  Le numéro devant le statut sert uniquement à trier la liste dans cet ordre.
#
#  Le script ne fait que LIRE : il ne modifie et ne supprime rien.
#  Résultat : un tableau à l'écran et un fichier CSV à ouvrir dans Excel.
# =============================================================================


# --- 1. Connexion à Microsoft Graph (lecture seule des applications) ---------

Connect-MgGraph -Scopes "Application.Read.All"


# --- 2. Récupération des applications ----------------------------------------
# -All        : récupère toutes les applications (sinon seulement la 1re page)
# -Property   : ne demande que les informations utiles

$applications = Get-MgApplication -All -Property DisplayName, AppId, PasswordCredentials, KeyCredentials

$aujourdhui = Get-Date
$liste = @()


# --- 3. Analyse de chaque application ----------------------------------------

foreach ($app in $applications) {

    # On rassemble les secrets et les certificats dans une seule liste
    $identifiants = @()

    foreach ($secret in $app.PasswordCredentials) {
        $identifiants += [pscustomobject]@{
            Type  = "Secret"
            Nom   = $secret.DisplayName
            Debut = $secret.StartDateTime
            Fin   = $secret.EndDateTime
        }
    }

    foreach ($certificat in $app.KeyCredentials) {
        $identifiants += [pscustomobject]@{
            Type  = "Certificat"
            Nom   = $certificat.DisplayName
            Debut = $certificat.StartDateTime
            Fin   = $certificat.EndDateTime
        }
    }

    # Application sans secret ni certificat : une seule ligne, pour qu'elle
    # apparaisse quand même dans la liste
    if ($identifiants.Count -eq 0) {
        $liste += [pscustomobject]@{
            Statut        = "4 - Aucun secret"
            Application   = $app.DisplayName
            AppId         = $app.AppId
            Type          = ""
            Nom           = ""
            Creation      = ""
            Expiration    = ""
            DureeEnJours  = ""
            JoursRestants = ""
        }
        continue
    }

    # Une ligne par secret ou certificat
    foreach ($id in $identifiants) {

        # Statut : on teste d'abord l'expiration, puis la durée
        # (Debut + 2 ans plutôt que 730 jours, pour ne pas compter les années bissextiles)
        if ($id.Fin -lt $aujourdhui) {
            $statut = "1 - Expiré"
        }
        elseif ($id.Fin -gt $id.Debut.AddYears(2)) {
            $statut = "2 - Plus de 2 ans"
        }
        else {
            $statut = "3 - OK"
        }

        $liste += [pscustomobject]@{
            Statut        = $statut
            Application   = $app.DisplayName
            AppId         = $app.AppId
            Type          = $id.Type
            Nom           = $id.Nom
            Creation      = $id.Debut.ToString("dd/MM/yyyy")
            Expiration    = $id.Fin.ToString("dd/MM/yyyy")
            DureeEnJours  = ($id.Fin - $id.Debut).Days
            JoursRestants = ($id.Fin - $aujourdhui).Days    # négatif si expiré
        }
    }
}


# --- 4. Affichage ------------------------------------------------------------

# Nombre de secrets par statut
$liste | Group-Object Statut | Sort-Object Name | Select-Object Name, Count | Format-Table -AutoSize

# Liste détaillée, triée par statut puis par application
$liste = $liste | Sort-Object Statut, Application
$liste | Format-Table Statut, Application, Type, Nom, Creation, Expiration, DureeEnJours -AutoSize


# --- 5. Export CSV pour Excel (séparateur ";" et UTF-8 pour les accents) -----

$liste | Export-Csv -Path ".\audit-secrets-applications.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Host "Export : $((Get-Location).Path)\audit-secrets-applications.csv"

