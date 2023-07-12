module Snopt

using SparseArrays
using Infiltrator

export snsolve, snopta
export ColdStart, WarmStart

const snoptlib = joinpath(dirname(@__FILE__), "../deps/src/libsnopt")

"""
Define global variables for print and summery file numbers.
"""
PRINTNUM = 18
SUMNUM = 6

# Utility functions
include("utils.jl")
include("sparse.jl")

# Types
include("Start.jl")
include("Workspace.jl")
include("Outputs.jl")

# SNOPT function wrappers
include("ccalls.jl")

# SNOPT interfaces
include("snsolve.jl")
include("snopta.jl")

end  # end module
