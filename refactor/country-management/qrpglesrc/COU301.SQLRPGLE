**free
//*%METADATA                                                                          *
//* %TEXT Select a Country code                                                       *
//*%EMETADATA                                                                         *
ctl-opt nomain;
ctl-opt datfmt(*iso) timfmt(*iso) decedit('0.');
ctl-opt option(*srcstmt:*nodebugio);

// File declarations - Keep display file, replace database files with SQL
dcl-f cou301d workstn usage(*input:*output) infds(INFO)
                             sfile(SFL01:subfileRecordNumber)
                             indds(indds);

// Data structures
dcl-ds INFO;
  LRRN                 int(5) pos(378);
end-ds;

// Country record structure
dcl-ds countryRec qualified;
  coid char(2);
  countr char(30);
  coiso char(3);
end-ds;

/copy country

dcl-ds indds;
  help                   ind pos(1);
  exit                   ind pos(3);
  prompt                 ind pos(4);
  refresh                ind pos(5);
  create                 ind pos(6);
  cf08                   ind pos(8);
  cancel                 ind pos(12);
  morekeys               ind pos(24);
  pagedown               ind pos(25);
  sflclr                 ind pos(30);
  sfldsp                 ind pos(31);
  sfldspctl              ind pos(32);
  sflnxtchg              ind pos(33);
  dspatrri               ind pos(34);
  InvalidOpt             ind pos(35);
  OneSelect              ind pos(36);
  bydesc                 ind pos(40);
  InvalidOptC            ind pos(41);
  NotAvail               ind pos(42);
  sflend                 ind pos(80);
end-ds;

// Standalone fields
dcl-s subfileRecordNumber int(5);
dcl-s cursorPosition      int(5);

// Constants
dcl-c PREPARE_STEP       'prp';
dcl-c LOAD_STEP          'lod';
dcl-c DISPLAY_STEP       'dsp';
dcl-c PROCESS_KEYS_STEP  'key';
dcl-c CHECK_SELECTIONS_STEP 'chk';
dcl-c CHECK_CONTROL_STEP 'chc';
dcl-c ACTION_CONTROL_STEP 'acc';
dcl-c PROCESS_ACTION_STEP 'act';

//=============================================
// Select a Country code
//=============================================
dcl-proc sltcountry export;
  dcl-pi *n                  like(coid);
    paramCountryCode         like(coid);
  end-pi;
  
  dcl-s returnCountryCode    like(coid);
  dcl-s processStep          char(3) inz(PREPARE_STEP);
  dcl-s f8KeyPressed         ind;
  dcl-s optionSelected       ind;
  dcl-s savedRecordNumber    int(5);
  dcl-s recordCounter        int(5);
  dcl-s errorFound           ind;
  dcl-s selectionMade        ind;
  dcl-s searchByCode         like(coid);
  dcl-s savedCode            like(coid);
  dcl-s paramDesc            like(countr);
  dcl-s searchByDesc         like(countr);
  dcl-s savedDesc            like(countr);
  dcl-s moreRecordsExist     ind;
  
  // SQL cursor for countries ordered by code
  exec sql
    DECLARE C_COUNTRY_BY_CODE CURSOR FOR
    SELECT COID, COUNTR
    FROM COUNTRY
    WHERE COID >= :searchByCode
    ORDER BY COID
    FOR READ ONLY;
  
  // SQL cursor for countries ordered by description
  exec sql
    DECLARE C_COUNTRY_BY_DESC CURSOR FOR
    SELECT COID, COUNTR
    FROM COUNTRY
    WHERE COUNTR >= :searchByDesc
    ORDER BY COUNTR
    FOR READ ONLY;
  
  if not %open(cou301d);
    open cou301d;
  endif;
  
  searchByCode = paramCountryCode;
  returnCountryCode = paramCountryCode;
  bydesc = *off;
  
  dow processStep <> ' ';
    select;
    when processStep = PREPARE_STEP;
      exsr prepareSubfile;
    when processStep = LOAD_STEP;
      exsr loadSubfile;
    when processStep = DISPLAY_STEP;
      exsr displaySubfile;
    when processStep = PROCESS_KEYS_STEP;
      exsr processCommandKeys;
    when processStep = CHECK_SELECTIONS_STEP;
      exsr checkSubfileSelections;
    when processStep = PROCESS_ACTION_STEP;
      exsr processSubfileActions;
    endsl;
  enddo;
  
  // Close any open cursors
  exec sql
    CLOSE C_COUNTRY_BY_CODE;
  
  exec sql
    CLOSE C_COUNTRY_BY_DESC;
  
  return returnCountryCode;
  
  //--- Clear Subfile  -----------------------------------------------------
  begsr prepareSubfile;
    savedRecordNumber = 0;
    clear CTL01;
    sflclr = *on;
    sfldsp = *off;
    sfldspctl = *off;
    write CTL01;
    sflclr = *off;
    
    // Close any open cursors
    exec sql
      CLOSE C_COUNTRY_BY_CODE;
    
    exec sql
      CLOSE C_COUNTRY_BY_DESC;
    
    // Open appropriate cursor based on search mode
    if not bydesc;
      exec sql
        OPEN C_COUNTRY_BY_CODE;
      
      // Fetch first record
      exec sql
        FETCH C_COUNTRY_BY_CODE INTO :countryRec.coid, :countryRec.countr;
      
      sflend = (SQLCODE <> 0);
    else;
      exec sql
        OPEN C_COUNTRY_BY_DESC;
      
      // Fetch first record
      exec sql
        FETCH C_COUNTRY_BY_DESC INTO :countryRec.coid, :countryRec.countr;
      
      sflend = (SQLCODE <> 0);
    endif;
    
    // Save current record values
    savedCode = countryRec.coid;
    savedDesc = countryRec.countr;
    processStep = LOAD_STEP;
  endsr;
  
  //--- Load Subfile  -----------------------------------------------------
  begsr loadSubfile;
    subfileRecordNumber = savedRecordNumber;
    cursorPosition = savedRecordNumber + 1;
    recordCounter = 0;
    OPT01 = 0;
    SflNxtChg = *OFF;
    
    // Set current record values
    coid = savedCode;
    countr = savedDesc;
    
    // Load records into subfile
    moreRecordsExist = not sflend;
    dow moreRecordsExist and recordCounter < 20;
      subfileRecordNumber = subfileRecordNumber + 1;
      recordCounter = recordCounter + 1;
      write SFL01;
      
      // Fetch next record
      if not bydesc;
        exec sql
          FETCH C_COUNTRY_BY_CODE INTO :countryRec.coid, :countryRec.countr;
      else;
        exec sql
          FETCH C_COUNTRY_BY_DESC INTO :countryRec.coid, :countryRec.countr;
      endif;
      
      // Check if we reached end of file
      moreRecordsExist = (SQLCODE = 0);
      SflEnd = not moreRecordsExist;
      
      // Update current record values if we have more records
      if moreRecordsExist;
        coid = countryRec.coid;
        countr = countryRec.countr;
      endif;
    enddo;
    
    // Save current record values
    savedCode = coid;
    savedDesc = countr;
    savedRecordNumber = subfileRecordNumber;
    processStep = DISPLAY_STEP;
  endsr;
  
  //--- Display Subfile  --------------------------------------------------
  begsr displaySubfile;
    sfldsp = savedRecordNumber > 0;
    sfldspctl = *on;
    write KEY01;
    exfmt CTL01;
    f8KeyPressed = CF08;
    cursorPosition = LRRN;
    processStep = PROCESS_KEYS_STEP;
  endsr;
  
  //--- Command Keys  -----------------------------------------------------
  begsr processCommandKeys;
    select;
    when exit;
      processStep = ' ';
    when cancel;
      processStep = ' ';
    when PageDown;
      processStep = LOAD_STEP;
    other;
      processStep = CHECK_SELECTIONS_STEP;
    endsl;
  endsr;
  
  //--- Check Subfile  ----------------------------------------------------
  begsr checkSubfileSelections;
    // SET FLAG SELECTION MADE OFF
    selectionMade = *OFF;
    // SET FLAG OPTION  MADE OFF
    optionSelected = *OFF;
    // SET FLAG ERROR   MADE OFF
    errorFound = *OFF;
    processStep = PROCESS_ACTION_STEP;
    
    readc(E) SFL01;
    SflNxtChg = *ON;
    
    dow not %error and not %eof;
      select;
      when OPT01 = 0;
        // NO ERROR
      when OPT01 <> 1;
        optionSelected = *ON;
        processStep = DISPLAY_STEP;
        dspatrRi = *on;
        InvalidOpt = *on;
        if errorFound = *OFF;
          cursorPosition = subfileRecordNumber;
          errorFound = *ON;
        endif;
      //OPTION = 1 BUT SELECTION ALREADY MADE
      when selectionMade = *ON;
        processStep = DISPLAY_STEP;
        dspatrRi = *on;
        OneSelect = *on;
        if errorFound = *OFF;
          cursorPosition = subfileRecordNumber;
          errorFound = *ON;
        endif;
      other;
        //OPTION = 1
        selectionMade = *ON;
        optionSelected = *ON;
      endsl;
      
      update SFL01;
      dspatrRi = *off;
      readc SFL01;
    enddo;
    
    select;
    when OPTC1 <> 8 and OPTC1 <> 0;
      InvalidOptC = *ON;
      processStep = DISPLAY_STEP;
    when selectionMade = *ON and OPTC1 <> 0;
      NotAvail = *ON;
      processStep = DISPLAY_STEP;
    when optionSelected = *ON and f8KeyPressed = *ON;
      processStep = DISPLAY_STEP;
    endsl;
  endsr;
  
  //--- Write Subfile  ----------------------------------------------------
  begsr processSubfileActions;
    processStep = DISPLAY_STEP;
    
    select;
    when f8KeyPressed;
      processStep = PREPARE_STEP;
      bydesc = not bydesc;
      if bydesc;
        clear searchByDesc;
      else;
        clear searchByCode;
      endif;
    when OPTC1 = 8;
      processStep = PREPARE_STEP;
      if not bydesc;
        searchByCode = POSCOD;  // Position code from display file
      else;
        searchByDesc = POSDES;  // Position description from display file
      endif;
    other;
      readc(E) SFL01;
      dow not %error and not %eof;
        if OPT01 = 1;
          return coid;
        endif;
        readc SFL01;
      enddo;
    endsl;
  endsr;
end-proc;
