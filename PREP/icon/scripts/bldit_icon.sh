#!/bin/bash

#> Critical Folder Locations
 export CMAQ_HOME=/home/ubuntu/CMAQ
 export CMAQ_REPO=/home/ubuntu/CMAQ

#> Set the compiler option
 export compiler=gcc
 export Vrsn=14.2
 export compilerVrsn=14
 echo "Compiler is set to $compiler"


# =======================================================================
#> Begin User Input Section
# =======================================================================

#> Source Code Locations
 ICON_SRC=${CMAQ_REPO}/PREP/icon/src #> location of the ICON source code
 export REPOROOT=$ICON_SRC

#> Working directory and Version IDs
 VRSN=v54                     #> Code Version
 EXEC=ICON_${VRSN}.exe        #> executable name for this application
 CFG=ICON_${VRSN}.cfg         #> BLDMAKE configuration file name

#> Controls for managing the source code and MPI compilation
# CompileBLDMAKE                 #> Recompile the BLDMAKE utility from source
#                                #>   comment out to use an existing BLDMAKE executable
# CopySrc                        #> copy the source files into the BLD directory
#set CopySrcTree                 #> copy the source files and directory tree into the build directory
#set Opt = verbose               #> show requested commands as they are executed
#set MakeFileOnly                #> uncomment to build a Makefile, but do not compile; 
                                 #>   comment out to compile the model (default if not set)
#set Debug_ICON                  #> uncomment to compile ICON with debug option equal to TRUE
                                 #>   comment out to use standard, optimized compile process

 export compilerString=${compiler}
 export compilerString=${compiler}${compilerVrsn}

#>==============================================================================
#> ICON Science Modules
#>
#> NOTE:  IC type is now a runtime option.  All IC types are included at
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

#> Check for CMAQ_REPO and CMAQ_LIB settings:
 if [ ! -e $CMAQ_REPO ] || [ ! -e $CMAQ_LIB ]
 then
    echo "   $CMAQ_REPO or $CMAQ_LIB directory not found"
###    exit 1
 fi
 echo "    Model repository base path: $CMAQ_REPO"
 echo "                  library path: $CMAQ_LIB"

#> If $CMAQ_MODEL is not set, default to $CMAQ_REPO
### if [ CMAQ_MODEL == true ]
### then
###    echo "         Model repository path: $CMAQ_MODEL"
### else
 Blder="/home/ubuntu/CMAQ/UTIL/bldmake/bldmake_gcc.exe -serial -verbose"

 Bld=$CMAQ_HOME/PREP/icon/scripts/BLD_ICON_${VRSN}_${compilerString}
 echo "Bld IS $Bld"

 if [ ! -e "$Bld" ]
 then
    mkdir $Bld
 fi
 cd $Bld

#> make the config file

 Cfile=${CFG}.bld
 quote='"'

 echo                                                               > $Cfile
 echo "model       $EXEC;"                                         >> $Cfile
 echo                                                              >> $Cfile
 echo "repo        $ICON_SRC;"                                     >> $Cfile
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


 echo "// project repository location: ${ICON_SRC}"                >> $Cfile
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

echo "Bld $Bld"
echo "Blder $Blder"

#> Relocate to the BLD_* directory 
cd $Bld


#> Run BLDMAKE Utility
$Blder -makefo -git_local $Cfile   # $Cfile = ${CFG}

#> Rename Makefile to specify compiler option and link back to Makefile
 mv Makefile Makefile.$compilerString
 if [ -e Makefile.$compilerString ] && [ -e Makefile ]
 then
   rm Makefile
 fi
 ln -s Makefile.$compilerString Makefile
 

 mv ${CFG}.bld $Bld/${CFG}

 exit

