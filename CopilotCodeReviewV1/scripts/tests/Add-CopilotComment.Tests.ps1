Describe "Add-CopilotComment.ps1" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot ".." "Add-CopilotComment.ps1"
    }

    Context "Adding Copilot Comment" {
        BeforeEach {
            Mock Invoke-RestMethod { 
                param($Uri)
                if ($Uri -match "threads") {
                    return @{ 
                        id = 123; 
                        status = "active"; 
                        comments = @(@{ id = 456; author = @{ displayName = "Test" }; publishedDate = "2026-04-05" })
                    }
                }
                return @{ 
                    pullRequestId = 123;
                    title = "PR Title"; 
                    repository = @{ name = "testrepo" }
                } 
            }
            
            $env:AZUREDEVOPS_TOKEN = "test_token"
            $env:AZUREDEVOPS_AUTH_TYPE = "Basic"
            $env:AZUREDEVOPS_COLLECTION_URI = "https://dev.azure.com/test"
            $env:PROJECT = "test_project"
            $env:REPOSITORY = "test_repo"
            $env:PRID = "123"
        }

        It "should call the API to add a copilot comment" {
            & $scriptPath -Comment "Copilot Review"
            
            Assert-MockCalled Invoke-RestMethod -Times 2 -Exactly
        }
    }
}
