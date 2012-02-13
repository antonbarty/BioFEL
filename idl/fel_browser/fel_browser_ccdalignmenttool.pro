;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2007-2009
;;

pro fel_browser_ccdalignmenttool, pstate

	;;
	;;	Freshly load image from file, keeping data as two panels to enable 
	;;	image shifting on the fly without reloading
	;;
		directory =	(*pstate).global.directory
		filenum = (*pstate).global.currentFileID
		filename = (*(*pstate).global.filenames)[filenum]


		case (*pstate).setup.camera of
			'XCAM' : begin
				;temp = query_tiff(directory+filename, info1) 
				temp = query_image(directory+filename, info1) 
				s = info1.dimensions
				data = fel_browser_readxcam(pstate,filename)
				if (size(data))[0] eq 2 then nframes = 1 $
					else nframes = (size(data))[1]
				end
		endcase


	;;
	;;	Specify coordinates on each chip
	;;
		ss = size(data,/dim)
		nn = max(ss)
		if n_elements(ss) eq 3 then begin
			ni = ss[0]
			nx = ss[1]
			ny = ss[2]
		endif $
		else begin
			ni = 1
			nx = ss[0]
			ny = ss[1]
		endelse
		data = reform(data,ni,nx,ny)
		xx = (xarr(nx,ny)-nx/2)
		yy = (yarr(nx,ny)-ny/2)


	;;
	;;	Do a loop allowing for tweaking of position on each cycle
	;;
	done = 0
	repeat begin
	
		;;
		;;	Allow for update of current transform
		;;
			fel_browser_createpixelmap, pstate
	
	
		;;
		;;	Retrieve the current transform guesses
		;;	(make rotation in degrees, shifts in pixels)
		;;
			xt = (*pstate).global.xcam_transform
			rotation = [xt.x1_rot, xt.x2_rot, xt.x3_rot]
			xshift = nn*[xt.x1_dx, xt.x2_dx, xt.x3_dx]
			yshift = nn*[xt.x1_dy, xt.x2_dy, xt.x3_dy]
			centre = (*pstate).global.img_centre
	
			;print,'xshift = ', xshift
			;print,'yshift = ', yshift
			;print,'rotation = ', rotation
	
	
			
	
	
		;;
		;;	Calculate the coordinates of each pixel on each CCD given current 
		;;	CCD panel transform and estimated image centre
		;;
			ccd_x = fltarr(ni, nx, ny)
			ccd_y = fltarr(ni, nx, ny)
			
			for i=0, ni-1 do begin
				temp_x =  xx*cos(!dtor*rotation[i]) + yy*sin(!dtor*rotation[i])
				temp_y = -xx*sin(!dtor*rotation[i]) + yy*cos(!dtor*rotation[i])
				temp_x += xshift[i]
				temp_y += yshift[i]
	
				ccd_x[i,*,*] = temp_x
				ccd_y[i,*,*] = temp_y
			endfor
	
		;;
		;;	Correct for estimated image centre
		;;
			wx = 2*max(abs(ccd_x))
			wy = 2*max(abs(ccd_y))
			cx = wx * float(centre[0])
			cy = wy * float(centre[1])
			dx = wx/2 - cx
			dy = wy/2 - cy
	
			ccd_x += dx
			ccd_y += dy
	
		;;
		;;	Convert to polar coordinates
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
			mm = min(data)
			replicate_inplace, result, mm
			avg = fltarr(n_r)
			
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
	
			display, result[*,0:800]^0.2
			
		;;
		;;	End on this cycle?
		;;
			form_desc=[ '0, LABEL, Are we there yet?, left', $
						'1, BASE,,row', $
						'0, BUTTON, Try again, QUIT, tag=ok', $
						'2, BUTTON, Let me out of here, QUIT' $
					  ]
	
			form = cw_form(form_desc, title='cw_form', /column)
			if form.ok ne 1 then $
				done = 1

			
	endrep until done 
end