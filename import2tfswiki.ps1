$source = "C:\dev\import2tfswiki\source"
$dest = "c:\dev\import2tfswiki\dest"

function CreateOrUpdateOrderFile {
    param($path, $entry)

    $orderFile = Join-Path $path ".order"
    if (!(Test-Path $orderFile)) { New-Item -ItemType File $orderFile | Out-Null }
    if (!((Get-Content $orderFile) -cmatch $entry)) { Add-Content $orderFile $entry }
}

function CheckLinks {
    param($page)

    $links = Select-String -AllMatches -Pattern "[!]\[(?<name>.*)\]\((?<link>.+)\)" -Path $_.FullName | ? { 
        !($_.Matches.Groups[2].Value.StartsWith("http"))
    }
    $links | % { 
        $link = $_.Matches.Groups[2].Value
        $fullLink = Join-Path $page.DirectoryName $link
        if (!(Test-Path $fullLink)) { Write-Warning "Invalid link in $($page.FullName) ($($_.LineNumber)): '$($link)'" }
    }
}

# remove old destination
if (Test-Path $dest) { Remove-Item $dest -Recurse }
New-Item $dest -ItemType Directory | Out-Null

# check consistency (links) of source files
$sourcePages = Get-ChildItem $source -Filter *.md -Recurse
$sourcePages | % { CheckLinks $_ }

# clone .md files with dircetory structure
$sourcePages | % {
    $path = $_.DirectoryName -Replace [Regex]::Escape($source), $dest
    If(!(Test-Path $path)) { New-Item -ItemType Directory -Path $path | Out-Null }
    Copy-Item $_.FullName -Destination $path
}

# create entry pages for empty sub directories
Get-ChildItem $dest -Directory -Recurse | % {
    $entryFile = ($_.FullName + ".md")
    if (!(Test-Path $entryFile)) { New-Item -ItemType File $entryFile | Out-Null }
}

$pages = Get-ChildItem -Filter *.md -Recurse -Path $dest
 # update .order files  
 $pages | % { CreateOrUpdateOrderFile $_.DirectoryName $_.BaseName }

# check links
$pages | % { CheckLinks $_ }

