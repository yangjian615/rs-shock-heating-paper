COMMON wkdirs, wkdir_global

@ ./StartCFD.pro
.r ./StartLARE.pro

Q0 = 1.60217646d-19 ; proton charge [C]
M0 = 9.10938188d-31 ; electron mass [kg]
kb = 1.3806503d-23  ; Boltzmann's constant [J/K]

wkdir_global="data"

!PATH=!PATH+':./'
!PATH=!PATH+':./data'
!PATH=!PATH+':./plot'
!PATH=!PATH+':./misc'
!PATH=!PATH+':./coyote'
!PATH=!PATH+':./nasa'
