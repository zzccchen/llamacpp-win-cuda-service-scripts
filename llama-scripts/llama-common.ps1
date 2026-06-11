function Get-LlamaProjectRoot {
    param([string]$ScriptsDir = $PSScriptRoot)

    return (Split-Path -Parent $ScriptsDir)
}

function Get-LlamaGitHubToken {
    param([string]$BaseDir)

    $GitHubToken = $env:GITHUB_TOKEN
    if (-not $GitHubToken) {
        $GitHubToken = $env:GH_TOKEN
    }

    $GitHubTokenFile = Join-Path $BaseDir "llama-config\github-token.txt"
    if (-not $GitHubToken -and (Test-Path $GitHubTokenFile)) {
        $GitHubToken = (Get-Content -Path $GitHubTokenFile -Raw).Trim()
    }

    if (-not $GitHubToken) {
        try {
            $GhCommand = Get-Command gh -ErrorAction SilentlyContinue
            if ($GhCommand) {
                $GitHubToken = (& $GhCommand.Source auth token 2>$null).Trim()
            }
        }
        catch {
            $GitHubToken = $null
        }
    }

    return $GitHubToken
}

function New-LlamaGitHubHeaders {
    param(
        [string]$BaseDir,
        [string]$UserAgent
    )

    $Headers = @{
        "User-Agent"           = $UserAgent
        "Accept"               = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    $GitHubToken = Get-LlamaGitHubToken -BaseDir $BaseDir
    if ($GitHubToken -and $GitHubToken -ne "PASTE_YOUR_GITHUB_TOKEN_HERE") {
        $Headers["Authorization"] = "Bearer $GitHubToken"
    }

    return $Headers
}

function Test-LlamaGitHubTokenConfigured {
    param([hashtable]$Headers)

    return $Headers.ContainsKey("Authorization")
}

function Get-LatestWindowsCudaAssetPair {
    param(
        [object[]]$Assets,
        [int]$CudaMajor
    )

    $RuntimeAssetsByCudaVersion = @{}

    foreach ($Asset in $Assets) {
        if ($Asset.name -match "^cudart-llama-bin-win-cuda-(?<CudaVersion>\d+(?:\.\d+)?)-x64\.zip$") {
            $CudaVersion = [version]$Matches.CudaVersion

            if ($CudaVersion.Major -eq $CudaMajor) {
                $RuntimeAssetsByCudaVersion[$CudaVersion.ToString()] = $Asset
            }
        }
    }

    $MainCandidates = foreach ($Asset in $Assets) {
        if ($Asset.name -match "^llama-b(?<Build>\d+)-bin-win-cuda-(?<CudaVersion>\d+(?:\.\d+)?)-x64\.zip$") {
            $CudaVersion = [version]$Matches.CudaVersion

            if ($CudaVersion.Major -eq $CudaMajor -and $RuntimeAssetsByCudaVersion.ContainsKey($CudaVersion.ToString())) {
                [pscustomobject]@{
                    MainAsset        = $Asset
                    CudaRuntimeAsset = $RuntimeAssetsByCudaVersion[$CudaVersion.ToString()]
                    CudaVersion      = $CudaVersion
                    Build            = [int]$Matches.Build
                }
            }
        }
    }

    $Pair = $MainCandidates |
    Sort-Object -Property CudaVersion, Build -Descending |
    Select-Object -First 1

    if ($Pair) {
        return $Pair
    }

    $AvailableCudaAssets = $Assets |
    Where-Object { $_.name -match "win-cuda|cudart-llama-bin-win-cuda" } |
    Select-Object -ExpandProperty name

    throw "Could not find a matching llama Windows x64 CUDA $CudaMajor.x main zip and CUDA runtime zip in latest release. Available CUDA assets: $($AvailableCudaAssets -join ', ')"
}

function Start-LlamaTranscriptWithRotation {
    param(
        [string]$Path,
        [int64]$MaxBytes = 1048576,
        [int]$KeepFiles = 5
    )

    if ((Test-Path $Path) -and ((Get-Item $Path).Length -ge $MaxBytes)) {
        for ($Index = $KeepFiles - 1; $Index -ge 1; $Index--) {
            $Source = "$Path.$Index"
            $Destination = "$Path.$($Index + 1)"

            if (Test-Path $Source) {
                Move-Item -Path $Source -Destination $Destination -Force
            }
        }

        Move-Item -Path $Path -Destination "$Path.1" -Force
    }

    Start-Transcript -Path $Path -Append | Out-Null
}

function Get-LlamaCudaBuildNumber {
    param([string]$Name)

    if ($Name -match "^llama-b(?<Build>\d+)-bin-win-cuda-\d+(?:\.\d+)?-x64(?:\.zip)?$") {
        return [int]$Matches.Build
    }

    return 0
}

function Get-LlamaCudaVersionFromName {
    param([string]$Name)

    if ($Name -match "cuda-(?<CudaVersion>\d+(?:\.\d+)?)-x64") {
        return $Matches.CudaVersion
    }

    return $null
}

function Remove-OldLlamaVersionsAndCache {
    param(
        [string]$BaseDir,
        [string]$DownloadCacheDir,
        [string]$ActiveInstallDir,
        [int]$CudaMajor,
        [int]$KeepVersions
    )

    $VersionDirs = Get-ChildItem -Path $BaseDir -Directory |
    Where-Object { $_.Name -match "^llama-b\d+-bin-win-cuda-$CudaMajor(?:\.\d+)?-x64$" } |
    Sort-Object { Get-LlamaCudaBuildNumber -Name $_.Name } -Descending

    $DirsToRemove = $VersionDirs | Select-Object -Skip $KeepVersions

    foreach ($Dir in $DirsToRemove) {
        if ($Dir.FullName -ne $ActiveInstallDir) {
            Write-Host "Removing old version: $($Dir.FullName)"
            Remove-Item $Dir.FullName -Recurse -Force
        }
    }

    $BuildsToKeep = $VersionDirs |
    Select-Object -First $KeepVersions |
    ForEach-Object { Get-LlamaCudaBuildNumber -Name $_.Name }

    $CudaVersionsToKeep = $VersionDirs |
    Select-Object -First $KeepVersions |
    ForEach-Object { Get-LlamaCudaVersionFromName -Name $_.Name } |
    Where-Object { $_ } |
    Select-Object -Unique

    $CachedZips = Get-ChildItem -Path $DownloadCacheDir -File |
    Where-Object {
        $_.Name -match "^llama-b\d+-bin-win-cuda-$CudaMajor(?:\.\d+)?-x64\.zip$" -or
        $_.Name -match "^cudart-llama-bin-win-cuda-$CudaMajor(?:\.\d+)?-x64\.zip$"
    } |
    Sort-Object {
        if ($_.Name -match "^llama-b\d+-") {
            Get-LlamaCudaBuildNumber -Name $_.Name
        }
        else {
            [int]::MaxValue
        }
    } -Descending

    foreach ($Zip in $CachedZips) {
        $ShouldKeep = $false

        if ($Zip.Name -match "^llama-b\d+-") {
            $ShouldKeep = (Get-LlamaCudaBuildNumber -Name $Zip.Name) -in $BuildsToKeep
        }
        elseif ($Zip.Name -match "^cudart-llama-bin-win-cuda-\d+(?:\.\d+)?-x64\.zip$") {
            $ShouldKeep = (Get-LlamaCudaVersionFromName -Name $Zip.Name) -in $CudaVersionsToKeep
        }

        if (-not $ShouldKeep) {
            Write-Host "Removing old cached zip: $($Zip.FullName)"
            Remove-Item $Zip.FullName -Force
        }
    }
}
