;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Top-level code that sets up the main GUI interface
;;
pro fel_browser, dir=dir, files=files, plugindir=plugindir

	;; Load colour table names
	loadct, 0, /silent
	loadct, get_names=table_names
	colour_list = string(indgen(n_elements(table_names)))+' '+table_names
	colour_list = '0\'+colour_list
	colour_list = ['0\Xloadct',colour_list]
	colour_list = strcompress(colour_list)
	colour_list[n_elements(colour_list)-1] = '2'+ strmid(colour_list[n_elements(colour_list)-1],1)
	
	;colour_list = ['0\0 B-W linear', '0\1 Blue/White', '0\2 Green-Red-Blue-White', '0\3 Red temperature', $
	;	'0\4 Blue-Green-Red-Yellow', '0\5 Standard Gamma II', '0\6 Prism', '0\7 Red-Purple', '0\8 Green-white linear', $
	;	'0\9 Green-White exponential', '0\10 Green-Pink', '0\11 Blue-Red', '0\12 16-Level', '0\13 Rainbow', $
	;	'0\14 Steps', '0\15 Stern Special', '0\16 Haze', '0\17 Blue-Pastel_Red', '0\18 Pastels', $
	;	'0\19 Hue Sal Lightness 1', '0\20 Hue Sat Lightness 2', '0\21 Hue Sat Value 1', '0\22 Hue Sat Value 2', $
	;	'0\23 Purple-Red stripes', '0\24 Beach', '0\25 Mac style', '0\26 Eos A', '0\27 Eos B', '0\28 Hard Candy', $
	;	'0\29 Nature', '0\30 Ocean', '0\31 Peppermint', '0\32 Plasma', '0\33 Blue-Red', '0\34 Rainbow', $
	;	'0\35 Blue waves', '0\36 Volcano', '0\37 Waves', '0\38 Rainbow18', '0\39 Rainbow + white', $
	;	'0\40 Rainbow + black', '2\Xloadct']


	;;
	;;	Default configuration file
	;;
		inifile = file_dirname(routine_filepath('fel_browser'),/mark) + 'fel_browser.ini'



	;;
	;;	Default file locations
	;;
		if NOT keyword_set(dir) then begin
			if (!version.os_family eq 'Windows') then $
				dir = 'd:/Hamburg Data/' $
			else $
				dir = '.'
		endif


	;;
	;;	Scan for plugins
	;;	Look in directory one up from the source code layer
	;;
		if not keyword_set(plugindir) then begin
			browser_dir = routine_filepath('fel_browser') 
			browser_dir = file_dirname(browser_dir)
			delim_pt = strsplit(browser_dir,path_sep())
			plugindir = strmid(browser_dir, 0, delim_pt[n_elements(delim_pt)-1])
			plugindir = plugindir+'plugins'
		endif
		plugins = file_search(plugindir + '/*.pro')
		plugins = file_basename(plugins)
		if plugins[0] eq '' then $
			plugins[0] = 'No plugins found'
			

	;;
	;;	Set up GUI top level
	;;
		top = widget_base(title='FEL image browser (LCLS, June 2010)', /row, mbar=bar, /TLB_SIZE_EVENTS)
		
		
	;;
	;;	Menu bar items
	;;
		mbSetup = widget_button(bar, value='Setup')
		mbfile_a = widget_button(mbSetup, value='About FEL browser')
		mbsetup_1 = widget_button(mbSetup, value='Roper CCD', /checked, /separator)
		mbsetup_2 = widget_button(mbSetup, value='XCAM', /checked)
		mbsetup_3 = widget_button(mbSetup, value='pnCCD (.h5)', /checked)
		mbsetup_8 = widget_button(mbSetup, value='cspad (.h5)', /checked)
		mbsetup_7 = widget_button(mbSetup, value='Assembled HDF5 (.h5)', /checked)
		mbsetup_4 = widget_button(mbSetup, value='Configure', /separator)
		mbsetup_5 = widget_button(mbSetup, value='Debug',/checked)
		mbsetup_6 = widget_button(mbSetup, value='Verbose',/checked)
		WIDGET_CONTROL, mbsetup_8, set_button=1

		mbfile = widget_button(bar, value='File')
		mbfile_1 = widget_button(mbfile, value='Select directory')
		mbfile_2 = widget_button(mbfile, value='Rescan directory')
		mbfile_10 = widget_button(mbfile, value='Set directory scan file filter')
		mbfile_17 = widget_button(mbfile, value='Save file list',/separator)
		mbfile_3 = widget_button(mbfile, value='Load file list')
		mbfile_4 = widget_button(mbfile, value='Save list of selected files')
		mbfile_q = widget_button(mbfile, value='Quit',/separator)
	
		
		mbExport = widget_button(bar, value='Export')
		mbfile_5 = widget_button(mbExport, value='Export colour picture(s)')
		;mbfile_9 = widget_button(mbExport, value='Export multiple pretty pictures')
		mbfile_6 = widget_button(mbExport, value='Export processed data')
		;mbfile_15 = widget_button(mbExport, value='Export processed data (UINT16 TIFF)')
		;mbfile_17 = widget_button(mbExport, value='Export processed data (INT16 TIFF)')
		;mbfile_18 = widget_button(mbExport, value='Export processed data (INT32 TIFF)')
		;mbfile_16 = widget_button(mbExport, value='Export processed data (HDF5)')
		mbfile_11 = widget_button(mbExport, value='Export autocorrelation data',/separator)
		mbfile_12 = widget_button(mbExport, value='Export autocorrelation image')
		mbfile_13 = widget_button(mbExport, value='Export masked autocorrelation data')
		mbfile_14 = widget_button(mbExport, value='Export masked autocorrelation image')
		mbfile_7 = widget_button(mbExport, value='Export selected metadata',/separator)
		mbfile_8 = widget_button(mbExport, value='Export all metadata')
		
		
		mbcolours = widget_button(bar, value='Colours')
		mbcolours_1 = CW_PDMENU(mbcolours, colour_list, /MBAR, IDs=mbcolours_IDs)
		
		mbcomments = widget_button(bar, value='Comments')
		mbcomments_1 = widget_button(mbcomments, value='Scan image header comments')
		mbcomments_2 = widget_button(mbcomments, value='Date + Time', /checked, /separator)
		mbcomments_3 = widget_button(mbcomments, value='Sample', /checked)
		mbcomments_4 = widget_button(mbcomments, value='Sample position', /checked)
		mbcomments_6 = widget_button(mbcomments, value='Comment 1', /checked)
		mbcomments_5 = widget_button(mbcomments, value='Comment 2', /checked)
		mbcomments_9 = widget_button(mbcomments, value='Timestamps', /checked)
		mbcomments_7 = widget_button(mbcomments, value='Hits', /checked)
		mbcomments_8 = widget_button(mbcomments, value='Hit strength', /checked)
		mbcomments_10 = widget_button(mbcomments, value='Tag', /checked)
		mbcomments_11 = widget_button(mbcomments, value='Exposure time', /checked)
		mbcomments_12 = widget_button(mbcomments, value='CCD binning', /checked)
		mbcomments_13 = widget_button(mbcomments, value='CCD temperature', /checked)
		mbcomments_14 = widget_button(mbcomments, value='N pulses counted', /checked)
		WIDGET_CONTROL, mbcomments_6, set_button=1


		mbtool = widget_button(bar, value='Tools')
		mbtool_5 = widget_button(mbtool, value='Define beamstop')
		mbtool_7 = widget_button(mbtool, value='Define beam centre')
		mbtool_2 = widget_button(mbtool, value='Autocorrelation',/separator)	
		mbtool_6 = widget_button(mbtool, value='Masked autocorrelation')	
		mbtool_19 = widget_button(mbtool, value='R/theta decomposition')	
		mbtool_10 = widget_button(mbtool, value='Reconstruct')		
		mbtool_4 = widget_button(mbtool, value='Find hits',/separator)		
		mbtool_17 = widget_button(mbtool, value='Sort hits by strength')		
		mbtool_18 = widget_button(mbtool, value='Sort hits file')		
		mbtool_24 = widget_button(mbtool, value='Sum images (virtual powder pattern)')		
		mbtool_3 = widget_button(mbtool, value='Pause in IDL command line',/separator)	
		mbtool_21 = widget_button(mbtool, value='h5_browser()')	
		mbtool_1 = widget_button(mbtool, value='X-ray calculator')	
		

		mbplugin = widget_button(bar, value='Plugins')
		mbplugin_id = intarr(n_elements(plugins)+1)
		for i=0, n_elements(plugins)-1 do begin
			mbplugin_id[i] = widget_button(mbplugin, value=plugins[i])		
		endfor
		
		mbcorr = widget_button(bar, value='PixelMaps')
		mbcorr_10 = widget_button(mbcorr, value='Quick rotation remapping',/checked)
		mbcorr_1 = widget_button(mbcorr, value='Pixel coordinate remapping',/checked)
		mbcorr_3 = widget_button(mbcorr, value='Load geometry (pixel location map)')
		mbcorr_8 = widget_button(mbcorr, value='Create pixel location map')
		mbcorr_12 = widget_button(mbcorr, value='Beam always in centre of image',/checked)
		mbcorr_11 = widget_button(mbcorr, value='CCD alignment tool')
		mbcorr_2 = widget_button(mbcorr, value='Pixel intensity remapping',/checked,/separator)
		mbcorr_13 = widget_button(mbcorr, value='CCD offset subtraction',/checked)
		mbcorr_9 = widget_button(mbcorr, value='Create pixel intensty map',sensitive=0)
		mbcorr_4 = widget_button(mbcorr, value='Load pixel intensty map',sensitive=0)
		mbcorr_5 = widget_button(mbcorr, value='View pixel X locations',/separator,sensitive=0)
		mbcorr_6 = widget_button(mbcorr, value='View pixel Y locations',sensitive=0)
		mbcorr_7 = widget_button(mbcorr, value='View pixel intensities',sensitive=0)
		;;WIDGET_CONTROL, mbcorr_1, set_button=1
		WIDGET_CONTROL, mbcorr_12, set_button=1

		mbback = widget_button(bar, value='Background')
		mbtool_8 = widget_button(mbback, value='Define background image(s)')
		mbviewer7 = widget_button(mbback, value='Subtract background', /checked)
		mbtool_22 = widget_button(mbback, value='Smooth background image', /checked)
		mbviewer8 = widget_button(mbback, value='View background image', /checked)		
		mbtool_9 = widget_button(mbback, value='Clear background image')
		mbtool_11 = widget_button(mbback, value='Remove Xcam overclock background (Horiz)',/checked,/separator)
		mbtool_12 = widget_button(mbback, value='Remove Xcam masked pixels (Horiz)',/checked)
		mbtool_16 = widget_button(mbback, value='Remove Xcam vertical banding (Vert)',/checked)
		mbtool_15 = widget_button(mbback, value='Xcam anti-herringbone',/checked)
		mbtool_13 = widget_button(mbback, value='Xcam banding reduction (Horiz FFT filter)',/checked)
		mbtool_25 = widget_button(mbback, value='pnCCD common mode subtraction',/checked,/separator)
		WIDGET_CONTROL, mbtool_11, set_button=1
		;;WIDGET_CONTROL, mbtool_25, set_button=1
		;;WIDGET_CONTROL, mbtool_16, set_button=1


		mbview = widget_button(bar, value='View')
		mbviewer9 = widget_button(mbview, value='Image filters')		
		mbtool_14 = widget_button(mbview, value='data = data > 0', /checked)
		mbtool_20 = widget_button(mbview, value='data = abs(data)', /checked)
		mbtool_23 = widget_button(mbview, value='Rescale ccdMax overflow', /checked)
		WIDGET_CONTROL, mbtool_23, set_button=1
		WIDGET_CONTROL, mbtool_14, set_button=1


		mbviewer = widget_button(bar, value='Display')
		mbviewer1 = widget_button(mbviewer, value='Gamma', /checked)		
		mbviewer2 = widget_button(mbviewer, value='Logarithmic', /checked)		
		mbviewer3 = widget_button(mbviewer, value='Histogram equalise', /checked)	
		mbviewer4 = widget_button(mbviewer, value='New window', /checked,/separator)		
		mbviewer6 = widget_button(mbviewer, value='Scrolling window', /checked)		
		mbviewer5 = widget_button(mbviewer, value='IDL iImage tool', /checked, sensitive=0)	
		WIDGET_CONTROL, mbviewer1, set_button=1
		WIDGET_CONTROL, mbviewer6, set_button=1
		WIDGET_CONTROL, mbviewer5, set_button=0
		
		mbview = widget_button(bar, value='Logfiles')
		mbview_4 = widget_button(mbview, value='Full size')
		mbview_3 = widget_button(mbview, value='Image Header.txt')
		mbview_1 = widget_button(mbview, value='Master Log.txt',/separator)
		mbview_2 = widget_button(mbview, value='Motor Positions.txt')
		
		

	;;
	;;	Stuff that doesn't work yet
	;;
		widget_control, mbfile_4, sensitive=0
		
		;widget_control, mbtool_10, sensitive=0
		;widget_control, mbfile_6, sensitive=0
	


	;;
	;;	2nd column
	;;	List of all files in directory
	;;
		base3 = widget_base(top, /column,/frame)
		
		text3a = widget_label(base3,value='File list', /align_left,/dynamic_resize)
		table1 = widget_table(base3, xsize=1, scr_xsize=400, scr_ysize=550, $
			/no_row_headers,  /RESIZEABLE_COLUMNS, /scroll, /all_events );/no_column_headers,
		widget_control, table1, column_widths=[500-30]
		widget_control, table1, column_labels = ['Filename']

		;list1 = widget_list(base3, xsize=80, ysize=34) ;/multi
		;WIDGET_CONTROL, list1, xsize=40

		text3c = widget_label(base3,value='Anton Barty (anton.barty@cfel.de)', /align_left,/dynamic_resize)
		text3d = widget_label(base3,value='No files selected: please select a directory', /align_left,/dynamic_resize)
		;text3e = widget_label(base3,value='', /align_left,/dynamic_resize)

		base3b = widget_base(base3, /row)
		b1 = widget_button(base3b, value='Select directory')
		b8 = widget_button(base3b, value='Load file list')
		b2 = widget_button(base3b, value='Rescan directory')
		b5 = widget_button(base3b, value='Collect comments')	
		b9 = widget_button(base3b, value='xtc->h5')	

		;base3d = widget_base(base3, /row)
		bq = widget_button(base3b, value='Quit')
						

	;;
	;;	3rd column
	;;	Image previews
	;;
		base4 = widget_base(top, /column,/frame)

		temp = widget_label(base4,value='Preview image', /align_left)
		preview_nx = 335
		preview_ny = 325
		draw1 = widget_draw(base4, xsize=preview_nx, ysize=preview_ny)

		temp = widget_label(base4,value='Histogram', /align_left)
		draw2 = widget_draw(base4, xsize=preview_nx, ysize=150, /button_events)

		text4a = widget_label(base4,value='512x512', /align_left,/dynamic_resize)
		text4b = widget_label(base4,value='  ', /align_left,/dynamic_resize)

		f1 = widget_slider(base4, title='Gamma (x100)', min=1, max=200, value=25)
		;f2 = cw_field(base4, title='Gamma ', value=0.2, xsize=5, /float, /return_events)
		
		base4c = widget_base(base4, /row)
		b4 = widget_button(base4c, value='Full size')
		b3 = widget_button(base4c, value='Autocorrelation')
		b6 = widget_button(base4c, value='Masked Acorr')
		b7 = widget_button(base4c, value='Reconstruct')
		
		;base4d = widget_base(base4, /row)


	;;
	;;	Make GUI
	;;
		widget_control, top, /realize
		widget_control, top, kill_notify='fel_browser_cleanup'
		widget_control, draw1, get_value=draw1_wID
		widget_control, draw2, get_value=draw2_wID
		device, decomposed=0

	;;
	;;	Information on geometry
	;;
		base_geometry = WIDGET_INFO(top, /geometry)
		;table_geometry = WIDGET_INFO(list1, /geometry)
		table_geometry = WIDGET_INFO(table1, /geometry)
		table_xpadding = base_geometry.scr_xsize - table_geometry.scr_xsize
		table_ypadding = base_geometry.scr_ysize - table_geometry.scr_ysize
		table_padding = {x : table_xpadding, y:table_ypadding}
	

	;;
	;;	ID Structures
	;;
		menuID= {	File : mbfile, $
					File_about : mbfile_a, $
					File_SelDir : mbfile_1, $
					File_RescanDir : mbfile_2, $
					File_Filter : mbfile_10, $
					File_Export : mbfile_5, $
					;File_ExportMultiple : mbfile_9, $
					File_ExportData : mbfile_6, $
					;File_ExportData_TIFFfloat : mbfile_6, $
					;File_ExportData_TIFFuint16 : mbfile_15, $
					;File_ExportData_TIFFint16 : mbfile_17, $
					;File_ExportData_hdf5 : mbfile_16, $
					File_ExportSelectedMetadata : mbfile_7, $
					File_ExportAllMetadata : mbfile_8, $
					File_ExportAcorrData : mbfile_11, $
					File_ExportAcorrImage : mbfile_12, $
					File_ExportMaskedAcorrData : mbfile_13, $
					File_ExportMaskedAcorrImage : mbfile_14, $
					File_SaveFileList : mbfile_17, $
					File_LoadFileList : mbfile_3, $
					File_SaveListOfSelectedFiles : mbfile_4, $
					Quit : mbfile_q, $
					
					Setup_RoperCCD : mbsetup_1, $
					Setup_Xcam : mbsetup_2, $
					Setup_pnCCD : mbsetup_3, $
					Setup_cspad : mbsetup_8, $
					Setup_hdf5 : mbsetup_7, $
					Setup_Configure : mbsetup_4, $
					Setup_Debug : mbsetup_5, $
					Setup_verbose : mbsetup_6, $
					
					Tool : mbtool, $
					Tool_calculator : mbtool_1, $
					Tool_autocorrelation : mbtool_2, $
					Tool_maskedautocorrelation : mbtool_6, $
					Tool_definebeamstop : mbtool_5, $
					Tool_rtheta : mbtool_19, $
					Tool_definebeamcentre : mbtool_7, $
					Tool_definebackgroundfiles : mbtool_8, $
					Tool_clearbackgroundfiles : mbtool_9, $
					Tool_smoothbackground : mbtool_22, $
					Tool_SumImages : mbtool_24, $
					Tool_reconstruct : mbtool_10, $
					Tool_Halt : mbtool_3, $
					Tool_h5browser : mbtool_21, $
					Tool_FindHits : mbtool_4, $
					Tool_SortHits : mbtool_17, $
					Tool_SortHitsFile : mbtool_18, $
					
					Plugins : mbplugin, $
					Plugin_ID : mbplugin_id, $
					Plugin_name : plugins, $
					
					Colours : mbcolours, $
					ColourList : mbcolours_1, $
					ColourListID : mbcolours_IDs, $
					
					Comment_scan : mbcomments_1, $
					Comment_datetime : mbcomments_2, $
					Comment_sample : mbcomments_3, $
					Comment_position : mbcomments_4, $
					Comment_Comment2 : mbcomments_5, $
					Comment_Comment1 : mbcomments_6, $
					Comment_Timestamps : mbcomments_9, $
					Comment_Hits : mbcomments_7, $
					Comment_HitStrength : mbcomments_8, $
					Comment_Tag : mbcomments_10, $
					Comment_ExposureTime : mbcomments_11, $
					Comment_CCDbinning : mbcomments_12, $
					Comment_CCDtemp : mbcomments_13, $
					Comment_PulsesCounted : mbcomments_14, $

					Correction_locations : mbcorr_1, $
					Correction_quick : mbcorr_10, $
					Correction_intensities : mbcorr_2, $
					Correction_CreateLocations : mbcorr_8, $
					Correciton_CreateIntensities : mbcorr_9, $
					Correction_CCDAlignmentTool : mbcorr_11, $
					Correction_ScaleOverflow : mbtool_23, $
					Correction_CCDoffset : mbcorr_13, $
					Correction_CentreInCentre : mbcorr_12, $
					Correction_LoadLocations : mbcorr_3, $
					Correciton_LoadIntensities : mbcorr_4, $
					Correction_ViewPixelX : mbcorr_5, $
					Correction_ViewPixelY : mbcorr_6, $
					Correction_ViewPixelIntensity : mbcorr_7, $
					Correction_XcamOverclock1 : mbtool_11, $
					Correction_XcamOverclock2 : mbtool_12, $
					Correction_XcamOverclock3 : mbtool_16, $
					Correction_XcamBanding : mbtool_13, $
					Correction_CropDataAtZero : mbtool_14, $
					Correction_AbsData : mbtool_20, $
					Correction_XcamAntiHerringbone : mbtool_15, $
					Correction_pnCCDcommonmode : mbtool_25, $
										
					Viewer : mbviewer, $
					Viewer_gamma : mbviewer1, $
					Viewer_filters : mbviewer9, $
					Viewer_Logarithmic : mbviewer2, $
					Viewer_HistEqual : mbviewer3, $
					Viewer_display : mbviewer4, $
					Viewer_scrolling : mbviewer6, $
					Viewer_iImage : mbviewer5, $
					Viewer_backgroundSubtract : mbviewer7, $
					Viewer_DisplayBackgroundImage : mbviewer8, $					
					
					View : mbview, $
					View_Fullsize : mbview_4, $
					View_MasterLog : mbview_1, $
					View_MotorPositions : mbview_2, $
					View_ImageHeader : mbview_3 $
				}

		fieldID = { gamma : f1 $
				  }
		
		buttonID= {	SelectDirectory : b1, $
					Reload : b2, $
					CollectComments : b5, $
					LoadFileList : b8, $
					XTCconverter : b9, $
					autocorrelation : b3, $
					maskedautocorrelation : b6, $
					reconstruct : b7, $
					fullsize : b4, $
					quit : bq $
				  }

		TextID = { 	FileListLabel : text3a, $
					listText1 : text3c, $
					listText2 : text3d, $
					;listText3 : text3e, $
					
					preview1 : text4a, $
					preview2 : text4b $
				}

		;listID = { files : list1 }
		
		tableID = { files : table1 }
		
		drawID = {	preview : draw1, $
					histogram : draw2 }

		windowID = { preview : draw1_wID, $
					 histogram : draw2_wID $
					}


	;;
	;;	Comment labels
	;;
		metacolumns = { filename : 0, $
						time : 1, $
						sample : 2, $
						position : 3, $
						comment1 : 4, $
						comment2 : 5, $
						hits : 6, $
						hitStrength : 7, $
						timestamps : 8, $
						tag : 9, $
						exposuretime : 10, $
						binning : 11, $
						ccdTemp : 12, $
						pulsesCounted : 13, $
						ncolumns : 14 $
					}
	;;	
	;;	Globals
	;;		
		xcam_transform = { $
					nx : 2048-160, $
					ny : 4096, $
					dx : 16.e-6, $
					
					x1_dx : -0.26046, $
					x1_dy : -0.033569, $
					x1_rot : 179.5, $
					x1_scale : 1.0, $
					x1_z : 1.0, $
					x1_i : 1.0, $
	
					x2_dx : +0.26046, $
					x2_dy : 0.033569, $
					x2_rot : 0.0, $
					x2_scale : 1.0, $
					x2_z : 1.0, $
					x2_i : 1.0, $
					
					x3_dx : 0.0, $
					x3_dy : 0.0, $
					x3_rot : 0.0, $
					x3_scale : 0.5, $
					x3_z : 4.0, $
					x3_i : 4.0 $
				}


		pnCCD_transform = { $
					nx : 1024, $
					ny : 1024, $
					dx : 75.e-6, $
					order : [0,1], $
					
					ccd1_dx : .0015, $
					ccd1_dy : 0.0, $
					ccd1_rot : 0.0, $
					ccd1_scale : 1.0, $
					ccd1_offset : 0.0, $
					ccd1_i : 1.0, $
					ccd1a_sep : 0.005, $
					ccd1b_sep : -0.005, $
					
					ccd2_dx : 0.0, $
					ccd2_dy : 0.0, $
					ccd2_rot : 0.0, $
					ccd2_scale : 0.15, $
					ccd2_offset : 0.0, $
					ccd2_i : 1.0, $
					ccd2a_sep : 0.0, $
					ccd2b_sep : 0.0, $
					
					ccd_usage : [1,1] $
				}

	
		global = {	inifile : inifile, $
					nfiles : 0L, $
					directory : dir, $
					XcamDir : [dir, dir, dir], $
					
					currentFileID : 0L, $
					
					preview_nx : preview_nx, $
					preview_ny : preview_ny, $
					colour_table : 4, $

					default_geometry : base_geometry, $  
					table_padding : table_padding, $
					ccd_max : 65535, $
					scale_min : 0, $
					scale_max : 65535, $
					beamstop : [0.5, 0.5, 0.05], $
					img_centre : [0.5, 0.5], $
					xcam_transform : xcam_transform, $
					pnccd_transform : pnccd_transform, $
					FilterMedian : 0, $
					FilterSmooth : 0, $
					FilterPeak : 0, $
					FilterFloor : 0, $
					FilterCeil : 0, $
					FilterSaturation : 0, $

					pixelLocationMapX : ptr_new(), $
					pixelLocationMapY : ptr_new(), $
					pixelIntensityMap : ptr_new(), $
					pixelOffsetMap : ptr_new(), $
					pixelPanelOrder : ptr_new(), $
					pixelPanelUsage : ptr_new(), $
					
					XTCsourcedir : '/reg/d/psdm/amo/amo01109/', $
					XTCdestinationdir : '/reg/d/psdm/amo/amo01109/scratch', $
					
					filenames : ptr_new(), $
					image_data : ptr_new(), $
					background_data : ptr_new(), $
					processed_data : ptr_new(), $
					metadata : ptr_new(), $
					metadata_columns : metacolumns $
				}
					
		
	;;
	;;	Setup
	;;
		setup = { 	camera : 'HDF5', $
					fileFilter : '*.h5' $
				}
		;setup = { 	camera : 'XCAM', $
		;			fileFilter : '*.tif,*.png' $
		;		}
		
		
	;;
	;;	Load configuration from last time
	;;
		if file_test(inifile) then $
			restore, inifile

		;; Reset a few defaults that must be zero
		global.nfiles = 0
		global.filenames = ptr_new()
		global.image_data = ptr_new()
		global.background_data = ptr_new()
		global.processed_data = ptr_new()
		global.metadata = ptr_new()
		
	;;
	;;	Create main state variable to hold global data structure
	;;	(this becomes (*pstate) in all functions and procedures.
	;;
		state = {	top : top, $
		
					global : global, $
					setup : setup, $
					menu : menuID, $
					field : fieldID, $
					button : buttonID, $
					text : textID, $
					;list : listID, $
					table : tableID, $
					draw : drawID, $
					window : windowID $
				}

		pstate = ptr_new(state, /no_copy)
		widget_control, top, set_uvalue=pstate
		
		

	;;
	;;	Configure default settings
	;;
		fel_browser_configure, pstate, 'cspad'
		(*pstate).global.inifile = file_dirname(routine_filepath('fel_browser'),/mark) + 'fel_browser.ini'

	;;
	;;	Dialog with authorship, etc
	;;
		;;r = dialog_message('Anton Barty, CFEL (anton.barty@desy.de)',/info,/center, title='fel_browser (December 2009)')


	;;
	;;	Start in current directory and populate file list
	;;
		cd, current=directory
		directory += path_sep()
		(*pstate).global.directory = directory
		WIDGET_CONTROL, (*pstate).text.FileListLabel, set_value = directory		
		;fel_browser_scandir, {top:top} 


		
		
	;;
	;;	Initiate event loop
	;;
		device, retain=3
		xmanager,'FEL browser',top, /no_block, event_handler='fel_browser_event'
		
end