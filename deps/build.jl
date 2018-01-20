if is_unix()
    suffix = is_apple() ? "dylib" : "so"
    cd(joinpath(dirname(@__FILE__), "src"))
    try
        run(`make FC=ifort SUFFIX=$suffix`)
    catch
        run(`make FC=gfortran SUFFIX=$suffix`)
    end
else
    error("windows currently unsupported")
end
