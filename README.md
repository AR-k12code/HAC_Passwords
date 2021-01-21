# HAC_Passwords

This project is for Arkansas Public Schools to set their students HAC passwords to a predefined password.  Unfortunately we couldn't use Powershell to accomplish this task as parts of the student profile page is rendered via Javascript. This project invokes a headless browser and submits the tasks as needed. Individually or in bulk using a CSV.

These scripts come without warranty of any kind. Use them at your own risk. I assume no liability for the accuracy, correctness, completeness, or usefulness of any information provided by this site nor for any sort of damages using these scripts may cause.

Sample command for single student:
````
$ node hacpassword.js -username 0401cmillsap -password [SSOPASSWORD] -studentid 40305966 -hacpassword "NewP@ssw0rd" -donotrequirepasswordchange -setloginidasemail
````

Sample command for processing a CSV:
````
node hacpassword.js -username 0401cmillsap -password [SSOPASSWORD] -csv hac_passwords.csv -donotrequirepasswordchange -setloginidasusername
````

## Command Line arguments:
- `-donotrequirepasswordchange` Check the box do not require password change.
- `-setloginidasemail` Sets the HAC login to the value of the Email Box. This needs to be populated otherwise will error.
- `-setloginidasusername` Sets the HAC login to the value of the Email Box with the domain stripped off. (example JohnDoe@myschool.com would be JohnDoe)
- `-displayprogress` Displays the browsers and slows down event times. Default is to run headless.

## CSV Example:
````
Student_id,Password
403001234,Sports.1234
403002345,Water!2345
````

## CSV Error Output:
````
Student_id,Error Details
403001234,"The Password must be at least 8 character(s) in length."
````

## PowerShell Wrapper example your using your existing Encrypted Password:
````
.\hacpassword.ps1 -username 0403cmillsap -studentID 403005966 -hacpassword "Testing 123234" -SetLoginIDasEmail -DoNotRequirePasswordChange
.\hacpassword.ps1 -username 0403cmillsap -CSV hac_passwords.csv -SetLoginIDasUsername -DoNotRequirePasswordChange -DisplayProgress
````

## Requirements
* Node.js `https://nodejs.org/en/download/`

## Install needed modules:
* npm i puppeteer
* npm i csv-parser

## Gotchas
- If your Mailing and Physical contacts for a student have different contact ID numbers then you will need to make sure the LoginID is unique for each of them. Otherwise you run into a duplicate ID error.
- In eSchool under the District HAC Configuration if you leave it where students can change their passwords then your students will be asked their security questions when they first login.

## Project Goals:
- [x] Lots of Error Control
- [x] Processing a CSV
- [X] Do not require password change
- [x] Set username to email or just username
