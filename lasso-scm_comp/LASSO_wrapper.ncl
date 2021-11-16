load "LASSO_wind_wa_subsets.ncl"
load "LASSO_thtQ_wa_subsets.ncl"
load "LASSO_thtQ_prof_wa_subsets.ncl"
load "LASSO_pblh_wa_subsets.ncl"
load "LASSO_cld_wa_subsets.ncl"

; Options.
; Generate new files and plots for each case, as opposed to
; simply generating the composites from existing case files.
case_files = True

; Directory to write results.
diro = "/work/noaa/ufs-phys/ekalina/lasso-les/comparison_data/"

; Directory containing LASSO data.
diri = "/work/noaa/ufs-phys/ekalina/lasso-les/2018_from_wayne/"

; Get a list of LASSO LES output to process.
files=tochar(systemfunc ("csh -c 'cd " + diri + " ; ls wrfstat*.nc'"))
nfiles=dimsizes(tostring(files))

yyyy=tostring(files(:,22:25))
mm=tostring(files(:,27:28))
dd=tostring(files(:,30:31))
hh=tostring(files(:,33:34))

if (case_files) then

  do i=0,nfiles-1

    print("Processing case "+yyyy(i)+mm(i)+dd(i)+hh(i))

    LASSO_wind_wa_subsets(yyyy(i),mm(i),dd(i),hh(i))
    LASSO_thtQ_wa_subsets(yyyy(i),mm(i),dd(i),hh(i))
    LASSO_thtQ_prof_wa_subsets(yyyy(i),mm(i),dd(i),hh(i))
    LASSO_pblh_wa_subsets(yyyy(i),mm(i),dd(i),hh(i))
    LASSO_cld_wa_subsets(yyyy(i),mm(i),dd(i),hh(i))

  end do

end if

; Make composite.
status = systemfunc("cdo -v ensmean "+diro+"LASSO_SCM_comp_*.nc "+diro+"LASSO_SCM_composite.nc")
status = systemfunc("cdo -v ensstd "+diro+"LASSO_SCM_comp_*.nc "+diro+"LASSO_SCM_composite_std.nc")
