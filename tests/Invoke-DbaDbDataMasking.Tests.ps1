$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandPath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $defaultParamCount = 13
        [object[]]$params = (Get-ChildItem function:\Invoke-DbaDbDataMasking).Parameters.Keys
        $knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'FilePath', 'Locale', 'CharacterString', 'Table', 'Column', 'ExcludeTable', 'ExcludeColumn', 'Query', 'MaxValue', 'EnableException'
        It "Should contain our specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $knownParameters.Count
        }
    }
}

Describe "$CommandName Integration Tests" -Tag "IntegrationTests" {
    BeforeAll {
        $db = "dbatoolsci_masker"
        $sql = "CREATE TABLE [dbo].[people](
                    [fname] [varchar](50) NULL,
                    [lname] [varchar](50) NULL,
                    [dob] [datetime] NULL
                ) ON [PRIMARY]
                GO
                INSERT INTO people (fname, lname, dob) VALUES ('Joe','Schmoe','2/2/2000')
                INSERT INTO people (fname, lname, dob) VALUES ('Jane','Schmee','2/2/1950')"
        New-DbaDatabase -SqlInstance $script:instance1 -Name $db
        Invoke-DbaQuery -SqlInstance $script:instance1 -Database $db -Query $sql
    }
    AfterAll {
        Remove-DbaDatabase -SqlInstance $script:instance1 -Database $db -Confirm:$false
        $file | Remove-Item -Confirm:$false -ErrorAction Ignore
    }

    Context "Command works" {
        It "starts with the right data" {
            Invoke-DbaQuery -SqlInstance $script:instance1 -Database $db -Query "select * from people where fname = 'Joe'" | Should -Not -Be $null
            Invoke-DbaQuery -SqlInstance $script:instance1 -Database $db -Query "select * from people where lname = 'Schmee'" | Should -Not -Be $null
        }
        It "returns the proper output" {
            $file = New-DbaDbMaskingConfig -SqlInstance $script:instance1 -Database $db -Path C:\temp
            $results = $file | Invoke-DbaDbDataMasking -SqlInstance $script:instance1 -Database $db -Confirm:$false
            $results.Count | Should -BeGreaterThan 1
            $results.Database | Should -Contain $db
        }
        It "masks the data and does not delete it" {
            Invoke-DbaQuery -SqlInstance $script:instance1 -Database $db -Query "select * from people" | Should -Not -Be $null
            Invoke-DbaQuery -SqlInstance $script:instance1 -Database $db -Query "select * from people where fname = 'Joe'" | Should -Be $null
            Invoke-DbaQuery -SqlInstance $script:instance1 -Database $db -Query "select * from people where lname = 'Schmee'" | Should -Be $null
        }
    }
}