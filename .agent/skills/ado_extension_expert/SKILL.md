# Azure DevOps Extension Expert

Professional guidance for building, packaging, and maintaining high-quality Azure DevOps extensions.

## Core Expertise
- **10+ Years Experience**: Senior-level architectural decisions and patterns.
- **Manifest Management**: Expert handling of `vss-extension.json` and `task.json`.
- **Pipeline Integration**: Deep understanding of how extensions interact with agent environments (Windows, Linux, macOS).

## Extension Principles

### Security and Authentication
- **System Access Token**: Prefer using `System.AccessToken` via `useSystemAccessToken` inputs where possible. Ensure instructions for granting "Contribute to pull requests" permissions are clear to users.
- **Personal Access Tokens (PAT)**: Guide users on minimum required scopes (Code-Read, Pull Request Threads-Read/Write) to maintain the principle of least privilege.

### Reliability and Versioning
- **Semantic Versioning**: Strictly follow SemVer for extension releases to avoid breaking downstream consumers.
- **Task Versioning**: Use major version pinning in YAML (`SomeTask@2`) while allowing minor/patch updates to flow through.

### User Experience (UX)
- **Informative Logging**: Always use `##vso[task.debug]` for diagnostic information and `##vso[task.logissue type=error]` for user-facing failures.
- **Clear Inputs**: Define intuitive input names and provide sensible defaults in `task.json`.

## Common Pitfalls to Avoid
- **Hardcoded Paths**: Never assume a specific directory structure on the agent. Use predefined variables like `$(Agent.WorkFolder)` or `$(Build.SourcesDirectory)`.
- **Environment Variables**: Be aware that sensitive environment variables are masked in logs but should still be handled securely in scripts.
