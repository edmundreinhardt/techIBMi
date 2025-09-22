**FREE
// MONTHRPT - Monthly Sales and Profit Report
// This program displays monthly sales and profit data for the last 12 months

CTL-OPT DFTACTGRP(*NO) ACTGRP(*NEW);
CTL-OPT DATFMT(*ISO) TIMFMT(*ISO);
CTL-OPT DECEDIT('0.');
CTL-OPT ALWNULL(*USRCTL);
CTL-OPT BNDDIR('VEHBND');
CTL-OPT COPYRIGHT('Used Car Dealership Inventory System - 2025');
CTL-OPT MAIN(Main);

// Include service program headers
/COPY QRPGLESRC,VEHCRUD_H
/COPY QRPGLESRC,VEHBIZ_H

// Display file
DCL-F MONTHRPTD WORKSTN SFILE(SFLRCD:SFLRRN) INDDS(DSPIND);

// Indicators
DCL-DS DSPIND;
  Exit IND POS(3);
  Refresh IND POS(5);
  Cancel IND POS(12);
  SflDsp IND POS(31);
  SflDspCtl IND POS(32);
  SflClr IND POS(33);
  SflEnd IND POS(34);
END-DS;

// Program variables
DCL-S ProgramStatus CHAR(10) INZ('RUNNING');
DCL-S MetricsCount INT(10);
DCL-S i INT(10);
DCL-S TotalSold INT(10);
DCL-S TotalRevenue PACKED(15:2);
DCL-S TotalCost PACKED(15:2);
DCL-S TotalProfit PACKED(15:2);
DCL-S AvgProfit PACKED(10:2);
DCL-S AvgDaysToSell INT(10);

// Array to hold monthly metrics
DCL-DS MetricsArray LIKEDS(SalesMetricsDS) DIM(12);

// Main procedure
DCL-PROC Main;
  // Initialize display
  ExecInit();
  
  // Process until exit
  DOW ProgramStatus = 'RUNNING';
    ExecDisplay();
    ExecCommand();
  ENDDO;
  
  // Clean up and exit
  *INLR = *ON;
  RETURN;
END-PROC;

// Initialize the program
DCL-PROC ExecInit;
  // Set period description
  PERIOD = 'Last 12 Months';
  
  // Load data
  LoadData();
  
  RETURN;
END-PROC;

// Load data from business logic service program
DCL-PROC LoadData;
  DCL-S Result INT(10);
  
  // Clear totals
  TotalSold = 0;
  TotalRevenue = 0;
  TotalCost = 0;
  TotalProfit = 0;
  AvgProfit = 0;
  AvgDaysToSell = 0;
  
  // Get monthly profit data for last 12 months
  Result = CalculateMonthlyProfitLast12Months(MetricsArray : MetricsCount);
  
  // Clear and initialize the subfile
  SflClr = *ON;
  WRITE SFCTL;
  SflClr = *OFF;
  
  // If no data, display empty subfile
  IF Result <= 0;
    SflDsp = *OFF;
    SflDspCtl = *ON;
    RETURN;
  ENDIF;
  
  // Load subfile with data
  SFLRRN = 0;
  
  FOR i = 1 TO MetricsCount;
    // Increment record number
    SFLRRN += 1;
    
    // Set subfile record fields
    MONTH = MetricsArray(i).Period;
    SOLD = MetricsArray(i).VehiclesSold;
    REVENUE = MetricsArray(i).TotalRevenue;
    COST = MetricsArray(i).TotalRevenue - MetricsArray(i).TotalProfit;
    PROFIT = MetricsArray(i).TotalProfit;
    AVGPROFIT = MetricsArray(i).AverageProfit;
    AVGDAYS = MetricsArray(i).AverageDaysToSell;
    
    // Write subfile record
    WRITE SFLRCD;
    
    // Accumulate totals
    TotalSold += SOLD;
    TotalRevenue += REVENUE;
    TotalCost += COST;
    TotalProfit += PROFIT;
  ENDFOR;
  
  // Calculate averages
  IF TotalSold > 0;
    AvgProfit = TotalProfit / TotalSold;
    
    // Calculate weighted average days to sell
    AvgDaysToSell = 0;
    FOR i = 1 TO MetricsCount;
      IF MetricsArray(i).VehiclesSold > 0;
        AvgDaysToSell += MetricsArray(i).AverageDaysToSell * 
                         MetricsArray(i).VehiclesSold;
      ENDIF;
    ENDFOR;
    AvgDaysToSell /= TotalSold;
  ENDIF;
  
  // Set totals for display
  TOTALSOLD = TotalSold;
  TOTALREV = TotalRevenue;
  TOTALCOST = TotalCost;
  TOTALPROF = TotalProfit;
  AVGPROF = AvgProfit;
  AVGDAYSTOT = AvgDaysToSell;
  
  // Turn on subfile display
  SflDsp = *ON;
  SflDspCtl = *ON;
  SflEnd = *ON;
  
  RETURN;
END-PROC;

// Display the screen
DCL-PROC ExecDisplay;
  // Write header
  WRITE SFCTL;
  
  // Write footer
  WRITE FOOTER;
  
  // Write totals
  WRITE TOTALS;
  
  // Display screen and read input
  EXFMT SFCTL;
  
  RETURN;
END-PROC;

// Process command keys
DCL-PROC ExecCommand;
  // Check function keys
  SELECT;
    WHEN Exit;
      ProgramStatus = 'EXIT';
    
    WHEN Refresh;
      LoadData();
    
    WHEN Cancel;
      ProgramStatus = 'EXIT';
  ENDSL;
  
  RETURN;
END-PROC;