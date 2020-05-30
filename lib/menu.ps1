

function Show-Menu
{
    param (
        [Hashtable[]]$options,
        [string]$Title = 'Billing Tools',
        [string]$backTitle = 'back'
        
    )
    #Clear-Host
    Write-Host "================ $Title ================"  

    $options.Keys | Sort-Object | foreach{ 
     
            Write-Host $_": "$($options.$_)

    }

    Write-Host "
q: $backTitle"

    $selection = Read-Host "Select option"
    return $selection
}
