# PowerShell Pipeline Pro

Expertise for writing robust, cross-platform PowerShell scripts tailored for Azure DevOps services and agents.

## Core Expertise
- **PowerShell 7 (`pwsh`)**: Focus on performance, cross-platform compatibility (Windows/Linux/macOS), and modern language features.
- **Pester Testing**: High-quality unit and integration testing for pipeline automation scripts.
- **REST API Integration**: Fluent use of `Invoke-RestMethod` with Azure DevOps and GitHub APIs.

## Scripting Standards

### Reliability and Error Handling
- **Action Preference**: Always set `$ErrorActionPreference = 'Stop'` to ensure scripts fail early and predictably.
- **Exit Codes**: Explicitly return non-zero exit codes (`exit 1`) for failures to correctly signal the ADO pipeline agent.
- **Logging**: Use `Write-Host` for regular output and `Write-Error` for terminal errors. Leverage `##vso[task.logissue type=warning;]` for visual highlights in the ADO UI.

### Cross-Platform Best Practices
- **Case Sensitivity**: Be mindful of file systems (Linux is case-sensitive, Windows is not). Use consistent casing for file paths and variables.
- **Path Separation**: Use `[IO.Path]::Combine()` or consistent forward slashes `/` which work on both modern Windows and Linux shells.
- **Encoding**: Default to UTF-8 without BOM for all script files and outputs.

### Azure DevOps Specifics
- **Predefined Variables**: Efficiently use `$env:SYSTEM_ACCESSTOKEN`, `$env:BUILD_SOURCESDIRECTORY`, and `$env:SYSTEM_TEAMPROJECT`.
- **Secret Masking**: Do not log sensitive variables. If a script must output a secret, ensure it's obfuscated or handled via standard secure mechanisms.

## Common Pitfalls to Avoid
- **Implicit Remoting**: Avoid `Enter-PSSession` or legacy remoting; use modern REST APIs or localized execution on agents.
- **Global Scope Overuse**: Keep variables scoped to functions to prevent side effects in long-running agents or shared modules.
