# HAC_Passwords
These scripts come without warranty of any kind. Use them at your own risk. I assume no liability for the accuracy, correctness, completeness, or usefulness of any information provided by this site nor for any sort of damages using these scripts may cause.

This project is for Arkansas Public Schools to set their students HAC passwords to a predefined password. Unfortunately we couldn't use Powershell to accomplish this task as parts of the student profile page is rendered via Javascript. This project invokes a headless browser and submits the tasks as needed.

This project has been changed from node.js using Puppeteer to Powershell using Selenium. This process now takes about 5:30 to set up 100 students.

ChromeDriver.exe and the Selenium WebDriver.dll are included in this project:
- https://chromedriver.chromium.org/downloads
- https://www.nuget.org/packages/Selenium.WebDriver

We must download Chromium v110 separately as it is too large for github.

### Manual Steps
- https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Win_x64/
- From this site, https://omahaproxy.appspot.com/, we can see that the latest v110 is branch_base_position:1084008
- Searching here: https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Win_x64/ we look for the closest to 1084008 which at the time of this writing is 1084068.
- https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Win_x64/1084068/
- Download chrome-win.zip and extract to bin\chrome-win.zip.

### Autoomatic Method (possible breakage on URL changes.)
````
Invoke-WebRequest -Uri "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win_x64%2F1084068%2Fchrome-win.zip?alt=media" -OutFile "$($env:temp)\chrome-win.zip"
Expand-Archive -Path "$($env:temp)\chrome-win.zip" -DestinationPath .\bin\ -Force
````

This project will use the default CognosModule profile by default. If you wish to use other credentials you can specify the CognosModule profile name with the -CognosConfig parameter.

# Command Line
````
hac_passwords.ps1 [-CognosConfig <String>] [-CSV <String>] [-ForcePasswordChange] [-DisplayProgress]
````

# Errors
Errors will be stored at .\logs\errors.csv so you can parse it and take additional actions afterwards.

# CSV Example
````
Student_id,Student_loginid,Student_password
801001234,Craig.Mil26@cistrict.org,P@ssw0rd
801001235,John.Doe29@cistrict.org,P@ssw0rd2
````

# Pipe in CSV
````
'Student_id,Student_loginid,Student_password
801001234,Craig.Mil26@cistrict.org,P@ssw0rd
801001235,John.Doe29@cistrict.org,P@ssw0rd2' | .\hac_passwords.ps1
````

# Think Bigger!
You would need to use some logic here to only set passwords for students who need it. Don't be setting all students over and over.
````
Invoke-SqlQuery -Query "SELECT Student_id,Student_email AS Student_loginid,Password AS Student_password" | ConvertTo-CSV | .\hac_passwords.ps1
````