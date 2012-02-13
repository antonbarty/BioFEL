;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;



pro fel_browser_displayNewWindow, pstate, img, window_title, data
	
	if n_elements(img) eq 0 then $
		return
	if n_elements(window_title) eq 0 then $
		title = 'New window'
		
	s = size(img, /dim)

	;; Open in new window
		if widget_info((*pstate).menu.Viewer_display, /button_set) then begin
			oldwin = !d.window
			window, /free, xpos=10, ypos=10, xsize=s[0], ysize=s[1], title=window_title, retain=2
			loadct, (*pstate).global.colour_table, /silent
			tvscl, img
			if oldwin ne -1 then $
				wset, oldwin
		endif $

	;; Scrolling window
		else if widget_info((*pstate).menu.Viewer_scrolling, /button_set) then begin
			fel_scrolldisplay, img, data, title=window_title
		endif $

	;; IDL iImage tool
		else if widget_info((*pstate).menu.Viewer_iImage, /button_set) then begin
			iimage, img, title=window_title, /fit_to_view, /DISABLE_SPLASH_SCREEN, /NO_SAVEPROMPT, insert_colorbar=[-0.5,-1]
		endif

end
