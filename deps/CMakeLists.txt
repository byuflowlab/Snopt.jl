
CMAKE_MINIMUM_REQUIRED(VERSION 3.27.0)

PROJECT(libsnopt
        VERSION 1.0.0
        DESCRIPTION "snopt7 dynamics library"
        LANGUAGES Fortran)

# Set verion of libsnopt
SET(version 7.7.7)

# Set FORTRAN compiler flags
INCLUDE(${CMAKE_SOURCE_DIR}/cmake/Modules/SetFortranFlags.cmake)

# Add src subdirectory
ADD_SUBDIRECTORY(src)

