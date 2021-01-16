const puppeteer = require('puppeteer');
const dotenv = require('dotenv').config();

// Expected command line should be in the following formats:
// node hacpassword.js 40305966 NewP@ssw0rd

if (process.argv[2] === undefined) {
    console.log('You must specify a StudentID or CSV to process.');
} else {
    if(process.argv[3] === undefined){
        console.log('You must specify a password for StudentID',process.argv[2]);
        process.exit(1)
    }

    var StudentID = process.argv[2];
    var HACPassword = process.argv[3];

    console.log('Going to set student',StudentID,'with password of',HACPassword);

}

// eSchool login

(async () => {
  //const browser = await puppeteer.launch();
  const browser = await puppeteer.launch({
    //headless: false
  });
  const page = await browser.newPage();

  await page.setViewport({
    width: 1366,
    height: 768,
    deviceScaleFactor: 1,
  });

  await page.goto('https://eschool20.esp.k12.ar.us/eSchoolPLUS20/Account/LogOn?ReturnUrl=%2feSchoolPLUS20');
  
  await page.type('#UserName', process.env.SSOUSERNAME);
  await page.type('#Password', process.env.PASSWORD);
  await page.click('#login');
  await page.waitForNavigation({
    waitUntil: 'networkidle0',
  });
  
  debugger;
  await page.click('#setEnvOkButton');

    // this doesn't always work.
    //   await page.waitForNavigation({
    //     waitUntil: 'networkidle0',
    //   });
    
  //We don't need the page to actually load so just navigate straight to the student after wait.
  await page.waitForTimeout(1000);
  
  //Go to student.
  //await page.setDefaultNavigationTimeout(0); //this takes awhile
  await page.goto('https://eschool20.esp.k12.ar.us/eSchoolPLUS20/Student/Registration/ContactDetail?studentId=' + StudentID + '&ContactPageMode=Address&PageEditMode=Modify&ContactEditMode=Modify')

  //Must be typed into the box. Setting the value doesn't work.
  await page.waitForSelector('#AddressOrContactDetail_PasswordToDisplay');
  await page.focus('#AddressOrContactDetail_PasswordToDisplay')
  await page.keyboard.type(HACPassword)

  await page.click('#pageOptions-option-save');
  await page.waitForTimeout(1000);
  await page.waitForSelector('#saveWarning-yes');
  await page.click('#saveWarning-yes');
  await page.waitForTimeout(1000);

  await browser.close()

})();