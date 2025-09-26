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
      processStep = prepareSubfile(bydesc: searchByCode: searchByDesc: 
                                  savedRecordNumber: savedCode: savedDesc: sflend);
    when processStep = LOAD_STEP;
      processStep = loadSubfile(savedRecordNumber: savedCode: savedDesc: bydesc: sflend:
                               subfileRecordNumber: savedCode: savedDesc: savedRecordNumber);
    when processStep = DISPLAY_STEP;
      processStep = displaySubfile(savedRecordNumber: f8KeyPressed: cursorPosition);
    when processStep = PROCESS_KEYS_STEP;
      processStep = processCommandKeys(exit: cancel: pagedown);
    when processStep = CHECK_SELECTIONS_STEP;
      processStep = checkSubfileSelections(f8KeyPressed: selectionMade: optionSelected: 
                                         errorFound: cursorPosition);
    when processStep = PROCESS_ACTION_STEP;
      processStep = processSubfileActions(f8KeyPressed: bydesc: OPTC1: 
                                        searchByCode: searchByDesc);
      // Check if a country was selected
      if processStep <> PREPARE_STEP and processStep <> DISPLAY_STEP;
        returnCountryCode = processStep;
        processStep = ' ';  // Exit the loop
      endif;
    endsl;
  enddo;
  
  // Close any open cursors
  exec sql
    CLOSE C_COUNTRY_BY_CODE;
  
  exec sql
    CLOSE C_COUNTRY_BY_DESC;
  
  return returnCountryCode;
end-proc;

//=============================================
// Prepare Subfile
//=============================================
dcl-proc prepareSubfile;
  dcl-pi *n char(3);
    p_bydesc ind const;
    searchByCode like(coid) const;
    searchByDesc like(countr) const;
    p_savedRecordNumber int(5);
    p_savedCode like(coid);
    p_savedDesc like(countr);
    p_sflend ind;
  end-pi;
  
  p_savedRecordNumber = 0;
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
  if not p_bydesc;
    exec sql
      OPEN C_COUNTRY_BY_CODE;
    
    // Fetch first record
    exec sql
      FETCH C_COUNTRY_BY_CODE INTO :countryRec.coid, :countryRec.countr;
    
    p_sflend = (SQLCODE <> 0);
  else;
    exec sql
      OPEN C_COUNTRY_BY_DESC;
    
    // Fetch first record
    exec sql
      FETCH C_COUNTRY_BY_DESC INTO :countryRec.coid, :countryRec.countr;
    
    p_sflend = (SQLCODE <> 0);
  endif;
  
  // Save current record values
  p_savedCode = countryRec.coid;
  p_savedDesc = countryRec.countr;
  
  return LOAD_STEP;
end-proc;

//=============================================
// Load Subfile
//=============================================
dcl-proc loadSubfile;
  dcl-pi *n char(3);
    p_savedRecordNumber int(5) const;
    p_savedCode like(coid) const;
    p_savedDesc like(countr) const;
    p_bydesc ind const;
    p_sflend ind const;
    p_subfileRecordNumber int(5);
    p_newSavedCode like(coid);
    p_newSavedDesc like(countr);
    p_newSavedRecordNumber int(5);
  end-pi;
  
  dcl-s l_recordCounter int(5);
  dcl-s l_moreRecordsExist ind;
  dcl-s l_cursorPosition int(5);
  
  p_subfileRecordNumber = p_savedRecordNumber;
  l_cursorPosition = p_savedRecordNumber + 1;
  l_recordCounter = 0;
  OPT01 = 0;
  SflNxtChg = *OFF;
  
  // Set current record values
  coid = p_savedCode;
  countr = p_savedDesc;
  
  // Load records into subfile
  l_moreRecordsExist = not p_sflend;
  dow l_moreRecordsExist and l_recordCounter < 20;
    p_subfileRecordNumber = p_subfileRecordNumber + 1;
    l_recordCounter = l_recordCounter + 1;
    write SFL01;
    
    // Fetch next record
    if not p_bydesc;
      exec sql
        FETCH C_COUNTRY_BY_CODE INTO :countryRec.coid, :countryRec.countr;
    else;
      exec sql
        FETCH C_COUNTRY_BY_DESC INTO :countryRec.coid, :countryRec.countr;
    endif;
    
    // Check if we reached end of file
    l_moreRecordsExist = (SQLCODE = 0);
    SflEnd = not l_moreRecordsExist;
    
    // Update current record values if we have more records
    if l_moreRecordsExist;
      coid = countryRec.coid;
      countr = countryRec.countr;
    endif;
  enddo;
  
  // Save current record values
  p_newSavedCode = coid;
  p_newSavedDesc = countr;
  p_newSavedRecordNumber = p_subfileRecordNumber;
  
  return DISPLAY_STEP;
end-proc;

//=============================================
// Display Subfile
//=============================================
dcl-proc displaySubfile;
  dcl-pi *n char(3);
    p_savedRecordNumber int(5) const;
    p_f8KeyPressed ind;
    p_cursorPosition int(5);
  end-pi;
  
  sfldsp = p_savedRecordNumber > 0;
  sfldspctl = *on;
  write KEY01;
  exfmt CTL01;
  p_f8KeyPressed = CF08;
  p_cursorPosition = LRRN;
  
  return PROCESS_KEYS_STEP;
end-proc;

//=============================================
// Process Command Keys
//=============================================
dcl-proc processCommandKeys;
  dcl-pi *n char(3);
    p_exit ind const;
    p_cancel ind const;
    p_pageDown ind const;
  end-pi;
  
  select;
  when p_exit;
    return ' ';
  when p_cancel;
    return ' ';
  when p_pageDown;
    return LOAD_STEP;
  other;
    return CHECK_SELECTIONS_STEP;
  endsl;
end-proc;

//=============================================
// Check Subfile Selections
//=============================================
dcl-proc checkSubfileSelections;
  dcl-pi *n char(3);
    p_f8KeyPressed ind const;
    p_selectionMade ind;
    p_optionSelected ind;
    p_errorFound ind;
    p_cursorPosition int(5);
  end-pi;
  
  // SET FLAG SELECTION MADE OFF
  p_selectionMade = *OFF;
  // SET FLAG OPTION  MADE OFF
  p_optionSelected = *OFF;
  // SET FLAG ERROR   MADE OFF
  p_errorFound = *OFF;
  
  readc(E) SFL01;
  SflNxtChg = *ON;
  
  dow not %error and not %eof;
    select;
    when OPT01 = 0;
      // NO ERROR
    when OPT01 <> 1;
      p_optionSelected = *ON;
      dspatrRi = *on;
      InvalidOpt = *on;
      if p_errorFound = *OFF;
        p_cursorPosition = subfileRecordNumber;
        p_errorFound = *ON;
      endif;
    //OPTION = 1 BUT SELECTION ALREADY MADE
    when p_selectionMade = *ON;
      dspatrRi = *on;
      OneSelect = *on;
      if p_errorFound = *OFF;
        p_cursorPosition = subfileRecordNumber;
        p_errorFound = *ON;
      endif;
    other;
      //OPTION = 1
      p_selectionMade = *ON;
      p_optionSelected = *ON;
    endsl;
    
    update SFL01;
    dspatrRi = *off;
    readc SFL01;
  enddo;
  
  select;
  when OPTC1 <> 8 and OPTC1 <> 0;
    InvalidOptC = *ON;
    return DISPLAY_STEP;
  when p_selectionMade = *ON and OPTC1 <> 0;
    NotAvail = *ON;
    return DISPLAY_STEP;
  when p_optionSelected = *ON and p_f8KeyPressed = *ON;
    return DISPLAY_STEP;
  other;
    return PROCESS_ACTION_STEP;
  endsl;
end-proc;

//=============================================
// Process Subfile Actions
//=============================================
dcl-proc processSubfileActions;
  dcl-pi *n varchar(3);
    p_f8KeyPressed ind const;
    p_bydesc ind;
    p_OPTC1 int(5) const;
    searchByCode like(coid);
    searchByDesc like(countr);
  end-pi;
  
  dcl-s l_selectedCountry like(coid);
  
  select;
  when p_f8KeyPressed;
    p_bydesc = not p_bydesc;
    if p_bydesc;
      clear searchByDesc;
    else;
      clear searchByCode;
    endif;
    return PREPARE_STEP;
  when p_OPTC1 = 8;
    if not p_bydesc;
      searchByCode = POSCOD;  // Position code from display file
    else;
      searchByDesc = POSDES;  // Position description from display file
    endif;
    return PREPARE_STEP;
  other;
    readc(E) SFL01;
    dow not %error and not %eof;
      if OPT01 = 1;
        return coid;  // Return selected country code
      endif;
      readc SFL01;
    enddo;
    return DISPLAY_STEP;
  endsl;
end-proc;
