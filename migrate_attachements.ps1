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

    $mdFiles = gci -Path $folder -Include *.md -Recurse

    $mdFiles | % {
        $content = Get-Content $_ -Encoding UTF8
        
        $pattern = "]($($item.Name)"
        $newValue = "]($(GetAttachmentName $file)"

        if ($content -like "*$pattern*") {
            #Write-Host "$pattern --> $newValue"
            Set-Content $_ ($content.Replace($pattern, $newValue)) -Encoding UTF8
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

