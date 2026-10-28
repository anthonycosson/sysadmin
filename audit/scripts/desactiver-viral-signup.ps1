# =============================================================================
#  Désactiver le « viral sign-up »
# =============================================================================
#
#  allowEmailVerifiedUsersToJoinOrganization : empêche une personne de
#      rejoindre le tenant toute seule en vérifiant son adresse e-mail.
#  allowedToSignUpEmailBasedSubscriptions : empêche l'inscription à un
#      abonnement en libre-service avec une adresse e-mail.
# =============================================================================

Install-Module Microsoft.Graph -Scope CurrentUser
Import-Module Microsoft.Graph
Connect-MgGraph -Scopes "Policy.ReadWrite.Authorization"

$params = @{
    allowEmailVerifiedUsersToJoinOrganization = $false
    allowedToSignUpEmailBasedSubscriptions = $false
}

Update-MgPolicyAuthorizationPolicy -BodyParameter $params

# Vérification : les deux valeurs doivent être à False
Get-MgPolicyAuthorizationPolicy | Select AllowEmailVerifiedUsersToJoinOrganization,AllowedToSignUpEmailBasedSubscriptions
