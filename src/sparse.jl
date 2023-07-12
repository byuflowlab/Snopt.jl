
# convenience function used internally to simplify conversion of Julia matricies to
# the format expected by snopt, i.e, iAfun, jAvar, A, lenA, neA.
function parseMatrix(A::SparseMatrixCSC)
    r, c, values = findnz(A)
    len = length(r)

    rows = zeros(Cint, len)
    rows .= r
    cols = zeros(Cint, len)
    cols .= c

    return len, rows, cols, values
end

function parseMatrix(A)
    if isempty(A)
        len = 0
        rows = Int32[1]
        cols = Int32[1]
        values = [0.0]
    else
        nf, nx = size(A)
        len = nf*nx
        rows = zeros(Cint, nx*nf)
        rows .= [i for i = 1:nf, j = 1:nx][:]
        cols = zeros(Cint, nx*nf)
        cols .= [j for i = 1:nf, j = 1:nx][:]
        values = A[:]
    end

    return len, rows, cols, values
end