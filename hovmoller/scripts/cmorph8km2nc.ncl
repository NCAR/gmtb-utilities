;***************************************************************
; cmorph8km2nc.ncl
;
; Concepts illustrated:
;   - Reading big endian binary files
;   - Reading records written by a fortran *direct access* write
;   - Reading CMORPH 8km data
;   - Adding meta data (attributes and coordinates [time, lat, lon])
;   - Explicitly setting contour levels and colors
;***************************************************************
;; ftp://ftp.cpc.ncep.noaa.gov/precip/global_CMORPH/README.cmorph.8km_30minute
;;
;; Each direct access record is a 4948 x 1649 CHARACTER*1 (use FORTRAN ichar
;; command to retrieve interger value for all parameters) array with  grid
;; increments of 0.072756669 degrees of longitude and 0.072771377 of latitude,
;; which is apporoximately 8 km at the equator.  The arrays are oriented from
;; North to South, beginning from latitude 59.963614N and from West to EAST from
;; longitude  0.036378335E.
;;
;; Missing data are denoted by values of 255.
;;
;; Note that the precipitation estimates have been scaled, and when multiplied by
;; "0.2", the data units are "mm/hour".
;;
;; For GrADS users, a descriptor ("ctl") file: CMORPH_8km-30-minute.ctl has been
;; provided.  However, since the data are in CHARACTER*1 words (bytes) the parameters
;; after each variable (-1,40,1,-1 in our example "ctl file") are system dependent.
;; Our example is for an SGI system.
;;
;; Each file contains 6 records.  The 1st 3 records pertain to the top half
;; of the hour (00-29 minus after the hour) and the last 3 records are for the
;; bottom half of the hour.  Within each group:
;;
;;   -  the 1st record contains the CMORPH precipitation estimates
;;
;;   -  the 2nd record contains the time (in half hour units) since the most
;;      recent microwave pass.  Note that since we do both a forward &
;;        backward interpolation in time, the nearest time may be prior to
;;        the file time stamp or after it.
;;
;;   -  the 3rd record contains an ID that tells the satellite from which the last
;;        microwave observation was made which can be interpretted by the following
;;        table (as of the time of the last update of this documentation):
;;
;;        13 = DMSP-13 (SSM/I instrument)
;;        14 = DMSP-14 (  "       "      )
;;        15 = DMSP-15 (  "       "      )
;;        16 = DMSP-16 (SSMIS instrument, coming soon)
;;        17 = DMSP-17 ( " " )
;;        18 = DMSP-18 ( " " )
;;       115 = NOAA-15 (AMSU-B    "      )
;;       116 = NOAA-16 (  "       "      )
;;       117 = NOAA-17 (  "       "      )
;;       118 = NOAA-18 (MHS )
;;       119 = NOAA-19 ( " " )
;;       151 = METOP-A ( " " )
;;       201 = TRMM    (TMI       "      )
;;       211 = AQUA    (AMSR-E    "      )
;;
;;
;; Each direct access record is a 4948 x 1649 CHARACTER*1 (use FORTRAN ichar
;; command to retrieve interger value for all parameters) array with  grid
;; increments of 0.072756669 degrees of longitude and 0.072771377 of latitude,
;; which is apporoximately 8 km at the equator.  The arrays are oriented from
;; North to South, beginning from latitude 59.963614N and from West to EAST from
;; longitude  0.036378335E.
;;
;; Missing data are denoted by values of 255.
;;
;; Note that the precipitation estimates have been scaled, and when multiplied by
;; "0.2", the data units are "mm/hour".
;********************************************************************************

  ; The file to process needs to be set!
  fili = "PATH_TO_INFILE"                                 ; INPUT
         print(fili)
  pthi  = fili
                                                          ; OUTPUT
  ncDir = "./"                                            ; directory for netCDF output
  ncFil = fili + ".nc"                                    ; netCDF name output

  dlim  = "_-"                                            ; string delimiter
  nfld  = str_fields_count(fili, dlim)                    ; nfld=4
           print(nfld)

  ymdh  = toint(str_get_field(fili, 4, dlim))             ; yyyymmddhh
  yyyy  = ymdh/1000000
  mdh   = ymdh - yyyy*1000000
  mm    = mdh/10000
  dh    = mdh - mm*10000
  dd    = dh/100
  hh    = dh-dd*100

  tunits= "hours since 2000-01-01 00:00:00"                ; arbitrary date
  time  = cd_inv_calendar(yyyy,mm,dd,hh, 0, 0,tunits, 0)
print(time)
  time!0= "time"

  ntim  = 1
  nlat  = 1649
  nlon  = 4948

  lat   = 59.963614d - ispan(0,nlat-1,1)*0.072771377d    ; N->S
  lat!0 = "lat"
  lat@units = "degrees_north"
  printMinMax(lat,0)

  lon   = 0.036378335d + ispan(0,nlon-1,1)*0.072756669d
  lon!0 = "lon"
  lon@units = "degrees_east"
  printMinMax(lon,0)

;---- Read 'top-half' of the hour (00-29 minus after the hour)
;     This is the 1st record (recnum=0)

  prc_u = fbindirread(pthi,0,(/ntim,nlat,nlon/),"ubyte")
  prc_u@_FillValue = toubyte(255)
  printMinMax(prc_u,0)

  prc = where(ismissing(prc_u), -9999., prc_u*0.2)
  prc@_FillValue = -9999.
  delete(prc_u)                        ; no longer needed

  prc@long_name = "CMORPH 8km"
  prc@units     = "mm/hr"
  prc!0         = "time"
  prc!1         = "lat"
  prc!2         = "lon"
  prc&time      =  time
  prc&lat       =  lat
  prc&lon       =  lon
  printVarSummary(prc)
  printMinMax(prc,0)

;************************************************
; Create netCDF
; Recommend to always create a 'time' dimension
;************************************************

nline  = inttochar(10)

globeAtt              = 1
globeAtt@Conventions  = "CF-1.0"
globeAtt@title        = "CMORPH: 8km Hourly"
globeAtt@ftp          = "ftp://ftp.cpc.ncep.noaa.gov/precip/global_CMORPH/30min_8km"
globeAtt@acronym      = "CMORPH: CPC Morphing Technique"
globeAtt@description  = "http://www.cpc.noaa.gov/products/janowiak/cmorph_description.html"
globeAtt@referenceon  = nline + \
  "Joyce, R. J., J. E. Janowiak, P. A. Arkin, and P. Xie, 2004:       "+nline+\
  "CMORPH: A method that produces global precipitation estimates      "+nline+\
  "        from passive microwave and infrared data at high spatial   "+nline+\
  "        and temporal resolution. J. Hydromet., 5, 487-503.         "+nline

globeAtt@creation_date= systemfunc ("date" )

NCFILE = ncDir + ncFil
system ("/bin/rm -f " +  NCFILE)    ; remove any pre-exist file

ncdf   = addfile(NCFILE,"c")

;setfileoption(ncdf, "definemode", True)

fileattdef( ncdf, globeAtt )        ; create the global [file] attributes

dimNames = (/"time", "lat", "lon" /)
dimSizes = (/ ntim ,  nlat,  nlon /)
dimUnlim = (/ True , False, False /)
filedimdef(ncdf, dimNames  , dimSizes,  dimUnlim )

filevardef   (ncdf, "time"  , typeof(time), getvardims(time) )
filevarattdef(ncdf, "time", time)

filevardef   (ncdf, "lat", typeof(lat), getvardims(lat))
filevarattdef(ncdf, "lat", lat)

filevardef   (ncdf, "lon", typeof(lon), getvardims(lon))
filevarattdef(ncdf, "lon", lon)

filevardef    (ncdf, "CMORPH"  , typeof(prc) , getvardims(prc) )
filevarattdef (ncdf, "CMORPH"  , prc)

ncdf->time   = (/ time /)
ncdf->lat    = (/ lat /)
ncdf->lon    = (/ lon /)
ncdf->CMORPH = (/ prc /)
