**FREE
/IF DEFINED(VEHCRUD_H)
/EOF
/ENDIF
/DEFINE VEHCRUD_H

// VEHCRUD_H - Vehicle CRUD Operations Header
// This header file defines the procedure prototypes for the VEHCRUD service program
// which provides CRUD operations for the vehicle inventory system.

// Data structures for parameter passing
DCL-DS VehicleDS QUALIFIED TEMPLATE;
  VehicleId INT(10);
  Make VARCHAR(50);
  Model VARCHAR(50);
  Trim VARCHAR(50);
  Year INT(10);
  VIN VARCHAR(17);
  Color VARCHAR(30);
  Odometer INT(10);
  ConditionRating INT(10);
  AcquisitionPrice PACKED(10:2);
  AskingPrice PACKED(10:2);
  DateAcquired DATE;
  DateSold DATE;
  Status VARCHAR(10);
  Notes VARCHAR(1000);
  LastUpdated TIMESTAMP;
END-DS;

DCL-DS VehicleHistoryDS QUALIFIED TEMPLATE;
  HistoryId INT(10);
  VehicleId INT(10);
  EventType VARCHAR(20);
  EventDate TIMESTAMP;
  OldStatus VARCHAR(10);
  NewStatus VARCHAR(10);
  OldPrice PACKED(10:2);
  NewPrice PACKED(10:2);
  UserId VARCHAR(10);
  Notes VARCHAR(1000);
END-DS;

DCL-DS VehicleFilterDS QUALIFIED TEMPLATE;
  Make VARCHAR(50);
  Model VARCHAR(50);
  YearFrom INT(10);
  YearTo INT(10);
  Status VARCHAR(10);
  DateAcquiredFrom DATE;
  DateAcquiredTo DATE;
  DateSoldFrom DATE;
  DateSoldTo DATE;
  PriceFrom PACKED(10:2);
  PriceTo PACKED(10:2);
END-DS;

// Return codes
DCL-C VEHCRUD_SUCCESS 0;
DCL-C VEHCRUD_ERROR -1;
DCL-C VEHCRUD_NOT_FOUND -2;
DCL-C VEHCRUD_DUPLICATE -3;
DCL-C VEHCRUD_INVALID_PARAM -4;

// Procedure prototypes

// Add a new vehicle to the inventory
// Returns: Vehicle ID if successful, error code if failed
DCL-PR AddVehicle INT(10);
  VehicleData LIKEDS(VehicleDS) CONST;
  UserId VARCHAR(10) CONST;
END-PR;

// Get vehicle details by ID
// Returns: VEHCRUD_SUCCESS if found, VEHCRUD_NOT_FOUND if not found
DCL-PR GetVehicleById INT(10);
  VehicleId INT(10) CONST;
  VehicleData LIKEDS(VehicleDS);
END-PR;

// Update vehicle information
// Returns: VEHCRUD_SUCCESS if successful, error code if failed
DCL-PR UpdateVehicle INT(10);
  VehicleData LIKEDS(VehicleDS) CONST;
  UserId VARCHAR(10) CONST;
END-PR;

// Delete a vehicle from the inventory
// Returns: VEHCRUD_SUCCESS if successful, error code if failed
DCL-PR DeleteVehicle INT(10);
  VehicleId INT(10) CONST;
  UserId VARCHAR(10) CONST;
END-PR;

// Update vehicle status (available, sold, on hold)
// Returns: VEHCRUD_SUCCESS if successful, error code if failed
DCL-PR UpdateVehicleStatus INT(10);
  VehicleId INT(10) CONST;
  NewStatus VARCHAR(10) CONST;
  DateSold DATE OPTIONS(*NOPASS);
  UserId VARCHAR(10) CONST;
  Notes VARCHAR(1000) OPTIONS(*NOPASS);
END-PR;

// List vehicles with optional filtering
// Returns: Number of vehicles found, error code if failed
DCL-PR ListVehicles INT(10);
  Filter LIKEDS(VehicleFilterDS) CONST OPTIONS(*NOPASS);
  ResultArray LIKEDS(VehicleDS) DIM(999) OPTIONS(*VARSIZE);
  ResultCount INT(10);
END-PR;

// Get vehicle history by vehicle ID
// Returns: Number of history records found, error code if failed
DCL-PR GetVehicleHistory INT(10);
  VehicleId INT(10) CONST;
  HistoryArray LIKEDS(VehicleHistoryDS) DIM(999) OPTIONS(*VARSIZE);
  HistoryCount INT(10);
END-PR;