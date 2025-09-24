# Rules.mk for qsqlsrc directory
# This file defines dependencies for building FILE objects from table source files

COUNTRY.FILE: COUNTRY.table
COUNTR1.FILE: COUNTR1.index COUNTRY.FILE

# Made with Better Object Builder

# Made with Bob
