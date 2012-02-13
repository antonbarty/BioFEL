;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


;;
;;	Display what we think is the current background image
;;
pro fel_browser_smoothbackground, pstate

	if NOT ptr_valid((*pstate).global.background_data) then begin
		result = dialog_message('No background image defined')
		return
	endif

	;;
	;;	Dialog box for parameters
	;;
		form_desc=[ '1, BASE,, COLUMN', $
					'0, INTEGER, 0, label_left=smooth(data):, tag=smooth', $
					'2, INTEGER, 0, label_left=median(data):, tag=median', $

					'1, BASE,, ROW, FRAME', $
					'0, BUTTON, OK, QUIT, tag=ok', $
					'2, BUTTON, Cancel, QUIT' $
				  ]

		form = cw_form(form_desc, title='OfflineCASS options', /column)
		if form.ok ne 1 then $
			return

	;;
	;;	Do the smoothing...
	;;
		bg = (*(*pstate).global.background_data)

		if form.smooth ne 0 then begin
			bg = smooth(bg, form.smooth) 
		endif

		if form.median ne 0 then begin
			bg = median(bg, form.median) 
		endif

	;;
	;;	Update background image
	;;
		ptr_free, (*pstate).global.background_data
		(*pstate).global.background_data = ptr_new(bg, /no_copy)					
	
end

