**FREE
// VEHBIZTST - Test suite for VEHBIZ service program
// This module contains RPGUNIT test cases for the VEHBIZ service program

CTL-OPT DFTACTGRP(*NO) ACTGRP(*CALLER);
CTL-OPT DATFMT(*ISO) TIMFMT(*ISO);
CTL-OPT DECEDIT('0.');
CTL-OPT ALWNULL(*USRCTL);
CTL-OPT BNDDIR('VEHBND');

/COPY QRPGLESRC,VEHCRUD_H
/COPY QRPGLESRC,VEHBIZ_H
/COPY QINCLUDE,RPGUNIT_H

// Test data
DCL-DS TestVehicleDS LIKEDS(VehicleDS) INZ;
DCL-DS TestTimeframeDS LIKEDS(TimeframeDS) INZ;

// Global variables
DCL-S TestVehicleId1 INT(10);
DCL-S TestVehicleId2 INT(10);
DCL-S TestVehicleId3 INT(10);
DCL-S TestVehicleId4 INT(10);
DCL-S TestUserId VARCHAR(10);
DCL-D Today DATE INZ(%DATE());
DCL-D Yesterday DATE INZ(%DATE() - %DAYS(1));
DCL-D LastWeek DATE INZ(%DATE() - %DAYS(7));
DCL-D LastMonth DATE INZ(%DATE() - %DAYS(30));
DCL-D LastYear DATE INZ(%DATE() - %DAYS(365));

// Setup procedure - runs before each test
DCL-PROC SETUP;
  // Initialize test data
  TestUserId = 'TESTUSER';
  
  // Clean up any test data from previous runs
  EXEC SQL
    DELETE FROM VEHICLES
    WHERE NOTES = 'Test vehicle';
    
  EXEC SQL
    DELETE FROM VEHICLE_HISTORY
    WHERE NOTES = 'Test vehicle';
    
  // Create test vehicles for business logic tests
  
  // Vehicle 1: Toyota Camry 2020, Sold yesterday, Acquired 30 days ago, $18,500
  TestVehicleDS.Make = 'Toyota';
  TestVehicleDS.Model = 'Camry';
  TestVehicleDS.Trim = 'LE';
  TestVehicleDS.Year = 2020;
  TestVehicleDS.VIN = 'TEST1' + %CHAR(%TIMESTAMP());
  TestVehicleDS.Color = 'Blue';
  TestVehicleDS.Odometer = 25000;
  TestVehicleDS.ConditionRating = 8;
  TestVehicleDS.AcquisitionPrice = 15000.00;
  TestVehicleDS.AskingPrice = 18500.00;
  TestVehicleDS.DateAcquired = LastMonth;
  TestVehicleDS.Status = 'AVAILABLE';
  TestVehicleDS.Notes = 'Test vehicle';
  
  TestVehicleId1 = AddVehicle(TestVehicleDS : TestUserId);
  UpdateVehicleStatus(TestVehicleId1 : 'SOLD' : Yesterday : TestUserId : 'Test vehicle');
  
  // Vehicle 2: Honda Accord 2019, Sold last week, Acquired 60 days ago, $17,000
  TestVehicleDS.Make = 'Honda';
  TestVehicleDS.Model = 'Accord';
  TestVehicleDS.Trim = 'EX';
  TestVehicleDS.Year = 2019;
  TestVehicleDS.VIN = 'TEST2' + %CHAR(%TIMESTAMP());
  TestVehicleDS.Color = 'Red';
  TestVehicleDS.Odometer = 35000;
  TestVehicleDS.ConditionRating = 7;
  TestVehicleDS.AcquisitionPrice = 14000.00;
  TestVehicleDS.AskingPrice = 17000.00;
  TestVehicleDS.DateAcquired = LastMonth - %DAYS(30);
  TestVehicleDS.Status = 'AVAILABLE';
  TestVehicleDS.Notes = 'Test vehicle';
  
  TestVehicleId2 = AddVehicle(TestVehicleDS : TestUserId);
  UpdateVehicleStatus(TestVehicleId2 : 'SOLD' : LastWeek : TestUserId : 'Test vehicle');
  
  // Vehicle 3: Toyota Corolla 2021, Available, Acquired 15 days ago, $16,000
  TestVehicleDS.Make = 'Toyota';
  TestVehicleDS.Model = 'Corolla';
  TestVehicleDS.Trim = 'LE';
  TestVehicleDS.Year = 2021;
  TestVehicleDS.VIN = 'TEST3' + %CHAR(%TIMESTAMP());
  TestVehicleDS.Color = 'White';
  TestVehicleDS.Odometer = 15000;
  TestVehicleDS.ConditionRating = 9;
  TestVehicleDS.AcquisitionPrice = 13000.00;
  TestVehicleDS.AskingPrice = 16000.00;
  TestVehicleDS.DateAcquired = LastMonth + %DAYS(15);
  TestVehicleDS.Status = 'AVAILABLE';
  TestVehicleDS.Notes = 'Test vehicle';
  
  TestVehicleId3 = AddVehicle(TestVehicleDS : TestUserId);
  
  // Vehicle 4: Ford F-150 2018, On Hold, Acquired 45 days ago, $25,000
  TestVehicleDS.Make = 'Ford';
  TestVehicleDS.Model = 'F-150';
  TestVehicleDS.Trim = 'XLT';
  TestVehicleDS.Year = 2018;
  TestVehicleDS.VIN = 'TEST4' + %CHAR(%TIMESTAMP());
  TestVehicleDS.Color = 'Black';
  TestVehicleDS.Odometer = 45000;
  TestVehicleDS.ConditionRating = 6;
  TestVehicleDS.AcquisitionPrice = 20000.00;
  TestVehicleDS.AskingPrice = 25000.00;
  TestVehicleDS.DateAcquired = LastMonth - %DAYS(15);
  TestVehicleDS.Status = 'AVAILABLE';
  TestVehicleDS.Notes = 'Test vehicle';
  
  TestVehicleId4 = AddVehicle(TestVehicleDS : TestUserId);
  UpdateVehicleStatus(TestVehicleId4 : 'ON_HOLD' : *NULL : TestUserId : 'Test vehicle');
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

// Test CalculateVehicleProfit procedure
DCL-PROC TEST_CALCULATE_VEHICLE_PROFIT EXPORT;
  DCL-S Profit PACKED(10:2);
  
  // Calculate profit for sold vehicle
  Profit = CalculateVehicleProfit(TestVehicleId1);
  
  // Verify profit calculation (18500 - 15000 = 3500)
  assert(Profit = 3500.00 : 'Profit should be $3,500.00');
  
  // Calculate profit for another sold vehicle
  Profit = CalculateVehicleProfit(TestVehicleId2);
  
  // Verify profit calculation (17000 - 14000 = 3000)
  assert(Profit = 3000.00 : 'Profit should be $3,000.00');
  
  // Calculate profit for available vehicle (uses asking price)
  Profit = CalculateVehicleProfit(TestVehicleId3);
  
  // Verify profit calculation (16000 - 13000 = 3000)
  assert(Profit = 3000.00 : 'Profit should be $3,000.00');
  
  // Test with invalid vehicle ID
  Profit = CalculateVehicleProfit(-1);
  assert(Profit = VEHBIZ_NO_DATA : 'Should return NO_DATA for invalid ID');
END-PROC;

// Test CalculateAggregateProfitByDate procedure
DCL-PROC TEST_CALCULATE_AGGREGATE_PROFIT_BY_DATE EXPORT;
  DCL-S Result INT(10);
  DCL-DS ProfitSummary LIKEDS(ProfitSummaryDS);
  DCL-DS Timeframe LIKEDS(TimeframeDS);
  
  // Calculate profit for all time
  Timeframe.StartDate = *LOVAL;
  Timeframe.EndDate = *HIVAL;
  
  Result = CalculateAggregateProfitByDate(Timeframe : ProfitSummary);
  
  // Verify result
  assert(Result = VEHBIZ_SUCCESS : 'CalculateAggregateProfitByDate should succeed');
  assert(ProfitSummary.TotalVehicles >= 2 : 'Should have at least 2 sold vehicles');
  assert(ProfitSummary.TotalRevenue >= 35500.00 : 'Total revenue should be at least $35,500.00');
  assert(ProfitSummary.TotalCost >= 29000.00 : 'Total cost should be at least $29,000.00');
  assert(ProfitSummary.TotalProfit >= 6500.00 : 'Total profit should be at least $6,500.00');
  assert(ProfitSummary.AverageProfit >= 3000.00 : 'Average profit should be at least $3,000.00');
  
  // Calculate profit for last week
  Timeframe.StartDate = LastWeek;
  Timeframe.EndDate = Today;
  
  Result = CalculateAggregateProfitByDate(Timeframe : ProfitSummary);
  
  // Verify result
  assert(Result = VEHBIZ_SUCCESS : 'CalculateAggregateProfitByDate should succeed');
  assert(ProfitSummary.TotalVehicles >= 1 : 'Should have at least 1 sold vehicle in last week');
  assert(ProfitSummary.TotalRevenue >= 18500.00 : 'Total revenue should be at least $18,500.00');
  assert(ProfitSummary.TotalCost >= 15000.00 : 'Total cost should be at least $15,000.00');
  assert(ProfitSummary.TotalProfit >= 3500.00 : 'Total profit should be at least $3,500.00');
END-PROC;

// Test CalculateSalesMetricsByTimeframe procedure
DCL-PROC TEST_CALCULATE_SALES_METRICS_BY_TIMEFRAME EXPORT;
  DCL-S Result INT(10);
  DCL-DS MetricsArray LIKEDS(SalesMetricsDS) DIM(12);
  DCL-S MetricsCount INT(10);
  DCL-DS Timeframe LIKEDS(TimeframeDS);
  
  // Calculate metrics for all time with MONTHLY timeframe
  Timeframe.StartDate = *LOVAL;
  Timeframe.EndDate = *HIVAL;
  
  Result = CalculateSalesMetricsByTimeframe(Timeframe : 'MONTHLY' : MetricsArray : MetricsCount);
  
  // Verify result
  assert(Result >= 1 : 'Should have at least 1 month with sales');
  assert(MetricsCount >= 1 : 'Should have at least 1 month with sales');
  assert(MetricsArray(1).VehiclesSold > 0 : 'Should have vehicles sold in first period');
  assert(MetricsArray(1).TotalRevenue > 0 : 'Should have revenue in first period');
  assert(MetricsArray(1).TotalProfit > 0 : 'Should have profit in first period');
  
  // Calculate metrics for all time with YEARLY timeframe
  Result = CalculateSalesMetricsByTimeframe(Timeframe : 'YEARLY' : MetricsArray : MetricsCount);
  
  // Verify result
  assert(Result >= 1 : 'Should have at least 1 year with sales');
  assert(MetricsCount >= 1 : 'Should have at least 1 year with sales');
  assert(MetricsArray(1).VehiclesSold >= 2 : 'Should have at least 2 vehicles sold in first period');
  
  // Test with invalid timeframe type
  Result = CalculateSalesMetricsByTimeframe(Timeframe : 'INVALID' : MetricsArray : MetricsCount);
  assert(Result = VEHBIZ_ERROR : 'Should return error for invalid timeframe type');
END-PROC;

// Test CalculateInventoryValuation procedure
DCL-PROC TEST_CALCULATE_INVENTORY_VALUATION EXPORT;
  DCL-S Result INT(10);
  DCL-DS InventoryValue LIKEDS(InventoryValueDS);
  
  Result = CalculateInventoryValuation(InventoryValue);
  
  // Verify result
  assert(Result = VEHBIZ_SUCCESS : 'CalculateInventoryValuation should succeed');
  assert(InventoryValue.TotalVehicles >= 2 : 'Should have at least 2 vehicles in inventory');
  assert(InventoryValue.TotalValue >= 41000.00 : 'Total value should be at least $41,000.00');
  assert(InventoryValue.AverageValue > 0 : 'Average value should be greater than 0');
  assert(InventoryValue.OldestVehicleDays > 0 : 'Oldest vehicle days should be greater than 0');
  assert(InventoryValue.AverageDaysInInventory > 0 : 'Average days in inventory should be greater than 0');
END-PROC;

// Test CalculateAverageTimeToSale procedure
DCL-PROC TEST_CALCULATE_AVERAGE_TIME_TO_SALE EXPORT;
  DCL-S AvgDaysToSell INT(10);
  DCL-DS Timeframe LIKEDS(TimeframeDS);
  
  // Calculate average time to sale for all time
  AvgDaysToSell = CalculateAverageTimeToSale();
  
  // Verify result
  assert(AvgDaysToSell > 0 : 'Average days to sell should be greater than 0');
  
  // Calculate average time to sale for specific timeframe
  Timeframe.StartDate = LastMonth;
  Timeframe.EndDate = Today;
  
  AvgDaysToSell = CalculateAverageTimeToSale(Timeframe);
  
  // Verify result
  assert(AvgDaysToSell > 0 : 'Average days to sell should be greater than 0');
END-PROC;

// Test CalculateTopSellingModels procedure
DCL-PROC TEST_CALCULATE_TOP_SELLING_MODELS EXPORT;
  DCL-S Result INT(10);
  DCL-DS ResultArray LIKEDS(VehicleDS) DIM(10);
  DCL-S ResultCount INT(10);
  DCL-DS Timeframe LIKEDS(TimeframeDS);
  
  // Calculate top selling models for all time
  Timeframe.StartDate = *LOVAL;
  Timeframe.EndDate = *HIVAL;
  
  Result = CalculateTopSellingModels(Timeframe : 5 : ResultArray : ResultCount);
  
  // Verify result
  assert(Result >= 2 : 'Should have at least 2 models sold');
  assert(ResultCount >= 2 : 'Should have at least 2 models in result');
  
  // Test with limit of 1
  Result = CalculateTopSellingModels(Timeframe : 1 : ResultArray : ResultCount);
  
  // Verify result
  assert(Result = 1 : 'Should have exactly 1 model in result');
  assert(ResultCount = 1 : 'Should have exactly 1 model in result');
END-PROC;

// Test CalculateProfitMargin procedure
DCL-PROC TEST_CALCULATE_PROFIT_MARGIN EXPORT;
  DCL-S ProfitMargin PACKED(5:2);
  
  // Calculate profit margin for sold vehicle
  ProfitMargin = CalculateProfitMargin(TestVehicleId1);
  
  // Verify profit margin calculation ((18500 - 15000) / 15000 * 100 = 23.33%)
  assert(ProfitMargin >= 23.00 AND ProfitMargin <= 24.00 : 'Profit margin should be around 23.33%');
  
  // Calculate profit margin for another sold vehicle
  ProfitMargin = CalculateProfitMargin(TestVehicleId2);
  
  // Verify profit margin calculation ((17000 - 14000) / 14000 * 100 = 21.43%)
  assert(ProfitMargin >= 21.00 AND ProfitMargin <= 22.00 : 'Profit margin should be around 21.43%');
  
  // Test with invalid vehicle ID
  ProfitMargin = CalculateProfitMargin(-1);
  assert(ProfitMargin = VEHBIZ_NO_DATA : 'Should return NO_DATA for invalid ID');
END-PROC;

// Test CalculateMonthlyProfitLast12Months procedure
DCL-PROC TEST_CALCULATE_MONTHLY_PROFIT_LAST_12_MONTHS EXPORT;
  DCL-S Result INT(10);
  DCL-DS MetricsArray LIKEDS(SalesMetricsDS) DIM(12);
  DCL-S MetricsCount INT(10);
  
  Result = CalculateMonthlyProfitLast12Months(MetricsArray : MetricsCount);
  
  // Verify result
  assert(Result >= 1 : 'Should have at least 1 month with sales');
  assert(MetricsCount >= 1 : 'Should have at least 1 month with sales');
  assert(MetricsArray(1).VehiclesSold > 0 : 'Should have vehicles sold in first month');
  assert(MetricsArray(1).TotalRevenue > 0 : 'Should have revenue in first month');
  assert(MetricsArray(1).TotalProfit > 0 : 'Should have profit in first month');
END-PROC;