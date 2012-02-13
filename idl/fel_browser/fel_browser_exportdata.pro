;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Export floating point data for analysis
;;
pro fel_browser_exportdata, pstate, float=float, uint16=uint16, int16=int16, int32=int32, h5=h5

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

		if sel_start eq sel_end then $
			single = 1 $
		else $
			single = 0



	;;
	;;	Dialog box for parameters
	;;
		form_desc=[ '1, BASE,, ROW', $
					'1, BASE,, COLUMN, FRAME', $
					'0, LABEL, File format(s), left', $
					'2, BUTTON, TIFF (float)|TIFF (UINT16)|TIFF (INT16)|TIFF (INT32)|HDF5, tag=fileformat', $
					'1, BASE,, COLUMN, FRAME', $
					'0, LABEL, Data export options, left', $
					'2, BUTTON, Background subtract|Hard beamstop|Soft beamstop|Suppress saturation|Shift image centre|Crop to best FFT size, tag=options', $
					;'0, INTEGER, 1024, label_left=Image size, tag=nx', $
					'1, BASE,,column', $
					'0, BUTTON, OK, QUIT, tag=ok', $
					'2, BUTTON, Cancel, QUIT' $
				  ]

		form = cw_form(form_desc, title='cw_form', /column)
		if form.ok ne 1 then $
			return

	;;
	;;	Which file formats?
	;;
		if form.fileformat[0] eq 1 then float=1
		if form.fileformat[1] eq 1 then uint16=1
		if form.fileformat[2] eq 1 then int16=1
		if form.fileformat[3] eq 1 then int32=1
		if form.fileformat[4] eq 1 then hdf5=1
		

	;;
	;;	Which directory or file for output?
	;;
		if keyword_set(single) then begin
			filename = dialog_pickfile(path=(*pstate).global.directory, /write)
			if (filename eq '') then $
				return
		endif else begin
			dir = dialog_pickfile(path=(*pstate).global.directory, /directory, title='Pick directory')
			if (dir eq '') then $
				return
		endelse



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
				fel_browser_loadimage,pstate
				data = float((*(*pstate).global.image_data))
				s = size(data,/dim)
		
			;;
			;;	Background subtract
			;;
				if form.options[0] eq 1 then begin 
					data = fel_browser_subtractBackground(pstate, data)
				endif
	
			;;
			;;	Hard beamstop
			;;
				if form.options[1] eq 1 then begin 
					mask = fel_browser_beamstopmask(pstate)
					data *= mask
				endif
	
			;;
			;;	Soft beamstop
			;;
				if form.options[2] eq 1 then begin 
					mask = fel_browser_beamstopmask(pstate,/soft)
					data *= mask
				endif
	
			;;
			;;	Suppress saturation
			;;
				if form.options[3] eq 1 then begin 
					saturated = where(data gt 65500.)
					if saturated[0] ne -1 then $
						data[saturated] = 0
				endif
	
			;;
			;;	Shift image centre
			;;
				if form.options[4] eq 1 then begin 
					centre = (*pstate).global.img_centre 
					cx = s[0] * float(centre[0])
					cy = s[1] * float(centre[1])
					dx = s[0]/2 - cx
					dy = s[1]/2 - cy
					data = shift(data, dx, dy)
				endif
		
		
			;;
			;; Crop to next best FFT size
			;;
				if form.options[5] eq 1 then begin
					i=0
					n = min([s[0],s[1]])
					while (2^i le n) do i++
					n = 2^(i-1)
					data = data[(s[0]-n)/2:((s[0]+n))/2-1,(s[1]-n)/2:((s[1]+n))/2-1] 
				endif
		
		
			;;
			;;	Image save filename
			;;
				if NOT keyword_set(single) then begin
					filename = (*(*pstate).global.filenames)[i]
					filename = file_basename(filename)
					;stub = strmid(filename,0,strpos(filename,'A_'))
					;stub = strmid(filename,0,strlen(filename)-strlen((*pstate).setup.filefilter)+1)
					stub = strmid(filename,0,strlen(filename)-4)
					stub = stub + '_merged'
					filename = dir+stub
				endif
				print, filename

			;;
			;;	test whether we can write the file?
			;;	(Used to prevent crash in runtime mode if directory does not exist or is write protected)
			;;
				openw, fp, filename, /get, error=err
				if err ne 0 then begin
					r = dialog_message(!error_state.msg)
					return
				endif
				close, fp
				free_lun, fp
				file_delete, filename, /quiet

			;;
			;;	Write data
			;;  Floating point TIFF
			;;
				if keyword_set(float) then begin
					write_tiff,filename+'.tif', data, /float
				endif 

			;; UINT16 TIFF
			if keyword_set(uint16) then begin
				write_tiff,filename+'.tif', fix(data>0, type=12), /short
			endif 

			;; INT16 TIFF
			if keyword_set(int16) then begin
				write_tiff,filename+'.tif', fix(data, type=2), /short, /signed
			endif 

			;; INT32 TIFF
			if keyword_set(int32) then begin
				write_tiff,filename+'.tif', fix(data, type=3), /long, /signed
			endif 

		
			;; HDF5
			if keyword_set(hdf5) then begin
				write_h5, filename+'.h5', data
			
				;fid = H5F_CREATE(filename+'.h5') 
				;creator = 'fel_browser'
				;datatype_id = H5T_IDL_CREATE(creator) 
				;dataspace_id = H5S_CREATE_SIMPLE(size(creator,/DIMENSIONS)) 
				;dataset_id = H5D_CREATE(fid,'creator',datatype_id,dataspace_id) 
				;H5D_WRITE,dataset_id,data 
				;H5D_CLOSE,dataset_id   
				;H5S_CLOSE,dataspace_id 
				;H5T_CLOSE,datatype_id 
	
				;datatype_id = H5T_IDL_CREATE(data) 
				;group_id = H5G_CREATE(fid, 'data')
				;dataspace_id = H5S_CREATE_SIMPLE(size(data,/DIMENSIONS)) 
				;dataset_id = H5D_CREATE(fid,'data/data',datatype_id,dataspace_id) 
				;H5D_WRITE,dataset_id,data 
				;H5D_CLOSE,dataset_id   
				;H5S_CLOSE,dataspace_id 
				;H5T_CLOSE,datatype_id 
				;H5G_CLOSE,group_id
				;H5F_CLOSE,fid 
			endif 
		
		;; Default (floating point TIFF)
		;else $
		;	write_tiff,filename, data, /float
		
	endfor
end

