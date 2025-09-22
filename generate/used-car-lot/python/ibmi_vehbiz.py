#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
IBM i VEHBIZ Connector Module

This module provides functions for connecting to IBM i and calling the VEHBIZ service program
for the Used Car Dealership Inventory System.
"""

import os
import datetime
import decimal
from typing import List, Dict, Any, Optional, Tuple

# Import from ibmi_connector
from ibmi_connector import IBMiConnector, Vehicle, CONFIG, ProfitSummary, InventoryValue, SalesMetrics

class IBMiVehBizConnector(IBMiConnector):
    """IBM i Connector class for calling VEHBIZ service program"""
    
    def calculate_vehicle_profit(self, vehicle_id: int) -> decimal.Decimal:
        """Calculate profit for a specific vehicle"""
        params = [
            # Vehicle ID
            ('VehicleId', '10i0', 'in', vehicle_id),
            
            # Return value
            ('Profit', '10p2', 'out', '')
        ]
        
        result = self._call_service_program('VEHBIZ', 'CalculateVehicleProfit', params)
        
        if result and 'CalculateVehicleProfit' in result:
            return decimal.Decimal(str(result['CalculateVehicleProfit']['Profit']['data']))
        
        return decimal.Decimal('0.00')
    
    def calculate_days_in_inventory(self, vehicle_id: int) -> int:
        """Calculate days in inventory for a specific vehicle"""
        params = [
            # Vehicle ID
            ('VehicleId', '10i0', 'in', vehicle_id),
            
            # Return value
            ('Days', '10i0', 'out', '')
        ]
        
        result = self._call_service_program('VEHBIZ', 'CalculateDaysInInventory', params)
        
        if result and 'CalculateDaysInInventory' in result:
            return int(result['CalculateDaysInInventory']['Days']['data'])
        
        return 0
    
    def calculate_days_to_sell(self, vehicle_id: int) -> int:
        """Calculate days to sell for a specific vehicle"""
        params = [
            # Vehicle ID
            ('VehicleId', '10i0', 'in', vehicle_id),
            
            # Return value
            ('Days', '10i0', 'out', '')
        ]
        
        result = self._call_service_program('VEHBIZ', 'CalculateDaysToSell', params)
        
        if result and 'CalculateDaysToSell' in result:
            return int(result['CalculateDaysToSell']['Days']['data'])
        
        return 0
    
    def calculate_profit_summary(self, start_date: Optional[datetime.date] = None, 
                               end_date: Optional[datetime.date] = None) -> ProfitSummary:
        """Calculate profit summary for a date range"""
        params = [
            # Start date (optional)
            ('StartDate', '10A', 'in', start_date.strftime('%Y-%m-%d') if start_date else ''),
            
            # End date (optional)
            ('EndDate', '10A', 'in', end_date.strftime('%Y-%m-%d') if end_date else ''),
            
            # Profit summary data structure
            iDS('ProfitSummary', {'dim': ''}),
            ('TotalVehicles', '10i0', 'out', ''),
            ('TotalRevenue', '10p2', 'out', ''),
            ('TotalCost', '10p2', 'out', ''),
            ('TotalProfit', '10p2', 'out', ''),
            ('AverageProfit', '10p2', 'out', ''),
            ('AverageDaysToSell', '10i0', 'out', ''),
            iDS('ProfitSummary', {'endds': ''})
        ]
        
        result = self._call_service_program('VEHBIZ', 'CalculateProfitSummary', params)
        
        if result and 'CalculateProfitSummary' in result:
            data = result['CalculateProfitSummary']['ProfitSummary']
            
            summary_dict = {
                'total_vehicles': int(data['TotalVehicles']['data']),
                'total_revenue': float(data['TotalRevenue']['data']),
                'total_cost': float(data['TotalCost']['data']),
                'total_profit': float(data['TotalProfit']['data']),
                'average_profit': float(data['AverageProfit']['data']),
                'average_days_to_sell': int(data['AverageDaysToSell']['data'])
            }
            
            return ProfitSummary(summary_dict)
        
        return ProfitSummary()
    
    def calculate_inventory_value(self) -> InventoryValue:
        """Calculate current inventory value"""
        params = [
            # Inventory value data structure
            iDS('InventoryValue', {'dim': ''}),
            ('TotalVehicles', '10i0', 'out', ''),
            ('TotalValue', '10p2', 'out', ''),
            ('AverageValue', '10p2', 'out', ''),
            ('OldestVehicleDays', '10i0', 'out', ''),
            ('AverageDaysInInventory', '10i0', 'out', ''),
            iDS('InventoryValue', {'endds': ''})
        ]
        
        result = self._call_service_program('VEHBIZ', 'CalculateInventoryValue', params)
        
        if result and 'CalculateInventoryValue' in result:
            data = result['CalculateInventoryValue']['InventoryValue']
            
            value_dict = {
                'total_vehicles': int(data['TotalVehicles']['data']),
                'total_value': float(data['TotalValue']['data']),
                'average_value': float(data['AverageValue']['data']),
                'oldest_vehicle_days': int(data['OldestVehicleDays']['data']),
                'average_days_in_inventory': int(data['AverageDaysInInventory']['data'])
            }
            
            return InventoryValue(value_dict)
        
        return InventoryValue()
    
    def get_monthly_sales_metrics(self, year: int) -> List[SalesMetrics]:
        """Get monthly sales metrics for a specific year"""
        params = [
            # Year
            ('Year', '10i0', 'in', year),
            
            # Sales metrics array
            iDS('SalesMetricsArray', {'dim': '12'}),
            ('Period', '10A', 'out', ''),
            ('VehiclesSold', '10i0', 'out', ''),
            ('TotalRevenue', '10p2', 'out', ''),
            ('TotalProfit', '10p2', 'out', ''),
            ('AverageProfit', '10p2', 'out', ''),
            ('AverageDaysToSell', '10i0', 'out', ''),
            iDS('SalesMetricsArray', {'endds': ''}),
            
            # Metrics count
            ('MetricsCount', '10i0', 'out', '')
        ]
        
        result = self._call_service_program('VEHBIZ', 'GetMonthlySalesMetrics', params)
        
        metrics_list = []
        if result and 'GetMonthlySalesMetrics' in result:
            count = int(result['GetMonthlySalesMetrics']['MetricsCount']['data'])
            
            if count > 0:
                # Extract metrics data from result
                metrics_array = result['GetMonthlySalesMetrics']['SalesMetricsArray']
                
                for i in range(count):
                    idx = str(i)
                    metrics_dict = {
                        'period': metrics_array['Period'][idx]['data'].strip(),
                        'vehicles_sold': int(metrics_array['VehiclesSold'][idx]['data']),
                        'total_revenue': float(metrics_array['TotalRevenue'][idx]['data']),
                        'total_profit': float(metrics_array['TotalProfit'][idx]['data']),
                        'average_profit': float(metrics_array['AverageProfit'][idx]['data']),
                        'average_days_to_sell': int(metrics_array['AverageDaysToSell'][idx]['data'])
                    }
                    
                    metrics_list.append(SalesMetrics(metrics_dict))
        
        return metrics_list
    
    def get_yearly_sales_metrics(self, start_year: int, end_year: int) -> List[SalesMetrics]:
        """Get yearly sales metrics for a range of years"""
        params = [
            # Start year
            ('StartYear', '10i0', 'in', start_year),
            
            # End year
            ('EndYear', '10i0', 'in', end_year),
            
            # Sales metrics array
            iDS('SalesMetricsArray', {'dim': '20'}),
            ('Period', '10A', 'out', ''),
            ('VehiclesSold', '10i0', 'out', ''),
            ('TotalRevenue', '10p2', 'out', ''),
            ('TotalProfit', '10p2', 'out', ''),
            ('AverageProfit', '10p2', 'out', ''),
            ('AverageDaysToSell', '10i0', 'out', ''),
            iDS('SalesMetricsArray', {'endds': ''}),
            
            # Metrics count
            ('MetricsCount', '10i0', 'out', '')
        ]
        
        result = self._call_service_program('VEHBIZ', 'GetYearlySalesMetrics', params)
        
        metrics_list = []
        if result and 'GetYearlySalesMetrics' in result:
            count = int(result['GetYearlySalesMetrics']['MetricsCount']['data'])
            
            if count > 0:
                # Extract metrics data from result
                metrics_array = result['GetYearlySalesMetrics']['SalesMetricsArray']
                
                for i in range(count):
                    idx = str(i)
                    metrics_dict = {
                        'period': metrics_array['Period'][idx]['data'].strip(),
                        'vehicles_sold': int(metrics_array['VehiclesSold'][idx]['data']),
                        'total_revenue': float(metrics_array['TotalRevenue'][idx]['data']),
                        'total_profit': float(metrics_array['TotalProfit'][idx]['data']),
                        'average_profit': float(metrics_array['AverageProfit'][idx]['data']),
                        'average_days_to_sell': int(metrics_array['AverageDaysToSell'][idx]['data'])
                    }
                    
                    metrics_list.append(SalesMetrics(metrics_dict))
        
        return metrics_list
    
    def calculate_price_adjustment(self, vehicle_id: int, days_threshold: int, 
                                 percentage: float) -> decimal.Decimal:
        """Calculate price adjustment based on days in inventory"""
        params = [
            # Vehicle ID
            ('VehicleId', '10i0', 'in', vehicle_id),
            
            # Days threshold
            ('DaysThreshold', '10i0', 'in', days_threshold),
            
            # Percentage
            ('Percentage', '10p2', 'in', percentage),
            
            # New price
            ('NewPrice', '10p2', 'out', '')
        ]
        
        result = self._call_service_program('VEHBIZ', 'CalculatePriceAdjustment', params)
        
        if result and 'CalculatePriceAdjustment' in result:
            return decimal.Decimal(str(result['CalculatePriceAdjustment']['NewPrice']['data']))
        
        return decimal.Decimal('0.00')
    
    def apply_price_adjustment(self, vehicle_id: int, days_threshold: int, 
                             percentage: float, user_id: str) -> int:
        """Apply price adjustment based on days in inventory"""
        params = [
            # Vehicle ID
            ('VehicleId', '10i0', 'in', vehicle_id),
            
            # Days threshold
            ('DaysThreshold', '10i0', 'in', days_threshold),
            
            # Percentage
            ('Percentage', '10p2', 'in', percentage),
            
            # User ID
            ('UserId', '10A', 'in', user_id)
        ]
        
        result = self._call_service_program('VEHBIZ', 'ApplyPriceAdjustment', params)
        
        if result and 'ApplyPriceAdjustment' in result:
            return int(result['ApplyPriceAdjustment']['return']['data'])
        
        return -1
    
    def apply_bulk_price_adjustment(self, days_threshold: int, percentage: float, 
                                  user_id: str) -> int:
        """Apply price adjustment to all vehicles over days threshold"""
        params = [
            # Days threshold
            ('DaysThreshold', '10i0', 'in', days_threshold),
            
            # Percentage
            ('Percentage', '10p2', 'in', percentage),
            
            # User ID
            ('UserId', '10A', 'in', user_id),
            
            # Vehicles adjusted
            ('VehiclesAdjusted', '10i0', 'out', '')
        ]
        
        result = self._call_service_program('VEHBIZ', 'ApplyBulkPriceAdjustment', params)
        
        if result and 'ApplyBulkPriceAdjustment' in result:
            return int(result['ApplyBulkPriceAdjustment']['VehiclesAdjusted']['data'])
        
        return 0

# Made with Bob
