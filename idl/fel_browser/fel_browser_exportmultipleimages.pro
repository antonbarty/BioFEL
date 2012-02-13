;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Export colour image to file
;;
pro fel_browser_exportmultipleimages, pstate

	if (*pstate).global.nfiles eq 0 then $
		return


	;;
	;;	Which directory?
	;;
		dir = dialog_pickfile(path=(*pstate).global.directory, /directory, title='Pick directory')
		if (dir eq '') then $
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
	;;	Loop through files
	;;
		WIDGET_CONTROL, /HOURGLASS
		for i=sel_start, sel_end do begin
		
			catch, Error_status 
			if Error_status ne 0 then begin
				continue
			endif 

		
			(*pstate).global.currentFileID = i
			WIDGET_CONTROL, (*pstate).table.files, SET_TABLE_SELECT=[-1,i,-1,i]

			;; 	Load image
			fel_browser_loadimage,pstate
			img = *((*pstate).global.image_data)
			img = float(img)

			;; Preprocess
			img = fel_browser_subtractBackground(pstate, img)
			img = fel_browser_scaleimage(pstate, img)
			img = fel_browser_imagegamma(pstate, img)
			loadct, (*pstate).global.colour_table, /silent

			crop = 1		
			if crop then begin
				s = size(img,/dim)
				ss = max(s)
				c = (*pstate).global.img_centre
				cx = s[0]*c[0]
				cy = s[1]*c[1]
				nn = ss/2
				img = img[cx-nn/2:cx+nn/2,cy-nn/2:cy+nn/2 ]
			endif


			;;	Filename
			filename = dir+'img_'+file_basename((*(*pstate).global.filenames)[i])
			print, filename

			;;	Can we write the file?
			openw, fp, filename, /get, error=err
			if err ne 0 then begin
				r = dialog_message(!error_state.msg)
				return
			endif
			close, fp
			free_lun, fp
		

			;;	Write file
			idl_write_tiff, filename, img
	
		endfor

end