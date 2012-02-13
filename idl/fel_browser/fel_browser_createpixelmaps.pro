;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;



;;
;;	Pixel maps
;;
pro fel_browser_createpixelmaps, pstate

	xt = (*pstate).global.xcam_transform
	xc = (*pstate).global.img_centre
	nmax = max([xt.nx, xt.ny])

	;;
	;;	Data input fields
	;;
		form_desc=[ '0, LABEL, Xcam pixel location transforms,left', $
	
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
	
		form = cw_form(form_desc, title='Pixel location parameters', /column)
		if form.ok ne 1 then $
			return

	;;
	;;	Re-populate structure
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
	
		(*pstate).global.xcam_transform = xt

		(*pstate).global.img_centre = [form.xc, form.yc]
	
	;;
	;;	Create the transform for each CCD panel
	;;
		;WIDGET_CONTROL, /HOURGLASS
		;rescale = 4
		;transform_nx = xt.nx/rescale
		;transform_ny = xt.ny/rescale
		;ccd_x = rescale*(xarr(transform_nx,transform_ny)-transform_nx/2)/nmax
		;ccd_y = rescale*(yarr(transform_nx,transform_ny)-transform_ny/2)/nmax
		
		;x1 = complex(ccd_x,ccd_y)
		;x1 *= xt.x1_scale
		;x1 *= complex(cos(!dtor*xt.x1_rot),sin(!dtor*xt.x1_rot))
		;x1 += complex(xt.x1_dx, xt.x1_dy)

		;x2 = complex(ccd_x,ccd_y)
		;x2 *= xt.x2_scale
		;x2 *= complex(cos(!dtor*xt.x2_rot),sin(!dtor*xt.x2_rot))
		;x2 += complex(xt.x2_dx, xt.x2_dy)
		
		;x3 = complex(ccd_x,ccd_y)
		;x3 *= xt.x3_scale
		;x3 *= complex(cos(!dtor*xt.x3_rot),sin(!dtor*xt.x3_rot))
		;x3 += complex(xt.x3_dx, xt.x3_dy)
		
	;;
	;;	Create the overall transform
	;;
		;map = complexarr(3, transform_nx, transform_ny)
		;map[0,*,*] = x1
		;map[1,*,*] = x2
		;map[2,*,*] = x3

	;;
	;;	Remember pixel location map
	;;
		;if ptr_valid((*pstate).global.pixelLocationMap) then $
		;	ptr_free, (*pstate).global.pixelLocationMap
		;(*pstate).global.pixelLocationMap = ptr_new(map, /no_copy)					


	;;
	;;	Also create a basic pixel intensity map
	;;	We can add more here later.
	;;
		imap = fltarr(3, xt.nx, xt.ny)
		imap[0,*,*] = xt.x1_i
		imap[1,*,*] = xt.x2_i
		imap[2,*,*] = xt.x3_i

		if ptr_valid((*pstate).global.pixelIntensityMap) then $
			ptr_free, (*pstate).global.pixelIntensityMap
		(*pstate).global.pixelIntensityMap = ptr_new(imap, /no_copy)					


end


