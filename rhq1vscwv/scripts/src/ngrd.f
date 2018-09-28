!convert lat/lon (in degree) to grid points function
 INTEGER FUNCTION ngrd(deg,deg0,ideg)
 REAL deg, deg0, ideg
   ngrd=NINT((deg-deg0)/ideg)+1
   RETURN
 END
