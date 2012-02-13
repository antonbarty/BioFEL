;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Display data
;;
pro fel_browser_reconstruct_display, pstate, centre=centre, fit=fit

	oldwin = !d.window
	xview = (*pstate).window.xview
	;;
	;;	Display diffraction pattern in 1st window
	;;
		if widget_info((*pstate).button.data_showbackground, /button_set) then $
			data = *(*pstate).global.background_data $
		else $
			data = *(*pstate).global.image_data 
		s = size(data, /dim)

		wset,(*pstate).window.dataW
		izoom = (*pstate).global.image_zoom
		new_nx = fix(s[0]*izoom)
		new_ny = fix(s[1]*izoom)
		expand, data, new_nx, new_ny, img
		;img = congrid(data, s[0]*zoom, s[1]*zoom)
		img = bytscl(img^0.2)
		widget_control, (*pstate).window.dataWindow, draw_xsize=new_nx 
		widget_control, (*pstate).window.dataWindow, draw_ysize=new_ny
		tv, img
		if keyword_set (centre) then $
			widget_control, (*pstate).window.dataWindow, SET_DRAW_VIEW=[(new_nx-xview)/2, (new_ny-xview)/2]
	

	;; 
	;;	Display either autocorrelation or support in 2nd window
	;;
		if widget_info((*pstate).button.acorr_acorr, /button_set) then $
			data = *(*pstate).global.acorr_data $
		else $
		if widget_info((*pstate).button.acorr_importedsupport, /button_set) then begin
			if ptr_valid((*pstate).global.user_support) then $
				data = *(*pstate).global.user_support $
			else $
				data = bytarr(s[0],s[1])
			data = congrid(data, s[0],s[1])
		endif $
		else $
			data = *(*pstate).global.support_data
		s = size(data, /dim)

		wset,(*pstate).window.supportW
		izoom = (*pstate).global.acorr_zoom
		new_nx = fix(s[0]*izoom)
		new_ny = fix(s[1]*izoom)
		expand, data, new_nx, new_ny, img
		;img = congrid(data, s[0]*zoom, s[1]*zoom)
		img = bytscl(img^0.2)
		widget_control, (*pstate).window.supportWindow, draw_xsize=new_nx
		widget_control, (*pstate).window.supportWindow, draw_ysize=new_nx
		tv, img
		if keyword_set (centre) then $
			widget_control, (*pstate).window.supportWindow, SET_DRAW_VIEW=[(new_nx-xview)/2, (new_ny-xview)/2]
	
	;;
	;;	Reset window
	;;
		if oldwin ne -1 then $
			wset, oldwin
end


;;
;;	Compute support
;;
pro fel_browser_reconstruct_makesupport, pstate

	WIDGET_CONTROL, /HOURGLASS

	;; Get sutocorrelation data
		widget_control, (*pstate).form.recon, get_value=form
		acorr = *(*pstate).global.acorr_data 
		m = max(acorr)
		s = size(acorr,/dim)
		support = fltarr(s[0],s[1])


	
	;;	Ceiling threshold
		widget_control,(*pstate).slider.SupportCeiling, GET_VALUE=thresh
		thresh /= 100.
		above = where(acorr gt thresh*max(acorr))
		if above[0] ne -1 then $
			acorr[above] = 0
	
	;; Floor threshold
		widget_control,(*pstate).slider.SupportFloor, GET_VALUE=thresh
		thresh /= 100.
		above = where(acorr gt thresh*max(acorr))
		if above[0] ne -1 then $
			support[above] = 1

	;; Fixed window
		if form.window ne 0 then begin
			mask = bytarr(s[0],s[1])
			mask[(s[0]-form.window)/2:(s[0]+form.window)/2,(s[0]-form.window)/2:(s[0]+form.window)/2] = 1
			support *= mask
		end
	
	;; Keep central dot
		;support[s[0]/2-1:s[0]/2+1,s[1]/2-1:s[1]/2+1] = 1

	;; Remember it	
		if ptr_valid( (*pstate).global.support_data) then $
			ptr_free, (*pstate).global.support_data			
		(*pstate).global.support_data = ptr_new(support, /no_copy)

end

;;
;;	Process diffraction pattern
;;
pro fel_browser_reconstruct_dataprocess, pstate, acorr=acorr

	;;
	;;	Process data
	;;
		WIDGET_CONTROL, /HOURGLASS
		data = float(*(*pstate).global.originaldata)
		felb_pstate = (*pstate).parent
		widget_control, (*pstate).form.recon, get_value=form
		s = size(data,/dim)
		background = fltarr(s[0],s[1])


		;; Remove hotspots
		;; 0.1% extreme pixel values (0.1% of a 1kx1k CD = 1000 pixels)		
		if widget_info((*pstate).menu.Process_hotspots1, /button_set) then begin 
			h = histogram(data, min=0, max=65525)
			t = total(h,/cum)
			hi = where(t gt 0.999*max(t))
			hi = min(hi)
			lo = where(t lt 0.001*max(t))
			lo = max(lo)
			if hi gt lo+255 then begin
				data = data < hi
				data = data > lo
			endif
		
		
		endif
		

		;; Remove saturation
		if widget_info((*pstate).menu.Process_SaturationSuppress, /button_set)  then begin 
			widget_control,(*pstate).slider.saturation, GET_VALUE=thresh
			saturated = where(data gt thresh)
			if saturated[0] ne -1 then $
				data[saturated] = 0
		endif
		if widget_info((*pstate).menu.Process_SaturationSuppressSoft, /button_set)  then begin 
			widget_control,(*pstate).slider.saturation, GET_VALUE=thresh
			saturated = where(data gt thresh)

			if saturated[0] ne -1 then begin 
				data[saturated] = 0
				mask = fltarr(s[0],s[1])
				mask[*] = 1
				mask[saturated] = 0
				mask = smooth(mask, 10)
				data *= mask
			endif
			
		endif


		;;	Background image subtract
		if widget_info((*pstate).menu.Process_BackgroundSubtract, /button_set)  then begin 
			widget_control,(*pstate).slider.BGsmoothing, GET_VALUE=BGsmooth
			widget_control,(*pstate).slider.BGimagescale, GET_VALUE=BGscale
			BGscale = float(BGscale)/100
			BGsmooth *= 2
			
			data = fel_browser_subtractBackground(felb_pstate, data, background=background, scale=BGscale, smooth=BGsmooth)
			data = data > 0
		end


		;;	Remove column defects
		if widget_info((*pstate).menu.Process_RemoveColumnDefects, /button_set) then begin 
			r1 = total(data[*,0:10],2)
			r2 = total(data[*,s[1]-10:s[1]-1],2)
			m1 = 2*median(r1)
			m2 = 2*median(r2)
			columns = where(r1 gt m1 AND r2 gt m2)
			mask = bytarr(s[0],s[1])
			mask[*] = 1
			mask[columns,*] = 0
			data *= mask
		endif


		;;	Adaptive background subtract
		if widget_info((*pstate).menu.Process_AdaptiveBackgroundSubtract, /button_set)  then begin 
			widget_control,(*pstate).slider.AdaptiveBG, GET_VALUE=value
			if value ne 0 then begin
				i=0
				repeat i++ until 2^i gt s[0]
				i -= 1
				kernel = (2^(i-value)) > 8
				bg = bg_sub(data, kernel)
				w = where(data le 0)
				data -= bg
				if w[0] ne -1 then $
					data[w] = 0
				background += bg
			endif
		end

		
		;;	Constant background subtract
		if widget_info((*pstate).menu.Process_ConstBackgroundSubtract, /button_set)  then begin 
			widget_control,(*pstate).slider.ConstantBG, GET_VALUE=BGlevel
			widget_control,(*pstate).slider.ConstantBGwidth, GET_VALUE=BGwidth
			widget_control,(*pstate).slider.ConstantBGheight, GET_VALUE=BGheight
			
			r = dist(s[0],s[1])
			r /= min([s[0],s[1]])
			r = shift(r, s[0]/2,s[1]/2)
			constantBG = BGheight*exp(-(BGwidth*r)^2) + BGlevel
			
			data = (data - constantBG) > 0 
			background += constantBG
		end

		;;	Hard beamstop
		if widget_info((*pstate).menu.Process_HardBeamstop, /button_set)  then begin 
			mask = fel_browser_beamstopmask(felb_pstate)
			data *= mask
		endif

		;;	Soft beamstop
		if widget_info((*pstate).menu.Process_SoftBeamstop, /button_set)  then begin 
			mask = fel_browser_beamstopmask(felb_pstate,/soft)
			data *= mask
		endif

						

		;;	Shift image centre
		if widget_info((*pstate).menu.Process_CentreShift, /button_set)  then begin 
			centre = (*felb_pstate).global.img_centre 
			cx = s[0] * float(centre[0])
			cy = s[1] * float(centre[1])
			dx = s[0]/2 - cx
			dy = s[1]/2 - cy
			data = shift(data, dx, dy)
		endif
		

		;; 	Median
			widget_control,(*pstate).slider.median, GET_VALUE=median
			if median ne 0 then begin
				data = median(data,median+1)
			endif

		;; 	Denoise
		if widget_info((*pstate).menu.Process_denoise, /button_set)  then begin 
			widget_control,(*pstate).slider.denoise, GET_VALUE=denoise
			if denoise ne 0 then begin
				r = denoise*2+1
				d = dist(r)
				d = shift(d, r/2, r/2)
				kernel = exp(-(4*d/denoise)^2)
				temp = convol(data,kernel, invalid=0, missing=0, /normalize)
				data = temp			
			endif
		endif		



		;;
		;;	Enforce data window
		;;
		if form.cropwindow ne 0 then begin
			ss = size(data,/dim)
			if ss[0] gt form.cropwindow and ss[1] gt form.cropwindow then begin
				data = data[((ss[0]-form.cropwindow)/2)>0:((ss[0]+form.cropwindow)/2-1)<(ss[0]-1),((ss[1]-form.cropwindow)/2)>0:((ss[1]+form.cropwindow)/2-1)<(ss[1]-1)]
			endif
		end


		;;
		;; Crop to next best FFT size
		;;
		if widget_info((*pstate).menu.Process_FFTcrop, /button_set)  then begin 
			ss = size(data,/dim)
			i=0
			n = min([ss[0],ss[1]])
			while (2^i le n) do i++
			n = 2^(i-1)
			data = data[(ss[0]-n)/2:((ss[0]+n))/2-1,(ss[1]-n)/2:((ss[1]+n))/2-1] 
			str = strcompress(string('Cropped to: ',n,' x ',n))
			widget_control, (*pstate).label.FFTcrop, set_value = str
		endif




		;;
		;;	Fill missing data with radial average
		;;
		if widget_info((*pstate).menu.Process_RadialInterpolate, /button_set)  then begin 
			ss = size(data,/dim)
			d = dist(ss[0],ss[1])
			d = shift(d,ss[0]/2,ss[1]/2)
			
			w_missing = where(data le 0, complement=w_data)
			if w_missing[0] ne -1 then begin
				
				hd = histogram(d[w_data], min=0, max=ceil(max(d)), reverse_indices = ii, _extra = extra)
				avg = hd*0.
				for i = 1, n_elements(hd)-1 do begin
					if ii[i] NE ii[i+1] then $
						avg[i] = total(data[w_data[ii[ii[i]:ii[i+1]-1]]])/hd[i]
				endfor
	
				data[w_missing] = avg[round(d[w_missing])]
			endif
			
		endif

	;;
	;;	Autocorrelation
	;;
		if keyword_set(acorr) then begin
			temp = sqrt(data > 0)
			acorr = fft(temp, 1)
			acorr = abs(acorr)
			acorr(0,0) = 0
			ss = size(temp,/dim)
			acorr = shift(acorr, ss[0]/2, ss[1]/2)

			;;	Smooth ?
			widget_control,(*pstate).slider.AcorrSmoothing, GET_VALUE=value
			if value ne 0 then $
				acorr = smooth(acorr, value)


			if ptr_valid((*pstate).global.acorr_data) then $
				ptr_free,(*pstate).global.acorr_data			
			(*pstate).global.acorr_data = ptr_new(acorr, /no_copy)
			fel_browser_reconstruct_makesupport, pstate
		endif

	;;
	;;	Save data back in pstate variables
	;;
		if ptr_valid( (*pstate).global.image_data) then $
			ptr_free, (*pstate).global.image_data			
		(*pstate).global.image_data = ptr_new(data, /no_copy)

		if ptr_valid( (*pstate).global.background_data) then $
			ptr_free, (*pstate).global.background_data			
		(*pstate).global.background_data = ptr_new(background, /no_copy)

	;;
	;;	Display it
	;;
		fel_browser_reconstruct_display, pstate
end

;;
;;	Reconstruction
;;
pro fel_browser_reconstruct_reconstruct, pstate, stop=stop

	;;
	;;	Data
	;;
		data = float(*(*pstate).global.image_data)

		if widget_info((*pstate).button.acorr_importedsupport, /button_set) then $
			support = *(*pstate).global.user_support $
		else $
			support = float(*(*pstate).global.support_data)

		s = size(data,/dim)
		widget_control, (*pstate).form.recon, get_value=form

		
	;;
	;;	Populate shrinkwrap2d structure
	;;
;;		info = shrinkwrap2d(/str)
		
		info.method = form.algorithm+1
		info.beta = form.beta
		info.erfreq = form.er_freq

		info.sw = 1
		info.swstart = form.sw_start
		info.swthresh = form.sw_thresh
		info.swfreq = form.sw_freq
		info.swradius = form.sw_radius
		info.swmaxradius = form.sw_radius
		info.swminradius = form.sw_minimum
		info.swdecay = form.sw_decay
		info.swsum = form.options[0]
		info.positive = form.options[1]
		info.quadrant = form.options[2]
		info.real = form.options[3]
		info.zerosfloat = 1-form.options[4]
		fftw = form.options[6]
		
		

	;;
	;;	Reconfigure data
	;;
		downsample = form.downsample
		if downsample ne 1 then begin
			data = rebin(data, s[0]/downsample, s[1]/downsample)
			support = support[(s[0]-s[0]/downsample)/2:(s[0]+s[0]/downsample)/2-1, (s[0]-s[0]/downsample)/2:(s[0]+s[0]/downsample)/2-1]
		endif
		s = size(data,/dim)	
		data = shift(data, s[0]/2, s[1]/2)
		data = sqrt(data > 0)
		support = shift(support, s[0]/2, s[1]/2)

		if form.window ne 0 then begin
			mask = bytarr(s[0],s[1])
			mask[(s[0]-form.window)/2:(s[0]+form.window)/2,(s[0]-form.window)/2:(s[0]+form.window)/2] = 1
			mask = shift(mask, s[0]/2, s[1]/2)
		endif $
		else begin
			mask = bytarr(s[0],s[1])
			mask[*] = 1
		endelse
			


		guess = fft(data,-1)
		guess = abs(guess)
		seed = long(systime(1) MOD 65535)
		phase = randomn(seed, s[0],s[1])
		guess = complex(guess*cos(phase),guess*sin(phase))
		guess *= support

		
	;;
	;;	Stop?
	;;
		if keyword_set(stop) then begin
			data = float(*(*pstate).global.image_data)
			support = float(*(*pstate).global.support_data)
			acorr = *(*pstate).global.acorr_data 
			print,'>----------------------<'
			print,'Pausing in command line: '
			print,'Variables are: data, support, acorr'			
			;;stop
		end

		
		
	;;
	;;	New window
	;;
		parent = (*pstate).parent
		filenum = (*parent).global.currentFileID
		filename = (*(*parent).global.filenames)[filenum]
		title = 'Shrinkwrap on '+filename

		window,0,xsize=512,ysize=512, title=title
		window,1,xsize=512,ysize=300, title=title
		
		
	;;
	;;	Reconstruction
	;;
;;		r = shrinkwrap2d(data, info, support_in=support, guess=guess, sw_mask=mask, fftw=fftw)
		;;stop
end



;;
;;	Reconstruction event handler
;;
pro fel_browser_reconstruct_event, event

	;help,event,/str
	widget_control, event.top, get_uvalue=pstate
	parent = (*pstate).parent

	case event.ID of 

		;;
		;;	Sliders
		;;
			(*pstate).slider.Saturation : begin
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).slider.BGimagescale : begin
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).slider.BGsmoothing : begin
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).slider.ConstantBG : begin
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).slider.ConstantBGwidth : begin
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).slider.ConstantBGheight : begin
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).slider.AdaptiveBG : begin
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).slider.Denoise : begin
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).slider.Median : begin
				fel_browser_reconstruct_dataprocess, pstate
			end


			(*pstate).slider.SupportCeiling : begin
				fel_browser_reconstruct_makesupport, pstate
				fel_browser_reconstruct_display, pstate
			end
			(*pstate).slider.SupportFloor : begin
				fel_browser_reconstruct_makesupport, pstate
				fel_browser_reconstruct_display, pstate
			end
			(*pstate).slider.AcorrSmoothing : begin
				;fel_browser_reconstruct_makesupport, pstate
				;fel_browser_reconstruct_display, pstate
			end

		;;
		;;	Buttons
		;;
			(*pstate).button.acorr_recalculate : begin
				fel_browser_reconstruct_dataprocess, pstate, /acorr			
			end
			(*pstate).button.reconstruct : begin
				fel_browser_reconstruct_reconstruct, pstate
			end

			(*pstate).button.pointnclick : begin
				data = *(*pstate).global.acorr_data 
				img = (data>0)^0.25
				;;support,img
				loadct, 4, /silent
			end


		;;
		;;	Toggling between views
		;;
			(*pstate).button.acorr_acorr : begin
				fel_browser_reconstruct_display, pstate, /centre
			end
			(*pstate).button.acorr_support : begin
				fel_browser_reconstruct_display, pstate, /centre
			end

			(*pstate).button.data_showdata : begin
				fel_browser_reconstruct_dataprocess, pstate
				fel_browser_reconstruct_display, pstate, /centre
			end
			(*pstate).button.data_showbackground : begin
				fel_browser_reconstruct_dataprocess, pstate
				fel_browser_reconstruct_display, pstate, /centre
			end
			

		;;
		;;	Zooming
		;;
			(*pstate).button.data_zoomout : begin
				(*pstate).global.image_zoom *= 0.9
				fel_browser_reconstruct_display, pstate, /centre
			end
			(*pstate).button.data_zoomin : begin
				(*pstate).global.image_zoom *= 1.11
				(*pstate).global.image_zoom = (*pstate).global.image_zoom < 2
				fel_browser_reconstruct_display, pstate, /centre
			end
			(*pstate).button.data_zoomreset : begin
				(*pstate).global.image_zoom = 1
				fel_browser_reconstruct_display, pstate, /centre
			end
			(*pstate).button.data_zoomfullscreen : begin
				xview = (*pstate).window.xview
				s = size(*(*pstate).global.image_data, /dim)
				(*pstate).global.image_zoom = 1.1*float(xview)/s[0]
				;widget_control, (*pstate).window.dataWindow, SET_DRAW_VIEW=[1,1]
				fel_browser_reconstruct_display, pstate, /centre
			end

			(*pstate).button.acorr_zoomout : begin
				(*pstate).global.acorr_zoom *= 0.9
				fel_browser_reconstruct_display, pstate, /centre
			end
			(*pstate).button.acorr_zoomin : begin
				(*pstate).global.acorr_zoom *= 1.11
				(*pstate).global.acorr_zoom = (*pstate).global.acorr_zoom < 2
				fel_browser_reconstruct_display, pstate, /centre
			end
			(*pstate).button.acorr_zoomreset : begin
				(*pstate).global.acorr_zoom = 1
				fel_browser_reconstruct_display, pstate, /centre
			end
			(*pstate).button.acorr_zoomfullscreen : begin
				xview = (*pstate).window.xview
				s = size(*(*pstate).global.acorr_data, /dim)
				(*pstate).global.acorr_zoom = 1.1*float(xview)/s[0]
				;widget_control, (*pstate).window.supportWindow, SET_DRAW_VIEW=[1,1]
				fel_browser_reconstruct_display, pstate, /centre
			end


		;;
		;;	Define beamstop and beam centre
		;;
			(*pstate).menu.Tool_definebeamstop : begin
				fel_browser_definebeamstop, parent
				fel_browser_reconstruct_dataprocess, pstate
			end

			(*pstate).menu.Tool_definebeamcentre : begin
				fel_browser_definebeamcentre, parent
				fel_browser_reconstruct_dataprocess, pstate
			end

			(*pstate).menu.Tool_calculator : begin
				fel_calculator
			end


		;;
		;;	Selection of processing options
		;;
			(*pstate).menu.Process_BackgroundSubtract : begin
				state = widget_info((*pstate).menu.Process_BackgroundSubtract, /button_set)
				widget_control, (*pstate).menu.Process_BackgroundSubtract, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_ConstBackgroundSubtract : begin
				state = widget_info((*pstate).menu.Process_ConstBackgroundSubtract, /button_set)
				widget_control, (*pstate).menu.Process_ConstBackgroundSubtract, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_AdaptiveBackgroundSubtract : begin
				state = widget_info((*pstate).menu.Process_AdaptiveBackgroundSubtract, /button_set)
				widget_control, (*pstate).menu.Process_AdaptiveBackgroundSubtract, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_Denoise : begin
				state = widget_info((*pstate).menu.Process_Denoise, /button_set)
				widget_control, (*pstate).menu.Process_Denoise, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_HardBeamstop : begin
				state = widget_info((*pstate).menu.Process_HardBeamstop, /button_set) 
				widget_control, (*pstate).menu.Process_HardBeamstop, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_SoftBeamstop : begin
				state = widget_info((*pstate).menu.Process_SoftBeamstop, /button_set)
				widget_control, (*pstate).menu.Process_SoftBeamstop, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_SaturationSuppress : begin
				state = widget_info((*pstate).menu.Process_SaturationSuppress, /button_set)
				widget_control, (*pstate).menu.Process_SaturationSuppress, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_SaturationSuppressSoft : begin
				state = widget_info((*pstate).menu.Process_SaturationSuppressSoft, /button_set)
				widget_control, (*pstate).menu.Process_SaturationSuppressSoft, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_CentreShift : begin
				state = widget_info((*pstate).menu.Process_CentreShift, /button_set)
				widget_control, (*pstate).menu.Process_CentreShift, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_FFTcrop : begin
				state = widget_info((*pstate).menu.Process_FFTcrop, /button_set)
				widget_control, (*pstate).menu.Process_FFTcrop, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_RemoveColumnDefects : begin
				state = widget_info((*pstate).menu.Process_RemoveColumnDefects, /button_set)
				widget_control, (*pstate).menu.Process_RemoveColumnDefects, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_RemoveRowDefects : begin
				state = widget_info((*pstate).menu.Process_RemoveRowDefects, /button_set)
				widget_control, (*pstate).menu.Process_RemoveRowDefects, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_Hotspots1 : begin
				state = widget_info((*pstate).menu.Process_Hotspots1, /button_set)
				widget_control, (*pstate).menu.Process_Hotspots1, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end
			(*pstate).menu.Process_RadialInterpolate : begin
				state = widget_info((*pstate).menu.Process_RadialInterpolate, /button_set)
				widget_control, (*pstate).menu.Process_RadialInterpolate, set_button=1-state
				fel_browser_reconstruct_dataprocess, pstate
			end

						




		;;
		;;	Update data to current selection in browser
		;;
			(*pstate).menu.file_update : begin
				filenum = (*parent).global.currentFileID
				filename = (*(*parent).global.filenames)[filenum]
				title = 'Image reconstruction ('+filename+')'
				widget_control, event.top, base_set_title=title
			
				data = float((*(*parent).global.image_data))
				if ptr_valid((*pstate).global.data) then $
					ptr_free,(*pstate).global.data
				(*pstate).global.data = ptr_new(data)
				
				fel_browser_reconstruct_dataprocess, pstate, /acorr
			end
			
			(*pstate).button.data_loadnew : begin
				filenum = (*parent).global.currentFileID
				filename = (*(*parent).global.filenames)[filenum]
				title = 'Image reconstruction ('+filename+')'
				widget_control, event.top, base_set_title=title
			
				data = float((*(*parent).global.image_data))
				if ptr_valid((*pstate).global.data) then $
					ptr_free,(*pstate).global.data
				(*pstate).global.data = ptr_new(data)
				
				fel_browser_reconstruct_dataprocess, pstate, /acorr
			
			end


		;;
		;;	Export data
		;;
			(*pstate).menu.Export_dataData_TIFFfloat : begin
				data = float(*(*pstate).global.image_data)
				file = dialog_pickfile(title='Select a TIFF filename to save', filter='*.tif')
				if file eq '' then return
				write_tiff, file, data, /float 
			end

			(*pstate).menu.Export_dataData_TIFFuint16 : begin
				data = float(*(*pstate).global.image_data)
				file = dialog_pickfile(title='Select a TIFF filename to save', filter='*.tif')
				if file eq '' then return
				temp = fix(data > 0, type=12)
				write_tiff, file, temp, /short
			end

			(*pstate).menu.Export_acorrData : begin
				acorr = *(*pstate).global.acorr_data 
				file = dialog_pickfile(title='Select a TIFF filename to save', filter='*.tif')
				if file eq '' then return
				write_tiff, file, acorr, /float
			end


			(*pstate).menu.file_exportTIFF : begin
				data = float(*(*pstate).global.image_data)
				support = float(*(*pstate).global.support_data)
				acorr = *(*pstate).global.acorr_data 

				file = (*pstate).global.datafile
				file = strmid(file, 0, strlen(file)-5)
				file = dialog_pickfile(title='Select a base filename to save', file=file)
				if file eq '' then return
				
				write_tiff,file+'_data.tif',data,/float
				write_tiff,file+'_acorr.tif',acorr,/float
				write_tiff,file+'_support.tif',byte(support)
				
			end


			(*pstate).menu.file_exportHDF5 : begin
				data = float(*(*pstate).global.image_data)
				raw_data = float(*(*pstate).global.data)
				background_data = float(*(*pstate).global.background_data)
				support = *(*pstate).global.support_data
				acorr = *(*pstate).global.acorr_data 
				names = ['data','raw_data','background_data','support','autocorrelation']
				
				file = (*pstate).global.datafile
				file = strmid(file, 0, strlen(file)-5)
				file = dialog_pickfile(title='Select a base filename to save', file=file)
				if file eq '' then return
				
				file_delete, file, /quiet
				fid = H5F_CREATE(file) 
		
				datatype1_id = H5T_IDL_CREATE(data) 
				dataspace1_id = H5S_CREATE_SIMPLE(size(data,/DIMENSIONS)) 
				dataset1_id = H5D_CREATE(fid,'data',datatype1_id,dataspace1_id) 
				H5D_WRITE,dataset1_id,data
				H5D_CLOSE,dataset1_id   
				H5S_CLOSE,dataspace1_id 
				H5T_CLOSE,datatype1_id 

				datatype2_id = H5T_IDL_CREATE(raw_data) 
				dataspace2_id = H5S_CREATE_SIMPLE(size(raw_data,/DIMENSIONS)) 
				dataset2_id = H5D_CREATE(fid,'raw_data',datatype2_id,dataspace2_id) 
				H5D_WRITE,dataset2_id,raw_data
				H5D_CLOSE,dataset2_id   
				H5S_CLOSE,dataspace2_id 
				H5T_CLOSE,datatype2_id 

				datatype3_id = H5T_IDL_CREATE(background_data) 
				dataspace3_id = H5S_CREATE_SIMPLE(size(background_data,/DIMENSIONS)) 
				dataset3_id = H5D_CREATE(fid,'background_data',datatype3_id,dataspace3_id) 
				H5D_WRITE,dataset3_id,background_data
				H5D_CLOSE,dataset3_id   
				H5S_CLOSE,dataspace3_id 
				H5T_CLOSE,datatype3_id 
				
				datatype4_id = H5T_IDL_CREATE(support) 
				dataspace4_id = H5S_CREATE_SIMPLE(size(support,/DIMENSIONS)) 
				dataset4_id = H5D_CREATE(fid,'support',datatype4_id,dataspace4_id) 
				H5D_WRITE,dataset4_id,support
				H5D_CLOSE,dataset4_id   
				H5S_CLOSE,dataspace4_id 
				H5T_CLOSE,datatype4_id 

				datatype5_id = H5T_IDL_CREATE(acorr) 
				dataspace5_id = H5S_CREATE_SIMPLE(size(acorr,/DIMENSIONS)) 
				dataset5_id = H5D_CREATE(fid,'autocorreation',datatype5_id,dataspace5_id) 
				H5D_WRITE,dataset5_id,acorr
				H5D_CLOSE,dataset5_id   
				H5S_CLOSE,dataspace5_id 
				H5T_CLOSE,datatype5_id 

				
				H5F_CLOSE,fid 
				
			end


		;;
		;;	Export pictures
		;;
			(*pstate).menu.Export_dataPicture : begin
				data = float(*(*pstate).global.image_data)
				file = dialog_pickfile(title='Select a TIFF filename to save', filter='*.tif')
				if file eq '' then return
				idl_write_tiff, file, data^0.2 
			end

			(*pstate).menu.Export_acorrPicture : begin
				acorr = *(*pstate).global.acorr_data 
				file = dialog_pickfile(title='Select a TIFF filename to save', filter='*.tif')
				if file eq '' then return
				idl_write_tiff, file, acorr^0.2
			end

			(*pstate).menu.Export_supportPicture : begin
				support = float(*(*pstate).global.support_data)
				file = dialog_pickfile(title='Select a filename to save', filter='*.tif')
				if file eq '' then return
				write_tiff, file, bytscl(support)
			end


			(*pstate).menu.file_Saveparameters : begin

			end


			(*pstate).button.Writepaper : begin
				r = dialog_message('You have to be kidding...')
			end

		;;
		;;	Imported support
		;;
			(*pstate).menu.File_importsupport : begin
				file = dialog_pickfile(title='Select a support file', filter='*.tif')
				if file eq '' then return
				user_support = read_tiff(file)
				if ptr_valid( (*pstate).global.user_support) then $
					ptr_free, (*pstate).global.user_support			
				(*pstate).global.user_support = ptr_new(user_support, /no_copy)
			end

			(*pstate).button.acorr_importedsupport : begin
				if widget_info((*pstate).button.acorr_importedsupport, /button_set) then begin
					if NOT ptr_valid((*pstate).global.user_support) then begin
						
						file = dialog_pickfile(title='Select a support file', filter='*.tif')
						if file eq '' then return
						user_support = read_tiff(file)
						if ptr_valid( (*pstate).global.user_support) then $
							ptr_free, (*pstate).global.user_support			
						(*pstate).global.user_support = ptr_new(user_support, /no_copy)
					endif
	
					fel_browser_reconstruct_display, pstate, /centre
				endif
			end


		;;
		;;	Reconstruction form data
		;;
			(*pstate).form.recon : begin
			end


		;;
		;;	Halt
		;;
			(*pstate).menu.File_Halt : begin
				fel_browser_reconstruct_reconstruct, pstate, /stop
			end
			(*pstate).menu.Tool_Halt : begin
				fel_browser_reconstruct_reconstruct, pstate, /stop
			end

		;;
		;;	Quit 
		;;
			(*pstate).menu.quit : begin
				widget_control, event.top, /destroy
			end
			(*pstate).button.quit : begin
				widget_control, event.top, /destroy
			end


		;;
		;;	Nothing found
		;;
			else : begin
				help, event, /str 
			endelse

	endcase
	
end

;;
;;	Cleanup routines
;;
pro fel_browser_reconstruct_cleanup, topID
	print,'Quitting Reconstruciton GUI'

	widget_control, topID, get_uvalue=pstate
	
	ptr_free, (*pstate).global.data
	ptr_free, (*pstate).global.image_data
	ptr_free, (*pstate).global.acorr_data
	ptr_free, (*pstate).global.support_data
	ptr_free, (*pstate).global.background_data
	
	ptr_free, pstate
end


;;
;;	Reconstruciton GUI
;;
pro fel_browser_reconstruct, pstate, title=title, datafile=datafile

	if (*pstate).global.nfiles eq 0 then $
		return


	;;
	;;	Trick version of how to do reconstructions :-)
	;;
		trick = 0
		if trick then begin	
			form_desc=[ '0, LABEL, Please enter the following information, left', $
						'0, DROPLIST, Visa|Mastercard|EC Karte, label_left=Card type, tag=card', $
						'0, INTEGER, , label_left=Card number, width=20, tag=cardnumber', $
						'0, TEXT, ,label_left=Expiration date, width=20, tag=exp_date', $
						'0, INTEGER, , label_left=Security code, width=5, tag=securitycode', $
						'0, TEXT, ,label_left=E-mail address, width=40, tag=email', $
						
						'1, BASE,,row', $
						'0, BUTTON, OK, QUIT, tag=ok', $
						'2, BUTTON, Cancel, QUIT' $
					  ]
			form = cw_form(form_desc, title='Reconstruction parameters', /column)
			if form.ok ne 1 then $
				return
			result = dialog_message('Thank you!')
			return
		endif 

	;;
	;;	Real version begins here
	;;	Create a new widget to pre-process data 
	;;

	
		;;
		;;	Base widget
		;;
			filenum = (*pstate).global.currentFileID
			filename = (*(*pstate).global.filenames)[filenum]
			title = 'Image reconstruction ('+filename+')'

			top = WIDGET_BASE(title=title, GROUP=GROUP, /ROW, mbar=bar, /TLB_SIZE_EVENTS)
			WIDGET_CONTROL, /MANAGED, top
	
		;;
		;;	Size to make images
		;;
			data = float((*(*pstate).global.image_data))
			s = size(data,/dim)
			screensize = get_screen_size()
			xview = min([512,s[0],s[1]])

		;;
		;;	Menu bars
		;;
			mbfile = widget_button(bar, value='File')
			mbfile3 = widget_button(mbfile, value='Import current fel_browser image')
			mbfile12 = widget_button(mbfile, value='Import user support')
			mbfile_g = widget_button(mbfile, value='Reconstruct')
			mbfile2 = widget_button(mbfile, value='Halt')		
			mbfile_q = widget_button(mbfile, value='Quit')

			mbexport = widget_button(bar, value='Export')
			mbfile5 = widget_button(mbexport, value='Export data picture')
			mbfile6 = widget_button(mbexport, value='Export autocorrelation picture')
			mbfile7 = widget_button(mbexport, value='Export calculated support picture')
			mbfile8 = widget_button(mbexport, value='Export prepared diffraction data (float TIFF)',/separator)
			mbfile10 = widget_button(mbexport, value='Export prepared diffraction data (UINT16 TIFF)')
			mbfile9 = widget_button(mbexport, value='Export calculated autocorrelation data')
			mbfile1 = widget_button(mbexport, value='Export all data (TIFF)',/separator)
			mbfile11 = widget_button(mbexport, value='Export all data (HDF5)')
			mbfile4 = widget_button(mbexport, value='Save parameters')

			mbtool = widget_button(bar, value='Tools')
			mbtool_2 = widget_button(mbtool, value='Define beamstop')
			mbtool_3 = widget_button(mbtool, value='Define beam centre')
			mbtool_4 = widget_button(mbtool, value='Calculator',/separator)		
			mbtool1 = widget_button(mbtool, value='Halt')		
	
			mbprocess = widget_button(bar, value='Pre-processing')
			mbprocess10 = widget_button(mbprocess, value='Crop to best FFT size (next power of 2)', /checked)	
			mbprocess13 = widget_button(mbprocess, value='Kill hotspots (top and bottom 0.1% of pixels)', /checked)	
			mbprocess1 = widget_button(mbprocess, value='Subtract background image (fel_browser background)', /checked)		
			mbprocess7 = widget_button(mbprocess, value='Subtract constant background', /checked)		
			mbprocess8 = widget_button(mbprocess, value='Subtract adaptive background', /checked)	
			mbprocess_14 = widget_button(mbprocess, value='Interpolate with radial average', /checked)	
			mbprocess9 = widget_button(mbprocess, value='Denoise', /checked)		
			mbprocess2 = widget_button(mbprocess, value='Hard beamstop', /checked)		
			mbprocess3 = widget_button(mbprocess, value='Soft beamstop', /checked)		
			mbprocess4 = widget_button(mbprocess, value='Hard saturation suppress', /checked)		
			mbprocess6 = widget_button(mbprocess, value='Soft saturation suppress', /checked)		
			mbprocess5 = widget_button(mbprocess, value='Shift image centre', /checked)	
			mbprocess11 = widget_button(mbprocess, value='Remove column defects', /checked)	
			mbprocess12 = widget_button(mbprocess, value='Remove row defects', /checked)				
			WIDGET_CONTROL, mbprocess1, set_button=1
			WIDGET_CONTROL, mbprocess2, set_button=0
			WIDGET_CONTROL, mbprocess3, set_button=1
			WIDGET_CONTROL, mbprocess4, set_button=0
			WIDGET_CONTROL, mbprocess6, set_button=1
			WIDGET_CONTROL, mbprocess7, set_button=1
			WIDGET_CONTROL, mbprocess8, set_button=1
			WIDGET_CONTROL, mbprocess10, set_button=1
			WIDGET_CONTROL, mbprocess13, set_button=1
			if NOT widget_info((*pstate).Menu.Correction_CentreInCentre, /button_set) then $
				WIDGET_CONTROL, mbprocess5, set_button=1



			
	
		;;
		;;	1st base, for adjusting raw data
		;;
			base1 = widget_base(top, /column, /frame)
			scroll1 = widget_draw(base1, xsize=s[0], ysize=s[1], /scroll,$
						x_scroll_size=xview, y_scroll_size=xview, $
						uvalue='SLIDE_IMAGE', expose_events=doEvents, viewport_events=doEvents)

			base1a = widget_base(base1, /row)
			button18 = widget_button(base1a, value='Grab new')
			button1 = widget_button(base1a, value='Zoom in')
			button2 = widget_button(base1a, value='Zoom out')
			button3 = widget_button(base1a, value='Zoom 1:1')
			button10 = widget_button(base1a, value='Fit')

			base1d = widget_base(base1a, /exclusive, /row)
			button14 = widget_button(base1d, value='Data')
			button15 = widget_button(base1d, value='Background')
			WIDGET_CONTROL, button14, set_button=1

			base1b = widget_base(base1, /row)
			slider1 = widget_slider(base1b, xsize=250, title='Saturation', min=0, max=65536L, value=65534L)
			slider11 = widget_slider(base1b, xsize=135, title='Background scaling', min=50, max=150, value=100)
			slider12 = widget_slider(base1b, xsize=125, title='Background smoothing', min=0, max=10, value=0)

			base1c = widget_base(base1, /row)
			slider8 = widget_slider(base1c, xsize=170,title='Median filter', min=0, max=10, value=0)
			slider5 = widget_slider(base1c, xsize=170,title='Denoise filter', min=0, max=10, value=0)
			slider7 = widget_slider(base1c, xsize=170,title='Adaptive background mesh', min=0, max=10, value=0)
			
			base1e = widget_base(base1, /row)
			slider4 = widget_slider(base1e, xsize=170,title='Constant background', min=0, max=1000, value=0)
			slider10 = widget_slider(base1e, xsize=170,title='+ Gaussian height', min=0, max=1000, value=0)
			slider9 = widget_slider(base1e, xsize=170,title='+ Gaussian width', min=0, max=50, value=0)



		;;
		;;	2nd base, for defining support
		;;
			base2 = widget_base(top, /column, /frame)
			scroll2 = widget_draw(base2, xsize=s[0], ysize=s[1], /scroll,$
						x_scroll_size=xview, y_scroll_size=xview, $
						uvalue='SLIDE_IMAGE', expose_events=doEvents, viewport_events=doEvents)

			base2a = widget_base(base2, /row)
			button4 = widget_button(base2a, value='Recalc')
			button5 = widget_button(base2a, value='Zoom in')
			button6 = widget_button(base2a, value='Zoom out')
			button7 = widget_button(base2a, value='Zoom 1:1')
			button11 = widget_button(base2a, value='Fit')

			base2b = widget_base(base2a, /exclusive, /row)
			button8 = widget_button(base2b, value='Acorr')
			button9 = widget_button(base2b, value='Support')
			button17 = widget_button(base2b, value='Imported support')
			WIDGET_CONTROL, button8, set_button=1
			

			base2b = widget_base(base2, /row)
			slider6 = widget_slider(base2b, xsize=160, title='Smoothing', min=0, max=40, value=0)
			slider3 = widget_slider(base2b, xsize=160, title='Floor', min=0, max=50, value=2)
			slider2 = widget_slider(base2b, xsize=160, title='Ceiling', min=0, max=100, value=50)
			
		;;
		;;	Space here for action buttons
		;;
			label = widget_label(base2, value='Actions', /align_left)
			base3a = widget_base(base2, /row)
			button12 = widget_button(base3a, value='Reconstruct')
			button19 = widget_button(base3a, value='Point-n-click')
			base3a = widget_base(base2, /row)
			button16 =  widget_button(base3a, value='Write paper')
			button13 = widget_button(base3a, value='Quit')

		


		;;
		;;	3rd base, inputs for reconstructions
		;;
			base3 = widget_base(top, /column, /frame)
			str1 = strcompress(string('Original size: ',s[0],' x ',s[1]))
			label1 = widget_label(base3, value = str1, /align_left)
			str2 = strcompress(string('Cropped to: ',s[0],' x ',s[1]))
			label2 = widget_label(base3, value = str2, /align_left)

			form_desc=[ '0, INTEGER, 1024, label_left=Crop to:, width=10, tag=cropwindow', $
						'0, INTEGER, 1, label_left=Pixel binning:, width=10, tag=downsample', $
						'0, INTEGER, 0, label_left=Support window, width=10, tag=window', $
						'0, DROPLIST, Error reduction|RAAR|HIO|Charge flip, label_left=Algorithm, tag=algorithm', $
						'0, FLOAT, 0.9, label_left=Beta, width=10, tag=beta', $
						'0, FLOAT, 4, label_left=SW radius, width=10, tag=sw_radius', $
						'0, FLOAT, 0.6, label_left=SW minimum, width=10, tag=sw_minimum', $
						'0, FLOAT, 0.05, label_left=SW thresh, width=10, tag=sw_thresh', $
						'0, INTEGER, 200, label_left=SW start, width=10, tag=sw_start', $
						'0, INTEGER, 100, label_left=SW freq, width=10, tag=sw_freq', $
						'0, INTEGER, 2000, label_left=SW decay, width=10, tag=sw_decay', $
						'0, INTEGER, 50, label_left=ER freq, width=10, tag=er_freq', $
						'0, BUTTON, SWsum|Im(g) > 0|Re(g) > 0 and Im(g) > 0|Im(g) = 0|Zeros float|Vortex genie|Use FFTW, column, tag=options' $
					  ]
			form1 = cw_form(base3, form_desc, /column)
			widget_control, form1, get_value=form
			form.algorithm = 2
			form.options[0] = 1
			form.options[4] = 1
 			form.options[6] = 1
			widget_control, form1, set_value=form



		;;
		;;	Create GUI
		;;
			widget_control, top, /realize
			widget_control, top, kill_notify='fel_browser_reconstruct_cleanup'
			WIDGET_CONTROL, get_value=wid1, scroll1
			WIDGET_CONTROL, get_value=wid2, scroll2


		;;
		;;	Collect together all the widget IDs	
		;;	
			menuID = { 	File : mbfile, $
						File_update : mbfile3, $
						File_exportTIFF : mbfile1, $
						File_exportHDF5 : mbfile11, $
						File_saveparameters : mbfile4, $
						File_importsupport : mbfile12, $
						File_go : mbfile_g, $
						File_halt : mbfile2, $
						Quit : mbfile_q, $
						
						Export_dataPicture : mbfile5, $
						Export_acorrPicture : mbfile6, $
						Export_supportPicture : mbfile7, $
						Export_dataData_TIFFfloat : mbfile8, $
						Export_dataData_TIFFuint16 : mbfile10, $
						Export_acorrData : mbfile9, $

						Tool : mbtool, $
						Tool_DefineBeamstop : mbtool_2, $
						Tool_DefineBeamCentre : mbtool_3, $
						Tool_Calculator : mbtool_4, $
						Tool_Halt : mbtool1, $

						Process : mbprocess, $
						Process_BackgroundSubtract : mbprocess1, $
						Process_ConstBackgroundSubtract : mbprocess7, $
						Process_AdaptiveBackgroundSubtract : mbprocess8, $
						Process_Denoise : mbprocess9, $
						Process_HardBeamstop : mbprocess2, $
						Process_SoftBeamstop : mbprocess3, $
						Process_SaturationSuppress : mbprocess4, $
						Process_SaturationSuppressSoft : mbprocess6, $
						Process_CentreShift : mbprocess5, $
						Process_FFTcrop : mbprocess10, $
						Process_RemoveColumnDefects : mbprocess11, $
						Process_RemoveRowDefects : mbprocess12, $
						Process_Hotspots1 : mbprocess13, $
						Process_RadialInterpolate : mbprocess_14 $
					}
				
			buttonID= {	data_zoomin : button1, $
						data_zoomout : button2, $
						data_zoomreset : button3, $
						data_zoomfullscreen : button10, $
						data_showdata : button14, $
						data_showbackground : button15, $
						data_loadnew : button18, $

						acorr_acorr : button8, $
						acorr_support : button9, $
						acorr_recalculate : button4, $
						acorr_zoomin : button5, $
						acorr_zoomout : button6, $
						acorr_zoomreset : button7, $
						acorr_zoomfullscreen : button11, $
						acorr_importedsupport : button17, $
						
						reconstruct : button12, $
						writepaper : button16, $
						pointnclick : button19, $
						quit : button13 $
					}

			slideID = { Saturation : slider1, $
						BGimagescale : slider11, $
						BGsmoothing : slider12, $
						ConstantBG : slider4, $
						ConstantBGwidth : slider9, $
						ConstantBGheight : slider10, $
						AdaptiveBG : slider7, $
						Denoise : Slider5, $
						Median : Slider8, $
						SupportCeiling : slider2, $
						SupportFloor : slider3, $
						AcorrSmoothing : slider6 $
					}
	
			windowID = { DataWindow : scroll1, $
						SupportWindow : scroll2, $
						DataW : wid1, $
						SupportW : wid2, $
						xview : xview $
					}
					
			formID = { recon : form1 }
			
			labelID = {	FFTcrop : label2 }
			
		;;
		;;	Global variables
		;;
			global = {  data : ptr_new(), $
						originaldata : ptr_new(), $
						image_data : ptr_new(), $
						acorr_data : ptr_new(), $
						support_data : ptr_new(), $
						user_support : ptr_new(), $
						background_data : ptr_new(), $
						image_zoom : 1.1*float(xview)/s[0], $
						acorr_zoom : 1.1*float(xview)/s[0], $
						datafile : filename $
					}
			datacopy = data
			global.data = ptr_new(data)
			global.originaldata = ptr_new(datacopy)
	



		;;
		;;	Info structure
		;;
			State = { 	parent : pstate, $
						menu : menuID, $
						button : buttonID, $
						slider : slideID, $
						window : windowID, $	
						form : formID, $
						label : labelID, $
						
						global : global $
					 }

			this_pstate = ptr_new(state, /no_copy)
			widget_control, top, set_uvalue=this_pstate

	
		;;
		;;	Populate window
		;;
			fel_browser_reconstruct_dataprocess, this_pstate, /acorr
			fel_browser_reconstruct_display, this_pstate, /centre
			

			;WIDGET_CONTROL, scroll1, SET_DRAW_VIEW=[(s[0]-xview)/2, (s[0]-xview)/2]
			;WIDGET_CONTROL, scroll2, SET_DRAW_VIEW=[(s[0]-xview)/2, (s[0]-xview)/2]
	
			XMANAGER, 'fel_browser_reconstruct', top, event='fel_browser_reconstruct_event', /NO_BLOCK
	
end
