<#
  Orin's PowerShell script to export a GitHub repo's files.
#>
<#
  ++ CONFIGURATION ++
#>
$L4D1_PATH = "C:\Program Files (x86)\Steam\steamapps\common\left 4 dead\left4dead\addons\sourcemod"
$L4D2_PATH = "C:\Program Files (x86)\Steam\steamapps\common\Left 4 Dead 2\left4dead2\addons\sourcemod"
$REPO_PATH = "D:\Useful Software\Git\Repos\luigi-survival-assets\sourcemod\local"

Set-Location $REPO_PATH
$fileFilters = 
@{
    Exts            = @("*.cfg", "*.smx"  , "*.sp"     , "*.txt"   )
    Folders         = @("data" , "plugins", "scripting", "gamedata")

    L4D1Blacklist   = @("l4d2", "vscript")
}

<#
  ++ MAIN ++
#>
for ($i=0; $i -lt $fileFilters.Length; $i++)
{
    Write-Output "STARTING AT FOLDER: '$REPO_PATH'"
    $fileResults = (Get-ChildItem $REPO_PATH -Name -Recurse -Include $fileFilters.Exts)
    foreach($file in $fileResults)
    {
        # Setup - Substring Filtering
        $fileSplit = $file.Split("\")
        $fileIndex = 0
        while( $fileFilters.Folders.Contains($fileSplit[$fileIndex]) -eq $false )
        {
            $fileIndex++
        }

        # Export - Build a PATH!
        $length = $fileSplit.Length - $fileIndex
        $dest = [string]::Join("\", $fileSplit, $fileIndex, $length)
        $fileL4D1 = $true
        foreach($entry in $fileFilters.L4D1Blacklist)
        { 
            if( $dest.Contains($entry) )
            {
                $fileL4D1 = $false
            }
        }
        
        # Export - ITS HAPPENING
        ## Bandaid to not push l4d2 plugins to l4d1 folders
        Write-Output "Copying '$file' to:"
        if( $fileL4D1 )
        {
            Copy-Item $REPO_PATH\$file $L4D1_PATH\$dest
            Write-Output "- $L4D1_PATH\$dest"
        }

        Copy-Item $REPO_PATH\$file $L4D2_PATH\$dest
        Write-Output "- $L4D2_PATH\$dest"
    }
}