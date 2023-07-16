# =====  Build options (would be nice to set these automatically or as arg to julia>]build )
# Windows : MSVC (ifort) or GNU (gfortran)
use_msvc     = true   # Set to false to use gfortran and MinGW
msvc_version = "17"
msvc_year    = "2022"

# ===== Remove old build directory
if isdir(joinpath(@__DIR__, "build"))
    rm(joinpath(@__DIR__, "build"); recursive=true, force=true)
end
mkdir(joinpath(@__DIR__, "build"))

# ===== Define CMAKE configuration paths
src_dir     = @__DIR__
build_dir   = joinpath(@__DIR__, "build")
install_dir = joinpath(@__DIR__, "lib")

# Generator
generator = ""
if Sys.isunix()

else
    if use_msvc
        generator = "Visual Studio $msvc_version $msvc_year"
    else
        generator = "MinGW Makefiles" 
    end
end

# ===== Configuration
run(`cmake --no-warn-unused-cli 
        -DCMAKE_BUILD_TYPE=Release 
        -DCMAKE_INSTALL_LIBDIR=$install_dir 
        -S$src_dir -B$build_dir -G"$generator"`)

# ===== Build
run(`cmake --build $build_dir --config Release --target install`)