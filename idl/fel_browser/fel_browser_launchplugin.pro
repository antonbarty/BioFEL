;;
;;	FEL_Browser
;;	Tool for snooping through FEL diffraction images
;;
;;	Anton Barty, 2010-2012
;;

;;
;;	Launch selected plugin module
;;
pro fel_browser_launchplugin, event
	widget_control, event.top, get_uvalue=pstate

	;;
	;;	Find which plugin was selected by scanning list of IDs
	;;
		n_plugins = n_elements((*pstate).menu.plugin_id)
		for i=0, n_plugins-1 do begin
			if event.ID eq (*pstate).menu.plugin_id[i] then $
				plugin_name = (*pstate).menu.plugin_name[i]
		endfor

	;;
	;;	Strip the '.pro'
	;;
		plugin_name = strmid(plugin_name, 0, strlen(plugin_name)-4)


	;;
	;;	Which files are currently selected?
	;;
		directory =	(*pstate).global.directory
		selection = widget_info((*pstate).table.files, /table_select)
		if (selection[0] eq -1) then begin 
			result = dialog_message('No images selected')
			return
		endif
		sel_start = selection[1]
		sel_end = selection[3]
		filenames = (*(*pstate).global.filenames)[sel_start:sel_end]
		
		filenames = directory+filenames

	;;
	;;	Launch the plugin
	;;
		print, n_elements(filenames),' files selected.'
		print, 'Launching: ', plugin_name

		call_procedure, plugin_name, pstate, filenames
	
end