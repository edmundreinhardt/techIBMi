**FREE
// VEHBIZ - Vehicle Business Logic Implementation
// This module implements the procedures for the VEHBIZ service program
// which provides business logic and financial calculations for the vehicle inventory system.

CTL-OPT NOMAIN;
CTL-OPT DATFMT(*ISO) TIMFMT(*ISO);
CTL-OPT COPYRIGHT('Used Car Dealership Inventory System - 2025');
CTL-OPT DECEDIT('0.');
CTL-OPT ALWNULL(*USRCTL);
CTL-OPT BNDDIR('VEHBND');

/COPY QRPGLESRC,VEHBIZ_H

// Global variables
DCL-S SQLState CHAR(5);
DCL-S ErrorMsg VARCHAR(1000);

// Calculate profit for a specific vehicle
DCL-PROC CalculateVehicleProfit EXPORT;
  DCL-PI *N PACKED(10:2);
    VehicleId INT(10) CONST;
  END-PI;
  
  DCL-S AcquisitionPrice PACKED(10:2);
  DCL-S SellingPrice PACKED(10:2);
  DCL-S Profit PACKED(10:2);
  DCL-S Status VARCHAR(10);
  DCL-S Found IND;
  
  // Get vehicle information
  EXEC SQL
    SELECT ACQUISITION_PRICE, ASKING_PRICE, STATUS
    INTO :AcquisitionPrice, :SellingPrice, :Status
    FROM VEHICLES
    WHERE VEHICLE_ID = :VehicleId;
  
  IF SQLSTATE = '02000' THEN
    RETURN VEHBIZ_NO_DATA;
  ELSEIF SQLSTATE <> '00000' THEN
    RETURN VEHBIZ_ERROR;
  ENDIF;
  
  // For sold vehicles, use actual selling price
  IF Status = 'SOLD' THEN
    EXEC SQL
      SELECT NEW_PRICE INTO :SellingPrice
      FROM VEHICLE_HISTORY
      WHERE VEHICLE_ID = :VehicleId
        AND EVENT_TYPE = 'STATUS_CHANGE'
        AND NEW_STATUS = 'SOLD'
      ORDER BY EVENT_DATE DESC
      FETCH FIRST 1 ROW ONLY;
    
    IF SQLSTATE <> '00000' AND SQLSTATE <> '02000' THEN
      RETURN VEHBIZ_ERROR;
    ENDIF;
  ENDIF;
  
  // Calculate profit
  Profit = SellingPrice - AcquisitionPrice;
  
  RETURN Profit;
END-PROC;

// Calculate aggregate profit within a date range
DCL-PROC CalculateAggregateProfitByDate EXPORT;
  DCL-PI *N INT(10);
    Timeframe LIKEDS(TimeframeDS) CONST;
    ProfitSummary LIKEDS(ProfitSummaryDS);
  END-PI;
  
  DCL-S StartDateValue DATE;
  DCL-S EndDateValue DATE;
  
  // Initialize summary
  ProfitSummary.TotalVehicles = 0;
  ProfitSummary.TotalRevenue = 0;
  ProfitSummary.TotalCost = 0;
  ProfitSummary.TotalProfit = 0;
  ProfitSummary.AverageProfit = 0;
  ProfitSummary.AverageDaysToSell = 0;
  
  // Set default dates if not provided
  IF Timeframe.StartDate = *LOVAL THEN
    StartDateValue = %DATE('0001-01-01');
  ELSE
    StartDateValue = Timeframe.StartDate;
  ENDIF;
  
  IF Timeframe.EndDate = *LOVAL THEN
    EndDateValue = %DATE();
  ELSE
    EndDateValue = Timeframe.EndDate;
  ENDIF;
  
  // Calculate total vehicles sold, revenue, cost, and days to sell
  EXEC SQL
    SELECT 
      COUNT(*) AS TotalVehicles,
      SUM(CASE 
            WHEN H.NEW_PRICE IS NOT NULL THEN H.NEW_PRICE 
            ELSE V.ASKING_PRICE 
          END) AS TotalRevenue,
      SUM(V.ACQUISITION_PRICE) AS TotalCost,
      AVG(DAYS(V.DATE_SOLD) - DAYS(V.DATE_ACQUIRED)) AS AvgDaysToSell
    INTO 
      :ProfitSummary.TotalVehicles,
      :ProfitSummary.TotalRevenue,
      :ProfitSummary.TotalCost,
      :ProfitSummary.AverageDaysToSell
    FROM VEHICLES V
    LEFT JOIN (
      SELECT VEHICLE_ID, NEW_PRICE
      FROM VEHICLE_HISTORY
      WHERE EVENT_TYPE = 'STATUS_CHANGE'
        AND NEW_STATUS = 'SOLD'
      ORDER BY EVENT_DATE DESC
    ) H ON V.VEHICLE_ID = H.VEHICLE_ID
    WHERE V.STATUS = 'SOLD'
      AND V.DATE_SOLD BETWEEN :StartDateValue AND :EndDateValue;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHBIZ_ERROR;
  ENDIF;
  
  // Calculate total profit and average profit
  IF ProfitSummary.TotalVehicles > 0 THEN
    ProfitSummary.TotalProfit = ProfitSummary.TotalRevenue - ProfitSummary.TotalCost;
    ProfitSummary.AverageProfit = ProfitSummary.TotalProfit / ProfitSummary.TotalVehicles;
  ENDIF;
  
  RETURN VEHBIZ_SUCCESS;
END-PROC;

// Calculate sales metrics by timeframe (daily, weekly, monthly, yearly)
DCL-PROC CalculateSalesMetricsByTimeframe EXPORT;
  DCL-PI *N INT(10);
    Timeframe LIKEDS(TimeframeDS) CONST;
    TimeframeType VARCHAR(10) CONST;
    MetricsArray LIKEDS(SalesMetricsDS) DIM(999) OPTIONS(*VARSIZE);
    MetricsCount INT(10);
  END-PI;
  
  DCL-S StartDateValue DATE;
  DCL-S EndDateValue DATE;
  DCL-S SQLStatement VARCHAR(2000);
  DCL-S GroupByClause VARCHAR(200);
  DCL-S SelectClause VARCHAR(200);
  DCL-S i INT(10);
  
  // Initialize count
  MetricsCount = 0;
  
  // Set default dates if not provided
  IF Timeframe.StartDate = *LOVAL THEN
    StartDateValue = %DATE('0001-01-01');
  ELSE
    StartDateValue = Timeframe.StartDate;
  ENDIF;
  
  IF Timeframe.EndDate = *LOVAL THEN
    EndDateValue = %DATE();
  ELSE
    EndDateValue = Timeframe.EndDate;
  ENDIF;
  
  // Set GROUP BY and SELECT clauses based on timeframe type
  SELECT;
    WHEN TimeframeType = 'DAILY' OR TimeframeType = 'DAY';
      GroupByClause = 'GROUP BY DATE(V.DATE_SOLD)';
      SelectClause = 'VARCHAR_FORMAT(DATE(V.DATE_SOLD), ''YYYY-MM-DD'') AS Period';
    
    WHEN TimeframeType = 'WEEKLY' OR TimeframeType = 'WEEK';
      GroupByClause = 'GROUP BY YEAR(V.DATE_SOLD), WEEK(V.DATE_SOLD)';
      SelectClause = 'CONCAT(CHAR(YEAR(V.DATE_SOLD)), ''-W'', CHAR(WEEK(V.DATE_SOLD))) AS Period';
    
    WHEN TimeframeType = 'MONTHLY' OR TimeframeType = 'MONTH';
      GroupByClause = 'GROUP BY YEAR(V.DATE_SOLD), MONTH(V.DATE_SOLD)';
      SelectClause = 'CONCAT(CHAR(YEAR(V.DATE_SOLD)), ''-'', RIGHT(''0'' || CHAR(MONTH(V.DATE_SOLD)), 2)) AS Period';
    
    WHEN TimeframeType = 'YEARLY' OR TimeframeType = 'YEAR';
      GroupByClause = 'GROUP BY YEAR(V.DATE_SOLD)';
      SelectClause = 'CHAR(YEAR(V.DATE_SOLD)) AS Period';
    
    OTHER;
      RETURN VEHBIZ_ERROR; // Invalid timeframe type
  ENDSL;
  
  // Build dynamic SQL statement
  SQLStatement = 'SELECT ' +
                 SelectClause + ', ' +
                 'COUNT(*) AS VehiclesSold, ' +
                 'SUM(CASE WHEN H.NEW_PRICE IS NOT NULL THEN H.NEW_PRICE ELSE V.ASKING_PRICE END) AS TotalRevenue, ' +
                 'SUM(CASE WHEN H.NEW_PRICE IS NOT NULL THEN H.NEW_PRICE ELSE V.ASKING_PRICE END) - ' +
                 'SUM(V.ACQUISITION_PRICE) AS TotalProfit, ' +
                 'AVG(DAYS(V.DATE_SOLD) - DAYS(V.DATE_ACQUIRED)) AS AvgDaysToSell ' +
                 'FROM VEHICLES V ' +
                 'LEFT JOIN (SELECT VEHICLE_ID, NEW_PRICE FROM VEHICLE_HISTORY ' +
                 'WHERE EVENT_TYPE = ''STATUS_CHANGE'' AND NEW_STATUS = ''SOLD'' ' +
                 'ORDER BY EVENT_DATE DESC) H ON V.VEHICLE_ID = H.VEHICLE_ID ' +
                 'WHERE V.STATUS = ''SOLD'' ' +
                 'AND V.DATE_SOLD BETWEEN ? AND ? ' +
                 GroupByClause + ' ' +
                 'ORDER BY Period';
  
  // Prepare and execute the dynamic SQL
  EXEC SQL
    PREPARE MetricsStmt FROM :SQLStatement;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHBIZ_ERROR;
  ENDIF;
  
  EXEC SQL
    DECLARE MetricsCursor CURSOR FOR MetricsStmt;
  
  EXEC SQL
    OPEN MetricsCursor USING :StartDateValue, :EndDateValue;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHBIZ_ERROR;
  ENDIF;
  
  // Fetch results
  i = 0;
  DOW i < %ELEM(MetricsArray) AND SQLSTATE = '00000';
    EXEC SQL
      FETCH NEXT FROM MetricsCursor INTO
        :MetricsArray(i+1).Period,
        :MetricsArray(i+1).VehiclesSold,
        :MetricsArray(i+1).TotalRevenue,
        :MetricsArray(i+1).TotalProfit,
        :MetricsArray(i+1).AverageDaysToSell;
    
    IF SQLSTATE = '00000' THEN
      // Calculate average profit
      IF MetricsArray(i+1).VehiclesSold > 0 THEN
        MetricsArray(i+1).AverageProfit = MetricsArray(i+1).TotalProfit / MetricsArray(i+1).VehiclesSold;
      ELSE
        MetricsArray(i+1).AverageProfit = 0;
      ENDIF;
      
      i += 1;
    ENDIF;
  ENDDO;
  
  MetricsCount = i;
  
  EXEC SQL
    CLOSE MetricsCursor;
  
  RETURN MetricsCount;
END-PROC;

// Calculate current inventory valuation
DCL-PROC CalculateInventoryValuation EXPORT;
  DCL-PI *N INT(10);
    InventoryValue LIKEDS(InventoryValueDS);
  END-PI;
  
  DCL-S CurrentDate DATE;
  
  // Initialize values
  InventoryValue.TotalVehicles = 0;
  InventoryValue.TotalValue = 0;
  InventoryValue.AverageValue = 0;
  InventoryValue.OldestVehicleDays = 0;
  InventoryValue.AverageDaysInInventory = 0;
  
  CurrentDate = %DATE();
  
  // Calculate inventory metrics
  EXEC SQL
    SELECT 
      COUNT(*) AS TotalVehicles,
      SUM(ASKING_PRICE) AS TotalValue,
      AVG(ASKING_PRICE) AS AverageValue,
      MAX(DAYS(:CurrentDate) - DAYS(DATE_ACQUIRED)) AS OldestVehicleDays,
      AVG(DAYS(:CurrentDate) - DAYS(DATE_ACQUIRED)) AS AverageDaysInInventory
    INTO 
      :InventoryValue.TotalVehicles,
      :InventoryValue.TotalValue,
      :InventoryValue.AverageValue,
      :InventoryValue.OldestVehicleDays,
      :InventoryValue.AverageDaysInInventory
    FROM VEHICLES
    WHERE STATUS = 'AVAILABLE' OR STATUS = 'ON_HOLD';
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHBIZ_ERROR;
  ENDIF;
  
  RETURN VEHBIZ_SUCCESS;
END-PROC;

// Calculate average time to sale for sold vehicles
DCL-PROC CalculateAverageTimeToSale EXPORT;
  DCL-PI *N INT(10);
    Timeframe LIKEDS(TimeframeDS) CONST OPTIONS(*NOPASS);
  END-PI;
  
  DCL-S StartDateValue DATE;
  DCL-S EndDateValue DATE;
  DCL-S AvgDaysToSell INT(10);
  
  // Set default dates if parameter not passed or values not provided
  IF %PARMS >= 1 AND %ADDR(Timeframe) <> *NULL THEN
    IF Timeframe.StartDate = *LOVAL THEN
      StartDateValue = %DATE('0001-01-01');
    ELSE
      StartDateValue = Timeframe.StartDate;
    ENDIF;
    
    IF Timeframe.EndDate = *LOVAL THEN
      EndDateValue = %DATE();
    ELSE
      EndDateValue = Timeframe.EndDate;
    ENDIF;
  ELSE
    StartDateValue = %DATE('0001-01-01');
    EndDateValue = %DATE();
  ENDIF;
  
  // Calculate average days to sell
  EXEC SQL
    SELECT AVG(DAYS(DATE_SOLD) - DAYS(DATE_ACQUIRED)) AS AvgDaysToSell
    INTO :AvgDaysToSell
    FROM VEHICLES
    WHERE STATUS = 'SOLD'
      AND DATE_SOLD BETWEEN :StartDateValue AND :EndDateValue;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHBIZ_ERROR;
  ENDIF;
  
  IF AvgDaysToSell = *NULL THEN
    RETURN VEHBIZ_NO_DATA;
  ENDIF;
  
  RETURN AvgDaysToSell;
END-PROC;

// Calculate top selling models by quantity
DCL-PROC CalculateTopSellingModels EXPORT;
  DCL-PI *N INT(10);
    Timeframe LIKEDS(TimeframeDS) CONST OPTIONS(*NOPASS);
    TopCount INT(10) CONST OPTIONS(*NOPASS);
    ResultArray LIKEDS(VehicleDS) DIM(999) OPTIONS(*VARSIZE);
    ResultCount INT(10);
  END-PI;
  
  DCL-S StartDateValue DATE;
  DCL-S EndDateValue DATE;
  DCL-S LimitValue INT(10);
  DCL-S SQLStatement VARCHAR(2000);
  DCL-S i INT(10);
  
  // Initialize result count
  ResultCount = 0;
  
  // Set default dates if parameter not passed or values not provided
  IF %PARMS >= 1 AND %ADDR(Timeframe) <> *NULL THEN
    IF Timeframe.StartDate = *LOVAL THEN
      StartDateValue = %DATE('0001-01-01');
    ELSE
      StartDateValue = Timeframe.StartDate;
    ENDIF;
    
    IF Timeframe.EndDate = *LOVAL THEN
      EndDateValue = %DATE();
    ELSE
      EndDateValue = Timeframe.EndDate;
    ENDIF;
  ELSE
    StartDateValue = %DATE('0001-01-01');
    EndDateValue = %DATE();
  ENDIF;
  
  // Set default limit if not provided
  IF %PARMS >= 2 AND %ADDR(TopCount) <> *NULL AND TopCount > 0 THEN
    LimitValue = TopCount;
  ELSE
    LimitValue = 10; // Default to top 10
  ENDIF;
  
  // Build dynamic SQL statement
  SQLStatement = 'SELECT MAKE, MODEL, YEAR, COUNT(*) AS SoldCount ' +
                 'FROM VEHICLES ' +
                 'WHERE STATUS = ''SOLD'' ' +
                 'AND DATE_SOLD BETWEEN ? AND ? ' +
                 'GROUP BY MAKE, MODEL, YEAR ' +
                 'ORDER BY SoldCount DESC ' +
                 'FETCH FIRST ' + %CHAR(LimitValue) + ' ROWS ONLY';
  
  // Prepare and execute the dynamic SQL
  EXEC SQL
    PREPARE TopModelStmt FROM :SQLStatement;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHBIZ_ERROR;
  ENDIF;
  
  EXEC SQL
    DECLARE TopModelCursor CURSOR FOR TopModelStmt;
  
  EXEC SQL
    OPEN TopModelCursor USING :StartDateValue, :EndDateValue;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHBIZ_ERROR;
  ENDIF;
  
  // Fetch results
  i = 0;
  DOW i < %ELEM(ResultArray) AND SQLSTATE = '00000';
    EXEC SQL
      FETCH NEXT FROM TopModelCursor INTO
        :ResultArray(i+1).Make,
        :ResultArray(i+1).Model,
        :ResultArray(i+1).Year,
        :ResultArray(i+1).VehicleId; // Using VehicleId to store count
    
    IF SQLSTATE = '00000' THEN
      i += 1;
    ENDIF;
  ENDDO;
  
  ResultCount = i;
  
  EXEC SQL
    CLOSE TopModelCursor;
  
  RETURN ResultCount;
END-PROC;

// Calculate profit margin percentage for a vehicle
DCL-PROC CalculateProfitMargin EXPORT;
  DCL-PI *N PACKED(5:2);
    VehicleId INT(10) CONST;
  END-PI;
  
  DCL-S AcquisitionPrice PACKED(10:2);
  DCL-S SellingPrice PACKED(10:2);
  DCL-S ProfitMargin PACKED(5:2);
  DCL-S Status VARCHAR(10);
  
  // Get vehicle information
  EXEC SQL
    SELECT ACQUISITION_PRICE, ASKING_PRICE, STATUS
    INTO :AcquisitionPrice, :SellingPrice, :Status
    FROM VEHICLES
    WHERE VEHICLE_ID = :VehicleId;
  
  IF SQLSTATE = '02000' THEN
    RETURN VEHBIZ_NO_DATA;
  ELSEIF SQLSTATE <> '00000' THEN
    RETURN VEHBIZ_ERROR;
  ENDIF;
  
  // For sold vehicles, use actual selling price
  IF Status = 'SOLD' THEN
    EXEC SQL
      SELECT NEW_PRICE INTO :SellingPrice
      FROM VEHICLE_HISTORY
      WHERE VEHICLE_ID = :VehicleId
        AND EVENT_TYPE = 'STATUS_CHANGE'
        AND NEW_STATUS = 'SOLD'
      ORDER BY EVENT_DATE DESC
      FETCH FIRST 1 ROW ONLY;
    
    IF SQLSTATE <> '00000' AND SQLSTATE <> '02000' THEN
      RETURN VEHBIZ_ERROR;
    ENDIF;
  ENDIF;
  
  // Calculate profit margin percentage
  IF AcquisitionPrice > 0 THEN
    ProfitMargin = ((SellingPrice - AcquisitionPrice) / AcquisitionPrice) * 100;
  ELSE
    ProfitMargin = 0;
  ENDIF;
  
  RETURN ProfitMargin;
END-PROC;

// Calculate monthly sales and profit for the last 12 months
DCL-PROC CalculateMonthlyProfitLast12Months EXPORT;
  DCL-PI *N INT(10);
    MetricsArray LIKEDS(SalesMetricsDS) DIM(12) OPTIONS(*VARSIZE);
    MetricsCount INT(10);
  END-PI;
  
  DCL-S EndDate DATE;
  DCL-S StartDate DATE;
  DCL-S TimeframeValue LIKEDS(TimeframeDS);
  DCL-S Result INT(10);
  
  // Set date range for last 12 months
  EndDate = %DATE();
  StartDate = %DATE(
    %YEAR(EndDate) - %DIV(%MONTH(EndDate) - 1, 12),
    %MONTH(EndDate) - 1 + %REM(%MONTH(EndDate) - 1, 12) * 11,
    1
  );
  
  TimeframeValue.StartDate = StartDate;
  TimeframeValue.EndDate = EndDate;
  
  // Call the general metrics calculation with MONTHLY timeframe
  Result = CalculateSalesMetricsByTimeframe(
    TimeframeValue : 'MONTHLY' : MetricsArray : MetricsCount
  );
  
  RETURN Result;
END-PROC;