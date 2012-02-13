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
pro fel_browser_readfilelist, event
	widget_control, event.top, get_uvalue=pstate
	directory =	(*pstate).global.directory

	;;
	;; Select file to load
	;;
		filename = dialog_pickfile()		;;path=(*pstate).global.directory
		if (filename eq '') then $
			return

	;;
	;;	Select CSV formatting
	;;
		form_desc=[ '0, LABEL, Data in CSV format:, left', $
					'0, LABEL, comma separated value, left', $
					'0, LABEL, # denotes comment line, left', $
					'0, BUTTON, Filenames only|' + $
								'Filename; Comment|' + $
								'Filename; Hit; HitStrength' + $
								',column, exclusive, set_value=0, tag=csv_format', $
					'1, BASE,,row', $
					'0, BUTTON, OK, QUIT, tag=ok', $
					'2, BUTTON, Cancel, QUIT' $
				  ]

		form = cw_form(form_desc, title='cw_form', /column)
		if form.ok ne 1 then $
			return



	;;
	;; Read in filename list (one file per line)
	;;
		WIDGET_CONTROL, /HOURGLASS
		;a = read_ascii(filename)
		nfiles = file_lines(filename)
		data = strarr(nfiles)

		openr, lun, filename, /get
		readf,lun, data
		close,lun
		free_lun, lun

	;;
	;;	Create new metadata fields
	;;
		metacolumns = (*pstate).global.metadata_columns		
		new_metadata = strarr(nfiles, metacolumns.ncolumns)
		new_metadata[*] = '---'


	;;
	;;	In general this is a CSV file - so split data lines at every comma
	;;	Also ignore comments (denoted by a # at the start of the line)
	;;
		counter = 0LL
		for i=0LL, n_elements(data)-1 do begin
			strings = strsplit(data[i],',',/extract)
			if strmid(strings[0],0,1) eq '#' then $
				continue

			case form.csv_format of
				
				0 : begin
					new_metadata[i, metacolumns.filename] = strings[0]
					counter += 1
					end

				1 : begin
					new_metadata[i, metacolumns.filename] = strings[0]
					new_metadata[i, metacolumns.comment1] = strings[1]
					counter += 1
					end

				2 : begin
					new_metadata[i, metacolumns.filename] = strings[0]
					new_metadata[i, metacolumns.hits] = strings[1]
					new_metadata[i, metacolumns.hitStrength] = strings[2]
					widget_control, (*pstate).menu.comment_Hits, set_button=1
					widget_control, (*pstate).menu.comment_HitStrength, set_button=1
					counter += 1
					end
				
				else : begin
					new_metadata[i, metacolumns.filename] = strings[0]
					counter += 1
					end
			endcase
		endfor
		new_metadata = new_metadata[0:counter-1, *]

	;;
	;;	We need to add the directory information for everything to work fine in the next step (!)
	;;	
		filenames = directory + new_metadata[*,metacolumns.filename]
	
	;;
	;;	Set default columns to be displayed
	;;
			case form.csv_format of
				1 : begin
					widget_control, (*pstate).menu.comment_comment1, set_button=1
					widget_control, (*pstate).menu.comment_Hits, set_button=0
					widget_control, (*pstate).menu.comment_HitStrength, set_button=0
					end


				2 : begin
					widget_control, (*pstate).menu.comment_comment1, set_button=0
					widget_control, (*pstate).menu.comment_Hits, set_button=1
					widget_control, (*pstate).menu.comment_HitStrength, set_button=1
					end
				
				else : begin
					end
			endcase

	
	;;
	;; Populate browser table (as if we had just scanned a directory)
	;;	This is the bit that requires fully qualified path names...
	;;
		fel_browser_updatefilelist, pstate, filenames, metadata=new_metadata
		WIDGET_CONTROL, (*pstate).table.files, SET_TABLE_VIEW=[0,0]	
		WIDGET_CONTROL, (*pstate).table.files, SET_TABLE_SELECT=[-1,0,-1,0]
		(*pstate).global.currentFileID = 0

end

