**FREE
// VEHCRUD - Vehicle CRUD Operations Implementation
// This module implements the procedures for the VEHCRUD service program
// which provides CRUD operations for the vehicle inventory system.

CTL-OPT NOMAIN;
CTL-OPT DATFMT(*ISO) TIMFMT(*ISO);
CTL-OPT COPYRIGHT('Used Car Dealership Inventory System - 2025');
CTL-OPT DECEDIT('0.');
CTL-OPT ALWNULL(*USRCTL);
CTL-OPT BNDDIR('VEHBND');

/COPY QRPGLESRC,VEHCRUD_H

// Global variables
DCL-S SQLState CHAR(5);
DCL-S ErrorMsg VARCHAR(1000);

// Add a new vehicle to the inventory
DCL-PROC AddVehicle EXPORT;
  DCL-PI *N INT(10);
    VehicleData LIKEDS(VehicleDS) CONST;
    UserId VARCHAR(10) CONST;
  END-PI;
  
  DCL-S NewVehicleId INT(10);
  DCL-S Success IND;
  
  // Validate input parameters
  IF VehicleData.Make = '' OR VehicleData.Model = '' OR 
     VehicleData.Year <= 0 OR VehicleData.VIN = '' THEN
    RETURN VEHCRUD_INVALID_PARAM;
  ENDIF;
  
  // Check if VIN already exists
  EXEC SQL
    SELECT COUNT(*) INTO :Success
    FROM VEHICLES
    WHERE VIN = :VehicleData.VIN;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  IF Success > 0 THEN
    RETURN VEHCRUD_DUPLICATE;
  ENDIF;
  
  // Insert new vehicle
  EXEC SQL
    INSERT INTO VEHICLES (
      MAKE, MODEL, TRIM, YEAR, VIN, COLOR, ODOMETER,
      CONDITION_RATING, ACQUISITION_PRICE, ASKING_PRICE,
      DATE_ACQUIRED, STATUS, NOTES
    ) VALUES (
      :VehicleData.Make, :VehicleData.Model, :VehicleData.Trim,
      :VehicleData.Year, :VehicleData.VIN, :VehicleData.Color,
      :VehicleData.Odometer, :VehicleData.ConditionRating,
      :VehicleData.AcquisitionPrice, :VehicleData.AskingPrice,
      :VehicleData.DateAcquired, :VehicleData.Status, :VehicleData.Notes
    );
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  // Get the generated ID
  EXEC SQL
    SELECT IDENTITY_VAL_LOCAL() INTO :NewVehicleId FROM SYSIBM.SYSDUMMY1;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  // Add entry to vehicle history
  EXEC SQL
    INSERT INTO VEHICLE_HISTORY (
      VEHICLE_ID, EVENT_TYPE, NEW_STATUS, NEW_PRICE, USER_ID, NOTES
    ) VALUES (
      :NewVehicleId, 'ADDED', :VehicleData.Status, :VehicleData.AskingPrice,
      :UserId, 'Vehicle added to inventory'
    );
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  RETURN NewVehicleId;
END-PROC;

// Get vehicle details by ID
DCL-PROC GetVehicleById EXPORT;
  DCL-PI *N INT(10);
    VehicleId INT(10) CONST;
    VehicleData LIKEDS(VehicleDS);
  END-PI;
  
  DCL-S Found IND;
  
  EXEC SQL
    SELECT 
      VEHICLE_ID, MAKE, MODEL, TRIM, YEAR, VIN, COLOR, ODOMETER,
      CONDITION_RATING, ACQUISITION_PRICE, ASKING_PRICE,
      DATE_ACQUIRED, DATE_SOLD, STATUS, NOTES, LAST_UPDATED
    INTO
      :VehicleData.VehicleId, :VehicleData.Make, :VehicleData.Model,
      :VehicleData.Trim, :VehicleData.Year, :VehicleData.VIN,
      :VehicleData.Color, :VehicleData.Odometer, :VehicleData.ConditionRating,
      :VehicleData.AcquisitionPrice, :VehicleData.AskingPrice,
      :VehicleData.DateAcquired, :VehicleData.DateSold, :VehicleData.Status,
      :VehicleData.Notes, :VehicleData.LastUpdated
    FROM VEHICLES
    WHERE VEHICLE_ID = :VehicleId;
  
  IF SQLSTATE = '02000' THEN
    RETURN VEHCRUD_NOT_FOUND;
  ELSEIF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  RETURN VEHCRUD_SUCCESS;
END-PROC;

// Update vehicle information
DCL-PROC UpdateVehicle EXPORT;
  DCL-PI *N INT(10);
    VehicleData LIKEDS(VehicleDS) CONST;
    UserId VARCHAR(10) CONST;
  END-PI;
  
  DCL-DS OldVehicleData LIKEDS(VehicleDS);
  DCL-S Result INT(10);
  
  // Get current vehicle data for history tracking
  Result = GetVehicleById(VehicleData.VehicleId : OldVehicleData);
  
  IF Result <> VEHCRUD_SUCCESS THEN
    RETURN Result;
  ENDIF;
  
  // Update vehicle information
  EXEC SQL
    UPDATE VEHICLES
    SET
      MAKE = :VehicleData.Make,
      MODEL = :VehicleData.Model,
      TRIM = :VehicleData.Trim,
      YEAR = :VehicleData.Year,
      COLOR = :VehicleData.Color,
      ODOMETER = :VehicleData.Odometer,
      CONDITION_RATING = :VehicleData.ConditionRating,
      ACQUISITION_PRICE = :VehicleData.AcquisitionPrice,
      ASKING_PRICE = :VehicleData.AskingPrice,
      NOTES = :VehicleData.Notes,
      LAST_UPDATED = CURRENT_TIMESTAMP
    WHERE VEHICLE_ID = :VehicleData.VehicleId;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  // Add history entry if price changed
  IF OldVehicleData.AskingPrice <> VehicleData.AskingPrice THEN
    EXEC SQL
      INSERT INTO VEHICLE_HISTORY (
        VEHICLE_ID, EVENT_TYPE, OLD_PRICE, NEW_PRICE, USER_ID, NOTES
      ) VALUES (
        :VehicleData.VehicleId, 'PRICE_CHANGE', :OldVehicleData.AskingPrice,
        :VehicleData.AskingPrice, :UserId, 'Price updated'
      );
    
    IF SQLSTATE <> '00000' THEN
      RETURN VEHCRUD_ERROR;
    ENDIF;
  ENDIF;
  
  RETURN VEHCRUD_SUCCESS;
END-PROC;

// Delete a vehicle from the inventory
DCL-PROC DeleteVehicle EXPORT;
  DCL-PI *N INT(10);
    VehicleId INT(10) CONST;
    UserId VARCHAR(10) CONST;
  END-PI;
  
  DCL-DS VehicleData LIKEDS(VehicleDS);
  DCL-S Result INT(10);
  
  // Check if vehicle exists
  Result = GetVehicleById(VehicleId : VehicleData);
  
  IF Result <> VEHCRUD_SUCCESS THEN
    RETURN Result;
  ENDIF;
  
  // Add history entry before deletion
  EXEC SQL
    INSERT INTO VEHICLE_HISTORY (
      VEHICLE_ID, EVENT_TYPE, USER_ID, NOTES
    ) VALUES (
      :VehicleId, 'DELETED', :UserId, 'Vehicle removed from inventory'
    );
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  // Delete the vehicle
  EXEC SQL
    DELETE FROM VEHICLES
    WHERE VEHICLE_ID = :VehicleId;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  RETURN VEHCRUD_SUCCESS;
END-PROC;

// Update vehicle status (available, sold, on hold)
DCL-PROC UpdateVehicleStatus EXPORT;
  DCL-PI *N INT(10);
    VehicleId INT(10) CONST;
    NewStatus VARCHAR(10) CONST;
    DateSold DATE OPTIONS(*NOPASS);
    UserId VARCHAR(10) CONST;
    Notes VARCHAR(1000) OPTIONS(*NOPASS);
  END-PI;
  
  DCL-DS VehicleData LIKEDS(VehicleDS);
  DCL-S Result INT(10);
  DCL-S NotesValue VARCHAR(1000);
  DCL-S DateSoldValue DATE;
  
  // Set default values for optional parameters
  IF %PARMS >= 5 AND %ADDR(Notes) <> *NULL THEN
    NotesValue = Notes;
  ELSE
    NotesValue = 'Status updated';
  ENDIF;
  
  // Check if vehicle exists and get current data
  Result = GetVehicleById(VehicleId : VehicleData);
  
  IF Result <> VEHCRUD_SUCCESS THEN
    RETURN Result;
  ENDIF;
  
  // Validate status
  IF NewStatus <> 'AVAILABLE' AND NewStatus <> 'SOLD' AND NewStatus <> 'ON_HOLD' THEN
    RETURN VEHCRUD_INVALID_PARAM;
  ENDIF;
  
  // Set date sold if status is changing to SOLD
  IF NewStatus = 'SOLD' THEN
    IF %PARMS >= 3 AND %ADDR(DateSold) <> *NULL THEN
      DateSoldValue = DateSold;
    ELSE
      DateSoldValue = %DATE();
    ENDIF;
    
    EXEC SQL
      UPDATE VEHICLES
      SET STATUS = :NewStatus,
          DATE_SOLD = :DateSoldValue,
          LAST_UPDATED = CURRENT_TIMESTAMP
      WHERE VEHICLE_ID = :VehicleId;
  ELSE
    EXEC SQL
      UPDATE VEHICLES
      SET STATUS = :NewStatus,
          LAST_UPDATED = CURRENT_TIMESTAMP
      WHERE VEHICLE_ID = :VehicleId;
  ENDIF;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  // Add history entry
  EXEC SQL
    INSERT INTO VEHICLE_HISTORY (
      VEHICLE_ID, EVENT_TYPE, OLD_STATUS, NEW_STATUS, USER_ID, NOTES
    ) VALUES (
      :VehicleId, 'STATUS_CHANGE', :VehicleData.Status,
      :NewStatus, :UserId, :NotesValue
    );
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  RETURN VEHCRUD_SUCCESS;
END-PROC;

// List vehicles with optional filtering
DCL-PROC ListVehicles EXPORT;
  DCL-PI *N INT(10);
    Filter LIKEDS(VehicleFilterDS) CONST OPTIONS(*NOPASS);
    ResultArray LIKEDS(VehicleDS) DIM(999) OPTIONS(*VARSIZE);
    ResultCount INT(10);
  END-PI;
  
  DCL-S SQL_Statement VARCHAR(4000);
  DCL-S WhereClause VARCHAR(2000);
  DCL-S HasFilter IND;
  DCL-S i INT(10);
  
  // Initialize result count
  ResultCount = 0;
  
  // Build SQL statement with dynamic WHERE clause
  SQL_Statement = 'SELECT VEHICLE_ID, MAKE, MODEL, TRIM, YEAR, VIN, COLOR, ' +
                  'ODOMETER, CONDITION_RATING, ACQUISITION_PRICE, ' +
                  'ASKING_PRICE, DATE_ACQUIRED, DATE_SOLD, STATUS, ' +
                  'NOTES, LAST_UPDATED FROM VEHICLES';
  
  // Apply filters if provided
  IF %PARMS >= 1 AND %ADDR(Filter) <> *NULL THEN
    HasFilter = *OFF;
    WhereClause = ' WHERE ';
    
    // Make filter
    IF Filter.Make <> '' THEN
      WhereClause += 'MAKE LIKE ''%' + %TRIM(Filter.Make) + '%''';
      HasFilter = *ON;
    ENDIF;
    
    // Model filter
    IF Filter.Model <> '' THEN
      IF HasFilter THEN
        WhereClause += ' AND ';
      ENDIF;
      WhereClause += 'MODEL LIKE ''%' + %TRIM(Filter.Model) + '%''';
      HasFilter = *ON;
    ENDIF;
    
    // Year range filter
    IF Filter.YearFrom > 0 THEN
      IF HasFilter THEN
        WhereClause += ' AND ';
      ENDIF;
      WhereClause += 'YEAR >= ' + %CHAR(Filter.YearFrom);
      HasFilter = *ON;
    ENDIF;
    
    IF Filter.YearTo > 0 THEN
      IF HasFilter THEN
        WhereClause += ' AND ';
      ENDIF;
      WhereClause += 'YEAR <= ' + %CHAR(Filter.YearTo);
      HasFilter = *ON;
    ENDIF;
    
    // Status filter
    IF Filter.Status <> '' THEN
      IF HasFilter THEN
        WhereClause += ' AND ';
      ENDIF;
      WhereClause += 'STATUS = ''' + %TRIM(Filter.Status) + '''';
      HasFilter = *ON;
    ENDIF;
    
    // Date acquired range filter
    IF Filter.DateAcquiredFrom <> *LOVAL THEN
      IF HasFilter THEN
        WhereClause += ' AND ';
      ENDIF;
      WhereClause += 'DATE_ACQUIRED >= ''' + %CHAR(Filter.DateAcquiredFrom) + '''';
      HasFilter = *ON;
    ENDIF;
    
    IF Filter.DateAcquiredTo <> *LOVAL THEN
      IF HasFilter THEN
        WhereClause += ' AND ';
      ENDIF;
      WhereClause += 'DATE_ACQUIRED <= ''' + %CHAR(Filter.DateAcquiredTo) + '''';
      HasFilter = *ON;
    ENDIF;
    
    // Date sold range filter
    IF Filter.DateSoldFrom <> *LOVAL THEN
      IF HasFilter THEN
        WhereClause += ' AND ';
      ENDIF;
      WhereClause += 'DATE_SOLD >= ''' + %CHAR(Filter.DateSoldFrom) + '''';
      HasFilter = *ON;
    ENDIF;
    
    IF Filter.DateSoldTo <> *LOVAL THEN
      IF HasFilter THEN
        WhereClause += ' AND ';
      ENDIF;
      WhereClause += 'DATE_SOLD <= ''' + %CHAR(Filter.DateSoldTo) + '''';
      HasFilter = *ON;
    ENDIF;
    
    // Price range filter
    IF Filter.PriceFrom > 0 THEN
      IF HasFilter THEN
        WhereClause += ' AND ';
      ENDIF;
      WhereClause += 'ASKING_PRICE >= ' + %CHAR(Filter.PriceFrom);
      HasFilter = *ON;
    ENDIF;
    
    IF Filter.PriceTo > 0 THEN
      IF HasFilter THEN
        WhereClause += ' AND ';
      ENDIF;
      WhereClause += 'ASKING_PRICE <= ' + %CHAR(Filter.PriceTo);
      HasFilter = *ON;
    ENDIF;
    
    // Add WHERE clause if any filters were applied
    IF HasFilter THEN
      SQL_Statement += WhereClause;
    ENDIF;
  ENDIF;
  
  // Add ORDER BY clause
  SQL_Statement += ' ORDER BY MAKE, MODEL, YEAR DESC';
  
  // Prepare and execute the dynamic SQL
  EXEC SQL
    PREPARE VehicleStmt FROM :SQL_Statement;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  EXEC SQL
    DECLARE VehicleCursor CURSOR FOR VehicleStmt;
  
  EXEC SQL
    OPEN VehicleCursor;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  // Fetch results
  i = 0;
  DOW i < %ELEM(ResultArray) AND SQLSTATE = '00000';
    EXEC SQL
      FETCH NEXT FROM VehicleCursor INTO
        :ResultArray(i+1).VehicleId, :ResultArray(i+1).Make,
        :ResultArray(i+1).Model, :ResultArray(i+1).Trim,
        :ResultArray(i+1).Year, :ResultArray(i+1).VIN,
        :ResultArray(i+1).Color, :ResultArray(i+1).Odometer,
        :ResultArray(i+1).ConditionRating, :ResultArray(i+1).AcquisitionPrice,
        :ResultArray(i+1).AskingPrice, :ResultArray(i+1).DateAcquired,
        :ResultArray(i+1).DateSold, :ResultArray(i+1).Status,
        :ResultArray(i+1).Notes, :ResultArray(i+1).LastUpdated;
    
    IF SQLSTATE = '00000' THEN
      i += 1;
    ENDIF;
  ENDDO;
  
  ResultCount = i;
  
  EXEC SQL
    CLOSE VehicleCursor;
  
  RETURN ResultCount;
END-PROC;

// Get vehicle history by vehicle ID
DCL-PROC GetVehicleHistory EXPORT;
  DCL-PI *N INT(10);
    VehicleId INT(10) CONST;
    HistoryArray LIKEDS(VehicleHistoryDS) DIM(999) OPTIONS(*VARSIZE);
    HistoryCount INT(10);
  END-PI;
  
  DCL-S i INT(10);
  
  // Initialize result count
  HistoryCount = 0;
  
  // Check if vehicle exists
  EXEC SQL
    SELECT COUNT(*) INTO :i
    FROM VEHICLES
    WHERE VEHICLE_ID = :VehicleId;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  IF i = 0 THEN
    RETURN VEHCRUD_NOT_FOUND;
  ENDIF;
  
  // Fetch history records
  EXEC SQL
    DECLARE HistoryCursor CURSOR FOR
    SELECT HISTORY_ID, VEHICLE_ID, EVENT_TYPE, EVENT_DATE,
           OLD_STATUS, NEW_STATUS, OLD_PRICE, NEW_PRICE,
           USER_ID, NOTES
    FROM VEHICLE_HISTORY
    WHERE VEHICLE_ID = :VehicleId
    ORDER BY EVENT_DATE DESC;
  
  EXEC SQL
    OPEN HistoryCursor;
  
  IF SQLSTATE <> '00000' THEN
    RETURN VEHCRUD_ERROR;
  ENDIF;
  
  // Fetch results
  i = 0;
  DOW i < %ELEM(HistoryArray) AND SQLSTATE = '00000';
    EXEC SQL
      FETCH NEXT FROM HistoryCursor INTO
        :HistoryArray(i+1).HistoryId, :HistoryArray(i+1).VehicleId,
        :HistoryArray(i+1).EventType, :HistoryArray(i+1).EventDate,
        :HistoryArray(i+1).OldStatus, :HistoryArray(i+1).NewStatus,
        :HistoryArray(i+1).OldPrice, :HistoryArray(i+1).NewPrice,
        :HistoryArray(i+1).UserId, :HistoryArray(i+1).Notes;
    
    IF SQLSTATE = '00000' THEN
      i += 1;
    ENDIF;
  ENDDO;
  
  HistoryCount = i;
  
  EXEC SQL
    CLOSE HistoryCursor;
  
  RETURN HistoryCount;
END-PROC;