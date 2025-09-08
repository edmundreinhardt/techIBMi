**FREE
/////////////////////////////////////////////////////////////////////////
// %TEXT Functions Country
/////////////////////////////////////////////////////////////////////////

ctl-opt nomain;

// SQL Definitions
exec sql set option commit=*none, datfmt=*iso, closqlcsr=*endmod;

/copy qprotosrc,COUNTRY

// Procedure prototype for retrieving country by ID
dcl-pr retrieveCountryById;
  countryId char(2) value;
end-pr;

// Country data structure
dcl-ds countryData qualified;
  id char(2);
  name varchar(50);
  isoCode char(3);
end-ds;

//=============================================
// Get country name by country ID
dcl-proc GetCountryName export;
  dcl-pi *n like(countryData.name);
    countryId char(2) value;
  end-pi;
  
  retrieveCountryById(countryId);
  return countryData.name;
end-proc;

//=============================================
// Get country ISO code by country ID
dcl-proc GetCountryIso3 export;
  dcl-pi *n like(countryData.isoCode);
    countryId char(2) value;
  end-pi;
  
  retrieveCountryById(countryId);
  return countryData.isoCode;
end-proc;

//=============================================
// Check if country exists by country ID
dcl-proc ExistCountry export;
  dcl-pi *n ind;
    countryId char(2) value;
  end-pi;
  
  dcl-s recordExists ind;
  
  exec sql
    SELECT 1
    INTO :recordExists
    FROM COUNTRY
    WHERE COID = :countryId;
    
  return SQLSTT = '00000' or SQLSTT = '01000';
end-proc;

// Retrieve country data by ID
dcl-proc retrieveCountryById;
  dcl-pi *n;
    countryId char(2) value;
  end-pi;
  
  clear countryData;
  
  exec sql
    SELECT COID, COUNTR, COISO
    INTO :countryData.id, :countryData.name, :countryData.isoCode
    FROM COUNTRY
    WHERE COID = :countryId;
end-proc;