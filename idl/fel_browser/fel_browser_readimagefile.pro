;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


;;
;;	Small program to read in the actual image file
;;	Currently a wrapper for read_tiff function
;;	It may seem like overkill to put this in a separate dedicated function
;;	But it will make life much easier if we ever need to change file formats or 
;;	deal with more than one file format at a time
;;	This way there will be only one place the code has to be changed.
;;
function fel_browser_readimagefile, pstate, filename

	;;
	;;	Check whether file exists and can be loaded
	;;
		WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Loading '+file_basename(filename)
		if query_tiff(filename) eq 0 then begin
			WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Error loading '+file_basename(filename)
			return, -1
		endif
	
	;;
	;;	Load file
	;;
		WIDGET_CONTROL, /HOURGLASS
		img = read_tiff(filename)
	
		return, img
end