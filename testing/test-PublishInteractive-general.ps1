param($testOutputRoot)
# set-psdebug -strict -trace 0

$script:succeeded = $true
# define all test cases here
function TestGetPathToMSDeploy01 {
    try {
        $expectedMsdeployExe = "C:\Program Files\IIS\Microsoft Web Deploy V2\msdeploy.exe"    
        $actualMsdeployExe = GetPathToMSDeploy
        
        $msg = "TestGetPathToMSDeploy01"
        AssertNotNull $actualMsdeployExe $msg
        AssertEqual $expectedMsdeployExe $actualMsdeployExe
        if(!(RaiseAssertions)) {
            $script:succeeded = false
        }
    }
    catch{
        $script:succeeded = $false
    }
}

# ExtractZip test cases
function TestExtractZip-Default {
    try {
        # extract the
        $zipFile = ((Join-Path $testOutputRoot -ChildPath "test-resources\SampleZip.zip" | Get-Item).FullName | Resolve-Path).Path
        $destFolder = (Join-Path $testOutputRoot -ChildPath "psout\SampleZip" | Resolve-Path).Path

        if(Test-Path $destFolder) {
            Remove-Item -Path $destFolder -Recurse
        }
        New-Item -Path $destFolder -type directory
        
        $expectedResults = @("SampleZip",
                             "SampleZip\subfolder01",
                             "SampleZip\subfolder02",
                             "SampleZip\file01.txt",
                             "SampleZip\file02.txt",
                             "SampleZip\subfolder01\file01.txt",
                             "SampleZip\subfolder01\file02.txt",
                             "SampleZip\subfolder02\file01.txt",
                             "SampleZip\subfolder02\file02.txt")
            
        Extract-Zip -zipFilename $zipFile -destination $destFolder
        $extractedItems = Get-ChildItem $destFolder -Recurse
        $actualResults = @()
                
        foreach($item in $extractedItems) {
            $actualResults += $item.FullName.Substring($destFolder.Length + 1)
        }        
        
        AssertNotNull $extractedItems "not-null: extractedItems"
        AssertEqual $expectedResults.Length $actualResults.Length  "$expectedResults.Length $actualResults.Length"
        for($i = 0; $i -lt $expectedResults.Length; $i++) {
            AssertEqual $expectedResults[$i] $actualResults[$i] ("exp-actual loop index {0}" -f $i)
        }
                
        if(!(RaiseAssertions)) { $script:succeeded = $false }
    }
    catch{
        $script:succeeded = $false
        $_.Exception | Write-Error | Out-Null
    }
}

function TestExtractZip-ZipDoesntExist {
    $exceptionThrown = $false
    try {
        $destFolder = (Join-Path $testOutputRoot -ChildPath "psout\SampleZip" | Resolve-Path).Path
        # -Intent $Intention.ShouldFail
        $zipFile = "C:\some\non-existing-path\123454545454545.zip"
        Extract-Zip -zipFilename $zipFile -destination $destFolder
    }
    catch {
        $exceptionThrown = $true
        AssertEqual "System.IO.FileNotFoundException" $_.Exception.GetType().FullName "TestExtractZip-ZipDoesntExist exception type check"
    }
    
    AssertEqual $true $exceptionThrown "$true $exceptionThrown"    
    if(!(RaiseAssertions)) { $script:succeeded = $false }
}

function TestExtractZip-DestDoesntExist {
    $exceptionThrown = $false
    
    try {
        $zipFile = ((Join-Path $testOutputRoot -ChildPath "test-resources\SampleZip.zip" | Get-Item).FullName | Resolve-Path).Path
        $destFolder = "C:\some\non-existing-path\12345454545454577777d454545\"
        Extract-Zip -zipFilename $zipFile -destination $destFolder
    }
    catch {
        $exceptionThrown = $true
        AssertEqual $true $_.Exception.Message.ToLower().Contains("destination not found at") "TestExtractZip-DestDoesntExist: checking exception msg"
    }
    
    AssertEqual $true $exceptionThrown "TestExtractZip-DestDoesntExist: $true $exceptionThrown"    
    if(!(RaiseAssertions)) { $script:succeeded = $false }
}







# GetZipFileForPublishing test cases

$currentDirectory = split-path $MyInvocation.MyCommand.Definition -parent
# Run the initilization script
& (Join-Path -Path $currentDirectory -ChildPath "setup-testing.ps1")

# start running test cases
TestExtractZip-Default
TestExtractZip-ZipDoesntExist
TestExtractZip-DestDoesntExist


# Run the tear-down script
& (Join-Path -Path $currentDirectory -ChildPath "teardown-testing.ps1")
ExitScript -succeeded $script:succeeded -sourceScriptFile $MyInvocation.MyCommand.Definition