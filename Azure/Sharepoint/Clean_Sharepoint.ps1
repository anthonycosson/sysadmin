# Créer une application d'entreprise et récupération du client ID de l'application
## > Register-PnPEntraIDAppForInteractiveLogin -ApplicationName "PnP PowerShell" -SharePointDelegatePermissions "AllSites.FullControl" -Tenant xxx.onmicrosoft.com -Interactive

# Variable à modifier
$sourceSite = "https://XXX.sharepoint.com/sites/XXXX"
$ClientId = "XXXXXXXXXXXXXXXXXXX"

# Connexion au site Sharepoint cible

try {
    Connect-PnPOnline -Url $sourceSite -ClientId $ClientId
    Write-Host -ForegroundColor Green "✅ Connexion réussie à SharePoint Online"
}
catch {
    Write-Host -ForegroundColor Red "❌ Échec de la connexion : $($_.Exception.Message)"
    exit
}

# Modifier la stratégie de rétention des fichiers (Adapter les valeurs au besoin)

try {
    Set-PnPSiteVersionPolicy -EnableAutoExpirationVersionTrim $false -MajorVersions 30 -MajorWithMinorVersions 30 -ExpireVersionsAfterDays 30
    Write-Host -ForegroundColor Green "✅ Modification des stratégies de rétention"
}
catch {
    Write-Host -ForegroundColor Yellow "❌ Échec de la modifiation des stratégies : $($_.Exception.Message)"
}

# Lancer le job de suppression de versions pour ne garde qu'une seul version (Adapter les valeurs au besoin)

try {
    New-PnPSiteFileVersionBatchDeleteJob -MajorVersionLimit 30 -MajorWithMinorVersionsLimit 30 -Force
    Write-Host -ForegroundColor Green "✅ Suppression des versions précédentes"
}
catch {
    Write-Host -ForegroundColor Yellow "❌ Échec de la supression des versions précédentes : $($_.Exception.Message)"
}

# Vider la corbeille

try {
    Clear-PnPRecycleBinItem -All -Force
    Write-Host -ForegroundColor Green "✅ Suppression de la corbeille"
}
catch {
    Write-Host -ForegroundColor Red "❌ Échec de la suppression de la corbeille : $($_.Exception.Message)"
}

# Vérifier l'état de la stratégie de rétention

try {
    Write-Host -ForegroundColor Cyan "📊 Voici l'état de la tâche de suppression des versions :"
    Get-PnPSiteVersionPolicyStatus
}
catch {
    Write-Host -ForegroundColor Yellow "❌ Impossible de récupérer l'état de la tâche de suppression des versions : $($_.Exception.Message)"
}

# Vérifier l'état du job de la supression des version

try {
    Write-Host -ForegroundColor Cyan "📊 Voici l'état de la tâche de suppression des versions :"
    Get-PnPSiteFileVersionBatchDeleteJobStatus
}
catch {
    Write-Host -ForegroundColor Yellow "❌ Impossible de récupérer l'état de la tâche de suppression des versions : $($_.Exception.Message)"
}