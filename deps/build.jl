if Sys.isunix()
    suffix = Sys.isapple() ? "dylib" : "so"
    cd(joinpath(dirname(@__FILE__), "src"))
    if isfile("libsnopt.$suffix")
        rm("libsnopt.$suffix")
    end
    try
        run(`make FC=ifort LD=ifort SUFFIX=$suffix`)
    catch
        run(`make FC=gfortran LD=gfortran SUFFIX=$suffix`)
    end
else
    error("windows currently unsupported")
end
