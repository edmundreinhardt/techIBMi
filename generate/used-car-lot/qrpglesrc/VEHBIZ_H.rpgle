**FREE
/IF DEFINED(VEHBIZ_H)
/EOF
/ENDIF
/DEFINE VEHBIZ_H

// VEHBIZ_H - Vehicle Business Logic Header
// This header file defines the procedure prototypes for the VEHBIZ service program
// which provides business logic and financial calculations for the vehicle inventory system.

/COPY QRPGLESRC,VEHCRUD_H

// Data structures for parameter passing
DCL-DS ProfitSummaryDS QUALIFIED TEMPLATE;
  TotalVehicles INT(10);
  TotalRevenue PACKED(15:2);
  TotalCost PACKED(15:2);
  TotalProfit PACKED(15:2);
  AverageProfit PACKED(10:2);
  AverageDaysToSell INT(10);
END-DS;

DCL-DS InventoryValueDS QUALIFIED TEMPLATE;
  TotalVehicles INT(10);
  TotalValue PACKED(15:2);
  AverageValue PACKED(10:2);
  OldestVehicleDays INT(10);
  AverageDaysInInventory INT(10);
END-DS;

DCL-DS SalesMetricsDS QUALIFIED TEMPLATE;
  Period VARCHAR(20);
  VehiclesSold INT(10);
  TotalRevenue PACKED(15:2);
  TotalProfit PACKED(15:2);
  AverageProfit PACKED(10:2);
  AverageDaysToSell INT(10);
END-DS;

DCL-DS TimeframeDS QUALIFIED TEMPLATE;
  StartDate DATE;
  EndDate DATE;
END-DS;

// Return codes
DCL-C VEHBIZ_SUCCESS 0;
DCL-C VEHBIZ_ERROR -1;
DCL-C VEHBIZ_NO_DATA -2;

// Procedure prototypes

// Calculate profit for a specific vehicle
// Returns: Profit amount if successful, error code if failed
DCL-PR CalculateVehicleProfit PACKED(10:2);
  VehicleId INT(10) CONST;
END-PR;

// Calculate aggregate profit within a date range
// Returns: VEHBIZ_SUCCESS if successful, error code if failed
DCL-PR CalculateAggregateProfitByDate INT(10);
  Timeframe LIKEDS(TimeframeDS) CONST;
  ProfitSummary LIKEDS(ProfitSummaryDS);
END-PR;

// Calculate sales metrics by timeframe (daily, weekly, monthly, yearly)
// Returns: Number of periods with data, error code if failed
DCL-PR CalculateSalesMetricsByTimeframe INT(10);
  Timeframe LIKEDS(TimeframeDS) CONST;
  TimeframeType VARCHAR(10) CONST; // 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'
  MetricsArray LIKEDS(SalesMetricsDS) DIM(999) OPTIONS(*VARSIZE);
  MetricsCount INT(10);
END-PR;

// Calculate current inventory valuation
// Returns: VEHBIZ_SUCCESS if successful, error code if failed
DCL-PR CalculateInventoryValuation INT(10);
  InventoryValue LIKEDS(InventoryValueDS);
END-PR;

// Calculate average time to sale for sold vehicles
// Returns: Average days to sale if successful, error code if failed
DCL-PR CalculateAverageTimeToSale INT(10);
  Timeframe LIKEDS(TimeframeDS) CONST OPTIONS(*NOPASS);
END-PR;

// Calculate top selling models by quantity
// Returns: Number of models in result, error code if failed
DCL-PR CalculateTopSellingModels INT(10);
  Timeframe LIKEDS(TimeframeDS) CONST OPTIONS(*NOPASS);
  TopCount INT(10) CONST OPTIONS(*NOPASS);
  ResultArray LIKEDS(VehicleDS) DIM(999) OPTIONS(*VARSIZE);
  ResultCount INT(10);
END-PR;

// Calculate profit margin percentage for a vehicle
// Returns: Profit margin percentage if successful, error code if failed
DCL-PR CalculateProfitMargin PACKED(5:2);
  VehicleId INT(10) CONST;
END-PR;

// Calculate monthly sales and profit for the last 12 months
// Returns: Number of months with data, error code if failed
DCL-PR CalculateMonthlyProfitLast12Months INT(10);
  MetricsArray LIKEDS(SalesMetricsDS) DIM(12) OPTIONS(*VARSIZE);
  MetricsCount INT(10);
END-PR;