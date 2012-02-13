;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Procedure to select current working directory
;;
pro fel_browser_selectdir, event
	widget_control, event.top, get_uvalue=pstate

	case (*pstate).setup.camera of

		'XCAM' : begin
			directory = dialog_pickfile(/directory, path=(*pstate).global.directory,title='Xcam #1 directory')
			if (directory eq '') then $
				return

			(*pstate).global.XcamDir[0] = directory
			(*pstate).global.XcamDir[1] = dialog_pickfile(/directory, path=(*pstate).global.XcamDir[0],title='Xcam #2 directory')
			(*pstate).global.XcamDir[2] = dialog_pickfile(/directory, path=(*pstate).global.XcamDir[0],title='Xcam #3 directory')
		end
	
		else : begin
			directory = dialog_pickfile(/directory, path=(*pstate).global.directory)
			if (directory eq '') then $
				return
		end
		
	endcase
	
	(*pstate).global.directory = directory
	WIDGET_CONTROL, (*pstate).text.FileListLabel, set_value = directory
end

