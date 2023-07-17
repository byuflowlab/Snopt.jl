module Snopt

using SparseArrays

export snsolve, snopta
export ColdStart, WarmStart

# Set path do snopt dynamic library
const snoptlib = joinpath(@__DIR__, "..", "deps", "lib", "libsnopt")
include_dependency(snoptlib)

"""
Define global variables for print and summery file numbers.
"""
PRINTNUM = 18
SUMNUM = 6

# Utility functions
include("utils.jl")
include("sparse.jl")

# Types
include("Names.jl")
include("Start.jl")
include("Workspace.jl")
include("Outputs.jl")

# SNOPT function wrappers
include("ccalls.jl")

# SNOPT interfaces
include("userfun.jl")
include("snsolve.jl")
include("snopta.jl")

end  # end module
