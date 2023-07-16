######################################################
# Determine and set the Fortran compiler flags we want 
######################################################

########################################################################
# Determine the appropriate flags for this compiler for each build type.
# For each option type, a list of possible flags is given that work
# for various compilers.  The first flag that works is chosen.
# If none of the flags work, nothing is added (unless the REQUIRED 
# flag is given in the call).  This way unknown compiles are supported.
#######################################################################

INCLUDE(CheckFortranCompilerFlag)

#####################
### GENERAL FLAGS ###
#####################

# There is some bug where -march=native doesn't work on Mac
IF(APPLE)
    SET(GNUNATIVE "-mtune=native")
ELSE()
    SET(GNUNATIVE "-march=native")
ENDIF()

# Optimize for the host's architecture
CHECK_FORTRAN_COMPILER_FLAG("-xHost"        FC_FLAG_xHost)
CHECK_FORTRAN_COMPILER_FLAG("/QxHost"       FC_FLAG_QxHost)
CHECK_FORTRAN_COMPILER_FLAG(${GNUNATIVE}    FC_FLAG_MarchNative)
IF (FC_FLAG_xHost)
    SET(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -xHost")
ELSEIF (FC_FLAG_QxHost)
    SET(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} /QxHost")
ELSEIF (FC_FLAG_MarchNative)
    SET(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} ${GNUNATIVE}")
ENDIF()

###################
### DEBUG FLAGS ###
###################
# NOTE: debugging symbols (-g or /debug:full) are already on by default

# Turn on all warnings 
CHECK_FORTRAN_COMPILER_FLAG("/warn:all"    FC_FLAG_SWARN_ALL)
CHECK_FORTRAN_COMPILER_FLAG("-warn all"    FC_FLAG_DWARN_ALL)
CHECK_FORTRAN_COMPILER_FLAG("-Wall"        FC_FLAG_WALL)
IF (FC_FLAG_SWARN_ALL)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} /warn:all")
ELSEIF (FC_FLAG_DWARN_ALL)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} -warn all")
ELSEIF (FC_FLAG_WALL)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} -Wall")
ENDIF()

# Traceback
CHECK_FORTRAN_COMPILER_FLAG("/traceback"   FC_FLAG_STRACEBACK)
CHECK_FORTRAN_COMPILER_FLAG("-traceback"   FC_FLAG_DTRACEBACK)
CHECK_FORTRAN_COMPILER_FLAG("-fbacktrace"  FC_FLAG_FBACKTRACE)
CHECK_FORTRAN_COMPILER_FLAG("-ftrace=full" FC_FLAG_FTRACE_FULL)
IF (FC_FLAG_STRACEBACK)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} /traceback")
ELSEIF (FC_FLAG_DTRACEBACK)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} -traceback")
ELSEIF (FC_FLAG_FBACKTRACE)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} -fbacktrace")
ELSEIF (FC_FLAG_FTRACE_FULL)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} -ftrace=full")
ENDIF()

# Check array bounds
CHECK_FORTRAN_COMPILER_FLAG("/check:bounds"  FC_FLAG_SCHECK_BOUNDS)
CHECK_FORTRAN_COMPILER_FLAG("-check bounds"  FC_FLAG_DCHECK_BOUNDS)
CHECK_FORTRAN_COMPILER_FLAG("-fcheck=bounds" FC_FLAG_FCHECK_BOUNDS)
CHECK_FORTRAN_COMPILER_FLAG("-fbounds-check" FC_FLAG_FBOUNDS_CHECK)
IF (FC_FLAG_SCHECK_BOUNDS)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} /check:bounds")
ELSEIF (FC_FLAG_DCHECK_BOUNDS)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} -check bound")
ELSEIF (FC_FLAG_FCHECK_BOUNDS)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} -fcheck=bounds")
ELSEIF (FC_FLAG_FBOUNDS_CHECK)
    SET(CMAKE_Fortran_FLAGS_DEBUG "${CMAKE_Fortran_FLAGS_DEBUG} -fbounds-check")
ENDIF()

#####################
### RELEASE FLAGS ###
#####################
# Aggressive optimizations
CHECK_FORTRAN_COMPILER_FLAG("/O3"          FC_FLAG_SO3)
CHECK_FORTRAN_COMPILER_FLAG("-O3"          FC_FLAG_DO3)
IF (FC_FLAG_SO3)
    SET(CMAKE_Fortran_FLAGS_RELEASE "/O3")
ELSEIF (FC_FLAG_DO3)
    SET(CMAKE_Fortran_FLAGS_RELEASE "-O3")
ENDIF()

# Unroll loops
CHECK_FORTRAN_COMPILER_FLAG("/Qunroll"       FC_FLAG_QUNROLL)
CHECK_FORTRAN_COMPILER_FLAG("-funroll-loops" FC_FLAG_FUNROLL)
CHECK_FORTRAN_COMPILER_FLAG("-unroll"        FC_FLAG_UNROLL)
IF (FC_FLAG_QUNROLL)
    SET(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} /Qunroll")
ELSEIF (FC_FLAG_FUNROLL)
    SET(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -funroll-loops")
ELSEIF (FC_FLAG_UNROLL)
    SET(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -unroll")
ENDIF()

# Inline functions
CHECK_FORTRAN_COMPILER_FLAG("/inline"               FC_FLAG_SINLINE)
CHECK_FORTRAN_COMPILER_FLAG("-inline"               FC_FLAG_DINLINE)
CHECK_FORTRAN_COMPILER_FLAG("-finline-functions"    FC_FLAG_FINLINE_FUNCTIONS)
IF (FC_FLAG_SINLINE)
    SET(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} /inline")
ELSEIF (FC_FLAG_DINLINE)
    SET(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -inline")
ELSEIF (FC_FLAG_FINLINE_FUNCTIONS)
    SET(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -finline-functions")
ENDIF()

# Single-file optimizations
CHECK_FORTRAN_COMPILER_FLAG("/Qip"       FC_FLAG_QIP)
CHECK_FORTRAN_COMPILER_FLAG("-ip"        FC_FLAG_IP)
IF (FC_FLAG_QIP)
    SET(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} /Qip")
ELSEIF (FC_FLAG_IP)
    SET(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -ip")
ENDIF()

# Vectorize code
CHECK_FORTRAN_COMPILER_FLAG("/Qvec" FC_FLAG_QVEC)
CHECK_FORTRAN_COMPILER_FLAG("-vec"  FC_FLAG_VEC)
IF (FC_FLAG_QVEC)
    SET(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} /Qvec")
ELSEIF (FC_FLAG_VEC)
    SET(CMAKE_Fortran_FLAGS_RELEASE "${CMAKE_Fortran_FLAGS_RELEASE} -vec")
ENDIF()