# Define constant dictionary to map exit code to message
const codes = Dict(
    1   => "Finished successfully: optimality conditions satisfied",
    2   => "Finished successfully: feasible point found",
    3   => "Finished successfully: requested accuracy could not be achieved",
    11  => "The problem appears to be infeasible: infeasible linear constraints",
    12  => "The problem appears to be infeasible: infeasible linear equalities",
    13  => "The problem appears to be infeasible: nonlinear infeasibilities minimized",
    14  => "The problem appears to be infeasible: infeasibilities minimized",
    15  => "The problem appears to be infeasible: infeasible linear constraints in QP subproblem",
    21  => "The problem appears to be unbounded: unbounded objective",
    22  => "The problem appears to be unbounded: constraint violation limit reached",
    31  => "Resource limit error: iteration limit reached",
    32  => "Resource limit error: major iteration limit reached",
    33  => "Resource limit error: the superbasics limit is too small",
    41  => "Terminated after numerical difficulties: current point cannot be improved",
    42  => "Terminated after numerical difficulties: singular basis",
    43  => "Terminated after numerical difficulties: cannot satisfy the general constraints",
    44  => "Terminated after numerical difficulties: ill-conditioned null-space basis",
    51  => "Error in the user-supplied functions: incorrect objective derivatives",
    52  => "Error in the user-supplied functions: incorrect constraint derivatives",
    61  => "Undefined user-supplied functions: undefined function at the first feasible point",
    62  => "Undefined user-supplied functions: undefined function at the initial point",
    63  => "Undefined user-supplied functions: unable to proceed into undefined region",
    71  => "User requested termination: terminated during function evaluation ",
    74  => "User requested termination: terminated from monitor routine",
    81  => "Insufficient storage allocated: work arrays must have at least 500 elements",
    82  => "Insufficient storage allocated: not enough character storage",
    83  => "Insufficient storage allocated: not enough integer storage",
    84  => "Insufficient storage allocated: not enough real storage",
    91  => "Input arguments out of range: invalid input argument",
    92  => "Input arguments out of range: basis file dimensions do not match this problem",
    141 => "System error: wrong number of basic variables",
    142 => "System error: error in basis package"
)

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