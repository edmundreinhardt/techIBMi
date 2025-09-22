# Used Car Lot Application Architecture

This document provides a comprehensive overview of the Used Car Lot application architecture, including data architecture, layered architecture, and integration patterns.

## 1. System Overview

The Used Car Lot application is a hybrid system that combines traditional IBM i (AS/400) components with a modern web interface. The system is designed to manage vehicle inventory, track sales, and provide business analytics for a used car dealership.

```mermaid
graph TD
    subgraph "Client Layer"
        WebBrowser["Web Browser"]
        DisplayFiles["IBM i Display Files"]
    end
    
    subgraph "Presentation Layer"
        Flask["Python Flask Web App"]
        RPGPrograms["RPG UI Programs"]
    end
    
    subgraph "Business Logic Layer"
        VEHBIZ["VEHBIZ Service Program"]
        PythonBiz["Python Business Logic"]
    end
    
    subgraph "Data Access Layer"
        VEHCRUD["VEHCRUD Service Program"]
        PythonConnector["Python IBM i Connector"]
    end
    
    subgraph "Data Storage Layer"
        DB["IBM i DB2 Database"]
    end
    
    WebBrowser --> Flask
    DisplayFiles --> RPGPrograms
    Flask --> PythonBiz
    RPGPrograms --> VEHBIZ
    PythonBiz --> PythonConnector
    VEHBIZ --> VEHCRUD
    PythonConnector --> VEHCRUD
    VEHCRUD --> DB
```

The system architecture follows a multi-layered approach with two distinct user interfaces:
1. Traditional IBM i green-screen interface using display files and RPG programs
2. Modern web interface using Python Flask with responsive design

Both interfaces interact with the same backend services and database, ensuring data consistency across the system.

## 2. Data Architecture

### 2.1 Database Schema

The application uses IBM i DB2 database with two primary tables:

```mermaid
erDiagram
    VEHICLES {
        int VEHICLE_ID PK
        varchar(50) MAKE
        varchar(50) MODEL
        varchar(50) TRIM
        int YEAR
        varchar(17) VIN
        varchar(30) COLOR
        int ODOMETER
        int CONDITION_RATING
        decimal(10,2) ACQUISITION_PRICE
        decimal(10) ASKING_PRICE
        date DATE_ACQUIRED
        date DATE_SOLD
        varchar(10) STATUS
        varchar(1000) NOTES
        timestamp LAST_UPDATED
    }
    
    VEHICLE_HISTORY {
        int HISTORY_ID PK
        int VEHICLE_ID FK
        varchar(20) EVENT_TYPE
        timestamp EVENT_DATE
        varchar(10) OLD_STATUS
        varchar(10) NEW_STATUS
        decimal(10) OLD_PRICE
        decimal(10) NEW_PRICE
        varchar(10) USER_ID
        varchar(1000) NOTES
    }
    
    VEHICLES ||--o{ VEHICLE_HISTORY : "has"
```

#### Key Database Design Features:
- **VEHICLES table**: Stores all vehicle information including inventory status
- **VEHICLE_HISTORY table**: Tracks all changes to vehicles for audit and analysis
- **Referential Integrity**: Foreign key constraints ensure data consistency
- **Indexes**: Strategic indexes on frequently queried fields for performance

### 2.2 Data Flow Architecture

```mermaid
flowchart TD
    subgraph "User Interfaces"
        Web["Web Interface"]
        DspF["Display Files Interface"]
    end
    
    subgraph "Data Operations"
        Create["Create Vehicle"]
        Read["Read Vehicle Data"]
        Update["Update Vehicle"]
        Delete["Delete Vehicle"]
        StatusChange["Change Status"]
    end
    
    subgraph "Business Processing"
        Inventory["Inventory Management"]
        Sales["Sales Processing"]
        Reports["Reporting & Analytics"]
        Pricing["Pricing Adjustments"]
    end
    
    subgraph "Data Storage"
        VehiclesTable["VEHICLES Table"]
        HistoryTable["VEHICLE_HISTORY Table"]
    end
    
    Web --> Create & Read & Update & Delete & StatusChange
    DspF --> Create & Read & Update & Delete & StatusChange
    
    Create --> VehiclesTable
    Read --> VehiclesTable
    Update --> VehiclesTable
    Delete --> VehiclesTable
    StatusChange --> VehiclesTable
    
    Update & StatusChange --> HistoryTable
    Delete --> HistoryTable
    
    VehiclesTable --> Inventory & Sales & Reports & Pricing
    HistoryTable --> Reports
    
    Inventory & Sales & Reports & Pricing --> Web
    Inventory & Sales & Reports & Pricing --> DspF
```

## 3. Layered Architecture

### 3.1 Data Access Layer

The Data Access Layer provides a clean separation between the database and business logic.

```mermaid
classDiagram
    class VEHCRUD_Service {
        +AddVehicle(VehicleDS, UserId) int
        +GetVehicleById(VehicleId, VehicleDS) int
        +UpdateVehicle(VehicleDS, UserId) int
        +DeleteVehicle(VehicleId, UserId) int
        +UpdateVehicleStatus(VehicleId, NewStatus, DateSold, UserId, Notes) int
        +ListVehicles(Filter, ResultArray, ResultCount) int
        +GetVehicleHistory(VehicleId, HistoryArray, HistoryCount) int
    }
    
    class IBMiConnector {
        -config
        -conn
        -transport
        +connect() bool
        +disconnect() void
        -_call_service_program(pgm_name, proc_name, params) result
        +add_vehicle(vehicle, user_id) int
        +get_vehicle_by_id(vehicle_id) Vehicle
        +update_vehicle(vehicle, user_id) int
        +delete_vehicle(vehicle_id, user_id) int
        +update_vehicle_status(vehicle_id, new_status, date_sold, user_id, notes) int
        +list_vehicles(filter_dict) List~Vehicle~
        +get_vehicle_history(vehicle_id) List~VehicleHistory~
    }
    
    class VehicleDS {
        +VehicleId int
        +Make string
        +Model string
        +Trim string
        +Year int
        +VIN string
        +Color string
        +Odometer int
        +ConditionRating int
        +AcquisitionPrice decimal
        +AskingPrice decimal
        +DateAcquired date
        +DateSold date
        +Status string
        +Notes string
        +LastUpdated timestamp
    }
    
    class Vehicle {
        +vehicle_id int
        +make string
        +model string
        +trim string
        +year int
        +vin string
        +color string
        +odometer int
        +condition_rating int
        +acquisition_price decimal
        +asking_price decimal
        +date_acquired date
        +date_sold date
        +status string
        +notes string
        +last_updated timestamp
        +from_dict(data) void
        +to_dict() dict
    }
    
    VEHCRUD_Service -- VehicleDS
    IBMiConnector -- Vehicle
    VehicleDS <|.. Vehicle : maps to
```

#### Zoom-in: Data Access Layer Implementation

```mermaid
sequenceDiagram
    participant Client
    participant Connector as IBMiConnector
    participant iToolkit as iToolkit
    participant Transport as DatabaseTransport
    participant DB as IBM i DB2
    participant VEHCRUD as VEHCRUD Service Program
    
    Client->>Connector: add_vehicle(vehicle, user_id)
    Connector->>Connector: connect()
    Connector->>iToolkit: create toolkit
    Connector->>iToolkit: add service program call
    iToolkit->>Transport: call(xml)
    Transport->>DB: execute SQL
    DB->>VEHCRUD: call service program
    VEHCRUD->>DB: INSERT INTO VEHICLES
    VEHCRUD->>DB: INSERT INTO VEHICLE_HISTORY
    DB-->>VEHCRUD: return vehicle_id
    VEHCRUD-->>Transport: return result
    Transport-->>iToolkit: return xml output
    iToolkit-->>Connector: return parsed result
    Connector-->>Client: return vehicle_id
```

### 3.2 Business Logic Layer

The Business Logic Layer implements domain-specific rules and calculations.

```mermaid
classDiagram
    class VEHBIZ_Service {
        +CalculateVehicleProfit(VehicleId) decimal
        +CalculateAggregateProfitByDate(Timeframe, ProfitSummary) int
        +CalculateSalesMetricsByTimeframe(Timeframe, TimeframeType, MetricsArray, MetricsCount) int
        +CalculateInventoryValuation(InventoryValue) int
        +CalculateAverageTimeToSale(Timeframe) int
        +CalculateTopSellingModels(Timeframe, TopCount, ResultArray, ResultCount) int
        +CalculateProfitMargin(VehicleId) decimal
        +CalculateMonthlyProfitLast12Months(MetricsArray, MetricsCount) int
    }
    
    class IBMiVehBizConnector {
        +calculate_vehicle_profit(vehicle_id) decimal
        +calculate_days_in_inventory(vehicle_id) int
        +calculate_days_to_sell(vehicle_id) int
        +calculate_profit_summary(start_date, end_date) ProfitSummary
        +calculate_inventory_value() InventoryValue
        +get_monthly_sales_metrics(year) List~SalesMetrics~
        +get_yearly_sales_metrics(start_year, end_year) List~SalesMetrics~
        +calculate_price_adjustment(vehicle_id, days_threshold, percentage) decimal
        +apply_price_adjustment(vehicle_id, days_threshold, percentage, user_id) int
        +apply_bulk_price_adjustment(days_threshold, percentage, user_id) int
    }
    
    class ProfitSummaryDS {
        +TotalVehicles int
        +TotalRevenue decimal
        +TotalCost decimal
        +TotalProfit decimal
        +AverageProfit decimal
        +AverageDaysToSell int
    }
    
    class ProfitSummary {
        +total_vehicles int
        +total_revenue decimal
        +total_cost decimal
        +total_profit decimal
        +average_profit decimal
        +average_days_to_sell int
        +from_dict(data) void
        +to_dict() dict
    }
    
    VEHBIZ_Service -- ProfitSummaryDS
    IBMiVehBizConnector -- ProfitSummary
    ProfitSummaryDS <|.. ProfitSummary : maps to
    IBMiVehBizConnector --|> IBMiConnector : extends
```

#### Zoom-in: Business Logic Implementation

```mermaid
flowchart TD
    subgraph "Business Logic Operations"
        Profit["Calculate Profit"]
        Metrics["Sales Metrics"]
        Inventory["Inventory Valuation"]
        Pricing["Price Adjustments"]
    end
    
    subgraph "Business Rules"
        ProfitRule["Profit = Sale Price - Acquisition Price - Expenses"]
        AgeRule["Price Adjustment based on Inventory Age"]
        ConditionRule["Pricing based on Vehicle Condition"]
        PerformanceRule["Performance Metrics Calculation"]
    end
    
    subgraph "Data Access"
        VEHCRUD["VEHCRUD Service"]
        DB["Database"]
    end
    
    Profit --> ProfitRule
    Metrics --> PerformanceRule
    Inventory --> ConditionRule
    Pricing --> AgeRule
    
    ProfitRule & AgeRule & ConditionRule & PerformanceRule --> VEHCRUD
    VEHCRUD --> DB
```

### 3.3 Presentation Layer

The Presentation Layer provides user interfaces for interacting with the system.

```mermaid
classDiagram
    class FlaskApp {
        +index() render_template
        +inventory() render_template
        +vehicle_detail(vehicle_id) render_template
        +add_vehicle() render_template
        +edit_vehicle(vehicle_id) render_template
        +update_vehicle_status(vehicle_id) redirect
    }
    
    class RPGPrograms {
        +VEHMGMT program
        +REPMENU program
        +INVRPT program
        +MONTHRPT program
    }
    
    class DisplayFiles {
        +VEHMGMTD display file
        +REPMENU display file
        +INVRPTD display file
        +MONTHRPTD display file
    }
    
    class Templates {
        +base.html
        +index.html
        +inventory.html
        +vehicle_detail.html
        +vehicle_form.html
    }
    
    FlaskApp -- Templates : renders
    RPGPrograms -- DisplayFiles : uses
    FlaskApp -- IBMiConnector : uses
    RPGPrograms -- VEHBIZ_Service : calls
    RPGPrograms -- VEHCRUD_Service : calls
```

#### Zoom-in: Web Interface Implementation

```mermaid
sequenceDiagram
    participant User
    participant Browser
    participant Flask as Flask App
    participant Template as Jinja Templates
    participant Connector as IBMiConnector
    participant VEHCRUD as VEHCRUD Service
    
    User->>Browser: Navigate to /inventory
    Browser->>Flask: GET /inventory
    Flask->>Connector: list_vehicles(filter)
    Connector->>VEHCRUD: ListVehicles
    VEHCRUD-->>Connector: vehicle list
    Connector-->>Flask: vehicle objects
    Flask->>Template: render inventory.html
    Template-->>Flask: HTML content
    Flask-->>Browser: HTTP response
    Browser-->>User: Display inventory page
```

#### Zoom-in: IBM i Interface Implementation

```mermaid
sequenceDiagram
    participant User
    participant Terminal
    participant VEHMGMT as VEHMGMT Program
    participant VEHMGMTD as VEHMGMTD Display File
    participant VEHCRUD as VEHCRUD Service
    participant DB as Database
    
    User->>Terminal: Start VEHMGMT
    Terminal->>VEHMGMT: Call program
    VEHMGMT->>VEHMGMTD: Display main screen
    VEHMGMTD-->>User: Show vehicle management screen
    User->>VEHMGMTD: Enter vehicle details
    VEHMGMTD->>VEHMGMT: Submit form data
    VEHMGMT->>VEHCRUD: AddVehicle
    VEHCRUD->>DB: Insert vehicle data
    DB-->>VEHCRUD: Return success
    VEHCRUD-->>VEHMGMT: Return result
    VEHMGMT->>VEHMGMTD: Display confirmation
    VEHMGMTD-->>User: Show success message
```

## 4. Integration Architecture

The system integrates IBM i backend services with a Python web interface.

```mermaid
graph TD
    subgraph "IBM i Environment"
        DB[(DB2 Database)]
        VEHCRUD["VEHCRUD Service Program"]
        VEHBIZ["VEHBIZ Service Program"]
        RPG["RPG UI Programs"]
    end
    
    subgraph "Python Environment"
        Flask["Flask Web App"]
        Connector["IBM i Connector"]
        VehBizConnector["VEHBIZ Connector"]
        Templates["HTML Templates"]
    end
    
    DB <--> VEHCRUD
    VEHCRUD <--> VEHBIZ
    VEHBIZ <--> RPG
    VEHCRUD <--> Connector
    VEHBIZ <--> VehBizConnector
    Connector <--> Flask
    VehBizConnector <--> Flask
    Flask <--> Templates
```

### 4.1 IBM i to Python Integration

```mermaid
sequenceDiagram
    participant Flask as Flask App
    participant Connector as IBMiConnector
    participant iToolkit as iToolkit
    participant DB as IBM i DB2
    participant VEHCRUD as VEHCRUD Service
    
    Flask->>Connector: call method
    Connector->>iToolkit: create service program call
    iToolkit->>DB: execute via DatabaseTransport
    DB->>VEHCRUD: call service program
    VEHCRUD->>DB: execute SQL
    DB-->>VEHCRUD: return data
    VEHCRUD-->>iToolkit: return result
    iToolkit-->>Connector: return XML output
    Connector-->>Flask: return Python objects
```

## 5. Deployment Architecture

```mermaid
flowchart TD
    subgraph "IBM i Server"
        DB[(DB2 Database)]
        VEHCRUD["VEHCRUD Service Program"]
        VEHBIZ["VEHBIZ Service Program"]
        RPG["RPG UI Programs"]
        DspF["Display Files"]
    end
    
    subgraph "Web Server"
        Flask["Flask Application"]
        Connector["IBM i Connector"]
        Static["Static Assets"]
    end
    
    subgraph "Client Devices"
        Browser["Web Browser"]
        Terminal["5250 Terminal"]
    end
    
    DB <--> VEHCRUD
    VEHCRUD <--> VEHBIZ
    VEHBIZ <--> RPG
    RPG <--> DspF
    VEHCRUD <--> Connector
    VEHBIZ <--> Connector
    Connector <--> Flask
    Flask <--> Static
    Flask <--> Browser
    DspF <--> Terminal
```

## 6. Security Architecture

```mermaid
flowchart TD
    subgraph "Authentication & Authorization"
        WebAuth["Web Authentication"]
        IBMiAuth["IBM i Authentication"]
        UserRoles["User Roles & Permissions"]
    end
    
    subgraph "Data Security"
        Encryption["Data Encryption"]
        SecureConn["Secure Connections"]
        AuditLog["Audit Logging"]
    end
    
    subgraph "Application Security"
        InputVal["Input Validation"]
        CSRF["CSRF Protection"]
        XSS["XSS Prevention"]
    end
    
    WebAuth --> UserRoles
    IBMiAuth --> UserRoles
    UserRoles --> Encryption
    SecureConn --> Encryption
    InputVal --> AuditLog
    CSRF --> AuditLog
    XSS --> AuditLog
```

## 7. Conclusion

The Used Car Lot application architecture combines traditional IBM i components with modern web technologies to create a robust, scalable system. The layered architecture ensures separation of concerns, while the integration between IBM i and Python provides flexibility in user interface options.

Key architectural strengths:
- Clear separation of data access, business logic, and presentation layers
- Dual interface options (web and green-screen) using the same backend
- Comprehensive data model with history tracking
- Robust business logic for financial calculations and inventory management
- Secure integration between IBM i and web components