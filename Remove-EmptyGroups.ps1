Import-Module ActiveDirectory

# Find total amount of groups
Write-Output "Finding total number of groups..."
$totalgroups = (Get-ADGroup -filter *).count
Write-Output "There are $totalgroups groups within the domain"

# Get empty groups
Write-Output "Finding total number of empty groups (may take a while) ..."
$emptygroups = Get-ADGroup -Filter { Members -notlike "*" } | Select-Object Name, DistinguishedName

# Find total amount of groups that are empty
$totalempty = $emptygroups.count

# Check if there are no empty groups (if script already executed)
if ($totalempty -eq 0) {
  Write-Output "There are no empty groups!"
  return
} else {
  Write-Output "There are $totalempty empty groups within the domain"
}

# Create export path as users home directory
$ExportPath = Join-Path $env:USERPROFILE "EmptyGroups.csv"

# Export empty group list to csv
$emptygroups | Export-Csv $ExportPath -NoTypeInformation
Write-Output "Exported a list of all empty groups to $ExportPath"

# confrm whether want to delete empty groups - deletion will require domain admin
$confirmation = Read-Host "Do you want to delete all $totalempty groups? - requires domain admin privileges (Y/N)"

if ($confirmation.ToUpper() -eq 'Y') {
  # loop to cover all empty groups
  ForEach ($Item in $emptygroups) {
    Remove-ADGroup -Identity $Item.DistinguishedName -Confirm:$false
    Write-Output "$($Item.DistinguishedName) - Deleted"
  }
  Write-Output "All empty groups deleted!"
} 
else {
  Write-Output "Empty groups not deleted, review $ExportPath"
}