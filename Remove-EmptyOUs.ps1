# Ensure a system state backup of the domain is available for recovery before running
Import-Module ActiveDirectory

# Find total amount of OUs
Write-Output "Finding total number of OUs..."
$totalOU = (Get-ADOrganizationalUnit -filter *).count
Write-Output "There are $totalOU OUs within the domain"

# Get empty OUs: gets all OUs, filters for those with no objects in then sorts by CN length to delete empty leaf OUs first
Write-Output "Finding total number of empty OUs (may take a while) ..."
$emptyOU = Get-ADOrganizationalUnit -filter * -Properties * | Select DistinguishedName, @{Name="Length"; e={$_.DistinguishedName.length}}, Name, @{Name="numObject"; Expression = { Get-ADObject -filter * -SearchBase $_.DistinguishedName | Where {$_.objectclass -ne "organizationalunit"} | Measure-Object | Select -ExpandProperty Count }} | Where {$_.numObject -eq 0} | Sort-Object -Property Length -Descending 

# Find total amount of OUs that are empty
$totalempty = $emptyOU.count

# Check if there are no empty OUs (if script already executed)
if ($totalempty -eq 0) {
  Write-Output "There are no empty OUs!"
  return
} else {
  Write-Output "There are $totalempty empty OUs within the domain"
  Write-Output "The domain size can be reduced by approximately $([math]::Round(($totalempty / $totalOU * 100), 2))%"
}

# Create export path as users home directory
$ExportPath = Join-Path $env:USERPROFILE "EmptyOUs.csv"

# Export empty OU list to csv
$emptyOU | Export-Csv $ExportPath -NoTypeInformation
Write-Output "Exported a list of all empty OUs to $ExportPath"

# confrm whether want to delete empty OUs - deletion will require domain admin
$confirmation = Read-Host "Do you want to delete all $totalempty empty OUs? - requires domain admin privileges (Y/N)"

if ($confirmation -eq 'Y') {
  # loop to cover all empty OUs, will cover empty leaf OUs first then work way up (see csv for order)
  ForEach ($Item in $emptyOU) {
  # remove deletion protection on each empty OU 
  Set-ADOrganizationalUnit -Identity $Item.DistinguishedName -ProtectedFromAccidentalDeletion $False 
  Write-Output "$($Item.DistinguishedName) - Deletion protection removed"

  # delete each empty OU
  Remove-ADOrganizationalUnit -Identity $Item.DistinguishedName -Confirm:$false
  Write-Output "$($Item.DistinguishedName) - Deleted"
  }
  Write-Output "All empty OUs deleted!"
} 
else {
  Write-Output "Empty OUs not deleted, review $ExportPath"
}
