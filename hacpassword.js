const puppeteer = require('puppeteer');
//const dotenv = require('dotenv').config(); //Removed since we should call this from our PowerShell script using our encrypted password now.
const csv = require('csv-parser');
const fs = require('fs');

// Expected command line should be in the following formats:
// node hacpassword.js -username 0401cmillsap -password [THIS SHOULD BE PULLED FROM YOUR ENCRYPTED PASSWORD] -studentid 40305966 -hacpassword "NewP@ssw0rd"
// node hacpassword.js -username 0401cmillsap -password [THIS SHOULD BE PULLED FROM YOUR ENCRYPTED PASSWORD] -csv hac_passwords.csv

//We should validate that this matches the incoming Student ID. Trim and convert to int.
//document.getElementById("StudentId").value 

if (process.argv.indexOf('-username') === -1) {
  console.log("-username is a required parameter"); process.exit(1)
} else {
  var username = process.argv[process.argv.indexOf('-username') + 1]
}

if (process.argv.indexOf('-password') === -1) {
  console.log("-password is a required parameter"); process.exit(1)
} else {
  var password = process.argv[process.argv.indexOf('-password') + 1]
}

//if csv is not specified then we use the supplied -studentid and -hacpassword.
if (process.argv.indexOf('-csv') === -1) {
  if (process.argv.indexOf('-studentid') === -1) {
    console.log("-studentid is a required parameter"); process.exit(1)
  } else {
    var StudentID = process.argv[process.argv.indexOf('-studentid') + 1]
  }

  if (process.argv.indexOf('-hacpassword') === -1) {
    console.log("-hacpassword is a required parameter"); process.exit(1)
  } else {
    var HACPassword = process.argv[process.argv.indexOf('-hacpassword') + 1]
  }

} else {
  var csvPath = process.argv[process.argv.indexOf('-csv') + 1]
  var studentsCSV = [];
}

if (process.argv.indexOf('-donotrequirepasswordchange') > 0) {
  var passwordChangeNotRequired = true
}

if (process.argv.indexOf('-setloginidasemail') > 0) {
  var loginIDAsEmail = true
}

if (process.argv.indexOf('-setloginidasusername') > 0) {
  var loginIDAsUsername = true
}


// eSchool login
(async () => {
  const browser = await puppeteer.launch({
    //uncomment to troubleshoot
    headless: false,
    //slowMo: 250
  });
  
  const page = await browser.newPage();

  await page.setViewport({
    width: 1366,
    height: 768,
    deviceScaleFactor: 1,
  });

  await page.setRequestInterception(true);
  
  //Don't waste resources on proceessing CSS,Fonts, or Images. Continue with JavaScript.
  page.on('request', (req) => {
      if(req.resourceType() == 'stylesheet' || req.resourceType() == 'font' || req.resourceType() == 'image'){
          req.abort();
      }
      else {
          req.continue();
      }
  });

  try {
    await page.goto('https://eschool20.esp.k12.ar.us/eSchoolPLUS20/Account/LogOn?ReturnUrl=%2feSchoolPLUS20');
    
    await page.type('#UserName', username);
    await page.type('#Password', password);
    await page.click('#login');
    await page.waitForNavigation({
      waitUntil: 'networkidle0',
    });
    
    // debugger;
    await page.click('#setEnvOkButton');

    // this doesn't always work.
    //   await page.waitForNavigation({
    //     waitUntil: 'networkidle0',
    //   });
      
    //We don't need the page to actually load so just navigate straight to the student after wait.
    await page.waitForTimeout(1000);
    
    // if csvPath is undefined then process the single student.
    if (csvPath === undefined) {

      console.log('Setting student',StudentID,'with password of',HACPassword);
      //Go to student.
      //await page.setDefaultNavigationTimeout(0); //this takes awhile
      await page.goto('https://eschool20.esp.k12.ar.us/eSchoolPLUS20/Student/Registration/ContactDetail?studentId=' + StudentID + '&ContactPageMode=Address&PageEditMode=Modify&ContactEditMode=Modify')

      //Must be typed into the box. Setting the value doesn't work.
      await page.waitForSelector('#AddressOrContactDetail_PasswordToDisplay');
      await page.focus('#AddressOrContactDetail_PasswordToDisplay')
      await page.keyboard.type(HACPassword)

      //Get email address
      await page.waitForSelector('#AddressOrContactDetail_Contact_Email');
      let emailAddressSelector = await page.$('#AddressOrContactDetail_Contact_Email');
      let emailAddress = await page.evaluate(el => el.value, emailAddressSelector);

      //If email is not empty and -setloginidasemail or -setloginidasusername then attempt using it for the LoginID
      if (emailAddress.length > 0 && (loginIDAsEmail || loginIDAsUsername)) {
        if (loginIDAsEmail) {
          //empty login id box
          let loginIDSelector = await page.$('#AddressOrContactDetail_Contact_LoginID');
          await page.evaluate(el => el.value = "", loginIDSelector);
          //insert full email address
          await page.focus('#AddressOrContactDetail_Contact_LoginID');
          await page.keyboard.type(emailAddress)
        }

        if (loginIDAsUsername) {
          if (emailAddress.indexOf('@') > 0) {
            //empty login id box.
            let loginIDSelector = await page.$('#AddressOrContactDetail_Contact_LoginID');
            await page.evaluate(el => el.value = "", loginIDSelector);
            //find username from email and input.
            var loginID = emailAddress.slice(0,emailAddress.indexOf('@'));
            await page.focus('#AddressOrContactDetail_Contact_LoginID');
            await page.keyboard.type(loginID);
          }
        }
      } else {
        console.log('Error:',StudentID,'is missing a email address for us to use to create a LoginID. Be sure to populate eSchool email addresses before doing this.');
        await stuPage.close();
        process.exit(1)
      }

      if (passwordChangeNotRequired) {
        await page.click('#AddressOrContactDetail_Contact_MustChangePasswordNextLogin');
      }

      await page.click('#pageOptions-option-save');
      await page.waitForTimeout(500);
      
      try {
        //If the password passes the validation then we should see the confirmation button.
        await page.waitForSelector('#saveWarning-yes', {
          timeout: 1000
        });
        await page.click('#saveWarning-yes');
        await page.waitForTimeout(1000);
      } catch(err) {
        //If the password failed validation then we need to log why.
        await page.waitForSelector('#error-list > li');
        let element = await page.$('#error-list > li');
        let value = await page.evaluate(el => el.textContent, element);
        console.log("Error:",value);
      }

      //without css you can't validate on visible.
      //await page.waitForSelector('#EmailLoginPanel-content > div > div.alert.alert-danger.password-exists', { visible: true, });

      await browser.close()
      
    } else {
      //csv file has been supplied. Lets do some crazy looping.

      fs.createReadStream(csvPath)
      .pipe(csv())
      //.on('data', async (row) => {
      .on('data', async (row) => {
        studentsCSV.push(row)
      })
      .on('end', async () => {
        console.log('CSV file successfully processed');
        for (let i = 0; i < studentsCSV.length; i++) {
          //studentsCSV[i]
            var StudentID = studentsCSV[i].Student_id
            var HACPassword = studentsCSV[i].Password
            //console.log(row);
  
            console.log('Going to set student',StudentID,'with password of',HACPassword);
            try {
              //Go to student.
              //await page.setDefaultNavigationTimeout(0); //this takes awhile

              let stuPage = await browser.newPage();

              await stuPage.setViewport({
                width: 1366,
                height: 768,
                deviceScaleFactor: 1,
              });

              await stuPage.setRequestInterception(true);
              
              //Don't waste resources on proceessing CSS,Fonts, or Images. Continue with JavaScript.
              await stuPage.on('request', (req) => {
                  if(req.resourceType() == 'stylesheet' || req.resourceType() == 'font' || req.resourceType() == 'image'){
                      req.abort();
                  }
                  else {
                      req.continue();
                  }
              });
              await stuPage.goto('https://eschool20.esp.k12.ar.us/eSchoolPLUS20/Student/Registration/ContactDetail?studentId=' + StudentID + '&ContactPageMode=Address&PageEditMode=Modify&ContactEditMode=Modify')
  
              //Must be typed into the box. Setting the value doesn't work.
              await stuPage.waitForSelector('#AddressOrContactDetail_PasswordToDisplay');
              await stuPage.focus('#AddressOrContactDetail_PasswordToDisplay')
              await stuPage.keyboard.type(HACPassword)
              
              //Get email address
              await stuPage.waitForSelector('#AddressOrContactDetail_Contact_Email');
              let emailAddressSelector = await stuPage.$('#AddressOrContactDetail_Contact_Email');
              let emailAddress = await stuPage.evaluate(el => el.value, emailAddressSelector);

              //If email is not empty and -setloginidasemail or -setloginidasusername then attempt using it for the LoginID
              if (emailAddress.length > 0 && (loginIDAsEmail || loginIDAsUsername)) {
                if (loginIDAsEmail) {
                  //empty login id box
                  let loginIDSelector = await stuPage.$('#AddressOrContactDetail_Contact_LoginID');
                  await stuPage.evaluate(el => el.value = "", loginIDSelector);
                  //insert full email address
                  await stuPage.focus('#AddressOrContactDetail_Contact_LoginID');
                  await stuPage.keyboard.type(emailAddress)
                }

                if (loginIDAsUsername) {
                  if (emailAddress.indexOf('@') > 0) {
                    //empty login id box.
                    let loginIDSelector = await stuPage.$('#AddressOrContactDetail_Contact_LoginID');
                    await stuPage.evaluate(el => el.value = "", loginIDSelector);
                    //find username from email and input.
                    var loginID = emailAddress.slice(0,emailAddress.indexOf('@'));
                    await stuPage.focus('#AddressOrContactDetail_Contact_LoginID');
                    await stuPage.keyboard.type(loginID);
                  }
                }
              } else {
                console.log('Error:',StudentID,'is missing a email address for us to use to create a LoginID. Be sure to populate eSchool email addresses before doing this.');
                await stuPage.close();
                continue
              }

              if (passwordChangeNotRequired) {
                await stuPage.click('#AddressOrContactDetail_Contact_MustChangePasswordNextLogin');
              }

              await stuPage.click('#pageOptions-option-save');
              await stuPage.waitForTimeout(1000);

              try {
                //If the password passes the validation then we should see the confirmation button.
                await stuPage.waitForSelector('#saveWarning-yes', {
                  timeout: 1000
                });
                await stuPage.click('#saveWarning-yes');
                await stuPage.waitForTimeout(1000);
              } catch(err) {
                //If the password failed validation then we need to log why.
                await stuPage.waitForSelector('#error-list > li');
                let element = await stuPage.$('#error-list > li');
                let value = await stuPage.evaluate(el => el.textContent, element);
                console.log("Error:",value);
              }

              await stuPage.close();

            } catch(err) {
              console.log("Failed to update",StudentID,": ",err)
            }

            //if we reached the end of the loop then close completely.
            if (i === studentsCSV.length - 1) {
              await browser.close()
            }

        }
      });

    }

  } catch(err) {
    console.log('Failed to update password.')
    process.exit(1)
  }

})();