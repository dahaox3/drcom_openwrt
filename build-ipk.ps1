$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Out = Join-Path $Root "dist"
$Work = Join-Path $Root ".ipk-build"

Remove-Item -Recurse -Force $Out, $Work -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $Out, $Work | Out-Null

function New-TarGz {
    param(
        [string]$SourceDir,
        [string]$OutputFile
    )
    Push-Location $SourceDir
    try {
        tar -czf $OutputFile .
    } finally {
        Pop-Location
    }
}

function New-ArPackage {
    param(
        [string]$PackageDir,
        [string]$OutputFile
    )
    Remove-Item $OutputFile -ErrorAction SilentlyContinue
    $members = @(
        "debian-binary",
        "control.tar.gz",
        "data.tar.gz"
    )

    $fs = [System.IO.File]::Open($OutputFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $writer = New-Object System.IO.BinaryWriter($fs, [System.Text.Encoding]::ASCII, $false)
        try {
            $writer.Write([System.Text.Encoding]::ASCII.GetBytes("!<arch>`n"))
            foreach ($name in $members) {
                $path = Join-Path $PackageDir $name
                $content = [System.IO.File]::ReadAllBytes($path)
                $header = New-Object byte[] 60

                function Set-AsciiField {
                    param(
                        [byte[]]$Buffer,
                        [int]$Offset,
                        [int]$Width,
                        [string]$Value,
                        [switch]$RightAlign
                    )

                    $bytes = [System.Text.Encoding]::ASCII.GetBytes($Value)
                    if ($bytes.Length -gt $Width) {
                        throw "Value '$Value' exceeds ar field width $Width."
                    }
                    $start = if ($RightAlign) { $Width - $bytes.Length } else { 0 }
                    for ($i = 0; $i -lt $Width; $i++) {
                        $Buffer[$Offset + $i] = 0x20
                    }
                    [Array]::Copy($bytes, 0, $Buffer, $Offset + $start, $bytes.Length)
                }

                Set-AsciiField -Buffer $header -Offset 0  -Width 16 -Value $name
                Set-AsciiField -Buffer $header -Offset 16 -Width 12 -Value "0" -RightAlign
                Set-AsciiField -Buffer $header -Offset 28 -Width 6  -Value "0" -RightAlign
                Set-AsciiField -Buffer $header -Offset 34 -Width 6  -Value "0" -RightAlign
                Set-AsciiField -Buffer $header -Offset 40 -Width 8  -Value "100644" -RightAlign
                Set-AsciiField -Buffer $header -Offset 48 -Width 10 -Value "$($content.Length)" -RightAlign
                $header[58] = 0x60
                $header[59] = 0x0A

                $writer.Write($header)
                $writer.Write($content)
                if (($content.Length % 2) -ne 0) {
                    $writer.Write([byte]0x0A)
                }
            }
        } finally {
            $writer.Dispose()
        }
    } finally {
        $fs.Dispose()
    }
}

function Write-AsciiLfFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $normalized = ($Content -replace "`r`n", "`n") -replace "`r", "`n"
    [System.IO.File]::WriteAllText($Path, $normalized, [System.Text.Encoding]::ASCII)
}

function Build-BackendPackage {
    $pkg = "campus-auth-guardian"
    $dir = Join-Path $Work $pkg
    $data = Join-Path $dir "data"
    $control = Join-Path $dir "control"
    New-Item -ItemType Directory -Force -Path $data, $control | Out-Null

    Copy-Item -Recurse "$Root/package/$pkg/files/*" $data
    New-Item -ItemType Directory -Force -Path "$control" | Out-Null
    $controlText = @"
Package: campus-auth-guardian
Version: 1.0.0-1
Architecture: all
Maintainer: Codex
Section: net
Priority: optional
Depends: curl, uclient-fetch
Description: Campus portal authentication daemon and helper scripts.
"@
    Write-AsciiLfFile "$control/control" $controlText

    Write-AsciiLfFile "$dir/debian-binary" "2.0"
    New-TarGz $control "$dir/control.tar.gz"
    New-TarGz $data "$dir/data.tar.gz"
    New-ArPackage $dir "$Out/campus-auth-guardian_1.0.0-1_all.ipk"
}

function Build-LuciPackage {
    $pkg = "luci-app-campus-auth-guardian"
    $dir = Join-Path $Work $pkg
    $data = Join-Path $dir "data"
    $control = Join-Path $dir "control"
    New-Item -ItemType Directory -Force -Path $data, $control | Out-Null

    New-Item -ItemType Directory -Force -Path "$data/www" | Out-Null
    Copy-Item -Recurse "$Root/package/$pkg/htdocs/*" "$data/www"
    Copy-Item -Recurse "$Root/package/$pkg/root/*" $data
    $controlText = @"
Package: luci-app-campus-auth-guardian
Version: 1.0.0-1
Architecture: all
Maintainer: Codex
Section: luci
Priority: optional
Depends: campus-auth-guardian, luci-base
Description: LuCI support for Campus Auth Guardian.
"@
    Write-AsciiLfFile "$control/control" $controlText

    Write-AsciiLfFile "$dir/debian-binary" "2.0"
    New-TarGz $control "$dir/control.tar.gz"
    New-TarGz $data "$dir/data.tar.gz"
    New-ArPackage $dir "$Out/luci-app-campus-auth-guardian_1.0.0-1_all.ipk"
}

Build-BackendPackage
Build-LuciPackage
Write-Host "Built packages in $Out"
