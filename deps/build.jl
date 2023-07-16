if Sys.isunix()
    # Get library suffix 
    suffix = Sys.isapple() ? "dylib" : "so"

    # Remove libsnopt.suffix if it exists
    isfile("libsnopt.$suffix") && rm("libsnopt.$suffix")

    # Move into src directory
    cd(joinpath(@__DIR__, "src"))

    # Build library
    try
        run(`make FC=ifort SUFFIX=$suffix`)
    catch
        run(`make FC=gfortran SUFFIX=$suffix`)
    end

    # Move library to deps directory
    mv("libsnopt.$suffix", joinpath(@__DIR__, "libsnopt.$suffix"))
else
    # Set library suffic
    suffix = "dll"

    # Remove libsnopt.dll if it exists
    isfile("libsnopt.$suffix") && rm("libsnopt.$suffix")

    # Move into src directory
    cd(joinpath(@__DIR__, "src"))

    # FC
    FC = "C:\\Program Files (x86)\\Intel\\oneAPI\\compiler\\latest\\windows\\bin\\intel64\\ifort"

    # Build library
    run(`mingw32-make FC=$FC SUFFIX=$suffix`)

    # Move library to deps directory
    mv("libsnopt.$suffix", joinpath(@__DIR__, "libsnopt.$suffix"))
end
