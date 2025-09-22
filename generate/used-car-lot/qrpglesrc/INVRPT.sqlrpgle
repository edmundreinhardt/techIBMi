**FREE
// INVRPT - Inventory Status Report
// This program displays current inventory status and valuation

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
DCL-F INVRPTD WORKSTN SFILE(SFLRCD:SFLRRN) INDDS(DSPIND);

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
DCL-S VehicleCount INT(10);
DCL-S i INT(10);
DCL-S CurrentDate DATE;
DCL-S AvailableCount INT(10);
DCL-S OnHoldCount INT(10);
DCL-S DaysInInventory INT(10);

// Array to hold vehicle data
DCL-DS VehicleArray LIKEDS(VehicleDS) DIM(999);

// Inventory valuation data
DCL-DS InventoryValue LIKEDS(InventoryValueDS);

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
  // Get current date
  CurrentDate = %DATE();
  
  // Load data
  LoadData();
  
  RETURN;
END-PROC;

// Load data from service programs
DCL-PROC LoadData;
  DCL-S Result INT(10);
  DCL-DS Filter LIKEDS(VehicleFilterDS);
  
  // Get inventory valuation
  Result = CalculateInventoryValuation(InventoryValue);
  
  // Set header information
  TOTVEH = InventoryValue.TotalVehicles;
  TOTVAL = InventoryValue.TotalValue;
  AVGDAYS = InventoryValue.AverageDaysInInventory;
  
  // Clear and initialize the subfile
  SflClr = *ON;
  WRITE SFCTL;
  SflClr = *OFF;
  
  // Filter for available and on-hold vehicles only
  Filter.Status = 'AVAILABLE';
  
  // Get available vehicles
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  
  // Initialize counters
  AvailableCount = 0;
  OnHoldCount = 0;
  
  // If no data, display empty subfile
  IF Result <= 0;
    SflDsp = *OFF;
    SflDspCtl = *ON;
    RETURN;
  ENDIF;
  
  // Load subfile with available vehicles
  SFLRRN = 0;
  
  FOR i = 1 TO VehicleCount;
    // Increment record number
    SFLRRN += 1;
    
    // Set subfile record fields
    VEHID = VehicleArray(i).VehicleId;
    MAKE = VehicleArray(i).Make;
    MODEL = VehicleArray(i).Model;
    YEAR = VehicleArray(i).Year;
    VIN = VehicleArray(i).VIN;
    STATUS = VehicleArray(i).Status;
    PRICE = VehicleArray(i).AskingPrice;
    
    // Calculate days in inventory
    DAYSINV = %DIFF(CurrentDate : VehicleArray(i).DateAcquired : *DAYS);
    
    // Write subfile record
    WRITE SFLRCD;
    
    // Count available vehicles
    AvailableCount += 1;
  ENDFOR;
  
  // Now get on-hold vehicles
  Filter = *ALLX'00';
  Filter.Status = 'ON_HOLD';
  
  Result = ListVehicles(Filter : VehicleArray : VehicleCount);
  
  // Add on-hold vehicles to subfile
  FOR i = 1 TO VehicleCount;
    // Increment record number
    SFLRRN += 1;
    
    // Set subfile record fields
    VEHID = VehicleArray(i).VehicleId;
    MAKE = VehicleArray(i).Make;
    MODEL = VehicleArray(i).Model;
    YEAR = VehicleArray(i).Year;
    VIN = VehicleArray(i).VIN;
    STATUS = VehicleArray(i).Status;
    PRICE = VehicleArray(i).AskingPrice;
    
    // Calculate days in inventory
    DAYSINV = %DIFF(CurrentDate : VehicleArray(i).DateAcquired : *DAYS);
    
    // Write subfile record
    WRITE SFLRCD;
    
    // Count on-hold vehicles
    OnHoldCount += 1;
  ENDFOR;
  
  // Set summary information
  AVAILCNT = AvailableCount;
  HOLDCNT = OnHoldCount;
  TOTVAL2 = InventoryValue.TotalValue;
  
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
  
  // Write summary
  WRITE SUMMARY;
  
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