Describe "Get-AzureDevOpsPRChanges.ps1" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot ".." "Get-AzureDevOpsPRChanges.ps1"
    }

    Context "PR Changes Fetch" {
        BeforeEach {
            Mock Invoke-RestMethod { 
                param($Uri)
                if ($Uri -match "changes") {
                    return [PSCustomObject]@{ 
                        changeEntries = @(
                            [PSCustomObject]@{ changeType = "edit"; item = [PSCustomObject]@{ path = "/file1.txt" } },
                            [PSCustomObject]@{ changeType = "add"; item = [PSCustomObject]@{ path = "/file2.txt" } }
                        ) 
                    } 
                }
                elseif ($Uri -match "iterations") {
                    return [PSCustomObject]@{ 
                        count = 1;
                        value = @([PSCustomObject]@{ id = 1; updatedDate = "2026-04-05T09:00:00Z" })
                    }
                }
                elseif ($Uri -match "commits") {
                    return [PSCustomObject]@{ 
                        value = @(
                            [PSCustomObject]@{ commitId = "0123456789abcdef"; comment = "Test Commit"; author = [PSCustomObject]@{ name = "Author"; date = "2026-04-05T09:00:00Z" } }
                        ) 
                    }
                }
                elseif ($Uri -match "pullrequests/\d+(\?|$)") {
                    return [PSCustomObject]@{ 
                        pullRequestId = 123;
                        title         = "PR Title"; 
                        status        = "active";
                        createdBy     = [PSCustomObject]@{ displayName = "Author" };
                        sourceRefName = "refs/heads/feature";
                        targetRefName = "refs/heads/main"
                    }
                }
                return [PSCustomObject]@{ value = @([PSCustomObject]@{ pullRequestId = 123; repository = [PSCustomObject]@{ name = "testrepo" } }) }
            }
            $env:AZUREDEVOPS_TOKEN = "test_token"
            $env:AZUREDEVOPS_AUTH_TYPE = "Basic"
            $env:AZUREDEVOPS_COLLECTION_URI = "https://dev.azure.com/test"
            $env:PROJECT = "test_project"
            $env:REPOSITORY = "test_repo"
            $env:PRID = "123"
        }

        It "should fetch PR changes and write to file" {
            $testFile = [IO.Path]::GetTempFileName()
            & $scriptPath -Token "token" -CollectionUri "url" -Project "proj" -Repository "repo" -OutputFile $testFile -Id 123
            
            Test-Path $testFile | Should -Be $true
            $content = Get-Content $testFile -Raw
            $content | Should -Match "file1.txt"
            Remove-Item $testFile
        }
    }
}
