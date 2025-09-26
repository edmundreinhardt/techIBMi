**free
//%METADATA                                                                          
// %TEXT Functions Country                                                           
//%EMETADATA                                                                         
ctl-opt nomain;

dcl-f COUNTRY disk keyed usropn;

/copy COUNTRY

dcl-pr chainCOUNTRY;
  P_COID char(2) value;
end-pr;

//=============================================
// Get country name from country code
//=============================================
dcl-proc GetCountryName export;
  dcl-pi *n like(countr);
    P_COID char(2) value;
  end-pi;
  
  chainCOUNTRY(P_COID);
  return COUNTR;
end-proc;

//=============================================
// Get ISO3 code from country code
//=============================================
dcl-proc GetCountryIso3 export;
  dcl-pi *n like(coiso);
    P_COID char(2) value;
  end-pi;
  
  chainCOUNTRY(P_COID);
  return COISO;
end-proc;

//=============================================
// Check if country code exists
//=============================================
dcl-proc ExistCountry export;
  dcl-pi *n ind;
    P_COID char(2) value;
  end-pi;
  
  chainCOUNTRY(P_COID);
  return %found(country);
end-proc;

//=============================================
// Chain to COUNTRY file
//=============================================
dcl-proc chainCOUNTRY;
  dcl-pi *n;
    P_COID char(2) value;
  end-pi;
  
  if not %open(COUNTRY);
    open COUNTRY;
  endif;
  
  if P_COID <> COID;
    clear FCOUN;
    chain (P_COID) COUNTRY;
  endif;
end-proc;

//=============================================
// Close COUNTRY file
//=============================================
dcl-proc closeCOUNTRY;
  dcl-pi *n;
  end-pi;
  
  if %open(COUNTRY);
    close COUNTRY;
  endif;
end-proc;
