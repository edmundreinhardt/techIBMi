**FREE
/////////////////////////////////////////////////////////////////////////
// %TEXT Work with Customers                                           //
/////////////////////////////////////////////////////////////////////////
// Application. : ARC_NEW    PRD:New Sample                            //
// Component. . : CUS200                        Type: SQLRPGLE         //
/////////////////////////////////////////////////////////////////////////
// Sub-system . : CUS Customer                                         //
// Function . . : Work with Customers                                  //
// Sub-function : List, Create, Update, View Orders                    //
/////////////////////////////////////////////////////////////////////////
// Description of functions:                                           //
// This program provides a subfile interface to work with customers.   //
// Users can view a list of customers, create new customers, update    //
// existing customers, and view customer orders.                       //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
// AUTHOR:    VTAQUIN    16/12/2016 10:10  01.02.02                    //
// MODIFS: 04 REINHARD   08/09/2025 13:54  01.03.00    00/             //
//           =====> Refactored to fully free RPG with subprocedures    //
//         03 VTAQUIN    20/05/2020 10:50  01.02.12    00/             //
//         02 VTAQUIN    20/05/2020 00:00  01.02.10    00/             //
//         01 VTAQUIN    16/01/2017 11:39  01.02.04    00/             //
//         02 VTAQUIN    16/12/2016 10:10  01.02.02    00/             //
//           =====> Type RPGLE      changed to SQLRPGLE   <===== *     //
//         01 VTAQUIN    03/11/2016 17:19  01.01.00    00/             //
/////////////////////////////////////////////////////////////////////////

ctl-opt dftactgrp(*no) bnddir('SAMPLE') main(main);

// File declarations
dcl-f CUSTOME2 if e           k disk    rename(fcust:fcust2);
dcl-f CUSTOME1 uf a e           k disk;
dcl-f CUS200D  cf   e             workstn
       indds(indicatorDataStructure)
       sfile(subfileRecord:subfileRelativeRecordNumber)
       infds(informationDataStructure);

/copy qprotosrc,country

//=================================================================
// Global Definitions
//=================================================================

// External procedure prototypes
dcl-pr processOrders extpgm('ORD200');
  customerId like(cuid);
end-pr;

// Data structures
dcl-ds indicatorDataStructure;
  helpIndicator                 ind pos(1);
  exitIndicator                 ind pos(3);
  promptIndicator               ind pos(4);
  refreshIndicator              ind pos(5);
  createIndicator               ind pos(6);
  cancelIndicator               ind pos(12);
  moreKeysIndicator             ind pos(24);
  pageDownIndicator             ind pos(25);
  subfileClearIndicator         ind pos(30);
  subfileDisplayIndicator       ind pos(31);
  subfileDisplayControlIndicator ind pos(32);
  subfileNextChangeIndicator    ind pos(33);
  displayAttributeReverseImage  ind pos(34);
  subfileMessageIndicator       ind pos(35);
  errorCountryIndicator         ind pos(40);
  errorNameIndicator            ind pos(41);
  errorDuplicateIndicator       ind pos(42);
  errorPhoneIndicator           ind pos(43);
  errorPhoneNumberIndicator     ind pos(44);
  subfileEndIndicator           ind pos(80);
end-ds;

dcl-ds informationDataStructure;
  lastRecordNumber             int(5) pos(378);
end-ds;

// Standalone fields
dcl-s subfileRelativeRecordNumber int(5);
dcl-s subfileSavedRecordNumber   int(5);
dcl-s subfileErrorIndicator      ind;

dcl-s currentPanel               int(3) inz(1);
dcl-s stepPanel1                 char(3) inz('PRP');
dcl-s stepPanel2                 char(3) inz('PRP');
dcl-s savedCustomerId            like(cuid);
dcl-s savedCustomerName          like(custnm);
dcl-s currentUser                char(10) inz(*user);
dcl-s recordCount                int(3);
dcl-s duplicateCount             int(3);
dcl-s mode                       char(3);

// Constants
dcl-c MODE_CREATE                'CRT';
dcl-c MODE_UPDATE                'UPD';
dcl-c STEP_PREPARE               'PRP';
dcl-c STEP_LOAD                  'LOD';
dcl-c STEP_DISPLAY               'DSP';
dcl-c STEP_KEY_PROCESSING        'KEY';
dcl-c STEP_CHECK                 'CHK';
dcl-c STEP_CHECK_CONTROL         'CHC';
dcl-c STEP_ACTION_CONTROL        'ACC';
dcl-c STEP_ACTION                'ACT';
dcl-c DEFAULT_DATE               d'1940-01-01';

//=================================================================
// Main Procedure
//=================================================================
dcl-proc main;
  // Initialize program
  initializeProgram();
  
  // Process panels until exit
  dow currentPanel > 0;
    selectPanel();
  enddo;
  
  // Exit program
  *inlr = *on;
  return;
end-proc;

//=================================================================
// Panel Selection Procedure
//=================================================================
dcl-proc selectPanel;
  select;
    when currentPanel = 1;
      processCustomerList();
    when currentPanel = 2;
      processCustomerDetail();
    other;
      currentPanel = 0;
  endsl;
end-proc;

//=================================================================
// Program Initialization
//=================================================================
dcl-proc initializeProgram;
  cumodid = currentUser;
  cucrea = %date();
  LASTORD = DEFAULT_DATE;
end-proc;

//=================================================================
// Panel 1 - Customer List Processing
//=================================================================
dcl-proc processCustomerList;
  select;
    when stepPanel1 = STEP_PREPARE;
      prepareSubfile();
    when stepPanel1 = STEP_LOAD;
      loadSubfile();
    when stepPanel1 = STEP_DISPLAY;
      displaySubfile();
    when stepPanel1 = STEP_KEY_PROCESSING;
      processSubfileKeys();
    when stepPanel1 = STEP_CHECK;
      checkSubfileSelections();
    when stepPanel1 = STEP_ACTION;
      processSubfileActions();
  endsl;
end-proc;

//--- Clear Subfile ----------------------------------------------------
dcl-proc prepareSubfile;
  subfileRelativeRecordNumber = 0;
  subfileClearIndicator = *on;
  write ctl01;
  subfileClearIndicator = *off;
  stepPanel1 = STEP_LOAD;
  clear savedCustomerId;
  savedCustomerName = posTo;
  clear posTo;
  subfileSavedRecordNumber = 0;
end-proc;

//--- Load Subfile -----------------------------------------------------
dcl-proc loadSubfile;
  restoreSubfilePosition();
  
  subfileRecordNumber = subfileRelativeRecordNumber + 1;
  opt01 = 0;
  recordCount = 0;
  
  read custome2;
  dow not %eof(custome2) and recordCount < 14;
    subfileRelativeRecordNumber += 1;
    recordCount += 1;
    write subfileRecord;
    read custome2;
  enddo;
  
  subfileEndIndicator = %eof(custome2);
  stepPanel1 = STEP_DISPLAY;
  
  saveSubfilePosition();
end-proc;

//--- Restore last read position ---------------------------------------
dcl-proc restoreSubfilePosition;
  setll (savedCustomerName:savedCustomerId) custome2;
  subfileRelativeRecordNumber = subfileSavedRecordNumber;
end-proc;

//--- Save last read position ------------------------------------------
dcl-proc saveSubfilePosition;
  savedCustomerId = cuid;
  savedCustomerName = custNm;
  subfileSavedRecordNumber = subfileRelativeRecordNumber;
end-proc;

//--- Display Subfile --------------------------------------------------
dcl-proc displaySubfile;
  subfileDisplayControlIndicator = *on;
  subfileDisplayIndicator = subfileRelativeRecordNumber > 0;

  write key01;
  exfmt ctl01;
  
  if lastRecordNumber <> 0;
    subfileRecordNumber = lastRecordNumber;
  endif;
  
  stepPanel1 = STEP_KEY_PROCESSING;
end-proc;

//--- Command Keys Processing ------------------------------------------
dcl-proc processSubfileKeys;
  select;
    when exitIndicator;
      currentPanel = 0;
      stepPanel1 = STEP_PREPARE;
    when cancelIndicator;
      stepPanel1 = STEP_PREPARE;
      currentPanel = currentPanel - 1;
    when refreshIndicator;
      stepPanel1 = STEP_PREPARE;
    when createIndicator;
      initializeNewCustomer();
    when pageDownIndicator;
      stepPanel1 = STEP_LOAD;
    other;
      stepPanel1 = STEP_CHECK;
  endsl;
end-proc;

//--- Initialize New Customer ------------------------------------------
dcl-proc initializeNewCustomer;
  stepPanel1 = STEP_DISPLAY;
  currentPanel = 2;
  stepPanel2 = STEP_DISPLAY;
  mode = MODE_CREATE;
  reset fcust;
  exec sql set :cuid = NEXT VALUE FOR CusSeq;
end-proc;

//--- Check Subfile Selections -----------------------------------------
dcl-proc checkSubfileSelections;
  stepPanel1 = STEP_ACTION;
  subfileErrorIndicator = *off;
  subfileNextChangeIndicator = *on;
  
  readc(e) subfileRecord;
  dow not %error and not %eof;
    if not isValidOption(opt01);
      markInvalidOption();
    endif;
    
    update subfileRecord;
    displayAttributeReverseImage = *off;
    readc(e) subfileRecord;
  enddo;
  
  subfileNextChangeIndicator = *off;
end-proc;

//--- Check if option is valid -----------------------------------------
dcl-proc isValidOption;
  dcl-pi *n ind;
    optionValue int(2) value;
  end-pi;
  
  return optionValue = 0 or optionValue = 2 or optionValue = 5;
end-proc;

//--- Mark invalid option in subfile -----------------------------------
dcl-proc markInvalidOption;
  stepPanel1 = STEP_DISPLAY;
  displayAttributeReverseImage = *on;
  subfileMessageIndicator = *on;
  
  if not subfileErrorIndicator;
    subfileRecordNumber = subfileRelativeRecordNumber;
    subfileErrorIndicator = *on;
  endif;
end-proc;

//--- Process Subfile Actions ------------------------------------------
dcl-proc processSubfileActions;
  readc(e) subfileRecord;
  
  select;
    when %error or %eof;
      handleEndOfSubfile();
    when opt01 = 2;
      handleUpdateOption();
    when opt01 = 5;
      handleOrdersOption();
    other;
      // No action
  endsl;
end-proc;

//--- Handle end of subfile --------------------------------------------
dcl-proc handleEndOfSubfile;
  if posto <> ' ';
    stepPanel1 = STEP_PREPARE;
  else;
    stepPanel1 = STEP_DISPLAY;
  endif;
end-proc;

//--- Handle update option ---------------------------------------------
dcl-proc handleUpdateOption;
  mode = MODE_UPDATE;
  currentPanel = 2;
  stepPanel2 = STEP_PREPARE;
  opt01 = 0;
  update subfileRecord;
end-proc;

//--- Handle orders option ---------------------------------------------
dcl-proc handleOrdersOption;
  processOrders(cuid);
  opt01 = 0;
  update subfileRecord;
end-proc;

//=================================================================
// Panel 2 - Customer Detail Processing
//=================================================================
dcl-proc processCustomerDetail;
  select;
    when stepPanel2 = STEP_PREPARE;
      prepareCustomerDetail();
    when stepPanel2 = STEP_DISPLAY;
      displayCustomerDetail();
    when stepPanel2 = STEP_KEY_PROCESSING;
      processDetailKeys();
    when stepPanel2 = STEP_CHECK;
      validateCustomerData();
    when stepPanel2 = STEP_ACTION;
      processCustomerUpdate();
  endsl;
end-proc;

//--- Prepare Customer Detail ------------------------------------------
dcl-proc prepareCustomerDetail;
  chain cuid custome1;
  coname = GetCountryName(CuCoun);
  
  if CULASTORD = 0;
    LASTORD = DEFAULT_DATE;
  else;
    LASTORD = %date(CULASTORD:*iso);
  endif;
  
  stepPanel2 = STEP_DISPLAY;
end-proc;

//--- Display Customer Detail ------------------------------------------
dcl-proc displayCustomerDetail;
  exfmt fmt02;
  stepPanel2 = STEP_KEY_PROCESSING;
end-proc;

//--- Process Detail Command Keys --------------------------------------
dcl-proc processDetailKeys;
  select;
    when exitIndicator;
      currentPanel = 1;
      stepPanel2 = STEP_PREPARE;
    when cancelIndicator;
      stepPanel2 = STEP_PREPARE;
      currentPanel = currentPanel - 1;
    when promptIndicator;
      handleCountryPrompt();
    other;
      stepPanel2 = STEP_CHECK;
  endsl;
end-proc;

//--- Handle Country Prompt --------------------------------------------
dcl-proc handleCountryPrompt;
  stepPanel2 = STEP_DISPLAY;
  cucoun = SltCountry(cucoun);
  coname = GetCountryName(CuCoun);
end-proc;

//--- Validate Customer Data -------------------------------------------
dcl-proc validateCustomerData;
  dcl-s isValid ind inz(*on);
  
  stepPanel2 = STEP_ACTION;
  
  // Validate country code
  if not validateCountry();
    isValid = *off;
  endif;
  
  // Validate customer name
  if not validateCustomerName();
    isValid = *off;
  endif;
  
  // Validate phone number
  if not validatePhoneNumber();
    isValid = *off;
  endif;
  
  // If any validation failed, return to display
  if not isValid;
    stepPanel2 = STEP_DISPLAY;
  endif;
end-proc;

//--- Validate Country -------------------------------------------------
dcl-proc validateCountry;
  dcl-pi *n ind;
  end-pi;
  
  if not ExistCountry(cucoun);
    errorCountryIndicator = *on;
    return *off;
  endif;
  
  return *on;
end-proc;

//--- Validate Customer Name -------------------------------------------
dcl-proc validateCustomerName;
  dcl-pi *n ind;
  end-pi;
  
  if custnm = *blanks;
    errorNameIndicator = *on;
    return *off;
  endif;
  
  return *on;
end-proc;

//--- Validate Phone Number --------------------------------------------
dcl-proc validatePhoneNumber;
  dcl-pi *n ind;
  end-pi;
  
  if cuphone = *blanks;
    errorPhoneIndicator = *on;
    return *off;
  endif;
  
  cuphone = %trim(cuphone);
  
  // Check for valid digits
  if %check('0123456789':%trim(cuphone)) > 0;
    errorPhoneNumberIndicator = *on;
    return *off;
  endif;
  
  // Check for duplicates
  if not checkForDuplicates();
    return *off;
  endif;
  
  return *on;
end-proc;

//--- Check for Duplicate Customers ------------------------------------
dcl-proc checkForDuplicates;
  dcl-pi *n ind;
  end-pi;
  
  exec sql select count(*) into :duplicateCount from customer
           where UPPER(custnm) = UPPER(:Custnm)
             and cuphone = :cuphone;
             
  if mode = MODE_CREATE and duplicateCount > 0 
     or mode = MODE_UPDATE and duplicateCount > 1;
    errData = custnm + cuphone;
    errorDuplicateIndicator = *on;
    return *off;
  endif;
  
  return *on;
end-proc;

//--- Process Customer Update ------------------------------------------
dcl-proc processCustomerUpdate;
  stepPanel2 = STEP_PREPARE;
  cumod = %timestamp();
  
  if mode = MODE_UPDATE;
    update fcust;
  else;
    write fcust;
  endif;
  
  currentPanel = 1;
end-proc;
