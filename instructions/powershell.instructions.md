---
name: powershell
description: PowerShell scripting standards, PSScriptAnalyzer linting, and best practices
applyTo: "**/*.ps1"
---

# PowerShell Development Instructions

## Technology Stack

- **PowerShell Version**: 7+ (PowerShell Core)
- **Linting**: PSScriptAnalyzer
- **Script Style**: Advanced functions with proper parameter handling

## Code Style & Standards

- Follow PowerShell best practices and style guidelines
- Use approved verbs for function names (Get-, Set-, New-, Remove-, etc.)
- Use singular nouns for function names (e.g., `Test-Branch` not `Test-Branches`)
- Use CmdletBinding for advanced functions
- Provide proper parameter validation
- Include help text with comment-based help or here-strings
- Use `$ErrorActionPreference = 'Stop'` for scripts that should fail fast

## Function Design

- **Verb Selection**: Choose verbs that accurately describe the function's action:
  - `Get-` for retrieving data without side effects
  - `New-` for creating resources (requires ShouldProcess)
  - `Set-` for modifying resources (requires ShouldProcess)
  - `Test-` for validation/checking (returns boolean)
  - `Invoke-` for executing commands
- **ShouldProcess**: Functions using state-changing verbs (New-, Set-, Remove-) **MUST** implement ShouldProcess:

  ```powershell
  function New-SpecFile {
      [CmdletBinding(SupportsShouldProcess)]
      param([string]$Path)

      if ($PSCmdlet.ShouldProcess($Path, "Create spec file")) {
          # Perform state change
          New-Item -Path $Path -ItemType File
      }
  }
  ```

- **Pure Functions**: If a function doesn't change state (e.g., generates strings, calculates values), use appropriate verbs like `Get-` or `ConvertTo-` instead of `New-`

## Linting & Code Quality

- **Linting**: PSScriptAnalyzer with PSGallery settings
- **MUST** run `Invoke-ScriptAnalyzer -Path <script>.ps1 -Settings PSGallery` after generating PowerShell code
- **MUST** resolve all warnings and errors before considering code complete
- **MUST** ensure scripts follow PowerShell best practices:
  - Use approved verbs (Get-Verb to see list)
  - Implement ShouldProcess for state-changing functions
  - Avoid unused variables
  - Use singular nouns in function names
  - Proper error handling with try/catch blocks

## Script Structure

Organize PowerShell scripts in the following order:

```powershell
#!/usr/bin/env pwsh

# Script documentation/help
# Description of what the script does

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$RequiredParam,

    [Parameter()]
    [switch]$OptionalSwitch
)

$ErrorActionPreference = 'Stop'

# 1. Help display (if -Help parameter)
if ($Help) {
    Write-Output @"
Usage: script.ps1 [OPTIONS]
...
"@
    exit 0
}

# 2. Source common functions
. "$PSScriptRoot/common.ps1"

# 3. Function definitions
function Get-Something {
    param([string]$Name)
    # Function body
}

# 4. Main execution
try {
    # Main script logic

} catch {
    Write-Error "Error: $_"
    exit 1
}
```

## Parameter Handling

- Use proper parameter attributes:
  ```powershell
  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$Path
  ```
- Use switch parameters for boolean flags:
  ```powershell
  [switch]$Json
  ```
- Provide parameter help:
  ```powershell
  [Parameter(Mandatory=$true, HelpMessage="Path to the spec file")]
  [string]$SpecFile
  ```

## Error Handling

- Use `$ErrorActionPreference = 'Stop'` to convert non-terminating errors to terminating
- Wrap main logic in try/catch blocks
- Provide meaningful error messages
- Use `Write-Error` for errors, `Write-Warning` for warnings, `Write-Host` for user-facing output
- Return appropriate exit codes (0 for success, non-zero for failure)

## Output

- For user-facing output: Use `Write-Host` or `Write-Output`
- For structured data: Support `-Json` parameter and use `ConvertTo-Json`
- For errors: Use `Write-Error`
- For warnings: Use `Write-Warning`
- For debugging: Use `Write-Verbose` (shown with `-Verbose` parameter)

## Testing

- Test scripts with both valid and invalid inputs
- Test with `-WhatIf` for functions that support ShouldProcess
- Verify JSON output is valid when `-Json` is used
- Check exit codes are correct

## Installation & Dependencies

- **MUST NOT** provide installation instructions for PowerShell (assume 7+ is installed)
- For module dependencies, check and install if needed:
  ```powershell
  if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
      Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
  }
  ```

## Common Patterns

### Sourcing Common Functions

```powershell
. "$PSScriptRoot/common.ps1"
```

### Checking for Git Repository

```powershell
$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Not in a git repository"
    exit 1
}
```

### JSON Output Pattern

```powershell
if ($Json) {
    [PSCustomObject]@{
        property1 = $value1
        property2 = $value2
    } | ConvertTo-Json -Compress
}
```
