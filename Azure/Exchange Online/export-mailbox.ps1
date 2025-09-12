# Boîtes utilisateurs avec taille
Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited |
  ForEach-Object { $s=Get-EXOMailboxStatistics $_.UserPrincipalName; [pscustomobject]@{DisplayName=$_.DisplayName;GivenName=$_.GivenName;Surname=$_.Surname;Email=$_.PrimarySmtpAddress;TotalSize=$s.TotalItemSize.Value} } |
  Export-Csv "user_mailboxes.csv" -NoTypeInformation -Delimiter ';' -Encoding UTF8

# Boîtes partagées avec taille
Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited |
  ForEach-Object { $s=Get-EXOMailboxStatistics $_.UserPrincipalName; [pscustomobject]@{DisplayName=$_.DisplayName;Email=$_.PrimarySmtpAddress;TotalSize=$s.TotalItemSize.Value} } |
  Export-Csv "shared_mailboxes.csv" -NoTypeInformation -Delimiter ';' -Encoding UTF8