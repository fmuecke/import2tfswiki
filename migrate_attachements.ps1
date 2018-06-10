$global:attachmentDir = "\.attachments"
$global:attachmentPath = Join-Path $PSScriptRoot $global:attachmentDir

function SetupAttachmentsDir {
    if (!(Test-Path $global:attachmentPath)) { New-Item -ItemType Directory $global:attachmentPath | Out-Null }
}

function GetAttachmentName {
    param($link)

    Set-Location $PSScriptRoot
    $path = (Resolve-Path -Relative $link).Replace("\", "__").Substring(3)
    return (Join-Path $global:attachmentDir -ChildPath $path)
}

function CloneAttachment {
    param($file)

    $newAttachmentPath = Join-Path $PSScriptRoot (GetAttachmentName $file)
    Copy-Item $file -Destination $newAttachmentPath
    #Move-Item $file -Destination $newAttachmentPath
}

function FixAttachementLink {
    param($file)

    $item = gi $file
    $folder = $item.Directory

    $mdFiles = gci -Path $folder -Include *.md -Recurse | ? { return !($_ -is [System.IO.DirectoryInfo]) }

    $mdFiles | % {
        if ($_.Length -gt 0) { # only if filesize > 0
            $content = (Get-Content $_ -Encoding UTF8).Replace("](images/", "](")
            
            $pattern = "]($($item.Name)"
            $newValue = "]($(GetAttachmentName $file)"

            if ($content -like "*$pattern*") {
                #Write-Host "$pattern --> $newValue"
                $newContent = ($content.Replace($pattern, $newValue))
                [System.IO.File]::WriteAllLines($_, $newContent) # writes UTF8 without BOM
            }
        }
    }
    
    $newAttachmentPath = Join-Path $PSScriptRoot (GetAttachmentName $file)
    Copy-Item $file -Destination $newAttachmentPath
    #Move-Item $file -Destination $newAttachmentPath
}


SetupAttachmentsDir

$attachments = Get-ChildItem $PSScriptRoot -Exclude .order,*.md -Recurse | ? { return !($_ -is [System.IO.DirectoryInfo]) }
$attachments | % { 
    CloneAttachment $_ 
    FixAttachementLink $_
}

#Write-Host "$($attachments.Length) files found"

