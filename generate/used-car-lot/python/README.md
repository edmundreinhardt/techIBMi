# Used Car Dealership Inventory System - Web Interface

This is a Python Flask web application that provides a web interface for the Used Car Dealership Inventory System. It connects to IBM i service programs to manage vehicle inventory, track sales, and generate reports.

## Prerequisites

- Python 3.8 or higher
- Access to an IBM i system with the Used Car Dealership Inventory System service programs installed
- IBM i Access ODBC Driver

## Installation

1. Clone the repository or download the source code.

2. Create a virtual environment:
   ```
   python -m venv venv
   ```

3. Activate the virtual environment:
   - On Windows:
     ```
     venv\Scripts\activate
     ```
   - On macOS/Linux:
     ```
     source venv/bin/activate
     ```

4. Install the required packages:
   ```
   pip install -r requirements.txt
   ```

5. Set up environment variables:
   - Create a `.env` file in the project root with the following variables:
     ```
     FLASK_APP=app.py
     FLASK_ENV=development
     FLASK_SECRET_KEY=your_secret_key
     IBMI_USER=your_ibmi_username
     IBMI_PASSWORD=your_ibmi_password
     IBMI_HOST=your_ibmi_host
     IBMI_LIBRARY=USEDCAR
     ```

## Running the Application

1. Make sure your virtual environment is activated.

2. Run the Flask application:
   ```
   flask run
   ```

3. Open a web browser and navigate to `http://localhost:5000` to access the application.

## Features

- Dashboard with inventory summary and recent sales
- Vehicle inventory management (add, edit, view, update status)
- Vehicle history tracking
- Responsive design for desktop and mobile devices

## Project Structure

- `app.py`: Main Flask application
- `ibmi_connector.py`: IBM i connector for VEHCRUD service program
- `ibmi_vehbiz.py`: IBM i connector for VEHBIZ service program
- `templates/`: HTML templates
- `static/`: Static files (CSS, JavaScript)

## Service Programs

This web interface connects to the following IBM i service programs:

- `VEHCRUD`: Service program for CRUD operations on vehicle inventory
- `VEHBIZ`: Service program for business logic and financial calculations

## License

This project is licensed under the MIT License - see the LICENSE file for details.