$INSTALL_PATH="c:\tools"
$PACKAGE_DESCRIPTOR_DIR=".\packages"

function setup_INSTALL_PATH {
    
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
        $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    $INSTALL_PATH=$folder

    write-host "Install root path defined to :"$INSTALL_PATH
}