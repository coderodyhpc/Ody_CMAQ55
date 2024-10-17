#!/bin/bash

# Definition of main subdirectories
 export CMAQ_HOME=/home/ubuntu/CMAQ
 export CMAQ_REPO=/home/ubuntu/CMAQ
 export CMAQ_DATA=$CMAQ_HOME/data_custom

# Definition of parameters
 APPL=example
 CoordName=coord_example     # 16-character maximum
 GridName=ex_12k                     # 16-character maximum

# Definition of subdirectories holding the data
 DataPath=/home/ubuntu/WRF-4.6/test/em_real
 InMetDir=$DataPath
 InGeoDir=/home/ubuntu/PREPRO/WPS
 OutDir=$CMAQ_DATA/$APPL
 ProgDir=$CMAQ_HOME/PREP/mcip/src
 WorkDir=$DataPath/mcip/$GridName

 InMetFiles="/home/ubuntu/WRF-4.6/test/em_real/wrfout_d01_2022-12-29_18_00_00"

 IfGeo="T"
 InGeoFile=$InGeoDir/geo_em.d01.nc

 LPV=0
 LWOUT=0
 LUVBOUT=1

 MCIP_START=2022-12-30-00:00:00.0000  # [UTC]
 MCIP_END=2022-12-31-00:00:00.0000  # [UTC]

 INTVL=45 # [min]

 IOFORM=1

#-----------------------------------------------------------------------
# Set number of meteorology "boundary" points to remove on each of four
# horizontal sides of MCIP domain.  This affects the output MCIP domain
# dimensions by reducing meteorology domain by 2*BTRIM + 2*NTHIK + 1,
# where NTHIK is the lateral boundary thickness (in BDY files), and the
# extra point reflects conversion from grid points (dot points) to grid
# cells (cross points).  Setting BTRIM = 0 will use maximum of input
# meteorology.  To remove MM5 lateral boundaries, set BTRIM = 5.
#
# *** If windowing a specific subset domain of input meteorology, set
#     BTRIM = -1, and BTRIM will be ignored in favor of specific window
#     information in X0, Y0, NCOLS, and NROWS.
#-----------------------------------------------------------------------

 BTRIM=2

#-----------------------------------------------------------------------
# Define MCIP subset domain.  (Only used if BTRIM = -1.  Otherwise,
# the following variables will be set automatically from BTRIM and
# size of input meteorology fields.)
#   X0:     X-coordinate of lower-left corner of full MCIP "X" domain
#           (including MCIP lateral boundary) based on input MM5 domain.
#           X0 refers to the east-west dimension.  Minimum value is 1.
#   Y0:     Y-coordinate of lower-left corner of full MCIP "X" domain
#           (including MCIP lateral boundary) based on input MM5 domain.
#           Y0 refers to the north-south dimension.  Minimum value is 1.
#   NCOLS:  Number of columns in output MCIP domain (excluding MCIP
#           lateral boundaries).
#   NROWS:  Number of rows in output MCIP domain (excluding MCIP
#           lateral boundaries).
#-----------------------------------------------------------------------

 X0=13
 Y0=94
 NCOLS=89
 NROWS=104

 LPRT_COL=0
 LPRT_ROW=0

 WRF_LC_REF_LAT=40.0

#=======================================================================
#=======================================================================
# Set up and run MCIP.
#   Should not need to change anything below here.
#=======================================================================
#=======================================================================

 PROG=mcip

#date

#-----------------------------------------------------------------------
# Create the output directory.
#-----------------------------------------------------------------------

 if [ ! -d $OutDir ]
 then
   mkdir -p $OutDir
 fi


#-----------------------------------------------------------------------
# Create a work directory for this job.
#-----------------------------------------------------------------------

 if [ ! -d $WorkDir ]
 then
   mkdir -p $WorkDir
 fi

 cd $WorkDir

#-----------------------------------------------------------------------
# Set up script variables for input files.
#-----------------------------------------------------------------------

 FILE_GD=$OutDir/GRIDDESC

#-----------------------------------------------------------------------
# Create namelist with user definitions.
#-----------------------------------------------------------------------

 Marker="&END"

 cat > $WorkDir/namelist.${PROG} << !
  &FILENAMES
   file_gd    = "$FILE_GD"
   file_mm    = "$InMetFiles",
!


#if [ $#InMetFiles > 1 ]
#then
#  @ nn = 2
#  while [ $nn <= $#InMetFiles ]
#    cat >> $WorkDir/namelist.${PROG} << !
#               "$InMetFiles[$nn]",
#!
#    @ nn ++
#  end
#fi

cat >> $WorkDir/namelist.${PROG} << !
               "$InMetFiles",
!

echo  $WorkDir $IfGeo $InGeoFile
if [ $IfGeo == "T" ]
then
cat >> $WorkDir/namelist.${PROG} << !
   file_geo   = "$InGeoFile"
!
fi

cat >> $WorkDir/namelist.${PROG} << !
  ioform     =  $IOFORM
 $Marker

 &USERDEFS
  lpv        =  $LPV
  lwout      =  $LWOUT
  luvbout    =  $LUVBOUT
  mcip_start = "$MCIP_START"
  mcip_end   = "$MCIP_END"
  intvl      =  $INTVL
  coordnam   = "$CoordName"
  grdnam     = "$GridName"
  btrim      =  $BTRIM
  lprt_col   =  $LPRT_COL
  lprt_row   =  $LPRT_ROW
  wrf_lc_ref_lat = $WRF_LC_REF_LAT
 $Marker
!
#-----------------------------------------------------------------------
# Set links to FORTRAN units.
#-----------------------------------------------------------------------

#rm fort.*
#if [ -f $FILE_GD ] rm -f $FILE_GD

#ln -s $FILE_GD                   fort.4
#ln -s $WorkDir/namelist.${PROG}  fort.8

#NUMFIL = 0
#foreach fil ( $InMetFiles )
#  @ NN = $NUMFIL + 10
#  ln -s $fil fort.$NN
#  @ NUMFIL ++
#end

#if [ $status == 0 ]
#then
#  rm fort.*
#  exit 0
#else
#  echo "Error running $PROG"
#  exit 1
#fi

#-----------------------------------------------------------------------
# Set output file names and other miscellaneous environment variables.
#-----------------------------------------------------------------------

export IOAPI_CHECK_HEADERS=T
export EXECUTION_ID=$PROG

export GRID_BDY_2D=$OutDir/GRIDBDY2D_${APPL}.nc
export GRID_CRO_2D=$OutDir/GRIDCRO2D_${APPL}.nc
export GRID_DOT_2D=$OutDir/GRIDDOT2D_${APPL}.nc
export MET_BDY_3D=$OutDir/METBDY3D_${APPL}.nc
export MET_CRO_2D=$OutDir/METCRO2D_${APPL}.nc
export MET_CRO_3D=$OutDir/METCRO3D_${APPL}.nc
export MET_DOT_3D=$OutDir/METDOT3D_${APPL}.nc
export LUFRAC_CRO=$OutDir/LUFRAC_CRO_${APPL}.nc
export SOI_CRO=$OutDir/SOI_CRO_${APPL}.nc
export MOSAIC_CRO=$OutDir/MOSAIC_CRO_${APPL}.nc

if [ -f "$GRID_BDY_2D" ]; then
        rm -f $GRID_BDY_2D
fi
if [ -f "$GRID_CRO_2D" ]; then
        rm -f $GRID_CRO_2D
fi
if [ -f "$GRID_DOT_2D" ]; then
        rm -f $GRID_DOT_2D
fi
if [ -f "$MET_BDY_3D"  ]; then
        rm -f $MET_BDY_3D
fi
if [ -f "$MET_CRO_2D"  ]; then
        rm -f $MET_CRO_2D
fi
if [ -f "$MET_CRO_3D"  ]; then
        rm -f $MET_CRO_3D
fi
if [ -f "$MET_DOT_3D"  ]; then
        rm -f $MET_DOT_3D
fi
if [ -f "$LUFRAC_CRO"  ]; then
        rm -f $LUFRAC_CRO
fi
if [ -f "$SOI_CRO"     ]; then
        rm -f $SOI_CRO
fi
if [ -f "$MOSAIC_CRO"  ]; then
        rm -f $MOSAIC_CRO
fi

if [ -f "$OutDir/mcip.nc" ]; then
        rm -f $OutDir/mcip.nc
fi
if [ -f "$OutDir/mcip_bdy.nc" ]; then
        rm -f $OutDir/mcip_bdy.nc
fi
#-----------------------------------------------------------------------
# Execute MCIP.
#-----------------------------------------------------------------------
echo "EXECUTING MCIP"
$ProgDir/${PROG}.exe


