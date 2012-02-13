;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2007-2009
;;

pro fel_browser_remove_pnCCDcmm, data
	; removes background following Rick Kirian's method
	; which is remove median along rows
	; and then remove median along colums
	; for each subtile of the CCD
	
	ntx = 2
	nty = 8
	
	nx = n_elements(data[*, 0])
	ny = n_elements(data[0, *])
	IF (nx NE 1024) OR (ny NE 1024) THEN BEGIN
		message, 'Data array not 1024 x 1024', /inform
		return
	ENDIF
	
	;loop over tiles
	FOR j = 0, nty-1 DO BEGIN
		FOR i = 0, ntx-1 DO BEGIN
			rm = median(data[i*512:(i+1)*512-1, j*128:(j+1)*128-1], dimension = 1)
			data[i*512:(i+1)*512-1, j*128:(j+1)*128-1] = $
			  data[i*512:(i+1)*512-1, j*128:(j+1)*128-1]-replicate(1, 512)#rm
			rc = median(data[i*512:(i+1)*512-1, j*128:(j+1)*128-1], dimension = 2)
			data[i*512:(i+1)*512-1, j*128:(j+1)*128-1] = $
			  data[i*512:(i+1)*512-1, j*128:(j+1)*128-1]-rc#replicate(1, 128)
		ENDFOR 
	ENDFOR 
	
	return
end


function fel_browser_readpnccd, pstate, filename

		directory =	(*pstate).global.directory		
		WIDGET_CONTROL, /HOURGLASS
		WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Loading '+filename
		
		;;
		;;	Does the requested file even exist?
			if file_test(filename,/read) eq 0 then begin
				WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Error loading '+filename
				return, uintarr(1024,1024)
			endif

		;;
		;; 	Individual events are exported to HDF5 from LCLS XTC file
		;;	One file per event
		;;	Potentially many cameras per file
		;;
			file_id = H5F_OPEN(filename) 
			dataset_id = H5D_OPEN(file_id, '/data/nframes') 
			nframes = H5D_READ(dataset_id) 
			nframes = nframes[0]
			H5D_CLOSE, dataset_id 

			if nframes eq 0 then begin
				WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'No frames in '+filename
				return, uintarr(1024,1024)
			endif


			;;
			;; Only one pnCCD frame in data set
			;;
			if nframes eq 1 then begin
				dataset_id = H5D_OPEN(file_id, '/data/data0') 
				data0 = H5D_READ(dataset_id) 
				H5D_CLOSE, dataset_id 
				H5F_CLOSE, file_id 
				return, data0
			endif $

			;;
			;; Else need to read in the additional frames
			;;
			else begin
				dataset_id = H5D_OPEN(file_id, '/data/data0') 
				data0 = H5D_READ(dataset_id) 
				H5D_CLOSE, dataset_id 
				s = size(data0, /dim)
				t = size(data0, /type)
				case t of 
					1 : data = bytarr(nframes,s[0],s[1])
					2 : data = intarr(nframes,s[0],s[1])
					3 : data = lonarr(nframes,s[0],s[1])
					4 : data = fltarr(nframes,s[0],s[1])
					5 : data = dblarr(nframes,s[0],s[1])
					12 : data = uintarr(nframes,s[0],s[1])
					13 : data = ulonarr(nframes,s[0],s[1])
					else : data = lonarr(nframes,s[0],s[1])
				endcase
				data[0,*,*] = data0
				
				for i=2, nframes do begin
					tag = strcompress(string('/data/data',i-1),/remove_all)
					dataset_id = H5D_OPEN(file_id, tag) 
					data0 = H5D_READ(dataset_id) 
					H5D_CLOSE, dataset_id 
					data[i-1,*,*] = data0
				endfor
				
				if widget_info((*pstate).menu.Correction_pnCCDcommonmode, /button_set) then begin
					temp = reform(data[0,*,*])
					fel_browser_remove_pnCCDcmm, temp
					data[0,*,*] = temp
				endif

				if ptr_valid((*pstate).global.pixelPanelUsage) then begin
					panelUsage = *(*pstate).global.pixelPanelUsage
					w = where(panelUsage ne 0)
					if w[0] eq -1 then w = [0]
					data = data[w,*,*]
					data = reform(data)
				endif

			endelse

			H5F_CLOSE, file_id 

	;;
	;;	Return value
	;;
		return, data

end