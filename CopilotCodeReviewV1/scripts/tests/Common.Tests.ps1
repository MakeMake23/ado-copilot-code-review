Describe "Common PowerShell Functions" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot ".." "Common.ps1"
        if (-not (Test-Path $scriptPath)) {
            throw "Could not find Common.ps1 at $scriptPath"
        }
        . $scriptPath
    }

    Context "Get-AuthorizationHeader" {
        It "should return a Basic auth header by default" {
            $token = "mytoken"
            $header = Get-AuthorizationHeader -Token $token
            $expected = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":mytoken"))
            $header.Authorization | Should -Be $expected
            $header["Content-Type"] | Should -Be "application/json"
        }
        
        It "should return a Bearer auth header when specified" {
            $token = "mytoken"
            $header = Get-AuthorizationHeader -Token $token -AuthType "Bearer"
            $header.Authorization | Should -Be "Bearer mytoken"
        }
    }
    
    Context "Invoke-AzureDevOpsApi" {
        BeforeEach {
            Mock Invoke-RestMethod { 
                param($Uri, $Headers, $Method)
                return [PSCustomObject]@{ value = "success" } 
            }
        }
        
        It "should call Invoke-RestMethod and return success" {
            $headers = @{ Authorization = "Basic test" }
            $result = Invoke-AzureDevOpsApi -Uri "http://test" -Headers $headers
            $result.value | Should -Be "success"
        }
        
        It "should handle failures when not silent" {
            Mock Invoke-RestMethod { throw "API Error" }
            $result = Invoke-AzureDevOpsApi -Uri "http://test" -Headers @{}
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context "Get-AzureDevOpsRepository" {
        BeforeEach {
            Mock Invoke-AzureDevOpsApi { 
                param($Uri, $Headers, $Method)
                return [PSCustomObject]@{ 
                    value = @(
                        [PSCustomObject]@{ pullRequestId = 123; repository = [PSCustomObject]@{ name = "Repo-123" } },
                        [PSCustomObject]@{ pullRequestId = 456; repository = [PSCustomObject]@{ name = "Repo-456" } }
                    ) 
                } 
            }
        }
        
        It "should return the repository name if provided correctly" {
            $result = Get-AzureDevOpsRepository -Repository "MyRepo" -PrId 123 -CollectionUri "http://test" -Project "Project" -Headers @{}
            $result | Should -Be "MyRepo"
        }
        
        It "should auto-discover repository name if 'undefined' is passed" {
            $result = Get-AzureDevOpsRepository -Repository "undefined" -PrId 456 -CollectionUri "http://test" -Project "Project" -Headers @{}
            $result | Should -Be "Repo-456"
        }
        
        It "should auto-discover repository name if an empty string is passed" {
            $result = Get-AzureDevOpsRepository -Repository "" -PrId 123 -CollectionUri "http://test" -Project "Project" -Headers @{}
            $result | Should -Be "Repo-123"
        }
    }
    
    Context "Format-DateForDisplay" {
        It "should format a valid date string correctly" {
            $date = "2026-04-05T09:00:00Z"
            $result = Format-DateForDisplay -DateString $date
            $result | Should -Match "2026-04-05"
        }
        
        It "should return 'N/A' for null or empty dates" {
            $result = Format-DateForDisplay -DateString $null
            $result | Should -Be "N/A"
        }
    }
}
