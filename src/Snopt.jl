module Snopt

using SparseArrays

export snopt

# __precompile__(false)

const snoptlib = joinpath(dirname(@__FILE__), "../deps/src/libsnopt")

const codes = Dict{Int64, String}()
codes[1] = "Finished successfully: optimality conditions satisfied"
codes[2] = "Finished successfully: feasible point found"
codes[3] = "Finished successfully: requested accuracy could not be achieved"
codes[11] = "The problem appears to be infeasible: infeasible linear constraints"
codes[12] = "The problem appears to be infeasible: infeasible linear equalities"
codes[13] = "The problem appears to be infeasible: nonlinear infeasibilities minimized"
codes[14] = "The problem appears to be infeasible: infeasibilities minimized"
codes[15] = "The problem appears to be infeasible: infeasible linear constraints in QP subproblem"
codes[21] = "The problem appears to be unbounded: unbounded objective"
codes[22] = "The problem appears to be unbounded: constraint violation limit reached"
codes[31] = "Resource limit error: iteration limit reached"
codes[32] = "Resource limit error: major iteration limit reached"
codes[33] = "Resource limit error: the superbasics limit is too small"
codes[41] =  "Terminated after numerical difficulties: current point cannot be improved"
codes[42] =  "Terminated after numerical difficulties: singular basis"
codes[43] =  "Terminated after numerical difficulties: cannot satisfy the general constraints"
codes[44] =  "Terminated after numerical difficulties: ill-conditioned null-space basis"
codes[51] =  "Error in the user-supplied functions: incorrect objective derivatives"
codes[52] =  "Error in the user-supplied functions: incorrect constraint derivatives"
codes[61] =  "Undefined user-supplied functions: undefined function at the first feasible point"
codes[62] =  "Undefined user-supplied functions: undefined function at the initial point"
codes[63] =  "Undefined user-supplied functions: unable to proceed into undefined region"
codes[71] =  "User requested termination: terminated during function evaluation "
codes[74] =  "User requested termination: terminated from monitor routine"
codes[81] =  "Insufficient storage allocated: work arrays must have at least 500 elements"
codes[82] =  "Insufficient storage allocated: not enough character storage"
codes[83] =  "Insufficient storage allocated: not enough integer storage"
codes[84] =  "Insufficient storage allocated: not enough real storage"
codes[91] =  "Input arguments out of range: invalid input argument"
codes[92] =  "Input arguments out of range: basis file dimensions do not match this problem"
codes[141] =  "System error: wrong number of basic variables"
codes[142] =  "System error: error in basis package"


const PRINTNUM = 18
const SUMNUM = 19

# callback function
function objcon_wrapper(objcon, status_::Ptr{Int32}, n::Int32, x_::Ptr{Cdouble},
    needf::Int32, nF::Int32, f_::Ptr{Cdouble}, needG::Int32, lenG::Int32,
    G_::Ptr{Cdouble}, cu::Ptr{UInt8}, lencu::Int32, iu::Ptr{Cint},
    leniu::Int32, ru_::Ptr{Cdouble}, lenru::Int32)

    status = unsafe_load(status_)

    # check if solution finished, no need to calculate more
    if status >= 2
        return
    end

    # unpack design variables
    x = zeros(n)
    for i = 1:n
        x[i] = unsafe_load(x_, i)
    end
    # x = unsafe_load(x_)  # TODO: test this

    # call function
    res = objcon(x)
    if length(res) == 3
        J, c, fail = res
        ceq = Float64[]
        gradprovided = false
    elseif length(res) == 4
        J, c, ceq, fail = res
        gradprovided = false
    elseif length(res) == 5
        J, c, gJ, gc, fail = res
        ceq = Float64[]
        gceq = spzeros(1, 1)
        gradprovided = true
    else
        J, c, ceq, gJ, gc, gceq, fail = res
        gradprovided = true
    end

    # copy obj and con values into C pointer
    unsafe_store!(f_, J, 1)
    for i = 2 : nF - length(ceq)
        unsafe_store!(f_, c[i-1], i)
    end
    if !isempty(ceq)
        for i = nF - length(ceq) + 1 : nF
            unsafe_store!(f_, ceq[i-length(c)-1], i)
        end
    end

    # gradients  TODO: separate gradient computation in interface?
    if needG > 0 && gradprovided

        for j = 1:n
            # gradients of f
            unsafe_store!(G_, gJ[j], j)
        end

        if typeof(gc) <: SparseMatrixCSC  # check if sparse

            k = n
            _, _, Vsp = findnz(gc)
            for i = 1:length(Vsp)
                unsafe_store!(G_, Vsp[i], k+i)
            end

            k += length(Vsp)
            _, _, Vsp = findnz(gceq)
            for i = 1:length(Vsp)
                unsafe_store!(G_, Vsp[i], k+i)
            end

        else

            k = n+1
            for i = 2 : nF - length(ceq)
                for j = 1:n
                    unsafe_store!(G_, gc[i-1, j], k)
                    k += 1
                end
            end
            for i = nF - length(ceq) + 1 : nF
                for j = 1:n
                    unsafe_store!(G_, gceq[i-length(c)-1, j], k)
                    k += 1
                end
            end
        end

    end

    # check if solutions fails
    if fail
        unsafe_store!(status_, -1, 1)
    end

    # flush output files to see progress
    ccall( (:flushfiles_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}),
        PRINTNUM, SUMNUM)


end

# main call to snopt
function snopt(objcon, x0, lb, ub, options;
               printfile = "snopt-print.out", sumfile = "snopt-summary.out")

    # make sure wrapper uses print file and summary file names if given in options
    if !isempty(options)
        if haskey(options, "Print file")
            printfile = options["Print file"]
        end
        if haskey(options, "Summary file")
            sumfile = options["Summary file"]
        end
    end

    # call function
    res = objcon(x0)
    if length(res) == 3
        J, c, fail = res
        ceq = Float64[]
        gradprovided = false
    elseif length(res) == 4
        J, c, ceq, fail = res
        gradprovided = false
    elseif length(res) == 5
        J, c, gJ, gc, fail = res
        ceq = Float64[]
        gceq = spzeros(1, 1)
        gradprovided = true
    else
        J, c, ceq, gJ, gc, gceq, fail = res
        gradprovided = true
    end

    objcon_wrapped = function(status_::Ptr{Int32}, n::Int32, x_::Ptr{Cdouble},
        needf::Int32, nF::Int32, f_::Ptr{Cdouble}, needG::Int32, lenG::Int32,
        G_::Ptr{Cdouble}, cu::Ptr{UInt8}, lencu::Int32, iu::Ptr{Cint},
        leniu::Int32, ru_::Ptr{Cdouble}, lenru::Int32)

        objcon_wrapper(objcon, status_, n, x_, needf, nF, f_, needG, lenG,
            G_, cu, lencu, iu, leniu, ru_, lenru)

        return nothing
    end

    # c wrapper to callback function
    usrfun = @cfunction($objcon_wrapped, Nothing, (Ptr{Cint}, Ref{Cint}, Ptr{Cdouble},
        Ref{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}, Ref{Cint}, Ptr{Cdouble},
        Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}))

    # TODO: set a timer


    # setup
    Start = 0  # cold start  # TODO: allow warm starts
    nF = 1 + length(c) + length(ceq)  # 1 objective + constraints
    n = length(x0)  # number of design variables
    ObjAdd = 0.0  # no constant term added to objective (user can add themselves if desired)
    ObjRow = 1  # objective is first thing returned, then constraints

    # linear constraints (none for now)
    iAfun = Int32[1]
    jAvar = Int32[1]
    A = [0.0]  # TODO: change later
    lenA = 1
    neA = 0

    # derivatives of obj and nonlinear constraints
    
    if gradprovided && typeof(gc) <: SparseMatrixCSC  # check if sparse
        lenG = n + length(gc.nzval) + length(gceq.nzval)
    else
        lenG = nF*n
    end

    neG = lenG
    iGfun = Array{Int32}(undef, lenG)
    jGvar = Array{Int32}(undef, lenG)

    if gradprovided && typeof(gc) <: SparseMatrixCSC  # check if sparse

        # objective gradients (assumed dense as it is just a vector)
        for j = 1:n
            iGfun[j] = 1
            jGvar[j] = j
        end

        idx = n
        Isp, Jsp, Vsp = findnz(gc)
        for k = 1:length(Isp)
            iGfun[idx+k] = Isp[k] + 1
            jGvar[idx+k] = Jsp[k]
        end

        idx = n + length(Isp)
        Isp, Jsp, Vsp = findnz(gceq)
        for k = 1:length(Isp)
            iGfun[idx+k] = Isp[k] + 1 + length(c)
            jGvar[idx+k] = Jsp[k]
        end

    else
        k = 1
        for i = 1:nF
            for j = 1:n
                iGfun[k] = i
                jGvar[k] = j
                k += 1
            end
        end
    end

    # bound constriaints (no infinite bounds for now)
    xlow = convert(Vector{Cdouble}, lb)
    xupp = convert(Vector{Cdouble}, ub)
    Flow = -1e20*ones(nF)  # TODO: check Infinite Bound size
    Fupp = zeros(nF)  # TODO: currently c <= 0, but perhaps change

    if !isempty(ceq) #equality constraints
        Flow[nF - length(ceq) + 1 : nF] .= 0.0
    end

    # names
    Prob = "opt prob"  # problem name TODO: change later
    nxname = 1  # TODO: change later
    xnames = Array{UInt8}(undef, nxname, 8)
    # xnames = ["TODOTODO"]
    nFname = 1  # TODO: change later
    Fnames = Array{UInt8}(undef, nFname, 8)
    # Fnames = ["TODOTODO"]

    # starting info
    x = convert(Vector{Cdouble}, x0)
    xstate = zeros(n)
    xmul = zeros(n)
    F = zeros(nF)
    Fstate = zeros(nF)
    Fmul = zeros(nF)
    # INFO = 0
    INFO = Cint[0]
    mincw = Cint[0]  # TODO: check that these are sufficient
    miniw = Cint[0]
    minrw = Cint[0]
    nS = Cint[0]
    nInf = Cint[0]
    sInf = Cdouble[0]
    lencu = 1
    cu = Array{UInt8}(undef, lencu, 8)
    iu = Int32[0]
    leniu = length(iu)
    ru = [0.0]
    lenru = length(ru)

    # open files for printing
    iprint = PRINTNUM
    isumm = SUMNUM
    printerr = Cint[0]
    sumerr = Cint[0]
    ccall( (:openfiles_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{UInt8}, Ptr{UInt8}),
        iprint, isumm, printerr, sumerr, printfile, sumfile)
    if printerr[1] != 0
        println("failed to open print file")
    end
    if sumerr[1] != 0
        println("failed to open summary file")
    end

    # temporary working arrays
    ltmpcw = 500
    cw = Array{UInt8}(undef, ltmpcw*8)
    ltmpiw = 500
    iw = Array{Int32}(undef, ltmpiw)
    ltmprw = 500
    rw = Array{Float64}(undef, ltmprw)

    # compilation command I used (OS X with gfortran):
    # gfortran -shared -O2 *.f *.f90 -o libsnopt.dylib -fPIC -v

    # --- initialize ----
    ccall( (:sninit_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}, Ptr{UInt8}, Ref{Cint}, Ptr{Cint},
        Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
        iprint, isumm, cw, ltmpcw, iw,
        ltmpiw, rw, ltmprw)

    # --- set options ----
    errors = Cint[0]

    for key in keys(options)
        value = options[key]
        buffer = string(key, repeat(" ", 55-length(key)))  # buffer length is 55 so pad with space.

        if length(key) > 55
            println("warning: invalid option, too long")
            continue
        end

        errors[1] = 0

        if typeof(value) == String

            value = string(value, repeat(" ", 72-length(value)))

            ccall( (:snset_, snoptlib), Nothing,
                (Ptr{UInt8}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
                Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
                value, iprint, isumm, errors,
                cw, ltmpcw, iw, ltmpiw, rw, ltmprw)

        elseif isinteger(value)

            ccall( (:snseti_, snoptlib), Nothing,
                (Ptr{UInt8}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
                Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
                buffer, value, iprint, isumm, errors,
                cw, ltmpcw, iw, ltmpiw, rw, ltmprw)

        elseif isreal(value)

            ccall( (:snsetr_, snoptlib), Nothing,
                (Ptr{UInt8}, Ref{Cdouble}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
                Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
                buffer, value, iprint, isumm, errors,
                cw, ltmpcw, iw, ltmpiw, rw, ltmprw)

        end

        # println(errors[1])

    end

    # --- set memory requirements --- #
    ccall( (:snmema_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint},
        Ref{Cint}, Ref{Cint}, Ref{Cint},
        Ptr{UInt8}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cdouble}, Ref{Cint}),
        INFO, nF, n, nxname, nFname, neA, neG,
        mincw, miniw, minrw,
        cw, ltmpcw, iw, ltmpiw, rw, ltmprw)

    # --- resize arrays to match memory requirements
    lencw = mincw
    resize!(cw,lencw[1]*8)
    leniw = miniw
    resize!(iw,leniw[1])
    lenrw = minrw
    resize!(rw,lenrw[1])

    memkey = ("Total character workspace", "Total integer   workspace",
        "Total real      workspace")
    memvalue = (lencw,leniw,lenrw)
    for (key,value) in zip(memkey,memvalue)
        buffer = string(key, repeat(" ", 55-length(key)))  # buffer length is 55 so pad with space.
        errors[1] = 0
        ccall( (:snseti_, snoptlib), Nothing,
            (Ptr{UInt8}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
            Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ptr{Cdouble}, Ref{Cint}),
            buffer, value, iprint, isumm, errors,
            cw, ltmpcw, iw, ltmpiw, rw, ltmprw)
    end

    # --- call snopta ----

    ccall( (:snopta_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cdouble},
        Ref{Cint}, Ptr{UInt8}, Ptr{Nothing}, Ptr{Cint}, Ptr{Cint}, Ref{Cint},
        Ref{Cint}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ref{Cint}, Ref{Cint},
        Ptr{Cdouble}, Ptr{Cdouble}, Ptr{UInt8}, Ptr{Cdouble}, Ptr{Cdouble},
        Ptr{UInt8}, Ptr{Cdouble}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cint},
        Ptr{Cdouble}, Ptr{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ptr{Cint},
        Ptr{Cint}, Ptr{Cdouble}, Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint},
        Ptr{Cdouble}, Ref{Cint}, Ptr{UInt8}, Ref{Cint}, Ptr{Cint}, Ref{Cint},
        Ptr{Cdouble}, Ref{Cint}),
        Start, nF, n, nxname, nFname, ObjAdd,
        ObjRow, Prob, usrfun, iAfun, jAvar, lenA,
        neA, A, iGfun, jGvar, lenG, neG,
        xlow, xupp, xnames, Flow, Fupp,
        Fnames, x, xstate, xmul, F, Fstate,
        Fmul, INFO, mincw, miniw, minrw, nS,
        nInf, sInf, cu, lencu, iu, leniu,
        ru, lenru, cw, lencw, iw, leniw,
        rw, lenrw)

    # println("done")

    # close output files
    ccall( (:closefiles_, snoptlib), Nothing,
        (Ref{Cint}, Ref{Cint}),
        iprint, isumm)


    return x, F[1], codes[INFO[1]]  # xstar, fstar, info

end


end  # end module
