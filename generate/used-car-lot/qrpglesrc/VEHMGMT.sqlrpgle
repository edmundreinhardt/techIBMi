**FREE
// VEHMGMT - Vehicle Inventory Management Program
// This program provides a user interface for managing vehicle inventory

CTL-OPT DFTACTGRP(*NO) ACTGRP(*NEW);
CTL-OPT DATFMT(*ISO) TIMFMT(*ISO);
CTL-OPT DECEDIT('0.');
CTL-OPT ALWNULL(*USRCTL);
CTL-OPT BNDDIR('VEHBND');
CTL-OPT COPYRIGHT('Used Car Dealership Inventory System - 2025');
CTL-OPT MAIN(Main);

// Include service program headers
/COPY QRPGLESRC,VEHCRUD_H

// Display file
DCL-F VEHMGMTD WORKSTN SFILE(SFLRCD:SFLRRN) SFILE(ERRORSFL:ERRRN) INDDS(DSPIND);

// Indicators
DCL-DS DSPIND;
  Exit IND POS(3);
  Delete IND POS(4);
  Refresh IND POS(5);
  Add IND POS(6);
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
DCL-S SelectedVehicleId INT(10);
DCL-S Result INT(10);
DCL-S ErrorMessage VARCHAR(100);
DCL-S ERRRN PACKED(4:0);
DCL-S UserId VARCHAR(10) INZ('USERMGMT');

// Array to hold vehicle data
DCL-DS VehicleArray LIKEDS(VehicleDS) DIM(999);

// Vehicle data structure for add/edit
DCL-DS VehicleData LIKEDS(VehicleDS);

// Array to hold history data
DCL-DS HistoryArray LIKEDS(VehicleHistoryDS) DIM(999);

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

// Load vehicle data
DCL-PROC LoadData;
  DCL-DS Filter LIKEDS(VehicleFilterDS);
  
  // Clear and initialize the subfile
  SflClr = *ON;
  WRITE SFCTL;
  SflClr = *OFF;
  
  // Get all vehicles
  Result = ListVehicles(*NULL : VehicleArray : VehicleCount);
  
  // If no data, display empty subfile
  IF Result <= 0;
    SflDsp = *OFF;
    SflDspCtl = *ON;
    RETURN;
  ENDIF;
  
  // Load subfile with vehicles
  SFLRRN = 0;
  
  FOR i = 1 TO VehicleCount;
    // Increment record number
    SFLRRN += 1;
    
    // Set subfile record fields
    OPTION = ' ';
    VEHID = VehicleArray(i).VehicleId;
    MAKE = VehicleArray(i).Make;
    MODEL = VehicleArray(i).Model;
    YEAR = VehicleArray(i).Year;
    VIN = VehicleArray(i).VIN;
    STATUS = VehicleArray(i).Status;
    PRICE = VehicleArray(i).AskingPrice;
    
    // Write subfile record
    WRITE SFLRCD;
  ENDFOR;
  
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
  
  // Display screen and read input
  EXFMT SFCTL;
  
  RETURN;
END-PROC;

// Process command keys and options
DCL-PROC ExecCommand;
  // Check function keys
  SELECT;
    WHEN Exit;
      ProgramStatus = 'EXIT';
    
    WHEN Refresh;
      LoadData();
    
    WHEN Add;
      AddVehicleScreen();
    
    WHEN Cancel;
      ProgramStatus = 'EXIT';
    
    OTHER;
      // Process options
      ProcessOptions();
  ENDSL;
  
  RETURN;
END-PROC;

// Process options entered on the subfile
DCL-PROC ProcessOptions;
  DCL-S OptionValue CHAR(1);
  DCL-S VehicleId INT(10);
  
  // Read all records in the subfile
  SFLRRN = 0;
  
  DOW SFLRRN < VehicleCount;
    SFLRRN += 1;
    
    // Read the record
    CHAIN SFLRRN SFLRCD;
    
    // If option entered, process it
    IF OPTION <> ' ';
      OptionValue = OPTION;
      VehicleId = VEHID;
      
      // Clear the option
      OPTION = ' ';
      UPDATE SFLRCD;
      
      // Process the option
      SELECT;
        WHEN OptionValue = '2';
          EditVehicleScreen(VehicleId);
        
        WHEN OptionValue = '4';
          DeleteVehicle(VehicleId);
        
        WHEN OptionValue = '5';
          UpdateStatusScreen(VehicleId);
        
        WHEN OptionValue = '6';
          ViewHistoryScreen(VehicleId);
        
        OTHER;
          ShowError('Invalid option. Valid options are 2, 4, 5, and 6.');
      ENDSL;
    ENDIF;
  ENDDO;
  
  RETURN;
END-PROC;

// Add vehicle screen
DCL-PROC AddVehicleScreen;
  // Initialize fields
  AMAKE = '';
  AMODEL = '';
  ATRIM = '';
  AYEAR = 0;
  AVIN = '';
  ACOLOR = '';
  AODOMETER = 0;
  ACONDITION = 0;
  AACQPRICE = 0;
  AASKPRICE = 0;
  ADATEACQ = CurrentDate;
  ASTATUS = 'AVAILABLE';
  ANOTES = '';
  
  // Display screen
  EXFMT ADDRCD;
  
  // Process function keys
  IF Exit OR Cancel;
    RETURN;
  ENDIF;
  
  // Add the vehicle
  VehicleData = *ALLX'00';
  VehicleData.Make = AMAKE;
  VehicleData.Model = AMODEL;
  VehicleData.Trim = ATRIM;
  VehicleData.Year = AYEAR;
  VehicleData.VIN = AVIN;
  VehicleData.Color = ACOLOR;
  VehicleData.Odometer = AODOMETER;
  VehicleData.ConditionRating = ACONDITION;
  VehicleData.AcquisitionPrice = AACQPRICE;
  VehicleData.AskingPrice = AASKPRICE;
  VehicleData.DateAcquired = ADATEACQ;
  VehicleData.Status = ASTATUS;
  VehicleData.Notes = ANOTES;
  
  Result = AddVehicle(VehicleData : UserId);
  
  IF Result <= 0;
    ShowError('Failed to add vehicle. Error code: ' + %CHAR(Result));
  ELSE;
    // Reload data
    LoadData();
  ENDIF;
  
  RETURN;
END-PROC;

// Edit vehicle screen
DCL-PROC EditVehicleScreen;
  DCL-PI *N;
    VehicleId INT(10) CONST;
  END-PI;
  
  // Get vehicle data
  Result = GetVehicleById(VehicleId : VehicleData);
  
  IF Result <> VEHCRUD_SUCCESS;
    ShowError('Failed to retrieve vehicle data. Error code: ' + %CHAR(Result));
    RETURN;
  ENDIF;
  
  // Set screen fields
  DVEHID = VehicleData.VehicleId;
  DMAKE = VehicleData.Make;
  DMODEL = VehicleData.Model;
  DTRIM = VehicleData.Trim;
  DYEAR = VehicleData.Year;
  DVIN = VehicleData.VIN;
  DCOLOR = VehicleData.Color;
  DODOMETER = VehicleData.Odometer;
  DCONDITION = VehicleData.ConditionRating;
  DACQPRICE = VehicleData.AcquisitionPrice;
  DASKPRICE = VehicleData.AskingPrice;
  DDATEACQ = VehicleData.DateAcquired;
  DDATESOLD = VehicleData.DateSold;
  DSTATUS = VehicleData.Status;
  DNOTES = VehicleData.Notes;
  
  // Display screen
  EXFMT DETAILSCR;
  
  // Process function keys
  SELECT;
    WHEN Exit OR Cancel;
      RETURN;
    
    WHEN Delete;
      DeleteVehicle(VehicleId);
      RETURN;
    
    WHEN Refresh;
      UpdateStatusScreen(VehicleId);
      RETURN;
    
    WHEN Add;
      ViewHistoryScreen(VehicleId);
      RETURN;
  ENDSL;
  
  // Update vehicle data
  VehicleData.Make = DMAKE;
  VehicleData.Model = DMODEL;
  VehicleData.Trim = DTRIM;
  VehicleData.Year = DYEAR;
  VehicleData.VIN = DVIN;
  VehicleData.Color = DCOLOR;
  VehicleData.Odometer = DODOMETER;
  VehicleData.ConditionRating = DCONDITION;
  VehicleData.AcquisitionPrice = DACQPRICE;
  VehicleData.AskingPrice = DASKPRICE;
  VehicleData.DateAcquired = DDATEACQ;
  VehicleData.DateSold = DDATESOLD;
  VehicleData.Status = DSTATUS;
  VehicleData.Notes = DNOTES;
  
  Result = UpdateVehicle(VehicleData : UserId);
  
  IF Result <> VEHCRUD_SUCCESS;
    ShowError('Failed to update vehicle. Error code: ' + %CHAR(Result));
  ELSE;
    // Reload data
    LoadData();
  ENDIF;
  
  RETURN;
END-PROC;

// Delete vehicle
DCL-PROC DeleteVehicle;
  DCL-PI *N;
    VehicleId INT(10) CONST;
  END-PI;
  
  // Delete the vehicle
  Result = VEHCRUD_DeleteVehicle(VehicleId : UserId);
  
  IF Result <> VEHCRUD_SUCCESS;
    ShowError('Failed to delete vehicle. Error code: ' + %CHAR(Result));
  ELSE;
    // Reload data
    LoadData();
  ENDIF;
  
  RETURN;
END-PROC;

// Update status screen
DCL-PROC UpdateStatusScreen;
  DCL-PI *N;
    VehicleId INT(10) CONST;
  END-PI;
  
  // Get vehicle data
  Result = GetVehicleById(VehicleId : VehicleData);
  
  IF Result <> VEHCRUD_SUCCESS;
    ShowError('Failed to retrieve vehicle data. Error code: ' + %CHAR(Result));
    RETURN;
  ENDIF;
  
  // Set screen fields
  SVEHID = VehicleData.VehicleId;
  SMAKE = VehicleData.Make;
  SMODEL = VehicleData.Model;
  SYEAR = VehicleData.Year;
  SVIN = VehicleData.VIN;
  SOLDSTATUS = VehicleData.Status;
  SNEWSTATUS = VehicleData.Status;
  SDATESOLD = VehicleData.DateSold;
  SNOTES = '';
  
  // Display screen
  EXFMT STATUSSCR;
  
  // Process function keys
  IF Exit OR Cancel;
    RETURN;
  ENDIF;
  
  // Update status
  Result = UpdateVehicleStatus(VehicleId : SNEWSTATUS : SDATESOLD : UserId : SNOTES);
  
  IF Result <> VEHCRUD_SUCCESS;
    ShowError('Failed to update vehicle status. Error code: ' + %CHAR(Result));
  ELSE;
    // Reload data
    LoadData();
  ENDIF;
  
  RETURN;
END-PROC;

// View history screen
DCL-PROC ViewHistoryScreen;
  DCL-PI *N;
    VehicleId INT(10) CONST;
  END-PI;
  
  DCL-S HistoryCount INT(10);
  DCL-S j INT(10);
  
  // Get vehicle data
  Result = GetVehicleById(VehicleId : VehicleData);
  
  IF Result <> VEHCRUD_SUCCESS;
    ShowError('Failed to retrieve vehicle data. Error code: ' + %CHAR(Result));
    RETURN;
  ENDIF;
  
  // Set screen fields
  HVEHID = VehicleData.VehicleId;
  HMAKE = VehicleData.Make;
  HMODEL = VehicleData.Model;
  HYEAR = VehicleData.Year;
  HVIN = VehicleData.VIN;
  
  // Get history data
  Result = GetVehicleHistory(VehicleId : HistoryArray : HistoryCount);
  
  IF Result < 0;
    ShowError('Failed to retrieve vehicle history. Error code: ' + %CHAR(Result));
    RETURN;
  ENDIF;
  
  // Clear history fields
  HDATE1 = '';
  HEVENT1 = '';
  HDETAIL1 = '';
  HDATE2 = '';
  HEVENT2 = '';
  HDETAIL2 = '';
  HDATE3 = '';
  HEVENT3 = '';
  HDETAIL3 = '';
  HDATE4 = '';
  HEVENT4 = '';
  HDETAIL4 = '';
  HDATE5 = '';
  HEVENT5 = '';
  HDETAIL5 = '';
  HDATE6 = '';
  HEVENT6 = '';
  HDETAIL6 = '';
  HDATE7 = '';
  HEVENT7 = '';
  HDETAIL7 = '';
  HDATE8 = '';
  HEVENT8 = '';
  HDETAIL8 = '';
  HDATE9 = '';
  HEVENT9 = '';
  HDETAIL9 = '';
  HDATE10 = '';
  HEVENT10 = '';
  HDETAIL10 = '';
  
  // Set history fields
  FOR j = 1 TO %MIN(HistoryCount : 10);
    SELECT;
      WHEN j = 1;
        HDATE1 = %CHAR(HistoryArray(j).EventDate);
        HEVENT1 = HistoryArray(j).EventType;
        HDETAIL1 = BuildHistoryDetail(HistoryArray(j));
      WHEN j = 2;
        HDATE2 = %CHAR(HistoryArray(j).EventDate);
        HEVENT2 = HistoryArray(j).EventType;
        HDETAIL2 = BuildHistoryDetail(HistoryArray(j));
      WHEN j = 3;
        HDATE3 = %CHAR(HistoryArray(j).EventDate);
        HEVENT3 = HistoryArray(j).EventType;
        HDETAIL3 = BuildHistoryDetail(HistoryArray(j));
      WHEN j = 4;
        HDATE4 = %CHAR(HistoryArray(j).EventDate);
        HEVENT4 = HistoryArray(j).EventType;
        HDETAIL4 = BuildHistoryDetail(HistoryArray(j));
      WHEN j = 5;
        HDATE5 = %CHAR(HistoryArray(j).EventDate);
        HEVENT5 = HistoryArray(j).EventType;
        HDETAIL5 = BuildHistoryDetail(HistoryArray(j));
      WHEN j = 6;
        HDATE6 = %CHAR(HistoryArray(j).EventDate);
        HEVENT6 = HistoryArray(j).EventType;
        HDETAIL6 = BuildHistoryDetail(HistoryArray(j));
      WHEN j = 7;
        HDATE7 = %CHAR(HistoryArray(j).EventDate);
        HEVENT7 = HistoryArray(j).EventType;
        HDETAIL7 = BuildHistoryDetail(HistoryArray(j));
      WHEN j = 8;
        HDATE8 = %CHAR(HistoryArray(j).EventDate);
        HEVENT8 = HistoryArray(j).EventType;
        HDETAIL8 = BuildHistoryDetail(HistoryArray(j));
      WHEN j = 9;
        HDATE9 = %CHAR(HistoryArray(j).EventDate);
        HEVENT9 = HistoryArray(j).EventType;
        HDETAIL9 = BuildHistoryDetail(HistoryArray(j));
      WHEN j = 10;
        HDATE10 = %CHAR(HistoryArray(j).EventDate);
        HEVENT10 = HistoryArray(j).EventType;
        HDETAIL10 = BuildHistoryDetail(HistoryArray(j));
    ENDSL;
  ENDFOR;
  
  // Display screen
  EXFMT HISTSCR;
  
  RETURN;
END-PROC;

// Build history detail string
DCL-PROC BuildHistoryDetail;
  DCL-PI *N VARCHAR(35);
    HistoryData LIKEDS(VehicleHistoryDS) CONST;
  END-PI;
  
  DCL-S Detail VARCHAR(35);
  
  SELECT;
    WHEN HistoryData.EventType = 'ADDED';
      Detail = 'Added to inventory';
    
    WHEN HistoryData.EventType = 'STATUS_CHANGE';
      Detail = 'Status: ' + %TRIM(HistoryData.OldStatus) + 
               ' -> ' + %TRIM(HistoryData.NewStatus);
    
    WHEN HistoryData.EventType = 'PRICE_CHANGE';
      Detail = 'Price: ' + %EDITC(HistoryData.OldPrice : 'J') + 
               ' -> ' + %EDITC(HistoryData.NewPrice : 'J');
    
    WHEN HistoryData.EventType = 'DELETED';
      Detail = 'Removed from inventory';
    
    OTHER;
      Detail = %TRIM(HistoryData.Notes);
  ENDSL;
  
  RETURN Detail;
END-PROC;

// Show error message
DCL-PROC ShowError;
  DCL-PI *N;
    Message VARCHAR(100) CONST;
  END-PI;
  
  // Clear error subfile
  ERRRN = 0;
  WRITE ERRORCTL;
  
  // Add error message
  ERRRN = 1;
  ERRPGM = 'VEHMGMT';
  ERRMSG = Message;
  WRITE ERRORSFL;
  
  // Display error
  EXFMT ERRORCTL;
  
  RETURN;
END-PROC;