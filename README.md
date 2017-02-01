# Snopt.jl
Julia interface to SNOPT (must obtain a licensed copy of SNOPT separately)

Requires a change to subroutine sn02lib.f. Function snSeti and snSetr take in a string of variable length `character*(*) buffer`. I changed to `character buffer*55`, then instead of evaluating `len(buffer)` I changed to `lenbuf = len_trim(buffer)`
