PROGRAM lare3d

  USE shared_data
  USE initial_conditions
  USE setup
  USE boundary
  USE openboundary
  USE diagnostics
  USE lagran
  USE remap
  USE mpi_routines
  USE welcome
  USE normalise
  USE neutral
  USE control
  USE corks

  IMPLICIT NONE

  INTEGER :: i = 0

  CALL MPI_INIT(errcode)

  CALL before_control      ! setup.F90
  CALL user_normalisation  ! control.f90
  CALL control_variables   ! control.f90
  CALL set_output_dumps    ! control.f90
  CALL mpi_initialise      ! mpi_routines.f90
  CALL after_control       ! setup.f90

  CALL welcome_message     ! welcome.f90

  CALL setup_neutral ! neutral.f90
  CALL normalise_transport  ! normalise.f90

  CALL set_boundary_conditions   ! boundary.f90
  CALL grid                      ! setup.f90 
  
  IF (IAND(initial, IC_RESTART) .NE. 0) THEN
    restart = .TRUE.
    CALL restart_data            ! setup.f90
  ELSE
    restart = .FALSE.
    restart_snapshot = 0     
    CALL set_initial_conditions  ! initial_conditions.f90
  END IF

  CALL open_files                ! setup.f90

  CALL set_boundary_conditions   ! boundary.f90
  CALL boundary_conditions       ! boundary.f90
  CALL eta_calc                  ! lagran.f90

  IF (eos_number /= EOS_IDEAL) CALL neutral_fraction ! neutral.f90 
  IF (eos_number == EOS_IDEAL .AND. neutral_gas) xi_n = 1.0_num
  IF (cowling_resistivity) CALL perpendicular_resistivity ! neutral.f90

  IF (rank .EQ. 0) PRINT *, "Initial conditions setup OK. Running Code"

  IF (diag_corks) THEN
    CALL deploy_cork_fleet       ! corks.f90  
  END IF
  
  CALL output_routines(i)        ! diagnostics.f90
  
  DO
    IF ((i >= nsteps .AND. nsteps >= 0) .OR. (time >= t_end)) EXIT
    i = i + 1
    CALL eta_calc                    ! lagran.f90
    CALL set_dt                      ! diagnostics.f90  
    IF (eos_number /= EOS_IDEAL) CALL neutral_fraction ! neutral.f90    
    CALL lagrangian_step             ! lagran.f90
    CALL eulerian_remap(i)           ! remap.f90
    IF (rke) CALL energy_correction  ! diagnostics.f90
    IF (any_open) THEN
      CALL open_bcs                  ! openboundary.f90
    END IF
    IF (diag_corks) THEN      
      CALL update_cork_fleet         ! corks.f90               
    END IF
    CALL output_routines(i)          ! diagnostics.f90
  END DO

  IF (rank .EQ. 0) PRINT *, "Code Terminated normally"
  CALL mpi_close                     ! mpi_routines.f90
  CALL close_files                   ! setup.f90
  IF (diag_corks) THEN
    CALL retire_cork_fleet           ! corks.f90
  END IF
  CALL MPI_FINALIZE(errcode)

END PROGRAM lare3d
