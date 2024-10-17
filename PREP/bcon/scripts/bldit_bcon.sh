#!/bin/bash

#> Critical Folder Locations
 export CMAQ_HOME=/home/ubuntu/CMAQ
 export CMAQ_REPO=/home/ubuntu/CMAQ

#> Set the compiler option
 export compiler=gcc
 export Vrsn=14.2
 export compilerVrsn=14

# =======================================================================
#> Begin User Input Section
# =======================================================================

#> Source Code Locations
 BCON_SRC=${CMAQ_REPO}/PREP/bcon/src #> location of the BCON source code
 export REPOROOT=$BCON_SRC

#> Working directory and Version IDs
 VRSN=v54                     #> Code Version
 EXEC=BCON_${VRSN}.exe        #> executable name for this application
 CFG=BCON_${VRSN}.cfg         #> BLDMAKE configuration file name

#> Controls for managing the source code and MPI compilation
# CopySrcTree                 #> copy the source files and directory tree into the build directory
# Opt=verbose                 #> show requested commands as they are executed
# MakeFileOnly                #> uncomment to build a Makefile, but do not compile; 
                              #>   comment out to compile the model (default if not set)
# Debug_BCON                  #> uncomment to compile BCON with debug option equal to TRUE
                              #>   comment out to use standard, optimized compile process

 export compilerString=${compiler}
 export compilerString=${compiler}${compilerVrsn}

#>==============================================================================
#> BCON Science Modules
#>
#> NOTE:  BC type is now a runtime option.  All BC types are included at
#>        compile time
#>==============================================================================

 ModCommon=common

 ModM3conc=m3conc

 ModProfile=profile

#>#>#>#>#>#>#>#>#>#>#>#>#>#> End User Input Section #<#<#<#<#<#<#<#<#<#<#<#<#<#
#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#>#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#<#

#> Set full path of Fortran 90 compiler
 FC=/opt/atrium/openmpi/bin/mpifort
 FP=/opt/atrium/openmpi/bin/mpicc
 export BLDER=${CMAQ_HOME}/UTIL/bldmake/bldmake_${compilerString}.exe   #> name of model builder executable

#> Set compiler flags
 xLib_Base=${CMAQ_LIB}
 xLib_1=ioapi/lib
 xLib_2=ioapi/include_files
 xLib_4=ioapi/lib
 FSTD=""
 DBG="-Wall -O0 -g -fcheck=all -ffpe-trap=invalid,zero,overflow -fbacktrace"
 F_FLAGS="-ffixed-form -ffixed-line-length-132 -finit-character=32 -O3 -march=native -funroll-loops -ftree-vectorize -ftree-loop-if-convert -fallow-argument-mismatch -fallow-invalid-boz"
 F90_FLAGS="-ffixed-form -ffixed-line-length-132 -finit-character=32 -O3 -march=native -funroll-loops -ftree-vectorize -ftree-loop-if-convert -fallow-argument-mismatch -fallow-invalid-boz"
 CPP_FLAGS=""
 LINK_FLAGS=""

 LIB1="$ioapi_lib"
 LIB2="$netcdf_lib $extra_lib"
 LIB3="$netcdff_lib"

#============================================================================================
#> Implement User Input
#============================================================================================


#> Set and create the "BLD" directory for checking out and compiling 
#> source code. Move current directory to that build directory.
 Bld=$CMAQ_HOME/PREP/bcon/scripts/BLD_BCON_${VRSN}_${compilerString}

 echo "Bld IS $Bld"

 if [ ! -e "$Bld" ]
 then
    mkdir $Bld
 fi
 cd $Bld

#> make the config file

 Cfile=$CFG.bld
 quote='"'

 echo                                                               > $Cfile
 echo "model       $EXEC;"                                         >> $Cfile
 echo                                                              >> $Cfile
 echo "repo        $BCON_SRC;"                                     >> $Cfile
 echo                                                              >> $Cfile
 echo "lib_base    $xLib_Base;"                                    >> $Cfile
 echo                                                              >> $Cfile
 echo "lib_1       $xLib_1;"                                       >> $Cfile
 echo                                                              >> $Cfile
 echo "lib_2       $xLib_2;"                                       >> $Cfile
 echo                                                              >> $Cfile
 echo "lib_4       $xLib_4;"                                       >> $Cfile
 echo                                                              >> $Cfile
 text="$quote$CPP_FLAGS$quote;"
 echo "cpp_flags   $text"                                          >> $Cfile
 echo                                                              >> $Cfile
 echo "f_compiler  $FC;"                                           >> $Cfile
 echo                                                              >> $Cfile
 echo "fstd        $quote$FSTD$quote;"                             >> $Cfile
 echo                                                              >> $Cfile
 echo "dbg         $quote$DBG$quote;"                              >> $Cfile
 echo                                                              >> $Cfile
 echo "f_flags     $quote$F_FLAGS$quote;"                          >> $Cfile
 echo                                                              >> $Cfile
 echo "f90_flags   $quote$F90_FLAGS$quote;"                        >> $Cfile
 echo                                                              >> $Cfile
 echo "link_flags  $quote$LINK_FLAGS$quote;"                       >> $Cfile
 echo                                                              >> $Cfile
 echo "ioapi       $quote$LIB1$quote;"                             >> $Cfile
 echo                                                              >> $Cfile
 echo "netcdf      $quote$LIB2$quote;"                             >> $Cfile
 echo                                                              >> $Cfile
 echo "netcdff      $quote$LIB3$quote;"                            >> $Cfile
 echo                                                              >> $Cfile

 echo "// project repository location: ${BCON_SRC}"                >> $Cfile
 echo                                                              >> $Cfile

 text="common"
 echo "// required" $text                                          >> $Cfile
 echo "Module ${ModCommon};"                                       >> $Cfile
 echo                                                              >> $Cfile

 text="m3conc"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModM3conc};"                                       >> $Cfile
 echo                                                              >> $Cfile

 text="profile"
 echo "// options are" $text                                       >> $Cfile
 echo "Module ${ModProfile};"                                      >> $Cfile
 echo                                                              >> $Cfile

 if [ ModMisc==true ]
 then
    echo "Module ${ModMisc};"                                      >> $Cfile
    echo                                                           >> $Cfile
 fi

# ============================================================================
#> Create Makefile and Model Executable
# ============================================================================

# unalias mv rm

#> Recompile BLDMAKE from source if requested or if it does not exist
# cd ${CMAQ_REPO}/UTIL/bldmake/scripts
# ./bldit_bldmake.sh
 Blder="/home/ubuntu/CMAQ/UTIL/bldmake/bldmake_gcc.exe -serial -verbose"

#> Relocate to the BLD_* directory 
 cd $Bld

echo "HAVE ARRIVED AT BREAK 1"

# Set BCON debug flags if true
 if [ Debug_BCON==true ]
 then
    Blder="${Blder} -debug_cctm"
 fi

#> Run BLDMAKE Utility
# if [ MakeFileOnly==true ]
# then
#    if [ CopySrc==true ]
#    then
#       $Blder -makefo $Cfile
#    else
       $Blder -makefo -git_local $Cfile   # $Cfile = ${CFG}
#     # totalview -a $Blder -makefo $Cfile
#    fi
# else   # also compile the model
#    if [ CopySrc==true ]
#    then
#       $Blder $Cfile
#    else
#       $Blder -git_local $Cfile
#    fi
# fi

#> Rename Makefile to specify compiler option and link back to Makefile
 mv Makefile Makefile.$compilerString
 if [ -e Makefile.$compilerString ] && [ -e Makefile ] 
 then
   rm Makefile
 fi
 ln -s Makefile.$compilerString Makefile

#> Alert user of error in BLDMAKE if it ocurred
 if [ $status != 0 ]
 then
    echo "   *** failure in $Blder ***"
    exit 1
 fi

#> Preserve old Config file, if it exists, before moving new one to 
#> build directory.
 if [ -e "$Bld/${CFG}" ]
 then
    echo "   >>> previous ${CFG} exists, re-naming to ${CFG}.old <<<"
#    unalias mv
    mv $Bld/${CFG} $Bld/${CFG}.old
 fi
 mv ${CFG}.bld $Bld/${CFG}

 exit
