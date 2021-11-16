undef("scm_press_to_hgt")

function scm_press_to_hgt(psfc_Pa:float,p_Pa:float,tmp_K:float,q_kgkg:float,z0:float)

; From Wayne Angevine:
; Converts pressure to height using geopotential equation
; (Wallace and Hobbs p.57 eq. 2.29)
; Input parameters are row vectors of pressure (mb),
; temperature (K), surface pressure p0 (mb), specific humidity (kg/kg),
; and ground height z0 (m).
; z0 may be set to zero to compute height AGL.
; Expects input arrays to be dimension (time,lev).
; This computation really only works reasonably accurately if you feed it
; the entire profile from near the ground, since it essentially integrates upward.

local R_dry,g,epsilon,p_mb,psfc_mb,rv_kgkg,Tv_K,dims,nhts,p,dz,hgt_m

begin

; Constants.
  R_dry   = 287.058 ; ideal gas constant for dry air (J kg^-1 K^-1)
  g       = 9.80665 ; acceleration due tp gravity (m s^-2)
  epsilon = 0.622

; Convert pressure from Pa to mb.
  p_mb = p_Pa/100.
  psfc_mb = psfc_Pa/100.

; Calculate virtual temperature.
  rv_kgkg = q_kgkg/(1.-q_kgkg)
  Tv_K = tmp_K*(1.+rv_kgkg/epsilon)/(1.+rv_kgkg)

  dims = dimsizes(p_mb)
  nhts = dims(1)

; Add surface pressure to existing pressure array.
; Dimensions must be named.
  psfc_mb!0 = "time"

  p_mb!0 = "time"
  p_mb!1 = "lev"

; Create the merged array.
; -1 indicates bottom-top ordering.
  p = merge_levels_sfc(p_mb,psfc_mb,-1)

  dz = (R_dry*Tv_K/g)*log(p(:,0:nhts-1)/p(:,1:nhts))

  hgt_m = new(dimsizes(p_mb),typeof(p_mb))

  do i = 0,nhts-1
    hgt_m(:,i) = z0+dim_sum(dz(:,0:i))
  end do

  return(hgt_m)

end
