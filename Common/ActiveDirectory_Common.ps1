function Get-ADGroupUser ($Identity){

    try{
        try{
            Get-ADGroup $Identity -Properties ManagedBy | select DistinguishedName, SamAccountName, Name, ManagedBy, ObjectClass
        }
        catch{
            Get-ADUser $Identity | select DistinguishedName, SamAccountName, Name, ManagedBy, ObjectClass
        }
    }
    catch{
        "Could not find $Identity"
    }
    #return $returnObject
}

function Get-ADGroupUserCache{
    param(
        [Parameter(Position=0, Mandatory=$true)]
        $SamAccountName,
        [Parameter(Position=1, Mandatory=$true)]
        $Cache
    )

    if($Cache.$SamAccountName){
        #Write-Host "$SamAccountName is in GroupUserCache" -ForegroundColor Yellow
        $returnObject = $Cache.$SamAccountName
    }
    else{
        #Write-Host "$SamAccountName is not in GroupUserCache" -ForegroundColor Red
        try{           
            $objectInfo = Get-ADGroupUser -Identity $SamAccountName
            $Cache | Add-Member -NotePropertyName $SamAccountName -NotePropertyValue $objectInfo
            $returnObject = $objectInfo
        }
        catch{
        }
    }
    #Write-Host $returnObject
    return $returnObject
}
    
    

function Get-ADGroupMemberCache($SamAccountName, $Cache, [Switch]$Recursive){ 

    if($Cache.$SamAccountName){
        #Write-Host "$SamAccountName is in GroupMemberCache" -ForegroundColor Yellow
        $returnObject = $Cache.$SamAccountName
    }

    else{
        $groupMembersParams = @{
            Identity = $SamAccountName
        }     
        if($Recursive){
            $groupMembersParams.Recursive = $true
        }
        try{
            #Write-Host "$SamAccountName is not in GroupMemberCache" -ForegroundColor Red
            $groupMembers = Get-ADGroupMember @groupMembersParams
            if($groupMembers -eq $null){
                $groupMembers = "Empty"
            }
            $Cache | Add-Member -NotePropertyName $SamAccountName -NotePropertyValue $groupMembers
            $returnObject = $groupMembers
        }
        catch{
        }
    }
    
    return $returnObject
}

function Get-ADUserCache{
    param(
        [Parameter(Position=0, Mandatory=$true)]
        $SamAccountName,
        [Parameter(Position=1, Mandatory=$true)]
        [PSCustomObject]$Cache
    )

    if($Cache.$SamAccountName){
        $returnObject = $Cache.$SamAccountName
    }
    else{
        try{
            $userInfo = Get-ADUser $SamAccountName | select SamAccountName, Name
            $Cache | Add-Member -NotePropertyName $SamAccountName -NotePropertyValue $userInfo
            $returnObject = $userInfo
        }
        catch{
            throw "Could not find $SamAccountName"
        }
    }
    return $returnObject
}

function Get-ADGroupCache{
    param(
        [Parameter(Position=0, Mandatory=$true)]
        $SamAccountName,
        [Parameter(Position=1, Mandatory=$true)]
        [PSCustomObject]$Cache
    )

    if($Cache.$SamAccountName){
        #Write-Host "$SamAccountName is in Group Cache" -ForegroundColor Yellow
        $returnObject = $Cache.$SamAccountName
    }
    else{
        try{
            #Write-Host "$SamAccountName is not in Group Cache" -ForegroundColor Red
            $returnObject = Get-ADGroup $SamAccountName -Properties  Description, Info, ManagedBy, Members, MemberOf, GroupCategory
            $Cache | Add-Member -NotePropertyName $SamAccountName -NotePropertyValue $returnObject        
        }
        catch{
            throw "Could not find $SamAccountName"
        }
    }
    return $returnObject
}
    

