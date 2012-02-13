;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;



;;
;;	Create pixel map for pnCCD
;;
pro fel_browser_createpixelmappnccd_dialog, pstate

	xt = (*pstate).global.pnccd_transform
	xc = (*pstate).global.img_centre

	;;
	;;	Data input fields
	;;
		
		form_desc=[ $;'1, BASE,, row', $
					;'2, BUTTON, Pixel location map|Ewald sphere, row, set_value=1, tag=transforms', $
	
					'1, BASE,, row, frame', $
					'0, INTEGER,'+string(xt.nx)+',label_left=nx, width=10, tag=nx', $
					'0, INTEGER,'+string(xt.ny)+',label_left=ny, width=10, tag=ny', $
					'2, FLOAT,'+string(1e6*xt.dx)+',label_left=dx (um), width=10, tag=dx', $

					;'1, BASE,, row, frame', $
					;'2, Button, Ignore CCD1|Ignore CCD2, row, tag=panelusage', $
	
					'1, BASE,, column, frame', $
					'0, LABEL, pnCCD 1 (Front),left', $
					'0, button, Hide|Show, exclusive, row, set_value='+string(xt.ccd_usage[0])+', tag=panel1usage', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(1000*xt.ccd1a_sep)+',label_left=ccd1 upper split (mm), width=10, tag=x1a_sep', $
					'0, FLOAT,'+string(1000*xt.ccd1b_sep)+',label_left=ccd1 lower split (mm), width=10, tag=x1b_sep', $
					'2, BASE,, row', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(1000*xt.ccd1_dx)+',label_left=ccd1 dx (mm), width=10, tag=x1_dx', $
					'0, FLOAT,'+string(1000*xt.ccd1_dy)+',label_left=ccd1 dy (mm), width=10, tag=x1_dy', $
					'2, FLOAT,'+string(xt.ccd1_rot)+',label_left=ccd1 rotation, width=10, tag=x1_rot', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(xt.ccd1_scale)+',label_left=Magnification, width=10, tag=x1_scale', $
					'0, FLOAT,'+string(xt.ccd1_offset)+',label_left=DC offset, width=10, tag=x1_offset', $
					'2, FLOAT,'+string(xt.ccd1_i)+',label_left=Multiply, width=10, tag=x1_i', $
					'2, BASE,, row', $
	
					'1, BASE,, column, frame', $
					'0, LABEL, pnCCD 2 (Rear),left', $
					'0, button, Hide|Show, exclusive, row, set_value='+string(xt.ccd_usage[1])+', tag=panel2usage', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(1000*xt.ccd2a_sep)+',label_left=ccd2 upper split (mm), width=10, tag=x2a_sep', $
					'0, FLOAT,'+string(1000*xt.ccd2b_sep)+',label_left=ccd2 lower split (mm), width=10, tag=x2b_sep', $
					'2, BASE,, row', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(1000*xt.ccd2_dx)+',label_left=ccd2 dx (mm), width=10, tag=x2_dx', $
					'0, FLOAT,'+string(1000*xt.ccd2_dy)+',label_left=ccd2 dy (mm), width=10, tag=x2_dy', $
					'2, FLOAT,'+string(xt.ccd2_rot)+',label_left=ccd2 rotation, width=10, tag=x2_rot', $
					'1, BASE,, row', $
					'0, FLOAT,'+string(xt.ccd2_scale)+',label_left=Magnification, width=10, tag=x2_scale', $
					'0, FLOAT,'+string(xt.ccd2_offset)+',label_left=DC offset, width=10, tag=x2_offset', $
					'2, FLOAT,'+string(xt.ccd2_i)+',label_left=Multiply, width=10, tag=x2_i', $
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
	
		form = cw_form(form_desc, title='pnCCD pixel location parameters', /column)
		if form.ok ne 1 then $
			return

	;;
	;;	Re-populate structure and save back into global preferences
	;;	Everything in mm
	;;
		xt.nx = form.nx
		xt.ny = form.ny
		xt.dx = form.dx/1e6
		
		xt.ccd1_dx = form.x1_dx/1e3
		xt.ccd1_dy = form.x1_dy/1e3
		xt.ccd1_rot = form.x1_rot
		xt.ccd1_offset = form.x1_offset
		xt.ccd1_scale = form.x1_scale
		xt.ccd1_i = form.x1_i
		xt.ccd1a_sep = form.x1a_sep/1e3
		xt.ccd1b_sep = form.x1b_sep/1e3
	
		xt.ccd2_dx = form.x2_dx/1e3
		xt.ccd2_dy = form.x2_dy/1e3
		xt.ccd2_rot = form.x2_rot
		xt.ccd2_offset = form.x2_offset
		xt.ccd2_scale = form.x2_scale
		xt.ccd2_i = form.x2_i
		xt.ccd2a_sep = form.x2a_sep/1e3
		xt.ccd2b_sep = form.x2b_sep/1e3



	;;
	;;	pnCCD usage
	;;
		panelUsage = [form.panel1usage,form.panel2usage]
		xt.ccd_usage = panelUsage
		if ptr_valid((*pstate).global.pixelPanelUsage) then $
			ptr_free,(*pstate).global.pixelPanelUsage
		(*pstate).global.pixelPanelUsage = ptr_new(panelUsage)


	;;
	;;	Save back into global structure
	;;
		(*pstate).global.pnccd_transform = xt
		(*pstate).global.img_centre = [form.xc, form.yc]


end


pro fel_browser_createpixelmap_pnccd, pstate, dimensions, compute=compute

	;;
	;;	Define pixel map coordinates
	;;
		if not KEYWORD_SET(compute) then begin
			fel_browser_createpixelmappnccd_dialog, pstate
			return
		endif

	;;
	;;	Retrieve transform info
	;;
		print,'Recalculating pixel transform...'
		xt = (*pstate).global.pnccd_transform
		
	;;
	;;	Don't shrink/expand when only one panel!
	;;
		if (xt.ccd_usage[0] eq 0) then $
			xt.ccd2_scale=1
		if (xt.ccd_usage[1] eq 0) then $
			xt.ccd1_scale=1

	;;
	;;	Compute the pixel location transform
	;;
		dim = dimensions
		if n_elements(dim) eq 2 then $
			dim = [2,dim]

		nl = dim[0]
		nx = dim[1]
		ny = dim[2]
		nn = max(dim)
		xx = fltarr(2,nx,ny)
		yy = fltarr(2,nx,ny)
		ccd_x = (xarr(nx,ny)-nx/2)
		ccd_y = (yarr(nx,ny)-ny/2)

		;; Transformations for 1st CCD		
		;; Introduce split between the CCD panels --> rotate --> scale --> translate
		x = ccd_x
		y = ccd_y
		y[*,xt.nx/2:xt.nx-1] += xt.ccd1a_sep/xt.dx
		y[*,0:xt.nx/2-1] += xt.ccd1b_sep/xt.dx		
		x2 =  cos(!dtor*xt.ccd1_rot)*x + sin(!dtor*xt.ccd1_rot)*y
		y2 = -sin(!dtor*xt.ccd1_rot)*x + cos(!dtor*xt.ccd1_rot)*y
		xx[0,*,*] = xt.ccd1_scale * (x2 + xt.ccd1_dx/xt.dx)
		yy[0,*,*] = xt.ccd1_scale * (y2 + xt.ccd1_dy/xt.dx)

		;; Transformations for 1st CCD		
		;; Introduce split between the CCD panels --> rotate --> scale --> translate
		x = ccd_x
		y = ccd_y
		y[*,xt.nx/2:xt.nx-1] += xt.ccd2a_sep/xt.dx
		y[*,0:xt.nx/2-1] += xt.ccd2b_sep/xt.dx		
		x2 =  cos(!dtor*xt.ccd2_rot)*x + sin(!dtor*xt.ccd2_rot)*y
		y2 = -sin(!dtor*xt.ccd2_rot)*x + cos(!dtor*xt.ccd2_rot)*y
		xx[1,*,*] = xt.ccd2_scale * (x2 + xt.ccd2_dx/xt.dx)
		yy[1,*,*] = xt.ccd2_scale * (y2 + xt.ccd2_dy/xt.dx)


		;; Reduce dimensions if needed
		xx = xx[0:nl-1,*,*]
		yy = yy[0:nl-1,*,*]



	;;
	;;	Create pixel intensity map correction
	;;
		imap = fltarr(dim[0], dim[1], dim[2])
		imap[0,*,*] = xt.ccd1_i
		imap[1,*,*] = xt.ccd2_i


	;;
	;;	Create pixel offset map
	;;
		offsetmap = fltarr(dim[0], dim[1], dim[2])
		offsetmap[0,*,*] = xt.ccd1_offset
		offsetmap[1,*,*] = xt.ccd2_offset


	;;
	;; CCD panel ordering
	;; (CCD2 is behind CCD1) 
	;;
		panelOrder = [1,0]
		panelOrder = panelOrder[0:nl-1]
		
		
	;;
	;; CCD panel usage
	;;
		panelUsage = xt.ccd_usage
		w = where(panelUsage ne 0)
		if w[0] eq -1 then w = [0]
		
		xx = xx[w,*,*]
		yy = yy[w,*,*]
		imap = imap[w,*,*]
		offsetmap = offsetmap[w,*,*]
		panelOrder = panelOrder[w]

	;;
	;;	Deal with case of 2D input with both panels visible
	;;
		if n_elements(dim) eq 2 then begin
			xx = xx[0,*,*]
			yy = yy[0,*,*]
			imap = imap[0,*,*]
			offsetmap = offsetmap[0,*,*]
		endif


	;;
	;;	Reform dimensions
	;;
		xx = reform(xx,/over)
		yy = reform(yy,/over)
		imap = reform(imap,/over)			
		offsetmap = reform(offsetmap,/over)			
		

	;;
	;; Delete old pointers
	;;
		if ptr_valid((*pstate).global.pixelLocationMapX) then $
			ptr_free, (*pstate).global.pixelLocationMapX
		if ptr_valid((*pstate).global.pixelLocationMapY) then $
			ptr_free, (*pstate).global.pixelLocationMapY
		if ptr_valid((*pstate).global.pixelOffsetMap) then $
			ptr_free, (*pstate).global.pixelOffsetMap
		if ptr_valid((*pstate).global.pixelIntensityMap) then $
			ptr_free, (*pstate).global.pixelIntensityMap
		if ptr_valid((*pstate).global.pixelPanelUsage) then $
			ptr_free, (*pstate).global.pixelPanelUsage
		if ptr_valid((*pstate).global.pixelPanelOrder) then $
			ptr_free, (*pstate).global.pixelPanelOrder

	;;
	;; Remember it
	;;
		(*pstate).global.pixelLocationMapX = ptr_new(xx, /no_copy)					
		(*pstate).global.pixelLocationMapY = ptr_new(yy, /no_copy)					
		(*pstate).global.pixelPanelOrder = ptr_new(panelOrder, /no_copy)	
		(*pstate).global.pixelPanelUsage = ptr_new(panelUsage, /no_copy)	
		(*pstate).global.pixelIntensityMap = ptr_new(imap, /no_copy)					
		(*pstate).global.pixelOffsetMap = ptr_new(offsetmap, /no_copy)					


end