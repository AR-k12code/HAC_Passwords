#Requires -Modules CognosModule
#Requires -Version 7

<#

    .SYNOPSIS
    This project will automate setting students HAC Login ID and Password.

    .NOTES
    Author: Craig Millsap, CAMTech Computer Services LLC. https://www.camtechcs.com
    Date: 3/4/2023

#>


Param(
    [Parameter(ValueFromPipeline, Mandatory=$false, Position=0)][string]$CSVData,
    [Parameter(Mandatory=$False)][string]$CognosConfig = "DefaultConfig",
    [Parameter(Mandatory=$false)][string]$CSV,
    [Parameter(Mandatory=$false)][Switch]$ForcePasswordChange,
    [Parameter(Mandatory=$false)][Switch]$DisplayProgress
)

Begin {
    $IncomingCSVData = [System.Collections.Generic.List[object]]::New()
}

Process {
    #$IncomingCSVData
    $IncomingCSVData.Add($CSVData)
}

End {

    if (-Not(Test-Path "$PSScriptRoot\logs")) { New-Item -ItemType Directory -Path $PSScriptRoot\logs }
    $logfile = "$PSScriptRoot\logs\$(get-date -f yyyy-MM-dd-HH-mm-ss).log"
    try { while (Stop-Transcript) {} } catch {} #close all other transcripts.
    Start-Transcript -Path $logfile -IncludeInvocationHeader -Force

    @("$PSScriptRoot\bin\chrome-win\chrome.exe","$PSScriptRoot\bin\chromedriver.exe","$PSScriptRoot\bin\WebDriver.dll") | ForEach-Object {

        if (-Not(Test-Path -Path "$PSitem")) {
            Write-Error "Dependency missing: $($PSitem)"
            Throw
        }

    }

    if ($IncomingCSVData) {
        $students = $IncomingCSVData | ConvertFrom-CSV
    } else {
        if (Test-Path "$CSV") {
            $students = Import-Csv -Path "$($CSV)"
        } else {
            Write-Error "Failed to find CSV file $($CSV)"
            exit 1
        }
    }

    if ($students.Count -ge 1) {
        Write-Output "HAC Passwords will be set for $($students.Count) students."
    } else {
        Write-Error "No students specified."
        exit 1
    }

    Write-Verbose ($students | ConvertTo-Json -Depth 99)

    Import-Module "$PSScriptRoot\bin\WebDriver.dll"

    $cognosModuleConfig = Get-Content "$($env:userprofile)\.config\Cognos\$($CognosConfig).json" | ConvertFrom-Json
    $username = $cognosModuleConfig | Select-Object -ExpandProperty Username
    $passwordSecureString = $cognosModuleConfig | Select-Object -ExpandProperty password | ConvertTo-SecureString
    $password = (New-Object PSCredential "user",$passwordSecureString).GetNetworkCredential().Password


    $ChromeOptions = New-Object OpenQA.Selenium.Chrome.ChromeOptions
    $ChromeOptions.BinaryLocation = "$PSScriptRoot\bin\chrome-win\chrome.exe"

    $ChromeOptions.AddExcludedArguments('enable-logging')

    #no extensions, no session history, no notifications that might cause issues, window size is required for javascript rendering of page (even headless)
    $ChromeOptions.AddArguments(@("--disable-extensions","--incognito","--disable-notifications","--disable-popup-blocking","--window-size=1920,1080"))

    $ChromeOptions.AddUserProfilePreference('profile.managed_default_content_settings.images',2)
    
    # This must be deprecated.
    # $ChromeOptions.AddUserProfilePreference('profile.managed_default_content_settings.stylesheets', 2)

    #JavaScript appears to quit working on Headless.
    if (-Not($DisplayProgress)) {
        $ChromeOptions.AddArgument('--headless')
    }

    $ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver($ChromeOptions)

    # Launch a browser and go to URL
    $ChromeDriver.Navigate().GoToURL('https://eschool20.esp.k12.ar.us/eSchoolPLUS20')

    $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("UserName")).SendKeys($username)
    $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("Password")).SendKeys($password)
    $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("login")).Click()

    #Lets grab the server, database, and year here.
    try {

        $eSPServerName = $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("ServerName")).GetAttribute('value')
        $eSPDatabase = $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("EnvironmentConfiguration_Database")).Text
        $eSPSchoolYear = $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("EnvironmentConfiguration_SchoolYear")).GetAttribute('value')

        Write-Output "Server: $($eSPServerName)"
        Write-Output "Database: $($eSPDatabase)"
        Write-Output "School Year: $($eSPSchoolYear)"

        $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("setEnvOkButton")).Click()

    } catch {
        Write-Error "Unable to find eSchool Environment"
        exit 1
    }

    $eSPHACErrors = [System.Collections.Generic.List[Object]]::New()

    #logged in.
    $students | ForEach-Object {

        $StudentID = $psitem.Student_id
        $StudentEmail = $psitem.Student_loginid
        $StudentPassword = $psitem.Student_password

        try {

            $startTime = (Get-Date)
            Write-Output "$($StudentID),$($StudentEmail),$($StudentPassword)"

            $ChromeDriver.Navigate().GoToURL("https://eschool20.esp.k12.ar.us/eSchoolPLUS20/Student/Registration/ContactDetail?studentId=$($StudentID)&ContactPageMode=Address&PageEditMode=Modify&ContactEditMode=Modify")

            try {
                #on the reload page alert this should force the issue to switch to another student.
                $ChromeDriver.SwitchTo().Alert().Accept()
            } catch {}

            #wait for phonegrid to load. Otherwise you can lose the phone numbers. This is why we can't use powershell directly.
            do {
                Start-Sleep -Milliseconds 300
                
                try {
                    if ($ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("gview_phoneGrid"))) { 
                        $phoneGrid = $true
                    }
                } catch {}

                #we can't let it get stuck in here. 10 seconds is plenty.
                if (((Get-Date) - $startTime).Seconds -gt 10) {
                    Throw "Timeout"
                }

            } until ($phoneGrid)

            $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("AddressOrContactDetail_Contact_LoginID")).Clear()

            $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("AddressOrContactDetail_Contact_LoginID")).SendKeys("$($StudentEmail)")
            #this triggers the javascript on the page which forces the issue on the "Change password on Next Login."
            $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("AddressOrContactDetail_Contact_LoginID")).Click()
            #Start-Sleep -Milliseconds 500 #it takes just a few milliseconds for the checkbox to be affected.

            $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("AddressOrContactDetail_PasswordToDisplay")).SendKeys("$($StudentPassword)")

            if ($ForcePasswordChange) {
                if (($ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("AddressOrContactDetail_Contact_MustChangePasswordNextLogin")).GetDomProperty('checked')) -eq $False) {
                    Write-Verbose "Check Must Change Password Box" #twice for some reason.
                    $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("AddressOrContactDetail_Contact_MustChangePasswordNextLogin")).Click()
                    $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("AddressOrContactDetail_Contact_MustChangePasswordNextLogin")).Click()
                } 
            } else {
                if (($ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("AddressOrContactDetail_Contact_MustChangePasswordNextLogin")).GetDomProperty('checked')) -eq $True) {
                    Write-Verbose "Uncheck Must Change Password Box"
                    $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("AddressOrContactDetail_Contact_MustChangePasswordNextLogin")).Click()
                }
            }

            # Read-Host "Press any key to continue..."

            $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("pageOptions-option-save")).Click()

            Start-Sleep -Milliseconds 500 #allows for the popup to show the errors.

            if ($hacErrors = $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("error-list")).Text) {
                $eSPHACErrors.Add(
                    [PSCustomObject]@{
                        Student_id = $StudentID
                        Error = (($hacErrors -join ';') -replace "`r`n",'')
                    }
                )
                return
            }

            Start-Sleep -Milliseconds 500 #we have to give it time to check if the phones are duplicates.

            try {
                try {
                    $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("phonePrioritiesWarning-yes")).Click()
                    Write-Warning "$StudentID has duplicate phone priorities listed."
                    Start-Sleep -Milliseconds 500
                } catch {}

                $ChromeDriver.FindElement([OpenQA.Selenium.By]::Id("saveWarning-yes")).Click()

                Start-Sleep -Milliseconds 200

                #You can not wait for this. The Javascript is too slow, we have already submitted, then the Javascript makes additional changes on the page. This causes it to show as "Unsaved Changes."

                # #The page never refreshes. Wait until the Changes Saved is diplayed.
                # do {
                #     Start-Sleep -Seconds 3
                    
                #     try {
                #         if ($ChromeDriver.FindElement([OpenQA.Selenium.By]::ClassName('alert-success')).Text -eq "Changes Saved") {
                #             $changesSaved = $true
                #         }
                #     } catch {}

                #     #we can't let it get stuck in here. 30 seconds is plenty.
                #     if (((Get-Date) - $startTime).Seconds -gt 30) {
                #         Throw "Timeout"
                #     }
            
                # } until ($changesSaved)

            } catch {
                $eSPHACErrors.Add(
                    [PSCustomObject]@{
                        Student_id = $StudentID
                        Error = (($psitem -join ';') -replace "`r`n",'')
                    }
                )
            }
        } catch {
            $eSPHACErrors.Add(
                    [PSCustomObject]@{
                        Student_id = $StudentID
                        Error = (($psitem -join ';') -replace "`r`n",'')
                    }
                )
        }

    }

    if ($eSPHACErrors) {
        #print to terminal
        $eSPHACErrors | Format-Table
        $eSPHACErrors | Export-Csv -Path "$PSScriptRoot\logs\errors.csv" -Force
    } else {
        Remove-Item -Path "$PSScriptRoot\logs\errors.csv" -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Done Processing Student HAC Passwords."

    $ChromeDriver.Close()
    $ChromeDriver.Dispose()

    Stop-Transcript
}