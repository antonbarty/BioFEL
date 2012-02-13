;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2006-2009
;;

function fel_browser_xtcconverter_options, pstate

	;;
	;;	Dialog box for parameters
	;;
		form_desc=[ '1, BASE,, COLUMN', $
					'1, BASE,, COLUMN, FRAME', $
					'0, LABEL, Options, left', $
					'0, BUTTON, Integrate (-s)|Output all files (-a)|Discard pnCCD 0 (-d)|Discard pnCCD 1 (-D)|'+ $
						'Start time (-t)|End time (-T), tag=options', $
					'0, LABEL, Command line string, left', $
					'2, TEXT, , width=40, tag=cl_string', $

					'1, BASE,, COLUMN, FRAME', $
					'0, LABEL, Destination path, left', $
					'0, TEXT, ' + (*pstate).global.XTCdestinationdir + ' , width=40, tag=destination_path', $
					'1, BASE,, ROW', $
					'0, BUTTON, OK, QUIT, tag=ok', $
					'2, BUTTON, Cancel, QUIT' $
				  ]

		form = cw_form(form_desc, title='OfflineCASS options', /column)
		if form.ok ne 1 then $
			return, 'cancel'


	;;
	;;	Create options string
	;;
		str = ''
		if form.options[0] then str += '-s '
		if form.options[1] then str += '-a '
		if form.options[2] then str += '-d '
		if form.options[3] then str += '-D '
		
		str += form.cl_string

	;;
	;;	Destination dir
	;;
		(*pstate).global.XTCdestinationdir = form.destination_path

		return, str

end



pro fel_browser_xtcconverter, pstate

	;;
	;;	Select files
	;;
		;default_dir = (*pstate).global.directory
		default_dir = (*pstate).global.XTCsourcedir
		file = dialog_pickfile(filter='*.xtc',path=default_dir, /multi)
		if file[0] eq '' then $
			return

	;;
	;;	Offline CASS options
	;;
		cass_options = fel_browser_xtcconverter_options(pstate)
		if cass_options eq 'cancel' then $
			return
	
		print, 'Executing: cass ', cass_options
	;;
	;;	Loop through files
	;;
		cd, current=olddir
		(*pstate).global.XTCsourcedir = file_dirname(file[0])
		for i=0, n_elements(file)-1 do begin
			path = file_dirname(file[i])
			file_short = file_basename(file[i])
			stub = strmid(file_short,0,strlen(file_short)-4)
			
			;; Normally we would put files in a directory below where the XTC file is located
			;; However due to permissions on psexport we have to put it in home directory instead
			;cd, '~/data/h5'
			;cd, path
			;cd, '../scratch'
			cd, (*pstate).global.XTCdestinationdir
			file_mkdir, stub
			cd, stub
			
			spawn, 'cp ~/cass.ini .'
			openw, lun, 'filesToProcess.txt', /get
			printf, lun, file
			close, lun
			free_lun, lun
			;;spawn,'cass'
			spawn, '~filipe/bin/cass ' + cass_options + ' &'
		endfor
	
	cd, olddir
end