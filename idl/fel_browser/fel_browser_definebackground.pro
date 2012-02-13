;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


;;
;;	Define background image
;;
pro fel_browser_definebackground, pstate

	if (*pstate).global.nfiles eq 0 then $
		return

	;;
	;;	Which files are currently selected?
	;;
		selection = widget_info((*pstate).table.files, /table_select)
		if (selection[0] eq -1) then $
			return
		sel_start = selection[1]
		sel_end = selection[3]
		
	;;
	;;	Loop through files
	;;	Background = average of selected files
	;;
		WIDGET_CONTROL, /HOURGLASS
		for i=sel_start, sel_end do begin
			(*pstate).global.currentFileID = i
			(*(*pstate).global.metadata)[i,(*pstate).global.metadata_columns.hits] = 'Background'
			WIDGET_CONTROL, (*pstate).table.files, SET_TABLE_SELECT=[-1,i,-1,i]
			fel_browser_loadimage,pstate
			image = *((*pstate).global.image_data)
			image = float(image)
	
			if n_elements(background) eq 0 then $
				background = image $
			else $
				background += image 
		endfor

		background /= (sel_end-sel_start+1)
	
	;;
	;;	Update global variable with current background image
	;;
		ptr_free, (*pstate).global.background_data
		(*pstate).global.background_data = ptr_new(background, /no_copy)					
		fel_browser_displaycomments, pstate

end
