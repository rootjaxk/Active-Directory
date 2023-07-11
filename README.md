# Active-Directory
Just some dirty scripts for cleaning up a messy AD environment
- Remove-EmptyOUs.ps1 will find all empty OUs then delete them
- Remove-UnlinkedGPO.ps1 will find all GPOs that have no link to anything (run after deleting emptyOUs), then delete them
- Remove-EmptyGroups.ps1 will find all empty groups then delete them
- Remove-InactiveUsers will find all users that have not logged in past 90 days then disable / delete them
- Remove-InactiveComputer will do the same as above but for computer objects

To do 
- Can run threaded with PowerShell v7.0 - Parallel
