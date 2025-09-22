#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Used Car Dealership Inventory System - Web Interface

This module provides a Flask web application for the Used Car Dealership Inventory System.
"""

import os
import datetime
import decimal
from typing import List, Dict, Any, Optional
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from werkzeug.security import generate_password_hash, check_password_hash

# Import connector modules
from ibmi_connector import IBMiConnector, Vehicle, VehicleHistory

# Create Flask application
app = Flask(__name__)
app.secret_key = os.environ.get('FLASK_SECRET_KEY', 'dev_key_for_testing_only')

# Configuration
app.config['IBMI_CONFIG'] = {
    'database': 'USEDCAR',
    'user': os.environ.get('IBMI_USER', ''),
    'password': os.environ.get('IBMI_PASSWORD', ''),
    'host': os.environ.get('IBMI_HOST', 'localhost'),
    'library': os.environ.get('IBMI_LIBRARY', 'USEDCAR')
}

# Create connector instance
connector = IBMiConnector(app.config['IBMI_CONFIG'])

# Helper functions
def format_currency(value):
    """Format decimal value as currency"""
    if isinstance(value, str):
        value = decimal.Decimal(value)
    return f"${value:,.2f}"

def format_date(date_str):
    """Format date string"""
    if not date_str:
        return ""
    try:
        date_obj = datetime.datetime.strptime(date_str, '%Y-%m-%d').date()
        return date_obj.strftime('%m/%d/%Y')
    except ValueError:
        return date_str

# Template filters
app.jinja_env.filters['currency'] = format_currency
app.jinja_env.filters['format_date'] = format_date

# Routes
@app.route('/')
def index():
    """Home page"""
    try:
        # Get available vehicles count
        available_vehicles = connector.list_vehicles({'status': 'AVAILABLE'})
        available_count = len(available_vehicles)
        
        # Get sold vehicles in the last 30 days
        thirty_days_ago = (datetime.date.today() - datetime.timedelta(days=30)).strftime('%Y-%m-%d')
        sold_vehicles = connector.list_vehicles({
            'status': 'SOLD',
            'date_sold_from': thirty_days_ago
        })
        sold_count = len(sold_vehicles)
        
        # Calculate total inventory value
        total_value = sum(v.asking_price for v in available_vehicles)
        
        # Get recent sales (last 5)
        recent_sales = sorted(sold_vehicles, key=lambda v: v.date_sold, reverse=True)[:5]
        
        # Get oldest inventory (5 vehicles)
        oldest_inventory = sorted(available_vehicles, key=lambda v: v.date_acquired)[:5]
        
        return render_template('index.html', 
                              available_count=available_count,
                              sold_count=sold_count,
                              total_value=total_value,
                              recent_sales=recent_sales,
                              oldest_inventory=oldest_inventory)
    except Exception as e:
        flash(f"Error loading dashboard: {str(e)}", "error")
        return render_template('index.html')

@app.route('/inventory')
def inventory():
    """Inventory listing page"""
    try:
        # Get filter parameters
        make = request.args.get('make', '')
        model = request.args.get('model', '')
        year_from = request.args.get('year_from', '')
        year_to = request.args.get('year_to', '')
        status = request.args.get('status', 'AVAILABLE')
        
        # Build filter dictionary
        filter_dict = {}
        if make:
            filter_dict['make'] = make
        if model:
            filter_dict['model'] = model
        if year_from and year_from.isdigit():
            filter_dict['year_from'] = int(year_from)
        if year_to and year_to.isdigit():
            filter_dict['year_to'] = int(year_to)
        if status:
            filter_dict['status'] = status
        
        # Get vehicles
        vehicles = connector.list_vehicles(filter_dict)
        
        # Get unique makes and models for filter dropdowns
        all_vehicles = connector.list_vehicles()
        makes = sorted(set(v.make for v in all_vehicles if v.make))
        models = sorted(set(v.model for v in all_vehicles if v.model))
        
        return render_template('inventory.html', 
                              vehicles=vehicles,
                              makes=makes,
                              models=models,
                              filters=request.args)
    except Exception as e:
        flash(f"Error loading inventory: {str(e)}", "error")
        return render_template('inventory.html', vehicles=[])

@app.route('/vehicle/<int:vehicle_id>')
def vehicle_detail(vehicle_id):
    """Vehicle detail page"""
    try:
        # Get vehicle details
        vehicle = connector.get_vehicle_by_id(vehicle_id)
        if not vehicle:
            flash(f"Vehicle with ID {vehicle_id} not found", "error")
            return redirect(url_for('inventory'))
        
        # Get vehicle history
        history = connector.get_vehicle_history(vehicle_id)
        
        return render_template('vehicle_detail.html', 
                              vehicle=vehicle,
                              history=history)
    except Exception as e:
        flash(f"Error loading vehicle details: {str(e)}", "error")
        return redirect(url_for('inventory'))

@app.route('/vehicle/add', methods=['GET', 'POST'])
def add_vehicle():
    """Add new vehicle page"""
    if request.method == 'POST':
        try:
            # Create vehicle object from form data
            vehicle = Vehicle({
                'make': request.form.get('make', ''),
                'model': request.form.get('model', ''),
                'trim': request.form.get('trim', ''),
                'year': int(request.form.get('year', 0)),
                'vin': request.form.get('vin', ''),
                'color': request.form.get('color', ''),
                'odometer': int(request.form.get('odometer', 0)),
                'condition_rating': int(request.form.get('condition_rating', 0)),
                'acquisition_price': request.form.get('acquisition_price', '0.00'),
                'asking_price': request.form.get('asking_price', '0.00'),
                'date_acquired': request.form.get('date_acquired', datetime.date.today().strftime('%Y-%m-%d')),
                'status': 'AVAILABLE',
                'notes': request.form.get('notes', '')
            })
            
            # Add vehicle to inventory
            user_id = session.get('user_id', 'WEBUSER')
            vehicle_id = connector.add_vehicle(vehicle, user_id)
            
            if vehicle_id > 0:
                flash(f"Vehicle added successfully with ID: {vehicle_id}", "success")
                return redirect(url_for('vehicle_detail', vehicle_id=vehicle_id))
            else:
                flash("Failed to add vehicle", "error")
                return render_template('vehicle_form.html', vehicle=vehicle, action='add')
        except Exception as e:
            flash(f"Error adding vehicle: {str(e)}", "error")
            return render_template('vehicle_form.html', vehicle=request.form, action='add')
    
    # GET request - show form
    return render_template('vehicle_form.html', vehicle=None, action='add')

@app.route('/vehicle/<int:vehicle_id>/edit', methods=['GET', 'POST'])
def edit_vehicle(vehicle_id):
    """Edit vehicle page"""
    # Get vehicle details
    vehicle = connector.get_vehicle_by_id(vehicle_id)
    if not vehicle:
        flash(f"Vehicle with ID {vehicle_id} not found", "error")
        return redirect(url_for('inventory'))
    
    if request.method == 'POST':
        try:
            # Update vehicle object from form data
            vehicle.make = request.form.get('make', '')
            vehicle.model = request.form.get('model', '')
            vehicle.trim = request.form.get('trim', '')
            vehicle.year = int(request.form.get('year', 0))
            vehicle.vin = request.form.get('vin', '')
            vehicle.color = request.form.get('color', '')
            vehicle.odometer = int(request.form.get('odometer', 0))
            vehicle.condition_rating = int(request.form.get('condition_rating', 0))
            vehicle.acquisition_price = decimal.Decimal(request.form.get('acquisition_price', '0.00'))
            vehicle.asking_price = decimal.Decimal(request.form.get('asking_price', '0.00'))
            vehicle.notes = request.form.get('notes', '')
            
            # Update vehicle in inventory
            user_id = session.get('user_id', 'WEBUSER')
            result = connector.update_vehicle(vehicle, user_id)
            
            if result == 0:  # VEHCRUD_SUCCESS
                flash("Vehicle updated successfully", "success")
                return redirect(url_for('vehicle_detail', vehicle_id=vehicle_id))
            else:
                flash("Failed to update vehicle", "error")
                return render_template('vehicle_form.html', vehicle=vehicle, action='edit')
        except Exception as e:
            flash(f"Error updating vehicle: {str(e)}", "error")
            return render_template('vehicle_form.html', vehicle=vehicle, action='edit')
    
    # GET request - show form
    return render_template('vehicle_form.html', vehicle=vehicle, action='edit')

@app.route('/vehicle/<int:vehicle_id>/status', methods=['POST'])
def update_vehicle_status(vehicle_id):
    """Update vehicle status"""
    try:
        # Get form data
        new_status = request.form.get('status', '')
        date_sold = None
        if new_status == 'SOLD':
            date_sold_str = request.form.get('date_sold', '')
            if date_sold_str:
                date_sold = datetime.datetime.strptime(date_sold_str, '%Y-%m-%d').date()
            else:
                date_sold = datetime.date.today()
        
        notes = request.form.get('notes', '')
        user_id = session.get('user_id', 'WEBUSER')
        
        # Update vehicle status
        result = connector.update_vehicle_status(vehicle_id, new_status, date_sold, user_id, notes)
        
        if result == 0:  # VEHCRUD_SUCCESS
            flash("Vehicle status updated successfully", "success")
        else:
            flash("Failed to update vehicle status", "error")
        
        return redirect(url_for('vehicle_detail', vehicle_id=vehicle_id))
    except Exception as e:
        flash(f"Error updating vehicle status: {str(e)}", "error")
        return redirect(url_for('vehicle_detail', vehicle_id=vehicle_id))

# Error handlers
@app.errorhandler(404)
def page_not_found(e):
    """404 error handler"""
    return render_template('404.html'), 404

@app.errorhandler(500)
def server_error(e):
    """500 error handler"""
    return render_template('500.html'), 500

# Main entry point
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))

# Made with Bob
