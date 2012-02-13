;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Function to read text header information
;;	(Actually, it only reads the bits we are interested in for this code...)
;;
function fel_browser_readimageheader, pstate, filename

	directory =	(*pstate).global.directory
		catch, Error_status 
		if Error_status ne 0 then begin
			return, {error: -1}
		endif 



	case (*pstate).setup.camera of
		'RoperCCD' : begin
			;; Filenames
				headerfile = strmid(filename, 0, strlen(filename)-4) + '.txt'
				headerfile = directory+headerfile
				openr, fp, headerfile, error=e, /get
				if e ne 0 then $
					return, {error: -1}
	
			;;	Header file parsing loop
				this_line = string('empty')
				repeat begin
					readf, fp, this_line
					part = strsplit(this_line,'=', /extract)
		
					case strcompress(strupcase(part[0]),/remove_all) of
						'SAMPLE' : sample = part[1]
						'SAMPLE_X' : sample_x = float(part[1])
						'SAMPLE_Y' : sample_y = float(part[1])
						'TIME' : time = part[1]
						'CCD_COMMENT' : ccd_comment = strjoin(part[1:n_elements(part)-1])
						'CCD_EXPTIME' : ccd_exptime = part[1]
						'CCD_BINNING' : ccd_binning = part[1]
						'CCD_TEMP' : ccd_temp = float(part[1])
						'MASTER_COMMENT' : master_comment = strjoin(part[1:n_elements(part)-1])
						'TIMESTAMPS' : timestamps = strjoin(part[1:n_elements(part)-1])
						'FEL_PULSES_COUNTED' : pulses_counted = fix(part[1])
						else : useless=1
					endcase
				endrep until eof(fp) 

			;;	Clean up and return
				close, fp
				free_lun, fp
			end

		'pnCCD' : begin
			sample = '--'
			sample_x = '--'
			sample_y = '--'
			comment1 = '--'
			comment2 = '--'
			ccd_exptime = '--'
			ccd_temp = '--'
			ccd_binning = '--'
			pulses_counted = '1'
			hitinfo = '--'
			hitstrength = '--'
			
			file_id = H5F_OPEN(directory+filename) 
			
			dataset_id = H5D_OPEN(file_id, 'LCLS/eventTime') 
			time = H5D_READ(dataset_id) 
			H5D_CLOSE, dataset_id 

			dataset_id = H5D_OPEN(file_id, 'LCLS/fiducial') 
			timestamps = H5D_READ(dataset_id) 
			H5D_CLOSE, dataset_id 
			
			H5F_CLOSE, file_id 
			end		
		
		else : begin
				return, {error: -1}
				end	

	endcase

	;;
	;;	Return
	;;
		result = { $
			error : 0, $
			sample : sample, $
			sample_x : sample_x, $
			sample_y : sample_y, $
			time : time, $
			comment1 : comment1, $
			ccd_exptime : ccd_exptime, $
			ccd_binning : ccd_binning, $
			ccd_temp : ccd_temp, $
			comment2 : comment2, $
			timestamps : timestamps, $
			pulses_counted : pulses_counted, $
			hitinfo : hitinfo, $
			hitstrengh : hitstrength $
		}

		return, result

end
