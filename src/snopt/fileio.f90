subroutine openfiles(printnum, sumnum, printerr, sumerr)

    ! inputs
    integer, intent(in) :: printnum, sumnum

    ! outputs
    integer, intent(out) :: printerr, sumerr

    open(printnum, file='snopt-print.out', action='write', status='replace', iostat=printerr)
    open(sumnum, file='snopt-summary.out', action='write', status='replace', iostat=sumerr)


end subroutine


subroutine closefiles(printnum, sumnum)

    ! inputs
    integer, intent(in) :: printnum, sumnum

    close(printnum)
    close(sumnum)

end subroutine
