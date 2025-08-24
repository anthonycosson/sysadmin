# Resynchroniser un compte AAD avec un compte AD en cas de doublon

## Récupérer l'immutable ID du compte sur Azure 

`Connect-MsolService`
`Get-MsolUser -UserPrincipalName "user@domain.tld" | Select-Object UserPrincipalName, ImmutableId`

## Convertir cette valeur de base64 vers un GUID

`$immutableID = "Valeur de l'ImmutableID"`
`$guid = [System.Guid]::New(([System.Convert]::FromBase64String($immutableID)))`
`$guid`

## Remplacer l'attribut mS-DS-ConsistencyGUID du compte AD par la valeur de $GUID

`Set-ADObject -Identity "CN=XXX,OU=XXX,DC=XXX,DC=XXX" -Replace @{ 'mS-DS-ConsistencyGUID' = $guid.ToByteArray() }`

**Attention** : Si le compte était déjà synchronisé il faudra d'abord le sortir de la synchro Entra Connect, supprimer définitivement le compte cloud .onmicrosoft.com qui aura été créer entre temps et le remettre dans la synchro après avoir fait les étapes précédente.