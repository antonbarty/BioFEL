;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;



;;
;;	Create pixel map for XCam systems 
;;
pro fel_browser_createpixelmapxcam_dialog, pstate

	xt = (*pstate).global.xcam_transform
	xc = (*pstate).global.img_centre
	nmax = max([xt.nx, xt.ny])

	;;
	;;	Data input fields
	;;
		form_desc=[ '0, LABEL, Xcam pixel location transform,left', $
	
					'1, BASE,, row', $
					'2, BUTTON, Pixel location map|Quick rotation|Ewald sphere, row, set_value=1, tag=transforms', $
	
					'1, BASE,, row, frame', $
					'0, INTEGER,'+string(xt.nx)+',label_left=nx, width=10, tag=nx', $
					'0, INTEGER,'+string(xt.ny)+',label_left=ny, width=10, tag=ny', $
					'2, INTEGER,'+string(1e6*xt.dx)+',label_left=dx (um), width=10, tag=dx', $
	
					'1, BASE,, column, frame', $
					'0, LABEL, Xcam #1,left', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(1000*xt.x1_dx*nmax*xt.dx)+',label_left=x1_dx (mm), width=10, tag=x1_dx', $
					'0, FLOAT,'+string(1000*xt.x1_dy*nmax*xt.dx)+',label_left=x1_dy (mm), width=10, tag=x1_dy', $
					'2, FLOAT,'+string(xt.x1_rot)+',label_left=x1_rotation, width=10, tag=x1_rot', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(xt.x1_scale)+',label_left=Distance, width=10, tag=x1_z', $
					'2, FLOAT,'+string(xt.x1_i)+',label_left=Intensity, width=10, tag=x1_i', $
					'2, BASE,, row', $
	
					'1, BASE,, column, frame', $
					'0, LABEL, Xcam #2,left', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(1000*xt.x2_dx*nmax*xt.dx)+',label_left=x2_dx (mm), width=10, tag=x2_dx', $
					'0, FLOAT,'+string(1000*xt.x2_dy*nmax*xt.dx)+',label_left=x2_dy (mm), width=10, tag=x2_dy', $
					'2, FLOAT,'+string(xt.x2_rot)+',label_left=x2_rotation, width=10, tag=x2_rot', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(xt.x2_scale)+',label_left=Distance, width=10, tag=x2_z', $
					'2, FLOAT,'+string(xt.x2_i)+',label_left=Intensity, width=10, tag=x2_i', $
					'2, BASE,, row', $
	
					'1, BASE,, column, frame', $
					'0, LABEL, Xcam #3,left', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(1000*xt.x3_dx*nmax*xt.dx)+',label_left=x3_dx (mm), width=10, tag=x3_dx', $
					'0, FLOAT,'+string(1000*xt.x3_dy*nmax*xt.dx)+',label_left=x3_dy (mm), width=10, tag=x3_dy', $
					'2, FLOAT,'+string(xt.x3_rot)+',label_left=x3_rotation, width=10, tag=x3_rot', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(xt.x3_scale)+',label_left=Distance, width=10, tag=x3_z', $
					'2, FLOAT,'+string(xt.x3_i)+',label_left=Intensity, width=10, tag=x3_i', $
					'2, BASE,, row', $

					'1, BASE,, column, frame', $
					'0, LABEL, Image centre estimate,left', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(xc[0])+',label_left=X centre, width=10, tag=xc', $
					'0, FLOAT,'+string(xc[1])+',label_left=Y centre, width=10, tag=yc', $
					'2, BASE,, row', $
	
					'1, BASE,,row', $
					'0, BUTTON, OK, QUIT, tag=ok', $
					'2, BUTTON, Cancel, QUIT' $
				  ]
	
		form = cw_form(form_desc, title='XCam pixel location parameters', /column)
		if form.ok ne 1 then $
			return

	;;
	;;	Re-populate structure and save back into global preferences
	;;
		xt.nx = form.nx
		xt.ny = form.ny
		xt.dx = form.dx/1e6
		nmax = max([xt.nx, xt.ny])
		
		xt.x1_dx = form.x1_dx/(1e3*nmax*xt.dx)
		xt.x1_dy = form.x1_dy/(1e3*nmax*xt.dx)
		xt.x1_rot = form.x1_rot
		xt.x1_z = form.x1_z
		xt.x1_i = form.x1_i
		xt.x1_scale = 1.0
	
		xt.x2_dx = form.x2_dx/(1e3*nmax*xt.dx)
		xt.x2_dy = form.x2_dy/(1e3*nmax*xt.dx)
		xt.x2_rot = form.x2_rot
		xt.x2_z = form.x2_z
		xt.x2_i = form.x2_i
		xt.x2_scale = xt.x2_z/xt.x1_z
	
		xt.x3_dx = form.x3_dx/(1e3*nmax*xt.dx)
		xt.x3_dy = form.x3_dy/(1e3*nmax*xt.dx)
		xt.x3_rot = form.x3_rot
		xt.x3_z = form.x3_z
		xt.x3_i = form.x3_i
		xt.x3_scale = xt.x3_z/xt.x1_z
	
	;;
	;;	Save back into global structure
	;;
		(*pstate).global.xcam_transform = xt
		(*pstate).global.img_centre = [form.xc, form.yc]


end


pro fel_browser_createpixelmap_xcam, pstate, dimensions, compute=compute

	;;
	;;	Define pixel map coordinates
	;;
		if not KEYWORD_SET(compute) then begin
			fel_browser_createpixelmapxcam_dialog, pstate
			return
		endif

	;;
	;;	Compute the pixel location transform
	;;
		xt = (*pstate).global.xcam_transform

		dim = dimensions
		if n_elements(dim) eq 2 then $
			dim = [1,dim]

		nl = dim[0]
		nx = dim[1]
		ny = dim[2]
		nn = max(dim)
		xx = fltarr(3,nx,ny)
		yy = fltarr(3,nx,ny)
		ccd_x = (xarr(nx,ny)-nx/2)
		ccd_y = (yarr(nx,ny)-ny/2)

		;; Transformations for each CCD panel
		x =  cos(!dtor*xt.x1_rot)*ccd_x + sin(!dtor*xt.x1_rot)*ccd_y
		y = -sin(!dtor*xt.x1_rot)*ccd_x + cos(!dtor*xt.x1_rot)*ccd_y
		xx[0,*,*] = x*xt.x1_scale + nn*xt.x1_dx
		yy[0,*,*] = y*xt.x1_scale + nn*xt.x1_dy

		x =  cos(!dtor*xt.x2_rot)*ccd_x + sin(!dtor*xt.x2_rot)*ccd_y
		y = -sin(!dtor*xt.x2_rot)*ccd_x + cos(!dtor*xt.x2_rot)*ccd_y
		xx[1,*,*] = x*xt.x2_scale + nn*xt.x2_dx
		yy[1,*,*] = y*xt.x2_scale + nn*xt.x2_dy

		x =  cos(!dtor*xt.x3_rot)*ccd_x + sin(!dtor*xt.x3_rot)*ccd_y
		y = -sin(!dtor*xt.x3_rot)*ccd_x + cos(!dtor*xt.x3_rot)*ccd_y
		xx[2,*,*] = x*xt.x3_scale + nn*xt.x3_dx
		xx[2,*,*] = y*xt.x3_scale + nn*xt.x3_dy


		;; Reduce dimensions if needed
		xx = xx[0:nl-1,*,*]
		yy = yy[0:nl-1,*,*]
		xx = reform(xx,/over)
		yy = reform(yy,/over)
		
		

	;;
	;;	Create pixel intensity map correction
	;;
		dim = dimensions
		if n_elements(dim) eq 2 then $
			dim = [1,dim]
		
		imap = fltarr(dim[0], dim[1], dim[2])
		imap[0,*,*] = xt.x1_i
		if dim[0] ge 2 then $
			imap[1,*,*] = xt.x2_i
		if dim[0] ge 3 then $
			imap[2,*,*] = xt.x3_i

		imap = reform(imap,/over)			

	;;
	;; Order in which panels are processed
	;;
		panelOrder = [0,1,2]
		panelOrder = panelOrder[0:nl-1,*,*]

	;;
	;; Delete old pointers
	;;
		if ptr_valid((*pstate).global.pixelLocationMapX) then $
			ptr_free, (*pstate).global.pixelLocationMapX
		if ptr_valid((*pstate).global.pixelLocationMapY) then $
			ptr_free, (*pstate).global.pixelLocationMapY
		if ptr_valid((*pstate).global.pixelIntensityMap) then $
			ptr_free, (*pstate).global.pixelIntensityMap
		if ptr_valid((*pstate).global.pixelPanelOrder) then $
			ptr_free, (*pstate).global.pixelPanelOrder
	;;
	;; Remember it
	;;
		(*pstate).global.pixelLocationMapX = ptr_new(xx, /no_copy)					
		(*pstate).global.pixelLocationMapY = ptr_new(yy, /no_copy)	
		(*pstate).global.pixelPanelOrder = ptr_new(panelOrder, /no_copy)	
		(*pstate).global.pixelIntensityMap = ptr_new(imap, /no_copy)					


end