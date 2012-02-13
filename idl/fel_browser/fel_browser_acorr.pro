;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Display Autocorrelation
;;
pro fel_browser_acorr, pstate, masked=masked, saveimage=saveimage, savedata=savedata

	if (*pstate).global.nfiles eq 0 then $
		return

	;;
	;;	Retrieve image
	;;
		WIDGET_CONTROL, /HOURGLASS
		data = float((*(*pstate).global.image_data))
		s = size(data,/dim)

	;;
	;;	Masked Autocorrelation?
	;;
		if keyword_set(masked) then begin
			;;	Beamstop mask
				mask = fel_browser_beamstopmask(pstate, /soft)
				
			;;	Kill saturation regions
				saturated = where(data gt 65530.)
				if saturated[0] ne -1 then $	
					mask[saturated] = 0
		endif $
			else mask = 1.
	

	;;
	;;	Compute autocorrelation
	;;
		WIDGET_CONTROL, (*pstate).text.preview2, SET_VALUE = 'Computing autocorrelation...'
		data = fel_browser_subtractBackground(pstate, data)
		data *= mask
		acorr = fft(data, 1)
		img = abs(acorr)
		img(0,0) = 0
		img = shift(img, s[0]/2, s[1]/2)
		
		img = fel_browser_imagegamma(pstate, img)


	;;
	;;	Display image
	;;
		filenum = (*pstate).global.currentFileID
		filename = (*(*pstate).global.filenames)[filenum]
		if keyword_set(masked) then $
			window_title = 'Masked object autocorrelation, '+filename + '  '+strcompress(string('(',s[0],'x',s[1],')'),/remove_all) $
		else $
			window_title = 'Object autocorrelation, '+filename + '  '+strcompress(string('(',s[0],'x',s[1],')'),/remove_all)

		fel_browser_displayNewWindow, pstate, img, window_title	
		WIDGET_CONTROL, (*pstate).text.preview2, SET_VALUE = '   '

	;;
	;;	Save?
	;;
		if keyword_set(saveimage) OR keyword_set(savedata) then begin
			filename = dialog_pickfile(path=(*pstate).global.directory, filter='*.tif', /write)
			if (filename eq '') then $
				return
			
			if keyword_set(saveimage) then begin
				loadct, (*pstate).global.colour_table, /silent
				idl_write_tiff,filename,img
			endif

			if keyword_set(savedata) then begin
				data /= max(data)
				write_tiff,filename,data,/float
			endif
		endif


end
