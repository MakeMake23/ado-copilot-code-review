Describe "Update-CopilotComment.ps1" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot ".." "Update-CopilotComment.ps1"
    }

    Context "Updating Comment" {
        BeforeEach {
            Mock Invoke-RestMethod { return @{ value = "updated" } }
            
            $env:AZUREDEVOPS_TOKEN = "test_token"
            $env:AZUREDEVOPS_AUTH_TYPE = "Basic"
            $env:AZUREDEVOPS_COLLECTION_URI = "https://dev.azure.com/test"
            $env:PROJECT = "test_project"
            $env:REPOSITORY = "test_repo"
            $env:PRID = "123"
        }

        It "should call the API to update a comment" {
            & $scriptPath -Content "Updated Review" -ThreadId 456 -CommentId 789
            
            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
        }
    }
}
