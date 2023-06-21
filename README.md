# Active-Directory
Just some dirty scripts for cleaning up a messy AD environment
- Remove-EmptyOUs.ps1 will find all empty OUs then delete them
- Remove-UnlinkedGPO.ps1 will find all GPOs that have no link to anything (run after deleting emptyOUs), then delete them

To do 
- Empty groups
- Stale users
