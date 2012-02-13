;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Export colour image to file
;;
pro fel_browser_rtheta, pstate

	;;
	;;	Retrieve image
	;;
		if (*pstate).global.nfiles eq 0 then $
			return
	
		if NOT ptr_valid((*pstate).global.image_data) then $
			return
			
		data = float((*(*pstate).global.image_data))
		s = size(data,/dim)
		nx = s[0]
		ny = s[1]
		
	;;
	;;	Create coordinate array
	;;
		xx = (xarr(nx,ny)-nx/2)
		yy = (yarr(nx,ny)-ny/2)


	;;
	;;	If the image centre is not automatically shifted to the centre of the data array
	;;	do it to the coordinate array instead
	;;
		if not widget_info((*pstate).menu.Correction_CentreInCentre , /button_set) then begin
			c = (*pstate).global.img_centre
			cx = nx*c[0]
			cy = ny*c[1]
		endif $
		else begin
			cx = nx/2
			cy = ny/2
		endelse
		dx = nx/2 - cx
		dy = ny/2 - cy
		ccd_x = xx + dx
		ccd_y = yy + dy
	
	
	;;
	;;	Convert XY to polar coordinates
	;;
		this_r = sqrt(ccd_x*ccd_x + ccd_y*ccd_y)
		this_theta = !radeg * atan(ccd_y, ccd_x) + 180 + 90
		this_theta = this_theta MOD 360
	
	
	;;
	;;	Calculate radial and angular average as 2D array in theta, r 
	;;
		n_r = ceil(max(this_r))+1
		n_theta = 360
		d_theta = 360./n_theta
		result = fltarr(n_theta, n_r)
		data = data > 0
		mm = min(data)
		replicate_inplace, result, mm
		avg = fltarr(n_r)

		WIDGET_CONTROL, /HOURGLASS
		for j=0, n_theta-1 do begin
			;; Which pixels are in this range?
			w = where(this_theta ge j*d_theta AND this_theta lt (j+1)*d_theta)
			
			;; If no matches just skip to next iteration
			if w[0] eq -1 then $
				continue
				
			;; Sort pixels by radius and average
			replicate_inplace, avg, mm
			hd = histogram(this_r[w], min=0, max=n_r, reverse_indices = ii, _extra = extra)
			for i = 1, n_elements(hd)-1 do begin
				if ii[i] NE ii[i+1] then $
					avg[i] = total(data[w[ii[ii[i]:ii[i+1]-1]]])/hd[i]
			endfor

			;; 
			result[j,*] = avg
			
		endfor
	

	;;
	;;	Display it
	;;
		img = result 
		img = fel_browser_imagegamma(pstate, img)
		filenum = (*pstate).global.currentFileID
		filename = file_basename((*(*pstate).global.filenames)[filenum])
		window_title = filename 


		fel_browser_displayNewWindow, pstate, img, window_title


end

