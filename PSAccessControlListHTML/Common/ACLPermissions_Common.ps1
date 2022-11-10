function Get-ACLTables($Path, $GroupMemberCache, $GroupUserCache, $ACLCache, $NETBiosName){
    $ACLTables = [PSCustomObject]@{}
    $totalUsers = @()

    $permissionList = (Get-Acl $Path).Access | select IdentityReference, FileSystemRights, IsInherited, ManagedBy, Members, ObjectClass | Sort-Object IdentityReference
    $originalPermissions = $permissionList | select IdentityReference, FileSystemRights, IsInherited

    $parentPath = Split-Path $Path -Parent

    if($ACLCache.$parentPath){
        $fullPermissionInherit = (Compare-Object $ACLCache.$parentPath.OriginalPermissions -DifferenceObject $originalPermissions)
        if(!($fullPermissionInherit)){
           $fullPermissionInherit = $true
        }
        
    }
    
    if($fullPermissionInherit -eq $true){
        $permissionList = $ACLCache.$parentPath.PermissionTable
        $userTable = $ACLCache.$parentPath.UserTable
    }
    else{

    $NETBiosName = $NETBiosName + "\"

    $i = 0
        
        foreach($permission in $permissionList){
            
            $permission.IdentityReference = (($permission.IdentityReference).ToString()).Replace("$NETBiosName","")
            $permission.FileSystemRights  = (($permission.FileSystemRights).ToString()).Replace(", Synchronize", "")

            if(($permission.IdentityReference -ne "Domain Users") -and ($permission.IdentityReference -ne "Everyone")){
                $permissionADInfo = Get-ADGroupUserCache -SamAccountName $permission.IdentityReference -Cache $GroupUserCache
            }

            $permissionMembers = [PSCustomObject]@{}

            if($permissionADInfo.ObjectClass -eq "User"){
                $permissionMembers = $permissionADInfo | select SamAccountName, Name
                $permission.Members = "`r`n" + $permissionMembers.Name
                $permission.ObjectClass = "User"
                $permissionInheritance = "Direct"
            }
            elseif($permissionADInfo.ObjectClass-eq "Group"){
                $permissionMembers = (Get-ADGroupMemberCache -SamAccountName $permission.IdentityReference -Cache $GroupMemberCache -Recursive) | select SamAccountName, Name
                $permission.Members = "`r`n" + (($permissionMembers.Name | Sort-Object) -join "`r`n")
                $permission.ObjectClass = "Group"
                $permissionInheritance = $permissionADInfo.SamAccountName
                if($permissionADInfo.ManagedBy -ne $null){
                    $permission.ManagedBy = (Get-ADGroupUserCache $permissionADInfo.ManagedBy -Cache $GroupUserCache).Name
                }
            } 

            $permissionMembers | Add-Member -NotePropertyName AccessRightsValue -NotePropertyValue (AssignAccessValue $permission.FileSystemRights)
            $permissionMembers | Add-Member -NotePropertyName HighestRights -NotePropertyValue $permission.FileSystemRights
            $permissionMembers | Add-Member -NotePropertyName PermissionInheritance -NotePropertyValue $permissionInheritance
            $totalUsers += $permissionMembers | Where-Object {$_.SamAccountName -ne $null}

            $permissionList[$i] = $permission

            $i++
        }
    
        $userTable = $totalUsers | Group-Object "SamAccountName", "AccessRightsValue" | %{ $_.Group | Select -First 1} | Sort-Object SamAccountName
        $userTable = $userTable | Group-Object "SamAccountName" | %{$_.Group | Sort-Object AccessRightsValue | select -First 1} | Select * -ExcludeProperty AccessRightsValue
        }

        $ACLTables | Add-Member -NotePropertyName "PermissionTable" -NotePropertyValue $permissionList
        $ACLTables | Add-Member -NotePropertyName "UserTable" -NotePropertyValue $userTable
        $ACLTables | Add-Member -NotePropertyName "OriginalPermissions" -NotePropertyValue $originalPermissions

        return $ACLTables
}

function AssignAccessValue($passthruObject){

    if($passthruObject -eq "FullControl"){
        1
    }
    elseif($passthruObject -eq "Modify"){
        2
    }
    elseif($passthruObject -eq "ReadAndExecute"){
        3
    }
    elseif($passthruObject -eq "Read"){
        4
    }
    elseif($passthruObject -eq "ListFolderContents"){
        5
    }
    else{
        6
    }
}

<#$directory = "\\gcsnas01\dept\Third Party\3rd Party Reporting (Compliance)\Top Errors (Weekly)"
$GroupMemberCache = [PSCustomObject]@{}
$GroupUserCache = [PSCustomObject]@{}
$test = Get-ACLTables -Path $directory -GroupMemberCache $GroupMemberCache -GroupUserCache $GroupUserCache#>