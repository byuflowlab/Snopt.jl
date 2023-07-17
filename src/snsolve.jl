
# commonly used convenience method to provide regular starting point (cold start)
function snsolve(func!, x0::T, lx, ux, lg, ug, rows, cols, 
    options=Dict(); A=[], names=Names(), objadd=0.0) where T<:Vector

    start = ColdStart(x0, length(lg)+1)
    
    return snsolve(func!, start, lx, ux, lg, ug, rows, cols, options, A=A, names=names, objadd=objadd)
end

"""
    snsolve(func!, x0, lx, ux, lg, ug, rows, cols, 
        options=Dict(); A=[], names=Names(), objadd=0.0)

Main function call into snOptA.

# Arguments
- `func!::function`: follows function signature shown in example!
- `x0::Vector{Float64}` or `x0::WarmStart`: starting point
- `lx::Vector{Float64}`: lower bounds on x
- `ux::Vector{Float64}`: upper bounds on x
- `lg::Vector{Float64}`: lower bounds on g
- `ug::Vector{Float64}`: upper bounds on g
- `rows::Vector{Int64}`: sparsity pattern for constraint jacobian.  dg[k] corresponds to rows[k], cols[k]
- `cols::Vector{Int64}`: sparsity pattern for constraint jacobian.  dg[k] corresponds to rows[k], cols[k]
- `options::Dict`: dictionary of options (see Snopt docs)
- `A::Matrix` (if dense) or `SparseMatrixCSC`: linear constraints g += A*x
- `names::Names`: custom names for problem and variables for print file
- `objAdd::Float64`: adds a scalar to objective (see Snopt docs)

# Returns
- `xstar::Vector{Float64}`: optimal x
- `fstar::Vector{Float64}`: corresponding f
- `info::String`: termination message
- `out::Outputs`: various outputs
"""
function snsolve(func!, start::Start, lx, ux, lg, ug, rows, cols, 
    options=Dict(); A=[], names=Names(), objadd=0.0)
    # --- number of functions ----
    nx = length(start.x)
    ng = length(lg)
    nf = 1 + length(lg)
    lf = [0.0; Float64.(lg)]  # bounds on objective are irrelevant
    uf = [0.0; Float64.(ug)]  
   
    # --- parse names -------
    nxname = length(names.xnames)
    if nxname != 1 && nxname != nx
        @warn "incorrect length for xnames"
        nxname = 1
    end
    nfname = length(names.fnames)
    if nfname != 1 && nfname != nf
        @warn "incorrect length for fnames"
        nfname = 1
    end
    
    # --- process names into fortran format ------
    sn_names = processnames(names)
    
    # ---- parse linear constraints -------
    lenA, iAfun, jAvar, Aval = parseMatrix(A)
    neA = lenA

    # ----- setup user function ---------------
    wrapper = function(status_::Ptr{Cint}, n::Cint, x_::Ptr{Cdouble},
        needf::Cint, nF::Cint, f_::Ptr{Cdouble}, needG::Cint, lenG::Cint,
        G_::Ptr{Cdouble}, cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
        leniu::Cint, ru::Ptr{Cdouble}, lenru::Cint)

        usrcallback_snsolve(func!, status_, n, x_, needf, nF, f_, needG, lenG,
            G_, cu, lencu, iu, leniu, ru, lenru)

        return nothing
    end

    # c wrapper to callback function
    usrfun = @cfunction($wrapper, Cvoid, (Ptr{Cint}, Ref{Cint}, Ptr{Cdouble},
        Ref{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, Ptr{Cdouble},
        Ptr{Cuchar}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}))

    # ---- setup jacobian  sparsity pattern ------
    nsp = length(rows)
    lenG = nx + nsp
    neG = lenG
    iGfun = Array{Cint}(undef, lenG)
    jGvar = Array{Cint}(undef, lenG)

    objrow = 1 

    # objective gradient (first row) assumed dense
    iGfun[1:nx] .= 1
    jGvar[1:nx] .= 1:nx

    # constraint jacobian
    for k = 1:nsp
        iGfun[nx + k] = rows[k] + 1  # adding one for objective row
        jGvar[nx + k] = cols[k]
    end

    # --- open files ------
    printfile = "snopt-print.out"
    sumfile = "snopt-summary.out"

    if haskey(options, "Print file")
        printfile = options["Print file"]
    end
    if haskey(options, "Summary file")
        sumfile = options["Summary file"]
    end
    openfiles(printfile, sumfile)

    # ----- initialize -------
    work = sninit(nx, nf)

    # --- set options ----
    setoptions(options, work)

    # ---- set memory requirements ------
    INFO = Cint[0]
    setmemory(INFO, nf, nx, nxname, nfname, neA, neG, work)

    # --- call snopta ----
    mincw = Cint[0]
    miniw = Cint[0]
    minrw = Cint[0]
    nInf = Cint[0]
    sInf = Cdouble[0]
    lencu = 1
    cu = Array{Cuchar}(undef, lencu*8)
    leniu = 1
    iu = Cint[0]
    lenru = 1
    ru = [0.0]
    ns = Cint[start.ns]
    snopta!(start.start, nf, nx, nxname, nfname, 
            objadd, objrow, sn_names.prob, usrfun, 
            iAfun, jAvar, lenA, neA, Aval, 
            iGfun, jGvar, lenG, neG,
            lx, ux, sn_names.xnames, lf, uf, sn_names.fnames, 
            start.x, start.xstate, start.xmul, start.f, start.fstate, start.fmul, 
            INFO, mincw, miniw, minrw, 
            ns, nInf, sInf, 
            cu, lencu, iu, leniu, ru, lenru, 
            work.cw, work.lencw, work.iw, work.leniw, work.rw, work.lenrw)

    # close output files
    closefiles()

    # pack outputs
    warm = WarmStart(ns[1], start.xstate, start.fstate, start.x, start.f, 
    start.xmul, start.fmul)

    out = Outputs(start.f[2:end], work.iw[421], work.iw[422], work.rw[462], 
        nInf[1], sInf[1], warm, INFO[1])

    return start.x, start.f[1], codes[INFO[1]], out
end