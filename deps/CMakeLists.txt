
CMAKE_MINIMUM_REQUIRED(VERSION 3.26.0)

PROJECT(libsnopt
        VERSION 1.0.0
        DESCRIPTION "snopt7 dynamics library"
        LANGUAGES Fortran C)

# Set verion of libsnopt
SET(version 7.7.7)

# BLAS options
OPTION(USE_EXTERNAL_BLAS        "Use external BLAS" OFF)
OPTION(USE_MKL                  "Use MKL" OFF)
OPTION(USE_OPENBLAS             "Use OpenBLAS" OFF)

# Setup BLAS
INCLUDE(${CMAKE_SOURCE_DIR}/cmake/Modules/SetupBLAS.cmake)

# Set FORTRAN compiler flags
INCLUDE(${CMAKE_SOURCE_DIR}/cmake/Modules/SetFortranFlags.cmake)

# Add src subdirectory
ADD_SUBDIRECTORY(src)

