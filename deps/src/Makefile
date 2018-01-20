FC = gfortran
LIB = snopt
FFLAGS = -shared -O2 -fPIC -v
SUFFIX = dylib

OBJ = $(shell ls *.f *.f90)

all : lib$(LIB).$(SUFFIX)

lib$(LIB).$(SUFFIX) : $(OBJ)
	$(FC) $(FFLAGS) $(OBJ) -o $@

clean :
	rm -f *.$(SUFFIX)

# gfortran -shared -O2 *.f *.f90 -o libsnopt.dylib -fPIC -v
