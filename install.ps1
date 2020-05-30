. $PSScriptRoot\lib\configure.ps1
. $PSScriptRoot\lib\menu.ps1
. $PSScriptRoot\lib\package.ps1

$mainMenuOptions=@{"1"="Install Billing tools package";
                   "2"="Choose application to install";
                   "3"="Uninstall application";
                   "4"="Configure"
                   }

function InstallPackageMenu {
    $packageChoose=Show-Menu $availablePackagesMenu "Available Applications"
    if ($packageChoose -ne "q")
    {
        if ($availablePackages.ContainsKey( $packageChoose)){
            install_package $($availablePackages.$packageChoose)
            pause
        }else{
            return "option not available"
        }
    }
}

function MainMenu {

do{
$selection = Show-Menu $mainMenuOptions "Billing Tools" "exit"
Write-Host $msg
 switch ($selection )
 {
     '1' {
         'You chose option #1'
         pause
     } '2' {
         $msg= InstallPackageMenu         
         
     } '3' {
         Show-Menu $availablePackagesMenu "Uninstall Application"
     } '4' {
        setup_INSTALL_PATH
     } 'q' {
         return
     }
 }
 }until ($selection -eq 'q')

}


$availablePackages=Load_Packages $PACKAGE_DESCRIPTOR_DIR

$availablePackagesMenu=List_Packages $availablePackages  

MainMenu