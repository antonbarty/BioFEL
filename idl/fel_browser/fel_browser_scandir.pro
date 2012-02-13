;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


;;
;;	Procedure to rescan directory contents
;;
pro fel_browser_scandir, event
	widget_control, event.top, get_uvalue=pstate
	filter = (*pstate).setup.fileFilter

	WIDGET_CONTROL, (*pstate).text.listText1, SET_VALUE = 'Gathering filenames...'
	directory =	(*pstate).global.directory
	;filenames = file_search(directory+path_sep()+filter)
	suffix = strsplit(filter,',',/extract)
	filenames = ''
	for i=0L, n_elements(suffix)-1 do begin
		this_file_list = file_search(directory,suffix[i],/fully_qualify)
		filenames = [filenames,this_file_list]
	endfor
	
	w = where(filenames ne '')
	if w[0] eq -1 then begin
		r = dialog_message('No matching files found', /info)
		return
	endif
	
	filenames = filenames[w]
	
	IF n_elements(filenames) EQ 1 THEN IF filenames EQ '' THEN BEGIN
		r = dialog_message('No matching files found', /info)
		return
	ENDIF 

	(*pstate).global.currentFileID = (*pstate).global.nfiles-1
	fel_browser_updatefilelist, pstate, filenames
	fel_browser_loadimage, pstate
	fel_browser_displaycomments, pstate
	
end

