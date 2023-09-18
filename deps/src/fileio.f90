subroutine openfile(funit, ferror, fname)

    ! inputs
    integer, intent(in) :: funit
    character*250, intent(in) :: fname

    ! outputs
    integer, intent(out) :: ferror

    open(funit, file=fname, action='write', status='replace', iostat=ferror)

end subroutine


subroutine closefile(funit)

    ! inputs
    integer, intent(in) :: funit

    close(funit)

end subroutine


subroutine flushfile(funit)

    ! inputs
    integer, intent(in) :: funit

    flush(funit)

end subroutine
