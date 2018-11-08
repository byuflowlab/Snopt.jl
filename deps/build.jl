if Sys.isunix()
    suffix = Sys.isapple() ? "dylib" : "so"
    cd(joinpath(dirname(@__FILE__), "src"))
    rm("libsnopt.$suffix")
    try
        run(`make FC=ifort SUFFIX=$suffix`)
    catch
        run(`make FC=gfortran SUFFIX=$suffix`)
    end
else
    error("windows currently unsupported")
end
