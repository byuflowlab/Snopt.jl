FC = gfortran
LIB = snopt
FFLAGS = -shared -O2 -fPIC -v
SUFFIX = dylib

OBJ := $(wildcard *.f *.f90)
$(info $$OBJ is [${OBJ}])

all : lib$(LIB).$(SUFFIX)

lib$(LIB).$(SUFFIX) : $(OBJ)
	$(FC) $(FFLAGS) $(OBJ) -o $@

clean :
	rm -f *.$(SUFFIX)
