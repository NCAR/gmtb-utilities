load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"

begin

; User modification area, read in the LASSO files and determine time
; Note: your directories will likely be different; will need to adjust
; based on your personal directory choices.
  topdir = "/glade/work/damico/"
  nmdir  = "/glade/u/home/damico/SCMv4/gmtb-scm/scm/etc/case_config/"
  LAS    = "LASSO"
  pbl    = (/ "ACM","MYNN","YSU" /)

; Change to the date of your simulation(s)
  YYYY = 2016   ; Year, 4 digit year CE
  MM   = 8      ; Month, no leading zero necessary
  DD   = 30     ; Day, day of your month, no leading zero
  hh   = 12     ; Hour, start time of simulation (mainly 12 for 12:00:00 utc)

; Define the full date
  if (MM .lt. 10 .and. DD .lt. 10) then
    date = YYYY+"0"+MM+"0"+DD
  else if (MM .lt. 10 .and. DD .ge. 10) then
    date = YYYY+"0"+MM+DD
  else if (MM .ge. 10 .and. DD .lt. 10) then
    date = YYYY+MM+"0"+DD
  else
    date = YYYY+MM+DD
  end if
  end if
  end if

; User modification area: Select the physics suite for your series of LASSO
; simulations
  phys = "GFS_v16beta_"+pbl
  np   = dimsizes(phys)

; List the simulations in the directory for your selected date
  simID = systemfunc("ls "+topdir+LAS+"_"+date+"/")
  xsim  = max(toint(simID))
  ns    = dimsizes(simID)

; Read one of the original LASSO namelists to determine how many lines 
; should be present in your individual (new) namelists
  orig_nm = nmdir+"LASSO_2016051812_MSDA.nml"
  orig    = asciiread(orig_nm,-1,"string")
  nl      = dimsizes(orig)

  delete(orig)

  lines = new((/ ns,nl /),string)
  do i=0,ns-1,1
    lines(i,:) = (/ "$case_config",                                    \
                    "model_name = 'FV3',",                             \
                    "n_columns = 1,",                                  \
                    "case_name = '"+LAS+"_"+date+"_SID"+simID(i)+"',", \
                    "dt = 600.0,",                                     \
                    "time_scheme = 1,",                                \
                    "runtime = 54000,",                                \
                    "output_frequency = 600.0,",                       \
                    "n_levels = 127,",                                 \
                    "output_file = 'output',",                         \
                    "case_data_dir = '../data/processed_case_input',", \
                    "vert_coord_data_dir = '../data/vert_coord_data',",\
                    "thermo_forcing_type = 2,",                        \
                    "mom_forcing_type = 3,",                           \
                    "relax_time = 7200.0,",                            \
                    "sfc_flux_spec = .true.,",                         \
                    "sfc_roughness_length_cm = 10.0,",                 \
                    "sfc_type = 1,",                                   \
                    "reference_profile_choice = 2,",                   \
                    "year = "+YYYY+",",                                \
                    "month = "+MM+",",                                 \
                    "day = "+DD+",",                                   \
                    "hour = "+hh+",",                                  \
                    "column_area = 1.45E8,",                           \
                    "$end" /)

;    system("/bin/rm -fv "+LAS+"_"+date+"_SID"+simID(i)+".nml")
;    asciiwrite(LAS+"_"+date+"_SID"+simID(i)+".nml",lines(i,:))
;    print("Wrote namelist "+LAS+"_"+date+"_SID"+simID(i)+".nml")
  end do

  dq = str_get_dq() ; Need double quotation marks in your strings to write the
                    ; multiple run file

  cs  = "cases = ["
  ste = "suites = [" 
  pnm = "namelists = [" 

  runs = new((/ ns /),string)
  csnm = new((/ ns /),string)
  do i=0,ns-1,1
    runs(i) = dq+LAS+"_"+date+"_SID"+simID(i)+dq
    if (i .ne. ns-1) then
      csnm(i) = runs(i)+","
    else
      csnm(i) = runs(i)+"]"
    end if
  end do

  fste   = new((/ np /),string)
  fnml   = new((/ np /),string)
  physte = new((/ np /),string)
  phynml = new((/ np /),string)
  do i=0,np-1,1
    fste(i) = dq+"SCM_"+phys(i)+dq
    fnml(i) = dq+"input_"+phys(i)+".nml"+dq
    if (i .ne. np-1) then
      physte(i) = fste(i)+","
      phynml(i) = fnml(i)+","
    else
      physte(i) = fste(i)+"]"
      phynml(i) = fnml(i)+"]"
    end if
  end do

  cases_n = str_concat(csnm)
  cases_t = cs + cases_n

  suite_n = str_concat(physte)
  suite_t = ste + suite_n

  nml_n = str_concat(phynml)
  nml_t = pnm + nml_n

  multifname = LAS+"_multirun_"+date+".py"
  system("/bin/rm -fv "+multifname)

  write_table(multifname,"w",[/cases_t/],"%s")
  write_table(multifname,"a",[/suite_t/],"%s")
  write_table(multifname,"a",[/nml_t/]  ,"%s")

  print("Wrote multi file Python: "+multifname)

end

