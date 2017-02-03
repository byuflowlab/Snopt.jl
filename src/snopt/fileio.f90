subroutine openfiles(printnum, printerr)

    ! inputs
    integer, intent(in) :: printnum

    ! outputs
    integer, intent(out) :: printerr

    open(printnum, file='snopt-print.out', action='write', status='replace', iostat=printerr)

end subroutine


subroutine closefiles(printnum)

    ! inputs
    integer, intent(in) :: printnum

    close(printnum)

end subroutine




! subroutine openfiles(printnum, sumnum, printerr, sumerr)
!
!     ! inputs
!     integer, intent(in) :: printnum, sumnum
!
!     ! outputs
!     integer, intent(out) :: printerr, sumerr
!
!     open(printnum, file='snopt-print.txt', action='write', status='replace', iostat=printerr)
!     open(sumnum, file='snopt-summary.txt', action='write', status='replace', iostat=sumerr)
!
!
! end subroutine
!
!
! subroutine closefiles(printnum, sumnum)
!
!     ! inputs
!     integer, intent(in) :: printnum, sumnum
!
!     close(printnum)
!     close(sumnum)
!
! end subroutine
!
