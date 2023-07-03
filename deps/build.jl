if Sys.isunix()
    suffix = Sys.isapple() ? "dylib" : "so"
    cd(joinpath(dirname(@__FILE__), "src"))
    if isfile("libsnopt.$suffix")
        rm("libsnopt.$suffix")
    end
    try
        run(`make FC=ifort SUFFIX=$suffix`)
    catch
        run(`make FC=gfortran SUFFIX=$suffix`)
    end
else
    suffix = "dll"
    cd(joinpath(dirname(@__FILE__), "src"))
    if isfile("libsnopt.$suffix")
        rm("libsnopt.$suffix")
    end
    run(`mingw32-make FC=gfortran SUFFIX=$suffix`)
end
