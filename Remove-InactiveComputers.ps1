﻿Import-Module ActiveDirectory

# Find total number of computers
Write-Output "Finding total number of computers..."
$totalcomputers = (Get-ADComputer -filter *).count
Write-Output "There are $totalcomputers computers within the domain"

# Set the number of days since last logon
$DaysInactive = 90
$InactiveDate = (Get-Date).Adddays(-($DaysInactive))

# Find stale computers (will also find never logged on computers)
$stalecomputers = Search-ADAccount -AccountInactive -DateTime $InactiveDate -ComputersOnly | Select-Object Name, LastLogonDate, Enabled, DistinguishedName

# Find total number of computers that are stale
$totalstale = $stalecomputers.count

# Check if there are no stale computers (if script already executed)
if ($totalstale -eq 0) {
  Write-Output "There are no inactive computers!"
  return
} else {
  Write-Output "There are $totalstale inactive computer objects within the domain"
}

# Create export path as users home directory
$ExportPath = Join-Path $env:USERPROFILE "InactiveComputers.csv"

# Export inactive computer list to csv
$stalecomputers | Export-Csv $ExportPath -NoTypeInformation
Write-Output "Exported a list of all inactive computers to $ExportPath"

# confrm whether want to disable inactive computers
$disableconfirmation = Read-Host "Do you want to disable all $stalecomputers inactive computers? - requires domain admin privileges (Y/N)"

if ($disableconfirmation.ToUpper() -eq 'Y') {
  # Disable Inactive Computers
  ForEach ($Item in $stalecomputers){
    Set-ADComputer -Identity $Item.DistinguishedName -Enabled $false
    Write-Output "$($Item.DistinguishedName) - Disabled"
  }
  Write-Output "All inactive computers disabled!"
} else {
  Write-Output "Inactive computers not disabled, review $ExportPath"
}

# confrm whether want to delete inactive computers
$deletionconfirmation = Read-Host "Do you want to delete all $stalecomputers inactive computers? - requires domain admin privileges (Y/N)"

if ($deletionconfirmation.ToUpper() -eq 'Y') {
  #delete inactive computers
  ForEach ($Item in $stalecomputers){
    Remove-ADComputer -Identity $Item.DistinguishedName -Confirm:$false
    Write-Output "$($Item.DistinguishedName) - Deleted"
  }
  Write-Output "All inactive computers deleted!"
} else {
  Write-Output "Inactive computers not deleted, review $ExportPath"
}