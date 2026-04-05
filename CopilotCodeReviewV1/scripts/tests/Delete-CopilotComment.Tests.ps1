Describe "Delete-CopilotComment.ps1" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot ".." "Delete-CopilotComment.ps1"
    }

    Context "Deleting Comment" {
        BeforeEach {
            Mock Invoke-RestMethod { return @{ value = "deleted" } }
            
            $env:AZUREDEVOPS_TOKEN = "test_token"
            $env:AZUREDEVOPS_AUTH_TYPE = "Basic"
            $env:AZUREDEVOPS_COLLECTION_URI = "https://dev.azure.com/test"
            $env:PROJECT = "test_project"
            $env:REPOSITORY = "test_repo"
            $env:PRID = "123"
        }

        It "should call the API to delete a comment" {
            & $scriptPath -ThreadId 456 -CommentId 789
            
            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
        }
    }
}
