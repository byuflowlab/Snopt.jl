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