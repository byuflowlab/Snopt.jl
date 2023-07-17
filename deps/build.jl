# =====  Build options (would be nice to set these automatically or as arg to julia>]build )
# CMake directory (set to full path if not in PATH)
cmake_path  = "cmake"

# Windows : MSVC (ifort) or GNU (gfortran)
win_use_msvc        = true     # Set to false to use gfortran and MinGW
win_msvc_version    = "17"
win_msvc_year       = "2022"

# Unix : GNU (gfortran) or Intel (ifort)
unix_use_gfortran   = true      # Set to false to use ifort
unix_use_ninja      = true      # Set to false to use GNU make

# BLAS
use_BLAS     = true
use_MKL      = true
use_OpenBLAS = false
OpenBLAS_DIR = joinpath("C:\\Source","OpenBLAS","install","share","cmake","OpenBLAS") 

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
    if unix_use_ninja
        generator = "Ninja"
    else
        generator = "Unix Makefiles"
    end
else
    if win_use_msvc
        generator = "Visual Studio $win_msvc_version $win_msvc_year"
    else
        generator = "MinGW Makefiles" 
    end
end

# ===== Configuration
boolToStr(x) = x ? "ON" : "OFF"
cmd = `$cmake_path --no-warn-unused-cli 
        -DCMAKE_BUILD_TYPE=Release 
        -DCMAKE_INSTALL_PREFIX=$install_dir 
        -S $src_dir 
        -B $build_dir 
        -G "$generator"
        -DUSE_EXTERNAL_BLAS=$(boolToStr(use_BLAS))
        -DUSE_MKL=$(boolToStr(use_MKL))
        -DUSE_OpenBLAS=$(boolToStr(use_OpenBLAS))
        -DOpenBLAS_DIR=$OpenBLAS_DIR`
run(cmd)

# ===== Build
cmd  = `$cmake_path --build $build_dir --config Release --target install`
run(cmd)