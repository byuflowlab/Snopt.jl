module SNOPT_Julia_c

    use iso_c_binding
    use iso_fortran_env

    implicit none

    private :: copy_a2s

contains

    subroutine openfile(funit, ferror, fname, len_fname) bind(C, name = "SNOPT_openfile")

        ! inputs
        integer(kind = c_int), intent(in) :: funit
        character(kind = c_char), dimension(*), intent(in) :: fname
        integer(kind = c_int), intent(in) :: len_fname
        ! character*250, intent(in) :: fname

        ! outputs
        integer(kind = c_int), intent(out) :: ferror

        open(funit, file = copy_a2s(fname(1:len_fname)), action = 'write', status = 'replace', iostat = ferror)

    end subroutine

    function get_stdout() bind(C, name = "SNOPT_get_stdout")
        ! output
        integer(kind = c_int) :: get_stdout
        get_stdout = output_unit
    end function

    subroutine closefile(funit) bind(C, name = "SNOPT_closefile")

        ! inputs
        integer(kind = c_int), intent(in) :: funit

        close(funit)

    end subroutine

    subroutine flushfile(funit) bind(C, name = "SNOPT_flushfile")

        ! inputs
        integer(kind = c_int), intent(in) :: funit

        flush(funit)

    end subroutine

    pure function copy_a2s(a) result(s)
        character(kind = c_char), intent(in) :: a(:)
        character(size(a)) :: s
        integer :: i
        s = ''
        do i = 1, size(a)
            if (a(i) == c_null_char) exit
            s(i:i) = a(i)
        end do
    end function

end module
