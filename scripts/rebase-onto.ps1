#!/usr/bin/env pwsh

# Rebase the current branch onto a target branch using the recorded fork point.
#
# After the base branch of this feature has been squash-merged into main, the two
# branches share no common ancestor. A plain `git rebase origin/main` will try to
# replay every commit since the beginning of time. This script reads the fork point
# SHA that was captured at branch-creation time and runs:
#
#   git rebase --onto origin/<target> <fork-point>
#
# which replays only the commits unique to this branch, correctly landing them on
# top of the new target.
#
# Usage: ./rebase-onto.ps1 [-TargetBranch <branch>]
#
# OPTIONS:
#   -TargetBranch      Branch to rebase onto (default: main)
#   -Help, -h          Show help message

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TargetBranch = 'main',

    [switch]$Help
)

$ErrorActionPreference = 'Stop'

if ($Help) {
    Write-Output @"
Usage: rebase-onto.ps1 [-TargetBranch <branch>]

Rebase the current branch onto a target using the fork point recorded in the spec file.

PARAMETERS:
  -TargetBranch      Branch to rebase onto (default: main)
  -Help, -h          Show this help message

EXAMPLES:
  # Rebase onto main (default)
  .\rebase-onto.ps1

  # Rebase onto develop
  .\rebase-onto.ps1 -TargetBranch develop
"@
    exit 0
}

# Source common functions
. "$PSScriptRoot/common.ps1"

# Resolve spec file via prerequisite check
$prereqOutput = & "$PSScriptRoot/check-prerequisites.ps1" -Json 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Prerequisites check failed. Make sure you are on a task branch with a spec file."
    exit 1
}

$prereqs = $prereqOutput | ConvertFrom-Json
$specFile = $prereqs.SPEC_FILE

# Parse fork point SHA from spec file
$specContent = Get-Content $specFile -Raw
if ($specContent -match '\*\*Fork Point\*\*:\s*`([0-9a-f]{7,40})`') {
    $forkPoint = $Matches[1]
}
else {
    Write-Error "No Fork Point found in spec file: $specFile"
    Write-Error "Add it manually or recreate the branch to have it recorded automatically:"
    Write-Error "  **Fork Point**: ``<SHA>``"
    exit 1
}

Write-Host "Fork Point:    $forkPoint"
Write-Host "Target:        origin/$TargetBranch"
Write-Host ""

# Fetch latest remote state
Write-Host "Fetching origin..."
git fetch origin 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "git fetch origin failed"
}

# Run the rebase
Write-Host "Running: git rebase --onto origin/$TargetBranch $forkPoint"
Write-Host ""
git rebase --onto "origin/$TargetBranch" $forkPoint

if ($LASTEXITCODE -eq 0) {
    $newTip = git rev-parse HEAD 2>$null
    Write-Host ""
    Write-Host "Rebase completed successfully."
    Write-Host "New tip: $newTip"
    exit 0
}

# Rebase stopped with conflicts — auto-resolve UD entries (deleted in HEAD, modified in
# rebased commit). These are spec/feature-branch-only files that do not exist on main.
# Only UD entries are safe to auto-resolve; any other conflict status requires manual action.
Write-Host ""
Write-Host "Rebase stopped with conflicts. Checking for auto-resolvable UD entries..."

$status = git status --porcelain 2>$null
$udFiles = @($status | Where-Object { $_ -match '^UD ' } | ForEach-Object { ($_ -replace '^UD ', '').Trim() })

if ($udFiles.Count -gt 0) {
    Write-Host "Auto-resolving $($udFiles.Count) UD conflict(s) (keeping file from this branch):"
    foreach ($file in $udFiles) {
        Write-Host "  git add $file"
        git add $file 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to stage file: $file"
        }
    }

    Write-Host ""
    Write-Host "Continuing rebase..."
    git rebase --continue

    if ($LASTEXITCODE -eq 0) {
        $newTip = git rev-parse HEAD 2>$null
        Write-Host ""
        Write-Host "Rebase completed successfully."
        Write-Host "New tip: $newTip"
        exit 0
    }
}

# Remaining conflicts require manual resolution
$remaining = @(git status --porcelain 2>$null | Where-Object { $_ -match '^[UAD][UAD] ' })
if ($remaining.Count -gt 0) {
    Write-Host ""
    Write-Host "Unresolved conflicts remain:"
    $remaining | ForEach-Object { Write-Host "  $_" }
}

Write-Host ""
Write-Host "Resolve conflicts manually, then run: git rebase --continue"
Write-Host "Or abort the rebase with:             git rebase --abort"
exit 1
