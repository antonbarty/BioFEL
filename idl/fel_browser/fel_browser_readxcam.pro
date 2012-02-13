;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2007-2009
;;

;;
;;	Load Xcam image file and do some preliminary processing
;;
function fel_browser_read_single_xcam_file, filename, pstate

		;;
		;; Verbose info
		;;
			if widget_info((*pstate).menu.setup_verbose, /button_set) then begin
				print,'Reading XCam file: ',filename
			endif

		;;
		;;	Read in single XCam data file
		;;	For some reason XCam set most significant bit to high
		;;	This gives everything a DC offset of 32768 (kill this offset)
		;;
			;xcam_data = read_tiff(filename)
			xcam_data = read_image(filename)
			xcam_data = xcam_data and ishft(uint(1),15)-1
			xcam_data = long(xcam_data)
			s = size(xcam_data,/dim)

		;; PNG files are inverted top-to-bottom relative to TIFF images 
			if strpos(filename,'.png') ne -1 then $
				xcam_data = rotate(xcam_data,7)


		;;
		;;	XCam data file has two regions of dead area in the image we should remove:
		;; 	Each chip has 2 segments, each 1024x4098, read out independently with separate ADCs
		;;	The first 50 pixels of each panel is shielded and not exposed (delete)
		;;	After all charge is read out, some extra lines are read out from each panel
		;;	These provide a real-time measure of ADC dark noise (also delete)
		;;	One segment is clocked from the left, and the other clocked from the right
		;;	The segments join together in the middle. 
		;;	And the size of these regions changes with binning....
		;;
		;;	Find coordinates to extract only the parts of the image that contain data...
		;;	Easiest way to diagnose is to display an image then run through calculations by hand
		;;	using plots[x,x],[y1,y2] to make sure it's right.
		;;
			precol = 50					;60 is slightly too much
			binning = round(4096./s[1])
			start1 = precol/binning
			end1 = (1024+precol)/binning-1
			overclock = s[0]-2*precol/binning-2048/binning	;; Precol appears on both sides!
			mid = end1 + overclock/2
			start2 = (1024+precol)/binning + overclock
			end2 = s[0]-precol/binning-1
			width1 = end1-start1+1
			width2 = end2-start2+1
			width = width1+width2

		;;
		;;	Create output data array
		;;	
			data = fltarr(width,s[1])
						

		;;
		;;	Background subtraction comes in various forms
		;;
			bg1 = 0
			bg2 = 0

			;;
			;;  Subtract background using overclock data between both panels
			;;	(located between the two readout panels) as reference for each row
			;;
			if overclock ne 0 AND widget_info((*pstate).menu.Correction_XcamOverclock1, /button_set) then begin
				bg1 = total(xcam_data[end1+1:end1+overclock/2,*],1)/(overclock/2)
				bg2 = total(xcam_data[end1+overclock/2+1:start2-1,*],1)/(overclock/2)
				s2=size(bg1,/dim)
				bg1 = reform(bg1,1,s2[0])
				bg2 = reform(bg2,1,s2[0])
				bg1 = rebin(bg1, mid, s2[0]) 
				bg2 = rebin(bg2, s[0]-mid, s2[0]) 

				xcam_data[0:mid-1,*] -= bg1
				xcam_data[mid:s[0]-1,*] -= bg2

				;bg1 = rebin(bg1, width1, s2[0]) - 50
				;bg2 = rebin(bg2, width2, s2[0]) - 50
			endif

			;;
			;;  Subtract background using dead pixels on left and bottom row as references
			;;
			if widget_info((*pstate).menu.Correction_XcamOverclock2, /button_set) then begin
				os0 = fix(8./binning)
				os1 = fix(50./binning)-1
				
				m_os = total(xcam_data[os0:os1, *], 1)/float(os1-os0+1) 
				
				xcam_data -= replicate(1., s[0])#m_os
			endif
			

			if widget_info((*pstate).menu.Correction_XcamOverclock3, /button_set) then begin
				y0 = fix(8./binning)
				y1 = fix(400./binning)
				y2 = fix((4096-400.)/binning)
				y3 = fix(4096./binning)-1

				m_y = total(xcam_data[*, y0:y1], 2)/float(y1-y0+1)
				;m_y2 = total(xcam_data[*, y2:y3], 2)/float(y2-y3+1)
				;m_y = (m_y + m_y2)/2

				xcam_data = xcam_data - m_y#replicate(1., s[1]) 
			endif

			;;
			;;  Remove herringbone pattern by using data from 2nd panel as reference valie
			;;
			if widget_info((*pstate).menu.Correction_XcamAntiHerringbone, /button_set) then begin
				panel2 = xcam_data[start2:end2,*]
				bg1 = rotate(panel2, 5) 
				bg2 = panel2 

				xcam_data[start1:end1,*] -= bg1
				xcam_data[start2:end2,*] -= bg2

				y0 = fix(8./binning)
				y1 = fix(400./binning)
				m_y = total(xcam_data[*, y0:y1], 2)/float(y1-y0+1)
				bg = m_y#replicate(1., s[1]) 
				xcam_data -= bg
			endif


			;;
			;;  Subtract horizontal ripples using a notch filter in Fourier space
			;;
			if overclock ne 0 AND widget_info((*pstate).menu.Correction_XcamBanding, /button_set) then begin
				oc = total(xcam_data[end1+1:start2-1,*],1)/(overclock)
				oc = reform(oc)
				fa = abs(fft(oc, 1))
				fa(0) = 0
				h = histogram(fa, min=0, max=max(fa))
				t = total(h,/cum)
				hi = where(t gt 0.92*max(t))
				thresh = min(hi)
	
				notch = fltarr(n_elements(fa))
				notch(*) = 1
				notch(where(fa gt thresh)) = 0
				;notch = smooth(notch, 3)

				temp = fft(xcam_data,1)
				temp[0,*] *= notch
				;temp[1,*] *= notch
				;temp[s[0]-1,*] *= notch
				xcam_data = abs(fft(temp, -1))
					
				;;
				;;	Remove panel-wise offsets in data
				;;
					y0 = fix(8./binning)
					y1 = fix(800./binning)
					m_y = total(xcam_data[*, y0:y1], 2)/float(y1-y0+1)
					bg1 = mean(m_y[start1:end1]) 
					bg2 = mean(m_y[start2:end2]) 


			endif

		;;
		;;	Extract result into data array
		;;
			data[0:width1-1,*] = xcam_data[start1:end1,*]
			data[width1:width-1,*] = xcam_data[start2:end2,*]

			
			
		;;
		;;	Verbose
		;;
			if widget_info((*pstate).menu.setup_verbose, /button_set) then begin
				print,'Xcam panel: min, max, mean, stddev'
				print,'Panel 1:', min(xcam_data[start1:end1,*]), max(xcam_data[start1:end1,*]), mean(xcam_data[start1:end1,*]), stddev(xcam_data[start1:end1,*])
				print,'Panel 2:', min(xcam_data[start2:end2,*]), max(xcam_data[start2:end2,*]), mean(xcam_data[start2:end2,*]), stddev(xcam_data[start2:end2,*])
			endif
			
		;;
		;;	Populate return array with data
		;;
			return, data
end


function fel_browser_readxcam, pstate, filename

		directory =	(*pstate).global.directory		
		WIDGET_CONTROL, /HOURGLASS
		WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Loading '+filename
		
		;;
		;; 	Each camera is saved into a different directory with similar filename
		;; 	The filenames are hand-tailored to what Nicola uses (this may change in the future)
		;;	eg:
		;; 		FEL_003699A_090425_150058.tif
		;;
			stub = strmid(filename,0,strpos(filename,'A_'))
			
			filename1 = (*pstate).global.XcamDir[0] + filename				
			filename2 = file_search((*pstate).global.XcamDir[1]+stub+'*')
			filename2 = filename2[0]
			filename3 = file_search((*pstate).global.XcamDir[2]+stub+'*')
			filename3 = filename3[0]
			
		;;
		;;	Check if file exists and get info about dimensions
		;;	If file does not exist, return blank array
		;;
			;if query_tiff(filename1, info1) eq 0 then begin
			if query_image(filename1, info1) eq 0 then begin
				WIDGET_CONTROL, (*pstate).text.ListText2, SET_VALUE = 'Error loading '+filename
				return, uintarr(1024,2048)
			endif

		;;
		;; Read in the three XCam image files
		;;
			XCam1 = fel_browser_read_single_xcam_file(filename1, pstate)
			s = size(XCam1, /dim)
			data = lonarr(3,s[0],s[1])
			data[0,*,*] = XCam1
			nframes = 1
			
			;if (*pstate).global.XcamDir[1] ne '' AND query_tiff(filename2, info2) ne 0 then begin
			if (*pstate).global.XcamDir[1] ne '' AND query_image(filename2, info2) ne 0 then begin
				XCam2 = fel_browser_read_single_xcam_file(filename2, pstate)
				nframes += 1
				data[1,*,*] = XCam2
			endif
			
			;if (*pstate).global.XcamDir[2] ne '' AND query_tiff(filename3, info3) ne 0 then begin
			if (*pstate).global.XcamDir[2] ne '' AND query_image(filename3, info3) ne 0 then begin
				 XCam3= fel_browser_read_single_xcam_file(filename3, pstate)
				nframes += 1
				data[2,*,*] = XCam3
			endif

			
			
		;;
		;;	If there is only one CCD image, return a 2D array
		;;
			if nframes ne 3 then begin
				data = data[0:nframes-1,*,*]
				data = reform(data)
			endif
			
	data += 100
	
	return, data
end