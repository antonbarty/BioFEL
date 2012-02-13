;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Scale image
;;
function fel_browser_scaleimage, pstate, img

	;;
	;;	Do we make data positive
	;;
		if widget_info((*pstate).menu.Correction_CropDataAtZero, /button_set) eq 0 AND min(img) lt 0 then begin
			img -= min(img)	
		endif


		if widget_info((*pstate).menu.Correction_ScaleOverflow, /button_set) then begin
			mm = max(img)
			if mm GT (*pstate).global.ccd_max then begin
				img *= ( (*pstate).global.ccd_max/float(mm) )
			
			endif
		endif


 

	;;
	;;	Apply our own scaling
	;;
		img = img > (*pstate).global.scale_min 
		img = img < (*pstate).global.scale_max 

	;;
	;;	Kill saturation
	;;
		;temp = img
		;sat = where(img gt 65500)
		;if sat[0] ne -1 then $
		;	temp[sat] = 0


	;; Automatically chop out top and bottom 0.1% extreme pixel values (hotspots)
	;; (0.1% of a 1kx1k CD = 1000 pixels)		
		h = histogram(img, min=0, max=(*pstate).global.ccd_max,/L64)
		h[0] = 0
		t = total(h,/cum,/int)
		hi = where(t gt 0.999*max(t))
		hi = min(hi)
		lo = where(t lt 0.001*max(t))
		lo = max(lo)
		
		if hi gt lo+255 then begin
			img = img < hi
			img = img > lo
		endif

		return, img
end
