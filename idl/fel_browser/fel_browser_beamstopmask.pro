;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Softened beamstop mask
;;
function fel_browser_beamstopmask, pstate, soft=soft

	;;
	;;	Scale beamstop location to image size
	;;
		data = (*(*pstate).global.image_data)
		s = size(data,/dim)
		cx = (*pstate).global.beamstop[0]*s[0]
		cy = (*pstate).global.beamstop[1]*s[1]
		cr = (*pstate).global.beamstop[2]*s[0]

	;;
	;;	Create beamstop mask
	;;
		d = dist(s[0],s[1])		
		d = shift(d, cx, cy)
		mask = fltarr(s[0],s[1])
		mask[*] = 1
		mask[where(d lt cr)] = 0
		
	;;
	;;	Make the edges soft
	;;
		if keyword_set(soft) then begin $
			;mask = smooth(mask, cr/4)
			;mask = smooth(mask, cr/4)
			mask = (d/cr)^4*exp(-0.5*(d/cr)^2)/(16.*exp(-2.))
			ii = where(d ge cr*2)
			mask[ii] = 1.
			
		endif

	;;
	;;	Return
	;;
		return, mask
end
