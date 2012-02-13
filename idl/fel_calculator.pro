;;
;;	FEL_Calculator
;;	Diffraction microscopy image pre-processor, optimised for use at FLASH 
;;
;;	Anton Barty 
;;	barty2 @ llnl.gov



pro fel_computeimginfo, pstate
	
	;;
	;;	Get values from fields
	;;
		widget_control, (*pstate).field.ccd_pixsize, get_value = ccd_dx
		widget_control, (*pstate).field.ccd_distance, get_value = ccd_dz
		widget_control, (*pstate).field.fft_arraysize, get_value = ccd_nx
		widget_control, (*pstate).field.wavelength, get_value = lambda

	;;
	;;	Compute pixel size
	;;	(Based on calculations in xewald_computepixsize.pro)
	;;
		df = (1e-3*ccd_dx/ccd_dz)/lambda
		dx = 1.0/(df*ccd_nx)

	;;
	;;	Set result fields
	;;
		WIDGET_CONTROL, (*pstate).field.img_pixsize, SET_VALUE=dx
		WIDGET_CONTROL, (*pstate).field.img_width, SET_VALUE=(ccd_nx*dx)/1000.
		WIDGET_CONTROL, (*pstate).field.img_objsize, SET_VALUE=(ccd_nx*dx/2)/1000.

end



;;
;;	Main event processing loop begins here
;;
pro FEL_calculator_event, event

	;help,event,/str
	widget_control, event.top, get_uvalue=pstate

	case event.ID of 
		;;
		;;	Change in energy or wavelength
		;;
			(*pstate).field.wavelength : begin
				widget_control, (*pstate).field.wavelength, get_value = wl
				wl = 1e-9*wl
				ev = (4.14e-15 * 3e8)/wl
				widget_control, (*pstate).field.energy, set_value = ev
				fel_computeimginfo, pstate
			end
			
			(*pstate).field.energy : begin
				widget_control, (*pstate).field.energy, get_value = en
				wl = (4.14e-15 * 3e8)/en
				wl_nm = 1e9*wl
				widget_control, (*pstate).field.wavelength, set_value = wl_nm
				fel_computeimginfo, pstate
			end

		;;
		;;	Change in ccd pixel value fields
		;;
			(*pstate).field.ccd_pixsize : fel_computeimginfo, pstate
			(*pstate).field.ccd_distance : fel_computeimginfo, pstate
			(*pstate).field.fft_arraysize : fel_computeimginfo, pstate
				


		;;
		;;	Quit
		;;
			(*pstate).menu.quit : begin
				widget_control, event.top, /destroy
			end

			
		;;
		;;	default
		;;		
			else : help, event, /str 
			
	endcase
	
end


;;
;;	Cleanup dirty laundry
;;
pro FEL_calc_cleanup, topID
	print,'Quitting FEL calculator'

	widget_control, topID, get_uvalue=pstate
	ptr_free, pstate

end



;;
;;	Top-level code that sets up the main GUI interface
;;
pro FEL_calculator

	;;
	;;	Set up GUI top level with menus
	;;
		top = widget_base(title='FEL calculator', /column, mbar=bar)
		
	;;
	;;	Menu items
	;;
		m1 = widget_button(bar, value='File')
		mbq = widget_button(m1, value='Quit')
		
		menuID = {  File : m1, $
					Quit : mbq $
				 }
		


	;;
	;;	Main data entry part of the GUI
	;;
		base1 = widget_base(top, /row)
		
		
	;;
	;;	1st column
	;;
		base2 = widget_base(base1,/column)
		base2a = widget_base(base2,/column, /frame)
		f1 = cw_field(base2a, title='Wavelength (nm) ', value=13.5, xsize=10, /float, /return_events)
		f2 = cw_field(base2a, title='Energy (eV) ', value=92, xsize=10, /float, /return_events)
		

		base2b = widget_base(base2,/column, /frame)
		f3 = cw_field(base2b, title='CCD pixel size (um) ', value=20, xsize=10, /float, /return_events)
		f4 = cw_field(base2b, title='CCD distance (mm) ', value=53.02, xsize=10, /float, /return_events)
		f5 = cw_field(base2b, title='FFT array size (pix) ', value=1024, xsize=10, /float, /return_events)
		f6 = cw_field(base2b, title='Image pixel size (nm) ', value=00, xsize=10, /float, /noedit)
		f7 = cw_field(base2b, title='Image width (um) ', value=00, xsize=10, /float, /noedit)
		f8 = cw_field(base2b, title='Sampled object size (um) ', value=00, xsize=10, /float, /noedit)
		

	;;
	;;	2nd column
	;;

		
	;;
	;;	Field structures
	;;
		fieldID = { wavelength: f1, $
					energy : f2, $
					
					ccd_pixsize : f3, $
					ccd_distance : f4, $
					fft_arraysize : f5, $
					img_pixsize : f6, $
					img_width : f7, $
					img_objsize : f8 $
				 }
	
	
	;;
	;;	Determine useful things such as window ID
	;;
		widget_control, top, /realize
		widget_control, top, kill_notify='FEL_calc_cleanup'


	;;
	;;	Create main state variable to hold global data structure
	;;	(this becomes (*pstate) in all functions and procedures.
	;;
		state = {	IDtop : top, $
					
					menu: menuID,  $
					field : fieldID $
				}

		pstate = ptr_new(state, /no_copy)
		widget_control, top, set_uvalue=pstate
		fel_computeimginfo, pstate
		

	
	;;
	;;	Initiate event loop
	;;
		xmanager,'FEL_calculator',top, /no_block
		
end