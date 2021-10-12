<#
  Orin's PowerShell script to export a GitHub repo's SM files.
#>
<#
  ++ CONFIGURATION ++
#>
$L4D1CFG_PATH = "C:\Program Files (x86)\Steam\steamapps\common\left 4 dead\left4dead\cfg"
$L4D2CFG_PATH = "C:\Program Files (x86)\Steam\steamapps\common\Left 4 Dead 2\left4dead2\cfg"
$REPOCFG_PATH = "D:\Useful Software\Git\Repos\luigi-survival-assets\cfg"
Set-Location $REPOCFG_PATH

$fileFilters = 
@{
    Exts            = @("*.cfg")
    L4D1Blacklist   = @("l4d2")
}

<#
  ++ MAIN ++
#>
Write-Host "STARTING AT FOLDER: '$REPOCFG_PATH'"
$fileResults = (Get-ChildItem $REPOCFG_PATH -Name -Recurse -Include $fileFilters.Exts)
foreach($file in $fileResults)
{
    ### Export - Filtering Items ###
    ################################
    $fileL4D1 = $true

    foreach($entry in $fileFilters.L4D1Blacklist) {
        if( $file.Contains($entry) ) {
            $fileL4D1 = $false
        }
    }

    ### Export - ITS HAPPENING ###
    ##############################
    ## Bandaid to not push l4d2 plugins to l4d1 folders
    Write-Host "Copying '$file' to:"
    if( $fileL4D1 ) {
        Copy-Item $REPOCFG_PATH\$file $L4D1CFG_PATH\$dest
        Write-Host "- $L4D1CFG_PATH\$file"
    }

    Copy-Item $REPOCFG_PATH\$file $L4D2CFG_PATH\$dest
    Write-Host "- $L4D2CFG_PATH\$file"
}
