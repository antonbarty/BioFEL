;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Main event loop begins here
;;
pro fel_browser_event, event

	;help,event,/str
	widget_control, event.top, get_uvalue=pstate



	;; Establish polite error handler to catch crashes
	;; (only if not in debug mode)
	if NOT widget_info((*pstate).menu.setup_debug, /button_set) then begin
		catch, Error_status 
		if Error_status ne 0 then begin
			message = 'Execution error: ' + !error_state.msg
			r = dialog_message(message,title='Error',/center,/error)
			catch, /cancel
			return
		endif 
	endif

	

	case event.ID of 
		;;
		;;	Select directory (menu or button)
		;;
			(*pstate).menu.File_SelDir : begin
				fel_browser_selectdir, event
				;fel_browser_scandir, event
			end

			(*pstate).button.SelectDirectory : begin
				fel_browser_selectdir, event
				;fel_browser_scandir, event
			end

			(*pstate).menu.File_Filter : begin
				form_desc=[ '0, LABEL, Set file filter, left', $
							'0, TEXT, FEL*.TIF, label_left = File filter, width=60, tag=filter', $
							'1, BASE,,row', $
							'0, BUTTON, OK, QUIT, tag=ok', $
							'2, BUTTON, Cancel, QUIT' $
						  ]
				form = cw_form(form_desc, title='cw_form', /column)
				if form.ok eq 1 then $
					(*pstate).global.fileFilter = form.filter
			return


			end

		;;
		;;	Rescan directory (menu or button)
		;;
			(*pstate).menu.File_RescanDir : begin
				fel_browser_scandir, event
			end

			(*pstate).button.Reload : begin
				fel_browser_scandir, event
			end
			

		;;
		;;	Deal with file lists
		;;
			(*pstate).menu.File_LoadFileList : begin
				fel_browser_readfilelist, event
				fel_browser_loadimage, pstate
			end
			(*pstate).button.LoadFileList : begin
				fel_browser_readfilelist, event
				fel_browser_loadimage, pstate
			end
			(*pstate).menu.File_SaveFileList : begin
				fel_browser_savefilelist, event
			end
			(*pstate).menu.File_SaveListOfSelectedFiles  : begin
				temp = dialog_message('Not yet implemented')
			end
			(*pstate).menu.Tool_sortHits : begin
				fel_browser_sorthits, pstate
				fel_browser_loadimage, pstate
			end
			(*pstate).menu.Tool_sortHitsFile : begin
				fel_browser_sorthits, pstate, /file
				fel_browser_loadimage, pstate
			end

			(*pstate).menu.Tool_rtheta : begin
				fel_browser_rtheta, pstate
			end

			(*pstate).button.XTCconverter : begin
				fel_browser_XTCconverter, pstate
			end



		;;
		;;	Export data
		;;
			(*pstate).menu.File_export : begin
				fel_browser_exportimages, pstate
			end
			(*pstate).menu.File_exportData : begin
				fel_browser_exportData, pstate
			end
			;(*pstate).menu.File_exportmultiple : begin
			;	fel_browser_exportimages, pstate
			;end
			;(*pstate).menu.File_exportData_TIFFfloat : begin
			;	fel_browser_exportData, pstate, /float
			;end
			;(*pstate).menu.File_exportData_TIFFuint16 : begin
			;	fel_browser_exportData, pstate, /uint16
			;end
			;(*pstate).menu.File_exportData_TIFFint16 : begin
			;	fel_browser_exportData, pstate, /int16
			;end
			;(*pstate).menu.File_exportData_hdf5 : begin
			;	fel_browser_exportData, pstate, /h5
			;end


		;;
		;;	Export metadata
		;;
			(*pstate).menu.File_ExportSelectedMetadata  : begin
				fel_browser_exportmetadata, pstate, /selected
			end
			(*pstate).menu.File_ExportAllMetadata  : begin
				fel_browser_exportmetadata, pstate
			end




		;;
		;;	Process click event in list of data files
		;;
			(*pstate).table.files : begin
				if event.type eq 4 then begin
					if event.sel_top ne -1 AND event.sel_top eq event.sel_bottom then begin
						(*pstate).global.currentFileID = event.sel_top
						fel_browser_loadimage, pstate
					endif
				endif $
				else if event.type eq 0 then begin
					(*(*pstate).global.metadata)[(*pstate).global.currentFileID,(*pstate).global.metadata_columns.tag] = string(event.ch)
					widget_control, (*pstate).menu.comment_tag, set_button=1
					fel_browser_displaycomments, pstate
				endif $
				else begin
					;help, event, /str
				endelse
			end


		;;
		;;	View full size
		;;
			(*pstate).menu.View_fullsize : begin
				fel_browser_displayfull, pstate
			end
			
			(*pstate).button.fullsize : begin
				fel_browser_displayfull, pstate
			end


		;;
		;;	Autocorrelation
		;;
			(*pstate).menu.Tool_autocorrelation : begin
				fel_browser_acorr, pstate
			end
			
			(*pstate).button.autocorrelation : begin
				fel_browser_acorr, pstate
			end

		;;
		;;	Masked autocorrelation
		;;
			(*pstate).menu.Tool_maskedautocorrelation : begin
				fel_browser_acorr, pstate, /masked
			end
			
			(*pstate).button.maskedautocorrelation : begin
				fel_browser_acorr, pstate, /masked
			end

			(*pstate).menu.Tool_SumImages  : begin
				fel_browser_sumdata, pstate
			end



		;;	Export autocorrelation
			(*pstate).menu.File_ExportAcorrData : begin
				fel_browser_acorr, pstate, /savedata
			end
			(*pstate).menu.File_ExportAcorrImage : begin
				fel_browser_acorr, pstate, /saveimage
			end
			(*pstate).menu.File_ExportMaskedAcorrData : begin
				fel_browser_acorr, pstate, /masked, /savedata
			end
			(*pstate).menu.File_ExportMAskedAcorrImage : begin
				fel_browser_acorr, pstate, /masked, /saveimage
			end


		;;
		;;	Reconstruct
		;;
			(*pstate).menu.Tool_reconstruct  : begin
				fel_browser_reconstruct, pstate
			end
			(*pstate).button.reconstruct : begin
				fel_browser_reconstruct, pstate
			end



		;;
		;;	Define beamstop and beam centre
		;;
			(*pstate).menu.Tool_definebeamstop : begin
				fel_browser_definebeamstop, pstate
			end

			(*pstate).menu.Tool_definebeamcentre : begin
				fel_browser_definebeamcentre, pstate
			end


		;;
		;;	Colour tables
		;;
			(*pstate).menu.colourList : begin
				if event.value eq 0 then $
					xloadct $
				else begin
					ct = event.value-1
					(*pstate).global.colour_table = ct
					loadct, ct, /silent
					widget_control, ((*pstate).menu.ColourListID)[event.value], SET_BUTTON=1
				endelse
				fel_browser_preview, pstate
			end

			(*pstate).field.gamma : begin
				fel_browser_preview, pstate
			end

		;;
		;;	Image scaling method
		;;	
			(*pstate).menu.Viewer_gamma : begin
				widget_control, (*pstate).menu.Viewer_gamma, set_button=1
				widget_control, (*pstate).menu.Viewer_Logarithmic, set_button=0
				widget_control, (*pstate).menu.Viewer_HistEqual, set_button=0
				fel_browser_preview, pstate
			end
			(*pstate).menu.Viewer_Logarithmic : begin
				widget_control, (*pstate).menu.Viewer_gamma, set_button=0
				widget_control, (*pstate).menu.Viewer_Logarithmic, set_button=1
				widget_control, (*pstate).menu.Viewer_HistEqual, set_button=0
				fel_browser_preview, pstate
			end
			(*pstate).menu.Viewer_HistEqual : begin
				widget_control, (*pstate).menu.Viewer_gamma, set_button=0
				widget_control, (*pstate).menu.Viewer_Logarithmic, set_button=0
				widget_control, (*pstate).menu.Viewer_HistEqual, set_button=1
				fel_browser_preview, pstate
			end




		;;
		;;	Viewer
		;;	
			(*pstate).menu.Viewer_display : begin
				widget_control, (*pstate).menu.Viewer_display, set_button=1
				widget_control, (*pstate).menu.Viewer_scrolling, set_button=0
				widget_control, (*pstate).menu.Viewer_iImage, set_button=0
			end
			(*pstate).menu.Viewer_scrolling : begin
				widget_control, (*pstate).menu.Viewer_display, set_button=0
				widget_control, (*pstate).menu.Viewer_scrolling, set_button=1
				widget_control, (*pstate).menu.Viewer_iImage, set_button=0
			end
			(*pstate).menu.Viewer_iImage : begin
				widget_control, (*pstate).menu.Viewer_display, set_button=0
				widget_control, (*pstate).menu.Viewer_scrolling, set_button=0
				widget_control, (*pstate).menu.Viewer_iImage, set_button=1
			end

			(*pstate).menu.Viewer_filters : begin
				form_desc=[ '0, LABEL, Viewer filters, left', $
							'0, INTEGER, '+string((*pstate).global.FilterMedian)+', label_left = Median, width=20, tag=median', $
							'0, INTEGER, '+string((*pstate).global.FilterSmooth)+', label_left = Smooth, width=20, tag=smooth', $
							'0, INTEGER, '+string((*pstate).global.FilterPeak)+', label_left = Peak enhance, width=20, tag=peak', $
							'0, INTEGER, '+string((*pstate).global.FilterFloor)+', label_left = Floor, width=20, tag=floor', $
							'0, INTEGER, '+string((*pstate).global.FilterCeil)+', label_left = Ceiling, width=20, tag=ceil', $
							'0, INTEGER, '+string((*pstate).global.FilterSaturation)+', label_left = Saturation, width=20, tag=saturation', $
							'1, BASE,,row', $
							'0, BUTTON, OK, QUIT, tag=ok', $
							'2, BUTTON, Cancel, QUIT' $
						  ]
				form = cw_form(form_desc, title='cw_form', /column)
				if form.ok ne 1 then $
					return		
				(*pstate).global.FilterMedian = form.median
				(*pstate).global.FilterSmooth = form.smooth
				(*pstate).global.FilterPeak = form.peak
				(*pstate).global.FilterFloor = form.floor
				(*pstate).global.FilterCeil = form.Ceil
				(*pstate).global.FilterSaturation = form.saturation
				fel_browser_loadimage, pstate
				fel_browser_preview, pstate
			end



		;;
		;;	Background files
		;;	
			(*pstate).menu.Tool_defineBackgroundFiles : begin
				fel_browser_definebackground, pstate
				widget_control, (*pstate).menu.Viewer_backgroundSubtract, set_button=1
			end
			(*pstate).menu.Tool_clearbackgroundfiles : begin
				ptr_free, (*pstate).global.background_data
			end
			
			(*pstate).menu.Tool_smoothbackground : begin
				fel_browser_smoothbackground, pstate
			end
			
			

			(*pstate).menu.Viewer_backgroundSubtract : begin
				state = widget_info((*pstate).menu.Viewer_backgroundSubtract, /button_set)
				widget_control, (*pstate).menu.Viewer_backgroundSubtract, set_button=1-state
				fel_browser_preview, pstate			
			end

					
			(*pstate).menu.Viewer_displayBackgroundImage : begin
				fel_browser_displayBackgroundImage, pstate
			end
			


		;;
		;;	Display log files
		;;
			(*pstate).menu.View_MasterLog : begin
				masterlog = (*pstate).global.directory+'MasterLog.txt'
				xdisplayfile, masterlog
			end
			(*pstate).menu.View_MotorPositions : begin
				motorpositions = (*pstate).global.directory+'Motor_Positions.txt'
				xdisplayfile, motorpositions
			end


			(*pstate).menu.View_ImageHeader : begin
				directory =	(*pstate).global.directory
				filenum = (*pstate).global.currentFileID
				filename = (*(*pstate).global.filenames)[filenum]
				headerfile = strmid(filename, 0, strlen(filename)-4) + '.txt'
				headerfile = directory+headerfile

				xdisplayfile, headerfile
			end

		;;
		;;	Click in the histogram changes maximum scale
		;;
			(*pstate).draw.histogram : begin
				if event.type eq 0 AND event.press eq 1 then begin

					;; Get display size
						oldwin = !d.window
						wset, (*pstate).window.histogram
						xs = !d.x_size
						ys = !d.y_size
						if oldwin ne -1 then $
							wset, oldwin
							
					;; Work out new upper level
						new_max = (float(event.x)/xs) * (*pstate).global.ccd_max
						(*pstate).global.scale_max = new_max 
						fel_browser_preview, pstate
				endif
			end
			
			

		;;
		;;	Collect comments
		;;
			(*pstate).menu.Comment_Scan : begin
				fel_browser_scancomments, pstate
			end
			(*pstate).button.collectcomments : begin
				fel_browser_scancomments, pstate
			end

		;;
		;;	What comments do we want to look at?
		;;
			(*pstate).menu.Comment_DateTime : begin
				state = widget_info((*pstate).menu.Comment_datetime, /button_set)
				widget_control, (*pstate).menu.comment_datetime, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_sample : begin
				state = widget_info((*pstate).menu.Comment_sample, /button_set) 
				widget_control, (*pstate).menu.comment_sample, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_position : begin
				state = widget_info((*pstate).menu.Comment_position, /button_set)
				widget_control, (*pstate).menu.comment_position, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_Comment1 : begin
				state = widget_info((*pstate).menu.Comment_Comment1, /button_set)
				widget_control, (*pstate).menu.Comment_Comment1, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_Comment2 : begin
				state = widget_info((*pstate).menu.Comment_Comment2, /button_set)
				widget_control, (*pstate).menu.comment_Comment2, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_timestamps : begin
				state = widget_info((*pstate).menu.Comment_timestamps, /button_set)
				widget_control, (*pstate).menu.comment_timestamps, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_Hits : begin
				state = widget_info((*pstate).menu.Comment_Hits, /button_set)
				widget_control, (*pstate).menu.comment_Hits, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_HitStrength : begin
				state = widget_info((*pstate).menu.Comment_HitStrength, /button_set)
				widget_control, (*pstate).menu.comment_HitStrength, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_Tag : begin
				state = widget_info((*pstate).menu.Comment_Tag, /button_set)
				widget_control, (*pstate).menu.comment_tag, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_ExposureTime : begin
				state = widget_info((*pstate).menu.Comment_ExposureTime, /button_set)
				widget_control, (*pstate).menu.Comment_ExposureTime, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_CCDbinning : begin
				state = widget_info((*pstate).menu.Comment_CCDbinning, /button_set)
				widget_control, (*pstate).menu.Comment_CCDbinning, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_CCDtemp : begin
				state = widget_info((*pstate).menu.Comment_CCDtemp, /button_set)
				widget_control, (*pstate).menu.Comment_CCDtemp, set_button=1-state
				fel_browser_displaycomments, pstate
			end
			(*pstate).menu.Comment_PulsesCounted : begin
				state = widget_info((*pstate).menu.Comment_PulsesCounted, /button_set)
				widget_control, (*pstate).menu.Comment_PulsesCounted, set_button=1-state
				fel_browser_displaycomments, pstate
			end

		;;
		;;	What camera are we using?
		;;
			(*pstate).menu.Setup_RoperCCD : begin
				fel_browser_configure, pstate, 'RoperCCD'
			end

			(*pstate).menu.Setup_XCAM : begin
				fel_browser_configure, pstate, 'XCAM'
			end

			(*pstate).menu.Setup_HDF5 : begin
				fel_browser_configure, pstate, 'HDF5'
			end

			(*pstate).menu.Setup_pnCCD : begin
				fel_browser_configure, pstate, 'pnCCD'
			end



			(*pstate).menu.Setup_debug : begin
				state = widget_info((*pstate).menu.setup_debug, /button_set)
				widget_control, (*pstate).menu.setup_debug, set_button=1-state
			end

			(*pstate).menu.Setup_verbose : begin
				state = widget_info((*pstate).menu.setup_verbose, /button_set)
				widget_control, (*pstate).menu.setup_verbose, set_button=1-state
			end

		;;
		;;	XCam overclock background removal
		;;
			(*pstate).menu.Correction_XcamOverclock1 : begin
				state = widget_info((*pstate).menu.Correction_XcamOverclock1, /button_set)
				widget_control, (*pstate).menu.Correction_XcamOverclock1, set_button=1-state
				widget_control, (*pstate).menu.Correction_XcamOverclock2, set_button=0
				widget_control, (*pstate).menu.Correction_XcamBanding, set_button=0
				widget_control, (*pstate).menu.Correction_XcamAntiHerringbone, set_button=0
			end

			(*pstate).menu.Correction_XcamOverclock2 : begin
				state = widget_info((*pstate).menu.Correction_XcamOverclock2, /button_set)
				widget_control, (*pstate).menu.Correction_XcamOverclock2, set_button=1-state
				widget_control, (*pstate).menu.Correction_XcamOverclock1, set_button=0
				widget_control, (*pstate).menu.Correction_XcamBanding, set_button=0
				widget_control, (*pstate).menu.Correction_XcamAntiHerringbone, set_button=0
			end

			(*pstate).menu.Correction_XcamOverclock3 : begin
				state = widget_info((*pstate).menu.Correction_XcamOverclock3, /button_set)
				widget_control, (*pstate).menu.Correction_XcamOverclock3, set_button=1-state
				;widget_control, (*pstate).menu.Correction_XcamOverclock1, set_button=0
				widget_control, (*pstate).menu.Correction_XcamBanding, set_button=0
				widget_control, (*pstate).menu.Correction_XcamAntiHerringbone, set_button=0
			end

			(*pstate).menu.Correction_XcamBanding : begin
				state = widget_info((*pstate).menu.Correction_XcamBanding, /button_set)
				widget_control, (*pstate).menu.Correction_XcamBanding, set_button=1-state
				widget_control, (*pstate).menu.Correction_XcamOverclock1, set_button=0
				widget_control, (*pstate).menu.Correction_XcamOverclock2, set_button=0
				widget_control, (*pstate).menu.Correction_XcamAntiHerringbone, set_button=0
			end

			(*pstate).menu.Correction_XcamAntiHerringbone : begin
				state = widget_info((*pstate).menu.Correction_XcamAntiHerringbone, /button_set)
				widget_control, (*pstate).menu.Correction_XcamAntiHerringbone, set_button=1-state
				widget_control, (*pstate).menu.Correction_XcamOverclock1, set_button=0
				widget_control, (*pstate).menu.Correction_XcamBanding, set_button=0
				widget_control, (*pstate).menu.Correction_XcamOverclock2, set_button=0
			end

			(*pstate).menu.Correction_CropDataAtZero : begin
				state = widget_info((*pstate).menu.Correction_CropDataAtZero, /button_set)
				widget_control, (*pstate).menu.Correction_CropDataAtZero, set_button=1-state
			end
			(*pstate).menu.Correction_AbsData : begin
				state = widget_info((*pstate).menu.Correction_AbsData, /button_set)
				widget_control, (*pstate).menu.Correction_AbsData, set_button=1-state
			end

			(*pstate).menu.Correction_CCDoffset : begin
				state = widget_info((*pstate).menu.Correction_CCDoffset, /button_set)
				widget_control, (*pstate).menu.Correction_CCDoffset, set_button=1-state
			end

			(*pstate).menu.Correction_ScaleOverflow  : begin
				state = widget_info((*pstate).menu.Correction_ScaleOverflow , /button_set)
				widget_control, (*pstate).menu.Correction_ScaleOverflow , set_button=1-state
			end

			(*pstate).menu.Correction_pnCCDcommonmode : begin
				state = widget_info((*pstate).menu.Correction_pnCCDcommonmode , /button_set)
				widget_control, (*pstate).menu.Correction_pnCCDcommonmode , set_button=1-state
			end


		;;
		;;	Image corrections
		;;
			
			(*pstate).menu.Correction_quick : begin
				state = widget_info((*pstate).menu.Correction_quick , /button_set)
				widget_control, (*pstate).menu.Correction_quick, set_button=1-state
				widget_control, (*pstate).menu.Correction_locations, set_button=0
				;if not ptr_valid((*pstate).global.pixelLocationMap) then $
				;	fel_browser_createPixelmap, pstate
				fel_browser_loadimage, pstate
			end

			(*pstate).menu.Correction_locations : begin
				state = widget_info((*pstate).menu.Correction_locations , /button_set)
				widget_control, (*pstate).menu.Correction_locations, set_button=1-state
				widget_control, (*pstate).menu.Correction_quick, set_button=0
				;if not ptr_valid((*pstate).global.pixelLocationMap) then $
				;	fel_browser_createPixelmap, pstate
				fel_browser_loadimage, pstate
			end
			
			(*pstate).menu.Correction_CCDAlignmentTool : begin
				fel_browser_CCDAlignmentTool, pstate
			end

			
			(*pstate).menu.Correction_intensities : begin
				state = widget_info((*pstate).menu.Correction_intensities , /button_set)
				widget_control, (*pstate).menu.Correction_intensities, set_button=1-state
				if not ptr_valid((*pstate).global.pixelIntensityMap) then $
					fel_browser_loadPixelIntensities, pstate
				fel_browser_loadimage, pstate
			end

			(*pstate).menu.Correction_CentreInCentre : begin
				state = widget_info((*pstate).menu.Correction_CentreInCentre , /button_set)
				widget_control, (*pstate).menu.Correction_CentreInCentre, set_button=1-state
			end

			
			(*pstate).menu.Correction_CreateLocations : begin
				fel_browser_createpixelmap, pstate
				widget_control, (*pstate).menu.Correction_locations, set_button=1
				fel_browser_loadimage, pstate
			end
			
			
			(*pstate).menu.Correction_LoadLocations : begin
				fel_browser_loadPixelLocations, pstate
				widget_control, (*pstate).menu.Correction_locations, set_button=1
				fel_browser_loadimage, pstate
			end
			
			(*pstate).menu.Correciton_LoadIntensities : begin
				fel_browser_loadPixelIntensities, pstate
				fel_browser_loadimage, pstate
			end
			
			(*pstate).menu.Correction_ViewPixelX : begin
			
			end
			
			(*pstate).menu.Correction_ViewPixelY : begin
			
			end
			
			(*pstate).menu.Correction_ViewPixelIntensity : begin
			
			end
		


		;;
		;;	Miscellaneous tools
		;;
			(*pstate).menu.Tool_calculator : begin
				fel_calculator
			end

			(*pstate).menu.Tool_FindHits : begin
				selection = widget_info((*pstate).table.files, /table_select)
				fel_browser_findhits, pstate
			end
		
			(*pstate).menu.Tool_SortHits : begin
				fel_browser_sorthits
			end
		
		
			(*pstate).menu.Tool_halt : begin
				data = *((*pstate).global.image_data)
				
				print,'Image data stored in variable (data)'
				stop
			end

			(*pstate).menu.Tool_h5browser : begin
				data = h5_browser()
			end



		;;
		;;	Window resize events
		;;
			(*pstate).top : begin
				x_padding = (*pstate).global.table_padding.x
				y_padding = (*pstate).global.table_padding.y
				min_xsize = (*pstate).global.default_geometry.scr_xsize - x_padding
				min_ysize = (*pstate).global.default_geometry.scr_ysize - y_padding
				
			  	new_xsize = (event.x gt x_padding) ? (event.x - x_padding) : x_padding
			  	new_ysize = (event.y gt y_padding) ? (event.y - y_padding) : y_padding
			  	new_xsize = (new_xsize lt min_xsize) ? min_xsize : new_xsize
			  	new_ysize = (new_ysize lt min_ysize) ? min_ysize : new_ysize

			  	WIDGET_CONTROL, (*pstate).table.files, scr_xsize=new_xsize, scr_ysize=new_ysize
			end

		;;
		;;	About
		;;
			(*pstate).menu.File_about : begin
				result = dialog_message(title='About FEL browser', $
					'FEL browser:  Anton Barty, CFEL (anton.barty@desy.de)')
			end

		;;
		;;	Quit 
		;;
			(*pstate).menu.quit : begin
				widget_control, event.top, /destroy
			end
			(*pstate).button.quit : begin
				widget_control, event.top, /destroy
			end

			
		;;
		;;	Nothing found:
		;;	Let's see if we know what to do with the parent
		;;		
			else : begin
				parent = widget_info(event.ID, /parent)
				case parent of

					;;
					;;	Plugin selected
					;;
						(*pstate).menu.Plugins : begin
							fel_browser_launchplugin, event
						end
					
					;;
					;;	Parent not known either
					;;
					else : 	begin
						print,'Selected event not in event handler list:'
						help, event, /str 
					endelse
				endcase
			endelse
			
	endcase
	
end

