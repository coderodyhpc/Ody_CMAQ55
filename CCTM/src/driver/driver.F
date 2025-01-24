      SUBROUTINE CMAQ_DRIVER ( MODEL_STDATE, MODEL_STTIME, MODEL_TSTEP,
     $                         MODEL_JDATE, MODEL_JTIME, LAST_STEP,
     $                         COUPLE_TSTEP, NCOLS_IN, NLAYS_IN)

      USE RXNS_DATA             ! chemical mechanism data
      USE CENTRALIZED_IO_MODULE
      USE ASX_DATA_MOD, Only : MET_DATA, INIT_MET, GET_MET
      USE LSM_MOD
      USE WVEL_DEFN             ! derived vertical velocity component
      USE BUDGET_DEFN
      USE AERO_DATA
      USE ELMO_DATA, ONLY : L_ELMO, ELMO_NSTEP
      USE ELMO_PROC, ONLY : ELMO_DRIVER, WRITE_ELMO, MAP_ELMO
      USE UTILIO_DEFN
      USE util_Family_module
      USE RUNTIME_VARS
      USE STD_CONC              ! standard CONC
      USE CGRID_SPCS            ! CGRID mechanism species
#ifdef mpas
      USE HGRD_DEFN, ONLY: MYPE
      use coupler_module
      use VGRD_DEFN, ONLY : NLAYS
      use HGRD_DEFN, ONLY : NCOLS, NROWS

      use mydata_module
      use get_env_module
      use lus_defn
      use mio_module
#else
      USE PCGRID_DEFN           ! inherits GRID_CONF
      USE AVG_CONC              ! integral average CONC
      USE PA_DEFN, Only: LIPR, LIRR  ! Process Anaylsis control and data variables
      USE PAGRD_DEFN            ! Process Anaylsis horiz domain specs

      USE BIDI_MOD, Only : INIT_BIDI

#ifdef parallel
      USE VERTEXT_MODULE
#endif
      USE lus_data_module

#ifdef parallel
      USE SE_MODULES            ! stenex (using SE_INIT_MODULE)
#else
      USE NOOP_MODULES          ! stenex (using NOOP_INIT_MODULE)
#endif
#endif   ! end mpas

      IMPLICIT NONE

      INTEGER, INTENT( IN )  :: MODEL_STDATE, MODEL_STTIME, MODEL_TSTEP
      INTEGER, INTENT( OUT ) :: MODEL_JDATE, MODEL_JTIME
      LOGICAL, INTENT( IN )  :: LAST_STEP
      INTEGER, INTENT( IN ), OPTIONAL :: COUPLE_TSTEP
      INTEGER, INTENT( IN ), OPTIONAL :: NCOLS_IN, NLAYS_IN

#ifdef mpas
      real, parameter :: cmin = 1.0E-30

      integer :: ncols_gl
#endif

C Include Files:
      INCLUDE SUBST_FILES_ID    ! I/O definitions and declarations

#ifdef parallel
!     INCLUDE SUBST_MPI         ! MPI definitions and parameters
      INCLUDE 'mpif.h'
#endif

C Local variables:

      INTEGER, SAVE :: TSTEP( 3 ) ! time step vector (HHMMSS)
                                  ! TSTEP(1) = local output step
                                  ! TSTEP(2) = sciproc sync. step (chem)
                                  ! TSTEP(3) = twoway model time step w.r.t. wrf time
                                  !            step and wrf/cmaq call frequency

      INTEGER, ALLOCATABLE, SAVE :: ASTEP( : )
      INTEGER, SAVE :: NREPS    ! number of model time steps per output step
      INTEGER          ISTEP    ! current output time step number
      INTEGER          IREP     ! model step number within this output step
      INTEGER, SAVE :: JDATE    ! current model date, coded YYYYDDD
      INTEGER, SAVE :: JTIME    ! current model time, coded HHMMSS
      INTEGER          C, R, L, K, S, V     ! loop induction variables
      INTEGER          ALLOCSTAT
      INTEGER          NFILE, IFILE
      LOGICAL          EXST, OPD
      CHARACTER( 1000 ) :: CFILE
      CHARACTER(   16 ) :: ACT
      REAL( 8 )         :: CPU_TIME_START, CPU_TIME_FINISH
      REAL              :: REAL_TIME


      CHARACTER(  2 ) :: COLROW = 'CR'  ! col/row arg list order
      CHARACTER( 16 ) :: PNAME = 'DRIVER'
      CHARACTER( 96 ) :: XMSG = ' '

      REAL, SAVE, POINTER     :: CGRID( :,:,:,: )
      REAL, ALLOCATABLE, SAVE :: AGRID( :,:,:,: )
      REAL    DIVFAC      ! trapezoidal average factor

      LOGICAL, SAVE :: FIRST_RUN = .TRUE.  ! used for twoway model
      LOGICAL       :: WFLG = .TRUE.       ! turn on write subdmap in pio_init

      INTEGER, SAVE :: myNREPS = 0
      INTEGER       :: STATUS

#ifdef mpas

      integer :: io_mode

      INTEGER      SPC_STRT, SPC_FINI, J
      LOGICAL      LSTAT
      INTEGER      STAT                       ! Status reported by Aerosol Dist Checker

      INTEGER      LMODE    !Identifies the problematic mode from
                                !the BC Check routine
      REAL         AER_PAR( 2, N_MODE,5 )  !Modal parameter after the BC 
                                           !check (N, dg, sg)
                                           !      (N, M2, M3) -
                                           !      Before
                                           !      (N, M2, M3) -
                                           !      After
      REAL,ALLOCATABLE :: AECON( : )

      REAL( 8 ) :: BEGTIME     ! Wall-clock time (sec) at MPI initialization
      LOGICAL       :: L_WRITE_WARNING


#endif

      INTERFACE
         SUBROUTINE INITSCEN ( CGRID, TSTEP )
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( OUT )   :: TSTEP( 3 )
         END SUBROUTINE INITSCEN
#ifndef mpas
         SUBROUTINE ADVSTEP ( JDATE, JTIME, TSTEP, ASTEP, NREPS )
            INTEGER, INTENT( IN )    :: JDATE, JTIME
            INTEGER, INTENT( INOUT ) :: TSTEP( 3 )
            INTEGER, INTENT( OUT )   :: ASTEP( : )
            INTEGER, INTENT( OUT )   :: NREPS
         END SUBROUTINE ADVSTEP
         SUBROUTINE CKSUMMER ( PRNAME, CGRID, JDATE, JTIME )
            CHARACTER( * ), INTENT( IN ) :: PRNAME
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )    :: JDATE, JTIME
         END SUBROUTINE CKSUMMER
         SUBROUTINE PA_INIT ( CGRID, JDATE, JTIME, TSTEP )
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )    :: JDATE, JTIME, TSTEP( 3 )
         END SUBROUTINE PA_INIT
         SUBROUTINE WR_ACONC ( AGRID, JDATE, JTIME, TSTEP )
            REAL,    INTENT( IN )    :: AGRID( :,:,:,: )
            INTEGER, INTENT( IN )    :: JDATE, JTIME, TSTEP
         END SUBROUTINE WR_ACONC
         SUBROUTINE WR_CGRID ( CGRID, JDATE, JTIME, TSTEP )
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )    :: JDATE, JTIME, TSTEP
         END SUBROUTINE WR_CGRID
         SUBROUTINE PA_OUTPUT ( CGRID, JDATE, JTIME )
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( IN )    :: JDATE, JTIME
         END SUBROUTINE PA_OUTPUT
#endif

         SUBROUTINE SCIPROC ( CGRID, JDATE, JTIME, TSTEP, ASTEP )
            REAL, POINTER            :: CGRID( :,:,:,: )
            INTEGER, INTENT( INOUT ) :: JDATE, JTIME
            INTEGER, INTENT( IN )    :: TSTEP( 3 ), ASTEP( : )
         END SUBROUTINE SCIPROC
#ifdef mpas
         SUBROUTINE UNLOAD_CGRID ( CGRID )
            REAL, INTENT(IN)  :: CGRID( :,:,:,: )
         END SUBROUTINE UNLOAD_CGRID
#endif
      END INTERFACE

C-----------------------------------------------------------------------

      IF ( FIRST_RUN ) THEN

         TSTEP = 0
#ifdef mpas
         CALL INIT_ENV_VARS( 0, 0 )
#else
         STDATE     = MODEL_STDATE
         STTIME     = MODEL_STTIME
#endif

         TSTEP( 1 ) = MODEL_TSTEP

         IF (PRESENT (COUPLE_TSTEP)) THEN
            TSTEP( 3 ) = SEC2TIME( COUPLE_TSTEP )
            MPAS_TSTEP = TSTEP( 3 )
         END IF

         IF (PRESENT(NCOLS_IN)) THEN
            NCOLS = NCOLS_IN
            NROWS = 1
            NLAYS = NLAYS_IN
            TSTEP( 2 ) = SEC2TIME( COUPLE_TSTEP )
         END IF

#ifdef mpas
         CALL MPCOMM_INIT( NPROCS, MYPE, BEGTIME, LMODE )

         IO_PE_INCLUSIVE = .TRUE.

         call mpi_allreduce (ncols, ncols_gl, 1, mpi_int, mpi_sum, mpi_comm_world, status)

         call mio_init (NPROCS, 1, ncols_gl, nrows, logdev=logdev)

C Set CGRID mechanism
         IF ( .NOT. CGRID_SPCS_INIT() ) THEN
            XMSG = 'Error in CGRID_SPCS:CGRID_SPCS_INIT'
            call M3EXIT (PNAME, JDATE, JTIME, XMSG, 1)
         END IF

         CALL GET_ENV ( LAND_SCHEME, 'LAND_SCHEME', 'NLCD40', LOGDEV )

         ALLOCATE (CGRID ( NCOLS,NROWS,NLAYS,NSPCSD ), STAT = ALLOCSTAT)

         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'CGRID memory allocation failed'
            call M3EXIT (PNAME, JDATE, JTIME, XMSG, 1)
         END IF

C Set up horizontal domain, calculate processor-to-subdomain maps
C and define vertical layer structure (in module GRID_CONF)
         IF ( .NOT. GRID_INIT ( NPROCS, MYPE ) ) THEN
            XMSG = '*** Failure defining domain configuration'
            call M3EXIT (PNAME, JDATE, JTIME, XMSG, 1)
         END IF

#else

C Set up horizontal domain, calculate processor-to-subdomain maps
C and define vertical layer structure (in module GRID_CONF)
         IF ( .NOT. GRID_INIT ( NPROCS, MYPE ) ) THEN
            XMSG = '*** Failure defining domain configuration'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

#ifdef verbose_driver
         write( logdev,* ) ' MYPE -> NPROCS:   ', mype, nprocs
         write( logdev,* ) ' MYPE -> NPCOL:    ', mype, npcol
         write( logdev,* ) ' MYPE -> NPROW:    ', mype, nprow
         write( logdev,* ) ' MYPE -> MY_NCOLS: ', mype, ncols
         write( logdev,* ) ' MYPE -> MY_NROWS: ', mype, nrows
         write( logdev,* ) ' MYPE -> GL_NCOLS: ', mype, gl_ncols
         write( logdev,* ) ' MYPE -> GL_NROWS: ', mype, gl_nrows
         write( logdev,* ) ' MYPE -> NLAYS:    ', mype, nlays
         write( logdev,* ) ' MYPE -> NBNDY:    ', mype, nbndy
#endif

C Set CGRID mechanism
         IF ( .NOT. CGRID_SPCS_INIT() ) THEN
            XMSG = 'Error in CGRID_SPCS:CGRID_SPCS_INIT'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, 1 )
         END IF

        CALL MAP_AERO()

#ifdef verbose_driver
         write( logdev,* ) ' MYPE -> NSPCS:    ', mype, nspcsd
#endif

#ifdef parallel_io
         IF ( MOD( MYPE, NPCOL ) .EQ. 0 ) THEN
#else
         IF ( MYPE .EQ. 0 ) THEN
#endif
            IO_PE_INCLUSIVE = .TRUE.
         ELSE
            IO_PE_INCLUSIVE = .FALSE.
         END IF

#ifdef parallel
C Initialize PARIO
         IF ( .NOT. PIO_INIT( COLROW, GL_NCOLS, GL_NROWS, NLAYS, NTHIK,
     &                        NCOLS, NROWS, NPCOL, NPROW, NPROCS, MYPE,
     &                        wflg = WFLG, io_pe_inclusive = IO_PE_INCLUSIVE ) ) THEN
            XMSG = 'Failed to initialize parallel I/O library.'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

#endif
C Initialize stencil exchange
         CALL SUBST_SE_INIT( NPROCS, NPCOL, NPROW, GL_NCOLS, GL_NROWS, NLAYS,
     &                       NSPCSD, MYPE, MNDIS, MEDIS, MSDIS, MWDIS )


#ifdef verbose_driver
         write( logdev,* ) ' MYPE -> MNDIS:    ', mype, mndis
         write( logdev,* ) ' MYPE -> MEDIS:    ', mype, medis
         write( logdev,* ) ' MYPE -> MSDIS:    ', mype, msdis
         write( logdev,* ) ' MYPE -> MWDIS:    ', mype, mwdis
#endif

C Generate the process analysis data: load PA_DEFN module
         CALL PA_DATAGEN( )

C Abort if the number of output variables exceeds the maximum allowed
C by I/O-API
         IF ( NSPCSD .GT. MXVARS3 ) THEN
            WRITE( XMSG,'(5X, A, I5, A)' ) 'The number of variables,', NSPCSD,
     &      ' to be written to the State CGRID File'
            CALL LOG_MESSAGE( LOGDEV, XMSG )
            WRITE( XMSG,'(5X, A, I5)' ) 'exceeds the I/O-API limit:', MXVARS3
            CALL LOG_MESSAGE( LOGDEV, XMSG )
            XMSG = 'Recompile with an I/O-API lib having a larger MXVARS3'
            CALL LOG_MESSAGE( LOGDEV, XMSG )
            CALL M3EXIT( PNAME, JDATE, JTIME, ' ', XSTAT1 )
         END IF

C Initialize PCGRID
         IF ( .NOT. PCGRID_INIT () ) THEN
            XMSG = 'Failure defining horizontal domain'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT2  )
         END IF
      
         CGRID => PCGRID( 1:NCOLS,1:NROWS,:,: )   ! required for PinG

C Initalize CONC definitions (in STD_CONC F90 module)
         CALL CONC_DEFN ()

C Get avg CONC definitions, species and layer pointers (in AVG_CONC F90 module)
         CALL A_CONC_DEFN ()

C Miscellaneous Configuration Operations
         WRITE( LOGDEV, * )
         CALL LOG_HEADING( LOGDEV, "Configure Scenario" )

C Initialize optional derived vertical velocity writes to conc file
         IF ( .NOT. WVEL_INIT () ) THEN
            XMSG = 'Failure initializing derived vertical velocity writes'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT2  )
         END IF

#endif  ! end of mpas


C Initialize Global Arrays for Storing Chemical, Regional, Process,
C and Emission Stream Families
         call read_families

C Initiliaze IO Arrays and Open Files
#ifdef mpas
         call centralized_io_init (NCOLS_IN)
#else
         call centralized_io_init
#endif

C Initialize ELMO Arrays and Maps
         call map_elmo

C Initialize conc field: Copy IC's to CONC file as step 0
C Convention: the input file concentration units are always ppmV.

         CALL INITSCEN ( CGRID, TSTEP )
         JDATE = STDATE; JTIME = STTIME

#ifndef mpas
         CALL CKSUMMER ( 'INITSCEN', CGRID, JDATE, JTIME )

         IF ( LIPR .OR. LIRR ) CALL PA_INIT ( CGRID, JDATE, JTIME, TSTEP )

C Verify input file header consistency and run duration
!         CALL FLCHECK ( JDATE, JTIME, TSTEP( 1 ) )

         ALLOCATE ( AGRID( NCOLS,NROWS,A_NLYS,N_ASPCS ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'AGRID memory allocation failed'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

         ALLOCATE ( ASTEP( NLAYS ), STAT = ALLOCSTAT )
         IF ( ALLOCSTAT .NE. 0 ) THEN
            XMSG = 'ASTEP memory allocation failed'
            CALL M3EXIT ( PNAME, JDATE, JTIME, XMSG, XSTAT1 )
         END IF

#else
!       if (.not. lus_init (mminlu_mpas, lufrac_data(:,:,1)) ) then
!          CALL M3EXIT( 'DRIVER',JDATE,JTIME,'ERROR: Cannot initialize Land Use Category', 2)
!       end if

        if (ncd_64bit_offset) then
            io_mode = ior (nf90_noclobber, nf90_64bit_offset)
         else
            io_mode = nf90_noclobber
         end if

        call mio_setfile ('GR_EMIS_001')

        if (L_ELMO) then
           call mio_fcreate (CTM_ELMO_1, io_mode)
        end if

         call get_env (mpas_diag, 'mpas_diag', .false.)

         if (mpas_diag) then
            call mio_fcreate ('CTM_OUT', io_mode)
         end if


!       call mio_fcreate (CTM_DRY_DEP_1, io_mode)
!       call mio_fcreate (CTM_WET_DEP_1, io_mode)

        if ( depv_diag ) then
            call mio_fcreate (CTM_DEPV_DIAG, io_mode)
        end if

        if ( cld_diag ) then
            call mio_fcreate (CTM_WET_DEP_2, io_mode)
        end if

!       if (photdiag) then
!          call mio_fcreate (CTM_RJ_1, io_mode)
!          call mio_fcreate (CTM_RJ_2, io_mode)
!       end if

#endif

C Initialize Meteorology Structures
         CALL INIT_LSM( JDATE, JTIME )
#ifndef mpas
         CALL INIT_BIDI( )
#endif
         CALL INIT_MET( JDATE, JTIME )

         CALL GET_MET ( JDATE, JTIME, 0 )

         IF ( W_VEL ) CALL GET_WVEL( JDATE, JTIME ) ! If the user wants vertical velocity written to file, retrieve it.

         FIRST_RUN = .FALSE.

C Main processing loop:
         IF ( MYPE .EQ. 0 ) WRITE( OUTDEV, * )
         IF ( MYPE. EQ. 0 ) CALL LOG_HEADING( OUTDEV, "Time Integration" )

      END IF ! first_run

      MODEL_JDATE = JDATE
      MODEL_JTIME = JTIME

#ifdef mpas

      mpas_cmaq_last_step = LAST_STEP

      v = size(cgrid, 4)

      DO L = 1, NLAYS
         DO C = 1, NCOLS
            CGRID( C,1,L,1:N_GC_SPC ) = cmaq_species( c,1,l,1:N_GC_SPC )
            CGRID( C,1,L,N_GC_SPC+2:v ) = cmaq_species( c,1,l,N_GC_SPC+1:v-1 )
         END DO
      END DO


      ! If this run is not a restart, then check the initial conditions
      ! to make sure they are physically realistic. Check Aerosol Size 
      ! Distributions and Warn the User if They Are Not Robust.
      call get_env (NEW_START, 'NEW_START', .false.)
      IF ( NEW_START ) THEN
         ALLOCATE( AECON( N_AE_SPC ) )
         SPC_STRT = AE_STRT
         SPC_FINI = AE_STRT + N_AE_SPC - 1
         LSTAT    = .FALSE.
         DO L = 1, NLAYS
            DO R = 1, NROWS
               DO C = 1, NCOLS
                  AECON( 1:N_AE_SPC ) = CGRID( C,R,L,SPC_STRT:SPC_FINI )
                  CALL CHECK_AERO_ICBC( AECON, .FALSE., .TRUE., .FALSE., L_WRITE_WARNING, C, R, L)
                  CGRID( C,R,L,SPC_STRT:SPC_FINI ) = AECON( 1:N_AE_SPC )
                  IF ( STAT .GT. 0 ) THEN
                     LSTAT = .TRUE.
                  ENDIF
               END DO
            END DO
         END DO
    
         !Print warning if any aerosol ICs violated the size
         !distribution parameters
         IF ( LSTAT ) THEN
            WRITE( XMSG, '(A,A)' ),
     &         'Applying fix to aerosol Initial Conditions for aerosol',
     &         ' modes.'
            print *, trim(xmsg)
         END IF
      END IF
 
      NREPS = 1
#else
C Get synchronization and advection time steps, TSTEP(2), ASTEP(L) and NREPS
      CALL ADVSTEP ( JDATE, JTIME, TSTEP, ASTEP, NREPS )

      IF ( MOD( TIME2SEC( JTIME ), TIME2SEC( TSTEP( 1 ) ) ) .EQ. 0 ) THEN
         DO V = 1, N_ASPCS
            S = AVG_CONC_MAP( V )
            AGRID( :,:,:,V ) = CGRID( :,:,ACONC_BLEV:ACONC_ELEV,S )
         END DO

         IF ( W_VEL )
     &      AVG_WVEL( :,:,: ) = WVEL( :,:,ACONC_BLEV:ACONC_ELEV )
         IF ( L_ACONC_RH )
     &      AVG_RH( :,:,: ) = MET_DATA%RH( :,:,ACONC_BLEV:ACONC_ELEV)
         IF ( L_ACONC_TA )
     &      AVG_TA( :,:,: ) = MET_DATA%TA( :,:,ACONC_BLEV:ACONC_ELEV)
         IF ( L_ACONC_PRES )
     &      AVG_PRES( :,:,: ) = MET_DATA%PRES( :,:,ACONC_BLEV:ACONC_ELEV )
      END IF
#endif

C Compute ELMO Values at Beginning of Main Time Step
      IF ( L_ELMO ) THEN
        IF ( JDATE .EQ. STDATE .AND. JTIME .EQ. STTIME ) THEN

             ! Calculate all ELMO variables for both Instantaneous and
             ! Average parameters
             CALL ELMO_DRIVER( CGRID, JDATE, JTIME, TSTEP, INIT_TIME=.TRUE.)
             ! Print Instantaneous Values at first time step
             CALL WRITE_ELMO( JDATE, JTIME, TSTEP, INIT_TIME=.TRUE. )

        ELSE IF ( ELMO_NSTEP .LT. 1.0 ) THEN
             ! Calculate all ELMO Variables for averaging but do not output them
             CALL ELMO_DRIVER( CGRID, JDATE, JTIME, TSTEP, INIT_TIME=.FALSE. )
        END IF
      END IF

C Initialize Budget Output File and Concentration Array
      IF ( BUDGET_DIAG ) CALL BUDGET_INIT( CGRID, JDATE, JTIME, TSTEP )

C science process sequence:
         
      myNREPS = myNREPS + NREPS

      DO IREP = 1, NREPS

         CALL SCIPROC ( CGRID, JDATE, JTIME, TSTEP, ASTEP )

#ifndef mpas
C Use trapezoidal rule to time-average data

         DO V = 1, N_ASPCS
            S = AVG_CONC_MAP( V )
            AGRID( :,:,:,V ) = AGRID( :,:,:,V )
     &            + 2.0 * CGRID( :,:,ACONC_BLEV:ACONC_ELEV,S )
         END DO
         IF ( W_VEL )
     &      AVG_WVEL( :,:,: ) = AVG_WVEL + 2.0 * WVEL( :,:,ACONC_BLEV:ACONC_ELEV )
         IF ( L_ACONC_RH )
     &      AVG_RH( :,:,: ) = AVG_RH + 2.0 * MET_DATA%RH( :,:,ACONC_BLEV:ACONC_ELEV )
         IF ( L_ACONC_TA )
     &      AVG_TA( :,:,: ) = AVG_TA + 2.0 * MET_DATA%TA( :,:,ACONC_BLEV:ACONC_ELEV )
         IF ( L_ACONC_PRES )
     &      AVG_PRES( :,:,: ) = AVG_PRES + 2.0 * MET_DATA%PRES( :,:,ACONC_BLEV:ACONC_ELEV )

#endif
         ! OUTPUT DIAGNOSTIC INFORMATION
         IF ( L_ELMO ) CALL ELMO_DRIVER( CGRID, JDATE, JTIME, TSTEP, INIT_TIME=.FALSE. )

      END DO

#ifndef mpas
      IF ( MOD( TIME2SEC( JTIME ), TIME2SEC( TSTEP( 1 ) ) ) .EQ. 0 ) THEN
         DIVFAC = 0.5 / FLOAT( myNREPS )
         myNREPS = 0

         DO V = 1, N_ASPCS
            S = AVG_CONC_MAP( V )
            AGRID( :,:,:,V ) = DIVFAC * ( AGRID( :,:,:,V )
     &           - CGRID( :,:,ACONC_BLEV:ACONC_ELEV,S ) )
         END DO
         IF ( W_VEL )
     &         AVG_WVEL( :,:,: ) = DIVFAC * ( AVG_WVEL( :,:,: ) - WVEL( :,:,ACONC_BLEV:ACONC_ELEV ) )
         IF ( L_ACONC_RH )
     &         AVG_RH( :,:,: ) = DIVFAC * ( AVG_RH( :,:,: ) - MET_DATA%RH( :,:,ACONC_BLEV:ACONC_ELEV ) )
         IF ( L_ACONC_TA )
     &         AVG_TA( :,:,: ) = DIVFAC * ( AVG_TA - MET_DATA%TA( :,:,ACONC_BLEV:ACONC_ELEV ) )
         IF ( L_ACONC_PRES )
     &         AVG_PRES( :,:,: ) = DIVFAC * ( AVG_PRES - MET_DATA%PRES( :,:,ACONC_BLEV:ACONC_ELEV ) )

      END IF

      DO V = 1, N_CSPCS
         S = CONC_MAP( V )
         SGRID( :,:,:,V ) = CGRID( :,:,CONC_BLEV:CONC_ELEV,S )
      END DO

C write conc fields

      IF ( MOD( TIME2SEC( JTIME ), TIME2SEC( TSTEP( 1 ) ) ) .EQ. 0 ) THEN
#ifdef parallel
         CPU_TIME_START =  MPI_WTIME()
#else
         CALL CPU_TIME( REAL_TIME )
         CPU_TIME_START = REAL( REAL_TIME,8 )
#endif
         CALL WR_CONC ( JDATE, JTIME, TSTEP( 1 ) )
#ifdef parallel
         IF ( LVEXT ) CALL WR_VEXT ( CGRID, JDATE, JTIME, TSTEP( 1 ) )
#endif
         CALL WR_ACONC ( AGRID, JDATE, JTIME, TSTEP( 1 ) )
         IF ( L_ELMO ) CALL WRITE_ELMO( JDATE, JTIME, TSTEP, INIT_TIME=.FALSE. )

         IF ( LIPR .OR. LIRR ) CALL PA_OUTPUT ( CGRID, JDATE, JTIME )
         IF ( BUDGET_DIAG ) CALL WRITE_BUDGET ( CGRID, JDATE, JTIME, TSTEP )
         IF ( PRINT_PROC_TIME ) CALL TIMING_SPLIT ( CPU_TIME_START, 3 )
         
      END IF

#else
      CALL UNLOAD_CGRID (CGRID)
#endif

      IF ( LAST_STEP ) THEN
#ifdef mpas
         call mio_shutdown()
#else
C write CGRID state file for subsequent runs
         CALL WR_CGRID ( CGRID, JDATE, JTIME, TSTEP( 1 ) )

C Shut down IOAPI
         IF ( SHUT3() ) THEN
            WRITE( LOGDEV, * )
            CALL LOG_HEADING( LOGDEV, 'Program Completed Successfully' )
            WRITE( XMSG, '(A,A,A,I7,A,I6.6,A)' ) 'Date and time ',
     &             DT2STR( JDATE, JTIME ), ' (',JDATE,':',JTIME,')' 
            CALL LOG_MESSAGE( LOGDEV, XMSG ) 

            IF ( MYPE .EQ. 0 ) WRITE( OUTDEV, * )
            IF ( MYPE .EQ. 0 ) CALL LOG_HEADING( OUTDEV, 'Program Completed Successfully' )
            IF ( MYPE .EQ. 0 ) CALL LOG_MESSAGE( OUTDEV, XMSG )
         ELSE
            CALL LOG_MESSAGE( LOGDEV, ' *** FATAL ERROR shutting down Models-3 I/O *** ' )
         END IF
#endif
      END IF

      END SUBROUTINE CMAQ_DRIVER
