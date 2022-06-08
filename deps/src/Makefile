# To run this makefile standalone, do:
# (Linux):  $ FC=gfortran LD=gfortran SUFFIX=os make
# (MacOS):  $ FC=gfortran LD=gfortran SUFFIX=dylib make

SUFFIX ?= so


LIB = snopt
FFLAGS = -shared -O2 -fPIC 
LDFLAGS =
VERSION_FOLDER =
PRECOMPILED_SONPT =

# # By default, we assume the sources or binary of SNOPT will be put in the ./dep/src folder.
# # If you want to put them in a subfolder instead (e.g., to maintain several versions), you can 
# # specify a folder in which we will look for the sources/binary. For example:
# VERSION_FOLDER = v7.7.5


# ========== TODO: uncomment the following block depending on what you want to do.  ===============

# # 0. DEFAULT: You have the source files. You don't need to do anything.  
# #    The following will compile the sources and create a dynamic lib with everything.

# # 1. You have SNOPT under the form of a dynamic lib (libsnopt7.dylib/libsnopt.so), and you put it in a subdirectory. 
# #    The following will compile our IO sources and create a dynamic lib that links to the libsnopt7.
# PRECOMPILED_SONPT = -lsnopt7
# LDFLAGS = -Wl,-rpath,$(shell pwd)/$(VERSION_FOLDER)/ 
# # Note:  you may have to run from the terminal, for linux:
# #        $ export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/path/to/your/libsnopt7.so
# #        or, for MacOS:
# #        $ export DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:/path/to/your/libsnopt7.dylib
# # Note:  you may also need to add other rpaths indicating where the correct libgfortran is.

# # 2. (RECOMMENDED OVER 1.) You have SNOPT under the form of a static lib (libsnopt7.a), and you put it in a subdirectory 
# #    The following will compile our IO sources and create a dynamic lib that includes the content of the static archive (libsnopt7 is NOT a dependency in this case).
# ifeq ($(SUFFIX),dylib)
# # FOR MACOS:
# LDFLAGS = -Wl,-force_load $(shell pwd)/$(VERSION_FOLDER)/libsnopt7.a
# else
#  # FOR LINUX:
# LDFLAGS = -Wl,--whole-archive $(shell pwd)/$(VERSION_FOLDER)/libsnopt7.a -Wl,--no-whole-archive 
# endif

# ==============================================================================================


SRC = $(shell ls *.f90 $(VERSION_FOLDER)/*.f $(VERSION_FOLDER)/*.f90)
OBJ = $(addsuffix .o, $(basename $(SRC)))

all : lib$(LIB).$(SUFFIX)

%.o:    %.f
	@echo " + Compiling $<..."; $(FC) $(FFLAGS) -o $@ -c $<
%.o:    %.f90
	@echo " + Compiling $<..."; $(FC) $(FFLAGS) -o $@ -c $<

lib$(LIB).$(SUFFIX) : $(OBJ)
	$(LD) $(FFLAGS)  $(OBJ) -L./$(VERSION_FOLDER)/ $(PRECOMPILED_SONPT)  $(LDFLAGS)  -o $@ 


clean :
	rm -f *.$(SUFFIX) $(OBJ)
