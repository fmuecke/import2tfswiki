

function CreateOrUpdateOrderFile {
    param($path, $entry)

    $orderFile = Join-Path $path ".order"
    if (!(Test-Path $orderFile)) { New-Item -ItemType File $orderFile | Out-Null }
    if (!((Get-Content $orderFile) -cmatch $entry)) { Add-Content $orderFile $entry }
}

# create entry pages for empty sub directories
function CreateEntryPages {
    Get-ChildItem $PSScriptRoot -Directory -Recurse | % {
        $entryFile = ($_.FullName + ".md")
        if (!(Test-Path $entryFile)) { New-Item -ItemType File $entryFile | Out-Null }
    }
}

CreateEntryPages

$pages = Get-ChildItem -Filter *.md -Recurse -Path $PSScriptRoot | sort

# update .order files  
$pages | % { CreateOrUpdateOrderFile $_.DirectoryName $_.BaseName }