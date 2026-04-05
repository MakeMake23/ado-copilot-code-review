Describe "Get-AzureDevOpsPR.ps1" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot ".." "Get-AzureDevOpsPR.ps1"
    }

    Context "PR Details Fetch" {
        BeforeEach {
            Mock Invoke-RestMethod { 
                param($Uri)
                if ($Uri -match "pullrequests/\d+(\?|$)") {
                    return [PSCustomObject]@{ 
                        pullRequestId = 123;
                        title         = "PR Title"; 
                        description   = "PR Description";
                        status        = "active";
                        repository    = [PSCustomObject]@{ name = "testrepo" };
                        createdBy     = [PSCustomObject]@{ displayName = "Author"; uniqueName = "author@test.com" };
                        creationDate  = "2026-04-05T09:00:00Z"
                    } 
                }
                return [PSCustomObject]@{ 
                    value = @(
                        [PSCustomObject]@{ pullRequestId = 123; repository = [PSCustomObject]@{ name = "testrepo" } }
                    ) 
                }
            }
            $env:AZUREDEVOPS_TOKEN = "test_token"
            $env:AZUREDEVOPS_AUTH_TYPE = "Basic"
            $env:AZUREDEVOPS_COLLECTION_URI = "https://dev.azure.com/test"
            $env:PROJECT = "test_project"
            $env:REPOSITORY = "test_repo"
            $env:PRID = "123"
        }

        It "should fetch PR details and write to file" {
            $testFile = [IO.Path]::GetTempFileName()
            & $scriptPath -Token "token" -CollectionUri "url" -Project "proj" -OutputFile $testFile -Id 123
            
            Test-Path $testFile | Should -Be $true
            $content = Get-Content $testFile -Raw
            $content | Should -Match "PR Title"
            Remove-Item $testFile
        }
    }
}
