
# Contains wrappers of SNOPT functions

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

function snopta!(Start::Cint,
                 nF::Integer, n::Integer,
                 nxname::Integer, nFname::Integer,
                 ObjAdd::Float64, ObjRow::Integer, 
                 Prob::Vector{Cuchar}, usrfun::Base.CFunction,
                 iAfun::Vector{IT1}, jAvar::Vector{IT2}, 
                 lenA::Integer, neA::Integer, A::Vector{Float64},
                 iGfun::Vector{Cint}, jGvar::Vector{Cint}, 
                 lenG::Integer, neG::Integer,
                 xlow::Vector{Float64}, xupp::Vector{Float64}, xnames::Vector{Cuchar}, 
                 Flow::Vector{Float64}, Fupp::Vector{Float64}, Fnames::Vector{Cuchar},
                 x::Vector{Float64}, xstate::Vector{Cint}, xmul::Vector{Float64}, 
                 F::Vector{Float64}, Fstate::Vector{Cint}, Fmul::Vector{Float64},
                 INFO::Vector{Cint}, 
                 mincw::Vector{Cint}, miniw::Vector{Cint}, minrw::Vector{Cint}, 
                 ns::Vector{Cint}, nInf::Vector{Cint}, sInf::Vector{Cdouble},
                 cu::Vector{Cuchar}, lencu::Integer, 
                 iu::Vector{Cint}, leniu::Integer, 
                 ru::Vector{Float64}, lenru::Integer,
                 cw::Vector{Cuchar}, lencw::Integer, 
                 iw::Vector{Cint}, leniw::Integer, 
                 rw::Vector{Float64}, lenrw::Integer) where {IT1<:Integer, IT2<:Integer}

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
        Start, nF, n, nxname, nFname, 
        ObjAdd, ObjRow, Prob, usrfun, 
        iAfun, jAvar, lenA, neA, A, 
        iGfun, jGvar, lenG, neG,
        xlow, xupp, xnames, Flow, Fupp, Fnames, 
        x, xstate, xmul, F, Fstate, Fmul, 
        INFO, mincw, miniw, minrw, 
        ns, nInf, sInf, 
        cu, lencu, iu, leniu, ru, lenru, 
        cw, lencw, iw, leniw, rw, lenrw)
    return nothing
end