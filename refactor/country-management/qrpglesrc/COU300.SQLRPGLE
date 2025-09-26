**free
//%METADATA                                                                          
// %TEXT Functions Country                                                           
//%EMETADATA                                                                         
ctl-opt nomain;
ctl-opt datfmt(*iso) timfmt(*iso) decedit('0.');
ctl-opt option(*srcstmt:*nodebugio);
ctl-opt thread(*concurrent);

/copy COUNTRY

// Country record structure
dcl-ds countryRec qualified;
  coid char(2);
  countr char(30);
  coiso char(3);
end-ds;

//=============================================
// Get country name from country code
//=============================================
dcl-proc GetCountryName export;
  dcl-pi *n like(countryRec.countr);
    P_COID char(2) value;
  end-pi;
  
  clear countryRec;
  
  exec sql
    SELECT COUNTR INTO :countryRec.countr
    FROM COUNTRY
    WHERE COID = :P_COID;
  
  if SQLCODE <> 0;
    // If not found, return blank
    return '';
  endif;
  
  return countryRec.countr;
end-proc;

//=============================================
// Get ISO3 code from country code
//=============================================
dcl-proc GetCountryIso3 export;
  dcl-pi *n like(countryRec.coiso);
    P_COID char(2) value;
  end-pi;
  
  clear countryRec;
  
  exec sql
    SELECT COISO INTO :countryRec.coiso
    FROM COUNTRY
    WHERE COID = :P_COID;
  
  if SQLCODE <> 0;
    // If not found, return blank
    return '';
  endif;
  
  return countryRec.coiso;
end-proc;

//=============================================
// Check if country code exists
//=============================================
dcl-proc ExistCountry export;
  dcl-pi *n ind;
    P_COID char(2) value;
  end-pi;
  
  dcl-s exists int(5);
  
  exec sql
    SELECT COUNT(*) INTO :exists
    FROM COUNTRY
    WHERE COID = :P_COID;
  
  if SQLCODE <> 0;
    return *off;
  endif;
  
  return exists > 0;
end-proc;

