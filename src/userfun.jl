
"""
    f, fail = example_snsolve!(g, df, dg, x, deriv)

The expected function signature for user functions used with snsolve.

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
function example_snsolve!(g, df, dg, x, deriv)
    return 0.0, false
end

"""
    fail = example_snopta!(f, dg, x, deriv)

The expected function signature for user functions used with snopta.

# Arguments
- `f::Vector{Float64}`: (output) function vector, modified in place
- `dg::Vector{Float64}`: (output) function jacobian vector, modified in place. 
    dgi/dxj in order corresponding to sparsity pattern provided to snopt 
    (preferably column major order if dense)
- `x::Vector{Float64}`: (input) design variables, unmodified
- `deriv::Bool`: (input) if false snopt does not need derivatives that iteration so you can skip their computation.

# Returns
- `fail::Bool`: true if function fails to compute at this x
"""
function example_snopta!(f, dg, x, deriv)
    return false
end

# wrapper for usrfun (augmented with function pass-in)
function usrcallback_snsolve(func!, status_::Ptr{Cint}, 
                             nx::Cint, x_::Ptr{Cdouble},
                             needf::Cint, nf::Cint, f_::Ptr{Cdouble}, 
                             needG::Cint, ng::Cint, G_::Ptr{Cdouble}, 
                             cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
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
    f[1], fail = func!(@view(f[2:end]), @view(G[1:nx]), @view(G[nx+1:end]), x, needG > 0)

    # check if solutions fails
    if fail
        unsafe_store!(status_, -1, 1)
    end
end

function usrcallback_snopta(func!, status_::Ptr{Cint}, 
                            n::Cint, x_::Ptr{Cdouble},
                            needf::Cint, nF::Cint, f_::Ptr{Cdouble}, 
                            needG::Cint, lenG::Cint, G_::Ptr{Cdouble}, 
                            cu::Ptr{Cuchar}, lencu::Cint, iu::Ptr{Cint},
                            leniu::Cint, ru::Ptr{Cdouble}, lenru::Cint)
    
    # check if solution finished, no need to calculate more
    status = unsafe_load(status_)
    if status >= 2
        return
    end

    # unpack design variables
    x = unsafe_wrap(Array, x_, n)
   
    # set functions
    f = unsafe_wrap(Array, f_, nF)
    G = unsafe_wrap(Array, G_, lenG)
    fail = func!(f, G, x, needG > 0)

    # check if solutions fails
    if fail
        unsafe_store!(status_, -1, 1)
    end
end