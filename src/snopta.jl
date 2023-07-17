

"""
    snopta(func!, start, ObjAdd, ObjRow, iAfun, jAvar, A, iGfun jGvar, xlow, xupp, Flow, Fupp, options = Dict(); names = Names())

Main function call into snOptA.

# Arguments
- `func!::function`: follows function signature shown in example!
- `start::Start`: see Start struct
- `ObjAdd::Float64`: adds a scalar to objective (see Snopt docs)
- `ObjRow::Int64`: row of objective in function vector F(x) (see Snopt docs)
- `iAfun::Vector{Int64}`: row indices of A matrix (see Snopt docs)
- `jAvar::Vector{Int64}`: column indices of A matrix (see Snopt docs)
- `A::Vector{Float64}`: values of A matrix (see Snopt docs)
- `iGfun::Vector{Int64}`: row indices of G matrix (see Snopt docs)
- `jGvar::Vector{Int64}`: column indices of G matrix (see Snopt docs)
- `xlow::Vector{Float64}`: lower bounds on x
- `xupp::Vector{Float64}`: upper bounds on x
- `Flow::Vector{Float64}`: lower bounds on F(x)
- `Fupp::Vector{Float64}`: upper bounds on F(x)
- `options::Dict` : see Snopt docs
- `names::Names`: see Names struct

# Returns
- `xstar::Vector{Float64}`: optimal x
- `fstar::Vector{Float64}`: corresponding f
- `info::String`: termination message
- `out::Outputs`: various outputs
"""
function snopta(func!, start::Start, ObjAdd, ObjRow, iAfun, jAvar, A, iGfun, jGvar, xlow, xupp, Flow, Fupp, options = Dict();
                names = Names())

    # Number of variables and functions
    n  = length(start.x)
    nF = length(Flow)

    # Parse names
    nxname = length(names.xnames)
    if nxname != 1 && nxname != n
        @warn "Incorrect length for xnames"
        nxname = 1
    end
    nfname = length(names.fnames)
    if nfname != 1 && nfname != nF
        @warn "Incorrect length for fnames"
        nfname = 1
    end

    # --- process names into fortran format ---
    sn_names = processnames(names)

    # A matrix requirements
    lenA    = length(A) 
    neA     = lenA
    if lenA == 1 && A[1] == 0.0
        neA = 0
    end
    iAfun_c = zeros(Cint, lenA)
    iAfun_c.= iAfun
    jAvar_c = zeros(Cint, lenA)
    jAvar_c.= jAvar

    # Setup user function
    wrapper = function(status_::Ptr{Cint}, n::Cint, x_::Ptr{Cdouble},
        needf::Cint, nF::Cint, f_::Ptr{Cdouble}, needG::Cint, lenG::Cint,
        G_::Ptr{Cdouble}, cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
        leniu::Cint, ru::Ptr{Cdouble}, lenru::Cint)

        usrcallback_snopta(func!, status_, n, x_, needf, nF, f_, needG, lenG,
            G_, cu, lencu, iu, leniu, ru, lenru)

        return nothing
    end

    # c wrapper to callback function
    usrfun = @cfunction($wrapper, Cvoid, (Ptr{Cint}, Ref{Cint}, Ptr{Cdouble},
        Ref{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, Ptr{Cdouble},
        Ptr{Cuchar}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}))

    # Setup jacobian sparsity pattern
    lenG    = length(iGfun)
    neG     = lenG
    iGfun_c = zeros(Cint, lenG)
    iGfun_c.= iGfun
    jGvar_c = zeros(Cint, lenG)
    jGvar_c.= jGvar

    # Open files
    printfile = "snopt-print.out"
    sumfile = "snopt-summary.out"
    if haskey(options, "Print file")
        printfile = options["Print file"]
    end
    if haskey(options, "Summary file")
        sumfile = options["Summary file"]
    end
    openfiles(printfile, sumfile)

    # Initialize
    work = sninit(n, nF)

    # Set options
    setoptions(options, work)

    # Set memory requirements
    INFO = Cint[0]
    setmemory(INFO, nF, n, nxname, nfname, neA, neG, work)

    # Call snopta
    mincw = Cint[0]
    miniw = Cint[0]
    minrw = Cint[0]
    nInf  = Cint[0]
    sInf  = Cdouble[0]
    lencu = 1
    cu    = Array{Cuchar}(undef, lencu*8)
    leniu = 1
    iu    = Cint[0]
    lenru = 1
    ru    = [0.0]
    ns    = Cint[start.ns]

    snopta!(start.start, nF, n, nxname, nfname,
            ObjAdd, ObjRow, sn_names.prob, usrfun,
            iAfun_c, jAvar_c, lenA, neA, A,
            iGfun_c, jGvar_c, lenG, neG,
            xlow, xupp, sn_names.xnames, Flow, Fupp, sn_names.fnames,
            start.x, start.xstate, start.xmul, start.f, start.fstate, start.fmul,
            INFO, mincw, miniw, minrw,
            ns, nInf, sInf,
            cu, lencu, iu, leniu, ru, lenru,
            work.cw, work.lencw, work.iw, work.leniw, work.rw, work.lenrw)

    # Close files
    closefiles()

    # Pack outputs
    warm = WarmStart(ns[1], start.xstate, start.fstate, start.x, start.f, start.xmul, start.fmul)
    out  = Outputs(start.f[1:end .!= ObjRow], work.iw[421], work.iw[422], work.rw[462], nInf[1], sInf[1], warm, INFO[1])
    return start.x, start.f[ObjRow], codes[INFO[1]], out
end