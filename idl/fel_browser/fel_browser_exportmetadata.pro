;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Export floating point data for analysis
;;
pro fel_browser_exportmetadata, pstate, selected=selected

	if ptr_valid((*pstate).global.metadata) eq 0 then $
		return

	;;
	;;	Save filename
	;;
		filename = dialog_pickfile(path=(*pstate).global.directory, /write)
		if (filename eq '') then $
			return

	;;
	;;	Gather metadata
	;;	
		if keyword_set(selected) then begin
			fel_browser_displaycomments, pstate, tabledata
		endif $
		else begin
			tabledata = (*(*pstate).global.metadata)
		endelse
	
	
	;;
	;;	Write to file
	;;
		openw, fp, filename, /get, error=err
		
		if err ne 0 then begin
			r = dialog_message(!error_state.msg)
			return
		endif
		
		n = size(tabledata, /dim)
		for i=0, n[0]-1 do $
			printf, fp, strjoin(reform(tabledata[i,*]),string(9B))
	
		close, fp
		free_lun, fp


end