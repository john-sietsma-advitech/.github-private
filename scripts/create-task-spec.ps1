#!/usr/bin/env pwsh

# Shared script for creating task specifications
# Used by both jira-task and ai-task agents
#
# Usage: ./create-task-spec.ps1 -TicketId <id> -Summary <summary> -Description <desc> [OPTIONS]
#
# OPTIONS:
#   -TicketId          Task/ticket identifier (e.g., VAC-123 or auto-generated)
#   -Summary           Brief task summary for branch name
#   -Description       Full task description for spec file
#   -Json              Output in JSON format
#   -Help, -h          Show help message

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TicketId,

    [Parameter(Mandatory = $true)]
    [string]$Summary,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [string]$BaseBranch,

    [Parameter(Mandatory = $false)]
    [string]$BranchPrefix = 'feature',

    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output @"
Usage: create-task-spec.ps1 -TicketId <id> -Summary <summary> -Description <desc> [OPTIONS]

Create a task specification with branch and spec file.

PARAMETERS:
  -TicketId          Task/ticket identifier (e.g., VAC-123)
  -Summary           Brief task summary for branch name
  -Description       Full task description for spec file
  -Json              Output in JSON format
  -Help, -h          Show this help message

EXAMPLES:
  # Create spec for Jira ticket
  .\create-task-spec.ps1 -TicketId "VAC-123" -Summary "Add user authentication" -Description "..."

  # Create spec for AI task
  .\create-task-spec.ps1 -TicketId "TASK-001" -Summary "Implement OAuth2" -Description "..."
"@
    exit 0
}

# Source common functions
. "$PSScriptRoot/common.ps1"

function ConvertTo-BranchSlug {
    param([string]$Text)

    return $Text.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
}

function Get-TaskBranchName {
    param(
        [string]$TicketId,
        [string]$Summary,
        [string]$Prefix = 'feature'
    )

    # Create branch slug from summary
    $slug = ConvertTo-BranchSlug -Text $Summary

    # Format: <prefix>/<TICKET_ID>-<slug>
    $branchName = "$Prefix/$TicketId-$slug"

    # GitHub enforces a 244-byte limit on branch names
    $maxBranchLength = 244
    if ($branchName.Length -gt $maxBranchLength) {
        Write-Warning "Branch name exceeded GitHub's 244-byte limit"
        Write-Warning "Original: $branchName ($($branchName.Length) bytes)"
        $branchName = $branchName.Substring(0, $maxBranchLength)
        Write-Warning "Truncated to: $branchName ($($branchName.Length) bytes)"
    }

    return $branchName
}

function Test-Branch {
    param([string]$BranchName)

    # Fetch remote branches to ensure we have latest information
    Write-Host "Fetching remote branches..."
    git fetch --all --prune 2>&1 | Out-Null

    # Check if branch exists locally or remotely
    git rev-parse --verify "refs/heads/$BranchName" 2>$null | Out-Null
    $localExist = ($LASTEXITCODE -eq 0)
    $remoteExist = git ls-remote --heads origin $BranchName 2>$null

    return ($localExist -or $remoteExist)
}

function New-SpecFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$SpecFilePath,
        [string]$BranchName,
        [string]$TicketId,
        [string]$Summary,
        [string]$Description,
        [string]$BaseBranch,
        [string]$ForkPoint
    )

    $repoRoot = Get-RepoRoot
    $templatePath = Join-Path $repoRoot 'templates/spec-template.md'

    if (-not (Test-Path $templatePath)) {
        throw "Spec template not found: $templatePath"
    }

    # Read template
    $content = Get-Content $templatePath -Raw

    # Replace placeholders
    $date = Get-Date -Format "yyyy-MM-dd"
    $content = $content -replace '\[FEATURE NAME\]', $Summary
    $content = $content -replace '\[###-feature-name\]', $BranchName
    $content = $content -replace '\[DATE\]', $date
    $content = $content -replace '\$ARGUMENTS', $Description
    $content = $content -replace '\[BASE_BRANCH\]', $BaseBranch
    $content = $content -replace '\[FORK_POINT_SHA\]', $ForkPoint

    # Ensure spec directory exists
    $specDir = Split-Path -Parent $SpecFilePath
    if (-not (Test-Path $specDir)) {
        if ($PSCmdlet.ShouldProcess($specDir, "Create directory")) {
            New-Item -ItemType Directory -Path $specDir -Force | Out-Null
        }
    }

    # Write spec file
    if ($PSCmdlet.ShouldProcess($SpecFilePath, "Create spec file")) {
        $content | Set-Content -Path $SpecFilePath -NoNewline
    }

    return $SpecFilePath
}

# Main execution
try {
    $repoRoot = Get-RepoRoot

    # Capture the current branch BEFORE any git operations (fetch, etc.) so the base
    # branch is not affected by anything that runs later in this script.
    if (-not $BaseBranch) {
        $BaseBranch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $BaseBranch) {
            throw "Could not determine the current branch. Make sure you are on the branch you want to branch from before running this script."
        }
    }

    # Generate branch name
    $branchName = Get-TaskBranchName -TicketId $TicketId -Summary $Summary -Prefix $BranchPrefix

    # Generate spec file path — strip whatever prefix was used (everything up to and including the first '/')
    $featureName = $branchName -replace '^[^/]+/', ''
    $specFile = Join-Path $repoRoot "docs/specs/$featureName.md"

    # Check if branch already exists
    if (Test-Branch -BranchName $branchName) {
        Write-Host ""
        Write-Host "⚠️  Branch '$branchName' already exists!"
        Write-Host ""
        Write-Host "Options:"
        Write-Host "  1. Switch to existing branch: git checkout $branchName"
        Write-Host "  2. Choose a different task/ticket"
        Write-Host ""

        if ($Json) {
            [PSCustomObject]@{
                error     = "Branch already exists"
                branch    = $branchName
                spec_file = $specFile
            } | ConvertTo-Json -Compress
        }

        exit 1
    }

    # Create and checkout branch from the captured base branch
    Write-Host "Creating branch: $branchName (from $BaseBranch)"
    git checkout -b $branchName $BaseBranch 2>&1 | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create branch '$branchName' from '$BaseBranch'"
    }

    # Record the fork point — the exact SHA of the base branch tip at the moment this
    # branch was created. This is used later by rebase-onto.ps1 to run
    # `git rebase --onto <target> <fork-point>` after the base branch has been
    # squash-merged and its history no longer shares a common ancestor with this branch.
    $forkPoint = git rev-parse $BaseBranch 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $forkPoint) {
        throw "Could not resolve fork point SHA for branch '$BaseBranch'"
    }

    # Create spec file
    Write-Host "Creating spec file: $specFile"
    New-SpecFile -SpecFilePath $specFile `
        -BranchName $branchName `
        -TicketId $TicketId `
        -Summary $Summary `
        -Description $Description `
        -BaseBranch $BaseBranch `
        -ForkPoint $forkPoint

    Write-Host ""
    Write-Host "✅ Task specification created successfully!"
    Write-Host ""
    Write-Host "Branch:      $branchName"
    Write-Host "Based on:    $BaseBranch"
    Write-Host "Spec:        $specFile"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Review and refine the spec: $specFile"
    Write-Host "  2. Use @dev-flow.clarify to ask clarification questions"
    Write-Host "  3. Start implementing tasks"
    Write-Host ""

    if ($Json) {
        [PSCustomObject]@{
            branch      = $branchName
            base_branch = $BaseBranch
            spec_file   = $specFile
            ticket_id   = $TicketId
        } | ConvertTo-Json -Compress
    }

    exit 0

}
catch {
    Write-Error "Error creating task specification: $_"

    if ($Json) {
        [PSCustomObject]@{
            error = $_.Exception.Message
        } | ConvertTo-Json -Compress
    }

    exit 1
}
