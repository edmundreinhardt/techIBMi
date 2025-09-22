#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
IBM i Connector Module

This module provides functions for connecting to IBM i and calling the service programs
for the Used Car Dealership Inventory System.
"""

import os
import datetime
import decimal
from typing import List, Dict, Any, Optional, Tuple

try:
    import itoolkit
    from itoolkit import iCmd, iPgm, iSrvPgm, iData, iDS
    from itoolkit.transport import DatabaseTransport
    import ibm_db_dbi as dbi
except ImportError:
    print("Error: Required modules not found. Please install the following modules:")
    print("pip install itoolkit ibm_db ibm_db_dbi")
    exit(1)

# Configuration
CONFIG = {
    'database': 'USEDCAR',
    'user': os.environ.get('IBMI_USER', ''),
    'password': os.environ.get('IBMI_PASSWORD', ''),
    'host': os.environ.get('IBMI_HOST', 'localhost'),
    'library': os.environ.get('IBMI_LIBRARY', 'USEDCAR')
}

# Data structure definitions
class Vehicle:
    """Vehicle data structure"""
    def __init__(self, data=None):
        self.vehicle_id = 0
        self.make = ""
        self.model = ""
        self.trim = ""
        self.year = 0
        self.vin = ""
        self.color = ""
        self.odometer = 0
        self.condition_rating = 0
        self.acquisition_price = decimal.Decimal('0.00')
        self.asking_price = decimal.Decimal('0.00')
        self.date_acquired = None
        self.date_sold = None
        self.status = "AVAILABLE"
        self.notes = ""
        self.last_updated = None
        
        if data:
            self.from_dict(data)
    
    def from_dict(self, data):
        """Initialize from dictionary"""
        self.vehicle_id = int(data.get('vehicle_id', 0))
        self.make = data.get('make', '')
        self.model = data.get('model', '')
        self.trim = data.get('trim', '')
        self.year = int(data.get('year', 0))
        self.vin = data.get('vin', '')
        self.color = data.get('color', '')
        self.odometer = int(data.get('odometer', 0))
        self.condition_rating = int(data.get('condition_rating', 0))
        self.acquisition_price = decimal.Decimal(str(data.get('acquisition_price', '0.00')))
        self.asking_price = decimal.Decimal(str(data.get('asking_price', '0.00')))
        
        if 'date_acquired' in data and data['date_acquired']:
            if isinstance(data['date_acquired'], str):
                self.date_acquired = datetime.datetime.strptime(data['date_acquired'], '%Y-%m-%d').date()
            else:
                self.date_acquired = data['date_acquired']
        
        if 'date_sold' in data and data['date_sold']:
            if isinstance(data['date_sold'], str):
                self.date_sold = datetime.datetime.strptime(data['date_sold'], '%Y-%m-%d').date()
            else:
                self.date_sold = data['date_sold']
        
        self.status = data.get('status', 'AVAILABLE')
        self.notes = data.get('notes', '')
        
        if 'last_updated' in data and data['last_updated']:
            if isinstance(data['last_updated'], str):
                self.last_updated = datetime.datetime.strptime(data['last_updated'], '%Y-%m-%d %H:%M:%S')
            else:
                self.last_updated = data['last_updated']
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'vehicle_id': self.vehicle_id,
            'make': self.make,
            'model': self.model,
            'trim': self.trim,
            'year': self.year,
            'vin': self.vin,
            'color': self.color,
            'odometer': self.odometer,
            'condition_rating': self.condition_rating,
            'acquisition_price': str(self.acquisition_price),
            'asking_price': str(self.asking_price),
            'date_acquired': self.date_acquired.strftime('%Y-%m-%d') if self.date_acquired else None,
            'date_sold': self.date_sold.strftime('%Y-%m-%d') if self.date_sold else None,
            'status': self.status,
            'notes': self.notes,
            'last_updated': self.last_updated.strftime('%Y-%m-%d %H:%M:%S') if self.last_updated else None
        }


class VehicleHistory:
    """Vehicle history data structure"""
    def __init__(self, data=None):
        self.history_id = 0
        self.vehicle_id = 0
        self.event_type = ""
        self.event_date = None
        self.old_status = ""
        self.new_status = ""
        self.old_price = decimal.Decimal('0.00')
        self.new_price = decimal.Decimal('0.00')
        self.user_id = ""
        self.notes = ""
        
        if data:
            self.from_dict(data)
    
    def from_dict(self, data):
        """Initialize from dictionary"""
        self.history_id = int(data.get('history_id', 0))
        self.vehicle_id = int(data.get('vehicle_id', 0))
        self.event_type = data.get('event_type', '')
        
        if 'event_date' in data and data['event_date']:
            if isinstance(data['event_date'], str):
                self.event_date = datetime.datetime.strptime(data['event_date'], '%Y-%m-%d %H:%M:%S')
            else:
                self.event_date = data['event_date']
        
        self.old_status = data.get('old_status', '')
        self.new_status = data.get('new_status', '')
        self.old_price = decimal.Decimal(str(data.get('old_price', '0.00')))
        self.new_price = decimal.Decimal(str(data.get('new_price', '0.00')))
        self.user_id = data.get('user_id', '')
        self.notes = data.get('notes', '')
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'history_id': self.history_id,
            'vehicle_id': self.vehicle_id,
            'event_type': self.event_type,
            'event_date': self.event_date.strftime('%Y-%m-%d %H:%M:%S') if self.event_date else None,
            'old_status': self.old_status,
            'new_status': self.new_status,
            'old_price': str(self.old_price),
            'new_price': str(self.new_price),
            'user_id': self.user_id,
            'notes': self.notes
        }


class ProfitSummary:
    """Profit summary data structure"""
    def __init__(self, data=None):
        self.total_vehicles = 0
        self.total_revenue = decimal.Decimal('0.00')
        self.total_cost = decimal.Decimal('0.00')
        self.total_profit = decimal.Decimal('0.00')
        self.average_profit = decimal.Decimal('0.00')
        self.average_days_to_sell = 0
        
        if data:
            self.from_dict(data)
    
    def from_dict(self, data):
        """Initialize from dictionary"""
        self.total_vehicles = int(data.get('total_vehicles', 0))
        self.total_revenue = decimal.Decimal(str(data.get('total_revenue', '0.00')))
        self.total_cost = decimal.Decimal(str(data.get('total_cost', '0.00')))
        self.total_profit = decimal.Decimal(str(data.get('total_profit', '0.00')))
        self.average_profit = decimal.Decimal(str(data.get('average_profit', '0.00')))
        self.average_days_to_sell = int(data.get('average_days_to_sell', 0))
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'total_vehicles': self.total_vehicles,
            'total_revenue': str(self.total_revenue),
            'total_cost': str(self.total_cost),
            'total_profit': str(self.total_profit),
            'average_profit': str(self.average_profit),
            'average_days_to_sell': self.average_days_to_sell
        }


class InventoryValue:
    """Inventory value data structure"""
    def __init__(self, data=None):
        self.total_vehicles = 0
        self.total_value = decimal.Decimal('0.00')
        self.average_value = decimal.Decimal('0.00')
        self.oldest_vehicle_days = 0
        self.average_days_in_inventory = 0
        
        if data:
            self.from_dict(data)
    
    def from_dict(self, data):
        """Initialize from dictionary"""
        self.total_vehicles = int(data.get('total_vehicles', 0))
        self.total_value = decimal.Decimal(str(data.get('total_value', '0.00')))
        self.average_value = decimal.Decimal(str(data.get('average_value', '0.00')))
        self.oldest_vehicle_days = int(data.get('oldest_vehicle_days', 0))
        self.average_days_in_inventory = int(data.get('average_days_in_inventory', 0))
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'total_vehicles': self.total_vehicles,
            'total_value': str(self.total_value),
            'average_value': str(self.average_value),
            'oldest_vehicle_days': self.oldest_vehicle_days,
            'average_days_in_inventory': self.average_days_in_inventory
        }


class SalesMetrics:
    """Sales metrics data structure"""
    def __init__(self, data=None):
        self.period = ""
        self.vehicles_sold = 0
        self.total_revenue = decimal.Decimal('0.00')
        self.total_profit = decimal.Decimal('0.00')
        self.average_profit = decimal.Decimal('0.00')
        self.average_days_to_sell = 0
        
        if data:
            self.from_dict(data)
    
    def from_dict(self, data):
        """Initialize from dictionary"""
        self.period = data.get('period', '')
        self.vehicles_sold = int(data.get('vehicles_sold', 0))
        self.total_revenue = decimal.Decimal(str(data.get('total_revenue', '0.00')))
        self.total_profit = decimal.Decimal(str(data.get('total_profit', '0.00')))
        self.average_profit = decimal.Decimal(str(data.get('average_profit', '0.00')))
        self.average_days_to_sell = int(data.get('average_days_to_sell', 0))
    
    def to_dict(self):
        """Convert to dictionary"""
        return {
            'period': self.period,
            'vehicles_sold': self.vehicles_sold,
            'total_revenue': str(self.total_revenue),
            'total_profit': str(self.total_profit),
            'average_profit': str(self.average_profit),
            'average_days_to_sell': self.average_days_to_sell
        }


class IBMiConnector:
    """IBM i Connector class for calling service programs"""
    
    def __init__(self, config=None):
        """Initialize the connector"""
        self.config = config or CONFIG
        self.conn = None
        self.transport = None
    
    def connect(self):
        """Connect to IBM i"""
        try:
            conn_str = f"DATABASE={self.config['database']};HOSTNAME={self.config['host']};UID={self.config['user']};PWD={self.config['password']}"
            self.conn = dbi.connect(conn_str)
            self.transport = DatabaseTransport(self.conn)
            return True
        except Exception as e:
            print(f"Error connecting to IBM i: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from IBM i"""
        if self.conn:
            self.conn.close()
            self.conn = None
            self.transport = None
    
    def __enter__(self):
        """Context manager entry"""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.disconnect()
    
    def _call_service_program(self, pgm_name, proc_name, params):
        """Call a service program procedure"""
        if not self.conn:
            if not self.connect():
                return None
        
        try:
            itool = itoolkit.iToolKit()
            srvpgm = iSrvPgm(pgm_name, proc_name, self.config['library'])
            
            # Add parameters
            for param in params:
                if isinstance(param, tuple):
                    name, data_type, io_type, value = param
                    srvpgm.addParm(iData(name, data_type, io_type, value))
                else:
                    srvpgm.addParm(param)
            
            itool.add(srvpgm)
            xml_output = itool.call(self.transport)
            result = itool.dict_out(xml_output)
            
            return result
        except Exception as e:
            print(f"Error calling service program: {e}")
            return None
    
    # VEHCRUD Service Program Functions
    
    def add_vehicle(self, vehicle: Vehicle, user_id: str) -> int:
        """Add a new vehicle to the inventory"""
        params = [
            # Vehicle data structure
            iDS('VehicleData', {'dim': ''}),
            ('Make', '50A', 'in', vehicle.make),
            ('Model', '50A', 'in', vehicle.model),
            ('Trim', '50A', 'in', vehicle.trim),
            ('Year', '10i0', 'in', vehicle.year),
            ('VIN', '17A', 'in', vehicle.vin),
            ('Color', '30A', 'in', vehicle.color),
            ('Odometer', '10i0', 'in', vehicle.odometer),
            ('ConditionRating', '10i0', 'in', vehicle.condition_rating),
            ('AcquisitionPrice', '10p2', 'in', float(vehicle.acquisition_price)),
            ('AskingPrice', '10p2', 'in', float(vehicle.asking_price)),
            ('DateAcquired', '10A', 'in', vehicle.date_acquired.strftime('%Y-%m-%d') if vehicle.date_acquired else ''),
            ('DateSold', '10A', 'in', vehicle.date_sold.strftime('%Y-%m-%d') if vehicle.date_sold else ''),
            ('Status', '10A', 'in', vehicle.status),
            ('Notes', '1000A', 'in', vehicle.notes),
            iDS('VehicleData', {'endds': ''}),
            
            # User ID
            ('UserId', '10A', 'in', user_id)
        ]
        
        result = self._call_service_program('VEHCRUD', 'AddVehicle', params)
        
        if result and 'AddVehicle' in result:
            return int(result['AddVehicle']['return']['data'])
        
        return -1
    
    def get_vehicle_by_id(self, vehicle_id: int) -> Optional[Vehicle]:
        """Get vehicle details by ID"""
        params = [
            # Vehicle ID
            ('VehicleId', '10i0', 'in', vehicle_id),
            
            # Vehicle data structure
            iDS('VehicleData', {'dim': ''}),
            ('VehicleId', '10i0', 'out', ''),
            ('Make', '50A', 'out', ''),
            ('Model', '50A', 'out', ''),
            ('Trim', '50A', 'out', ''),
            ('Year', '10i0', 'out', ''),
            ('VIN', '17A', 'out', ''),
            ('Color', '30A', 'out', ''),
            ('Odometer', '10i0', 'out', ''),
            ('ConditionRating', '10i0', 'out', ''),
            ('AcquisitionPrice', '10p2', 'out', ''),
            ('AskingPrice', '10p2', 'out', ''),
            ('DateAcquired', '10A', 'out', ''),
            ('DateSold', '10A', 'out', ''),
            ('Status', '10A', 'out', ''),
            ('Notes', '1000A', 'out', ''),
            ('LastUpdated', '26A', 'out', ''),
            iDS('VehicleData', {'endds': ''})
        ]
        
        result = self._call_service_program('VEHCRUD', 'GetVehicleById', params)
        
        if result and 'GetVehicleById' in result:
            ret_val = int(result['GetVehicleById']['return']['data'])
            
            if ret_val == 0:  # VEHCRUD_SUCCESS
                data = result['GetVehicleById']['VehicleData']
                
                vehicle_dict = {
                    'vehicle_id': int(data['VehicleId']['data']),
                    'make': data['Make']['data'].strip(),
                    'model': data['Model']['data'].strip(),
                    'trim': data['Trim']['data'].strip(),
                    'year': int(data['Year']['data']),
                    'vin': data['VIN']['data'].strip(),
                    'color': data['Color']['data'].strip(),
                    'odometer': int(data['Odometer']['data']),
                    'condition_rating': int(data['ConditionRating']['data']),
                    'acquisition_price': float(data['AcquisitionPrice']['data']),
                    'asking_price': float(data['AskingPrice']['data']),
                    'date_acquired': data['DateAcquired']['data'].strip(),
                    'date_sold': data['DateSold']['data'].strip(),
                    'status': data['Status']['data'].strip(),
                    'notes': data['Notes']['data'].strip(),
                    'last_updated': data['LastUpdated']['data'].strip()
                }
                
                return Vehicle(vehicle_dict)
        
        return None
    
    def update_vehicle(self, vehicle: Vehicle, user_id: str) -> int:
        """Update vehicle information"""
        params = [
            # Vehicle data structure
            iDS('VehicleData', {'dim': ''}),
            ('VehicleId', '10i0', 'in', vehicle.vehicle_id),
            ('Make', '50A', 'in', vehicle.make),
            ('Model', '50A', 'in', vehicle.model),
            ('Trim', '50A', 'in', vehicle.trim),
            ('Year', '10i0', 'in', vehicle.year),
            ('VIN', '17A', 'in', vehicle.vin),
            ('Color', '30A', 'in', vehicle.color),
            ('Odometer', '10i0', 'in', vehicle.odometer),
            ('ConditionRating', '10i0', 'in', vehicle.condition_rating),
            ('AcquisitionPrice', '10p2', 'in', float(vehicle.acquisition_price)),
            ('AskingPrice', '10p2', 'in', float(vehicle.asking_price)),
            ('DateAcquired', '10A', 'in', vehicle.date_acquired.strftime('%Y-%m-%d') if vehicle.date_acquired else ''),
            ('DateSold', '10A', 'in', vehicle.date_sold.strftime('%Y-%m-%d') if vehicle.date_sold else ''),
            ('Status', '10A', 'in', vehicle.status),
            ('Notes', '1000A', 'in', vehicle.notes),
            iDS('VehicleData', {'endds': ''}),
            
            # User ID
            ('UserId', '10A', 'in', user_id)
        ]
        
        result = self._call_service_program('VEHCRUD', 'UpdateVehicle', params)
        
        if result and 'UpdateVehicle' in result:
            return int(result['UpdateVehicle']['return']['data'])
        
        return -1
    
    def delete_vehicle(self, vehicle_id: int, user_id: str) -> int:
        """Delete a vehicle from the inventory"""
        params = [
            # Vehicle ID
            ('VehicleId', '10i0', 'in', vehicle_id),
            
            # User ID
            ('UserId', '10A', 'in', user_id)
        ]
        
        result = self._call_service_program('VEHCRUD', 'DeleteVehicle', params)
        
        if result and 'DeleteVehicle' in result:
            return int(result['DeleteVehicle']['return']['data'])
        
        return -1
    
    def update_vehicle_status(self, vehicle_id: int, new_status: str, date_sold: Optional[datetime.date], 
                             user_id: str, notes: str = '') -> int:
        """Update vehicle status"""
        params = [
            # Vehicle ID
            ('VehicleId', '10i0', 'in', vehicle_id),
            
            # New status
            ('NewStatus', '10A', 'in', new_status),
            
            # Date sold (optional)
            ('DateSold', '10A', 'in', date_sold.strftime('%Y-%m-%d') if date_sold else ''),
            
            # User ID
            ('UserId', '10A', 'in', user_id),
            
            # Notes (optional)
            ('Notes', '1000A', 'in', notes)
        ]
        
        result = self._call_service_program('VEHCRUD', 'UpdateVehicleStatus', params)
        
        if result and 'UpdateVehicleStatus' in result:
            return int(result['UpdateVehicleStatus']['return']['data'])
        
        return -1
    
    def list_vehicles(self, filter_dict: Optional[Dict[str, Any]] = None) -> List[Vehicle]:
        """List vehicles with optional filtering"""
        # Create filter data structure if provided
        filter_params = []
        if filter_dict:
            filter_params = [
                iDS('Filter', {'dim': ''}),
                ('Make', '50A', 'in', filter_dict.get('make', '')),
                ('Model', '50A', 'in', filter_dict.get('model', '')),
                ('YearFrom', '10i0', 'in', filter_dict.get('year_from', 0)),
                ('YearTo', '10i0', 'in', filter_dict.get('year_to', 0)),
                ('Status', '10A', 'in', filter_dict.get('status', '')),
                ('DateAcquiredFrom', '10A', 'in', filter_dict.get('date_acquired_from', '')),
                ('DateAcquiredTo', '10A', 'in', filter_dict.get('date_acquired_to', '')),
                ('DateSoldFrom', '10A', 'in', filter_dict.get('date_sold_from', '')),
                ('DateSoldTo', '10A', 'in', filter_dict.get('date_sold_to', '')),
                ('PriceFrom', '10p2', 'in', filter_dict.get('price_from', 0.0)),
                ('PriceTo', '10p2', 'in', filter_dict.get('price_to', 0.0)),
                iDS('Filter', {'endds': ''})
            ]
        
        # Result array and count
        params = filter_params + [
            # Result array
            iDS('ResultArray', {'dim': '999'}),
            ('VehicleId', '10i0', 'out', ''),
            ('Make', '50A', 'out', ''),
            ('Model', '50A', 'out', ''),
            ('Trim', '50A', 'out', ''),
            ('Year', '10i0', 'out', ''),
            ('VIN', '17A', 'out', ''),
            ('Color', '30A', 'out', ''),
            ('Odometer', '10i0', 'out', ''),
            ('ConditionRating', '10i0', 'out', ''),
            ('AcquisitionPrice', '10p2', 'out', ''),
            ('AskingPrice', '10p2', 'out', ''),
            ('DateAcquired', '10A', 'out', ''),
            ('DateSold', '10A', 'out', ''),
            ('Status', '10A', 'out', ''),
            ('Notes', '1000A', 'out', ''),
            ('LastUpdated', '26A', 'out', ''),
            iDS('ResultArray', {'endds': ''}),
            
            # Result count
            ('ResultCount', '10i0', 'out', '')
        ]
        
        result = self._call_service_program('VEHCRUD', 'ListVehicles', params)
        
        vehicles = []
        if result and 'ListVehicles' in result:
            count = int(result['ListVehicles']['ResultCount']['data'])
            
            if count > 0:
                # Extract vehicle data from result
                result_array = result['ListVehicles']['ResultArray']
                
                for i in range(count):
                    idx = str(i)
                    vehicle_dict = {
                        'vehicle_id': int(result_array['VehicleId'][idx]['data']),
                        'make': result_array['Make'][idx]['data'].strip(),
                        'model': result_array['Model'][idx]['data'].strip(),
                        'trim': result_array['Trim'][idx]['data'].strip(),
                        'year': int(result_array['Year'][idx]['data']),
                        'vin': result_array['VIN'][idx]['data'].strip(),
                        'color': result_array['Color'][idx]['data'].strip(),
                        'odometer': int(result_array['Odometer'][idx]['data']),
                        'condition_rating': int(result_array['ConditionRating'][idx]['data']),
                        'acquisition_price': float(result_array['AcquisitionPrice'][idx]['data']),
                        'asking_price': float(result_array['AskingPrice'][idx]['data']),
                        'date_acquired': result_array['DateAcquired'][idx]['data'].strip(),
                        'date_sold': result_array['DateSold'][idx]['data'].strip(),
                        'status': result_array['Status'][idx]['data'].strip(),
                        'notes': result_array['Notes'][idx]['data'].strip(),
                        'last_updated': result_array['LastUpdated'][idx]['data'].strip()
                    }
                    
                    vehicles.append(Vehicle(vehicle_dict))
        
        return vehicles
    
    def get_vehicle_history(self, vehicle_id: int) -> List[VehicleHistory]:
        """Get vehicle history by vehicle ID"""
        params = [
            # Vehicle ID
            ('VehicleId', '10i0', 'in', vehicle_id),
            
            # History array
            iDS('HistoryArray', {'dim': '999'}),
            ('HistoryId', '10i0', 'out', ''),
            ('VehicleId', '10i0', 'out', ''),
            ('EventType', '20A', 'out', ''),
            ('EventDate', '26A', 'out', ''),
            ('OldStatus', '10A', 'out', ''),
            ('NewStatus', '10A', 'out', ''),
            ('OldPrice', '10p2', 'out', ''),
            ('NewPrice', '10p2', 'out', ''),
            ('UserId', '10A', 'out', ''),
            ('Notes', '1000A', 'out', ''),
            iDS('HistoryArray', {'endds': ''}),
            
            # History count
            ('HistoryCount', '10i0', 'out', '')
        ]
        
        result = self._call_service_program('VEHCRUD', 'GetVehicleHistory', params)
        
        history_records = []
        if result and 'GetVehicleHistory' in result:
            count = int(result['GetVehicleHistory']['HistoryCount']['data'])
            
            if count > 0:
                # Extract history data from result
                history_array = result['GetVehicleHistory']['HistoryArray']
                
                for i in range(count):
                    idx = str(i)
                    history_dict = {
                        'history_id': int(history_array['HistoryId'][idx]['data']),
                        'vehicle_id': int(history_array['VehicleId'][idx]['data']),
                        'event_type': history_array['EventType'][idx]['data'].strip(),
                        'event_date': history_array['EventDate'][idx]['data'].strip(),
                        'old_status': history_array['OldStatus'][idx]['data'].strip(),
                        'new_status': history_array['NewStatus'][idx]['data'].strip(),
                        'old_price': float(history_array['OldPrice'][idx]['data']),
                        'new_price': float(history_array['NewPrice'][idx]['data']),
                        'user_id': history_array['UserId'][idx]['data'].strip(),
                        'notes': history_array['Notes'][idx]['data'].strip()
                    }
                    
                    history_records.append(VehicleHistory(history_dict))
        
        return history_records
    
    # VEHBIZ Service Program Functions are moved to ibmi_vehbiz.py

# Made with Bob
