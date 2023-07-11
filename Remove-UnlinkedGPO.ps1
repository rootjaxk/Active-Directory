Import-Module GroupPolicy

# Find total amount of GPOs
Write-Output "Finding total number of GPOs..."
$totalGPO = (Get-GPO -All).count
Write-Output "There are $totalGPO GPOs within the domain"

# Get all GPOs with the gpo report type as XML and also look for the section <LinksTo> in the xml report, considering only the GPOs that doesnt have <LinksTo> section.
Write-Output "Finding total number of unlinked GPOs (will take a long time) ..."
$unlinkedGPOs = Get-GPO -All | Where-Object { $_ | Get-GPOReport -ReportType XML | Select-String -NotMatch "<LinksTo>" }

# Find total GPOs that are unlinked
$totalunlinked = $unlinkedGPOs.count

# Check if there are no unlinked GPOs (if script already executed)
if ($totalunlinked -eq 0) {
  Write-Output "There are no unlinked GPOs!"
  return
} else {
  Write-Output "There are $totalunlinked unlinked GPOs within the domain"
}

## Creates a backup directory to store the GPO reports
$BackupDir = Join-Path $env:USERPROFILE "GPO-Backup"
if (-Not(Test-Path -Path $BackupDir))  {
  New-Item -ItemType Directory $BackupDir -Force
}

# Backup loop
ForEach ($Item in $unlinkedGPOs) {  
  # Backup the GPO & HTML report to preserve GPO details
  Write-Output "Backing up $Item.DisplayName to $BackupDir"
  Backup-GPO -Name $Item.DisplayName -Path $BackupDir
  Get-GPOReport -Name $Item.DisplayName -ReportType Html -Path "$BackupDir\$($Item.DisplayName).html"
}
Write-Output "All unlinked GPOs backedup! Review $BackupDir for confirmation"

# confirm whether want to delete unlinked GPOs - deletion will require domain admin
$confirmation = Read-Host "Do you want to delete all $totalunlinked GPOs? - requires domain admin privileges (Y/N)"
if ($confirmation -eq 'Y') {
  ForEach ($Item in $unlinkedGPOs) { 
    $Item.Displayname | Remove-GPO
    Write-Output "$Item.Displayname deleted"
  } 
  Write-Output "All unlinked GPOs deleted!"
} else {
  Write-Output "Unlinked GPOs not deleted, review $BackupDir"
}
