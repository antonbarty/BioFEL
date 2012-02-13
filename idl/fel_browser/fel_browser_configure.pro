pro fel_browser_configure, pstate, system

	;;
	;;	Configure default properties depending on what camera we are using
	;;
	case system of
	
			'RoperCCD' : begin
				(*pstate).setup.camera = 'RoperCCD'
				(*pstate).setup.FileFilter = 'FEL*.TIF'
				(*pstate).global.ccd_max = 2L^16-1
				(*pstate).global.scale_max = 2L^16-1
				widget_control, (*pstate).menu.Setup_RoperCCD, set_button=1
				widget_control, (*pstate).menu.Setup_cspad, set_button=0
				widget_control, (*pstate).menu.Setup_XCAM, set_button=0
				widget_control, (*pstate).menu.Setup_HDF5, set_button=0
				widget_control, (*pstate).menu.Setup_pnCCD, set_button=0
			end

			'XCAM' : begin
				(*pstate).setup.camera = 'XCAM'
				(*pstate).setup.FileFilter = '*.tif,*.png'
				(*pstate).global.ccd_max = 2L^14-1
				(*pstate).global.scale_max = 2L^14-1
				widget_control, (*pstate).menu.Setup_RoperCCD, set_button=0
				widget_control, (*pstate).menu.Setup_XCAM, set_button=1
				widget_control, (*pstate).menu.Setup_cspad, set_button=0
				widget_control, (*pstate).menu.Setup_HDF5, set_button=0
				widget_control, (*pstate).menu.Setup_pnCCD, set_button=0
			end
				
			'pnCCD' : begin
				(*pstate).setup.camera = 'pnCCD'
				(*pstate).global.ccd_max = 2L^14-1
				(*pstate).global.scale_max = 2L^14-1
				widget_control, (*pstate).menu.Setup_RoperCCD, set_button=0
				widget_control, (*pstate).menu.Setup_XCAM, set_button=0
				widget_control, (*pstate).menu.Setup_cspad, set_button=0
				widget_control, (*pstate).menu.Setup_HDF5, set_button=0
				widget_control, (*pstate).menu.Setup_pnCCD, set_button=1
				;widget_control, (*pstate).menu.Correction_AbsData, set_button=1
				widget_control, (*pstate).menu.Correction_ScaleOverflow , set_button=1
				widget_control, (*pstate).menu.comment_Comment1, set_button=0
				widget_control, (*pstate).menu.comment_Datetime, set_button=1
				widget_control, (*pstate).menu.comment_Hits, set_button=1
				widget_control, (*pstate).menu.comment_HitStrength, set_button=1
				widget_control, (*pstate).menu.Correction_pnCCDcommonmode, set_button=0

			end

			'cspad' : begin
				(*pstate).setup.camera = 'cspad'
				(*pstate).setup.FileFilter = '*.h5'
				widget_control, (*pstate).menu.Setup_RoperCCD, set_button=0
				widget_control, (*pstate).menu.Setup_XCAM, set_button=0
				widget_control, (*pstate).menu.Setup_HDF5, set_button=0
				widget_control, (*pstate).menu.Setup_pnCCD, set_button=0
				widget_control, (*pstate).menu.Setup_cspad, set_button=1
			end


			'HDF5' : begin
				(*pstate).setup.camera = 'HDF5'
				(*pstate).setup.FileFilter = '*.h5'
				widget_control, (*pstate).menu.Setup_RoperCCD, set_button=0
				widget_control, (*pstate).menu.Setup_XCAM, set_button=0
				widget_control, (*pstate).menu.Setup_HDF5, set_button=1
				widget_control, (*pstate).menu.Setup_cspad, set_button=0
				widget_control, (*pstate).menu.Setup_pnCCD, set_button=0
			end


	endcase




end
