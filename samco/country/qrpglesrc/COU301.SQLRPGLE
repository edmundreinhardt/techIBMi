**FREE
/////////////////////////////////////////////////////////////////////////
// %TEXT Select a Country code
/////////////////////////////////////////////////////////////////////////

ctl-opt nomain;

// SQL Definitions
exec sql set option commit=*none, datfmt=*iso, closqlcsr=*endmod;

dcl-f cou301d workstn infds(INFO) sfile(SFL01:RRN01) indds(indds);

dcl-ds INFO;
  LRRN int(5) pos(378);
end-ds;

/copy qprotosrc,country

dcl-ds indds;
  help ind pos(1);
  exit ind pos(3);
  prompt ind pos(4);
  refresh ind pos(5);
  create ind pos(6);
  cf08 ind pos(8);
  cancel ind pos(12);
  morekeys ind pos(24);
  pagedown ind pos(25);
  sflclr ind pos(30);
  sfldsp ind pos(31);
  sfldspctl ind pos(32);
  sflnxtchg ind pos(33);
  dspatrri ind pos(34);
  InvalidOpt ind pos(35);
  OneSelect ind pos(36);
  bydesc ind pos(40);
  InvalidOptC ind pos(41);
  NotAvail ind pos(42);
  sflend ind pos(80);
end-ds;

dcl-s rrn01 int(5);

dcl-c prp 'prp';
dcl-c lod 'lod';
dcl-c dsp 'dsp';
dcl-c key 'key';
dcl-c chk 'chk';
dcl-c chkctl 'chc';
dcl-c actctl 'acc';
dcl-c act 'act';

// SQL Cursor for country data
exec sql declare country_cursor cursor for
  select COID, COUNTR, COISO
  from COUNTRY
  where COID >= :keycod
  order by COID;

// SQL Cursor for country data by name
exec sql declare countr1_cursor cursor for
  select COID, COUNTR, COISO
  from COUNTRY
  where COUNTR >= :keydes
  order by COUNTR;

//=============================================
dcl-proc sltcountry export;
  dcl-pi *n like(coid);
    pcod like(coid);
  end-pi;
  
  dcl-s dft like(coid);
  dcl-s step01 char(3) inz(prp);
  dcl-s in08 ind;
  dcl-s sts01 ind;
  dcl-s rrs01 int(5);
  dcl-s teller int(5);
  dcl-s err01 ind;
  dcl-s slt01 ind;
  dcl-s keycod like(coid);
  dcl-s savcod like(coid);
  dcl-s pdes like(countr);
  dcl-s keydes like(countr);
  dcl-s savdes like(countr);
  
  // SQL work variables
  dcl-s sqlCOID like(coid);
  dcl-s sqlCOUNTR like(countr) varying;
  dcl-s sqlCOISO like(coiso);
  
  if not %open(cou301d);
    open cou301d;
  endif;
  keycod = pcod;
  dft = pcod;
  bydesc = *off;
  dow step01 <> ' ';
    select;
    when step01 = prp;
      s01prp();
    when step01 = lod;
      s01lod();
    when step01 = dsp;
      s01dsp();
    when step01 = key;
      s01key();
    when step01 = chk;
      s01chk();
    when step01 = act;
      s01act();
    endsl;
  enddo;
  return dft;
  
  //--- Clear Subfile -----------------------------------------------------
  dcl-proc s01prp;
    RRS01 = 0;
    clear CTL01;
    sflclr = *on;
    sfldsp = *off;
    sfldspctl = *off;
    write CTL01;
    sflclr = *off;
    
    // Close any open cursors
    exec sql close country_cursor;
    exec sql close countr1_cursor;
    
    if not bydesc;
      // Open cursor for access by code
      exec sql open country_cursor;
      // Fetch first record
      exec sql fetch country_cursor into :sqlCOID, :sqlCOUNTR, :sqlCOISO;
      sflend = (SQLSTT <> '00000' and SQLSTT <> '01000');
    else;
      // Open cursor for access by name
      exec sql open countr1_cursor;
      // Fetch first record
      exec sql fetch countr1_cursor into :sqlCOID, :sqlCOUNTR, :sqlCOISO;
      sflend = (SQLSTT <> '00000' and SQLSTT <> '01000');
    endif;
    
    // Set fields for display
    coid = sqlCOID;
    countr = sqlCOUNTR;
    coiso = sqlCOISO;
    
    SAVCOD = coid;
    SAVDES = countr;
    Step01 = lod;
  end-proc;
  
  //--- Load Subfile -----------------------------------------------------
  dcl-proc S01lod;
    RRN01 = RRS01;
    RRB01 = RRS01 + 1;
    TELLER = 0;
    OPT01 = 0;
    SflNxtChg = *OFF;
    coid = SAVCOD;
    countr = SAVDES;
    coiso = sqlCOISO;
    
    dow not sflend and TELLER < 20;
      RRN01 = RRN01 + 1;
      TELLER = TELLER + 1;
      write SFL01;
      
      if not bydesc;
        // Fetch next record by code
        exec sql fetch country_cursor into :sqlCOID, :sqlCOUNTR, :sqlCOISO;
      else;
        // Fetch next record by name
        exec sql fetch countr1_cursor into :sqlCOID, :sqlCOUNTR, :sqlCOISO;
      endif;
      
      // Set fields for display
      coid = sqlCOID;
      countr = sqlCOUNTR;
      coiso = sqlCOISO;
      
      SflEnd = (SQLSTT <> '00000' and SQLSTT <> '01000');
    enddo;
    
    SAVCOD = coid;
    SAVDES = countr;
    RRS01 = RRN01;
    Step01 = dsp;
  end-proc;
  
  //--- Display Subfile --------------------------------------------------
  dcl-proc S01dsp;
    sfldsp = rrs01 > 0;
    sfldspctl = *on;
    write KEY01;
    exfmt CTL01;
    IN08 = CF08;
    RRB01 = LRRN;
    Step01 = key;
  end-proc;
  
  //--- Command Keys -----------------------------------------------------
  dcl-proc S01key;
    select;
    when exit;
      step01 = ' ';
    when cancel;
      Step01 = ' ';
    when PageDown;
      Step01 = lod;
    other;
      Step01 = chk;
    endsl;
  end-proc;
  
  //--- Check Subfile ----------------------------------------------------
  dcl-proc S01chk;
    // SET FLAG SELECTION MADE OFF
    SLT01 = *OFF;
    // SET FLAG OPTION  MADE OFF
    STS01 = *OFF;
    // SET FLAG ERROR   MADE OFF
    ERR01 = *OFF;
    Step01 = act;
    readc(E) SFL01;
    SflNxtChg = *ON;
    dow not %error and not %eof;
      select;
      when OPT01 = 0;
        // NO ERROR
      when OPT01 <> 1;
        STS01 = *ON;
        Step01 = dsp;
        dspatrRi = *on;
        InvalidOpt = *on;
        if ERR01 = *OFF;
          RRB01 = RRN01;
          ERR01 = *ON;
        endif;
        //OPTION = 1 BUT SELECTION ALREADY MADE
      when SLT01 = *ON;
        Step01 = dsp;
        dspatrRi = *on;
        OneSelect = *on;
        if ERR01 = *OFF;
          RRB01 = RRN01;
          ERR01 = *ON;
        endif;
      other;
        //OPTION = 1
        SLT01 = *ON;
        STS01 = *ON;
      endsl;
      update SFL01;
      dspatrRi = *off;
      readc SFL01;
    enddo;
    select;
    when OPTC1 <> 8 and OPTC1 <> 0;
      InvalidOptC = *ON;
      Step01 = dsp;
    when SLT01 = *ON and OPTC1 <> 0;
      NotAvail = *ON;
      Step01 = dsp;
    when STS01 = *ON and IN08 = *ON;
      Step01 = dsp;
    endsl;
  end-proc;
  
  //--- Write Subfile ----------------------------------------------------
  dcl-proc S01act;
    Step01 = dsp;
    select;
    when IN08;
      Step01 = prp;
      bydesc = not bydesc;
      if bydesc;
        clear KEYdes;
      else;
        clear KEYcod;
      endif;
    when OPTC1 = 8;
      Step01 = prp;
      if not bydesc;
        KEYCOD = POSCOD;
      else;
        KEYDES = POSDES;
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
  end-proc;
