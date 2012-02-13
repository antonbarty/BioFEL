;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Export colour image to file
;;
pro fel_browser_exportimage, pstate

	if (*pstate).global.nfiles eq 0 then $
		return

	filename = dialog_pickfile(path=(*pstate).global.directory, /write)
	if (filename eq '') then $
		return


	img = float((*(*pstate).global.image_data))
	s = size(img,/dim)

	img = fel_browser_subtractBackground(pstate, img)
	img = fel_browser_scaleimage(pstate, img)
	img = fel_browser_imagegamma(pstate, img)

	loadct, (*pstate).global.colour_table, /silent

	;;
	;;	Can we write the file?
	;;
		openw, fp, file_basename(filename), /get, error=err
		if err ne 0 then begin
			r = dialog_message(!error_state.msg)
			return
		endif
		close, fp
		free_lun, fp
		
	idl_write_tiff, filename, img
end

