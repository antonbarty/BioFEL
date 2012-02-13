;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


;;
;;	Procedure to update the file list with new contents
;;
pro fel_browser_updatefilelist, pstate, filenames, metadata=metadata

	tableID = (*pstate).table.files
	metacolumns = (*pstate).global.metadata_columns		

	;;
	;;	Populate filename data fields
	;;
		nfiles = n_elements(filenames)
		directory = (*pstate).global.directory
		dirlen = strlen(directory)
	
	;;
	;;	Find the portion of fully qualified paths that comes after directory name
	;;
		filename_short = strmid(filenames, dirlen, 99)
		tabledata = strcompress(filename_short, /remove_all)
		tabledata = transpose(tabledata)	
	
	;;
	;;	If we are presented with metadata, use it ONLY if size and dimensions match what is needed
	;;	Else create a new, blank set of metadata.
	;;
		sm = size(metadata,/dim)
		if (n_elements(metadata) ne 0 AND sm[0] eq nfiles) then begin
			if (sm[1] eq metacolumns.ncolumns) then begin
				new_metadata = metadata
				new_metadata[*,metacolumns.filename] = filename_short
			endif
		endif $
		else begin
			new_metadata = strarr(nfiles, metacolumns.ncolumns)
			new_metadata[*,metacolumns.filename] = filename_short
			new_metadata[*,1:metacolumns.ncolumns-1] = '---'
		endelse

	;;
	;;	See whether we can copy any existing metadata by comparing filenames
	;;	(useful when refreshing a directory with lots of files)
	;;
		if ptr_valid((*pstate).global.metadata) eq 1 then begin
			old_metadata = *(*pstate).global.metadata
			s = size(old_metadata,/dim)
			
			for i=0L, min([s[0],n_elements(filename_short)])-1 do begin
				if (old_metadata[i,metacolumns.filename]) eq filename_short[i] then begin
					new_metadata[i,*] = old_metadata[i,*]
				endif 
			endfor
		endif			

	;;
	;;	Populate pstate fields
	;;
		ptr_free, (*pstate).global.filenames
		(*pstate).global.filenames = ptr_new(filename_short, /no_copy)				
		(*pstate).global.nfiles = nfiles
		(*pstate).global.currentFileID = nfiles-1

		ptr_free, (*pstate).global.metadata
		(*pstate).global.metadata = ptr_new(new_metadata, /no_copy)				



	;;
	;;	Update the table
	;;
		fel_browser_displaycomments, pstate
	
		;WIDGET_CONTROL, tableID, table_ysize = nfiles
		;WIDGET_CONTROL, tableID, table_xsize = 1
		;WIDGET_CONTROL, tableID, column_widths=[400-30]
		;WIDGET_CONTROL, tableID, column_labels = ['Filename']
		
		;WIDGET_CONTROL, tableID, SET_VALUE=tabledata
		WIDGET_CONTROL, tableID, SET_TABLE_SELECT=[-1,nfiles-1,-1,nfiles-1]
		WIDGET_CONTROL, (*pstate).table.files, SET_TABLE_VIEW=[0,max([0,nfiles-20])]	
		
		WIDGET_CONTROL, (*pstate).text.listText1, SET_VALUE = strcompress(string(nfiles) + ' files')
		WIDGET_CONTROL, (*pstate).text.listText2, SET_VALUE = ' '
end
