#!/usr/bin/env pwsh

# Create a Bitbucket pull request.
#
# Usage: ./create-pr.ps1 -Title <title> -Description <desc> -TargetBranch <branch> [OPTIONS]
#
# OPTIONS:
#   -Title             PR title (conventional commit format recommended)
#   -Description       PR description (Markdown)
#   -TargetBranch      Destination branch (e.g. main, develop)
#   -SourceBranch      Source branch (default: current git branch)
#   -NoPush            Skip pushing the branch to origin
#   -Json              Output result as JSON
#   -Help, -h          Show help message

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Title,

    [Parameter(Mandatory = $false)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [string]$TargetBranch,

    [Parameter(Mandatory = $false)]
    [string]$SourceBranch,

    [switch]$NoPush,
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

if ($Help) {
    Write-Output @"
Usage: create-pr.ps1 -Title <title> -Description <desc> -TargetBranch <branch> [OPTIONS]

Create a Bitbucket pull request.

PARAMETERS:
  -Title             PR title
  -Description       PR description (Markdown)
  -TargetBranch      Destination branch
  -SourceBranch      Source branch (default: current git branch)
  -NoPush            Skip pushing the branch to origin
  -Json              Output result as JSON
  -Help, -h          Show this help message

CREDENTIAL RESOLUTION (in order):
  1. Environment variables: ATLASSIAN_API_KEY, ATLASSIAN_EMAIL
  2. File: ~/.atlassian
  File format:
    ATLASSIAN_API_KEY=<api_key>
    ATLASSIAN_EMAIL=<email>        (optional — defaults to git config user.email)

EXAMPLES:
  .\create-pr.ps1 -Title "feat: add login page" -Description "..." -TargetBranch main
"@
    exit 0
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Result {
    param([hashtable]$Result)
    if ($Json) {
        $Result | ConvertTo-Json -Compress
    }
    else {
        if ($Result.success) {
            Write-Host ""
            Write-Host "✅ $($Result.message)"
            Write-Host "   $($Result.url)"
            Write-Host ""
        }
        else {
            Write-Host ""
            Write-Host "⚠️  $($Result.message)"
            Write-Host "   $($Result.fallback_url)"
            Write-Host ""
        }
    }
}

# ---------------------------------------------------------------------------
# Validate required parameters
# ---------------------------------------------------------------------------

if (-not $Title) {
    Write-Error "-Title is required."
    exit 1
}
if (-not $TargetBranch) {
    Write-Error "-TargetBranch is required."
    exit 1
}

# Resolve source branch
if (-not $SourceBranch) {
    $SourceBranch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $SourceBranch) {
        Write-Error "Could not determine current branch."
        exit 1
    }
}

# Guard: never create a PR from main/master/develop
if ($SourceBranch -in @('main', 'master', 'develop')) {
    Write-Error "PRs must not originate from '$SourceBranch'. Switch to a working branch first."
    exit 1
}

# ---------------------------------------------------------------------------
# Resolve Bitbucket workspace / repo
# ---------------------------------------------------------------------------

try {
    $repoRef = Get-BitbucketRepo
    $workspace = $repoRef.Workspace
    $repo = $repoRef.Repo
}
catch {
    Write-Error $_
    exit 1
}

# ---------------------------------------------------------------------------
# Push branch
# ---------------------------------------------------------------------------

if (-not $NoPush) {
    Write-Host "Pushing branch '$SourceBranch' to origin..."
    git push origin $SourceBranch 2>&1 | Write-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git push failed. Resolve push errors before retrying."
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Load and validate credentials
# ---------------------------------------------------------------------------

$credential = Get-ApiCredential
$apiKey = $credential.ApiKey
$username = $credential.Username

if (-not $apiKey) {
    Write-Warning "ATLASSIAN_API_KEY not found. Skipping API call."
    $fallback = "https://bitbucket.org/$workspace/$repo/pull-requests/new?source=$SourceBranch&destination=$TargetBranch"
    Write-Result @{
        success      = $false
        message      = "Credentials not found. Set ATLASSIAN_API_KEY env var or create ~/.atlassian with ATLASSIAN_API_KEY=<key>"
        fallback_url = $fallback
    }
    exit 2
}

if (-not $username -or $username -notlike '*@*') {
    Write-Warning "git user.email is not set or invalid: '$username'"
    $fallback = "https://bitbucket.org/$workspace/$repo/pull-requests/new?source=$SourceBranch&destination=$TargetBranch"
    Write-Result @{
        success      = $false
        message      = "Invalid git user.email '$username'. Run: git config user.email you@example.com"
        fallback_url = $fallback
    }
    exit 2
}

# ---------------------------------------------------------------------------
# Call Bitbucket API
# ---------------------------------------------------------------------------

$authHeader = ConvertTo-BasicAuthHeader -Username $username -ApiKey $apiKey
$headers = @{
    Authorization  = $authHeader
    'Content-Type' = 'application/json'
}

try {
    $payload = @{
        title       = $Title
        description = $Description
        source      = @{ branch = @{ name = $SourceBranch } }
        destination = @{ branch = @{ name = $TargetBranch } }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod `
        -Uri "https://api.bitbucket.org/2.0/repositories/$workspace/$repo/pullrequests" `
        -Method POST `
        -Headers $headers `
        -Body $payload

    if (-not $response.id -or -not $response.links.html.href) {
        throw "API returned an unexpected response (missing id or URL)"
    }

    Write-Result @{
        success = $true
        message = "PR #$($response.id) created"
        url     = $response.links.html.href
        pr_id   = $response.id
    }
}
catch {
    # Non-fatal — provide manual fallback
    $errDetail = $_.Exception.Message
    Write-Warning "Bitbucket API call failed: $errDetail"
    Write-Result @{
        success      = $false
        message      = "API creation failed. Create the PR manually."
        fallback_url = "https://bitbucket.org/$workspace/$repo/pull-requests/new?source=$SourceBranch&destination=$TargetBranch"
        error        = $errDetail
    }
    exit 2
}
