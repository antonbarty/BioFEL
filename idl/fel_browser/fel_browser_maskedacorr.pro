;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


;;
;;	Display masked Autocorrelation
;;
pro fel_browser_maskedacorr, pstate

	if (*pstate).global.nfiles eq 0 then $
		return

	;;
	;;	Retrieve data
	;;
		WIDGET_CONTROL, /HOURGLASS
		data = float(*(*pstate).global.image_data)
		s = size(data,/dim)

	;;
	;;	Beamstop mask
	;;
		mask = fel_browser_beamstopmask(pstate, /soft)
		
	;;
	;;	Kill saturation regions
	;;
		saturated = where(data gt 65530.)
		if saturated[0] ne -1 then $	
			mask[saturated] = 0

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
		window_title = 'Masked object autocorrelation, '+filename + '  '+strcompress(string('(',s[0],'x',s[1],')'),/remove_all)

		fel_browser_displayNewWindow, pstate, img, window_title	
		WIDGET_CONTROL, (*pstate).text.preview2, SET_VALUE = '   '

end
