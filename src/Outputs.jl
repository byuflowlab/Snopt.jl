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