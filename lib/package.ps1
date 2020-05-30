. $PSScriptRoot\configure.ps1


function Validate_Package_Descriptor ([Hashtable[]]$properties){
    if ($properties.group -eq "bulk"){
        $packageListKeys = @("group", "name", "version", "dependencies")
    }else{
        $packageListKeys = @("group", "name", "version", "url")

    }
    foreach($key in $packageListKeys){
        if ([string]::IsNullOrEmpty($properties.$key)){
            Write-Warning "Invalid package descriptor. Missing property $key"
            return $false
        }
    }
     
    return $true
}

Function Merge-Hashtables {
    $Output = @{}
    ForEach ($Hashtable in ($Input + $Args)) {
        If ($Hashtable -is [Hashtable]) {
            ForEach ($Key in $Hashtable.Keys) {$Output.$Key = $Hashtable.$Key}
        }
    }
    $Output
}

function check_dependencies([Hashtable[]]$package,[Hashtable[]]$availablePackages){
    $dependencies = @{}
    
    $package.dependencies.split(",") | forEach {
         $pckg_name=$_.split(":")[0]
        $pckg_version=$_.split(":")[1]
        
        foreach($k in $availablePackages.keys){                        
            if ($($availablePackages.$k).name -eq $pckg_name -and $($availablePackages.$k).version -eq $pckg_version){                           
                
                if ( -not [string]::IsNullOrEmpty($($availablePackages.$k).dependencies) ){
                   $child_dep = $(check_dependencies $($availablePackages.$k) $availablePackages)
                   $dependencies=Merge-Hashtables $child_dep  $dependencies
                }
                if (-not $dependencies.ContainsKey($($availablePackages.$k).name+":"+$($availablePackages.$k).version)){
                    $dependencies.add($_,$availablePackages.$k) 
                    write-host "[$(get_package_name $package)] dependency $_ found"
                }
            }
        }
        
        if ( [string]::IsNullOrEmpty($_) ){
                Write-Warning "[$(get_package_name $package)] can't find dependency $_"
                return  @{}
            }         
    }
    
    return $dependencies
}


function get_package_name ([Hashtable[]] $package){
    return  "["+$package.group+"] "+$package.name+ " ("+$package.version+")"
}

function get_package_dir ([Hashtable[]] $package){
    return  "$($package.group)\$($package.name)_$($package.version)"
}


function Load_Packages ([string] $dir) {
    $packages = @{}
    $index=1
    write-host "Looking for package $dir"
    Get-ChildItem -Path $dir | foreach {
        write-host "Loading packages $_"
        
        $packageProperties = (get-content $_.FullName ) | ConvertFrom-StringData         
        $valid=Validate_Package_Descriptor $packageProperties
        
        if ($valid){                  
            $packages.add(""+$index, $packageProperties)
            $index=$index+1   
            write-host "Loaded $(get_package_name $packageProperties)"        
        }else{
            Write-Warning "Please check the package descriptor $_"
        }               
    }  
    if ($packages.count -eq 0 ){
        write-host "Exiting...No packages found in $dir"
        exit
    }
    return $packages
}

function List_Packages ([Hashtable[]]$packages){
    
    $packagesList = @{}    
    $index=1
    
    foreach($key in $packages.keys){
        $packagesList.Add($key,$(get_package_name $packages.$key) )                        
    }                 

    return $packagesList 

}

function set_env_var ([Hashtable[]]$package){
foreach ($key in $package.keys){
    if (([string]$key).startsWith("env_") ){
        $package_dir=get_package_dir $package
        $var_key=$key.replace("env_","") 
        $var_value = ([string]$($package.$key)).replace("`${basedir}","$INSTALL_PATH\$package_dir")
        write-host "[$(get_package_name $package)] Creating env key"$var_key": "$var_value
        if (-not ([string]$key).endsWith("PATH") ){                   
            [System.Environment]::SetEnvironmentVariable($var_key,$var_value,[System.EnvironmentVariableTarget]::User)
        }elseif(([string]$key).endsWith("PATH")){
            $orig_env_path=$([System.Environment]::GetEnvironmentVariable('PATH','user'))
            $orig_env_path=$orig_env_path+";"+$var_value
            [System.Environment]::SetEnvironmentVariable('PATH',$orig_env_path,[System.EnvironmentVariableTarget]::User)
        }
    }
}
}


function install_package ([Hashtable[]]$package){

    New-Item -ItemType Directory -Force -Path $INSTALL_PATH    

    $package_dir=get_package_dir $package

    write-host "[$(get_package_name $package)] Start to install $INSTALL_PATH\$package_dir"

    if (Test-Path $INSTALL_PATH\$package_dir){        
        $deletedir = read-host "[$(get_package_name $package)] The package $package_dir already exists. Do you want to reinstall it? (Y)/N"

        if ($deletedir -eq "N"){
            write-host "[$(get_package_name $package)] Stopping installation"

            return 1
        }else{
            write-host "[$(get_package_name $package)] Removing old installation on $INSTALL_PATH\$package_dir" 
            Remove-Item $INSTALL_PATH\$package_dir -Recurse -Force
            New-Item -ItemType Directory -Force -Path $INSTALL_PATH\$package_dir
        }           
    }

    write-host "[$(get_package_name $package)] Installing on $INSTALL_PATH\$package_dir" 
    write-host "[$(get_package_name $package)] Get file $($package.url) and unzip it into $INSTALL_PATH\$package_dir"
    
    if (unzip_package $($package.url) "$INSTALL_PATH\$package_dir"){
        write-host "[$(get_package_name $package)] Setup Environment"
        if ($(set_env_var $package)){

        }
    }
    

    write-host "[$(get_package_name $package)] Install completed on $INSTALL_PATH\$package_dir" 
}

function unzip_package ([string] $url, [string] $destination){
    if ($url.StartsWith("http")){
        $zipFilename=[System.IO.Path]::GetTempFileName()+".zip"
        Invoke-WebRequest $url -OutFile $zipFilename -PassThru         
    }else{
        $zipFilename = $url
    }    

    if (Test-Path $zipFilename){   
        Expand-Archive $zipFilename "$destination" -Force
    }else{
       write-host "[$(get_package_name $package)] File $zipFilename not found. Aborting..."
       return $false
    }
    return $true
}


