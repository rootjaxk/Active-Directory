Import-Module ActiveDirectory

# Find total number of users
Write-Output "Finding total number of users..."
$totalusers = (Get-ADUser -filter *).count
Write-Output "There are $totalusers users within the domain"

# Set the number of days since last logon
$DaysInactive = 90
$InactiveDate = (Get-Date).Adddays(-($DaysInactive))

# Find stale users (will also find never logged on users)
$staleusers = Search-ADAccount -AccountInactive -DateTime $InactiveDate -UsersOnly | Select-Object @{ Name="Username"; Expression={$_.SamAccountName} }, Name, LastLogonDate, DistinguishedName

# Find total number of users that are stale
$totalstale = $staleusers.count

# Check if there are no stale users (if script already executed)
if ($totalstale -eq 0) {
  Write-Output "There are no inactive users!"
  return
} else {
  Write-Output "There are $totalstale inactive users within the domain"
}

# Create export path as users home directory
$ExportPath = Join-Path $env:USERPROFILE "InactiveUsers.csv"

# Export inactive user list to csv
$staleusers | Export-Csv $ExportPath -NoTypeInformation
Write-Output "Exported a list of all inactive users to $ExportPath"

# confrm whether want to disable inactive users
$disableconfirmation = Read-Host "Do you want to disable all $staleusers inactive users? - requires domain admin privileges (Y/N)"

if ($disableconfirmation -eq 'Y') {
  # Disable Inactive Users
  ForEach ($Item in $staleusers){
    Disable-ADAccount -Identity $Item.DistinguishedName
    Write-Output "$($Item.DistinguishedName) - Disabled"
    Get-ADUser -Filter { DistinguishedName -eq $Item.DistinguishedName } | Select-Object @{ Name="Username"; Expression={$_.SamAccountName} }, Name, Enabled
  }
  Write-Output "All inactive users disabled!"
} else {
  Write-Output "Inactive users not disabled, review $ExportPath"
}

# confrm whether want to delete inactive users
$deletionconfirmation = Read-Host "Do you want to delete all $staleusers inactive users? - requires domain admin privileges (Y/N)"

if ($deletionconfirmation.ToUpper() -eq 'Y') {
  #delete inactive Users
  ForEach ($Item in $staleusers){
    Remove-ADUser -Identity $Item.DistinguishedName -Confirm:$false
    Write-Output "$($Item.Username) - Deleted"
  }
  Write-Output "All inactive users deleted!"
} else {
  Write-Output "Inactive users not deleted, review $ExportPath"
}