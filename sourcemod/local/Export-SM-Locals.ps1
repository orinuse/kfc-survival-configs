<#
  Orin's PowerShell script to export a GitHub repo's SM files.
#>
<#
  ++ CONFIGURATION ++
#>
$L4D1SM_PATH = "C:\Program Files (x86)\Steam\steamapps\common\left 4 dead\left4dead\addons\sourcemod"
$L4D2SM_PATH = "C:\Program Files (x86)\Steam\steamapps\common\Left 4 Dead 2\left4dead2\addons\sourcemod"
$REPOSM_PATH = "D:\Useful Software\Git\Repos\luigi-survival-assets\sourcemod\local"
Set-Location $REPOSM_PATH

$fileFilters = 
@{
    Exts            = @("*.cfg", "*.smx"  , "*.sp"     , "*.txt"   )
    Folders         = @("data" , "plugins", "scripting", "gamedata")

    Blacklist       = @("l4d_reservecontrol\data")
    L4D1Blacklist   = @("l4d2", "vscript")
}

<#
  ++ MAIN ++
#>
Write-Host "STARTING AT FOLDER: '$REPOSM_PATH'"
$fileResults = (Get-ChildItem $REPOSM_PATH -Name -Recurse -Include $fileFilters.Exts)
foreach($file in $fileResults)
{
    ## is there a better way to do these :(
    $fileAbandon = $false
    foreach($entry in $fileFilters.Blacklist)
    {
        if( $file.Contains($entry) ) {
            $fileAbandon = $true
            break
        }
    }
    if( $fileAbandon ) { continue }

    ### Setup - Substring Filtering ###
    ###################################
    $fileSplit = $file.Split("\")
    $fileIndex = 0
    while( $fileFilters.Folders.Contains($fileSplit[$fileIndex]) -eq $false ) {
        $fileIndex++
    }

    ### Export - Build a PATH! ###
    ##############################
    $length = $fileSplit.Length - $fileIndex
    $dest = [string]::Join("\", $fileSplit, $fileIndex, $length)
    $fileL4D1 = $true

    foreach($entry in $fileFilters.L4D1Blacklist) {
        if( $dest.Contains($entry) ) {
            $fileL4D1 = $false
        }
    }

    ### Export - ITS HAPPENING ###
    ##############################
    ## Bandaid to not push l4d2 plugins to l4d1 folders
    Write-Host "Copying '$file' to:"
    if( $fileL4D1 ) {
        Copy-Item $REPOSM_PATH\$file $L4D1SM_PATH\$dest
        Write-Host "- $L4D1SM_PATH\$dest"
    }

    Copy-Item $REPOSM_PATH\$file $L4D2SM_PATH\$dest
    Write-Host "- $L4D2SM_PATH\$dest"
}
