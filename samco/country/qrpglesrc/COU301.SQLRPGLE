**FREE
/////////////////////////////////////////////////////////////////////////
// %TEXT Select a Country code
/////////////////////////////////////////////////////////////////////////

ctl-opt nomain;

// SQL Definitions
exec sql set option commit=*none, datfmt=*iso, closqlcsr=*endmod;

dcl-f cou301d workstn infds(displayInfo) sfile(SFL01:subfileRelativeRecord) indds(indicators);

dcl-ds displayInfo;
  lastRecordNumber int(5) pos(378);
end-ds;

/copy qprotosrc,country

// Indicator data structure for display file
dcl-ds indicators;
  help ind pos(1);
  exit ind pos(3);
  prompt ind pos(4);
  refresh ind pos(5);
  create ind pos(6);
  functionKey8 ind pos(8);
  cancel ind pos(12);
  moreKeys ind pos(24);
  pageDown ind pos(25);
  subfileClear ind pos(30);
  subfileDisplay ind pos(31);
  subfileControl ind pos(32);
  subfileNextChange ind pos(33);
  reverseImage ind pos(34);
  invalidOption ind pos(35);
  multipleSelection ind pos(36);
  searchByName ind pos(40);
  invalidPositionOption ind pos(41);
  positionNotAvailable ind pos(42);
  subfileEnd ind pos(80);
end-ds;

// Subfile relative record number
dcl-s subfileRelativeRecord int(5);

// State machine constants
dcl-c STATE_PREPARE 'prp';
dcl-c STATE_LOAD 'lod';
dcl-c STATE_DISPLAY 'dsp';
dcl-c STATE_PROCESS_KEYS 'key';
dcl-c STATE_CHECK_INPUT 'chk';
dcl-c STATE_PROCESS_ACTION 'act';

// SQL Cursor for country data by ID
exec sql declare country_cursor cursor for
  select COID, COUNTR, COISO
  from COUNTRY
  where COID >= :searchByIdValue
  order by COID;

// SQL Cursor for country data by name
exec sql declare countr1_cursor cursor for
  select COID, COUNTR, COISO
  from COUNTRY
  where COUNTR >= :searchByNameValue
  order by COUNTR;

//=============================================
// Main procedure to select a country
dcl-proc selectCountry export;
  dcl-pi *n like(coid);
    defaultCountryId like(coid);
  end-pi;
  
  // Return value
  dcl-s selectedCountryId like(coid);
  
  // State machine variables
  dcl-s currentState char(3) inz(STATE_PREPARE);
  dcl-s functionKey8Pressed ind;
  dcl-s optionSelected ind;
  dcl-s subfileRecordCount int(5);
  dcl-s recordCounter int(5);
  dcl-s errorOccurred ind;
  dcl-s selectionMade ind;
  
  // Search variables
  dcl-s searchByIdValue like(coid);
  dcl-s savedCountryId like(coid);
  dcl-s positionDescription like(countr);
  dcl-s searchByNameValue like(countr);
  dcl-s savedCountryName like(countr);
  
  // SQL work variables
  dcl-s tempId like(coid);
  dcl-s tempName like(countr) varying;
  dcl-s tempIsoCode like(coiso);
  
  // Initialize
  if not %open(cou301d);
    open cou301d;
  endif;
  
  searchByIdValue = defaultCountryId;
  selectedCountryId = defaultCountryId;
  searchByName = *off;
  
  // State machine loop
  dow currentState <> ' ';
    select;
    when currentState = STATE_PREPARE;
      prepareSubfile();
    when currentState = STATE_LOAD;
      loadSubfile();
    when currentState = STATE_DISPLAY;
      displaySubfile();
    when currentState = STATE_PROCESS_KEYS;
      processKeys();
    when currentState = STATE_CHECK_INPUT;
      checkInput();
    when currentState = STATE_PROCESS_ACTION;
      processAction();
    endsl;
  enddo;
  
  return selectedCountryId;
end-proc;  
  //--- Prepare Subfile -----------------------------------------------------
  dcl-proc prepareSubfile;
    subfileRecordCount = 0;
    clear CTL01;
    subfileClear = *on;
    subfileDisplay = *off;
    subfileControl = *off;
    write CTL01;
    subfileClear = *off;
    
    // Close any open cursors
    exec sql close country_cursor;
    exec sql close countr1_cursor;
    
    if not searchByName;
      // Open cursor for access by code
      exec sql open country_cursor;
      // Fetch first record
      exec sql fetch country_cursor into :tempId, :tempName, :tempIsoCode;
      subfileEnd = (SQLSTT <> '00000' and SQLSTT <> '01000');
    else;
      // Open cursor for access by name
      exec sql open countr1_cursor;
      // Fetch first record
      exec sql fetch countr1_cursor into :tempId, :tempName, :tempIsoCode;
      subfileEnd = (SQLSTT <> '00000' and SQLSTT <> '01000');
    endif;
    
    // Set fields for display
    coid = tempId;
    countr = tempName;
    coiso = tempIsoCode;
    
    savedCountryId = coid;
    savedCountryName = countr;
    currentState = STATE_LOAD;
  end-proc;
  
  //--- Load Subfile -----------------------------------------------------
  dcl-proc loadSubfile;
    subfileRelativeRecord = subfileRecordCount;
    RRB01 = subfileRecordCount + 1;
    recordCounter = 0;
    OPT01 = 0;
    subfileNextChange = *OFF;
    coid = savedCountryId;
    countr = savedCountryName;
    coiso = tempIsoCode;
    
    dow not subfileEnd and recordCounter < 20;
      subfileRelativeRecord += 1;
      recordCounter += 1;
      write SFL01;
      
      if not searchByName;
        // Fetch next record by code
        exec sql fetch country_cursor into :tempId, :tempName, :tempIsoCode;
      else;
        // Fetch next record by name
        exec sql fetch countr1_cursor into :tempId, :tempName, :tempIsoCode;
      endif;
      
      // Set fields for display
      coid = tempId;
      countr = tempName;
      coiso = tempIsoCode;
      
      subfileEnd = (SQLSTT <> '00000' and SQLSTT <> '01000');
    enddo;
    
    savedCountryId = coid;
    savedCountryName = countr;
    subfileRecordCount = subfileRelativeRecord;
    currentState = STATE_DISPLAY;
  end-proc;
  
  //--- Display Subfile --------------------------------------------------
  dcl-proc displaySubfile;
    subfileDisplay = subfileRecordCount > 0;
    subfileControl = *on;
    write KEY01;
    exfmt CTL01;
    functionKey8Pressed = functionKey8;
    RRB01 = lastRecordNumber;
    currentState = STATE_PROCESS_KEYS;
  end-proc;
  
  //--- Process Function Keys -----------------------------------------------------
  dcl-proc processKeys;
    select;
    when exit;
      currentState = ' ';
    when cancel;
      currentState = ' ';
    when pageDown;
      currentState = STATE_LOAD;
    other;
      currentState = STATE_CHECK_INPUT;
    endsl;
  end-proc;
  
  //--- Check User Input ----------------------------------------------------
  dcl-proc checkInput;
    // Reset flags
    selectionMade = *OFF;
    optionSelected = *OFF;
    errorOccurred = *OFF;
    currentState = STATE_PROCESS_ACTION;
    
    // Process subfile options
    readc(E) SFL01;
    subfileNextChange = *ON;
    
    dow not %error and not %eof;
      select;
      when OPT01 = 0;
        // No option entered - no action needed
      when OPT01 <> 1;
        // Invalid option entered
        optionSelected = *ON;
        currentState = STATE_DISPLAY;
        reverseImage = *on;
        invalidOption = *on;
        if not errorOccurred;
          RRB01 = subfileRelativeRecord;
          errorOccurred = *ON;
        endif;
      when selectionMade;
        // Multiple selections not allowed
        currentState = STATE_DISPLAY;
        reverseImage = *on;
        multipleSelection = *on;
        if not errorOccurred;
          RRB01 = subfileRelativeRecord;
          errorOccurred = *ON;
        endif;
      other;
        // Valid option 1 selected
        selectionMade = *ON;
        optionSelected = *ON;
      endsl;
      
      update SFL01;
      reverseImage = *off;
      readc SFL01;
    enddo;
    
    // Process position to option
    select;
    when OPTC1 <> 8 and OPTC1 <> 0;
      invalidPositionOption = *ON;
      currentState = STATE_DISPLAY;
    when selectionMade and OPTC1 <> 0;
      positionNotAvailable = *ON;
      currentState = STATE_DISPLAY;
    when optionSelected and functionKey8Pressed;
      currentState = STATE_DISPLAY;
    endsl;
  end-proc;
  
  //--- Process Actions ----------------------------------------------------
  dcl-proc processAction;
    currentState = STATE_DISPLAY;
    
    select;
    when functionKey8Pressed;
      // Toggle between search by ID and search by name
      currentState = STATE_PREPARE;
      searchByName = not searchByName;
      if searchByName;
        clear searchByNameValue;
      else;
        clear searchByIdValue;
      endif;
    when OPTC1 = 8;
      // Position to specified value
      currentState = STATE_PREPARE;
      if not searchByName;
        searchByIdValue = POSCOD;
      else;
        searchByNameValue = POSDES;
      endif;
    other;
      // Process selection
      readc(E) SFL01;
      dow not %error and not %eof;
        if OPT01 = 1;
          return coid;
        endif;
        readc SFL01;
      enddo;
    endsl;
  end-proc;

