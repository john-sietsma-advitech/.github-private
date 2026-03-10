#!/usr/bin/env pwsh
# Common PowerShell functions analogous to common.sh

function Get-RepoRoot {
    try {
        $result = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    }
    catch {
        # Git command failed, fall back to script location
        Write-Verbose "Git not available, using script location"
    }

    # Fall back to script location for non-git repos
    return (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
}

function Get-CurrentBranch {
    # First check if BRANCH_NAME environment variable is set
    if ($env:BRANCH_NAME) {
        return $env:BRANCH_NAME
    }

    # Then check git if available
    try {
        $result = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    }
    catch {
        # Git command failed, fall back to default
        Write-Verbose "Git not available, using default branch name"
    }

    # Final fallback
    return "main"
}

function Test-HasGit {
    try {
        git --version | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

function Test-FeatureBranch {
    param(
        [string]$Branch
    )

    if ($Branch -notmatch '^[a-z]+/[\w\-]+$') {
        Write-Output "ERROR: Not on a task branch. Current branch: $Branch"
        Write-Output "Task branches should be named like: <prefix>/<name> (e.g. feature/my-feature, bugfix/fix-login)"
        return $false
    }
    return $true
}

function Get-SpecFile {
    param([string]$RepoRoot, [string]$Branch)
    # Extract name from branch by stripping the prefix (e.g. feature/VAC-123-desc -> VAC-123-desc)
    $featureName = $Branch -replace '^[^/]+/', ''
    Join-Path $RepoRoot "docs/specs/$featureName.md"
}

function Get-FeaturePathsEnv {
    $repoRoot = Get-RepoRoot
    $currentBranch = Get-CurrentBranch
    $specFile = Get-SpecFile -RepoRoot $repoRoot -Branch $currentBranch

    [PSCustomObject]@{
        REPO_ROOT      = $repoRoot
        CURRENT_BRANCH = $currentBranch
        SPEC_FILE      = $specFile
    }
}

function Test-File {
    param([string]$Path, [string]$Description)
    if (Test-Path -Path $Path -PathType Leaf) {
        Write-Output "  ✓ $Description"
        return $true
    }
    else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

function Test-DirectoryHasFile {
    param([string]$Path, [string]$Description)
    if ((Test-Path -Path $Path -PathType Container) -and (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1)) {
        Write-Output "  ✓ $Description"
        return $true
    }
    else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

# ---------------------------------------------------------------------------
# Bitbucket API helpers
# ---------------------------------------------------------------------------

function Get-BitbucketRepo {
    $remoteUrl = git remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $remoteUrl) {
        throw 'Cannot read remote URL. Run: git remote get-url origin'
    }

    if ($remoteUrl -match 'bitbucket\.org[:/]([^/]+)/([^/]+?)(?:\.git)?$') {
        return @{ Workspace = $Matches[1]; Repo = $Matches[2] }
    }

    throw "Remote URL is not a Bitbucket URL: $remoteUrl"
}

function Get-ApiCredential {
    $apiKey = $env:ATLASSIAN_API_KEY

    # Use a scriptblock to keep the helper private to this function (avoids polluting the dot-sourced namespace)
    $readCredentialFile = {
        param([string]$FilePath)
        if (-not (Test-Path $FilePath)) { return $null }
        $result = @{}
        foreach ($line in (Get-Content $FilePath)) {
            if ($line -match '^ATLASSIAN_API_KEY=(.+)$') { $result.ApiKey = $Matches[1] }
            if ($line -match '^ATLASSIAN_EMAIL=(.+)$') { $result.Email = $Matches[1] }
        }
        return $result
    }

    $homeCredential = & $readCredentialFile (Join-Path $env:USERPROFILE '.atlassian')

    if (-not $apiKey -and $homeCredential) { $apiKey = $homeCredential.ApiKey }

    $email = $env:ATLASSIAN_EMAIL
    if (-not $email -and $homeCredential) { $email = $homeCredential.Email }
    if (-not $email) { $email = git config user.email 2>$null }

    return @{ ApiKey = $apiKey; Username = $email }
}

function ConvertTo-BasicAuthHeader {
    param([string]$Username, [string]$ApiKey)
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${Username}:${ApiKey}"))
    return "Basic $encoded"
}
