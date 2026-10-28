# =============================================================================
#  Désactiver les achats et les versions d'essai en libre-service
# =============================================================================
#
#  Empêche les utilisateurs d'acheter ou d'essayer eux-mêmes une licence
#  (Power BI Pro, Power Automate, Visio…) sans passer par l'informatique.
#
#  Microsoft ajoute régulièrement de nouveaux produits, activés par défaut :
#  relancer le script de temps en temps.
# =============================================================================

Install-Module MSCommerce
Import-Module MSCommerce
Connect-MSCommerce

# Désactiver tous les produits encore autorisés
Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase |
    Where-Object { $_.PolicyValue -eq "Enabled" } |
    ForEach-Object {
        Update-MSCommerceProductPolicy `
            -PolicyId AllowSelfServicePurchase `
            -ProductId $_.ProductId `
            -Enabled $False
    }

# Vérification : aucun produit ne doit rester à "Enabled"
Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase |
    Select-Object ProductName, PolicyValue
