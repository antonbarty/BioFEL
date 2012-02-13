;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;



;;
;;	Pixel maps
;;
function fel_browser_pixelmaps, pstate, data, output_size

	WIDGET_CONTROL, /HOURGLASS
	s = size(data)
	
	


	;;
	;;	Subtraction of pixel offsets 
	;;
		if widget_info((*pstate).menu.Correction_CCDoffset, /button_set) then begin
	
			;; Has the pixel map been computed yet?
			if NOT PTR_VALID((*pstate).global.pixelOffsetMap) then begin
				fel_browser_createpixelmap, pstate, size(data,/dim), /compute
			endif
			
			;; Do the existing pixel map array sizes match??
			sm = size(*(*pstate).global.pixelOffsetMap)
			for i=1, s[0] do begin
				if (s[i] ne sm[i]) then begin
					fel_browser_createpixelmap, pstate, size(data,/dim), /compute
					break
				endif
			endfor
				
			;; Intensity correction is now trivial
			data -= (*(*pstate).global.pixelOffsetMap)
			data = (data > (-10))
		end



	;;
	;;	Scaling of intensities (multiplicative) using predefined intensity map
	;;
		if widget_info((*pstate).menu.Correction_intensities, /button_set) then begin
	
			;; Has the pixel map been computed yet?
			if NOT PTR_VALID((*pstate).global.pixelIntensityMap) then begin
				fel_browser_createpixelmap, pstate, size(data,/dim), /compute
			endif
			
			;; Do the existing pixel map array sizes match??
			sm = size(*(*pstate).global.pixelIntensityMap)
			for i=1, s[0] do begin
				if (s[i] ne sm[i]) then begin
					fel_browser_createpixelmap, pstate, size(data,/dim), /compute
					break
				endif
			endfor
				
			;; Intensity correction is now trivial
			data *= *(*pstate).global.pixelIntensityMap
		end
	

	
	;;
	;; Mapping of pixel locations using pre-defined pixel coordinates
	;;
		if widget_info((*pstate).menu.Correction_locations, /button_set)  then begin

			;; Has the pixel map been computed yet?
			if not ptr_valid((*pstate).global.pixelLocationMapX) OR not ptr_valid((*pstate).global.pixelLocationMapY) then begin
				fel_browser_createpixelmap, pstate, size(data,/dim), /compute
			endif
			
			;; Do the existing pixel map array sizes match??
			sm = size(*(*pstate).global.pixelLocationMapX)
			for i=1, s[0] do begin
				if (s[i] ne sm[i]) then begin
					fel_browser_createpixelmap, pstate, size(data,/dim), /compute
					break
				endif
			endfor

			;; OK - now we can actually proceed with the calculation
			xmap = *(*pstate).global.pixelLocationMapX
			ymap = *(*pstate).global.pixelLocationMapY
			order = *(*pstate).global.pixelPanelOrder
			img_nx = 2*max(abs(xmap))+2
			img_ny = 2*max(abs(ymap))+2


			;; A little fiddling is required to keep the centre pixel 
			;;	in the centre of the final composite image
			if widget_info((*pstate).menu.Correction_CentreInCentre , /button_set) then begin
				centre = (*pstate).global.img_centre
				cx = img_nx*float(centre[0])
				cy = img_ny*float(centre[1])
				dx = img_nx/2 - cx
				dy = img_ny/2 - cy
				xmap += dx
				ymap += dy
				img_nx = 2*max(abs(xmap))+2
				img_ny = 2*max(abs(ymap))+2
			endif


			;; Set border area to bottom 0.1% value of real data
			h = histogram(data, omin=omin, max=(*pstate).global.ccd_max)
			t = total(h,/cum)
			lo = where(t lt 0.01*max(t))
			lo = omin+max(lo)
			result = fltarr(img_nx,img_ny)
			replicate_inplace, result, lo
			data = data > lo


			;; Or just pad with zeros...
			replicate_inplace, result, 0.


			;; Transcribe pixels into array		
			xmap += img_nx/2
			ymap += img_ny/2
			
			if s[0] eq 2 AND sm[0] eq 2 then begin
				result[xmap,ymap] = data			
			endif $
			else if s[0] eq 2 AND sm[0] gt 2 then begin
				result[xmap[0,*,*],ymap[0,*,*]] = data			
			endif $
			else begin
				for i=0, n_elements(order)-1 do begin
					result[xmap[order[i],*,*],ymap[order[i],*,*]] = data[order[i],*,*] 
				endfor
			endelse
			
			return, result
		endif





		;;	
		;; Simple rotations and translations using rotate() and shift() only
		;;
		;;if widget_info((*pstate).menu.Correction_quick, /button_set) eq 1 then begin
		if 0 eq 1 then begin
			s = size(data)
			xt = (*pstate).global.xcam_transform
			rotation = round([xt.x1_rot, xt.x2_rot, xt.x3_rot]/90.)
			xshift = [xt.x1_dx, xt.x2_dx, xt.x3_dx]
			yshift = [xt.x1_dy, xt.x2_dy, xt.x3_dy]

			;; Single 2D image will simply be returned unchanged
			if s(0) eq 2 then begin
				return, rotate(data,rotation[0])
			endif $ 
			
			;; Stack of 2D images need to be assembled into one compound image
			else if s(0) eq 3 then begin
				panel_nx = s[2]
				panel_ny = s[3]
				width = max([s[2],s[3]])
				
				left = xshift*width - panel_nx/2
				right = xshift*width + panel_nx/2
				top = yshift*width + panel_ny/2
				bottom = yshift*width - panel_ny/2
				
				image_nx = 2*max(abs([right,left]))+2
				image_ny = 2*max(abs([top,bottom]))+2
				;image_nx = max(right)-min(left)+2
				;image_ny = max(top)-min(bottom)+2
				image = lonarr(image_nx, image_ny)
				
				;h = histogram(data, min=0, max=(*pstate).global.ccd_max)
				h = histogram(data, omin=omin, max=(*pstate).global.ccd_max)
				t = total(h,/cum)
				lo = where(t lt 0.01*max(t))
				lo = omin + max(lo)
				replicate_inplace, image, lo
				data = data > lo

				;; Do the rotations and transforms
				for i=0, s[1]-1 do begin
					temp = reform(data[i,*,*])
					temp = rotate(temp,rotation[i])
					image[image_nx/2+left[i], image_ny/2+bottom[i]] = temp
				endfor

				return, image
			endif 
		endif 

		;;
		;;	Rotate one panel only
		;;
		if widget_info((*pstate).menu.Correction_quick, /button_set) eq 1 then begin
			s = size(data)
			xt = (*pstate).global.xcam_transform
			rotation = round([xt.x1_rot, xt.x2_rot, xt.x3_rot]/90.)
			if s(0) eq 2 then begin
				return, rotate(data,rotation[0])
			endif $ 
			else if s(0) eq 3 then begin
				img = fltarr(s[1]*s[2],s[3])
				for i=0, s[1]-1 do begin
					img[i*s[2],0] = rotate(reform(data[i,*,*]),rotation[i])
				endfor
				return, img
			endif 
		endif

		;;
		;; Default behaviour is trivial: multiple images are put side by side
		;;
		s = size(data)
		if s(0) eq 2 then begin
			return, data
		endif $ 
		else if s(0) eq 3 then begin
			img = fltarr(s[1]*s[2],s[3])
			for i=0, s[1]-1 do begin
				img[i*s[2],0] = reform(data[i,*,*])
			endfor
			return, img
		endif 


end


