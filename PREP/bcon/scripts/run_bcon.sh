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

#> Set General Parameters for Configuring the Simulation
 VRSN=v55                       #> Code Version
 APPL=exemplum
 BCTYPE=profile

#> Set the working directory:
 BLD=/home/ubuntu/CMAQ/PREP/bcon/scripts/BLD_BCON_v54_gcc12
 EXEC=BCON_${VRSN}.exe  

#> Horizontal grid definition 
 export GRID_NAME=exem
 export GRIDDESC=/home/ubuntu/CMAQ/data_custom/exemplum/GRIDDESC
 export IOAPI_ISPH=20                     #> GCTP spheroid, use 20 for WRF-based modeling

#> I/O Controls
 export IOAPI_LOG_WRITE=F     #> turn on excess WRITE3 logging [ options: T | F ]
 export IOAPI_OFFSET_64=YES   #> support large timestep records (>2GB/timestep record) [ options: YES | NO ]
 export EXECUTION_ID=$EXEC    #> define the model execution id

# =====================================================================
#> BCON Configuration Options
#
# BCON can be run in one of two modes:                                     
#     1) regrids CMAQ CTM concentration files (BC type = regrid)     
#     2) use default profile inputs (BC type = profile)
# =====================================================================

 export BCON_TYPE=` echo $BCTYPE | tr "[A-Z]" "[a-z]" `

# =====================================================================
#> Input/Output Directories
# =====================================================================

 OUTDIR=$CMAQ_HOME/data_custom/bcon       #> output file directory

# =====================================================================
#> Input Files
#  
#  Regrid mode (BC = regrid) (includes nested domains, windowed domains,
#                             or general regridded domains)
#     CTM_CONC_1 = the CTM concentration file for the coarse domain          
#     MET_CRO_3D_CRS = the MET_CRO_3D met file for the coarse domain
#     MET_BDY_3D_FIN = the MET_BDY_3D met file for the target nested domain
#                                                                            
#  Profile mode (BC type = profile)
#     BC_PROFILE = static/default BC profiles 
#     MET_BDY_3D_FIN = the MET_BDY_3D met file for the target domain 
#
# NOTE: SDATE (yyyyddd), STIME (hhmmss) and RUNLEN (hhmmss) are only 
#       relevant to the regrid mode and if they are not set,  
#       these variables will be set from the input MET_BDY_3D_FIN file
# =====================================================================
#> Output File
#     BNDY_CONC_1 = gridded BC file for target domain
# =====================================================================
 
    DATE="2022-12-30"
    YYYYJJJ=`date -ud "${DATE}" +%Y%j`   #> Convert YYYY-MM-DD to YYYYJJJ
    YYMMDD=`date -ud "${DATE}" +%y%m%d` #> Convert YYYY-MM-DD to YYMMDD
    YYYYMMDD=`date -ud "${DATE}" +%Y%m%d` #> Convert YYYY-MM-DD to YYYYMMDD
#   export SDATE=2023-01-15
#   export STIME=000000
#   export RUNLEN=240000
 export MET_BDY_3D_FIN=/home/ubuntu/CMAQ/data_custom/exemplum/METBDY3D_exemplum.nc
 export BNDY_CONC_1=/home/ubuntu/CMAQ/data_custom/exemplum/BNDY_CONC_1
 if [ $BCON_TYPE == regrid ]
 then 
    export CTM_CONC_1=/home/ubuntu/CMAQ/data_custom/exemplum/CTM_CONC_1
    export MET_CRO_3D_CRS=/home/ubuntu/CMAQ/data_custom/exemplum/METCRO3D_exemplum.nc
 fi

 if [ $BCON_TYPE == profile ]
 then
    export BC_PROFILE=/home/ubuntu/CMAQ/PREP/bcon/src/profile/avprofile_cb6r3m_ae7_kmtbr_hemi2016_v53beta2_m3dry_col051_row068.csv
 fi

# =====================================================================
#> Output File
# =====================================================================
 
#>- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 if [ ! -d "$OUTDIR" ]
 then
   mkdir -p $OUTDIR
 fi 


#> Executable call:
 time $BLD/$EXEC

