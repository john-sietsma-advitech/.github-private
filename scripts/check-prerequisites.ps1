#!/usr/bin/env pwsh

# Consolidated prerequisite checking script (PowerShell)
#
# This script provides unified prerequisite checking for Spec-Driven Development workflow.
# It replaces the functionality previously spread across multiple scripts.
#
# Usage: ./check-prerequisites.ps1 [OPTIONS]
#
# OPTIONS:
#   -Json               Output in JSON format
#   -Help, -h           Show help message

[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
    Write-Output @"
Usage: check-prerequisites.ps1 [OPTIONS]

Consolidated prerequisite checking for Spec-Driven Development workflow.

OPTIONS:
  -Json               Output in JSON format
  -Help, -h           Show this help message

EXAMPLES:
  # Check task prerequisites
  .\check-prerequisites.ps1 -Json
"@
    exit 0
}

# Source common functions
. "$PSScriptRoot/common.ps1"

# Get feature paths and validate branch
$paths = Get-FeaturePathsEnv

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH)) {
    exit 1
}

# Validate required files
if (-not (Test-Path $paths.SPEC_FILE -PathType Leaf)) {
    Write-Output "ERROR: Feature spec file not found: $($paths.SPEC_FILE)"
    Write-Output "Run @dev-flow.task first to create the feature specification."
    exit 1
}

# Output results
if ($Json) {
    # JSON output
    [PSCustomObject]@{
        SPEC_FILE = $paths.SPEC_FILE
    } | ConvertTo-Json -Compress
}
else {
    # Text output
    Write-Output "SPEC_FILE:$($paths.SPEC_FILE)"
}
