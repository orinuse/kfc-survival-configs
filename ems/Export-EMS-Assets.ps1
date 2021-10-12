<#
  Orin's PowerShell script to export a GitHub repo's EMS files.
  Like a Makefile, lol
#>
<#
  ++ CONFIGURATION ++
#>
$L4D2PATH_EMS = "C:\Program Files (x86)\Steam\steamapps\common\Left 4 Dead 2\left4dead2\ems"
$REPOPATH_EMS = "D:\Useful Software\Git\Repos\luigi-survival-assets\ems"
Set-Location $REPOPATH_EMS

$fileFilters =
@{
    Exts            = @("*.nut", "*.txt")
}

<#
  ++ MAIN ++
#>
Write-Host "STARTING AT FOLDER: '$REPOPATH_EMS'"
$fileResults = (Get-ChildItem $REPOPATH_EMS -Name -Recurse -Include $fileFilters.Exts)
foreach($file in $fileResults)
{
    ### Export - ITS HAPPENING ###
    ##############################
    Write-Host "Copying '$file' to: $L4D2PATH_EMS\$file"
    Copy-Item $REPOPATH_EMS\$file $L4D2PATH_EMS\$file
}
