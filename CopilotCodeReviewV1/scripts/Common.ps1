<#
.SYNOPSIS
    Common helper functions for Azure DevOps PowerShell scripts.

.DESCRIPTION
    This script contains reusable functions for authentication, API invocation,
    and repository discovery to be used across all extension scripts.
#>

function Get-AuthorizationHeader {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Bearer")]
        [string]$AuthType = "Basic"
    )
    
    if ($AuthType -eq "Bearer") {
        return @{
            Authorization  = "Bearer $Token"
            "Content-Type" = "application/json"
        }
    }
    else {
        $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($Token)"))
        return @{
            Authorization  = "Basic $base64Auth"
            "Content-Type" = "application/json"
        }
    }
}

function Invoke-AzureDevOpsApi {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Headers,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Get", "Post", "Patch", "Delete")]
        [string]$Method = "Get",
        
        [Parameter(Mandatory = $false)]
        [object]$Body = $null,
        
        [Parameter(Mandatory = $false)]
        [switch]$SilentOnFailure
    )
    
    try {
        $params = @{
            Uri         = $Uri
            Headers     = $Headers
            Method      = $Method
            ErrorAction = "Stop"
        }
        
        if ($null -ne $Body) {
            $params.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 10 -Compress }
        }
        
        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        if ($SilentOnFailure) { return $null }
        
        $statusCode = $null
        $errorDetail = $null

        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $errorDetail = $_.ErrorDetails.Message
        }

        # Build a descriptive error message
        $baseMsg = "Azure DevOps API error"
        if ($statusCode) {
            $baseMsg += " (HTTP $statusCode)"
        }
        $baseMsg += " calling $Method $Uri"

        if ($statusCode -eq 401) {
            Write-Error "$baseMsg — Authentication failed. Verify token permissions. API response: $errorDetail"
        }
        elseif ($statusCode -eq 404) {
            Write-Error "$baseMsg — Resource not found. Verify organization, project, repository, or PR ID. API response: $errorDetail"
        }
        elseif ($statusCode) {
            Write-Error "$baseMsg — API response: $errorDetail"
        }
        else {
            Write-Error "$baseMsg — $($_.Exception.Message)"
        }
        return $null
    }
}

function Get-AzureDevOpsRepository {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionUri,
        
        [Parameter(Mandatory = $true)]
        [string]$Project,
        
        [Parameter(Mandatory = $true)]
        [int]$PrId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Headers
    )
    
    # If repository is not specified or is "undefined", we need to find it first
    if ([string]::IsNullOrWhiteSpace($Repository) -or $Repository -eq "undefined") {
        Write-Host "Repository not specified for PR #$PrId. Attempting to auto-discover..." -ForegroundColor Cyan
        
        # Search for the PR across all repositories in the project
        $searchUrl = "$CollectionUri/$Project/_apis/git/pullrequests?searchCriteria.status=all&api-version=7.1"
        
        try {
            $response = Invoke-AzureDevOpsApi -Uri $searchUrl -Headers $Headers -Method Get -ErrorAction Stop -SilentOnFailure
            if ($null -eq $response -or $null -eq $response.value) {
                Write-Error "Pull Request #$PrId not found in project '$Project'. Cannot auto-discover repository."
                exit 1
            }
            
            $targetPR = $response.value | Where-Object { $_.pullRequestId -eq $PrId } | Select-Object -First 1
            
            if ($null -eq $targetPR) {
                Write-Error "Pull Request #$PrId not found in project '$Project'. Cannot auto-discover repository."
                exit 1
            }
            
            $Repository = $targetPR.repository.name
            Write-Host "Auto-discovered repository: $Repository" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to auto-discover repository for Pull Request #$($PrId): $($_.Exception.Message)"
            exit 1
        }
    }
    
    return $Repository
}

function Format-DateForDisplay {
    param([string]$DateString)
    
    if ([string]::IsNullOrEmpty($DateString)) {
        return "N/A"
    }
    
    try {
        $date = [DateTime]::Parse($DateString)
        return $date.ToString("yyyy-MM-dd HH:mm:ss")
    }
    catch {
        return $DateString
    }
}
