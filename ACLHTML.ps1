#Written by Kailis Lenz 2022
#The below code will generate an access control list for your indicated file shares.
#Prerequisites: Output relies on the module PSWriteHTML by Przemyslaw Klys. (Install-Module PSWriteHTML)
#Prerequisites: You must have rights to your Domain Controller


#Modifiable Variables
$directories = @("") #locations of your file shares (ex. @("\\SERVER\HR", "\\SERVER\Operations\EmployeeInformation"))
$saveFilePath = "" #path your output file will be written to (ex. "C:\AccessControlList.html"))

#Imports custom functions
. .\Common\ActiveDirectory_Common.ps1
. .\Common\ACLPermissions_Common.ps1

#Necessary objects and variables
$GroupMemberCache = [PSCustomObject]@{}
$GroupUserCache = [PSCustomObject]@{}
$ACLTables = [PSCustomObject]@{}
$NETBiosName = (Get-ADDomain).NETBiosName

#Iterates through each directory in $directories and pulls access control lists through custom functions
foreach($directory in $directories){
    Write-Host "Generating $directory access control list..." -ForegroundColor Yellow
    $ACLs = Get-ACLTables $directory -GroupMemberCache $GroupMemberCache -GroupUserCache $GroupUserCache -ACLCache $ACLTables -NETBiosName $NETBiosName
    $ACLTables | Add-Member -NotePropertyName $directory -NotePropertyValue $ACLs
}


#PSWriteHTML formatting for output
New-HTML -TitleText "ACL Tables" -FilePath $saveFilePath {
    New-HTMLTableStyle -FontSize 14

    foreach($directory in $directories){
        New-HTMLSection -HeaderText $directory -HeaderTextSize 14 -CanCollapse {
            New-HTMLTable -DataTable $ACLTables.$directory.PermissionTable -HideFooter {
                New-HTMLTableHeader "Members" -ResponsiveOperations none
            }
            New-HTMLTable -DataTable $ACLTables.$directory.UserTable -HideFooter {
                New-HTMLTableHeader "GroupPermission" -ResponsiveOperations none
            }
        } -Width 30%
    }
} -ShowHTML -Format