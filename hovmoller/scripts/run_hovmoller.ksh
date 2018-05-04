#!/bin/ksh

# This script uses NetCDF files from the run_pcp_combine.ksh to call the plot_hovmoller.ncl script, which creates Hovmoller plots (time/longitude plots). This script is universal; it can plot either the forecast or the observations. Users can edit the run_hovmoller.ncl script to change titles, etc. In addition, the script is set to average precipitation from 5N - 15N, but is easily user-configurable.

# Name of script
script="plot_hovmoller.ncl"

# Load necessary modules
module load ncl

# Input directory where forecast or observation file is located
in_dir="/scratch4/BMC/gmtb/harrold/test_hovmoller/cmorph/proc/cat/"

# Name of input file to be plotted
in_file="cmorph_APCP06_2016060200-2016061100_valid00Z.nc"

# Output directory where forecast or observation hovmoller plot will be written 
out_dir="/scratch4/BMC/gmtb/harrold/test_hovmoller/output/"
mkdir -p ${out_dir}

# Name of output file
out_file="test06_cmorph.png"

# Name of precipitation variable in file created in run_pcp_combine.ksh script
precip_var="APCP_06"

ncl "in_dir=\"${in_dir}\"" "in_file=\"${in_file}\"" "out_dir=\"${out_dir}\"" "out_file=\"${out_file}\"" "precip_var=\"${precip_var}\"" < ${script}

