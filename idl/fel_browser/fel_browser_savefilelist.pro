;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


;;
;;	Procedure to load a filename list from ASCII file
;;	Very basic - can be made fancier later on
;;
pro fel_browser_savefilelist, event
	widget_control, event.top, get_uvalue=pstate

	;;
	;; Select destination text file
	;;
		filename = dialog_pickfile()
		if (filename eq '') then $
			return

	;;
	;;	Files to save
	;;
		directory =	(*pstate).global.directory
		filenames = (*(*pstate).global.filenames)
		nfiles = n_elements(filenames)
		
		


	;;
	;; Write filenames to file
	;;
		openw, lun, filename, /get

		for i=0, nfiles-1 do begin
			printf, lun, filenames[i]
		endfor

		close,lun
		free_lun, lun
		
end

