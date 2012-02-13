;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


;;
;;	Display what we think is the current background image
;;
pro fel_browser_displayBackgroundImage, pstate

	if NOT ptr_valid((*pstate).global.background_data) then begin
		result = dialog_message('No background image defined')
		return
	endif

	img = (*(*pstate).global.background_data)
	s = size(img,/dim)

	window_title = 'Current background image  '+strcompress(string('(',s[0],'x',s[1],')'),/remove_all)

	img = fel_browser_scaleimage(pstate, img)
	img = fel_browser_imagegamma(pstate, img)
	fel_browser_displayNewWindow, pstate, img, window_title

end

