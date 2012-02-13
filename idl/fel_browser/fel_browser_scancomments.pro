;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Procedure to scan info file for comments
;;
pro fel_browser_scancomments, pstate

	WIDGET_CONTROL, /HOURGLASS
	directory =	(*pstate).global.directory
	nfiles = (*pstate).global.nfiles
	
	if nfiles eq 0 then $
		return

	metacolumns = (*pstate).global.metadata_columns		

	;;
	;;	Loop through files
	;;
	next_done = 0
	for i=0, nfiles-1 do begin
		
		;;
		;;	Can we save time and copy existing data?
		;;	Use '---' as a tag for unknown metadata
		;;
		if (*(*pstate).global.metadata)[i,metacolumns.time] eq '---' then begin		
			done = fix(100*float(i+1)/nfiles)
			if done ge next_done then begin 
				donestr = strcompress(string('( ',i,' of ',nfiles,' )'))
				message = 'Scanning for comments... '+string(done)+'%    '+donestr
				WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = message
				next_done += 1
			endif

			filename = (*(*pstate).global.filenames)[i]
			info = fel_browser_readimageheader(pstate, filename)
			
			if info.error ne -1 then begin
				(*(*pstate).global.metadata)[i,metacolumns.filename] 	= filename
				(*(*pstate).global.metadata)[i,metacolumns.time] 		= info.time
				(*(*pstate).global.metadata)[i,metacolumns.sample] 	= info.sample
				(*(*pstate).global.metadata)[i,metacolumns.position] 	= strcompress(string('(',info.sample_x,',',info.sample_y,')'),/remove_all)
				(*(*pstate).global.metadata)[i,metacolumns.comment1] = info.comment1		
				(*(*pstate).global.metadata)[i,metacolumns.exposuretime] = info.ccd_exptime			
				(*(*pstate).global.metadata)[i,metacolumns.binning] = info.ccd_binning			
				(*(*pstate).global.metadata)[i,metacolumns.ccdTemp] = info.ccd_temp	
				(*(*pstate).global.metadata)[i,metacolumns.pulsescounted] = strcompress(string(info.pulses_counted))
				(*(*pstate).global.metadata)[i,metacolumns.comment2] = info.comment2
				(*(*pstate).global.metadata)[i,metacolumns.timestamps] = info.timestamps
			endif $
			else begin
				(*(*pstate).gloabl.metadata)[i,0] = filename
				(*(*pstate).gloabl.metadata)[i,1:metacolumns.ncolumns-1] = '---'
			endelse
		endif
	endfor
	
	WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = ' '
	
	fel_browser_displaycomments, pstate
	
end

