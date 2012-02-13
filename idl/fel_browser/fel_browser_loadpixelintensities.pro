;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Procedure to select current working directory
;;
pro fel_browser_loadpixelintensities, pstate

	;; Select the file
		file = dialog_pickfile(filter='*.tif', path=(*pstate).global.directory)
		if (file eq '') then begin
			buttonstate = widget_info((*pstate).menu.Correction_intensities , /button_set)
			if NOT ptr_valid((*pstate).global.pixelIntensityMap) AND buttonstate eq 1 then $
				widget_control, (*pstate).menu.Correction_intensities, set_button=0
			return
		endif
		if query_tiff(file, info) eq 0 then begin
			WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Error loading '+filename
			return
		endif
		WIDGET_CONTROL, /HOURGLASS


	;; Load the file 
		intensityMap = read_tiff(file)
		
		
	;; Store intensity map in memory
		if ptr_valid((*pstate).global.pixelIntensityMap) then $
			ptr_free, (*pstate).global.pixelIntensityMap
		(*pstate).global.pixelIntensityMap = ptr_new(intensityMap, /no_copy)					
end

