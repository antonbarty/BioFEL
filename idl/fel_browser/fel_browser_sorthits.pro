;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;


pro fel_browser_sorthitsfile
	;;
	;; Select file to load
	;;
		filename = dialog_pickfile()	
		if (filename eq '') then $
			return

	;;
	;; Read in filename list (one file per line)
	;;
		a = read_ascii(filename, delimiter=',', comment='#')

		nlines = file_lines(filename)
		data = strarr(nlines)
		hitval = fltarr(nlines)

		openr, lun, filename, /get
		readf,lun, data
		close,lun
		free_lun, lun


	;;
	;;	Extract the hit values...
	;;
		for i=0LL, n_elements(data)-1 do begin
			substring = strsplit(data[i],',',/extract)

			if strmid(substring[0],0,1) eq '#' then $
				hitval[i] = 0 $
			else $
				hitval[i] = float(substring[2])
		endfor

	;;
	;;	Sort it so that best hits come first
	;;
		s = sort(hitval)
		s = reverse(s)
		
		
	;;
	;;	Write out filename
	;;
		openw, lun, filename+'_sorted', /get

		counter = 0
		for i=0LL, nlines-1 do $
			printf, lun, data[s[i]]		
		
		close,lun
		free_lun, lun
	
end


;;
;;	Procedure to load a filename list from ASCII file
;;	Very basic - can be made fancier later on
;;
pro fel_browser_sorthits, pstate, file=file

	;;
	;;	Sorting an existing file?
	;;	If so call another routine
	;;
		if keyword_set(file) then begin
			fel_browser_sorthitsfile
			return
		endif

	;;
	;;	Information we will need
	;;
		directory =	(*pstate).global.directory
		filenames = (*pstate).global.filenames
		metacolumns = (*pstate).global.metadata_columns		
		metadata = *(*pstate).global.metadata
		sm = size(metadata,/dim)
		hitStrength = metadata[*, metacolumns.hitStrength]
		
	;;
	;;	Sort the list by hit strength 
	;;
		hitStrength = float(hitStrength)
		s = sort(hitStrength)
		s = reverse(s)

		new_metadata = metadata
		for i=0LL, n_elements(s)-1 do begin
			new_metadata[i,*] = metadata[s[i],*]
		endfor
		filenames = directory + new_metadata[*,metacolumns.filename]

	
	;;
	;;  Re-populate table with sorted data
	;;	This is the bit that requires fully qualified path names...
	;;
		fel_browser_updatefilelist, pstate, filenames, metadata=new_metadata
		WIDGET_CONTROL, (*pstate).table.files, SET_TABLE_VIEW=[0,0]	
		WIDGET_CONTROL, (*pstate).table.files, SET_TABLE_SELECT=[-1,0,-1,0]
		(*pstate).global.currentFileID = 0

end

