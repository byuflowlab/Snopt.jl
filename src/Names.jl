"""
    Names(prob, xnames, fnames)

Convenience to put custom names in output files.
Arguments to variables of same names in snOptA. 
Use strings and vectors of strings.
"""
struct Names
    prob::String
    xnames::Vector{String}
    fnames::Vector{String}
end

"""
    Names()

Default names (uses snopt defaults for xnames, fnames)
"""
Names() = Names("Opt Prob", [""], [""])