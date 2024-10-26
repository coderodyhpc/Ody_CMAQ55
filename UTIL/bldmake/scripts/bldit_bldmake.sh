#!/bin/bash

# ==================== Build Script for BLDMAKE ===================== #
# Usage: bldit_bldmake.sh                                            #
# Requirements: I/O API & netCDF libraries; a Fortran compiler        #
#                                                                     #
# To report problems or request help with this script/program:        #
#             http://www.cmascenter.org                               #
# =================================================================== #

#> Recompile BLDMAKE from source if requested or if it does not exist
# if [ CompileBLDMAKE ] && [ ! -f $BLDER ]
# then
#     #> Set BLDER to Default Path
     BLDEXE="bldmake_${compilerString}.exe"
     BLDDIR="$CMAQ_HOME/UTIL/bldmake"
     export BLDER="${BLDDIR}/${BLDEXE}"

#     #> Make bldmake directory if it does not exist
     if [ ! -d $BLDDIR ] 
     then 
       mkdir -pv $BLDDIR
     fi

#     #> Compile BLDMAKE source code
     BLDSRCDIR="$CMAQ_REPO/UTIL/bldmake/src"
     flist="\
          cfg_module\
          bldmake\
          parser\
          utils"
#     #> Clean Destination BLDMAKE directory
     cd $BLDDIR
     rm *.o *.mod $BLDER
  
#     #> Create Object Files
     cd $BLDSRCDIR
     for file in $flist
     do
        "$myFC" -c $myFFLAGS "$file.f" -o "$BLDDIR/$file.o"
     done
  
#     #> Compile BLDMAKE
     cd $BLDDIR
     $myFC *.o -o $BLDEXE
     if [ ! -e $BLDEXE ]
     then
         echo " "; echo " ***ERROR*** BLDMAKE Compile failed"; echo " "
###         exit 1
     fi
     chmod 755 $BLDEXE
     echo " "; echo " Finish building $BLDEXE "
   # fi
