subroutine openfiles(printnum, sumnum, printerr, sumerr, printfile, sumfile)

    ! inputs
    integer, intent(in) :: printnum, sumnum
    character*250, intent(in) :: printfile, sumfile

    ! outputs
    integer, intent(out) :: printerr, sumerr

    open(printnum, file=printfile, action='write', status='replace', iostat=printerr)
    open(sumnum, file=sumfile, action='write', status='replace', iostat=sumerr)


end subroutine


subroutine closefiles(printnum, sumnum)

    ! inputs
    integer, intent(in) :: printnum, sumnum

    close(printnum)
    close(sumnum)

end subroutine


subroutine flushfiles(printnum, sumnum)

    ! inputs
    integer, intent(in) :: printnum, sumnum

    flush(printnum)
    flush(sumnum)

end subroutine
