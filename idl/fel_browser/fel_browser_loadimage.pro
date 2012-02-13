;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Load image from file
;;
pro fel_browser_loadimage, pstate, quiet=quiet

	;;
	;;	Load image from file
	;;
		directory =	(*pstate).global.directory
		filenum = (*pstate).global.currentFileID
		filename = (*(*pstate).global.filenames)[filenum]
		
		WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Loading '+file_basename(filename)
		
		case (*pstate).setup.camera of
			'RoperCCD' : begin
				;; Read in a 2D TIFF image
				if query_tiff(directory+filename) eq 0 then begin
					WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Error loading '+filename
					return
				endif
				WIDGET_CONTROL, /HOURGLASS
				data = read_tiff(directory+filename)
				s = size(data, /dim)
				nframes = 1
				end

			'XCAM' : begin
				;temp = query_tiff(directory+filename, info1) 
				temp = query_image(directory+filename, info1) 
				if (temp eq 0) then begin
					WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Error loading '+filename
					return
				endif
				s = info1.dimensions
				data = fel_browser_readxcam(pstate,filename)
				if (size(data))[0] eq 2 then nframes = 1 $
					else nframes = (size(data))[1]
				end


			'pnCCD' : begin
				WIDGET_CONTROL, /HOURGLASS
				data = fel_browser_readpnccd(pstate, directory+filename)
				if (size(data))[0] eq 2 then begin
					nframes = 1
					s = size(data,/dim)
				endif else begin
					nframes = (size(data))[1]
					s = (size(data))[2:3]
				endelse
				end

			'cspad' : begin
				WIDGET_CONTROL, /HOURGLASS
				data = read_h5(directory+filename)
				s = size(data,/dim)
				nframes = 1				
				end


			'HDF5' : begin
				WIDGET_CONTROL, /HOURGLASS
				data = read_h5(directory+filename)
				s = size(data,/dim)
				nframes = 1				
				end


			'XCAM_3D' : begin
				;; Read in a 2D or layered 3D TIFF image
				;; Place into a flat 2D array ready to display on screen
				if query_tiff(directory+filename, info) eq 0 then begin
					WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Error loading '+filename
					return
				endif
				WIDGET_CONTROL, /HOURGLASS

				if info.num_images eq 1 then begin
					data = read_tiff(directory+filename)
				endif $
				else begin
					data = uintarr(info.num_images*info.dimensions[0],info.dimensions[1])
					for i=0, info.num_images-1 do begin
						data[i*info.dimensions[0],0] = read_tiff(directory+filename, image_index=i) 
					endfor
				endelse
				s = [info.dimensions[0],info.dimensions[1]]
				nframes = info.num_images
				end


			else : begin
				;; Default is a standard TIFF image (same as RoperCCD)
				if query_tiff(directory+filename) eq 0 then begin
					WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Error loading '+filename
					return
				endif
				WIDGET_CONTROL, /HOURGLASS
				data = read_tiff(directory+filename)
				s = size(data, /dim)
				nframes = 1
				end

		endcase

			
	;;
	;;	Now that we have loaded the image, obtain statistics on the image 
	;;	that only need computing once when loaded
	;;
		t = size(data, /type)
		case t of 
			0 : type = 'undefined'
			1 : type = 'byte'
			2 : type = 'INT16'
			3 : type = 'INT32'
			4 : type = 'float'
			5 : type = 'double'
			12 : type = 'UINT16'
			13 : type = 'UINT32'
			else : type = 'unknown'
		endcase

		if nframes eq 1 then $
			text1 = strcompress(string('[',s[0],'x',s[1],']'),/remove_all) $
		else $
			text1 = strcompress(string('[',s[0],'x',s[1],']x',nframes),/remove_all) 
		text2 = strcompress('min = ' + string(min(data)) + ', max = ' + string(max(data)))
		widget_control, (*pstate).text.preview1, SET_VALUE= 'Data = ' + text1 + ' ('+type + ')  ' + text2

	;;
	;;	To simplify calculations later (ie: avoid assumptions about data types)  
	;;	convert everything to float here
	;;
		data = float(data)





	;;
	;;	Remap pixel locations and intensities
	;;	
		data = fel_browser_pixelmaps(pstate, data, s)


	;;
	;; Median filters, etc
	;;
		if (*pstate).global.FilterMedian ne 0 then $
			data = median(data, (*pstate).global.FilterMedian)
		if (*pstate).global.FilterSmooth ne 0 then $
			data = smooth(data, (*pstate).global.FilterSmooth)
		if (*pstate).global.FilterPeak ne 0 then $
			data = data - median(data, (*pstate).global.FilterPeak)
		if (*pstate).global.FilterFloor ne 0 then $
			data = (data > (*pstate).global.FilterFloor)
		if (*pstate).global.FilterCeil ne 0 then $
			data = (data < (*pstate).global.FilterCeil)
		if (*pstate).global.FilterSaturation ne 0 then begin
			w = where(data ge (*pstate).global.FilterSaturation)
			if w[0] ne -1 then $
				data[w] = 0
		endif


	;;
	;;	Make data positive
	;;
		if widget_info((*pstate).menu.Correction_CropDataAtZero, /button_set) then $
			data = (data > 0)
		if widget_info((*pstate).menu.Correction_AbsData, /button_set) then $
			data = abs(data)		



	;;
	;;	Remapped frames
		s = size(data,/dim)
		text1 = strcompress(string(s[0],'x',s[1]),/remove_all) 
		text2 = strcompress('min = ' + string(min(data)) + ', max = ' + string(max(data)))
		widget_control, (*pstate).text.preview2, $
			SET_VALUE= 'Image = '+text1 + ', '+text2


	;;
	;;	Save pointer in memory
	;;
		ptr_free, (*pstate).global.image_data
		(*pstate).global.image_data = ptr_new(data, /no_copy)					

	;;
	;;	Preview image
	;;
		WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = '  '
		if NOT KEYWORD_SET(quiet) then $
			fel_browser_preview, pstate

end