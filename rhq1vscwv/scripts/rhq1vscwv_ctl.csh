#!/bin/csh -f
foreach fcst (000 024 048 072 096 120 144 168 192 216)

cat>r.vs.pwat_PDF.f${fcst}.ctl<<EOF
DSET ^r.vs.pwat_PDF.f${fcst}.gdat
title FV3GFS r vs pwat
undef 9.999e+20
options little_endian
xdef     1 linear    0.000  1.000
ydef     1 linear    0.000  1.000
zdef 19 levels 1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200
* number of bins
tdef   61 linear   01JUN2017   1dy
vars 1
p  19 99 r [%] as a function of pwat [mm]
endvars
EOF

end
