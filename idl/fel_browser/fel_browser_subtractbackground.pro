;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Subtract background
;;
function fel_browser_subtractBackground, pstate, img, background=background, scale=scale, smooth=smooth

	;;
	;;	Should we even execute the code
	;;
		if NOT widget_info((*pstate).menu.Viewer_backgroundSubtract, /button_set) then begin
			background = 0
			return, img
		endif
			
		if NOT ptr_valid((*pstate).global.background_data) then begin
			background = 0
			return, img
		endif
		
	;;
	;;	Scaling
	;;
		if not KEYWORD_SET(scale) then $
			scale = 1.0
		if not KEYWORD_SET(smooth) then $
			smooth = 0
		
	;;
	;;	Retrieve background data from memory
	;;
		background = float((*(*pstate).global.background_data))
		if smooth ne 0 then $
			background = smooth(background, smooth)
		background *= scale
		sb = size(background,/dim)
		si = size(img,/dim)

	;;
	;;	Subtract images, scaled to the same size
	;;
		if (si[0] eq sb[0]) AND (si[1] eq sb[1]) then begin
			img -= background 
		endif $
		else begin
			background = congrid(background, si[0],si[1])
			img -= background
		endelse

	return, img
end
