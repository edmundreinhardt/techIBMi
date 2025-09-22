**FREE
// REPMENU - Reporting Menu Program
// This program provides a menu interface for accessing various reports

CTL-OPT DFTACTGRP(*NO) ACTGRP(*NEW);
CTL-OPT DATFMT(*ISO) TIMFMT(*ISO);
CTL-OPT DECEDIT('0.');
CTL-OPT COPYRIGHT('Used Car Dealership Inventory System - 2025');
CTL-OPT MAIN(Main);

// Display file
DCL-F REPMENU WORKSTN SFILE(ERRORSFL:ERRRN) INDDS(DSPIND);

// Indicators
DCL-DS DSPIND;
  Exit IND POS(3);
  Cancel IND POS(12);
END-DS;

// Program variables
DCL-S ProgramStatus CHAR(10) INZ('RUNNING');
DCL-S ERRRN PACKED(4:0);
DCL-S Command VARCHAR(100);

// Main procedure
DCL-PROC Main;
  // Process until exit
  DOW ProgramStatus = 'RUNNING';
    // Display menu
    ExecDisplay();
    
    // Process selection
    ExecCommand();
  ENDDO;
  
  // Clean up and exit
  *INLR = *ON;
  RETURN;
END-PROC;

// Display the menu
DCL-PROC ExecDisplay;
  // Clear option
  OPTION = ' ';
  
  // Display menu screen
  EXFMT MENUSCR;
  
  // Check function keys
  IF Exit OR Cancel;
    ProgramStatus = 'EXIT';
  ENDIF;
  
  RETURN;
END-PROC;

// Process menu selection
DCL-PROC ExecCommand;
  // If exit requested, return
  IF ProgramStatus = 'EXIT';
    RETURN;
  ENDIF;
  
  // Process option
  SELECT;
    WHEN OPTION = '1';
      // Monthly Sales and Profit Report
      CallProgram('MONTHRPT');
    
    WHEN OPTION = '2';
      // Inventory Status Report
      CallProgram('INVRPT');
    
    WHEN OPTION = '3';
      // Vehicle Inventory Management
      CallProgram('VEHMGMT');
    
    WHEN OPTION = '4';
      // Exit
      ProgramStatus = 'EXIT';
    
    OTHER;
      // Invalid option
      ShowError('Invalid option. Please enter 1, 2, 3, or 4.');
  ENDSL;
  
  RETURN;
END-PROC;

// Call a program
DCL-PROC CallProgram;
  DCL-PI *N;
    ProgramName CHAR(10) CONST;
  END-PI;
  
  // Build command
  Command = 'CALL PGM(' + %TRIM(ProgramName) + ')';
  
  // Execute command
  EXEC SQL
    CALL QCMDEXC(:Command, :(%LEN(%TRIM(Command))));
  
  RETURN;
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
  ERRPGM = 'REPMENU';
  ERRMSG = Message;
  WRITE ERRORSFL;
  
  // Display error
  EXFMT ERRORCTL;
  
  RETURN;
END-PROC;