# Rules.mk for qsrvsrc directory
# This file defines dependencies for building service programs from modules

VEHCRUD.SRVPGM: VEHCRUD.bnd VEHCRUD.MODULE
VEHBIZ.SRVPGM: VEHBIZ.bnd VEHBIZ.MODULE VEHCRUD.SRVPGM

# Made with Bob
