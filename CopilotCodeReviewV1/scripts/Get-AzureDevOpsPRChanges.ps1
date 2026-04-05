<#
.SYNOPSIS
    Retrieves commits and changed files from the most recent iteration of a pull request.

.DESCRIPTION
    This script uses the Azure DevOps REST API to get the list of commits and 
    changed files from the most recent iteration (latest push) of a pull request.

.PARAMETER Token
    Required. Authentication token for Azure DevOps. Can be a PAT or OAuth token.

.PARAMETER AuthType
    Optional. The type of authentication to use. Valid values: 'Basic' (for PAT) or 'Bearer' (for OAuth/System.AccessToken).
    Default is 'Basic'.

.PARAMETER CollectionUri
    Required. The Azure DevOps collection URI (e.g., 'https://dev.azure.com/myorg' or 'https://tfs.contoso.com/tfs/DefaultCollection').

.PARAMETER Project
    Required. The Azure DevOps project name.

.PARAMETER Repository
    Required. The repository name where the pull request exists.

.PARAMETER Id
    Required. The pull request ID to retrieve changes for.

.EXAMPLE
    .\Get-AzureDevOpsPRChanges.ps1 -Token "your-pat" -CollectionUri "https://dev.azure.com/myorg" -Project "myproject" -Repository "myrepo" -Id 123
    Retrieves the commits and changed files from the most recent iteration of PR #123.

.EXAMPLE
    .\Get-AzureDevOpsPRChanges.ps1 -Token "oauth-token" -AuthType "Bearer" -CollectionUri "https://dev.azure.com/myorg" -Project "myproject" -Repository "myrepo" -Id 123
    Retrieves PR changes using OAuth/System.AccessToken authentication.

.EXAMPLE
    .\Get-AzureDevOpsPRChanges.ps1 -Token "your-pat" -CollectionUri "https://tfs.contoso.com/tfs/DefaultCollection" -Project "myproject" -Repository "myrepo" -Id 123 -OutputFile "C:\output\pr-changes.txt"
    Writes the pull request changes to the specified file (on-prem example).

.NOTES
    Author: Little Fort Software
    Date: December 2025
    Requires: PowerShell 5.1 or later
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Authentication token for Azure DevOps (PAT or OAuth token)")]
    [ValidateNotNullOrEmpty()]
    [string]$Token,

    [Parameter(Mandatory = $false, HelpMessage = "Authentication type: 'Basic' for PAT, 'Bearer' for OAuth")]
    [ValidateSet("Basic", "Bearer")]
    [string]$AuthType = "Basic",

    [Parameter(Mandatory = $true, HelpMessage = "Azure DevOps collection URI (e.g., https://dev.azure.com/myorg)")]
    [ValidateNotNullOrEmpty()]
    [string]$CollectionUri,

    [Parameter(Mandatory = $true, HelpMessage = "Azure DevOps project name")]
    [ValidateNotNullOrEmpty()]
    [string]$Project,

    [Parameter(Mandatory = $true, HelpMessage = "Repository name")]
    [ValidateNotNullOrEmpty()]
    [string]$Repository,

    [Parameter(Mandatory = $true, HelpMessage = "Pull request ID")]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$Id,

    [Parameter(Mandatory = $false, HelpMessage = "Output file path to write results to")]
    [string]$OutputFile
)

# Dot-source common helper functions
. "$PSScriptRoot\Common.ps1"

#region Local Helper Functions (not in Common.ps1)

function Write-Output-Line {
    param(
        [string]$Message = "",
        [string]$ForegroundColor = "White",
        [switch]$NoNewline
    )
    
    if ($script:OutputToFile) {
        if ($null -eq $script:OutputLines) { $script:OutputLines = @() }
        
        if ($NoNewline) {
            # For NoNewline, we append to the last line if possible
            if ($script:OutputLines.Count -eq 0) {
                $script:OutputLines += $Message
            } else {
                $lastIdx = $script:OutputLines.Count - 1
                $script:OutputLines[$lastIdx] += $Message
            }
        }
        else {
            $script:OutputLines += $Message
        }
    }
    
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $ForegroundColor -NoNewline
    }
    else {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
}

function Get-ChangeTypeDisplay {
    param([string]$ChangeType)
    
    switch ($ChangeType) {
        "add" { return @{ Text = "Added"; Color = "Green" } }
        "edit" { return @{ Text = "Modified"; Color = "Yellow" } }
        "delete" { return @{ Text = "Deleted"; Color = "Red" } }
        "rename" { return @{ Text = "Renamed"; Color = "Cyan" } }
        "copy" { return @{ Text = "Copied"; Color = "Cyan" } }
        default { return @{ Text = $ChangeType; Color = "White" } }
    }
}

#endregion

#region Main Logic

# Initialize output handling
$script:OutputToFile = -not [string]::IsNullOrEmpty($OutputFile)
$script:OutputLines = @()

$headers = Get-AuthorizationHeader -Token $Token -AuthType $AuthType

$Repository = Get-AzureDevOpsRepository -Repository $Repository -CollectionUri $CollectionUri -Project $Project -PrId $Id -Headers $headers
$baseUrl = "$CollectionUri/$Project/_apis/git/repositories/$Repository/pullrequests/$Id"
$apiVersion = "api-version=7.1"

# Verify the PR exists and get details
Write-Host "`nRetrieving Pull Request #$Id from repository '$Repository'..." -ForegroundColor Cyan
$pr = Invoke-AzureDevOpsApi -Uri "$baseUrl`?$apiVersion" -Headers $headers

if ($null -eq $pr) {
    Write-Error "Failed to retrieve pull request #$Id from repository '$Repository'."
    exit 1
}

Write-Host "Found PR: $($pr.title)" -ForegroundColor Green
$prStatusColor = if ($pr.status -eq "active") { "Green" } else { "Yellow" }
Write-Host "Status: $($pr.status.ToUpper())" -ForegroundColor $prStatusColor

# Get iterations
Write-Host "`nRetrieving iterations..." -ForegroundColor Cyan
$iterationsUrl = "$baseUrl/iterations?$apiVersion"
$iterations = Invoke-AzureDevOpsApi -Uri $iterationsUrl -Headers $headers

if ($null -eq $iterations -or $null -eq $iterations.count -or $iterations.count -eq 0) {
    Write-Warning "No iterations found for this pull request."
    exit 0
}

# Sort iterations by ID descending to get the latest
$latestIteration = $iterations.value | Sort-Object -Property id -Descending | Select-Object -First 1
$iterationId = $latestIteration.id

Write-Host "Found $($iterations.count) iteration(s). Using latest: Iteration #$iterationId" -ForegroundColor Green

# Get commits for the PR
Write-Host "`nRetrieving commits..." -ForegroundColor Cyan
$commitsUrl = "$baseUrl/commits?$apiVersion"
$commits = Invoke-AzureDevOpsApi -Uri $commitsUrl -Headers $headers

# Get changes for the latest iteration
Write-Host "Retrieving changes for iteration #$iterationId..." -ForegroundColor Cyan
$iterationChangesUrl = "$baseUrl/iterations/$iterationId/changes?$apiVersion"
$changes = Invoke-AzureDevOpsApi -Uri $iterationChangesUrl -Headers $headers

# --- Output Results ---

Write-Output-Line ("`n" + ("=" * 80)) -ForegroundColor DarkGray
Write-Output-Line "PULL REQUEST CHANGES (Iteration #$iterationId)" -ForegroundColor Green
Write-Output-Line ("=" * 80) -ForegroundColor DarkGray

Write-Output-Line "`n[Pull Request]" -ForegroundColor Yellow
Write-Output-Line "  Title:           $($pr.title)"
Write-Output-Line "  Status:          $($pr.status.ToUpper())" -ForegroundColor $prStatusColor
Write-Output-Line "  Author:          $($pr.createdBy.displayName)"
Write-Output-Line "  Source Branch:   $($pr.sourceRefName -replace '^refs/heads/', '')"
Write-Output-Line "  Target Branch:   $($pr.targetRefName -replace '^refs/heads/', '')"

# Commits
Write-Output-Line "`n[Latest Commits]" -ForegroundColor Yellow
if ($commits -and $commits.value -and $commits.value.Count -gt 0) {
    # Only show top 10 commits
    $commitsToShow = $commits.value | Select-Object -First 10
    foreach ($commit in $commitsToShow) {
        $shortId = $commit.commitId.Substring(0, 8)
        $message = $commit.comment -split "`n" | Select-Object -First 1
        if ($message.Length -gt 60) {
            $message = $message.Substring(0, 57) + "..."
        }
        Write-Output-Line "  $shortId - $message" -ForegroundColor Cyan
        Write-Output-Line "           Author: $($commit.author.name) | $(Format-DateForDisplay $commit.author.date)" -ForegroundColor DarkGray
    }
    
    if ($commits.value.Count -gt 10) {
        Write-Output-Line "  ... and $($commits.value.Count - 10) more commits." -ForegroundColor DarkGray
    }
}
else {
    Write-Output-Line "  No commits found."
}

# Changed Files
Write-Output-Line "`n[Changed Files]" -ForegroundColor Yellow
if ($changes -and $changes.changeEntries -and $changes.changeEntries.Count -gt 0) {
    # Group by change type for summary
    $entries = @($changes.changeEntries)
    $addedCount = ($entries | Where-Object { $_.changeType -eq "add" }).Count
    $modifiedCount = ($entries | Where-Object { $_.changeType -eq "edit" }).Count
    $deletedCount = ($entries | Where-Object { $_.changeType -eq "delete" }).Count
    $renameCount = ($entries | Where-Object { $_.changeType -eq "rename" }).Count
    $otherCount = $entries.Count - $addedCount - $modifiedCount - $deletedCount - $renameCount

    $summaryLine = "  Total files: $($entries.Count) (+$addedCount, ~$modifiedCount, -$deletedCount, R$renameCount"
    if ($otherCount -gt 0) {
        $summaryLine += ", $otherCount other"
    }
    $summaryLine += ")"

    Write-Output-Line $summaryLine
    Write-Output-Line ""
    
    # List each file
    foreach ($change in $changes.changeEntries) {
        $changeDisplay = Get-ChangeTypeDisplay -ChangeType $change.changeType
        $filePath = $change.item.path
        
        Write-Output-Line "  [$($changeDisplay.Text)] $filePath" -ForegroundColor $changeDisplay.Color
        
        # Show original path for renames
        if ($change.changeType -eq "rename" -and $change.originalPath) {
            Write-Output-Line "         (from: $($change.originalPath))" -ForegroundColor DarkGray
        }
    }
}
else {
    Write-Output-Line "  No file changes found in this iteration."
}

Write-Output-Line ("`n" + ("=" * 80)) -ForegroundColor DarkGray

# Provide link to the PR
$webUrl = "$CollectionUri/$Project/_git/$Repository/pullrequest/$Id"
Write-Host "`nView PR: $webUrl" -ForegroundColor Cyan
if ($script:OutputToFile) {
    $script:OutputLines += "`nView PR: $webUrl"
}

# Write to output file if specified
if ($script:OutputToFile) {
    try {
        $outputDir = Split-Path -Parent $OutputFile
        if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        $script:OutputLines | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "`nOutput written to: $OutputFile" -ForegroundColor Green
        
        # Also write the iteration ID to a separate file for use by other scripts
        $iterationIdFile = Join-Path $outputDir "Iteration_Id.txt"
        $iterationId.ToString() | Out-File -FilePath $iterationIdFile -Encoding UTF8 -NoNewline
        Write-Host "Iteration ID written to: $iterationIdFile" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to write output file: $_"
    }
}

#endregion
