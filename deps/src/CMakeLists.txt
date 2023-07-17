
# Set source files
SET(SRCS
    fileio.f90
    sn01dum.f
    sn02lib.f 
    sn02slib.f
    sn02tlib.f
    sn03prnt.f 
    sn04stats.f 
    sn04wrap.f 
    sn05wrpa.f 
    sn05wrpb.f 
    sn05wrpc.f 
    sn05wrpch.f 
    sn05wrpn.f
    sn10mach.f 
    sn12ampl.f 
    sn17util.f
    sn20amat.f
    sn25bfac.f 
    sn27lu.f 
    sn30spec.f 
    sn35mps.f 
    sn37wrap.f 
    sn40bfil.f 
    sn50lp.f 
    sn55qp.f 
    sn56qncg.f 
    sn57qopt.f 
    sn60srch.f 
    sn65rmod.f 
    sn70nobj.f 
    sn80ncon.f 
    sn82qn.f 
    sn83bfgs.f 
    sn85hess.f 
    sn87sopt.f 
    snfilewrapper.f 
    snopta.f 
    snoptb.f 
    snoptc.f 
    snoptch.f 
    snoptq.f 
    snctrl.f 
    sq02lib.f 
    sq02slib.f 
    sq02tlib.f 
    sqopt.f
    np02lib.f
    np02slib.f
    np02tlib.f 
    npopt.f 
    sqopt_wrapper.f90
    snopt_wrapper.f90 
)

# If not using BLAS, add BLAS source file
IF (NOT USE_EXTERNAL_BLAS)
    LIST(APPEND SRCS snblas.f)
ENDIF()

# Add library
ADD_LIBRARY(snopt SHARED ${SRCS})

# Set BLAS
IF (USE_EXTERNAL_BLAS)
    IF (USE_MKL)
        TARGET_COMPILE_OPTIONS(snopt PUBLIC $<TARGET_PROPERTY:MKL::MKL,INTERFACE_COMPILE_OPTIONS>)
        TARGET_INCLUDE_DIRECTORIES(snopt PUBLIC $<TARGET_PROPERTY:MKL::MKL,INTERFACE_INCLUDE_DIRECTORIES>)
        TARGET_LINK_LIBRARIES(snopt PUBLIC $<LINK_ONLY:MKL::MKL>)
    ELSEIF (USE_OPENBLAS)
        TARGET_INCLUDE_DIRECTORIES(snopt PUBLIC "${OpenBLAS_INCLUDE_DIRS}")
        TARGET_LINK_LIBRARIES(snopt PUBLIC "${OpenBLAS_LIBRARY}")
    ENDIF()
ENDIF()

# Set library version
SET_TARGET_PROPERTIES(snopt PROPERTIES VERSION ${PROJECT_VERSION})

# Set subversion
SET_TARGET_PROPERTIES(snopt PROPERTIES SOVERSION 1)

# Set src subdirectory
TARGET_INCLUDE_DIRECTORIES(snopt PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

# Install
INSTALL(TARGETS snopt 
        CONFIGURATIONS Release
        RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX})