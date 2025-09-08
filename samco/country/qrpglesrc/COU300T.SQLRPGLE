**FREE
/////////////////////////////////////////////////////////////////////////
// %TEXT Unit Tests for Country Functions
/////////////////////////////////////////////////////////////////////////

ctl-opt actgrp(*caller) bnddir('RPGUNIT');

/copy RPGUNIT1,TESTCASE
/copy qprotosrc,COUNTRY

// Procedure prototypes for the procedures to test
dcl-pr GetCountryName varchar(50);
  countryId char(2) value;
end-pr;

dcl-pr GetCountryIso3 char(3);
  countryId char(2) value;
end-pr;

dcl-pr ExistCountry ind;
  countryId char(2) value;
end-pr;

// Test data
dcl-c TEST_COUNTRY_ID_1 'US';
dcl-c TEST_COUNTRY_NAME_1 'United States';
dcl-c TEST_COUNTRY_ISO_1 'USA';

dcl-c TEST_COUNTRY_ID_2 'CA';
dcl-c TEST_COUNTRY_NAME_2 'Canada';
dcl-c TEST_COUNTRY_ISO_2 'CAN';

dcl-c TEST_COUNTRY_ID_3 'MX';
dcl-c TEST_COUNTRY_NAME_3 'Mexico';
dcl-c TEST_COUNTRY_ISO_3 'MEX';

dcl-c NONEXISTENT_COUNTRY_ID 'ZZ';

// Main test procedure
dcl-proc RUNTESTS export;
  dcl-pi *n;
  end-pi;
  
  // Run all tests
  setUp();
  
  testGetCountryName();
  testGetCountryIso3();
  testExistCountry();
  
  tearDown();
end-proc;

// Set up test data
dcl-proc setUp;
  // Clean up any existing test data first
  tearDown();
  
  // Insert test data
  exec sql
    INSERT INTO COUNTRY (COID, COUNTR, COISO)
    VALUES (:TEST_COUNTRY_ID_1, :TEST_COUNTRY_NAME_1, :TEST_COUNTRY_ISO_1);
    
  exec sql
    INSERT INTO COUNTRY (COID, COUNTR, COISO)
    VALUES (:TEST_COUNTRY_ID_2, :TEST_COUNTRY_NAME_2, :TEST_COUNTRY_ISO_2);
    
  exec sql
    INSERT INTO COUNTRY (COID, COUNTR, COISO)
    VALUES (:TEST_COUNTRY_ID_3, :TEST_COUNTRY_NAME_3, :TEST_COUNTRY_ISO_3);
    
  // Verify test data was inserted correctly
  assertSqlSuccess('Failed to insert test data');
end-proc;

// Clean up test data
dcl-proc tearDown;
  exec sql
    DELETE FROM COUNTRY
    WHERE COID IN (:TEST_COUNTRY_ID_1, :TEST_COUNTRY_ID_2, :TEST_COUNTRY_ID_3);
    
  // We don't assert here because the table might not exist yet
end-proc;

// Test GetCountryName procedure
dcl-proc testGetCountryName;
  dcl-s result varchar(50);
  
  // Test with existing country ID
  result = GetCountryName(TEST_COUNTRY_ID_1);
  assertEqual(TEST_COUNTRY_NAME_1: result: 'GetCountryName failed for US');
  
  result = GetCountryName(TEST_COUNTRY_ID_2);
  assertEqual(TEST_COUNTRY_NAME_2: result: 'GetCountryName failed for CA');
  
  result = GetCountryName(TEST_COUNTRY_ID_3);
  assertEqual(TEST_COUNTRY_NAME_3: result: 'GetCountryName failed for MX');
  
  // Test with non-existent country ID
  result = GetCountryName(NONEXISTENT_COUNTRY_ID);
  assertEqual('': result: 'GetCountryName should return empty string for non-existent country');
end-proc;

// Test GetCountryIso3 procedure
dcl-proc testGetCountryIso3;
  dcl-s result char(3);
  
  // Test with existing country ID
  result = GetCountryIso3(TEST_COUNTRY_ID_1);
  assertEqual(TEST_COUNTRY_ISO_1: result: 'GetCountryIso3 failed for US');
  
  result = GetCountryIso3(TEST_COUNTRY_ID_2);
  assertEqual(TEST_COUNTRY_ISO_2: result: 'GetCountryIso3 failed for CA');
  
  result = GetCountryIso3(TEST_COUNTRY_ID_3);
  assertEqual(TEST_COUNTRY_ISO_3: result: 'GetCountryIso3 failed for MX');
  
  // Test with non-existent country ID
  result = GetCountryIso3(NONEXISTENT_COUNTRY_ID);
  assertEqual('': result: 'GetCountryIso3 should return empty string for non-existent country');
end-proc;

// Test ExistCountry procedure
dcl-proc testExistCountry;
  dcl-s result ind;
  
  // Test with existing country ID
  result = ExistCountry(TEST_COUNTRY_ID_1);
  assertTrue(result: 'ExistCountry should return true for US');
  
  result = ExistCountry(TEST_COUNTRY_ID_2);
  assertTrue(result: 'ExistCountry should return true for CA');
  
  result = ExistCountry(TEST_COUNTRY_ID_3);
  assertTrue(result: 'ExistCountry should return true for MX');
  
  // Test with non-existent country ID
  result = ExistCountry(NONEXISTENT_COUNTRY_ID);
  assertFalse(result: 'ExistCountry should return false for non-existent country');
end-proc;

// Helper procedure to assert SQL success
dcl-proc assertSqlSuccess;
  dcl-pi *n;
    message varchar(100) const;
  end-pi;
  
  if SQLSTT <> '00000' and SQLSTT <> '01000';
    fail(message + ' (SQLSTT: ' + SQLSTT + ')');
  endif;
end-proc;