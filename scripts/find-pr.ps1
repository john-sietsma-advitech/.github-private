#!/usr/bin/env pwsh

# Find an open Bitbucket pull request for a given branch.
#
# Usage: ./find-pr.ps1 [-SourceBranch <branch>] [-Json]
#
# OPTIONS:
#   -SourceBranch   Branch to search for (default: current git branch)
#   -Json           Output result as JSON
#   -Help           Show this help message
#
# EXIT CODES:
#   0   PR found
#   1   No PR found or error

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SourceBranch,

    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

if ($Help) {
    Write-Output @"
Usage: find-pr.ps1 [-SourceBranch <branch>] [-Json]

Find an open Bitbucket pull request for a given branch.

PARAMETERS:
  -SourceBranch   Branch to search for (default: current git branch)
  -Json           Output result as JSON
  -Help           Show this help message

CREDENTIAL RESOLUTION (in order):
  1. Environment variables: ATLASSIAN_API_KEY, ATLASSIAN_EMAIL
  2. File: ~/.atlassian
  File format:
    ATLASSIAN_API_KEY=<api_key>
    ATLASSIAN_EMAIL=<email>        (optional — defaults to git config user.email)

EXIT CODES:
  0   PR found
  1   No PR found or error

EXAMPLES:
  # Find PR for current branch, human-readable output
  .\find-pr.ps1

  # Find PR for a specific branch, JSON output
  .\find-pr.ps1 -SourceBranch feature/AML-42-my-feature -Json
"@
    exit 0
}

# Resolve source branch
if (-not $SourceBranch) {
    $SourceBranch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $SourceBranch) {
        Write-Error 'Could not determine current branch.'
        exit 1
    }
}

# Resolve workspace/repo
try {
    $repoRef = Get-BitbucketRepo
    $workspace = $repoRef.Workspace
    $repo = $repoRef.Repo
}
catch {
    Write-Error $_
    exit 1
}

# Load credentials
$credential = Get-ApiCredential
$apiKey = $credential.ApiKey
$username = $credential.Username

if (-not $apiKey) {
    Write-Warning 'ATLASSIAN_API_KEY not found. Set the env var or create ~/.atlassian with ATLASSIAN_API_KEY=<key>.'
    exit 1
}

# Query API
$authHeader = ConvertTo-BasicAuthHeader -Username $username -ApiKey $apiKey
$headers = @{ Authorization = $authHeader }

try {
    # Fetch open PRs and filter client-side — avoids server-side q encoding issues with branch names containing slashes
    $uri = "https://api.bitbucket.org/2.0/repositories/$workspace/$repo/pullrequests?state=OPEN&pagelen=50"
    $resp = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET
    $match = $resp.values | Where-Object { $_.source.branch.name -eq $SourceBranch } | Select-Object -First 1

    if ($match) {
        if ($Json) {
            @{
                found = $true
                id    = "$($match.id)"
                title = $match.title
                url   = $match.links.html.href ?? ''
            } | ConvertTo-Json -Compress
        }
        else {
            Write-Host "PR #$($match.id): $($match.title)"
            Write-Host "   $($match.links.html.href)"
        }
        exit 0
    }
    else {
        if ($Json) { '{"found":false}' }
        else { Write-Host "No open PR found for branch '$SourceBranch'." }
        exit 1
    }
}
catch {
    Write-Warning "Bitbucket API error: $($_.Exception.Message)"
    exit 1
}
