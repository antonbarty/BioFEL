;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Display image in preview window
;;
pro fel_browser_preview, pstate

	if (*pstate).global.nfiles eq 0 then $
		return
			
	data = (*(*pstate).global.image_data)
	data = float(data)
	
	;; Correction	
		if widget_info((*pstate).menu.Correction_CropDataAtZero, /button_set) then $
			data = data > 0		
		if widget_info((*pstate).menu.Correction_AbsData, /button_set) then $
			data = abs(data)		

	
	;; Prepare data for display
		data = fel_browser_subtractBackground(pstate, data)
		data = fel_browser_scaleimage(pstate, data)
		fel_browser_histogram, pstate, xmin=min(data), xmax=max(data)
		

	;; Generate preview image
		img = data
		img = fel_browser_imagegamma(pstate, img)
		;stop
	
	
	;; Rescale to preview display window size (but do not change aspect ratio)
		s = size(img, /dim)
		mag_x = float((*pstate).global.preview_nx)/s[0]
		mag_y = float((*pstate).global.preview_ny)/s[1]
		mag = min([mag_x,mag_y])
		xstart = ((*pstate).global.preview_nx-s[0]*mag)/2
		ystart = ((*pstate).global.preview_ny-s[1]*mag)/2
		
		preview = fltarr((*pstate).global.preview_nx, (*pstate).global.preview_ny)
		replicate_inplace, preview, min(img)
		preview[xstart,ystart] = congrid(img, s[0]*mag, s[1]*mag) 


	;; Display
		oldwin = !d.window
		wset, (*pstate).window.preview
		loadct, (*pstate).global.colour_table, /silent
		tvscl, preview
		if oldwin ne -1 then $
			wset, oldwin
			
	;;	Save processed data in global
		if ptr_valid((*pstate).global.processed_data) then $
			ptr_free, (*pstate).global.processed_data
		(*pstate).global.processed_data = ptr_new(data, /no_copy)
end

