# HAC_Passwords

This project is for Arkansas Public Schools to set their students HAC passwords to a predefined password.

Sample command for single student:
````
$ node hacpassword.js -username 0401cmillsap -password [SSOPASSWORD] -studentid 40305966 -hacpassword "NewP@ssw0rd" -donotrequirepasswordchange -setloginidasemail
````

Sample command for processing a CSV:
````
node hacpassword.js -username 0401cmillsap -password [SSOPASSWORD] -csv hac_passwords.csv -donotrequirepasswordchange -setloginidasusername
````

Using the PowerShell Wrapper to use your existing Encrypted Password:
````
.\hacpassword.ps1 -username 0403cmillsap -studentID 403005966 -hacpassword "Testing 123234" -SetLoginIDasEmail -DoNotRequirePasswordChange
.\hacpassword.ps1 -username 0403cmillsap -CSV hac_passwords.csv -SetLoginIDasUsername -DoNotRequirePasswordChange
````

## Command Line arguments:
- `-donotrequirepasswordchange` Check the box do not require password change.
- `-setloginidasemail` Sets the HAC login to the value of the Email Box. This needs to be populated otherwise will error.
- `-setloginidasusername` Sets the HAC login to the value of the Email Box with the domain stripped off. (example JohnDoe@myschool.com would be JohnDoe)

## CSV Example:
````
Student_id,Password
403001234,Sports.1234
403002345,Water!2345
````

## Install needed modules:
* npm i puppeteer
* npm i csv-parser

## Project Goals:
- [x] Lots of Error Control
- [x] Processing a CSV
- [X] Do not require password change
- [x] Set username to email or just username
