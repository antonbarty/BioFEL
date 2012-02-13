;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Interactively define the beamtop
;;
pro fel_browser_definebeamstop, pstate

	if (*pstate).global.nfiles eq 0 then $
		return

	img = float((*(*pstate).global.image_data))
	img = fel_browser_scaleimage(pstate, img)
	img = fel_browser_imagegamma(pstate, img)
	s = size(img,/dim)

	beamstop = (*pstate).global.beamstop
	r = fel_definebeamstop_gui(img, cx = beamstop[0], cy = beamstop[1], cr = beamstop[2])
	
	cx_rel = float(r[0]) / s[0]
	cy_rel = float(r[1]) / s[1]
	cr_rel = float(r[2]) / s[0]
	(*pstate).global.beamstop = [cx_rel,cy_rel,cr_rel]

	r = fix(r)
	text = strcompress(string('centre = ( ',r[0],', ',r[1],' ), r=', r[2]),/remove_all) 
	WIDGET_CONTROL, (*pstate).text.listText2, SET_VALUE = text

end
