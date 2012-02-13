;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Export floating point data for analysis
;;
pro fel_browser_sumdata, pstate

	if (*pstate).global.nfiles eq 0 then $
		return

	;;
	;;	Which files are currently selected?
	;;
		selection = widget_info((*pstate).table.files, /table_select)
		if (selection[0] eq -1) then $
			return
		sel_start = selection[1]
		sel_end = selection[3]

	;;
	;;	Blank variable for running sum
	;;
		s = size((*(*pstate).global.image_data),/dim)
		sum = fltarr(s[0],s[1])


	;;
	;;	Loop through all selected files
	;;
		WIDGET_CONTROL, /HOURGLASS
		for i=sel_start, sel_end do begin
		
			;;
			;; Error trap
			;;	If something bad happens, continue with next loop
			;;
				catch, Error_status 
				if Error_status ne 0 then begin
					continue
				endif 

			;;
			;; 	Load ith data file
			;;
				(*pstate).global.currentFileID = i
				WIDGET_CONTROL, (*pstate).table.files, SET_TABLE_SELECT=[-1,i,-1,i]
				fel_browser_loadimage, pstate, /quiet
		
		
			;;
			;; Keep running sum
			;;
				temp = *(*pstate).global.image_data
				sum = sum + temp
		
		
			;;
			;;	Store the sum back into data variable and display it
			;;
				ptr_free, (*pstate).global.image_data
				(*pstate).global.image_data = ptr_new(sum)					
				fel_browser_preview, pstate

		endfor

		fel_browser_displayfull, pstate

end

