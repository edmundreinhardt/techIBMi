**FREE
// VEHCRUDTST - Test suite for VEHCRUD service program
// This module contains RPGUNIT test cases for the VEHCRUD service program

CTL-OPT DFTACTGRP(*NO) ACTGRP(*CALLER);
CTL-OPT DATFMT(*ISO) TIMFMT(*ISO);
CTL-OPT DECEDIT('0.');
CTL-OPT ALWNULL(*USRCTL);
CTL-OPT BNDDIR('VEHBND');

/COPY QRPGLESRC,VEHCRUD_H
/COPY QINCLUDE,RPGUNIT_H

// Test data
DCL-DS TestVehicleDS LIKEDS(VehicleDS) INZ;
DCL-DS TestVehicleFilterDS LIKEDS(VehicleFilterDS) INZ;
DCL-DS TestVehicleHistoryDS LIKEDS(VehicleHistoryDS) INZ;

// Global variables
DCL-S TestVehicleId INT(10);
DCL-S TestUserId VARCHAR(10);

// Setup procedure - runs before each test
DCL-PROC SETUP;
  // Initialize test data
  TestVehicleDS.Make = 'Toyota';
  TestVehicleDS.Model = 'Camry';
  TestVehicleDS.Trim = 'LE';
  TestVehicleDS.Year = 2020;
  TestVehicleDS.VIN = 'TEST' + %CHAR(%TIMESTAMP());
  TestVehicleDS.Color = 'Blue';
  TestVehicleDS.Odometer = 25000;
  TestVehicleDS.ConditionRating = 8;
  TestVehicleDS.AcquisitionPrice = 15000.00;
  TestVehicleDS.AskingPrice = 18500.00;
  TestVehicleDS.DateAcquired = %DATE();
  TestVehicleDS.Status = 'AVAILABLE';
  TestVehicleDS.Notes = 'Test vehicle';
  
  TestUserId = 'TESTUSER';
  
  // Clean up any test data from previous runs
  EXEC SQL
    DELETE FROM VEHICLES
    WHERE NOTES = 'Test vehicle';
    
  EXEC SQL
    DELETE FROM VEHICLE_HISTORY
    WHERE NOTES = 'Test vehicle';
END-PROC;

// Teardown procedure - runs after each test
DCL-PROC TEARDOWN;
  // Clean up test data
  EXEC SQL
    DELETE FROM VEHICLES
    WHERE NOTES = 'Test vehicle';
    
  EXEC SQL
    DELETE FROM VEHICLE_HISTORY
    WHERE NOTES = 'Test vehicle';
END-PROC;

// Test AddVehicle procedure
DCL-PROC TEST_ADD_VEHICLE EXPORT;
  DCL-S Result INT(10);
  DCL-DS VehicleData LIKEDS(VehicleDS);
  
  // Add a test vehicle
  Result = AddVehicle(TestVehicleDS : TestUserId);
  
  // Verify result is greater than 0 (vehicle ID)
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  TestVehicleId = Result;
  
  // Verify vehicle was added to database
  Result = GetVehicleById(TestVehicleId : VehicleData);
  
  assert(Result = VEHCRUD_SUCCESS : 'GetVehicleById should succeed');
  assert(VehicleData.Make = TestVehicleDS.Make : 'Make should match');
  assert(VehicleData.Model = TestVehicleDS.Model : 'Model should match');
  assert(VehicleData.Year = TestVehicleDS.Year : 'Year should match');
  assert(VehicleData.VIN = TestVehicleDS.VIN : 'VIN should match');
  
  // Verify history entry was created
  DCL-S HistoryCount INT(10);
  DCL-DS HistoryArray LIKEDS(VehicleHistoryDS) DIM(10);
  
  HistoryCount = GetVehicleHistory(TestVehicleId : HistoryArray : HistoryCount);
  
  assert(HistoryCount > 0 : 'History entry should be created');
  assert(HistoryArray(1).EventType = 'ADDED' : 'Event type should be ADDED');
END-PROC;

// Test GetVehicleById procedure
DCL-PROC TEST_GET_VEHICLE_BY_ID EXPORT;
  DCL-S Result INT(10);
  DCL-DS VehicleData LIKEDS(VehicleDS);
  
  // Add a test vehicle
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  TestVehicleId = Result;
  
  // Get the vehicle by ID
  Result = GetVehicleById(TestVehicleId : VehicleData);
  
  // Verify result
  assert(Result = VEHCRUD_SUCCESS : 'GetVehicleById should succeed');
  assert(VehicleData.VehicleId = TestVehicleId : 'Vehicle ID should match');
  assert(VehicleData.Make = TestVehicleDS.Make : 'Make should match');
  assert(VehicleData.Model = TestVehicleDS.Model : 'Model should match');
  
  // Test with invalid ID
  Result = GetVehicleById(-1 : VehicleData);
  assert(Result = VEHCRUD_NOT_FOUND : 'GetVehicleById should return NOT_FOUND for invalid ID');
END-PROC;

// Test UpdateVehicle procedure
DCL-PROC TEST_UPDATE_VEHICLE EXPORT;
  DCL-S Result INT(10);
  DCL-DS VehicleData LIKEDS(VehicleDS);
  DCL-DS UpdatedData LIKEDS(VehicleDS);
  
  // Add a test vehicle
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  TestVehicleId = Result;
  
  // Get the vehicle
  Result = GetVehicleById(TestVehicleId : VehicleData);
  assert(Result = VEHCRUD_SUCCESS : 'GetVehicleById should succeed');
  
  // Update the vehicle
  VehicleData.Color = 'Red';
  VehicleData.Odometer = 26000;
  VehicleData.AskingPrice = 19000.00;
  
  Result = UpdateVehicle(VehicleData : TestUserId);
  assert(Result = VEHCRUD_SUCCESS : 'UpdateVehicle should succeed');
  
  // Verify the update
  Result = GetVehicleById(TestVehicleId : UpdatedData);
  assert(Result = VEHCRUD_SUCCESS : 'GetVehicleById should succeed');
  assert(UpdatedData.Color = 'Red' : 'Color should be updated');
  assert(UpdatedData.Odometer = 26000 : 'Odometer should be updated');
  assert(UpdatedData.AskingPrice = 19000.00 : 'Asking price should be updated');
  
  // Verify history entry for price change
  DCL-S HistoryCount INT(10);
  DCL-DS HistoryArray LIKEDS(VehicleHistoryDS) DIM(10);
  
  HistoryCount = GetVehicleHistory(TestVehicleId : HistoryArray : HistoryCount);
  
  assert(HistoryCount >= 2 : 'History entries should be created');
  // The most recent entry should be the price change
  assert(HistoryArray(1).EventType = 'PRICE_CHANGE' : 'Event type should be PRICE_CHANGE');
END-PROC;

// Test UpdateVehicleStatus procedure
DCL-PROC TEST_UPDATE_VEHICLE_STATUS EXPORT;
  DCL-S Result INT(10);
  DCL-DS VehicleData LIKEDS(VehicleDS);
  
  // Add a test vehicle
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  TestVehicleId = Result;
  
  // Update status to ON_HOLD
  Result = UpdateVehicleStatus(TestVehicleId : 'ON_HOLD' : *NULL : TestUserId : 'Test status change');
  assert(Result = VEHCRUD_SUCCESS : 'UpdateVehicleStatus should succeed');
  
  // Verify the status update
  Result = GetVehicleById(TestVehicleId : VehicleData);
  assert(Result = VEHCRUD_SUCCESS : 'GetVehicleById should succeed');
  assert(VehicleData.Status = 'ON_HOLD' : 'Status should be updated to ON_HOLD');
  
  // Update status to SOLD
  DCL-D SoldDate DATE INZ(%DATE());
  Result = UpdateVehicleStatus(TestVehicleId : 'SOLD' : SoldDate : TestUserId : 'Test sold');
  assert(Result = VEHCRUD_SUCCESS : 'UpdateVehicleStatus should succeed');
  
  // Verify the status update and sold date
  Result = GetVehicleById(TestVehicleId : VehicleData);
  assert(Result = VEHCRUD_SUCCESS : 'GetVehicleById should succeed');
  assert(VehicleData.Status = 'SOLD' : 'Status should be updated to SOLD');
  assert(VehicleData.DateSold = SoldDate : 'Sold date should be set');
  
  // Verify history entries
  DCL-S HistoryCount INT(10);
  DCL-DS HistoryArray LIKEDS(VehicleHistoryDS) DIM(10);
  
  HistoryCount = GetVehicleHistory(TestVehicleId : HistoryArray : HistoryCount);
  
  assert(HistoryCount >= 3 : 'History entries should be created');
  // The most recent entry should be the status change to SOLD
  assert(HistoryArray(1).EventType = 'STATUS_CHANGE' : 'Event type should be STATUS_CHANGE');
  assert(HistoryArray(1).NewStatus = 'SOLD' : 'New status should be SOLD');
END-PROC;

// Test DeleteVehicle procedure
DCL-PROC TEST_DELETE_VEHICLE EXPORT;
  DCL-S Result INT(10);
  DCL-DS VehicleData LIKEDS(VehicleDS);
  
  // Add a test vehicle
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  TestVehicleId = Result;
  
  // Delete the vehicle
  Result = DeleteVehicle(TestVehicleId : TestUserId);
  assert(Result = VEHCRUD_SUCCESS : 'DeleteVehicle should succeed');
  
  // Verify the vehicle is deleted
  Result = GetVehicleById(TestVehicleId : VehicleData);
  assert(Result = VEHCRUD_NOT_FOUND : 'Vehicle should not be found after deletion');
END-PROC;

// Test ListVehicles procedure with all filter criteria
DCL-PROC TEST_LIST_VEHICLES EXPORT;
  DCL-S Result INT(10);
  DCL-DS VehicleArray LIKEDS(VehicleDS) DIM(20);
  DCL-S VehicleCount INT(10);
  DCL-DS Filter LIKEDS(VehicleFilterDS);
  DCL-S VehicleId1 INT(10);
  DCL-S VehicleId2 INT(10);
  DCL-S VehicleId3 INT(10);
  DCL-S VehicleId4 INT(10);
  DCL-S VehicleId5 INT(10);
  DCL-S VehicleId6 INT(10);
  DCL-D Today DATE INZ(%DATE());
  DCL-D Yesterday DATE INZ(%DATE() - %DAYS(1));
  DCL-D LastWeek DATE INZ(%DATE() - %DAYS(7));
  DCL-D LastMonth DATE INZ(%DATE() - %DAYS(30));
  
  // Add multiple test vehicles with different attributes for filtering tests
  
  // Vehicle 1: Toyota Camry 2020, Available, Acquired today, $18,500
  TestVehicleDS.Make = 'Toyota';
  TestVehicleDS.Model = 'Camry';
  TestVehicleDS.Year = 2020;
  TestVehicleDS.VIN = 'TEST1' + %CHAR(%TIMESTAMP());
  TestVehicleDS.DateAcquired = Today;
  TestVehicleDS.Status = 'AVAILABLE';
  TestVehicleDS.AskingPrice = 18500.00;
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  VehicleId1 = Result;
  
  // Vehicle 2: Honda Accord 2019, Available, Acquired last week, $17,000
  TestVehicleDS.Make = 'Honda';
  TestVehicleDS.Model = 'Accord';
  TestVehicleDS.Year = 2019;
  TestVehicleDS.VIN = 'TEST2' + %CHAR(%TIMESTAMP());
  TestVehicleDS.DateAcquired = LastWeek;
  TestVehicleDS.Status = 'AVAILABLE';
  TestVehicleDS.AskingPrice = 17000.00;
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  VehicleId2 = Result;
  
  // Vehicle 3: Toyota Corolla 2021, On Hold, Acquired last month, $16,000
  TestVehicleDS.Make = 'Toyota';
  TestVehicleDS.Model = 'Corolla';
  TestVehicleDS.Year = 2021;
  TestVehicleDS.VIN = 'TEST3' + %CHAR(%TIMESTAMP());
  TestVehicleDS.DateAcquired = LastMonth;
  TestVehicleDS.Status = 'ON_HOLD';
  TestVehicleDS.AskingPrice = 16000.00;
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  VehicleId3 = Result;
  
  // Vehicle 4: Ford F-150 2018, Sold yesterday, Acquired last month, $25,000
  TestVehicleDS.Make = 'Ford';
  TestVehicleDS.Model = 'F-150';
  TestVehicleDS.Year = 2018;
  TestVehicleDS.VIN = 'TEST4' + %CHAR(%TIMESTAMP());
  TestVehicleDS.DateAcquired = LastMonth;
  TestVehicleDS.Status = 'AVAILABLE';
  TestVehicleDS.AskingPrice = 25000.00;
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  VehicleId4 = Result;
  
  // Update to SOLD status
  Result = UpdateVehicleStatus(VehicleId4 : 'SOLD' : Yesterday : TestUserId : 'Test sold');
  assert(Result = VEHCRUD_SUCCESS : 'UpdateVehicleStatus should succeed');
  
  // Vehicle 5: Chevrolet Malibu 2020, Available, Acquired last week, $19,500
  TestVehicleDS.Make = 'Chevrolet';
  TestVehicleDS.Model = 'Malibu';
  TestVehicleDS.Year = 2020;
  TestVehicleDS.VIN = 'TEST5' + %CHAR(%TIMESTAMP());
  TestVehicleDS.DateAcquired = LastWeek;
  TestVehicleDS.Status = 'AVAILABLE';
  TestVehicleDS.AskingPrice = 19500.00;
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  VehicleId5 = Result;
  
  // Vehicle 6: Honda Civic 2021, Sold today, Acquired last week, $21,000
  TestVehicleDS.Make = 'Honda';
  TestVehicleDS.Model = 'Civic';
  TestVehicleDS.Year = 2021;
  TestVehicleDS.VIN = 'TEST6' + %CHAR(%TIMESTAMP());
  TestVehicleDS.DateAcquired = LastWeek;
  TestVehicleDS.Status = 'AVAILABLE';
  TestVehicleDS.AskingPrice = 21000.00;
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  VehicleId6 = Result;
  
  // Update to SOLD status
  Result = UpdateVehicleStatus(VehicleId6 : 'SOLD' : Today : TestUserId : 'Test sold');
  assert(Result = VEHCRUD_SUCCESS : 'UpdateVehicleStatus should succeed');
  
  // Test 1: List all test vehicles
  Result = ListVehicles(*NULL : VehicleArray : VehicleCount);
  assert(Result >= 6 : 'ListVehicles should return at least 6 vehicles');
  
  // Test 2: Filter by Make
  Filter = *ALLX'00';
  Filter.Make = 'Toyota';
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 2 : 'ListVehicles should return at least 2 Toyota vehicles');
  assert(VehicleArray(1).Make = 'Toyota' : 'First vehicle should be Toyota');
  
  // Test 3: Filter by Model
  Filter = *ALLX'00';
  Filter.Model = 'Accord';
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 1 : 'ListVehicles should return at least 1 Accord vehicle');
  assert(VehicleArray(1).Model = 'Accord' : 'First vehicle should be Accord');
  
  // Test 4: Filter by Year range
  Filter = *ALLX'00';
  Filter.YearFrom = 2020;
  Filter.YearTo = 2021;
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 4 : 'ListVehicles should return at least 4 vehicles from 2020-2021');
  assert(VehicleArray(1).Year >= 2020 : 'First vehicle year should be >= 2020');
  assert(VehicleArray(1).Year <= 2021 : 'First vehicle year should be <= 2021');
  
  // Test 5: Filter by Status
  Filter = *ALLX'00';
  Filter.Status = 'AVAILABLE';
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 3 : 'ListVehicles should return at least 3 available vehicles');
  assert(VehicleArray(1).Status = 'AVAILABLE' : 'First vehicle should be available');
  
  Filter = *ALLX'00';
  Filter.Status = 'SOLD';
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 2 : 'ListVehicles should return at least 2 sold vehicles');
  assert(VehicleArray(1).Status = 'SOLD' : 'First vehicle should be sold');
  
  Filter = *ALLX'00';
  Filter.Status = 'ON_HOLD';
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 1 : 'ListVehicles should return at least 1 on-hold vehicle');
  assert(VehicleArray(1).Status = 'ON_HOLD' : 'First vehicle should be on hold');
  
  // Test 6: Filter by DateAcquired range
  Filter = *ALLX'00';
  Filter.DateAcquiredFrom = Today;
  Filter.DateAcquiredTo = Today;
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 1 : 'ListVehicles should return at least 1 vehicle acquired today');
  assert(VehicleArray(1).DateAcquired = Today : 'First vehicle should be acquired today');
  
  Filter = *ALLX'00';
  Filter.DateAcquiredFrom = LastWeek;
  Filter.DateAcquiredTo = Today;
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 4 : 'ListVehicles should return at least 4 vehicles acquired in the last week');
  
  // Test 7: Filter by DateSold range
  Filter = *ALLX'00';
  Filter.DateSoldFrom = Yesterday;
  Filter.DateSoldTo = Yesterday;
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 1 : 'ListVehicles should return at least 1 vehicle sold yesterday');
  
  Filter = *ALLX'00';
  Filter.DateSoldFrom = Yesterday;
  Filter.DateSoldTo = Today;
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 2 : 'ListVehicles should return at least 2 vehicles sold in the last 2 days');
  
  // Test 8: Filter by Price range
  Filter = *ALLX'00';
  Filter.PriceFrom = 20000.00;
  Filter.PriceTo = 30000.00;
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 2 : 'ListVehicles should return at least 2 vehicles priced $20,000-$30,000');
  assert(VehicleArray(1).AskingPrice >= 20000.00 : 'First vehicle price should be >= $20,000');
  assert(VehicleArray(1).AskingPrice <= 30000.00 : 'First vehicle price should be <= $30,000');
  
  // Test 9: Combined filters
  Filter = *ALLX'00';
  Filter.Make = 'Honda';
  Filter.YearFrom = 2020;
  Filter.Status = 'SOLD';
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result >= 1 : 'ListVehicles should return at least 1 Honda from 2020+ that is sold');
  assert(VehicleArray(1).Make = 'Honda' : 'First vehicle should be Honda');
  assert(VehicleArray(1).Year >= 2020 : 'First vehicle year should be >= 2020');
  assert(VehicleArray(1).Status = 'SOLD' : 'First vehicle should be sold');
  
  // Test 10: Filter with no matches
  Filter = *ALLX'00';
  Filter.Make = 'BMW';
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  assert(Result = 0 : 'ListVehicles should return 0 vehicles for non-existent make');
END-PROC;

// Test GetVehicleHistory procedure
DCL-PROC TEST_GET_VEHICLE_HISTORY EXPORT;
  DCL-S Result INT(10);
  DCL-DS HistoryArray LIKEDS(VehicleHistoryDS) DIM(10);
  DCL-S HistoryCount INT(10);
  
  // Add a test vehicle
  Result = AddVehicle(TestVehicleDS : TestUserId);
  assert(Result > 0 : 'AddVehicle should return a valid vehicle ID');
  TestVehicleId = Result;
  
  // Update status to create history
  Result = UpdateVehicleStatus(TestVehicleId : 'ON_HOLD' : *NULL : TestUserId : 'Test status change');
  assert(Result = VEHCRUD_SUCCESS : 'UpdateVehicleStatus should succeed');
  
  // Update price to create history
  DCL-DS VehicleData LIKEDS(VehicleDS);
  Result = GetVehicleById(TestVehicleId : VehicleData);
  assert(Result = VEHCRUD_SUCCESS : 'GetVehicleById should succeed');
  
  VehicleData.AskingPrice = 20000.00;
  Result = UpdateVehicle(VehicleData : TestUserId);
  assert(Result = VEHCRUD_SUCCESS : 'UpdateVehicle should succeed');
  
  // Get history
  Result = GetVehicleHistory(TestVehicleId : HistoryArray : HistoryCount);
  assert(Result >= 3 : 'GetVehicleHistory should return at least 3 history entries');
  
  // Verify history entries
  assert(HistoryArray(1).EventType = 'PRICE_CHANGE' : 'Most recent event should be PRICE_CHANGE');
  assert(HistoryArray(2).EventType = 'STATUS_CHANGE' : 'Second event should be STATUS_CHANGE');
  assert(HistoryArray(3).EventType = 'ADDED' : 'Third event should be ADDED');
  
  // Test with invalid vehicle ID
  Result = GetVehicleHistory(-1 : HistoryArray : HistoryCount);
  assert(Result = VEHCRUD_NOT_FOUND : 'GetVehicleHistory should return NOT_FOUND for invalid ID');
END-PROC;