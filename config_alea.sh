#!/bin/bash

#> Critical Folder Locations
 export CMAQ_HOME=/home/ubuntu/CMAQ
 export CMAQ_REPO=/home/ubuntu/CMAQ
 export CMAQ_DATA=$CMAQ_HOME/data
 [ ! -d $CMAQ_DATA ] && mkdir -p $CMAQ_DATA

 cd $CMAQ_HOME

#===============================================================================
#> architecture & compiler specific settings
#===============================================================================

#> Set the compiler option
 export compiler=gcc
 export Vrsn=14.2
 echo "Compiler is set to $compiler"


#> Compiler flags and settings
 case $compiler in

#>  NVHPC fortran compiler.............................................
    nvhpc)

        #> I/O API, netCDF, and MPI library locations
        export IOAPI_INCL_DIR=iopai_inc_pgi     #> I/O API include header files
        export IOAPI_LIB_DIR=ioapi_lib_pgi      #> I/O API libraries
        export NETCDF_LIB_DIR=netcdf_lib_pgi    #> netCDF C directory path
        export NETCDF_INCL_DIR=netcdf_inc_pgi   #> netCDF C directory path
        export NETCDFF_LIB_DIR=netcdff_lib_pgi  #> netCDF Fortran directory path
        export NETCDFF_INCL_DIR=netcdff_inc_pgi #> netCDF Fortran directory path
        export MPI_LIB_DIR=mpi_lib_pgi          #> MPI directory path

        #> Compiler Aliases and Flags
        setenv myFC mpifort
        setenv myCC pgcc
        setenv myLINK_FLAG # "-mp" openMP not supported w/ CMAQ
        setenv myFSTD "-O3"
        setenv myDBG  "-O0 -g -Mbounds -Mchkptr -traceback -Ktrap=fp"
        setenv myFFLAGS "-Mfixed -Mextend -mcmodel=medium -tp px"
        setenv myFRFLAGS "-Mfree -Mextend -mcmodel=medium -tp px"
        setenv myCFLAGS "-O2"
        #setenv extra_lib "-lextra"
        #setenv mpi_lib "-lmpi"   #> -lmpich for mvapich or -lmpi for openmpi
        setenv extra_lib ""
        setenv mpi_lib ""   #> -lmpich for mvapich or -lmpi for openmpi

        ;;

#>  gfortran compiler............................................................
    gcc)

        export WRF_ARCH=34
        #> I/O API, netCDF, and MPI library locations
        export IOAPI_INCL_DIR=/opt/atrium/ioapi-3.2/Linux2_aarch64gfort14   #> I/O API include header files
        export IOAPI_LIB_DIR=/opt/atrium/ioapi-3.2/Linux2_aarch64gfort14   #> I/O API libraries
        export NETCDF_LIB_DIR=/opt/atrium/netcdf/lib                     #> netCDF C directory path
        export NETCDF_INCL_DIR=/opt/atrium/netcdf/include                 #> netCDF C directory path
        export NETCDFF_LIB_DIR=/opt/atrium/netcdf/lib                     #> netCDF Fortran directory path
        export NETCDFF_INCL_DIR=/opt/atrium/netcdf/include                 #> netCDF Fortran directory path
        export MPI_LIB_DIR=/opt/atrium/openmpi/lib                    #> MPI directory path

        echo "MPI $MPI_LIB_DIR "

        #> Compiler Aliases and Flags
        #> set the compiler flag -fopt-info-missed to generate a missed optimization report in the bldit logfile
        export myFC=/opt/atrium/openmpi/bin/mpifort
        export myCC=/opt/atrium/openmpi/bin/mpicc
        export myFSTD=""
        export myDBG="-Wall -O0 -g -fcheck=all -ffpe-trap=invalid,zero,overflow -fbacktrace"
        export myFFLAGS="-ffixed-form -ffixed-line-length-132 -finit-character=32 -O3 -mcpu=neoverse-v2 -fallow-argument-mismatch -fallow-invalid-boz"
        export myFRFLAGS="-ffree-form -ffree-line-length-none -finit-character=32 -O3 -mcpu=neoverse-v2 -fallow-argument-mismatch -fallow-invalid-boz"
        export myCFLAGS="-O2"
#        export myLINK_FLAG= # "-fopenmp" openMP not supported w/ CMAQ
        export extra_lib=""
#        #export mpi_lib="-lmpi_mpifh"   #> -lmpich for mvapich or -lmpi for openmpi
        export mpi_lib="-lmpi"   #> -lmpich for mvapich or -lmpi for openmpi

        echo "myFC $myFC "
        echo "myFFLAGS $myFFLAGS "
        ;;

    *)
        echo "*** Compiler $compiler not found"
        exit
        ;;
 esac

#> Apply Specific Module and Library Location Settings for those working inside EPA
 # source /work/MOD3DEV/cmaq_common/cmaq_env.csh  #>>> UNCOMMENT if at EPA

#> Add The Complier Version Number to the Compiler String if it's not empty
 export compilerString=${compiler}
        echo "Compiler string $compilerString"
# if [$compilerVrsn != "Empty"] then
    export compilerString=${compiler}${compilerVrsn}
# endif
        echo "Compiler string $compilerString"

#===============================================================================

#> I/O API, netCDF, and MPI libraries
 export netcdf_lib="-lnetcdf"  #> -lnetcdff -lnetcdf for netCDF v4.2.0 and later
 export netcdff_lib="-lnetcdff"
 export ioapi_lib="-lioapi"
 export pnetcdf_lib="-lpnetcdf"

#> Query System Info and Current Working Directory
 export system="`uname -m`"
 export bld_os="`uname -s``uname -r | cut -d. -f1`"
 export lib_basedir=$CMAQ_HOME/lib

#> Generate Library Locations
 export CMAQ_LIB=${lib_basedir}/${system}/${compilerString}
 export MPI_DIR=$CMAQ_LIB/mpi
 export NETCDF_DIR=$CMAQ_LIB/netcdf
 export NETCDFF_DIR=$CMAQ_LIB/netcdff
 export PNETCDF_DIR=$CMAQ_LIB/pnetcdf
 export IOAPI_DIR=$CMAQ_LIB/ioapi

 echo "Cmaq_lib is set to $CMAQ_LIB"
 echo "MPI_DIR is set to $MPI_DIR"
 echo "IOAPI_DIR is set to $IOAPI_DIR"
 echo "NETCDF_DIR is set to $NETCDF_DIR"
 echo "NETCDFF_DIR is set to $NETCDFF_DIR"

#> Create Symbolic Links to Libraries
 [ ! -d $CMAQ_LIB ] && mkdir -p $CMAQ_LIB
 if [ -e $MPI_DIR ]
 then
    rm -rf $MPI_DIR
#    ln -s $MPI_LIB_DIR $MPI_DIR
    mkdir $MPI_DIR
    ln -s $MPI_LIB_DIR $MPI_DIR/lib
    ln -s $MPI_INCL_DIR $MPI_DIR/include
 fi
 [ ! -d $NETCDF_DIR ] && mkdir -p $NETCDF_DIR
 [ ! -e $NETCDF_DIR/lib ] && ln -sfn $NETCDF_LIB_DIR $NETCDF_DIR/lib
 [ ! -e $NETCDF_DIR/include ] && ln -sfn $NETCDF_INCL_DIR $NETCDF_DIR/include
 [ ! -d $NETCDFF_DIR ] && mkdir -p $NETCDFF_DIR
 [ ! -e $NETCDFF_DIR/lib ] && ln -sfn $NETCDFF_LIB_DIR $NETCDFF_DIR/lib
 [ ! -e $NETCDFF_DIR/include ] && ln -sfn $NETCDFF_INCL_DIR $NETCDFF_DIR/include
 if [ ! -d $IOAPI_DIR ] 
 then
    mkdir $IOAPI_DIR
    ln -sfn $IOAPI_INCL_DIR $IOAPI_DIR/include_files
    ln -sfn $IOAPI_LIB_DIR  $IOAPI_DIR/lib
 fi

#> Check for netcdf and I/O API libs/includes, error if they don't exist
 if [ ! -e $NETCDF_DIR/lib/libnetcdf.a ] 
 then
    echo "ERROR: $NETCDF_DIR/lib/libnetcdf.a does not exist in your CMAQ_LIB directory!!! Check your installation before proceeding with CMAQ build."
###    stop
 fi
 if [ ! -e $NETCDFF_DIR/lib/libnetcdff.a ] 
 then
    echo "ERROR: $NETCDFF_DIR/lib/libnetcdff.a does not exist in your CMAQ_LIB directory!!! Check your installation before proceeding with CMAQ build."
#    exit
 fi
 if [ ! -e $IOAPI_DIR/lib/libioapi.a ] 
 then
    echo "ERROR: $IOAPI_DIR/lib/libioapi.a does not exist in your CMAQ_LIB directory!!! Check your installation before proceeding with CMAQ build."
#    exit
 fi
 if [ ! -e $IOAPI_DIR/lib/m3utilio.mod ] 
 then
    echo "ERROR: $IOAPI_MOD_DIR/m3utilio.mod does not exist in your CMAQ_LIB directory!!! Check your installation before proceeding with CMAQ build."
#    exit
 fi

##> Set executable id
 export EXEC_ID=${bld_os}_${system}${compilerString}
 echo "EXEC_ID $EXEC_ID"
