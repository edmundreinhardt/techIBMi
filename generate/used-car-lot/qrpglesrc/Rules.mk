# Rules.mk for qrpglesrc directory
# This file defines dependencies for building modules from SQLRPGLE source files

VEHCRUD.MODULE: VEHCRUD.sqlrpgle VEHCRUD_H.rpgle
VEHBIZ.MODULE: VEHBIZ.sqlrpgle VEHBIZ_H.rpgle VEHCRUD_H.rpgle
MONTHRPT.MODULE: MONTHRPT.sqlrpgle VEHCRUD_H.rpgle VEHBIZ_H.rpgle
INVRPT.MODULE: INVRPT.sqlrpgle VEHCRUD_H.rpgle VEHBIZ_H.rpgle
VEHMGMT.MODULE: VEHMGMT.sqlrpgle VEHCRUD_H.rpgle
REPMENU.MODULE: REPMENU.sqlrpgle

# Made with Bob
