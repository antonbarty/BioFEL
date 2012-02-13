;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Display image full-size
;;
pro fel_browser_displayfull, pstate

	if (*pstate).global.nfiles eq 0 then $
		return

	WIDGET_CONTROL, /HOURGLASS
	data = float((*(*pstate).global.image_data))
	filenum = (*pstate).global.currentFileID
	filename = (*(*pstate).global.filenames)[filenum]
	s = size(data,/dim)

	window_title = filename + '  '+strcompress(string('(',s[0],'x',s[1],')'),/remove_all)

	img = fel_browser_subtractBackground(pstate, data)
	img = fel_browser_scaleimage(pstate, img)
	img = fel_browser_imagegamma(pstate, img)
	fel_browser_displayNewWindow, pstate, img, window_title, data
	
end

