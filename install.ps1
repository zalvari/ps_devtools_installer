. $PSScriptRoot\lib\configure.ps1
. $PSScriptRoot\lib\menu.ps1
. $PSScriptRoot\lib\package.ps1

$mainMenuOptions=@{"1"="Choose application to install";
                   "2"="Uninstall application (not implemented)";
                   "3"="Configure"
                   }

function InstallPackageMenu {
    $packageChoose=Show-Menu $availablePackagesMenu "Available Applications"
    if ($packageChoose -ne "q")
    {
        if ($availablePackages.ContainsKey( $packageChoose)){

            $dep = $(check_dependencies $($availablePackages.$packageChoose) $availablePackages) 
            foreach($v in $dep.values){
           
                if ($v.group -ne "bulk"){
                    install_package $v
                }
            }
            if ($($availablePackages.$packageChoose).group -ne "bulk"){
                install_package $($availablePackages.$packageChoose)
            }

            pause
        }else{
            return "option not available"
        }
    }
}

function MainMenu {

do{
$selection = Show-Menu $mainMenuOptions "Dev Team Tools" "exit"
Write-Host $msg
 switch ($selection )
 { 
    '1' {
         $msg = InstallPackageMenu         
         
     } '2' {
         Show-Menu $availablePackagesMenu "Uninstall Application"
     } '3' {
        setup_INSTALL_PATH
     } 'q' {
         return
     }
 }
 }until ($selection -eq 'q')

}


$availablePackages=Load_Packages "$PSScriptRoot\packages"
$availablePackagesMenu=List_Packages $availablePackages 


MainMenu