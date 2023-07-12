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