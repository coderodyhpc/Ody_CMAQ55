#!/bin/bash

# ==================================================================
#> Runtime Environment Options
# ==================================================================

 export CMAQ_HOME=/home/ubuntu/CMAQ
 export CMAQ_REPO=/home/ubuntu/CMAQ
 export CMAQ_DATA=/home/ubuntu/CMAQ/data_custom

#> Set the compiler option
 export compiler=gcc
 export Vrsn=14.2
 export compilerString=gcc14

#> Set General Parameters for Configuring the Simulation
 VRSN=v55                       #> Code Version
 APPL=exemplum
 ICTYPE=profile

#> Set the working directory:
 BLD=${CMAQ_HOME}/PREP/icon/scripts/BLD_ICON_${VRSN}_${compilerString}
 EXEC=ICON_${VRSN}.exe  
 cat $BLD/ICON_${VRSN}.cfg; echo " "; set echo

#> Horizontal grid definition 
 export GRID_NAME=exem
 export GRIDDESC=/home/ubuntu/CMAQ/data_custom/exemplum/GRIDDESC
 export IOAPI_ISPH=20                     #> GCTP spheroid, use 20 for WRF-based modeling

#> I/O Controls
 export IOAPI_LOG_WRITE=F     #> turn on excess WRITE3 logging [ options: T | F ]
 export IOAPI_OFFSET_64=YES   #> support large timestep records (>2GB/timestep record) [ options: YES | NO ]
 export EXECUTION_ID=$EXEC    #> define the model execution id

# =====================================================================
#> ICON Configuration Options
#
# ICON can be run in one of two modes:                                     
#     1) regrids CMAQ CTM concentration files (IC type = regrid)     
#     2) use default profile inputs (IC type = profile)
# =====================================================================

 export ICON_TYPE=` echo $ICTYPE | tr "[A-Z]" "[a-z]" ` 

# =====================================================================
#> Input/Output Directories
# =====================================================================

 OUTDIR=$CMAQ_HOME/data_custom/icon       #> output file directory

# =====================================================================
#> Input Files
#  
#  Regrid mode (IC = regrid) (includes nested domains, windowed domains,
#                             or general regridded domains)
#     CTM_CONC_1 = the CTM concentration file for the coarse domain          
#     MET_CRO_3D_CRS = the MET_CRO_3D met file for the coarse domain
#     MET_CRO_3D_FIN = the MET_CRO_3D met file for the target nested domain 
#                                                                            
#  Profile Mode (IC = profile)
#     IC_PROFILE = static/default IC profiles 
#     MET_CRO_3D_FIN = the MET_CRO_3D met file for the target domain 
#
# NOTE: SDATE (yyyyddd) and STIME (hhmmss) are only relevant to the
#       regrid mode and if they are not set, these variables will 
#       be set from the input MET_CRO_3D_FIN file
# =====================================================================
#> Output File
#     INIT_CONC_1 = gridded IC file for target domain
# =====================================================================

    DATE=2023-01-15
    YYYYJJJ=`date -ud "${DATE}" +%Y%j`        #> Convert YYYY-MM-DD to YYYYJJJ
    YYMMDD=`date -ud "${DATE}" +%y%m%d`       #> Convert YYYY-MM-DD to YYMMDD
    YYYYMMDD=`date -ud "${DATE}" +%Y%m%d`     #> Convert YYYY-MM-DD to YYYYMMDD
#   export SDATE           ${YYYYJJJ}
#   export STIME           000000

 export MET_CRO_3D_FIN=/home/ubuntu/CMAQ/data_custom/exemplum/METCRO3D_exemplum.nc
 export INIT_CONC_1=/home/ubuntu/CMAQ/data_custom/exemplum/INIT_CONC_1
 if [ $ICON_TYPE == regrid ]
 then
    export CTM_CONC_1=/home/ubuntu/CMAQ/data_custom/exemplum/CTM_CONC_1
    export MET_CRO_3D_CRS=/home/ubuntu/CMAQ/data_custom/exemplum/METCRO3D_exemplum.nc
 fi

 if [ $ICON_TYPE == profile ]
 then
    export IC_PROFILE=/home/ubuntu/CMAQ/PREP/icon/src/profile/avprofile_cb6r3m_ae7_kmtbr_hemi2016_v53beta2_m3dry_col051_row068.csv
 fi
 
#>- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 if [ ! -d "$OUTDIR" ]
 then
   mkdir -p $OUTDIR
 fi


#> Executable call:
 time $BLD/$EXEC

