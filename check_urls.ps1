
function GetPageLinks {
    param ($page)

    $links = Select-String -AllMatches -Pattern "[!]\[(?<name>.*)\]\((?<link>.+)\)" -Path $_.FullName | ? { 
        !($_.Matches.Groups[2].Value.StartsWith("http"))
    }
    return $links
}

function GetFullLink {
    param($link, $page)
    $fullLink = Join-Path $page.DirectoryName $link.Split(" ")[0] # separate file part from optional tooltip
    
    # index.md may contain additional directory base name
    if ($page.BaseName -eq "index" -and $page.Directory.BaseName -eq ($link.Split('/')[0])) {
        $fullLink = Join-Path $page.Directory.parent.FullName $link
    }

    # handle paths
    if ($link.StartsWith('/')) {
        Write-Warning "Absolute path not (yet) supported! $($page.FullName) ($($_.LineNumber)): '$($link)'" 
        return
    }

    return $fullLink
}

function CheckLinks {
    param($page)

    GetPageLinks $page | % { 
        $global:checked++
        $link = GetPlainLink $_
        $fullLink = GetFullLink $link $page
        
        # check if target exists
        if (!(Test-Path $fullLink)) { 
			$global:errors++
            Write-Warning "$($page.FullName) ($($_.LineNumber)): link target not found: '$($link)'" 
            #$fullLink
        }        
    }
}

function GetPlainLink {
    param($link)
    $_.Matches.Groups[2].Value.Split(" ")[0] # separate file part from optional tooltip
}

function GetAttachemntName {
    param($link)

    Set-Location $PSScriptRoot
    $path = (Resolve-Path -Relative $link).Replace("\", "__").Substring(3)
    return $path
}

function CloneAttachements {
    param($page)

    GetPageLinks $page | % { 
        $link = GetPlainLink $_
        $fullLink = GetFullLink $link $page
        $attachment = GetAttachemntName $fullLink
    
        Copy-Item -Path $fullLink -Destination (Join-Path $global:attachmentDir $attachment)

        # correct links
        (Get-Content $page.FullName -Encoding UTF8).Replace($link, $(".attachments/" + $attachment)) | Out-File $page.FullName -Encoding utf8
    }
}

$global:checked = 0
$global:errors = 0
$global:attachmentDir = Join-Path $PSScriptRoot "\.attachments"
if (!(Test-Path $global:attachmentDir)) { New-Item -ItemType Directory $global:attachmentDir | Out-Null }

# check consistency (links) of source files
$sourcePages = Get-ChildItem $PSScriptRoot -Filter *.md -Recurse
$sourcePages | % { CheckLinks $_ }
Write-Host "$($global:checked) links checked, $($global:errors) errors found"

