# Snopt.jl
Julia interface to SNOPT (must obtain a licensed copy of SNOPT separately)

Requires a change to subroutine sn02lib.f. Function snSet, snSeti, and snSetr require the following changes:

`character*(*) buffer` => `character buffer*72`   (snSet)

`character*(*) buffer` => `character buffer*55`  (snSeti and snSetr)

`lenbuf = len(buffer)` => `lenbuf = len_trim(buffer)`  (snSeti and snSetr)

The first two change the argument from a variable length string to one with a known length (which are the max lengths according to snopt docs).  I had problems trying to pass variable length strings from Julia.  I believe this can be done with pointers and allocatable strings, but that requires changes on the Fortran side anyway (and the changes would be more extensive).  You must then always pass in a string of the correct length from Julia, so I pad the options with spaces in Julia, but this is transparent to the user.  The latter change computes the length without the whitespace at the end so that the messages printed in the files don't contain the extra padding.
