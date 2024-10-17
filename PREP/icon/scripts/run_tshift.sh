#!/bin/bash

export EXEC=/opt/atrium/ioapi-3.2/Linux2_aarch64gfort12/m3tshift

#> Year to be entirely encompassed by the time stamps in the time-shifted output file
export TARGET_YEAR=2024

#> Path to the seasonal average H-CMAQ file downloaded from the CMAS data warehouse
#> This path will also be used to store the time-shifted output file
export DATADIR=/home/ubuntu/CMAQ/SEASONAL

#> Name of the seasonal average H-CMAQ file downloaded from the CMAS data warehouse
export AV_CONC_INFILE=CCTM_CONC_v53beta2_intel17.0_HEMIS_cb6r3m_ae7_kmtbr_m3dry_2016_quarterly_av.nc

#> Name of the time-shifted seasonal average H-CMAQ file 
export AV_CONC_OUTFILE=CCTM_CONC_v53beta2_intel17.0_HEMIS_cb6r3m_ae7_kmtbr_m3dry_${TARGET_YEAR}_quarterly_av.nc

export INFILE=${DATADIR}/${AV_CONC_INFILE}
export OUTFILE=${DATADIR}/${AV_CONC_OUTFILE}

#> Invoke m3shift to shift the time stamps to the target year
#> Note that the first time stamp represents the fall of the previous year
export PREVIOUS_YEAR=2021

${EXEC} << EOF
INFILE
2015289
120000
${PREVIOUS_YEAR}289
120000
21960000
131760000
OUTFILE
EOF
