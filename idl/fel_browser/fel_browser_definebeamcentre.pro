;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


;;
;;	Interactively define the diffraction pattern centre
;;
pro fel_browser_definebeamcentre, pstate

	if (*pstate).global.nfiles eq 0 then $
		return

	;;
	;;	If centre is shifted, turn this off for now
	;;	and load a raw, unshifted image
	;;
		state = widget_info((*pstate).menu.Correction_CentreInCentre , /button_set)
		if state eq 1 then begin
			widget_control, (*pstate).menu.Correction_CentreInCentre, set_button=0
			fel_browser_loadimage, pstate		
		endif


	img = float((*(*pstate).global.image_data))
	img = fel_browser_scaleimage(pstate, img)
	img = fel_browser_imagegamma(pstate, img)

	s = size(img,/dim)

	centre = (*pstate).global.img_centre
	r = fel_definebeamstop_gui(img, cx = centre[0], cy = centre[1], /star)

	cx_rel = float(r[0]) / s[0]
	cy_rel = float(r[1]) / s[1]
	(*pstate).global.img_centre = [cx_rel,cy_rel]

	r = fix(r)
	text = strcompress(string('centre = ( ',r[0],', ',r[1],' )'),/remove_all) 
	WIDGET_CONTROL, (*pstate).text.listText2, SET_VALUE = text


	;;
	;;	If centre was shifted, turn it back on
	;;
		if state eq 1 then begin
			widget_control, (*pstate).menu.Correction_CentreInCentre, set_button=1
			fel_browser_loadimage, pstate		
		endif


end
