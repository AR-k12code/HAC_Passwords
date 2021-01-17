# HAC_Passwords

Sample command for single student:
> node hacpassword.js -username 0401cmillsap -password [THIS SHOULD BE PULLED FROM YOUR ENCRYPTED PASSWORD] -studentid 40305966 -hacpassword "NewP@ssw0rd"

Sample command for processing a CSV:
> node hacpassword.js -username 0401cmillsap -password [THIS SHOULD BE PULLED FROM YOUR ENCRYPTED PASSWORD] -csv hac_passwords.csv

Do not require password change:
> -donotrequirepasswordchange

## CSV Headers
Student_id,Password

## Install needed modules:
* npm i puppeteer
* npm i csv-parser

## Project Goals:
- [ ] Lots of Error Control
- [x] Processing a CSV
- [X] Do not require password change
- [ ] Set username to email or just username
