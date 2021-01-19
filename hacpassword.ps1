#This is a sample wrapper for node to use your encrypted at rest password.
#eSchool Set HAC Password for students.

#1/18/2021 Craig Millsap

Param(
[parameter(mandatory=$true,Helpmessage="eSchool username")][String]$username, #You're SSO Username
[parameter(Mandatory=$false,HelpMessage="File for ADE SSO Password")][String]$passwordfile="C:\Scripts\apscnpw.txt", #Specify if you need a different path.
[parameter(mandatory=$false,Helpmessage="CSV File Path")][string]$CSV,
[parameter(mandatory=$false,Helpmessage="Student ID")][int]$studentID,
[parameter(mandatory=$false,Helpmessage="Student HAC Password")][string]$hacpassword,
[parameter(mandatory=$false,Helpmessage="Do not require password change")][switch]$DoNotRequirePasswordChange,
[parameter(mandatory=$false,Helpmessage="Set the Login ID to the Email Address in eSchool")][switch]$SetLoginIDasEmail,
[parameter(mandatory=$false,Helpmessage="Set the Login ID to the username from the Email Address in eSchool")][switch]$SetLoginIDasUsername
)

#encrypted password file.
If (Test-Path $passwordfile) {
    $password = (New-Object pscredential "user",(Get-Content $passwordfile | ConvertTo-SecureString)).GetNetworkCredential().Password
}
Else {
    Write-Host("Password file does not exist! [$passwordfile]. Please enter a password to be saved on this computer for scripts") -ForeGroundColor Yellow
    Read-Host "Enter Password" -AsSecureString |  ConvertFrom-SecureString | Out-File $passwordfile
    $password = Get-Content $passwordfile | ConvertTo-SecureString -AsPlainText -Force
}

$nodeArguments = @('hacpassword.js','-username',$username,'-password',"""$password""")

if ($DoNotRequirePasswordChange) {
    $nodeArguments += @('-donotrequirepasswordchange')
}

if ($CSV) {
    if (Test-Path $CSV) {
        $nodeArguments += @("-csv","""$CSV""")
    }
} else {
    $nodeArguments += @('-studentid',$studentID,"-hacpassword","""$hacpassword""")
}

if ($SetLoginIDasEmail) {
    $nodeArguments += @('-setloginidasemail')
} elseif ($SetLoginIDasUsername) {
    $nodeArguments += @('-setloginidasusername')
}

Start-Process -FilePath "node.exe" -ArgumentList $nodeArguments -NoNewWindow -Wait
