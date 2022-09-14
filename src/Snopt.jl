module Snopt

using SparseArrays

export snopta

const snoptlib = joinpath(dirname(@__FILE__), "../deps/src/libsnopt")

const codes = Dict(
1 => "Finished successfully: optimality conditions satisfied",
2 => "Finished successfully: feasible point found",
3 => "Finished successfully: requested accuracy could not be achieved",
11 => "The problem appears to be infeasible: infeasible linear constraints",
12 => "The problem appears to be infeasible: infeasible linear equalities",
13 => "The problem appears to be infeasible: nonlinear infeasibilities minimized",
14 => "The problem appears to be infeasible: infeasibilities minimized",
15 => "The problem appears to be infeasible: infeasible linear constraints in QP subproblem",
21 => "The problem appears to be unbounded: unbounded objective",
22 => "The problem appears to be unbounded: constraint violation limit reached",
31 => "Resource limit error: iteration limit reached",
32 => "Resource limit error: major iteration limit reached",
33 => "Resource limit error: the superbasics limit is too small",
41 => "Terminated after numerical difficulties: current point cannot be improved",
42 => "Terminated after numerical difficulties: singular basis",
43 => "Terminated after numerical difficulties: cannot satisfy the general constraints",
44 => "Terminated after numerical difficulties: ill-conditioned null-space basis",
51 => "Error in the user-supplied functions: incorrect objective derivatives",
52 => "Error in the user-supplied functions: incorrect constraint derivatives",
61 => "Undefined user-supplied functions: undefined function at the first feasible point",
62 => "Undefined user-supplied functions: undefined function at the initial point",
63 => "Undefined user-supplied functions: unable to proceed into undefined region",
71 => "User requested termination: terminated during function evaluation ",
74 => "User requested termination: terminated from monitor routine",
81 => "Insufficient storage allocated: work arrays must have at least 500 elements",
82 => "Insufficient storage allocated: not enough character storage",
83 => "Insufficient storage allocated: not enough integer storage",
84 => "Insufficient storage allocated: not enough real storage",
91 => "Input arguments out of range: invalid input argument",
92 => "Input arguments out of range: basis file dimensions do not match this problem",
141 => "System error: wrong number of basic variables",
142 => "System error: error in basis package"
)

const PRINTNUM = 18
const SUMNUM = 19


"""
    Names(prob, xnames, fnames)

Convenience to put custom names in output files.
Arguments to variables of same names in snOptA. 
Use strings and vectors of strings.
"""
struct Names{TS}
    prob::TS
    xnames::Vector{TS}
    fnames::Vector{TS}
end

"""
    Names()

Default names (uses snopt defaults for xnames, fnames)
"""
Names() = Names("Opt Prob", [""], [""])


# Internal: truncater or pad string to 8 characters
function eightchar(name)
    n = length(name)
    if n >= 8
        return name[1:8]
    else
        return string(name, repeat(" ", 8-n))
    end
end

# Internal: struct of names in fortran format
struct NamesFStyle{TC}
    prob::Vector{TC}
    xnames::Vector{TC}
    fnames::Vector{TC}
end

# Internal: convert a list of names to fortran format
function process_list_of_names(names)
    allnames = ""
    for name in names
        allnames *= eightchar(name)
    end
    return Vector{Cuchar}(allnames)
end

# Internal: convert the names to fortran format
function processnames(names)
    
    prob = Vector{Cuchar}(eightchar(names.prob))

    xnames = process_list_of_names(names.xnames)
    fnames = process_list_of_names(names.fnames)
    
    return NamesFStyle(prob, xnames, fnames)
end

"""
    Start(start, ns, xstate, fstate, x, f, xmul, fmul)

A starting point for optimization.  
Usually not used directly. Instead use ColdStart or WarmStart.
Arguments correspond to the same names in snOptA.
"""
struct Start{TI, TF}
    start::TI
    ns::TI
    xstate::Vector{TI}
    fstate::Vector{TI}
    x::Vector{TF}
    f::Vector{TF}
    xmul::Vector{TF}
    fmul::Vector{TF}
end

"""
    ColdStart(x0, nf)

A cold start.

# Arguments
- `x0::Vector{Float64}`: starting point
- `nf::Int64`: number of output functions (obj + constraints)
"""
function ColdStart(x0, nf)
    nx = length(x0)
    return Start(Cint(0), Cint(0),
        zeros(Cint, nx), zeros(Cint, nf), 
        x0, zeros(nf), zeros(nx), zeros(nf)
        )
end

"""
    WarmStart(ns, xstate, fstate, x, f, xmul, fmul)

A warm start.  Arguments correspond to variables of same names in snOptA.
One of the outputs of snopta is a WarmStart object that can be reused as an input.
"""
WarmStart(ns, xstate, fstate, x, f, xmul, fmul) = Start(
    Cint(2), ns, xstate, fstate, x, f, xmul, fmul)

# internal use: workspace vectors
mutable struct Workspace{TI,TF,TS}
    lencw::TI
    cw::Vector{TS}
    leniw::TI
    iw::Vector{TI}
    lenrw::TI
    rw::Vector{TF}
end

# internal use: initialize workspace arrays from lengths
Workspace(lenc, leni, lenr) = Workspace(
    Cint(lenc), Array{Cuchar}(undef, lenc*8),
    Cint(leni), Array{Cint}(undef, leni),
    Cint(lenr), Array{Float64}(undef, lenr)
)

"""
    Outputs(gstar, iterations, major_iter, run_time, nInf, sInf, warm, info_code)

Outputs returned by the snopta function.

# Arguments
- `gstar::Vector{Float}`: constraints evaluated at the optimal point
- `iterations::Int`: total iteration count
- `major_iter::Int`: number of major iterations
- `run_time::Float`: solve time as reported by snopt
- `nInf::Int`: number of infeasibility constraints, see snopta docs
- `sInf::Float`: sum of infeasibility constraints, see snopta docs
- `warm::WarmStart`: a warm start object that can be used in a restart.
- `info_code::Int`: snopta `INFO` exit status code
"""
struct Outputs{TF,TI,TW}
    gstar::Vector{TF}
    iterations::TI
    major_iter::TI
    run_time::TF
    nInf::TI
    sInf::TF
    warm::TW
    info_code::TI
end


# wrapper for snInit
function sninit(nx, nf)

    # temporary working arrays
    minlen = 500
    lencw = minlen
    leniw = minlen + 100*(nx + nf)
    lenrw = minlen + 200*(nx + nf)
    w = Workspace(lencw, leniw, lenrw)

    ccall( (:sninit_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}, Ptr{Cuchar}, Ref{Cint}, Ptr{Cint},
        Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
        PRINTNUM, SUMNUM, w.cw, w.lencw, w.iw,
        w.leniw, w.rw, w.lenrw)

    return w
end


# wrapper for openfiles. not defined with snopt, fortran file supplied in repo (from pyoptsparse)
function openfiles(printfile, sumfile)

    # open files for printing (not part of snopt distribution)
    printerr = Cint[0]
    sumerr = Cint[0]
    ccall( (:openfiles_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cuchar}, Ptr{Cuchar}),
        PRINTNUM, SUMNUM, printerr, sumerr, printfile, sumfile)

    if printerr[1] != 0
        @warn "failed to open print file"
    end
    if sumerr[1] != 0
        @warn "failed to open summary file"
    end

    return nothing
end

# wrapper for closefiles. not defined with snopt, fortran file supplied in repo (from pyoptsparse)
function closefiles()
    # close output files
    ccall( (:closefiles_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}),
        PRINTNUM, SUMNUM)

    return nothing
end

# wrapper for flushfiles. not defined with snopt, fortran file supplied in repo (from pyoptsparse)
function flushfiles()
    # flush output files to see progress
    ccall( (:flushfiles_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}),
        PRINTNUM, SUMNUM)

    return nothing
end

# wrapper for snSet, snSeti, snSetr
function setoptions(options, work)

    # --- set options ----
    errors = Cint[0]

    for key in keys(options)
        value = options[key]
        buffer = string(key, repeat(" ", 55-length(key)))  # buffer length is 55 so pad with space.

        if length(key) > 55
            @warn "invalid option, too long"
            continue
        end

        errors[1] = 0

        if typeof(value) == String
            # snSet is intended for string containing both the key and value in the string, 
            # not for when the value alone is a string. File names are handled separately
            # for more information please see 
            # https://web.stanford.edu/group/SOL/guides/sndoc7.pdf page 66 (sec 7.5).

            if key != "Print file" && key != "Summary file" 
                value = string(value, repeat(" ", 72-length(value)))
                ccall( (:snset_, snoptlib), Nothing,
                    (Ptr{Cuchar}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
                    Ptr{Cuchar}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
                    value, PRINTNUM, SUMNUM, errors,
                    work.cw, work.lencw, work.iw, work.leniw, work.rw, work.lenrw)
            end
        elseif isinteger(value)

            ccall( (:snseti_, snoptlib), Nothing,
                (Ptr{Cuchar}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
                Ptr{Cuchar}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
                buffer, value, PRINTNUM, SUMNUM, errors,
                work.cw, work.lencw, work.iw, work.leniw, work.rw, work.lenrw)

        elseif isreal(value)

            ccall( (:snsetr_, snoptlib), Nothing,
                (Ptr{Cuchar}, Ref{Cdouble}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
                Ptr{Cuchar}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
                buffer, value, PRINTNUM, SUMNUM, errors,
                work.cw, work.lencw, work.iw, work.leniw, work.rw, work.lenrw)
        end

        if errors[1] > 0
            @warn errors[1], " errors encountered while setting options"
        end

    end
    
    return nothing
end


# wrapper for snMemA
function setmemory(INFO, nf, nx, nxname, nfname, neA, neG, work)

    mincw = Cint[0]
    miniw = Cint[0]
    minrw = Cint[0]
    
    # --- set memory requirements --- #
    ccall( (:snmema_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint},
        Ref{Cint}, Ref{Cint}, Ref{Cint},
        Ptr{Cuchar}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cdouble}, Ref{Cint}),
        INFO, nf, nx, nxname, nfname, neA, neG,
        mincw, miniw, minrw,
        work.cw, work.lencw, work.iw, work.leniw, work.rw, work.lenrw)

    if INFO[1] != 104
        @warn "error in snmema memory setting: ", INFO[1]
    end

    # --- resize arrays to match memory requirements
    if mincw[1] > work.lencw
        work.lencw = mincw[1]
        resize!(work.cw, work.lencw*8)
    end
    if miniw[1] > work.leniw
        work.leniw = miniw[1]
        resize!(work.iw, work.leniw)
    end
    if minrw[1] > work.lenrw
        work.lenrw = minrw[1]
        resize!(work.rw, work.lenrw)
    end

    memkey = ("Total character workspace", "Total integer   workspace",
        "Total real      workspace")
    memvalue = (work.lencw, work.leniw, work.lenrw)
    errors = Cint[0]
    for (key,value) in zip(memkey, memvalue)
        buffer = string(key, repeat(" ", 55-length(key)))  # buffer length is 55 so pad with space.
        errors[1] = 0
        ccall( (:snseti_, snoptlib), Nothing,
            (Ptr{Cuchar}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
            Ptr{Cuchar}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
            buffer, value, PRINTNUM, SUMNUM, errors,
            work.cw, work.lencw, work.iw, work.leniw, work.rw, work.lenrw)
        if errors[1] > 0
            @warn errors[1], " error encountered while lengths in options from memory sizing"
        end
    end

    return nothing
end


"""
    f, fail = example!(g, df, dg, x, deriv)

The expected function signature for user functions.

# Arguments
- `g::Vector{Float64}`: (output) constraint vector, modified in place
- `df::Vector{Float64}`: (output) gradient vector, modified in place
- `dg::Vector{Float64}`: (output) constraint jacobian vector, modified in place. 
    dgi/dxj in order corresponding to sparsity pattern provided to snopt 
    (preferably column major order if dense)
- `x::Vector{Float64}`: (input) design variables, unmodified
- `deriv::Bool`: (input) if false snopt does not need derivatives that iteration so you can skip their computation.

# Returns
- `f::Float64`: objective value
- `fail::Bool`: true if function fails to compute at this x
"""
function example!(g, df, dg, x, deriv)
    return 0.0, false
end

global userfunction! = example!

# wrapper for usrfun (augmented with function pass-in)
function usrcallback(status_::Ptr{Cint}, nx::Cint, x_::Ptr{Cdouble},
    needf::Cint, nf::Cint, f_::Ptr{Cdouble}, needG::Cint, ng::Cint,
    G_::Ptr{Cdouble}, cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
    leniu::Cint, ru::Ptr{Cdouble}, lenru::Cint)
    
    # check if solution finished, no need to calculate more
    status = unsafe_load(status_)
    if status >= 2
        return
    end

    # unpack design variables
    x = unsafe_wrap(Array, x_, nx)
   
    # set functions
    f = unsafe_wrap(Array, f_, nf)
    G = unsafe_wrap(Array, G_, ng)
    f[1], fail = userfunction!(@view(f[2:end]), @view(G[1:nx]), @view(G[nx+1:end]), x, needG > 0)

    # check if solutions fails
    if fail
        unsafe_store!(status_, -1, 1)
    end

end

# convenience function used internally to simplify passing in arguments associated with A (linear constraints).
# automatically computes iAfun, jAvar, A, lenA, neA.
function parseAmatrix(A)

    if typeof(A) <: SparseMatrixCSC
        # len = nnz(A)
        r, c, values = findnz(A)
        len = length(r)
        
        rows = zeros(Cint, len)
        rows .= r
        cols = zeros(Cint, len)
        cols .= c
        
    else  # dense
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
    end

    return len, rows, cols, values
end


# commonly used convenience method to provide regular starting point (cold start)
function snopta(func!, x0::T, lx, ux, lg, ug, rows, cols, 
    options=Dict(); A=[], names=Names(), objadd=0.0) where T<:Vector

    start = ColdStart(x0, length(lg)+1)
    
    return snopta(func!, start, lx, ux, lg, ug, rows, cols, options, A=A, names=names, objadd=objadd)
end

"""
    snopta(func!, x0, lx, ux, lg, ug, rows, cols, 
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
function snopta(func!, start::Start, lx, ux, lg, ug, rows, cols, 
    options=Dict(); A=[], names=Names(), objadd=0.0)

    # --- number of functions ----
    nx = length(start.x)
    ng = length(lg)
    nf = 1 + length(lg)
    lf = [0.0; lg]  # bounds on objective are irrelevant
    uf = [0.0; ug]  
    global userfunction! = func!
   
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
    
    if nxname == nx && nfname == nf
        names = processnames(names) # TODO: prob not type stable if names are added
    end
    
    # ---- parse linear constraints -------
    lenA, iAfun, jAvar, Aval = parseAmatrix(A)
    neA = lenA

    # ----- setup user function ---------------
    # c wrapper to callback function
    usrfun = @cfunction(usrcallback, Cvoid, (Ptr{Cint}, Ref{Cint}, Ptr{Cdouble},
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

    ccall( (:snopta_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, 
        Ref{Cdouble}, Ref{Cint}, Ptr{Cuchar}, Ptr{Nothing}, 
        Ptr{Cint}, Ptr{Cint}, Ref{Cint}, Ref{Cint}, Ptr{Cdouble}, 
        Ptr{Cint}, Ptr{Cint}, Ref{Cint}, Ref{Cint},
        Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cuchar}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cuchar}, 
        Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}, 
        Ptr{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, 
        Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, 
        Ptr{Cuchar}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}, 
        Ptr{Cuchar}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
        start.start, nf, nx, nxname, nfname, 
        objadd, objrow, names.prob, usrfun, 
        iAfun, jAvar, lenA, neA, Aval, 
        iGfun, jGvar, lenG, neG,
        lx, ux, names.xnames, lf, uf, names.fnames, 
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


end  # end module
