# =====  Build options (would be nice to set these automatically or as arg to julia>]build )
# Windows : MSVC (ifort) or GNU (gfortran)
use_msvc     = true   # Set to false to use gfortran and MinGW
msvc_version = "17"
msvc_year    = "2022"

# BLAS
use_BLAS     = true
use_MKL      = true
use_OPENBlas = false
OPENBlas_DIR = joinpath("C:\\Source","OpenBLAS","install","share","cmake","OpenBLAS") 

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
    generator = "Ninja"
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
        -DCMAKE_INSTALL_PREFIX=$install_dir 
        -S $src_dir 
        -B $build_dir 
        -G "$generator"
        -DUSE_EXTERNAL_BLAS=$(use_BLAS ? "ON" : "OFF")
        -DUSE_MKL=$(use_MKL ? "ON" : "OFF")
        -DUSE_OPENBLAS=$(use_OPENBlas ? "ON" : "OFF")
        $(use_OPENBlas ? "-DOpenBLAS_DIR=$OPENBlas_DIR" : ())`)

# ===== Build
run(`cmake --build $build_dir --config Release --target install -j $(Sys.CPU_THREADS)`)