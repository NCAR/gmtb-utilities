*
*  Script to plot a colorbar
*
*
*	modifications by mike fiorino 940614
*	modifications and simplification by Kyu-Myong Kim 960923
*
*	- the colors are boxed in white
*	- input arguments in during a run execution:
*   USAGE:
*   run cbar-g.gs scl sf vert xmid ymid ndig sfc xsz ysz (for scl<0)
*   run cbar-g.gs scl sf vert xmid ymid ndig sfc (for scl>0)
*   run cbar-g.gs scl sf vert xmid ymid ndig (scl>0 and defalut string size)
*   run cbar-g.gs scl sf vert xmid ymid (scl>0, defalut string size, and ndig=1)
*
*	scl  - scale the bar sizei, 1.0 = x/y axis size of the figure
*              if scl < 0, bar size is determined by xsz and ysz
*	sf   - scale the bar width, x and y offset, and string offset
*	vert - 0 FORCES a horizontal bar = 1 a vertical bar
*	xmid - the x position on the virtual page the center the bar
*              xmid+xoffset is the left end of the bar for vert=1
*	ymid - the x position on the virtual page the center the bar
*              ymid+yoffset is the top end of the bar for vert=0
*	ndig - numbert of total digit include +/- and dots (only for vert=1)
*              (e.g. -10.4 --> ndig=5)
*	sfc  - scale factors for string size. default size is 0.12x0.13
*       xsz  - horizontal size of the bar. only for negative scl
*              xsz will be neglected for vert=1
*       ysz  - vertical size of the bar. only for negative scl
*              ysz will be neglected for vert=0
*

function colorbar (args)

scl=subwrd(args,1)
sf=subwrd(args,2)
vert=subwrd(args,3)
xmid=subwrd(args,4)
ymid=subwrd(args,5)
skn=subwrd(args,6)
ndigit=subwrd(args,7)
sfc=subwrd(args,8)

if (sfc='') ; sfc=1.0;endif
if (ndigit='') ; ndigit=1.0;endif
if(sf='');sf=1.0;endif
  if (scl<0)
  xsz=subwrd(args,8)
  ysz=subwrd(args,9)
  sfc=1.0
  endif

*
*  Check shading information
*
  'query shades'
  shdinfo = result
  if (subwrd(shdinfo,1)='None') 
    say 'Cannot plot color bar: No shading information'
    return
  endif

* 
*  Get plot size info
*
  'query gxinfo'
  rec2 = sublin(result,2)
  rec3 = sublin(result,3)
  rec4 = sublin(result,4)
  if (scl>0)
  xsiz = subwrd(rec3,6)-subwrd(rec3,4)
  ysiz = subwrd(rec4,6)-subwrd(rec4,4)
  xsiz=xsiz*scl
  ysiz=ysiz*scl
  else
  xsiz=xsz
  ysiz=ysz
  endif

  barsf=0.1*sf
  yoffset=barsf / 2
  xoffset=barsf / 2
  stroff=0.05*sfc
  strxsiz=0.12*sfc
  strysiz=0.13*sfc
  stroff2=strxsiz*(ndigit-0.5)
*
*  Decide if horizontal or vertical color bar
*  and set up constants.
*
  cnum = subwrd(shdinfo,5)
*
*	logic for setting the bar orientation with user overides
*
    if(vert = 0) ; vchk = 0 ; endif
    if(vert = 1) ; vchk = 1 ; endif
*
*	vertical bar
*

  if (vchk = 1 )

    xwid = ysiz/cnum*barsf
    ywid = ysiz/cnum
    
    xl = xmid+xoffset
    xr = xl + xwid
    yb = ymid-ysiz/2
    'set string 1 r 5'
    vert = 1

  else

*
*	horizontal bar
*

    ywid = xsiz/cnum*barsf
    xwid = xsiz/cnum

    yt = ymid + yoffset
    yb = ymid
    xl = xmid-xsiz/2
    'set string 1 tc 5'
    vert = 0
  endif

*
*  Plot colorbar
*
  'set strsiz 'strxsiz' 'strysiz
    rec = sublin(shdinfo,2)
    hi = subwrd(rec,2)
      if (vert)
         xp=xr+stroff +stroff2
        'draw string 'xp' 'yb' 'hi
      else
         yp=yb-stroff
*        'draw string 'xl' 'yp' 'hi
      endif

  num = 0
  checklab=0
  while (num<cnum) 
  checklab=checklab+1
    rec = sublin(shdinfo,num+2)
    col = subwrd(rec,1)
    hi = subwrd(rec,3)
    if (vert) 
      yt = yb + ywid
    else 
      xr = xl + xwid
    endif

    if(num!=-1 & num!= cnum)
    'set line 1 1 10'
    'draw rec 'xl' 'yb' 'xr' 'yt
    'set line 'col
    'draw recf 'xl' 'yb' 'xr' 'yt

    if (num<cnum & checklab = skn);checklab = 0;
      if (vert) 
        xp=xr+stroff+stroff2
        'draw string 'xp' 'yt' 'hi
      else
        yp=yb-stroff
        'draw string 'xr' 'yp' 'hi
      endif
    endif
    endif

    num = num + 1
    if (vert); yb = yt;
    else; xl = xr; endif;
  endwhile
return
