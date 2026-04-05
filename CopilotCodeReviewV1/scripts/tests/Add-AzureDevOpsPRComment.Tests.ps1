Describe "Add-AzureDevOpsPRComment.ps1" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot ".." "Add-AzureDevOpsPRComment.ps1"
        $commonPath = Join-Path $PSScriptRoot ".." "Common.ps1"
    }

    Context "Commenting Logic" {
        BeforeEach {
            Mock Invoke-RestMethod { 
                param($Uri)
                if ($Uri -match "threads") {
                    return @{ 
                        id       = 123; 
                        status   = "active"; 
                        comments = @(@{ id = 456; author = @{ displayName = "Test" }; publishedDate = "2026-04-05" })
                    }
                }
                return @{ 
                    pullRequestId = 123;
                    title         = "PR Title"; 
                    repository    = @{ name = "testrepo" }
                } 
            }
            Mock Get-Date { return [DateTime]"2026-04-05" }
            
            # Mock environment variables
            $env:AZUREDEVOPS_TOKEN = "test_token"
            $env:AZUREDEVOPS_AUTH_TYPE = "Basic"
            $env:AZUREDEVOPS_COLLECTION_URI = "https://dev.azure.com/test"
            $env:PROJECT = "test_project"
            $env:REPOSITORY = "test_repo"
            $env:PRID = "123"
        }

        It "should call the API to add a comment" {
            # Run script with parameters
            & $scriptPath -Comment "Test Comment" -Token "token" -AuthType "Basic" -CollectionUri "url" -Project "proj" -Repository "repo" -Id 123
            
            Assert-MockCalled Invoke-RestMethod -Times 2 -Exactly # One for PR verification, one for comment
        }
    }
}
