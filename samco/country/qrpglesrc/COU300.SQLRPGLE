**FREE
/////////////////////////////////////////////////////////////////////////
// %TEXT Functions Country
/////////////////////////////////////////////////////////////////////////

ctl-opt nomain;

// SQL Definitions
exec sql set option commit=*none, datfmt=*iso, closqlcsr=*endmod;

/copy qprotosrc,COUNTRY

dcl-pr chainCOUNTRY;
  P_COID char(2) value;
end-pr;

dcl-ds FCOUN qualified;
  COID char(2);
  COUNTR varchar(50);
  COISO char(3);
end-ds;

//=============================================
dcl-proc GetCountryName export;
  dcl-pi *n like(FCOUN.countr);
    P_COID char(2) value;
  end-pi;
  
  chainCOUNTRY(P_COID);
  return FCOUN.COUNTR;
end-proc;

//=============================================
dcl-proc GetCountryIso3 export;
  dcl-pi *n like(FCOUN.coiso);
    P_COID char(2) value;
  end-pi;
  
  chainCOUNTRY(P_COID);
  return FCOUN.COISO;
end-proc;

//=============================================
dcl-proc ExistCountry export;
  dcl-pi *n ind;
    P_COID char(2) value;
  end-pi;
  
  dcl-s found ind;
  
  exec sql
    SELECT 1
    INTO :found
    FROM COUNTRY
    WHERE COID = :P_COID;
    
  return SQLSTT = '00000' or SQLSTT = '01000';
end-proc;

dcl-proc chainCOUNTRY;
  dcl-pi *n;
    P_COID char(2) value;
  end-pi;
  
  clear FCOUN;
  
  exec sql
    SELECT COID, COUNTR, COISO
    INTO :FCOUN.COID, :FCOUN.COUNTR, :FCOUN.COISO
    FROM COUNTRY
    WHERE COID = :P_COID;
end-proc;

// No need for closeCOUNTRY procedure with SQL