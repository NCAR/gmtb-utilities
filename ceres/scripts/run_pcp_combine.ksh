#!/bin/sh
# Run the MET tool pcp_combine to derive the mean, given a forecast list
# Must use METv8.1 (or development branch if not yet released)
#
# Regrid forecast to observation using MET regrid_data_plane tool

base=/gpfs/u/home/hertneky/scripts/ceres
list_dir=${base}/file_lists
out_dir=${base}/output
obs_dir=/glade/p/ral/jntp/GMTB/data/ceres
pcp_combine=/glade/p/ral/jntp/MET/MET_development/trunk/met/bin/pcp_combine
regrid_data_plane=/glade/p/ral/jntp/MET/MET_development/trunk/met/bin/regrid_data_plane

suite_list="suite1 suite2 suite3 suite4"
season_list="DJF MAM JJA SON YEAR"
day_list="day1 day3 day5 day10"

mkdir -p ${out_dir}

# Loop through all suites, seasons, and forecast days
for suite in ${suite_list}; do
    for season in ${season_list}; do
	for day in ${day_list}; do

	    # Run pcp_combine to derive the mean for the specified fields
	    ${pcp_combine} -derive mean ${list_dir}/file_list_${suite}_${season}_${day}.txt \
	    ${out_dir}/fv3gfs_${suite}_${season}_${day}_mean.nc \
	    -field 'name="DSWRF";level="L0";' -field 'name="DLWRF";level="L0";' \
	    -field 'name="USWRF";level="L0";' -field 'name="ULWRF";level="L0";' \
	    -field 'name="USWRF";level="R493";' -field 'name="ULWRF";level="R494";' \
	    -name DSWRF,DLWRF,USWRF,ULWRF,USWRF_TOA,ULWRF_TOA

	    # Regrid the mean files to the observation grid
	    regrid_data_plane ${out_dir}/fv3gfs_${suite}_${season}_${day}_mean.nc \
                              ${obs_dir}/CERES_EBAF-Surface_Ed4.0_Subset_201601-201712.nc \
                              ${out_dir}/fv3gfs_${suite}_${season}_${day}_mean_regrid.nc \
                              -field 'name="DSWRF";level="L0";' \
                              -field 'name="DLWRF";level="L0";' \
                              -field 'name="USWRF";level="L0";' \
                              -field 'name="ULWRF";level="L0";' \
                              -field 'name="USWRF_TOA";level="L0";' \
                              -field 'name="ULWRF_TOA";level="L0";'

	done
    done
done
